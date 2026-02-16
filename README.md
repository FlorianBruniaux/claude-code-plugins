# Claude Code Plugins

Production-ready plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) from the [Ultimate Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide).

## Available Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| [session-summary](./plugins/session-summary/) | Session analytics dashboard with 15 configurable sections | 3.0.0 |

## Quick Install

```bash
# 1. Add the marketplace
claude plugin marketplace add FlorianBruniaux/claude-code-plugins

# 2. Install a plugin
claude plugin install session-summary@florian-claude-tools
```

That's it. Hooks are auto-wired, no manual configuration needed.

## Managing Plugins

```bash
# List installed plugins
claude plugin list

# Check available plugins from this marketplace
claude plugin marketplace list florian-claude-tools

# Uninstall
claude plugin uninstall session-summary

# Remove marketplace
claude plugin marketplace remove florian-claude-tools
```

## Plugin Details

### session-summary

Displays a comprehensive analytics dashboard when your Claude Code session ends.

**15 configurable sections**: session metadata, duration, model usage, estimated cost, tool calls, error details, files touched, lines of code, features used, git diff, RTK savings, conversation ratio, thinking blocks, context window estimate, section order.

See [plugin README](./plugins/session-summary/README.md) for full documentation.

## Requirements

- Claude Code with plugin support
- `jq` (required for JSON parsing)
- `bc`, `ccusage`, `rtk`, `git` (optional, for enhanced sections)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on adding new plugins.

## License

MIT - See [LICENSE](./LICENSE)

## Links

- [Claude Code Ultimate Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) - Comprehensive documentation
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code) - Official docs
