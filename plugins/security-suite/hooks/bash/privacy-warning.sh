#!/bin/bash
# privacy-warning.sh - Warn users about data sent to Anthropic
#
# Hook type: SessionStart
# Triggers: Once at the beginning of each Claude Code session
#
# Purpose:
#   Reminds users that their prompts, files, and MCP results are sent to Anthropic.
#   Provides link to opt-out of training data (reduces retention from 5 years to 30 days).
#
# Installation:
#   1. Copy to .claude/hooks/SessionStart/
#   2. Make executable: chmod +x privacy-warning.sh
#   3. Register in hooks config (see Claude Code docs)
#
# Configuration:
#   Set PRIVACY_WARNING_SHOWN=1 in your environment to suppress after first run.
#
# Reference: https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/data-privacy.md

# Only show once per terminal session
if [[ -n "$PRIVACY_WARNING_SHOWN" ]]; then
    exit 0
fi

# Output privacy reminder
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│  🔐 PRIVACY REMINDER                                           │"
echo "├─────────────────────────────────────────────────────────────────┤"
echo "│  Your prompts, files, and MCP results are sent to Anthropic.   │"
echo "│                                                                 │"
echo "│  Retention: 5 years (default) → 30 days (opt-out training)     │"
echo "│                                                                 │"
echo "│  Disable training: claude.ai/settings/data-privacy-controls    │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

# Mark as shown for this terminal session
export PRIVACY_WARNING_SHOWN=1

# Always exit 0 to allow session to continue
exit 0
