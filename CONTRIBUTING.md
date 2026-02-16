# Contributing

## Adding a New Plugin

1. Create a directory under `plugins/your-plugin-name/`
2. Add the required structure:

```
plugins/your-plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── hooks/
│   └── hooks.json           # Hook definitions (auto-wired)
├── scripts/
│   └── your-script.sh       # Hook implementation
└── README.md                # Documentation
```

3. Register your plugin in `.claude-plugin/marketplace.json`:

```json
{
  "name": "your-plugin-name",
  "source": "./plugins/your-plugin-name",
  "description": "What it does",
  "author": { "name": "Your Name" },
  "keywords": ["relevant", "tags"],
  "category": "productivity",
  "license": "MIT"
}
```

4. Update the root `README.md` plugin table.

## Plugin Guidelines

- **Self-contained**: All scripts and resources within the plugin directory
- **Use `${CLAUDE_PLUGIN_ROOT}`**: For paths in `hooks.json` — never hardcode absolute paths
- **Graceful degradation**: Optional dependencies should be auto-detected, not required
- **Configuration via env vars**: Use a consistent prefix (e.g., `YOUR_PLUGIN_*`)
- **Bash 3.2+ compatible**: macOS ships with Bash 3.2, no associative arrays
- **Exit 0 on success**: Hooks must exit cleanly to not block Claude Code

## Quality Checklist

- [ ] `plugin.json` has name, description, version, author
- [ ] `hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` for script paths
- [ ] Scripts are executable (`chmod +x`)
- [ ] Scripts use `set -euo pipefail`
- [ ] Optional dependencies are auto-detected
- [ ] README documents all configuration options
- [ ] Tested with `claude --plugin-dir ./plugins/your-plugin-name`

## Submitting

1. Fork the repo
2. Create your plugin branch
3. Submit a PR with the plugin + updated marketplace.json + updated root README
