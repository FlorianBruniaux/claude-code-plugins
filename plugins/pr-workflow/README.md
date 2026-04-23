# pr-workflow

PR and issue lifecycle for Claude Code — structured planning (CEO + Eng gates), PR creation, code review, issue and PR triage, session handoffs.

## What's included

**Commands (9)**: `/pr`, `/review-pr`, `/plan-start`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-execute`, `/plan-validate`, `/review-plan`, handoff commands (create/resume/update)

**Agents (3)**: planner, planning-coordinator, plan-challenger

**Skills (2)**: pr-triage (4-phase PR review), issue-triage (3-phase backlog management)

**Hooks (2)**: file-guard, velocity-governor

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/pr-workflow
```

## Quick start

```
/plan-start          # 5-phase planning: PRD → design → decisions → research → metrics
/pr                  # Analyze changes + create well-structured PR
/pr-triage all       # 4-phase PR backlog review with validated comments
```
