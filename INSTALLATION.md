# Installation Guide

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with plugin support
- `jq` installed (`brew install jq` on macOS)

## Plugin Install (Recommended)

```bash
# Step 1: Add the marketplace
claude plugin marketplace add FlorianBruniaux/claude-code-plugins

# Step 2: Install the plugin you want
claude plugin install session-summary@florian-claude-tools

# Step 3: Verify
claude plugin list
```

The plugin system handles hook registration automatically. No manual configuration needed.

## Verify Installation

After installing, start a new Claude Code session:

1. Run `/hooks` to see registered hooks — session-summary should appear with `[Plugin]` label
2. Use Claude Code normally
3. When you exit the session, the summary dashboard appears automatically

## Uninstall

```bash
claude plugin uninstall session-summary
```

## Manual Installation

If you prefer manual setup (without the plugin system), see the [Ultimate Guide hooks documentation](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/tree/main/examples/hooks).

## Troubleshooting

### Summary doesn't appear on session end
- Check `jq` is installed: `which jq`
- Check hooks are registered: `/hooks` in Claude Code
- Check for errors: `SESSION_SUMMARY_SKIP=0 bash -x ~/.claude/plugins/session-summary/scripts/session-summary.sh`

### RTK section shows "N/A"
- RTK auto-detects. Install RTK or set `SESSION_SUMMARY_RTK=0` to hide the section.

### Cost shows "$0.00"
- Install `ccusage` for accurate cost: `npm install -g ccusage`
- Without ccusage, the fallback pricing table estimates may be less accurate.
