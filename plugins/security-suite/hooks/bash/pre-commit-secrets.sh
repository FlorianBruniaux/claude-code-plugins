#!/bin/bash
# pre-commit-secrets.sh - Pre-commit hook to detect secrets in staged files
# Version: 1.0.0
# Purpose: Prevent accidental commits of API keys, tokens, and credentials
#
# Installation:
#   cp examples/hooks/bash/pre-commit-secrets.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Test:
#   echo "GITHUB_TOKEN=ghp_test" > test.txt
#   git add test.txt
#   git commit -m "Test"
#   # Should fail with secret detection error

set -euo pipefail

# Context: this is a pre-commit hook (uses git diff --cached); outside a git
# repo (e.g. running as PostToolUse:Edit under ~/.claude) there are no staged
# files to check.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Secret patterns (extended regex)
# Compat: bash 3.2 (macOS default) does not support 'declare -A'
# (associative arrays only exist from bash 4 onward). So names and
# regexes live in two PARALLEL indexed arrays, in the same order,
# instead of a single name->regex map.
PATTERN_NAMES=(
    "OpenAI API Key"
    "GitHub Token (ghp)"
    "GitHub Token (gho)"
    "GitHub Token (ghu)"
    "GitHub Token (ghs)"
    "GitHub Token (ghr)"
    "AWS Access Key"
    "AWS Secret Key"
    "Anthropic API Key"
    "Generic API Key"
    "Generic Secret"
    "Generic Token"
    "Database URL with Password"
    "Private Key"
    "JWT Token"
)

PATTERN_REGEXES=(
    "sk-[A-Za-z0-9]{48}"
    "ghp_[A-Za-z0-9]{36}"
    "gho_[A-Za-z0-9]{36}"
    "ghu_[A-Za-z0-9]{36}"
    "ghs_[A-Za-z0-9]{36}"
    "ghr_[A-Za-z0-9]{36}"
    "AKIA[A-Z0-9]{16}"
    "[A-Za-z0-9/+=]{40}"
    "sk-ant-[A-Za-z0-9-]{95,}"
    "api[_-]?key[\"']?\s*[:=]\s*[\"']?[A-Za-z0-9]{20,}"
    "secret[\"']?\s*[:=]\s*[\"']?[A-Za-z0-9]{20,}"
    "token[\"']?\s*[:=]\s*[\"']?[A-Za-z0-9]{20,}"
    "(postgres|mysql|mongodb)://[^:]+:[^@]+@"
    "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
    "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"
)

# Whitelisted patterns (safe to ignore)
WHITELIST=(
    "your_token_here"
    "your_key_here"
    "example.com"
    "localhost"
    "placeholder"
    "XXXXXX"
    "\${env:"  # Template variable syntax
    "sk-ant-example"  # Example in documentation
)

# Files to always skip (even if staged)
SKIP_FILES=(
    "*.md"  # Documentation often contains example secrets
    "*.txt" # Same for text files
    "*example*"
    "*template*"
    "*.sample"
)

# Check if a file should be skipped
should_skip_file() {
    local file=$1
    for pattern in "${SKIP_FILES[@]}"; do
        # Convert glob to regex
        local regex="${pattern//\*/.*}"
        if [[ $file =~ $regex ]]; then
            return 0  # Skip this file
        fi
    done
    return 1  # Don't skip
}

# Check if a match is whitelisted
is_whitelisted() {
    local match=$1
    for whitelist in "${WHITELIST[@]}"; do
        if [[ $match == *"$whitelist"* ]]; then
            return 0  # Whitelisted
        fi
    done
    return 1  # Not whitelisted
}

# Main secret detection logic
detect_secrets() {
    local files
    files=$(git diff --cached --name-only --diff-filter=ACM)

    if [ -z "$files" ]; then
        exit 0  # No staged files
    fi

    local found_secrets=0
    local secrets_report=""

    # Iterate through staged files
    while IFS= read -r file; do
        # Skip if file should be ignored
        if should_skip_file "$file"; then
            continue
        fi

        # Skip if file doesn't exist (deleted)
        if [ ! -f "$file" ]; then
            continue
        fi

        # Get staged content
        local content
        content=$(git show ":$file" 2>/dev/null || continue)

        # Check each pattern (walks both arrays by the same index)
        local pidx=0
        while [ "$pidx" -lt "${#PATTERN_NAMES[@]}" ]; do
            local pattern_name="${PATTERN_NAMES[$pidx]}"
            local pattern="${PATTERN_REGEXES[$pidx]}"
            pidx=$((pidx + 1))
            local matches
            # -e isolates the pattern from option parsing: some patterns
            # (e.g. "Private Key") start with "-----", and without -e
            # grep treats them as an unknown flag instead of a regex,
            # failing with "unrecognized option" and never matching.
            matches=$(echo "$content" | grep -noE -e "$pattern" || true)

            if [ -n "$matches" ]; then
                # Check each match against whitelist
                while IFS= read -r match; do
                    local line_num="${match%%:*}"
                    local matched_text="${match#*:}"

                    if ! is_whitelisted "$matched_text"; then
                        found_secrets=1
                        secrets_report+="  ${file}:${line_num} - ${pattern_name}\n"
                        secrets_report+="    Content: ${matched_text:0:50}...\n"
                    fi
                done <<< "$matches"
            fi
        done
    done <<< "$files"

    # Report findings
    if [ $found_secrets -eq 1 ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}✗ COMMIT BLOCKED: Secrets detected in staged files${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}Found potential secrets:${NC}"
        echo -e "$secrets_report"
        echo ""
        echo -e "${YELLOW}Remediation steps:${NC}"
        echo "  1. Remove secrets from files"
        echo "  2. Use environment variables: \${env:VAR_NAME}"
        echo "  3. Store secrets in ~/.claude/.env (gitignored)"
        echo "  4. See: guide/ultimate-guide.md Section 8.3.1"
        echo ""
        echo -e "${YELLOW}If this is a false positive:${NC}"
        echo "  - Edit .git/hooks/pre-commit and add to WHITELIST array"
        echo "  - Or skip hook: git commit --no-verify (USE WITH CAUTION)"
        echo ""
        exit 1
    fi

    exit 0
}

# Run detection
detect_secrets
