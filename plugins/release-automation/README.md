# release-automation

Release workflow for Claude Code — generate changelogs, release notes in 3 formats (CHANGELOG.md, PR body, Slack), and social content (LinkedIn/Twitter/Newsletter) from git commits.

## What's included

**Commands (2)**: `/release-notes`, `/commit`

**Skills (2)**: release-notes-generator (CHANGELOG + PR + Slack), guide-recap (LinkedIn + Twitter + Newsletter + Slack)

**Hooks (1)**: validate-changes (LLM-as-a-Judge pre-commit gate)

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/release-automation
```

## Quick start

```
/release-notes           # Generate CHANGELOG, PR body, and Slack from git log
/guide-recap v3.20.0     # Generate LinkedIn + Twitter + Newsletter from CHANGELOG
```
