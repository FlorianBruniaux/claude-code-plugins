# devops-pipeline

CI/CD automation for Claude Code: git worktrees, deploy pipeline, canary monitoring, auto-format/test hooks, and GitHub Actions templates.

## What's included

**Hooks (8)**: auto-format (bash + PowerShell), test-on-change, typecheck-on-save, pre-commit-evaluator, auto-checkpoint, notification, setup-init

**Workflows**: database-branch-setup

**Skills (13)**: ci-all, ci-pipeline, ci-status, ci-tests, canary, land-and-deploy, ship, commit, sandbox-status, git-worktree, git-worktree-clean, git-worktree-remove, git-worktree-status

**GitHub Actions templates**, **integrations**, and **utility scripts**

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/devops-pipeline
```

## Quick start

```
/ci-all          # Full local CI (tests + typecheck + push + pipeline URL)
/ship            # Pre-deployment verification checklist
/land-and-deploy # Merge PR → wait CI → verify deploy → canary
```
