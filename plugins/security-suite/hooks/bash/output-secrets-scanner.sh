#!/bin/bash
# =============================================================================
# Output Secrets Scanner Hook
# =============================================================================
# Event: PostToolUse (runs after each tool execution)
# Purpose: Detect secrets that might leak in tool outputs
#
# This complements security-check.sh (which scans inputs). This hook scans
# outputs to catch secrets that Claude might inadvertently expose.
#
# Installation:
#   Add to .claude/settings.json:
#   {
#     "hooks": {
#       "PostToolUse": [{
#         "matcher": "",
#         "hooks": ["bash examples/hooks/bash/output-secrets-scanner.sh"]
#       }]
#     }
#   }
#
# What it detects:
#   - API keys (OpenAI, Anthropic, AWS, GCP, Azure, Stripe, etc.)
#   - Private keys and certificates
#   - Database connection strings with passwords
#   - GitHub/GitLab tokens
#   - JWT tokens
# =============================================================================

set -euo pipefail

# Read the hook input from stdin
INPUT=$(cat)

# Extract tool output from JSON (handle both formats)
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // .output // ""' 2>/dev/null || echo "")

# If no output or empty, exit cleanly
if [[ -z "$TOOL_OUTPUT" ]]; then
    exit 0
fi

# Secret patterns to detect
# Compat: bash 3.2 (macOS default) does not support 'declare -A'
# (associative arrays only exist from bash 4 onward). So names and
# regexes live in two PARALLEL indexed arrays, in the same order,
# instead of a single name->regex map.
SECRET_NAMES=(
    # API Keys
    "OpenAI API Key"
    "Anthropic API Key"
    "AWS Access Key"
    "AWS Secret Key"
    "GCP API Key"
    "Azure Key"
    "Stripe Key"
    "Twilio Key"
    "SendGrid Key"
    "Slack Token"
    "Discord Token"

    # Tokens
    "GitHub Token"
    "GitLab Token"
    "NPM Token"
    "PyPI Token"
    "JWT Token"
    "Heroku API Key"

    # Private Keys
    "Private Key"
    "PGP Private Key"

    # Database
    "Database URL with Password"
    "Redis URL with Password"

    # Generic (58% of leaked secrets are "generic" - GitGuardian 2025)
    "Generic API Key"
    "Generic Secret"
    "Generic Token"
    "Private Key Inline"

    # Environment Variable Leakage
    "Env Dump Command"
    "Proc Environ Access"
)

SECRET_REGEXES=(
    # API Keys
    "sk-[a-zA-Z0-9]{20,}"
    "sk-ant-[a-zA-Z0-9]{20,}"
    "AKIA[0-9A-Z]{16}"
    "[0-9a-zA-Z/+]{40}"
    "AIza[0-9A-Za-z_-]{35}"
    "[a-zA-Z0-9]{32,}"
    "(sk|pk)_(live|test)_[0-9a-zA-Z]{24,}"
    "SK[a-f0-9]{32}"
    "SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}"
    "xox[baprs]-[0-9a-zA-Z-]{10,}"
    "[MN][A-Za-z0-9]{23,}\.[A-Za-z0-9-_]{6}\.[A-Za-z0-9-_]{27}"

    # Tokens
    "(ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36,}"
    "glpat-[a-zA-Z0-9_-]{20,}"
    "npm_[a-zA-Z0-9]{36}"
    "pypi-[a-zA-Z0-9_-]{50,}"
    "eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*"
    "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"

    # Private Keys
    "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
    "-----BEGIN PGP PRIVATE KEY BLOCK-----"

    # Database
    "(postgres|mysql|mongodb)://[^:]+:[^@]+@"
    "redis://:[^@]+@"

    # Generic (58% of leaked secrets are "generic" - GitGuardian 2025)
    "(api[_-]?key|apikey|api[_-]?secret)['\"]?\s*[:=]\s*['\"]?[a-zA-Z0-9_-]{20,}"
    "(secret|password|passwd|pwd)['\"]?\s*[:=]\s*['\"]?[^\s'\"]{8,}"
    "(token|auth[_-]?token|access[_-]?token|bearer)['\"]?\s*[:=]\s*['\"]?[a-zA-Z0-9_-]{20,}"
    "['\"]?-----BEGIN[^-]+PRIVATE KEY-----"

    # Environment Variable Leakage
    "^(env|printenv|set)$"
    "/proc/self/environ|/proc/[0-9]+/environ"
)

DETECTED_SECRETS=()

# Check each pattern (walks both arrays by the same index)
i=0
while [ "$i" -lt "${#SECRET_NAMES[@]}" ]; do
    secret_type="${SECRET_NAMES[$i]}"
    pattern="${SECRET_REGEXES[$i]}"
    # -e isolates the pattern from option parsing: patterns like
    # "Private Key" start with "-----", and without -e grep treats them
    # as an unknown flag instead of a regex, never matching anything.
    if echo "$TOOL_OUTPUT" | grep -qiE -e "$pattern" 2>/dev/null; then
        DETECTED_SECRETS+=("$secret_type")
    fi
    i=$((i + 1))
done

# If secrets detected, warn via systemMessage
if [[ ${#DETECTED_SECRETS[@]} -gt 0 ]]; then
    SECRETS_LIST=$(printf ", %s" "${DETECTED_SECRETS[@]}")
    SECRETS_LIST=${SECRETS_LIST:2}  # Remove leading ", "

    WARNING_MSG="SECRET LEAK WARNING: Potential secrets detected in output: $SECRETS_LIST. Do NOT commit or share this output. Consider using environment variables or a secrets manager."

    echo "{\"systemMessage\": \"$WARNING_MSG\"}"
fi

# Always exit 0 (warn, don't block)
exit 0
