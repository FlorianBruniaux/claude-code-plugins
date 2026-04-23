#!/bin/bash
# Git pre-commit hook: LLM-as-a-Judge evaluation before commit
#
# This hook uses Claude to evaluate staged changes before allowing a commit.
# It's an OPT-IN feature due to API costs and latency.
#
# COST WARNING: Each commit evaluation costs ~$0.01-0.05 (Haiku model)
#
# Installation:
#   1. Copy to your repo: cp pre-commit-evaluator.sh .git/hooks/pre-commit
#   2. Make executable: chmod +x .git/hooks/pre-commit
#   3. Set required env var: export CLAUDE_PRECOMMIT_EVAL=1
#
# Environment Variables:
#   CLAUDE_PRECOMMIT_EVAL  - Set to "1" to enable (default: disabled)
#   CLAUDE_EVAL_MODEL      - Model to use (default: haiku)
#   CLAUDE_EVAL_THRESHOLD  - Minimum score to pass (default: 7)
#   CLAUDE_EVAL_SKIP_PATHS - Colon-separated paths to skip (e.g., "docs:*.md")
#
# Bypass for single commit:
#   CLAUDE_SKIP_EVAL=1 git commit -m "message"
#   or
#   git commit --no-verify -m "message"

set -e

# Check if evaluation is enabled
if [[ "${CLAUDE_PRECOMMIT_EVAL:-0}" != "1" ]]; then
    exit 0
fi

# Check for bypass
if [[ "${CLAUDE_SKIP_EVAL:-0}" == "1" ]]; then
    echo "Skipping LLM evaluation (CLAUDE_SKIP_EVAL=1)"
    exit 0
fi

# Configuration
MODEL="${CLAUDE_EVAL_MODEL:-haiku}"
THRESHOLD="${CLAUDE_EVAL_THRESHOLD:-7}"
SKIP_PATHS="${CLAUDE_EVAL_SKIP_PATHS:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check for staged changes
STAGED_FILES=$(git diff --cached --name-only)
if [[ -z "$STAGED_FILES" ]]; then
    exit 0
fi

# Filter out skipped paths
if [[ -n "$SKIP_PATHS" ]]; then
    IFS=':' read -ra SKIP_ARRAY <<< "$SKIP_PATHS"
    FILTERED_FILES=""
    for file in $STAGED_FILES; do
        skip=false
        for pattern in "${SKIP_ARRAY[@]}"; do
            if [[ "$file" == $pattern ]]; then
                skip=true
                break
            fi
        done
        if [[ "$skip" == "false" ]]; then
            FILTERED_FILES="$FILTERED_FILES $file"
        fi
    done
    STAGED_FILES=$(echo "$FILTERED_FILES" | xargs)
fi

# Exit if all files were filtered
if [[ -z "$STAGED_FILES" ]]; then
    exit 0
fi

# Count files
FILE_COUNT=$(echo "$STAGED_FILES" | wc -w | tr -d ' ')

echo -e "${CYAN}Evaluating $FILE_COUNT staged file(s) with Claude ($MODEL)...${NC}"
echo -e "${YELLOW}Cost: ~\$0.01-0.05 per evaluation${NC}"
echo ""

# Get the diff
DIFF=$(git diff --cached)

# Truncate diff if too large (to control costs)
MAX_CHARS=50000
if [[ ${#DIFF} -gt $MAX_CHARS ]]; then
    echo -e "${YELLOW}Warning: Diff truncated to ${MAX_CHARS} chars for cost control${NC}"
    DIFF="${DIFF:0:$MAX_CHARS}

[TRUNCATED - diff exceeded ${MAX_CHARS} characters]"
fi

# Prepare the prompt
PROMPT="You are a code quality evaluator. Analyze this git diff and provide a JSON evaluation.

Score each criterion from 0-10:
- correctness: Does the code work correctly?
- completeness: Is the implementation complete (no TODOs, stubs)?
- safety: No secrets, no security issues?

Respond ONLY with valid JSON in this format:
{
  \"verdict\": \"APPROVE\" or \"NEEDS_REVIEW\" or \"REJECT\",
  \"scores\": {\"correctness\": N, \"completeness\": N, \"safety\": N},
  \"issues\": [{\"severity\": \"high/medium/low\", \"description\": \"...\"}],
  \"summary\": \"One sentence summary\"
}

Rules:
- APPROVE if all scores >= $THRESHOLD and no high-severity issues
- NEEDS_REVIEW if any score is 5-$((THRESHOLD-1)) or medium issues exist
- REJECT if any score < 5 or high-severity security issues

Git diff to evaluate:

$DIFF"

# Call Claude (requires claude CLI to be installed and authenticated)
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: 'claude' CLI not found. Install Claude Code first.${NC}"
    exit 1
fi

# Run evaluation
RESULT=$(echo "$PROMPT" | claude --model "$MODEL" --print 2>/dev/null) || {
    echo -e "${RED}Error: Claude evaluation failed${NC}"
    echo "You can bypass with: CLAUDE_SKIP_EVAL=1 git commit"
    exit 1
}

# Extract JSON from response (handle potential markdown wrapping)
JSON_RESULT=$(echo "$RESULT" | grep -o '{.*}' | head -1)

if [[ -z "$JSON_RESULT" ]]; then
    echo -e "${YELLOW}Warning: Could not parse evaluation result${NC}"
    echo "Raw response: $RESULT"
    echo ""
    echo "Proceeding with commit (evaluation inconclusive)"
    exit 0
fi

# Parse result
VERDICT=$(echo "$JSON_RESULT" | jq -r '.verdict // "UNKNOWN"')
CORRECTNESS=$(echo "$JSON_RESULT" | jq -r '.scores.correctness // 0')
COMPLETENESS=$(echo "$JSON_RESULT" | jq -r '.scores.completeness // 0')
SAFETY=$(echo "$JSON_RESULT" | jq -r '.scores.safety // 0')
SUMMARY=$(echo "$JSON_RESULT" | jq -r '.summary // "No summary"')
ISSUES=$(echo "$JSON_RESULT" | jq -r '.issues // []')

# Display results
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                 Evaluation Results${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Correctness:   $CORRECTNESS/10"
echo "  Completeness:  $COMPLETENESS/10"
echo "  Safety:        $SAFETY/10"
echo ""
echo "  Summary: $SUMMARY"
echo ""

# Show issues if any
ISSUE_COUNT=$(echo "$ISSUES" | jq 'length')
if [[ "$ISSUE_COUNT" -gt 0 ]]; then
    echo "  Issues found:"
    echo "$ISSUES" | jq -r '.[] | "    [\(.severity | ascii_upcase)] \(.description)"'
    echo ""
fi

# Handle verdict
case "$VERDICT" in
    APPROVE)
        echo -e "${GREEN}✓ APPROVED - Proceeding with commit${NC}"
        echo ""
        exit 0
        ;;
    NEEDS_REVIEW)
        echo -e "${YELLOW}⚠ NEEDS_REVIEW - Issues detected${NC}"
        echo ""
        echo "Options:"
        echo "  1. Fix issues and try again"
        echo "  2. Bypass: CLAUDE_SKIP_EVAL=1 git commit"
        echo "  3. Skip hook: git commit --no-verify"
        echo ""
        exit 1
        ;;
    REJECT)
        echo -e "${RED}✗ REJECTED - Critical issues found${NC}"
        echo ""
        echo "Please fix the issues before committing."
        echo "To force commit anyway: git commit --no-verify"
        echo ""
        exit 1
        ;;
    *)
        echo -e "${YELLOW}? Unknown verdict: $VERDICT${NC}"
        echo "Proceeding with commit (evaluation inconclusive)"
        exit 0
        ;;
esac
