# Changelog

All notable changes to claude-code-plugins are documented here.

## [Unreleased]

### Security

- **security-suite 1.1.2 and code-quality 1.1.2: private key patterns never matched on macOS**: `pre-commit-secrets.sh`, `output-secrets-scanner.sh` (security-suite) and `output-validator.sh` (code-quality) passed patterns starting with `-----` to `grep` without `-e`; BSD grep read them as options, exited 2, and the error was hidden. Synced from the guide (#99): patterns go through `-e`, a grep error above exit 1 now blocks the commit or warns instead of passing as "no secret". The Discord token class `[A-Za-z0-9-_]`, an invalid range for BSD grep, is now `[A-Za-z0-9_-]`, so the scanner no longer reports an incomplete scan on every output. `output-validator.sh` keeps the portable `#!/usr/bin/env bash` shebang. Checked on macOS: private key flagged by all three hooks, staged key blocked, clean output silent.
- **security-suite 1.1.1: `security-check` and `security-audit` cited `npx mcp-scan` as Snyk's scanner**: that npm name belongs to an unrelated author, and Invariant's scanner was renamed to the PyPI package `snyk-agent-scan`. Synced from the guide: both skills now cite `uvx snyk-agent-scan@latest`.
- **session-tools 1.1.1 and code-quality 1.1.1: `diagnose` skill pointed at a foreign GitHub account**: the skill fetched the guide and piped `audit-scan.sh` into `bash` from `flobby41/claude-code-ultimate-guide`, an account unrelated to the guide whose repository returns 404. Whoever controls that account could have created the repository and run arbitrary code on every machine that used the skill. All URLs now point to `FlorianBruniaux/claude-code-ultimate-guide`, matching the guide source.
- **`diagnose` no longer pipes a moving branch into bash**: synced from the guide, step 3 downloads `audit-scan.sh` from a pinned commit to a temporary file and reports failures instead of hiding them; step 2 extracts the guide's Section 10.4 by heading, which the previous 3,000-line cut never reached.
- **session-tools 1.1.2: `config/mcp.json` template named packages its maintainers do not publish**: Serena launched through `uvx serena`, a PyPI project from another author, and the Sequential Thinking and Playwright entries cited `@anthropic/sequential-thinking-mcp` and `@anthropic/playwright-mcp`, unpublished in an npm scope that holds unrelated packages. Whoever publishes under those names would run on every machine that copied the template. Synced from the guide: Serena runs as `serena start-mcp-server` after `uv tool install -p 3.13 serena-agent`, and the two others are `@modelcontextprotocol/server-sequential-thinking` and `@playwright/mcp`. The plugin does not load this file automatically.

### Changed

- **ai-methodology 1.2.0: `git-ai-archaeology` v2**, synced from the guide (`examples/skills/git-ai-archaeology/`): one-pass `scripts/harness_archaeology.py` (file lifecycles, copies and propagations, AI-trailer usage, unmerged harness work), a reading grid in `references/`, routing scenarios in `evals/`, and a six-step `SKILL.md` with completion criteria.
- **Resync with the guide examples at `650559c6` (Claude Code 2.1.330 pass)**: every plugin file that still matched an earlier guide version was replaced by the current one, about 170 files. Hook fixes: `file-guard.sh` (pr-workflow) now blocks with exit 2 and a stderr message instead of exit 1, which never blocked; `output-validator.sh` (code-quality) reads `tool_input.content` / `tool_response` because PostToolUse sends no `tool_output`; `governance-enforcement-hook.sh` (code-quality) returns one `systemMessage` JSON; `tts-selective.sh` (session-tools) reads `.message`; `file-guard-mcp.sh` (security-suite) works with `shasum` on macOS and its URL check now matches. Skill fixes: `Task` renamed `Agent`, frontmatter corrected, escaped `\$N` in skill bodies, grep `--include` braces. Portable `#!/usr/bin/env bash` shebangs are kept.
- **Skills moved to the one-directory-per-skill layout** (minor bumps): the flat files `pdf-generator.md` (ai-methodology), `tdd-workflow.md`, `smart-explore.md`, `ast-grep-patterns.md` (code-quality), `security-checklist.md` (security-suite) and `token-audit/skill.md` (session-tools) became `<name>/SKILL.md`, and the nested talk pipeline (`talk-pipeline/stage-N-x/`) became the top-level skills `talk-stage1-extract` to `talk-stage6-revision`, with the orchestrator as `talk-pipeline/SKILL.md`. The documented plugin layout is one `skills/<name>/SKILL.md` per skill. `pr-triage` gains `references/worktree-setup.md`.
- **Plugin READMEs list skills, not commands**: the stale `Commands` sections (`/ci:all`, `/plan-start` and others) are folded into the skills lists with the current names and counts. The leftover `devops-pipeline/commands/ci/README.md` is removed, since `commands/` loads every markdown file there as a command.
- Plugin versions: ai-methodology 1.3.0, code-quality 1.2.0, security-suite 1.2.0, session-tools 1.2.0, devops-pipeline 1.1.1, pr-workflow 1.1.1, release-automation 1.1.1, session-summary 3.1.1. The marketplace version stays at 2.2.0 until the next release is cut.

### Kept as local adaptations

- `learning-capture.sh` (ai-methodology), `governance-enforcement-hook.sh` (security-suite) and `session-summary-config.sh` (session-summary) still differ from the guide on purpose; only the model name in the `session-summary-config.sh` sample output was synced.

## [2.2.0] - 2026-10-28

### Summary

Resync with the Claude Code Ultimate Guide `examples/` catalog, which is the source of truth for these templates. A plugin file was updated only when it matched an earlier version of its guide source exactly; files carrying a local adaptation were kept.

### Changed

- **214 templates refreshed** across all eight plugins (agents, skills, hooks, scripts and references) to their current guide versions. `file-guard.sh` (pr-workflow) and `prompt-injection-detector.sh` (security-suite) take the guide fixes while keeping the portable `#!/usr/bin/env bash` shebang; the detector now checks decoded JSON strings for NUL bytes with `jq` instead of `grep -P`, which BSD grep on macOS does not support.
- **51 commands migrated to skills**, as in the guide since Claude Code 2.1.3: each command whose guide source became a pointer to a skill is replaced by that skill (33 skills added, the others already present). Renamed invocations: `/ci:all`, `/ci:pipeline`, `/ci:status`, `/ci:tests` become `/ci-all`, `/ci-pipeline`, `/ci-status`, `/ci-tests`; the handoff commands become `/handoff-create`, `/handoff-resume`, `/handoff-update`; the plan pipeline steps become `/plan-pipeline-start`, `/plan-pipeline-ceo-review`, `/plan-pipeline-eng-review`, `/plan-pipeline-execute`, `/plan-pipeline-validate`. The README lists them as skills.
- Plugin versions: session-summary 3.1.0, the seven others 1.1.0; marketplace 2.2.0.

### Kept as local adaptations

- `learning-capture.sh` (ai-methodology), `governance-enforcement-hook.sh` (security-suite) and `session-summary-config.sh` (session-summary) differ from every guide version and stay as they were. Six scripts whose only difference is the portable shebang are unchanged.

## [2.1.0] - 2026-06-04

### Summary

31 new skills ported from the Claude Code Ultimate Guide catalog, bringing the total to 212 templates across 8 plugins. This release also includes a hooks compatibility update for Claude Code >= 2.1 and a skills quality pass.

### New Skills

**devops-pipeline** (+11): ci-all, ci-pipeline, ci-status, ci-tests, canary, land-and-deploy, sandbox-status, git-worktree, git-worktree-clean, git-worktree-remove, git-worktree-status

**code-quality** (+5): validate-changes, audit-codebase, check-cache-bugs, recipe-template, diagnose

**session-tools** (+6): explain, handoff-create, handoff-resume, handoff-update, session-save, catchup

**ai-methodology** (+5): eval-agents, eval-hooks, methodology-advisor, autoresearch, routines-discover

**pr-workflow** (+3): plan-pipeline, review-plan, review-pr

**release-automation** (+1): release-notes

### Fixes and Improvements

- **Hooks compatibility**: migrate all hooks.json to record format required by Claude Code >= 2.1
- **Skills quality pass**: em dashes removed, allowed-tools format corrected, effort levels and trigger phrasing audited
- **eval-rules and eval-skills**: updated from guide source with latest content

### Statistics

- Templates: 181 → 212
- New skills: 31
- Plugins updated: 6/8

---

## [2.0.0] - 2026-05-XX

### Summary

Initial public release. 7 focused plugins with 181 templates covering DevOps, security, code quality, PR workflow, session tooling, release automation, and AI methodology.

### Plugins

- **security-suite**: OWASP auditing, cyber-defense pipeline, 13 protective hooks
- **devops-pipeline**: CI/CD, git worktrees, deploy automation, GitHub Actions
- **release-automation**: Changelog, release notes (3 formats), social content
- **code-quality**: SOLID refactoring, TDD, GoF patterns, 6 review agents
- **pr-workflow**: Planning gates, PR/issue triage, handoffs
- **session-tools**: ccboard monitoring, voice refinement, 11 session hooks
- **ai-methodology**: Scaffolding, 6-stage talk pipeline, context-engineering
- **session-summary**: Session analytics dashboard, 15 configurable sections
