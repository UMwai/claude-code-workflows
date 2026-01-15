---
description: "Start or continue UM Loop"
argument-hint: "[start TASK] or no args to continue"
---

# UM Loop Command

You are now in UM Loop mode - an iterative task completion workflow.

## If Arguments Include "start"

The user wants to START a new loop. Extract the task description from the arguments.

1. **Create PRD.md** in the current directory:
   ```markdown
   # Product Requirements Document

   ## Objective
   [INSERT TASK DESCRIPTION HERE]

   ## Tasks
   - [ ] Task 1: Initial setup/scaffolding
   - [ ] Task 2: Core implementation
   - [ ] Task 3: Add error handling
   - [ ] Task 4: Add tests
   - [ ] Task 5: Verify and finalize

   ## Constraints
   - Keep changes minimal and focused
   - Each task should be independently verifiable
   - Leave codebase in working state after each task
   ```

   Analyze the task and create appropriate checkbox items (not just the template).

2. **Create progress.md**:
   ```markdown
   # UM Loop Progress Log

   ## Session Started
   [CURRENT TIMESTAMP]

   ## Objective
   [TASK DESCRIPTION]

   ---
   ```

3. **Create PROMPT.md** with agent instructions (from templates)

4. **Begin first item** - Read PRD.md, work on first checkbox

## If No "start" Argument (Continue Mode)

1. **Read PRD.md** - Understand requirements
2. **Read progress.md** - See what's been done
3. **Find next `- [ ]` item** - This is your target
4. **Implement it** - Do the work
5. **Verify** - Test your work
6. **Update progress.md** - Append entry with timestamp
7. **Update PRD.md** - Mark `- [ ]` → `- [x]`
8. **Report** - Tell user what you completed

## Completion

When ALL checkboxes are `[x]`:
- Write "DONE" at end of progress.md
- Report: "UM Loop complete! All PRD items finished."

## Rules

- **One item per invocation** - Complete one checkbox, then stop
- **Always update both files** - PRD.md and progress.md
- **Verify before marking** - Only `[x]` when truly done
- **Leave code working** - Each iteration should be committable
