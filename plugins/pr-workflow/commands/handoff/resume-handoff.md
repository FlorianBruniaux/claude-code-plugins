---
description: "Load a handoff document and resume work from where a previous session left off. Parses scope, file references, completed work, and next steps, then confirms understanding before proceeding."
argument-hint: "<handoff-file-path>"
---

Read and load the handoff document at `$ARGUMENTS[0]`.

## Steps

1. **Read the file** at the provided path. If the path does not exist, list files in `claudedocs/handoffs/` and ask the user which one to load.

2. **Parse and confirm**:
   - Task and scope
   - Files involved (with line numbers)
   - Key discoveries
   - Work completed so far
   - Current status
   - Next steps (ordered)

3. **Confirm understanding**: Summarize what you have loaded in 3-5 bullet points. Ask: "Should I proceed with the next step, or do you want to adjust the plan first?"

4. **Do not start working** until the user confirms. The confirmation step is mandatory.

## Notes

- If the handoff file references commits (`commit: abc1234`), note them but do not re-run the work.
- If next steps are unclear or conflicting, flag it before proceeding.
- The "Work Done" section is the authoritative record of what has been completed. Trust it.
