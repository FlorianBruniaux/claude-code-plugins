#!/bin/bash
# subagent-stop.sh
# Runs when a sub-agent completes
# Use for cleanup, logging, or metrics

INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // 0')
DURATION=$(echo "$INPUT" | jq -r '.duration_ms // 0')

# Log subagent completion
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_ENTRY=$(jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg agent "$AGENT_NAME" \
  --arg session "$SESSION_ID" \
  --argjson exit_code "$EXIT_CODE" \
  --argjson duration "$DURATION" \
  '{timestamp: $timestamp, agent: $agent, session: $session, exit_code: $exit_code, duration_ms: $duration}')

echo "$LOG_ENTRY" >> "$LOG_DIR/subagents-$(date +%Y-%m-%d).jsonl"

# Calculate duration in seconds for readability
DURATION_SEC=$(echo "scale=2; $DURATION / 1000" | bc)

# Provide feedback on slow agents (>30 seconds)
if [[ $(echo "$DURATION > 30000" | bc) -eq 1 ]]; then
    cat << EOF
{
  "systemMessage": "⏱️ Subagent '$AGENT_NAME' took ${DURATION_SEC}s to complete. Consider optimizing or splitting into smaller tasks.",
  "hookSpecificOutput": {
    "additionalContext": "Subagent performance: $AGENT_NAME completed in ${DURATION_SEC}s"
  }
}
EOF
fi

# Alert on failed subagents
if [[ $EXIT_CODE -ne 0 ]]; then
    cat << EOF
{
  "systemMessage": "❌ Subagent '$AGENT_NAME' failed with exit code $EXIT_CODE. Review task output for errors."
}
EOF
fi

exit 0
