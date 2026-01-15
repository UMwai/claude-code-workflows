# UM Loop Skill

Invoke with: `/um-loop` or `/um-loop start [task]`

## Description

An iterative development workflow for autonomous task completion. Uses a PRD (Product Requirements Document) with checkboxes to track progress, and a progress log to maintain state across iterations.

Based on the Ralph Wiggum technique - repeatedly working on the same task until all requirements are met, with state persisted to files.

## Core Principle

> "Each iteration starts fresh, but progress persists in files. The PRD is the contract, progress.md is the memory, and checkboxes are the scoreboard."

## The Three-File System

| File | Purpose | When to Update |
|------|---------|----------------|
| `PRD.md` | Requirements with checkboxes | Mark `[x]` when items complete |
| `progress.md` | Log of actions taken | Append after each significant action |
| `PROMPT.md` | Instructions for the agent | Usually unchanged after setup |

## Workflow Instructions

### Starting a New Loop

When user invokes `/um-loop start [task description]`:

1. Create `PRD.md` from template with the task description
2. Create `progress.md` initialized with start timestamp
3. Create `PROMPT.md` with autonomous agent instructions
4. Begin working on the first incomplete item

### Continuing an Existing Loop

When user invokes `/um-loop` (no start):

1. Read `PRD.md` to understand requirements
2. Read `progress.md` to see what's been done
3. Identify the next incomplete item (`- [ ]`)
4. Work on that item
5. Update files when done

### Each Iteration

Follow this cycle:

```
1. READ PRD.md        → Know what needs doing
2. READ progress.md   → Know what's been done
3. PICK next item     → First unchecked box
4. IMPLEMENT          → Do the work
5. VERIFY             → Test/check your work
6. UPDATE progress.md → Log what you did
7. UPDATE PRD.md      → Mark checkbox [x]
8. CHECK completion   → All boxes checked? → DONE
```

### Completion Detection

The loop is complete when:
- All `- [ ]` items in PRD.md are marked `- [x]`
- OR you write "DONE" in progress.md

When complete, output:
```
## UM Loop Complete

All PRD items have been completed. See progress.md for full log.
```

## Commands

| Command | Action |
|---------|--------|
| `/um-loop start [task]` | Initialize new loop with task |
| `/um-loop` | Continue existing loop (read state, do next item) |
| `/um-loop status` | Show PRD checkboxes and last progress entry |
| `/um-loop reset` | Clear progress.md, uncheck all PRD boxes |

## Critical Rules

1. **One item per iteration** - Complete one checkbox, then stop. User re-invokes to continue.
2. **Always update progress.md** - Every action gets logged. This is your memory.
3. **Never skip verification** - Test before marking complete.
4. **Leave codebase working** - Each iteration should be committable.
5. **Be honest about completion** - Only mark `[x]` when truly done.

## Example Session

```
User: /um-loop start Build a CLI calculator with add, subtract, multiply, divide

Claude:
1. Creates PRD.md:
   ## Objective
   Build a CLI calculator with add, subtract, multiply, divide

   ## Tasks
   - [ ] Set up project structure
   - [ ] Implement add operation
   - [ ] Implement subtract operation
   - [ ] Implement multiply operation
   - [ ] Implement divide operation
   - [ ] Add input validation
   - [ ] Add tests
   - [ ] Verify all operations work

2. Creates progress.md with timestamp
3. Creates PROMPT.md
4. Works on first item (project structure)
5. Updates progress.md: "Created calc.py with argparse setup"
6. Marks PRD: [x] Set up project structure
7. Reports completion of iteration

User: /um-loop

Claude:
1. Reads PRD.md - sees next item is "Implement add operation"
2. Reads progress.md - knows structure exists
3. Implements add
4. Tests it
5. Updates progress.md
6. Marks PRD checkbox
7. Reports completion

... continues until all boxes checked ...
```

## Integration with Manus Workflow

UM Loop focuses on **iteration and task completion**.
Manus Workflow focuses on **research and context persistence**.

Use together:
- Start with Manus for research/planning phase
- Switch to UM Loop for implementation phase
- Manus `notes.md` can inform UM Loop `PRD.md`

## When to Use

**Good for:**
- Well-defined tasks with clear deliverables
- Multi-step implementations
- Tasks that can be broken into checkboxes
- Iterative refinement

**Not good for:**
- Open-ended research (use Manus instead)
- Tasks requiring continuous human feedback
- One-shot operations

## Anti-Patterns (AVOID)

- Starting work without reading PRD.md first
- Marking checkboxes without verifying the work
- Trying to complete multiple items in one iteration
- Forgetting to update progress.md
- Leaving codebase in broken state between iterations
