#!/usr/bin/env bash
# Hook: PostToolUse (matcher ".*"), observation only.
# Appends one JSON line per tool call to a daily log. PostToolUse fires per tool
# call by design, so no once-per-session guard applies here (unlike a Stop hook).
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[[ -z "$TOOL_NAME" ]] && exit 0
# CLAUDE_PLUGIN_DATA survives plugin updates; CLAUDE_PLUGIN_ROOT does not
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}}/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
# jq escapes the tool name; a hand-built JSON string would break on quotes
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg tool "$TOOL_NAME" '{ts: $ts, tool: $tool}' \
    >> "$LOG_DIR/learning-capture-$(date +%Y-%m-%d).jsonl" 2>/dev/null
exit 0
