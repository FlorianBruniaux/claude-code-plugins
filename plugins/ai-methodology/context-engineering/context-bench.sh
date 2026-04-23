#!/bin/bash
# Context Engineering Benchmark
#
# Measures the impact of structural metadata files (code-map.yaml) on
# context quality. Two complementary angles:
#
#   1. Budget — token cost of different context loading strategies
#   2. Probe  — % of structural questions answerable without filesystem traversal
#
# Usage:
#   ./context-bench.sh                          # run both (default)
#   ./context-bench.sh --budget                 # budget analysis only
#   ./context-bench.sh --probe                  # probe coverage only
#   ./context-bench.sh /path/to/project         # specific project
#   ./context-bench.sh --compare v1.yaml v2.yaml  # diff two code-map versions
#
# What "probe coverage" means:
#   For each structural question a developer might ask ("where do I create a
#   new router?", "how many Prisma models exist?"), the probe checks whether
#   the answer is present in code-map.yaml. A covered question requires 0
#   filesystem tool calls to answer. An uncovered question requires Claude to
#   browse files — consuming turns and tokens before any code is written.
#
# Interpreting results:
#   Budget: on-demand loading (loading code-map only for implementation tasks)
#           should cost fewer session-start tokens than always-on loading.
#   Probe:  ≥ 80% coverage means Claude can answer most structural questions
#           in a single lookup. < 50% means the code-map needs more sections.

set -euo pipefail

# ── Args ─────────────────────────────────────────────────────────────────────

PROJECT_DIR="."
MODE="all"
COMPARE_A=""
COMPARE_B=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --budget)    MODE="budget";  shift ;;
    --probe)     MODE="probe";   shift ;;
    --compare)   MODE="compare"; COMPARE_A="$2"; COMPARE_B="$3"; shift 3 ;;
    -*)          echo "Unknown flag: $1" >&2; exit 1 ;;
    *)           PROJECT_DIR="$1"; shift ;;
  esac
done

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
CODE_MAP="$PROJECT_DIR/machine-readable/code-map.yaml"

# ── Helpers ───────────────────────────────────────────────────────────────────

estimate_tokens() {
  local file="$1"
  [[ -f "$file" ]] || { echo "0"; return; }
  local chars
  chars=$(wc -c < "$file" | tr -d ' ')
  echo $((chars / 4))
}

bold()   { printf "\033[1m%s\033[0m" "$*"; }
green()  { printf "\033[32m%s\033[0m" "$*"; }
yellow() { printf "\033[33m%s\033[0m" "$*"; }
red()    { printf "\033[31m%s\033[0m" "$*"; }
dim()    { printf "\033[2m%s\033[0m" "$*"; }

hr() { printf '%.0s─' {1..60}; echo; }

# ── Budget Analysis ───────────────────────────────────────────────────────────
#
# Compares three loading strategies for a typical implementation session:
#
#   A. No code-map     — CLAUDE.md only. Structural questions require FS traversal.
#   B. Always-on       — CLAUDE.md + code-map loaded at every session start.
#   C. On-demand       — CLAUDE.md at start, code-map loaded only for impl tasks.
#
# Strategy C is the recommended pattern. It costs 0 extra tokens for sessions
# that don't need structural context (debug, review, docs) and 1 tool call for
# sessions that do. Strategy B is wasteful: you pay the structural tokens even
# for sessions that never need them.

run_budget() {
  echo
  bold "  Budget Analysis"; echo
  hr

  local claude_tokens code_map_tokens
  claude_tokens=$(estimate_tokens "$CLAUDE_MD")
  code_map_tokens=$(estimate_tokens "$CODE_MAP")

  if [[ "$claude_tokens" -eq 0 ]]; then
    yellow "  CLAUDE.md not found at $CLAUDE_MD"; echo
    echo "  Run from your project root or pass a path: ./context-bench.sh /path/to/project"
    return
  fi

  printf "  %-32s %6d tokens\n" "CLAUDE.md" "$claude_tokens"

  if [[ "$code_map_tokens" -gt 0 ]]; then
    printf "  %-32s %6d tokens\n" "code-map.yaml" "$code_map_tokens"
  else
    yellow "  code-map.yaml not found at $CODE_MAP"; echo
    dim "  Create it with: pnpm ai:codemap (or equivalent)"; echo
  fi

  echo
  printf "  %-36s %s\n" "Strategy" "Session-start tokens"
  printf "  %-36s %s\n" "────────" "────────────────────"

  local always_on=$((claude_tokens + code_map_tokens))

  printf "  %-36s %6d  %s\n" \
    "A. No code-map (baseline)" \
    "$claude_tokens" \
    "$(dim "structural questions → filesystem traversal")"

  if [[ "$code_map_tokens" -gt 0 ]]; then
    printf "  %-36s %6d  %s\n" \
      "B. Always-on (avoid)" \
      "$always_on" \
      "$(yellow "+$code_map_tokens every session")"

    printf "  %-36s %6d  %s\n" \
      "C. On-demand (recommended)" \
      "$claude_tokens" \
      "$(green "+$code_map_tokens only when needed")"

    echo
    local impl_pct
    impl_pct=$(( (code_map_tokens * 100) / (claude_tokens > 0 ? claude_tokens : 1) ))
    printf "  code-map overhead: %d tokens = %d%% of CLAUDE.md size\n" \
      "$code_map_tokens" "$impl_pct"

    if [[ "$code_map_tokens" -lt 800 ]]; then
      printf "  Budget grade: %s\n" "$(green "LEAN — excellent")"
    elif [[ "$code_map_tokens" -lt 1500 ]]; then
      printf "  Budget grade: %s\n" "$(green "OK — within the 1.5K target for auto-generated files")"
    elif [[ "$code_map_tokens" -lt 2500 ]]; then
      printf "  Budget grade: %s\n" "$(yellow "HEAVY — check for hand-curated content that belongs elsewhere")"
    else
      printf "  Budget grade: %s\n" "$(red "OVERLOADED — structural metadata should stay under 2.5K tokens")"
    fi
  fi

  echo
}

# ── Probe Coverage ────────────────────────────────────────────────────────────
#
# Structural probes: questions a developer commonly asks before writing code.
# Each probe checks whether the answer is present in code-map.yaml using
# grep. A match means Claude can answer in one lookup (0 filesystem tool
# calls). A miss means Claude must traverse the filesystem — consuming extra
# turns before any code is written.
#
# Add project-specific probes to the EXTRA_PROBES array at the bottom of
# this section.

run_probe() {
  echo
  bold "  Probe Coverage"; echo
  hr
  dim "  Checks which structural questions code-map.yaml can answer directly."; echo
  dim "  A covered probe = 0 filesystem tool calls needed to answer it."; echo
  echo

  if [[ ! -f "$CODE_MAP" ]]; then
    red "  code-map.yaml not found — all probes fail by definition"; echo
    echo "  Create it first: pnpm ai:codemap (or equivalent)"
    return
  fi

  local pass=0 fail=0 total=0
  local results=()

  probe() {
    local label="$1"
    local pattern="$2"
    total=$((total + 1))
    if grep -q "$pattern" "$CODE_MAP" 2>/dev/null; then
      results+=("  $(green "✓") $label")
      pass=$((pass + 1))
    else
      results+=("  $(red "✗") $label  $(dim "→ grep: $pattern")")
      fail=$((fail + 1))
    fi
  }

  # Core structural probes — adapt patterns to your stack
  probe "Architecture layers defined"           "^layers:"
  probe "Layer root paths present"              "root:"
  probe "Layer file counts present"             "count:"
  probe "Component/feature domains listed"      "^component_domains:"
  probe "Domain file counts present"            "component_domains:.*count\|name:.*count:"
  probe "Nested CLAUDE.md files inventoried"    "^nested_contexts:"
  probe "Aggregate file count stats"            "^stats:"
  probe "Total source file count"               "total_.*files:"
  probe "Test file count"                       "test.*:"
  probe "Key canonical paths defined"           "^key_paths:"

  for r in "${results[@]}"; do echo "$r"; done

  echo
  local pct=$(( (pass * 100) / (total > 0 ? total : 1) ))
  printf "  Score: %d/%d probes covered (%d%%)\n" "$pass" "$total" "$pct"

  if [[ "$pct" -ge 80 ]]; then
    printf "  Grade: %s\n" "$(green "GOOD — most structural questions answerable in 1 lookup")"
  elif [[ "$pct" -ge 50 ]]; then
    printf "  Grade: %s\n" "$(yellow "PARTIAL — add missing sections to code-map.yaml")"
  else
    printf "  Grade: %s\n" "$(red "POOR — code-map.yaml needs more sections")"
    echo
    dim "  Covered probes save approximately 2-4 filesystem tool calls each."
    dim "  At 5 implementation sessions/day, a 50% improvement in coverage"
    dim "  saves roughly 20-40 tool calls per day across the team."
  fi
  echo

  # Navigation overhead estimate
  local nav_calls_saved=$(( pass * 2 ))   # rough: each covered probe saves ~2 glob/grep calls
  local nav_calls_lost=$(( fail * 3 ))    # uncovered: ~3 FS calls to locate the info
  if [[ "$total" -gt 0 ]]; then
    echo
    dim "  Estimated navigation overhead (per implementation session):"
    printf "  $(green "Saved")  : ~%d filesystem tool calls (covered probes)\n" "$nav_calls_saved"
    printf "  $(red "Wasted") : ~%d filesystem tool calls (uncovered probes)\n" "$nav_calls_lost"
  fi
}

# ── Compare two code-map versions ─────────────────────────────────────────────

run_compare() {
  echo
  bold "  Code-map Diff: $COMPARE_A → $COMPARE_B"; echo
  hr

  for f in "$COMPARE_A" "$COMPARE_B"; do
    [[ -f "$f" ]] || { red "  File not found: $f"; echo; exit 1; }
  done

  local tokens_a tokens_b
  tokens_a=$(estimate_tokens "$COMPARE_A")
  tokens_b=$(estimate_tokens "$COMPARE_B")
  local delta=$(( tokens_b - tokens_a ))

  printf "  %-20s %6d tokens\n" "$(basename "$COMPARE_A")" "$tokens_a"
  printf "  %-20s %6d tokens\n" "$(basename "$COMPARE_B")" "$tokens_b"

  if [[ "$delta" -gt 0 ]]; then
    printf "  Delta: $(yellow "+%d tokens")\n" "$delta"
  elif [[ "$delta" -lt 0 ]]; then
    printf "  Delta: $(green "%d tokens (reduced)")\n" "$delta"
  else
    printf "  Delta: $(dim "no change")\n"
  fi

  echo
  dim "  Structural diff (grep -based):"; echo
  diff <(grep -E "^[a-z_]+:" "$COMPARE_A" 2>/dev/null || true) \
       <(grep -E "^[a-z_]+:" "$COMPARE_B" 2>/dev/null || true) | \
    grep -E "^[<>]" | \
    sed 's/^< /  removed: /; s/^> /  added:   /' || \
    dim "  (no top-level section changes)"; echo
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

echo
bold "📐 Context Engineering Benchmark"; echo
bold "   Project: $PROJECT_DIR"; echo

case "$MODE" in
  budget)  run_budget ;;
  probe)   run_probe ;;
  compare) run_compare ;;
  all)     run_budget; run_probe ;;
esac

bold "Done."; echo
