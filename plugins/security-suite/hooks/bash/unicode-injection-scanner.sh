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
# CONTENT_JQ_FILTER is kept separately (plain string) so the null-byte
# check further below can re-apply the same filter through a pure pipe,
# without going through the CONTENT variable (bash silently drops \0 on
# assignment via $()).
CONTENT=""
CONTENT_JQ_FILTER=""
case "$TOOL_NAME" in
    Write)
        CONTENT_JQ_FILTER='.content // empty'
        ;;
    Edit)
        CONTENT_JQ_FILTER='.new_string // empty'
        ;;
esac
CONTENT=$(echo "$TOOL_INPUT" | jq -r "$CONTENT_JQ_FILTER")

# Skip if no content
[[ -z "$CONTENT" ]] && exit 0

# === ZERO-WIDTH CHARACTERS ===
# U+200B Zero Width Space
# U+200C Zero Width Non-Joiner
# U+200D Zero Width Joiner
# U+FEFF Byte Order Mark (when not at start)
if echo "$CONTENT" | perl -C -0777 -ne 'exit(/[\x{200B}-\x{200D}\x{FEFF}]/ ? 0 : 1)'; then
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
if echo "$CONTENT" | perl -C -0777 -ne 'exit(/[\x{202A}-\x{202E}\x{2066}-\x{2069}]/ ? 0 : 1)'; then
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
# Portability note: same reasoning as prompt-injection-detector.sh - BSD
# grep has no -P, and bash drops \0 from any variable on assignment via
# $(), so checking "$CONTENT" would never work on any system. The correct
# check compares stream size (via pure pipe) before/after stripping NUL,
# using LC_ALL=C to operate byte by byte.
CONTENT_RAW_SIZE=$(echo "$TOOL_INPUT" | jq -r "$CONTENT_JQ_FILTER" | wc -c | tr -d ' ')
CONTENT_STRIPPED_SIZE=$(echo "$TOOL_INPUT" | jq -r "$CONTENT_JQ_FILTER" | LC_ALL=C tr -d '\000' | wc -c | tr -d ' ')
if [ "$CONTENT_RAW_SIZE" != "$CONTENT_STRIPPED_SIZE" ]; then
    echo "BLOCKED: Null byte detected. These can cause string truncation attacks." >&2
    exit 2
fi

# === TAG CHARACTERS ===
# U+E0000-U+E007F are invisible "tag" characters
# Sometimes used to embed hidden data
if echo "$CONTENT" | perl -C -0777 -ne 'exit(/[\x{E0000}-\x{E007F}]/ ? 0 : 1)'; then
    echo "BLOCKED: Unicode tag characters detected (U+E0000-E007F). These can embed invisible data." >&2
    exit 2
fi

# === OVERLONG UTF-8 SEQUENCES ===
# Detect potential overlong encodings (e.g., encoding '/' as C0 AF instead of 2F)
# These can bypass path filters
# Check for C0 or C1 bytes followed by 80-BF (overlong 2-byte sequences)
# Note: this check operates at the raw BYTE level, not on decoded
# codepoints (that is exactly the pattern that detects malformed UTF-8).
# That's why perl runs WITHOUT the -C flag: with -C it would decode the
# input as UTF-8 before matching, and \xC0 would then mean codepoint
# U+00C0 instead of the raw byte 0xC0.
if echo "$CONTENT" | perl -0777 -ne 'exit(/[\xC0-\xC1][\x80-\xBF]/ ? 0 : 1)'; then
    echo "BLOCKED: Overlong UTF-8 sequence detected. These can bypass security filters." >&2
    exit 2
fi

# === HOMOGLYPHS WARNING ===
# Detect Cyrillic characters that look like Latin (confusables)
# Common in typosquatting and filter bypass
# а (U+0430) vs a, е (U+0435) vs e, о (U+043E) vs o, etc.
HOMOGLYPHS_FOUND=false
if echo "$CONTENT" | perl -C -0777 -ne 'exit(/[\x{0430}\x{0435}\x{043E}\x{0440}\x{0441}\x{0445}]/ ? 0 : 1)'; then
    HOMOGLYPHS_FOUND=true
fi
if echo "$CONTENT" | perl -C -0777 -ne 'exit(/[\x{0391}-\x{03C9}]/ ? 0 : 1)' && echo "$CONTENT" | perl -C -0777 -ne 'exit(/[a-zA-Z]/ ? 0 : 1)'; then
    # Greek mixed with Latin
    HOMOGLYPHS_FOUND=true
fi

if [[ "$HOMOGLYPHS_FOUND" == "true" ]]; then
    # Warning only - could be legitimate multilingual content
    echo '{"systemMessage": "Warning: Potential homoglyph characters detected (Cyrillic/Greek mixed with Latin). Verify this is not an attempt to bypass filters."}'
fi

# All checks passed
exit 0
