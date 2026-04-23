#!/bin/bash
# Hook: Notification - macOS alerts with contextual sounds
# Plays different sound based on notification type
#
# Place in: .claude/hooks/notification.sh
# Register in: .claude/settings.json under Notification event
#
# Note: macOS only - requires afplay and osascript

set -e

# Read JSON from stdin
INPUT=$(cat)

# Extract message and title
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code Notification"')
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')

# Select sound based on context
select_sound() {
    local msg="$1"
    local msg_lower=$(echo "$msg" | tr '[:upper:]' '[:lower:]')

    # Success / Completion
    if echo "$msg_lower" | grep -qE "(completed|terminé|fini|done|success|réussi|validé|finished)"; then
        echo "/System/Library/Sounds/Hero.aiff"
        return
    fi

    # Error / Failure
    if echo "$msg_lower" | grep -qE "(error|erreur|failed|échec|échoué|problem|problème|failure)"; then
        echo "/System/Library/Sounds/Basso.aiff"
        return
    fi

    # Waiting / Permission
    if echo "$msg_lower" | grep -qE "(waiting|attente|permission|approval|input|question|prompt)"; then
        echo "/System/Library/Sounds/Submarine.aiff"
        return
    fi

    # Warning / Attention
    if echo "$msg_lower" | grep -qE "(warning|attention|caution|alert|avertissement)"; then
        echo "/System/Library/Sounds/Sosumi.aiff"
        return
    fi

    # Default
    echo "/System/Library/Sounds/Ping.aiff"
}

SOUND_FILE=$(select_sound "$MESSAGE")

# Play sound (in background to avoid blocking)
if [[ -f "$SOUND_FILE" ]]; then
    afplay "$SOUND_FILE" &
fi

# Display macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"\"" 2>/dev/null || true

exit 0
