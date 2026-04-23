#!/bin/bash
echo -e "\n=== Claude Code Health Check ==="
echo -e "\n--- Node & npm ---"
node --version
npm --version

echo -e "\n--- Claude Installation ---"
which claude
if [ $? -eq 0 ]; then
    echo "✓ Claude found in PATH"
else
    echo "✗ Claude not in PATH"
fi

echo -e "\n--- Running Claude Doctor ---"
if claude doctor; then
    echo "✓ Claude doctor completed"
else
    echo "✗ Claude doctor failed"
fi

echo -e "\n--- API Key Status ---"
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "✓ ANTHROPIC_API_KEY is set"
else
    echo "✗ ANTHROPIC_API_KEY not set"
fi

echo -e "\n--- Privacy Reminder ---"
echo "⚠️  Your prompts and file contents are sent to Anthropic"
echo "   Default retention: 5 years (training) | Opt-out: 30 days"
echo "   → Disable training: https://claude.ai/settings/data-privacy-controls"

echo -e "\n--- MCP Servers ---"
claude mcp list

echo -e "\n--- Config Location ---"
if [ -f ~/.claude.json ]; then
    echo "✓ Config found at: ~/.claude.json"
else
    echo "⚠ No config file at: ~/.claude.json"
fi

echo -e "\n=== Health Check Complete ==="
