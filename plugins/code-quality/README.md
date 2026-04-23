# code-quality

Code quality pipeline for Claude Code — SOLID refactoring, TDD workflow, GoF design patterns, performance optimization, and 6 specialist review agents.

## What's included

**Agents (6)**: code-reviewer, refactoring-specialist, architecture-reviewer, test-writer, integration-reviewer, output-evaluator

**Commands (8)**: `/refactor`, `/optimize`, `/generate-tests`, `/explain`, `/review-plan`, `/qa`, `/investigate`, `/sonarqube`

**Skills (5)**: design-patterns (GoF reference + checklists), eval-skills, tdd-workflow, smart-explore, ast-grep-patterns

**Hooks (3)**: output-validator, governance-enforcement-hook, validate-changes

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/code-quality
```

## Quick start

```
/refactor      # SOLID violation detection + targeted improvements
/investigate   # Systematic root-cause debugging before any fix
/qa            # Diff-aware web app testing with fix-and-verify loop
```
