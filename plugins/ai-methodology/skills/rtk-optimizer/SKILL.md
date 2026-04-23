---
name: rtk-optimizer
description: "Wrap high-verbosity shell commands with RTK to reduce token consumption. Use when running git log, git diff, cargo test, pytest, or other verbose CLI output that wastes context window tokens."
version: 1.0.0
tags: [optimization, tokens, efficiency, git]
effort: low
---

# RTK Optimizer Skill

**Purpose**: Automatically suggest RTK wrappers for high-verbosity commands to reduce token consumption.

## How It Works

1. **Detect high-verbosity commands** in user requests
2. **Suggest RTK wrapper** if applicable
3. **Execute with RTK** when user confirms
4. **Track savings** over session

## Supported Commands

### Git (>70% reduction)
- `git log` → `rtk git log` (92.3% reduction)
- `git status` → `rtk git status` (76.0% reduction)
- `find` → `rtk find` (76.3% reduction)

### Medium-Value (50-70% reduction)
- `git diff` → `rtk git diff` (55.9% reduction)
- `cat <large-file>` → `rtk read <file>` (62.5% reduction)

### JS/TS Stack (70-90% reduction)
- `pnpm list` → `rtk pnpm list` (82% reduction)
- `pnpm test` / `vitest run` → `rtk vitest run` (90% reduction)

### Rust Toolchain (80-90% reduction)
- `cargo test` → `rtk cargo test` (90% reduction)
- `cargo build` → `rtk cargo build` (80% reduction)
- `cargo clippy` → `rtk cargo clippy` (80% reduction)

### Python & Go (90% reduction)
- `pytest` → `rtk python pytest` (90% reduction)
- `go test` → `rtk go test` (90% reduction)

### GitHub CLI (79-87% reduction)
- `gh pr view` → `rtk gh pr view` (87% reduction)
- `gh pr checks` → `rtk gh pr checks` (79% reduction)

### File Operations
- `ls` → `rtk ls` (condensed output)
- `grep` → `rtk grep` (filtered output)

## Activation Examples

**User**: "Show me the git history"
**Skill**: Detects `git log` → Suggests `rtk git log` → Explains 92.3% token savings

**User**: "Find all markdown files"
**Skill**: Detects `find` → Suggests `rtk find "*.md" .` → Explains 76.3% savings

## Installation Check

Before first use, verify RTK is installed:
```bash
rtk --version  # Should output: rtk 0.16.0+
```

If not installed:
```bash
# Homebrew (macOS/Linux)
brew install rtk-ai/tap/rtk

# Cargo (all platforms)
cargo install rtk
```

## Usage Pattern

```markdown
# When user requests high-verbosity command:

1. Acknowledge request
2. Suggest RTK optimization:
   "I'll use `rtk git log` to reduce token usage by ~92%"
3. Execute RTK command
4. Track savings (optional):
   "Saved ~13K tokens (baseline: 14K, RTK: 1K)"
```

## Session Tracking

Optional: Track cumulative savings across session:

```bash
# At session end
rtk gain  # Shows total token savings for session (SQLite-backed)
```

## Edge Cases

- **Small outputs** (<100 chars): Skip RTK (overhead not worth it)
- **Already using Claude tools**: Grep/Read tools are already optimized
- **Multiple commands**: Batch with RTK wrapper once, not per command

## Configuration

Enable via CLAUDE.md:
```markdown
## Token Optimization

Use RTK (Rust Token Killer) for high-verbosity commands:
- git operations (log, status, diff)
- package managers (pnpm, npm)
- build tools (cargo, go)
- test frameworks (vitest, pytest)
- file finding and reading
```

## Metrics (Verified)

Based on real-world testing:
- `git log`: 13,994 chars → 1,076 chars (92.3% reduction)
- `git status`: 100 chars → 24 chars (76.0% reduction)
- `find`: 780 chars → 185 chars (76.3% reduction)
- `git diff`: 15,815 chars → 6,982 chars (55.9% reduction)
- `read file`: 163,587 chars → 61,339 chars (62.5% reduction)

**Average: 72.6% token reduction**

## Limitations

- 446 stars on GitHub, actively maintained (30 releases in 23 days)
- Not suitable for interactive commands
- Rapid development cadence (check for breaking changes)

## Recommendation

**Use RTK for**: git workflows, file operations, test frameworks, build tools, package managers
**Skip RTK for**: small outputs, quick exploration, interactive commands

## References

- RTK GitHub: https://github.com/rtk-ai/rtk
- RTK Website: https://www.rtk-ai.app/
- Evaluation: `docs/resource-evaluations/rtk-evaluation.md`
- CLAUDE.md template: `examples/claude-md/rtk-optimized.md`
