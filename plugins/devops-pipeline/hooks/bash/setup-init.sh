#!/bin/bash
# setup-init.sh
# Runs when Claude Code starts (v2.1.10+)
# Use with --init, --init-only, or --maintenance flags

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')

# Create log directory if needed
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

# Log startup event
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "[$TIMESTAMP] Setup hook triggered - Session: $SESSION_ID - CWD: $CWD" >> "$LOG_DIR/setup.log"

# Check project requirements
if [[ -f "package.json" ]]; then
    # Check if node_modules exists
    if [[ ! -d "node_modules" ]]; then
        cat << EOF
{
  "systemMessage": "⚠️ Project setup incomplete: node_modules missing. Run 'npm install' before continuing.",
  "hookSpecificOutput": {
    "additionalContext": "Node.js project detected without dependencies installed."
  }
}
EOF
        exit 0
    fi
fi

# Check git status
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current)
    UNCOMMITTED=$(git status --short | wc -l | tr -d ' ')

    if [[ $UNCOMMITTED -gt 0 ]]; then
        cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "Git status: On branch $BRANCH with $UNCOMMITTED uncommitted changes."
  }
}
EOF
    fi
fi

exit 0
