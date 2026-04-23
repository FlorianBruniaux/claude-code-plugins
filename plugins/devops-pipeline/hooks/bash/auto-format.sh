#!/bin/bash
# PostToolUse hook - Auto-format files after editing
# Place in: .claude/hooks/auto-format.sh
# Register in: .claude/settings.json

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# Only run after Write or Edit operations
if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]]; then
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path')

    if [[ -z "$FILE" || "$FILE" == "null" ]]; then
        exit 0
    fi

    # Get file extension
    EXT="${FILE##*.}"

    case "$EXT" in
        js|jsx|ts|tsx|json|css|scss|md|html|vue)
            # Format with Prettier if available
            if command -v npx &> /dev/null && [[ -f "node_modules/.bin/prettier" ]]; then
                npx prettier --write "$FILE" 2>/dev/null
            fi
            ;;
        py)
            # Format with Black if available
            if command -v black &> /dev/null; then
                black "$FILE" 2>/dev/null
            fi
            ;;
        go)
            # Format with gofmt
            if command -v gofmt &> /dev/null; then
                gofmt -w "$FILE" 2>/dev/null
            fi
            ;;
        rs)
            # Format with rustfmt
            if command -v rustfmt &> /dev/null; then
                rustfmt "$FILE" 2>/dev/null
            fi
            ;;
    esac
fi

exit 0
