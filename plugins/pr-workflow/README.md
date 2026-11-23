# pr-workflow

PR and issue lifecycle for Claude Code: structured planning (CEO + Eng gates), PR creation, code review, issue and PR triage, session handoffs.

## What's included

**Agents (3)**: planner, planning-coordinator, plan-challenger

**Skills (15)**: pr, review-pr, review-plan, plan-pipeline, plan-pipeline-start, plan-pipeline-ceo-review, plan-pipeline-eng-review, plan-pipeline-execute, plan-pipeline-validate, handoff-create, handoff-resume, handoff-update, pr-triage (4-phase PR review), issue-triage (3-phase backlog management)

**Hooks (2)**: file-guard, velocity-governor

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/pr-workflow
```

## Quick start

```
/plan-pipeline-start # 5-phase planning: PRD → design → decisions → research → metrics
/pr                  # Analyze changes + create well-structured PR
/pr-triage all       # 4-phase PR backlog review with validated comments
```
