---
name: eval-rules
description: "Audit .claude/rules/ files for structural correctness, glob validity, and real-world usefulness. Resolves each paths: pattern against actual project files, then asks the user whether each rule is still relevant and useful. Can update rules in-place based on answers. Use when setting up rules for the first time, debugging rules that fire too often or never, or doing a periodic rules hygiene pass."
allowed-tools: Read, Glob, Bash, Edit
effort: medium
argument-hint: [path to rules dir — default: .claude/rules/]
---

# Rules Evaluator

Discover all rule files, validate their structure and glob patterns against the real project, then run an interactive session to confirm (or improve) each rule with the user.

The goal is not just to score — it is to leave the rules directory in better shape than it was.

## When to Use

- First time writing `.claude/rules/` files (validate before committing)
- A rule seems to never trigger, or fires on every file
- Migrating `@` imports from CLAUDE.md to path-scoped rules
- Periodic hygiene: "are these rules still relevant to how we work?"
- After onboarding to a new codebase

## Key Concepts

| Mechanism | When it loads | Notes |
|---|---|---|
| `@file` in CLAUDE.md | Session start, always | Even inside a conditional sentence |
| No `paths:` in rule | Session start, always | Same cost as @import |
| `paths:` frontmatter | When Claude reads a matching file | Trigger = Read tool, not Write |

The `paths:` field is the main lever for keeping rules contextual. An always-on rule with 80 lines loads on every session even if you're fixing a typo in README.md.

---

## Scoring Criteria (12 pts per rule)

| # | Criterion | Max | What is checked |
|---|-----------|-----|-----------------|
| 1 | **frontmatter block** | 1 | File has YAML frontmatter (`---` delimited) |
| 2 | **paths: field** | 2 | Present (1pt) + at least one pattern listed (1pt) |
| 3 | **pattern validity** | 3 | Each pattern matches ≥1 file in project (up to 3 patterns checked) |
| 4 | **scope** | 2 | Not dead (≥1 match) + not too broad (<30% of project source files) |
| 5 | **content quality** | 3 | Has clear header/title (1pt) + rules are specific/actionable (1pt) + under 150 lines (1pt) |
| Bonus | **focus** | +1 | Under 15 rules in file |

**Thresholds:**
- ✅ Good: ≥10/12 (≥83%)
- ⚠️ Needs work: 7–9/12 (58–82%)
- ❌ Fix: <7/12 (<58%)

**Always-on rules** (no `paths:` field): skip criteria 2, 3, 4. Score on 5 pts max. Flag with 🔵 and go through the interactive step to decide if scoping is needed.

---

## Execution Instructions

### Step 1 — Discovery

Use Glob to find all rule files:

```
.claude/rules/**/*.md
```

If an argument was passed (e.g., `/eval-rules ./my-rules/`), use that path instead.

Also count total source files for scope % calculation:
```bash
find . \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.go" -o -name "*.rs" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
  2>/dev/null | wc -l
```

If no `.claude/rules/` directory exists, report it and stop.

### Step 2 — Parse each rule

For each `.md` file found:
1. Read the full file
2. Extract YAML frontmatter (content between first `---` and second `---`)
3. Parse `paths:` field — collect all glob patterns as a list
4. Classify: **conditional** (has `paths:`) or **always-on** (no frontmatter or no `paths:`)
5. Read the body: line count, presence of a clear title/header, whether rules are specific

### Step 3 — Resolve glob patterns

For each rule with `paths:`, use Glob to resolve each pattern against the project:

- Collect total matched files per pattern
- Show up to 10 sample paths
- Flag dead patterns (0 matches) and broad patterns (>30% of source files)

### Step 4 — Interactive review (core of the skill)

Process rules **one by one**. Do not batch and skip the interaction.

**For each conditional rule (has `paths:`):**

Show:
```
Rule: payments.md [conditional]
paths: ["**/payments/**", "src/billing/**"]
Matches: 12 files
  - src/payments/stripe.py
  - src/payments/webhook.py
  - src/billing/invoice.py
  ... (9 more)
```

Ask three questions:
1. "Is this scope right? (y = yes / n = needs adjustment)"
2. "Is this rule still useful day-to-day? (y / n / unsure)"
3. "Anything to add, remove, or update in the rule content? (describe or skip)"

**For each always-on rule (no `paths:`):**

Show:
```
Rule: database.md [always-on — loads every session]
Content: 91 lines, 8 rules
```

Ask:
1. "This rule loads at every session. Should it stay always-on, or be scoped to specific files? (keep / scope / skip)"
2. "Is the content still accurate and useful? (y / n)"

If the user says **scope**: help them define a `paths:` pattern based on the rule content (e.g., database rules → `**/models/**`, `**/migrations/**`, `**/*.sql`). Propose the frontmatter block and ask for confirmation before editing.

**If the user provides corrections or updates during the interaction**: apply them directly using Edit, confirm each change, then move to the next rule.

### Step 5 — Output report

After all rules are reviewed:

```
# Rules Audit — [project name or path]
Date: [today] | Scanned: N rules (X conditional, Y always-on)

## Summary

| Status | Count |
|--------|-------|
| ✅ Good (≥83%) | N |
| ⚠️ Needs work (58–82%) | N |
| ❌ Fix (<58%) | N |
| 🔵 Always-on (no paths:) | N |
| ✅ User confirmed useful | N |
| ⚠️ User flagged for update | N |
| 🗑️ User marked as stale | N |

---

## Per-Rule Results

### payments.md — 11/12 ✅ [conditional]

paths: `**/payments/**`, `src/billing/**`
Matches: 12 files (3.5% of 340 source files)

| Criterion | Score | Notes |
|-----------|-------|-------|
| frontmatter | ✅ 1/1 | — |
| paths: field | ✅ 2/2 | 2 patterns |
| pattern validity | ✅ 3/3 | All match ≥1 file |
| scope | ✅ 2/2 | 3.5% — well-scoped |
| content quality | ⚠️ 2/3 | 158 lines — over 150 |

User feedback: ✅ scope confirmed — "fires exactly when we work on Stripe"
Content: no changes needed

---

### database.md — 3/5 🔵 [always-on]

No paths: field — loads at every session.

| Criterion | Score | Notes |
|-----------|-------|-------|
| frontmatter | ❌ 0/1 | No frontmatter block |
| content quality | ✅ 3/3 | 91 lines, specific rules, clear header |
| focus | ✅ 1/1 | 8 rules |

User feedback: scope → added paths: ["**/models/**", "**/migrations/**", "**/*.sql"]
Edit applied ✅

---
```

### Step 6 — Fix Summary

```
## What Changed This Session

database.md:
  - Added frontmatter with paths: ["**/models/**", "**/migrations/**", "**/*.sql"]

testing.md:
  - User confirmed useful, no changes

git-workflow.md:
  - User flagged as stale — marked for deletion (not deleted yet, awaiting confirmation)

---
N rules audited · N edits applied · N rules flagged as stale
```

For any rule the user marked as stale or outdated: ask for explicit confirmation before deleting. Never delete without a clear "yes, delete it".

---

## Edge Cases

- **Subdirectory rules** (e.g., `.claude/rules/frontend/react.md`): discovered and processed normally
- **Invalid YAML frontmatter**: report parse error, score frontmatter as 0/1
- **Empty file**: flag as ❌, skip interactive step, ask if it should be deleted
- **Dead pattern** (0 matches): flag, suggest fix based on rule content
- **Pattern matching >30% of files**: flag as too broad, suggest narrowing
- **User says "unsure" about usefulness**: note it in the report, do not edit, add a comment "Review in next audit"
