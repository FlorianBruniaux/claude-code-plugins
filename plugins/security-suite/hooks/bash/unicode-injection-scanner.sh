#!/bin/bash
# =============================================================================
# Unicode Injection Scanner Hook
# =============================================================================
# Event: PreToolUse (runs before Edit/Write operations)
# Purpose: Detect invisible Unicode characters used for prompt injection
#
# This hook detects evasion techniques that embed invisible instructions:
#   - Zero-width characters (U+200B-U+200D, U+FEFF)
#   - RTL/LTR override (U+202A-U+202E, U+2066-U+2069)
#   - ANSI escape sequences (terminal injection)
#   - Null bytes (truncation attacks)
#   - Tag characters (U+E0000-U+E007F)
#
# Installation:
#   Add to .claude/settings.json:
#   {
#     "hooks": {
#       "PreToolUse": [{
#         "matcher": "Edit|Write",
#         "hooks": ["bash examples/hooks/bash/unicode-injection-scanner.sh"]
#       }]
#     }
#   }
#
# Exit codes:
#   0 = allow (no injection detected)
#   2 = block (injection detected, stderr message shown to Claude)
#
# References:
#   - CVE-2025-53109/53110: Unicode-based sandbox escape
#   - Arxiv 2509.22040: Prompt Injection on Coding Assistants
# =============================================================================

set -euo pipefail

# Read the hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

# Only check Edit and Write tools
case "$TOOL_NAME" in
    Edit|Write)
        ;;
    *)
        exit 0
        ;;
esac

# Extract content to analyze
CONTENT=""
case "$TOOL_NAME" in
    Write)
        CONTENT=$(echo "$TOOL_INPUT" | jq -r '.content // empty')
        ;;
    Edit)
        CONTENT=$(echo "$TOOL_INPUT" | jq -r '.new_string // empty')
        ;;
esac

# Skip if no content
[[ -z "$CONTENT" ]] && exit 0

# === ZERO-WIDTH CHARACTERS ===
# U+200B Zero Width Space
# U+200C Zero Width Non-Joiner
# U+200D Zero Width Joiner
# U+FEFF Byte Order Mark (when not at start)
if echo "$CONTENT" | grep -qP '[\x{200B}-\x{200D}\x{FEFF}]'; then
    echo "BLOCKED: Zero-width characters detected (U+200B-U+200D or BOM). These can hide malicious instructions." >&2
    exit 2
fi

# === BIDIRECTIONAL TEXT OVERRIDE ===
# U+202A Left-to-Right Embedding
# U+202B Right-to-Left Embedding
# U+202C Pop Directional Formatting
# U+202D Left-to-Right Override
# U+202E Right-to-Left Override (most dangerous - reverses text display)
# U+2066-U+2069 Isolate controls
if echo "$CONTENT" | grep -qP '[\x{202A}-\x{202E}\x{2066}-\x{2069}]'; then
    echo "BLOCKED: Bidirectional text override detected (U+202A-U+202E). These can disguise malicious commands." >&2
    exit 2
fi

# === ANSI ESCAPE SEQUENCES ===
# \x1b[ CSI (Control Sequence Introducer) - terminal control
# \x1b] OSC (Operating System Command)
# \x1b( Character set selection
# These can manipulate terminal display or execute commands
if echo "$CONTENT" | grep -qE $'\x1b\[|\x1b\]|\x1b\('; then
    echo "BLOCKED: ANSI escape sequence detected. These can manipulate terminal display." >&2
    exit 2
fi

# === NULL BYTES ===
# \x00 can truncate strings and bypass security checks
if echo "$CONTENT" | grep -qP '\x00'; then
    echo "BLOCKED: Null byte detected. These can cause string truncation attacks." >&2
    exit 2
fi

# === TAG CHARACTERS ===
# U+E0000-U+E007F are invisible "tag" characters
# Sometimes used to embed hidden data
if echo "$CONTENT" | grep -qP '[\x{E0000}-\x{E007F}]'; then
    echo "BLOCKED: Unicode tag characters detected (U+E0000-E007F). These can embed invisible data." >&2
    exit 2
fi

# === OVERLONG UTF-8 SEQUENCES ===
# Detect potential overlong encodings (e.g., encoding '/' as C0 AF instead of 2F)
# These can bypass path filters
# Check for C0 or C1 bytes followed by 80-BF (overlong 2-byte sequences)
if echo "$CONTENT" | grep -qP '[\xC0-\xC1][\x80-\xBF]'; then
    echo "BLOCKED: Overlong UTF-8 sequence detected. These can bypass security filters." >&2
    exit 2
fi

# === HOMOGLYPHS WARNING ===
# Detect Cyrillic characters that look like Latin (confusables)
# Common in typosquatting and filter bypass
# а (U+0430) vs a, е (U+0435) vs e, о (U+043E) vs o, etc.
HOMOGLYPHS_FOUND=false
if echo "$CONTENT" | grep -qP '[\x{0430}\x{0435}\x{043E}\x{0440}\x{0441}\x{0445}]'; then
    HOMOGLYPHS_FOUND=true
fi
if echo "$CONTENT" | grep -qP '[\x{0391}-\x{03C9}]' && echo "$CONTENT" | grep -qP '[a-zA-Z]'; then
    # Greek mixed with Latin
    HOMOGLYPHS_FOUND=true
fi

if [[ "$HOMOGLYPHS_FOUND" == "true" ]]; then
    # Warning only - could be legitimate multilingual content
    echo '{"systemMessage": "Warning: Potential homoglyph characters detected (Cyrillic/Greek mixed with Latin). Verify this is not an attempt to bypass filters."}'
fi

# All checks passed
exit 0
