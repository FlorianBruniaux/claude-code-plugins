# session-tools

Session productivity for Claude Code — cost/token monitoring (ccboard), context catchup, voice refinement, MCP integration templates, config templates, and 11 session hooks.

## What's included

**Commands (8)**: `/catchup`, `/session-save`, `/check-cache-bugs`, `/diagnose`, `/routines-discover`, `/autoresearch`, `/learn-alternatives`, `/learn-quiz`, `/learn-teach`

**Skills (4)**: ccboard (TUI/Web dashboard), voice-refine, token-audit, mcp-integration-reference

**Hooks (11)**: session-summary dashboard, session-logger, rtk-auto-wrapper, smart-suggest, identity-reinjection, learning-capture, subagent-stop, tts-selective, and more

**Config templates**: MCP configs, team configs, modes, memory patterns

**Workflows**: memory-stack-integration, Remotion quickstart

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/session-tools
```

## Quick start

```
/catchup         # Restore context after /clear
/ccboard         # Launch cost/session/MCP monitoring dashboard
/diagnose        # Interactive troubleshooting for Claude Code issues
```
