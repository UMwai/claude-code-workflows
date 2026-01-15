---
description: "Start or continue UM Loop"
argument-hint: "start [TASK] | status | reset | (no args to continue)"
---

# UM Loop Command

You are now in UM Loop mode - an iterative task completion workflow.

## Parse Arguments

Check what the user requested:

---

### If "start [TASK]"
Initialize a new loop:

1. **Create PRD.md**:
   ```markdown
   # Product Requirements Document

   ## Objective
   [TASK DESCRIPTION FROM ARGUMENTS]

   ## Tasks
   - [ ] Task 1: [Break down the task into logical steps]
   - [ ] Task 2: [Continue breaking down]
   - [ ] Task 3: [Add more as needed]
   - [ ] Task N: Verify and finalize

   ## Constraints
   - Keep changes minimal and focused
   - Each task should be independently verifiable
   ```

   **Important:** Analyze the task and create appropriate checkbox items - don't just use generic placeholders.

2. **Create progress.md**:
   ```markdown
   # UM Loop Progress Log

   ## Session Started
   [CURRENT DATE/TIME]

   ## Objective
   [TASK DESCRIPTION]

   ---
   ```

3. **Begin first item** - Start working on the first checkbox

---

### If "status"
Check current progress:

1. Read PRD.md (if exists)
2. Read progress.md (if exists)
3. Report:
   - Total tasks (count all checkboxes)
   - Completed (count `[x]`)
   - Remaining (count `[ ]`)
   - Next item to work on

If no PRD.md: "No active UM Loop. Start with `/um-loop start [task]`"

---

### If "reset"
Reset the loop:

1. Confirm with user first: "Reset UM Loop? This will uncheck all items and clear progress."
2. If confirmed:
   - Change all `[x]` back to `[ ]` in PRD.md
   - Clear progress.md entries (keep header only)
   - Report: "UM Loop reset. All tasks unchecked."

---

### If No Arguments (Continue Mode)
Continue working on next item:

1. **Read PRD.md** - Understand requirements
2. **Read progress.md** - See what's done
3. **Find next `- [ ]`** - This is your target
4. **Implement it** - Do the work
5. **Verify** - Test your work
6. **Update progress.md** - Append what you did (with timestamp)
7. **Update PRD.md** - Mark `[ ]` → `[x]`
8. **Report** - Tell user what you completed

---

## Completion

When ALL checkboxes are `[x]`:
- Append "DONE" to progress.md
- Report: "UM Loop complete! All PRD items finished."

## Rules

- **One item per invocation** - Complete one checkbox, then stop
- **Always update both files** - PRD.md and progress.md
- **Verify before marking** - Only `[x]` when truly done
- **Leave code working** - Each iteration should be committable
