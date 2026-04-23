---
name: eval-skills
description: "Audit all skills in the current project for frontmatter completeness, effort level appropriateness, allowed-tools scoping, and content quality. Produces a scored report with effort-level recommendations for each skill. Use when onboarding to a new project, reviewing skill quality before shipping, or adding effort fields to an existing skill library."
allowed-tools: Read, Glob, Bash
effort: medium
---

# Skill Evaluator

Discover all skills in the project, score them across 6 criteria, and infer the appropriate `effort` level based on content analysis.

## When to Use

- New project: run once to establish baseline quality
- Before committing a skill to a team repo
- After bulk-importing skills from another project
- When adding `effort` fields for the first time (v2.1.80+)

## What Gets Audited

All `SKILL.md` files and flat `.md` files found in:
- `.claude/skills/**`
- `~/.claude/skills/**` (if requested)
- Any path passed as argument: `/eval-skills ./my-skills-dir`

---

## Scoring Criteria (14 pts per skill)

| # | Criterion | Max | What is checked |
|---|-----------|-----|-----------------|
| 1 | **name** | 1 | Present, lowercase, hyphens only, matches directory name |
| 2 | **description** | 2 | Present + has "Use when" / "when to" / trigger phrasing |
| 3 | **allowed-tools** | 2 | Present + not overly broad (Bash without scoping when read-only) |
| 4 | **effort** | 3 | Present (1pt) + appropriate for content (2pt based on inference) |
| 5 | **content structure** | 4 | Has Purpose/When section (1), has examples/usage (1), has clear workflow (1), no placeholder text (1) |
| 6 | **bonus** | +2 | argument-hint present (1), version/author metadata (1) |

> **Note**: `tags` is NOT an officially supported frontmatter field in Claude Code. It is ignored by the runtime. Do not include it or score it as a quality criterion.

**Thresholds:**
- ✅ Good: ≥11/14 (≥80%)
- ⚠️ Needs work: 8–10/14 (60–79%)
- ❌ Fix: <8/14 (<60%)

---

## Effort Level Inference Engine

For each skill, analyze description + content and classify using these signals:

### `low` — Mechanical execution, no design decisions

Signals:
- Verbs: commit, push, sync, scaffold, generate (template-based), format, rename, bump, wrap, convert
- No reasoning required: sequential steps, template instantiation, data fetching
- allowed-tools: Bash only, or Read-only
- No sub-agents spawned
- Short workflow (<5 steps)

Examples: `/commit`, `/release-notes`, `/scaffold`, `/sync`, `/format`

### `medium` — Analysis with bounded scope, categorization

Signals:
- Verbs: review, triage, analyze, categorize, suggest, evaluate (single file or bounded scope)
- Requires pattern recognition but not architectural reasoning
- allowed-tools: Read + Grep + Bash combination
- May spawn 1-2 sub-agents but with predefined scope
- Produces structured output (tables, categorized lists)

Examples: `/code-review` (single PR), `/issue-triage`, `/dependency-audit`, `/test-coverage`

### `high` — Design decisions, adversarial reasoning, cross-system analysis

Signals:
- Verbs: architect, redesign, threat-model, audit (security), orchestrate (multi-agent), score, assess trade-offs
- Requires reasoning about edge cases, attack vectors, or system-wide implications
- allowed-tools: broad access (Read + Write + Bash + external tools)
- Spawns multiple sub-agents or uses parallel execution
- Produces analysis with explicit uncertainty or trade-off sections
- Keywords in content: "security", "architecture", "adversarial", "pipeline", "threat", "design decision"

Examples: `/security-audit`, `/architecture-review`, `/cyber-defense`, `/eval-agents`

### Mismatch flag

If a skill has `effort:` already set but the inferred level differs, flag it:
> ⚠️ Effort mismatch: declared `low`, inferred `high` — skill spawns 4 sub-agents and performs security analysis

---

## Execution Instructions

### Step 1 — Discovery

```bash
# Find all SKILL.md files
find .claude/skills -name "SKILL.md" 2>/dev/null

# Find flat skill files
find .claude/skills -maxdepth 1 -name "*.md" ! -name "README*" 2>/dev/null

# If argument provided, use that path instead
```

### Step 2 — Parse each skill

For each skill file found:
1. Read the full file
2. Extract YAML frontmatter (between first `---` and second `---`)
3. Parse: name, description, allowed-tools, effort, argument-hint, version
4. Note presence/absence of each field
5. Read the body content for structure analysis

### Step 3 — Score and infer

Apply the scoring criteria above to each skill:
- Check frontmatter fields
- Evaluate description quality (does it answer "when to use"? is it under 1024 chars?)
- Evaluate allowed-tools scope (is Bash used when only Read would suffice? are tools scoped with wildcards when possible?)
- Infer effort level from content analysis
- Compare inferred vs declared effort (if set)
- Evaluate content structure (scan for "When to Use", "Purpose", "Example", "Workflow" sections)

### Step 4 — Output

Produce a structured report:

```
# Skills Audit — [project name or path]
Date: [today] | Scanned: N skills

## Summary
| Status | Count |
|--------|-------|
| ✅ Good (≥80%) | N |
| ⚠️ Needs work (60–79%) | N |
| ❌ Fix (<60%) | N |

**Effort coverage**: N/N skills have effort field set

---

## Per-Skill Results

### [skill-name] — [score]/15 [✅/⚠️/❌]

| Criterion | Score | Notes |
|-----------|-------|-------|
| name | ✅ 1/1 | — |
| description | ⚠️ 1/2 | Missing "Use when" phrasing |
| allowed-tools | ✅ 2/2 | Well-scoped |
| effort | ❌ 0/3 | Missing — Recommended: high |
| content structure | ⚠️ 2/4 | No examples section |

**Effort inference**: `high` — skill performs security analysis with adversarial reasoning
  Signals: "threat", "attack surface", "vulnerability scoring" in content; spawns 4 agents

**Priority fixes** (ordered by impact):
1. Add `effort: high` to frontmatter
2. Add "Use when" to description
3. Add a concrete usage example section

---
```

After all skills: print a **Fix Summary** — all missing effort fields with recommended values, ready to copy-paste.

---

## Fix Summary Format

At the end, print a ready-to-use patch block for all missing/mismatched effort fields:

```
## Recommended effort fields (copy-paste ready)

skill-name-1: effort: low     # mechanical scaffold
skill-name-2: effort: high    # security analysis, spawns agents
skill-name-3: effort: medium  # code review, bounded scope
```

And a 1-line count: `N skills need effort field · N mismatches · N missing allowed-tools`
