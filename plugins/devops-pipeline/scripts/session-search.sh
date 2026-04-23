#!/bin/bash
# session-search.sh - Fast Claude Code session search & resume (v2.0)
#
# Zero-dependency bash script to search past Claude Code conversations
# and generate ready-to-use resume commands.
#
# Usage:
#   cs                          # List 10 most recent sessions
#   cs "keyword"                # Single keyword search
#   cs "Prisma migration"       # Multi-word AND search (both must match)
#   cs -n 20                    # Show 20 results
#   cs -p myproject "bug"       # Filter by project name
#   cs --since 7d               # Sessions from last 7 days
#   cs --json "api"             # JSON output for scripting
#   cs --rebuild                # Force index rebuild
#
# Smart refresh:
#   Index auto-rebuilds when any session file is newer than the index.
#
# Performance:
#   - List recent:    ~15ms (cached index)
#   - Keyword search: ~400ms (multi-word AND)
#   - Index rebuild:  ~5s for 200 sessions
#   - Timeout:        3s max for searches
#
# Installation:
#   cp session-search.sh ~/.claude/scripts/cs
#   chmod +x ~/.claude/scripts/cs
#   echo "alias cs='~/.claude/scripts/cs'" >> ~/.zshrc

set -euo pipefail

INDEX="$HOME/.claude/sessions.idx"
PROJECTS="$HOME/.claude/projects"
LIMIT=10
PROJECT_FILTER=""
SINCE_DATE=""
OUTPUT_JSON=false
MAX_SEARCH_TIME=3

# Colors (disabled for JSON output)
C_CYAN='\033[36m'
C_YELLOW='\033[33m'
C_DIM='\033[2m'
C_RESET='\033[0m'

show_help() {
    cat << 'EOF'
Usage: cs [OPTIONS] [KEYWORD]

Search and resume Claude Code sessions.

Options:
  -n <N>              Show N results (default: 10)
  -p, --project <P>   Filter by project name (substring match)
  --since <DATE>      Filter sessions since DATE
                      Formats: YYYY-MM-DD, today, yesterday, 7d, 30d
  --json              Output as JSON (for scripting)
  --rebuild           Force index rebuild
  -h, --help          Show this help

Examples:
  cs                        # 10 most recent sessions
  cs "api"                  # Search for "api"
  cs "Prisma migration"     # Multi-word AND search (both must match)
  cs -p myproject "bug"     # Search "bug" in myproject only
  cs --since today          # Today's sessions
  cs --since 7d "fix"       # "fix" in last 7 days
  cs --json "api" | jq .    # JSON output for scripting

Output:
  Each result shows date, project, preview, and a ready-to-copy command:
    claude --resume <session-id>
EOF
}

# Parse --since date to YYYY-MM-DD format
parse_since() {
    local input="$1"
    case "$input" in
        today)
            date +%Y-%m-%d
            ;;
        yesterday)
            date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d
            ;;
        *d)
            local days="${input%d}"
            date -v-${days}d +%Y-%m-%d 2>/dev/null || date -d "-${days} days" +%Y-%m-%d
            ;;
        *)
            echo "$input"
            ;;
    esac
}

# Extract readable preview from session file
extract_preview() {
    local file="$1"
    local max_len="${2:-60}"

    # Find first user message with simple string content (not array)
    # Skip messages that look like tool results or file references
    local preview=$(grep '"type":"user"' "$file" 2>/dev/null | \
        grep -v '"content":\[' | \
        grep -v 'file-history-snapshot' | \
        head -1 | \
        sed 's/.*"content":"\([^"]*\).*/\1/' | \
        sed 's/\\n/ /g' | \
        sed 's/<[^>]*>//g' | \
        sed 's/@[^ ]*//g' | \
        sed 's/  */ /g' | \
        tr -cd '[:print:] ' | \
        cut -c1-"$max_len" | \
        tr -d '\n')

    # Fallback: if empty or still looks like JSON, use generic text
    if [[ -z "$preview" || "$preview" == "{"* ]]; then
        preview="(session)"
    fi

    echo "$preview"
}

# Extract clean project name from path
extract_project() {
    local dir="$1"
    basename "$dir" | \
        sed 's/^-Users-[^-]*-Sites-perso-//' | \
        sed 's/^-Users-[^-]*-Sites-//' | \
        sed 's/^-Users-[^-]*-//'
}

build_index() {
    echo "Indexing sessions..." >&2
    : > "$INDEX"

    local count=0
    for f in "$PROJECTS"/*/*.jsonl; do
        [[ -f "$f" ]] || continue
        # Skip agent/subagent sessions
        [[ "$(basename "$f")" == agent* ]] && continue

        local id=$(basename "$f" .jsonl)
        local proj=$(extract_project "$(dirname "$f")")
        local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f" 2>/dev/null || \
                      stat -c "%y" "$f" 2>/dev/null | cut -d: -f1-2)

        local msg=$(extract_preview "$f" 60)

        [[ -n "$msg" ]] && {
            printf '%s\t%s\t%s\t%s\n' "$mtime" "$proj" "$id" "$msg" >> "$INDEX"
            count=$((count + 1))
        }
    done

    sort -rk1 "$INDEX" -o "$INDEX"
    echo "Indexed $count sessions" >&2
}

needs_refresh() {
    [[ ! -f "$INDEX" ]] && return 0
    local newer=$(find "$PROJECTS" -name "*.jsonl" -newer "$INDEX" 2>/dev/null | head -1)
    [[ -n "$newer" ]] && return 0
    return 1
}

# Check if date is after since filter
check_since() {
    local mtime="$1"
    [[ -z "$SINCE_DATE" ]] && return 0

    # Extract just the date part (YYYY-MM-DD)
    local session_date="${mtime%% *}"
    [[ "$session_date" > "$SINCE_DATE" || "$session_date" == "$SINCE_DATE" ]]
}

# Check if project matches filter
check_project() {
    local proj="$1"
    [[ -z "$PROJECT_FILTER" ]] && return 0
    [[ "$proj" == *"$PROJECT_FILTER"* ]]
}

# Multi-word AND search: all words must be present
check_pattern() {
    local file="$1"
    local pattern="$2"

    [[ -z "$pattern" ]] && return 0

    # Split pattern into words
    local words=($pattern)

    # Check ALL words are present (AND logic)
    for word in "${words[@]}"; do
        grep -qi "$word" "$file" 2>/dev/null || return 1
    done

    return 0
}

# Escape string for JSON output
json_escape() {
    local str="$1"
    # Escape backslashes first, then quotes, then filter non-printable
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    printf '%s' "$str" | tr -cd '[:print:] '
}

# Display a single result
display_result() {
    local date="$1" proj="$2" id="$3" msg="$4"

    if [[ "$OUTPUT_JSON" == true ]]; then
        local escaped_msg=$(json_escape "$msg")
        printf '{"date":"%s","project":"%s","id":"%s","preview":"%s","resume":"claude --resume %s"}' \
            "$date" "$proj" "$id" "$escaped_msg" "$id"
    else
        printf "${C_CYAN}%s${C_RESET} │ ${C_YELLOW}%-22s${C_RESET} │ %.50s...\n" "$date" "$proj" "$msg"
        printf "  ${C_DIM}claude --resume %s${C_RESET}\n\n" "$id"
    fi
}

search_fulltext() {
    local pattern="$1"
    local start_time=$(date +%s)
    local found=0

    # Collect results for sorting
    declare -a results=()

    for f in "$PROJECTS"/*/*.jsonl; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == agent* ]] && continue

        # Timeout check
        local now=$(date +%s)
        if (( now - start_time > MAX_SEARCH_TIME )); then
            [[ "$OUTPUT_JSON" != true ]] && echo "Search timed out after ${MAX_SEARCH_TIME}s" >&2
            break
        fi

        # Multi-word AND search
        check_pattern "$f" "$pattern" || continue

        local id=$(basename "$f" .jsonl)
        local proj=$(extract_project "$(dirname "$f")")
        local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f" 2>/dev/null || \
                      stat -c "%y" "$f" 2>/dev/null | cut -d: -f1-2)

        # Apply filters
        check_project "$proj" || continue
        check_since "$mtime" || continue

        local msg=$(extract_preview "$f" 50)

        # Store for sorting (pipe-delimited)
        results+=("${mtime}|${proj}|${id}|${msg}")
        found=$((found + 1))
    done

    # Sort by date descending and display
    if [[ ${#results[@]} -gt 0 ]]; then
        if [[ "$OUTPUT_JSON" == true ]]; then
            echo -n '{"sessions":['
            local first=true
            printf '%s\n' "${results[@]}" | sort -rk1 -t'|' | head -"$LIMIT" | while IFS='|' read -r date proj id msg; do
                [[ "$first" != true ]] && echo -n ','
                first=false
                display_result "$date" "$proj" "$id" "$msg"
            done
            echo ']}'
        else
            echo ""
            printf '%s\n' "${results[@]}" | sort -rk1 -t'|' | head -"$LIMIT" | while IFS='|' read -r date proj id msg; do
                display_result "$date" "$proj" "$id" "$msg"
            done
        fi
    else
        if [[ "$OUTPUT_JSON" == true ]]; then
            echo '{"sessions":[]}'
        else
            echo "No sessions found${pattern:+ matching '$pattern'}."
        fi
    fi
}

search() {
    local pattern="$1"

    if [[ -z "$pattern" && -z "$PROJECT_FILTER" && -z "$SINCE_DATE" ]]; then
        # No filters = use fast index
        needs_refresh && build_index

        local results=$(head -"$LIMIT" "$INDEX")
        if [[ -z "$results" ]]; then
            if [[ "$OUTPUT_JSON" == true ]]; then
                echo '{"sessions":[]}'
            else
                echo "No sessions found."
            fi
            return
        fi

        if [[ "$OUTPUT_JSON" == true ]]; then
            echo -n '{"sessions":['
            local first=true
            echo "$results" | while IFS=$'\t' read -r date proj id msg; do
                [[ "$first" != true ]] && echo -n ','
                first=false
                display_result "$date" "$proj" "$id" "$msg"
            done
            echo ']}'
        else
            echo ""
            echo "$results" | while IFS=$'\t' read -r date proj id msg; do
                display_result "$date" "$proj" "$id" "$msg"
            done
        fi
    else
        # Filters or pattern = full-text search
        search_fulltext "$pattern"
    fi
}

# Parse arguments
KEYWORD=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --rebuild)
            build_index
            exit 0
            ;;
        -n)
            LIMIT="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_FILTER="$2"
            shift 2
            ;;
        --since)
            SINCE_DATE=$(parse_since "$2")
            shift 2
            ;;
        --json)
            OUTPUT_JSON=true
            C_CYAN='' C_YELLOW='' C_DIM='' C_RESET=''
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            KEYWORD="$1"
            shift
            ;;
    esac
done

search "$KEYWORD"
