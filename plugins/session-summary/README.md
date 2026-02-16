# session-summary

Session analytics dashboard for Claude Code. Displays a comprehensive summary with 15 configurable sections when your session ends.

## What It Shows

| Section | Default | Description |
|---------|---------|-------------|
| Meta | on | Session ID, name, git branch |
| Duration | on | Wall time, active time, turns, exit reason |
| Models | on | Requests per model, tokens in/out, cache hit rate |
| Cost | on | Estimated cost (via ccusage or pricing table fallback) |
| Tools | on | Tool calls breakdown with success/error rates |
| Errors | on | Error details (tool name + truncated message) |
| Files | on | Files read/edited/created, top edited files |
| LOC | on | Lines of code written (via Edit/Write tools) |
| Features | on | MCP servers, agents, skills, teams, plan mode |
| Git | on | Diff summary (+/- lines, files changed) |
| RTK | auto | RTK token savings delta (if RTK installed) |
| Ratio | on | Interactive vs auto turns, avg time/turn |
| Thinking | off | Thinking blocks count |
| Context | off | Context window usage estimate |

## Installation

### Plugin System (Recommended)

```bash
# Add the marketplace
claude plugin marketplace add FlorianBruniaux/claude-code-plugins

# Install
claude plugin install session-summary@florian-claude-tools
```

Done. Hooks are auto-wired for `SessionStart` (RTK baseline) and `SessionEnd` (summary display).

### Manual Installation

See the [Ultimate Guide hooks section](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/tree/main/examples/hooks) for manual setup instructions.

## Configuration

### Via Environment Variables

All settings use the `SESSION_SUMMARY_` prefix:

```bash
# Disable a section
export SESSION_SUMMARY_GIT=0

# Enable an off-by-default section
export SESSION_SUMMARY_THINKING=1

# Skip summary entirely
export SESSION_SUMMARY_SKIP=1

# Custom log directory
export SESSION_SUMMARY_LOG_DIR=~/my-logs

# RTK: auto (default), 1 (force on), 0 (force off)
export SESSION_SUMMARY_RTK=auto
```

### Via Config CLI

The `session-summary-config.sh` script provides a CLI for persistent configuration:

```bash
# From the plugin scripts directory:
./session-summary-config.sh show              # Show current config
./session-summary-config.sh set git=0         # Disable git section
./session-summary-config.sh set thinking=1    # Enable thinking section
./session-summary-config.sh reset             # Reset to defaults
./session-summary-config.sh sections          # Show section order
./session-summary-config.sh sections "meta,duration,tools,cost"  # Minimal output
./session-summary-config.sh preview           # Demo output
./session-summary-config.sh log 10            # Last 10 session summaries
```

Config file location: `~/.config/session-summary/config.sh`

### Configuration Priority

`env vars > config file > defaults`

## Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| `jq` | Yes | JSON parsing (session transcript) |
| `bc` | No | Precise arithmetic for cost calculation |
| `ccusage` | No | Accurate cost calculation (falls back to pricing table) |
| `rtk` | No | Token savings tracking |
| `git` | No | Git diff summary section |

## Session Logs

Summaries are logged as JSONL at `~/.claude/logs/session-summaries.jsonl` for historical analysis.

View recent summaries:
```bash
./session-summary-config.sh log 5
```

## Links

- [Claude Code Ultimate Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) - Full documentation
- [Hook Examples](https://github.com/FlorianBruniaux/claude-code-ultimate-guide/tree/main/examples/hooks) - All hook templates
