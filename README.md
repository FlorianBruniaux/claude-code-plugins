# Claude Code Plugins

<table>
  <tr>
    <td width="64">
      <a href="https://www.florian.bruniaux.com/about/?utm_source=github&amp;utm_medium=readme&amp;utm_campaign=claude-code-plugins"><img src="https://cc.bruniaux.com/author.png" width="56" height="56" alt="Florian Bruniaux" /></a>
    </td>
    <td>
      <strong><a href="https://www.florian.bruniaux.com/about/?utm_source=github&amp;utm_medium=readme&amp;utm_campaign=claude-code-plugins">Florian BRUNIAUX</a></strong> &middot; AI Founding Engineer @ <a href="https://methode-aristote.fr/">Méthode Aristote</a><br />
      13 years from developer to CTO / VP Eng &middot; <a href="https://www.florian.bruniaux.com/blog/?utm_source=github&amp;utm_medium=readme&amp;utm_campaign=claude-code-plugins">Blog &#8599;</a> &middot; <a href="https://www.florian.bruniaux.com/projects/?utm_source=github&amp;utm_medium=readme&amp;utm_campaign=claude-code-plugins">Projects &#8599;</a>
    </td>
  </tr>
</table>

Production-ready plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) from the [Ultimate Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide). 212 templates across 8 focused plugins.

## StarMapper

<a href="https://starmapper.bruniaux.com/FlorianBruniaux/claude-code-plugins">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://starmapper.bruniaux.com/api/map-image/FlorianBruniaux/claude-code-plugins?theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://starmapper.bruniaux.com/api/map-image/FlorianBruniaux/claude-code-plugins?theme=light" />
    <img alt="StarMapper: see who stars this repo on a world map" src="https://starmapper.bruniaux.com/api/map-image/FlorianBruniaux/claude-code-plugins" />
  </picture>
</a>

## Quick Install

```bash
# 1. Add the marketplace
claude plugin marketplace add FlorianBruniaux/claude-code-plugins

# 2. Install the plugins you need
claude plugin install security-suite
claude plugin install devops-pipeline
claude plugin install release-automation
claude plugin install code-quality
claude plugin install pr-workflow
claude plugin install session-tools
claude plugin install ai-methodology
claude plugin install session-summary
```

That's it. Hooks are auto-wired, no manual configuration needed.

## Available Plugins

| Plugin | Description | Templates | Version |
|--------|-------------|-----------|---------|
| [security-suite](./plugins/security-suite/) | OWASP auditing, cyber-defense pipeline, 13 protective hooks | 29 | 1.0.0 |
| [devops-pipeline](./plugins/devops-pipeline/) | CI/CD, git worktrees, deploy automation, GitHub Actions | 50+ | 1.0.0 |
| [release-automation](./plugins/release-automation/) | Changelog, release notes (3 formats), social content | 20+ | 1.0.0 |
| [code-quality](./plugins/code-quality/) | SOLID refactoring, TDD, GoF patterns, 6 review agents | 30 | 1.0.0 |
| [pr-workflow](./plugins/pr-workflow/) | Planning gates, PR/issue triage, handoffs | 23 | 1.0.0 |
| [session-tools](./plugins/session-tools/) | ccboard monitoring, voice refinement, 11 session hooks | 40+ | 1.0.0 |
| [ai-methodology](./plugins/ai-methodology/) | Scaffolding, 6-stage talk pipeline, context-engineering | 45+ | 1.0.0 |
| [session-summary](./plugins/session-summary/) | Session analytics dashboard, 15 configurable sections | 1 | 3.0.0 |

## Plugin Details

### security-suite

Security auditing pipeline with OWASP checks, vulnerability scanning, and a 4-agent cyber-defense pipeline (anomaly detection → risk classification → threat reporting).

**Skills** (slash-invocable): `/security`, `/security-audit`, `/security-check`, `/update-threat-db`, `/sandbox-status`

**Agents**: security-auditor, security-patcher, anomaly-detector, log-ingestor, risk-classifier, threat-reporter

**Hooks (13)**: secrets scanner, prompt injection detector, dangerous actions blocker, sandbox validation, repo integrity scanner, MCP config integrity, security gate, and more

---

### devops-pipeline

CI/CD automation with git worktree isolation, full deploy pipeline, canary monitoring, and auto-format/test hooks. Auto-detects Python / Node / Rust stacks.

**Skills** (slash-invocable): `/ci-all`, `/ci-pipeline`, `/ci-status`, `/ci-tests`, `/canary`, `/land-and-deploy`, `/ship`, `/git-worktree`, `/commit`

**Hooks (8)**: auto-format (bash + PowerShell), test-on-change, typecheck-on-save, pre-commit-evaluator, auto-checkpoint, notification, setup-init

---

### release-automation

From `git log` to published release notes and social posts in one command. Generates CHANGELOG.md entries, PR descriptions, Slack announcements, LinkedIn posts, and newsletters.

**Skills** (slash-invocable): `/release-notes`, `/commit`

**Skills**: release-notes-generator, guide-recap

---

### code-quality

Code review and refactoring pipeline with 6 specialist agents and GoF design pattern reference. Enforces SOLID, detects N+1 and complexity issues, drives TDD cycles.

**Skills** (slash-invocable): `/refactor`, `/optimize`, `/generate-tests`, `/explain`, `/review-plan`, `/qa`, `/investigate`, `/sonarqube`

**Agents**: code-reviewer, refactoring-specialist, architecture-reviewer, test-writer, integration-reviewer, output-evaluator

---

### pr-workflow

Full PR lifecycle from idea to merged. CEO + Engineering planning gates enforce architecture review before any code is written. Includes backlog triage for PRs and issues.

**Skills** (slash-invocable): `/plan-pipeline-start`, `/plan-pipeline-ceo-review`, `/plan-pipeline-eng-review`, `/plan-pipeline-execute`, `/plan-pipeline-validate`, `/pr`, `/review-pr`, `/handoff-create`, `/handoff-resume`, `/handoff-update`

**Skills**: pr-triage, issue-triage

---

### session-tools

Session productivity toolkit: cost/token monitoring dashboard (ccboard), voice memo refinement, context restoration after `/clear`, and MCP integration templates.

**Skills** (slash-invocable): `/catchup`, `/session-save`, `/diagnose`, `/routines-discover`, `/autoresearch`

**Skills**: ccboard (TUI/Web dashboard), voice-refine, token-audit, mcp-integration-reference

**Hooks (11)**: session-summary, RTK auto-wrapper, smart-suggest, identity-reinjection, learning-capture, and more

---

### ai-methodology

Methodology advisor, 6-stage conference talk pipeline, landing page generator from any repo, skill scaffolding, and context-engineering reference patterns.

**Skills** (slash-invocable): `/methodology-advisor`, `/scaffold`, `/audit-codebase`, `/audit-agents-skills`

**Skills**: skill-creator, talk-pipeline (stages 1-6 + orchestrator), landing-page-generator, git-ai-archaeology, rtk-optimizer, pdf-generator

---

### session-summary

Displays a comprehensive analytics dashboard when your Claude Code session ends. 15 configurable sections: session metadata, duration, model usage, estimated cost, tool calls, files touched, git diff, RTK savings, and more.

See [plugin README](./plugins/session-summary/README.md) for full documentation.

## Managing Plugins

```bash
# List installed plugins
claude plugin list

# Disable/enable without uninstalling
claude plugin disable code-quality
claude plugin enable code-quality

# Update to latest version
claude plugin update security-suite

# Uninstall
claude plugin uninstall pr-workflow

# Remove marketplace
claude plugin marketplace remove florian-claude-tools
```

## Requirements

- Claude Code with plugin support
- `jq` (required for JSON parsing in hooks)
- `bc`, `ccusage`, `rtk`, `git` (optional, enhance certain features)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on adding new plugins.

<!-- BEGIN GENERATED RELATED PROJECTS -->
<!-- Source: https://github.com/FlorianBruniaux/FlorianBruniaux/blob/main/ecosystem/projects.json; project: claude-code-plugins -->
## Explore the ecosystem

These projects extend the workflow without duplicating this tool:

- **Learn with [Claude Code Ultimate Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide)**: the guide explains the decisions and trade-offs behind the installable templates.
- **Observe with [CCBoard](https://github.com/FlorianBruniaux/ccboard)**: the session-tools plugin already connects Claude Code workflows to CCBoard.
- **Optimize with [RTK](https://github.com/rtk-ai/rtk)**: the session-tools plugin already provides an RTK integration.
- **Validate with [ctxharness](https://github.com/FlorianBruniaux/ctxharness)**: check that installed instructions remain aligned with the codebase.

[Browse the complete open-source galaxy](https://github.com/FlorianBruniaux#open-source-galaxy)
<!-- END GENERATED RELATED PROJECTS -->

## License

MIT. See [LICENSE](./LICENSE)

## Links

- [Claude Code Ultimate Guide](https://cc.bruniaux.com): Full documentation
- [Ultimate Guide GitHub](https://github.com/FlorianBruniaux/claude-code-ultimate-guide): Source repo
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code): Official Anthropic docs
