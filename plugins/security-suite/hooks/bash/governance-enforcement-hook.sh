#!/usr/bin/env bash
# Governance Enforcement Hook - PostToolUse (Edit|Write), observation only.
# Appends each edit to ~/.claude/governance-audit.log and shows a systemMessage
# when the file looks sensitive. Never blocks (always exit 0).

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL_NAME" in
    Edit|Write) ;;
    *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

AUDIT_LOG="${HOME}/.claude/governance-audit.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{ mkdir -p "$(dirname "$AUDIT_LOG")" && echo "${TIMESTAMP} | ${TOOL_NAME} | ${FILE_PATH}" >> "$AUDIT_LOG"; } 2>/dev/null || true

# Plain substrings: a backslash inside a quoted [[ == ]] pattern is literal, so
# escaped patterns such as "\.env" never matched anything.
SENSITIVE_PATTERNS=(".env" ".claude.json" ".mcp.json" "settings.json" "CLAUDE.md" ".ssh/" ".gnupg/" "id_rsa" "id_ed25519" ".pem" ".key")

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" == *"$pattern"* ]]; then
        # jq escapes quotes and backslashes in the path; hand-built JSON broke on them
        jq -n --arg msg "Governance: sensitive file modified: $FILE_PATH" '{systemMessage: $msg}'
        break
    fi
done

exit 0
