#!/bin/bash
# permission-request.sh
# Runs when permission dialog appears
# Use for custom approval logic or logging

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
PERMISSION_TYPE=$(echo "$INPUT" | jq -r '.permission_type // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Log permission request
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_ENTRY=$(jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg permission "$PERMISSION_TYPE" \
  --arg session "$SESSION_ID" \
  '{timestamp: $timestamp, tool: $tool, permission_type: $permission, session: $session}')

echo "$LOG_ENTRY" >> "$LOG_DIR/permissions-$(date +%Y-%m-%d).jsonl"

# Example: Auto-deny dangerous permissions in production
if [[ "$PERMISSION_TYPE" == "file_write" ]] && [[ "$PWD" == *"/production"* ]]; then
    echo "BLOCKED: File write in production directory requires manual approval" >&2
    exit 2
fi

# Example: Warn about elevated permissions
if [[ "$PERMISSION_TYPE" == "bash_sudo" ]]; then
    cat << EOF
{
  "systemMessage": "⚠️ Warning: Tool requesting sudo permissions. Review carefully before approving."
}
EOF
fi

exit 0
