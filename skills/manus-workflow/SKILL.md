# Manus Workflow Skill

Invoke with: `/manus` or `/manus-workflow`

## Description

Persistent markdown-based planning workflow inspired by Manus AI's context engineering approach. Uses three files as "working memory on disk" to maintain focus across many tool calls.

## Core Principle

> "Markdown is my working memory on disk. Since I process information iteratively and my active context has limits, Markdown files serve as scratch pads for notes, checkpoints for progress, and building blocks for final deliverables."

## The Three-File System

| File | Purpose | When to Update |
|------|---------|----------------|
| `task_plan.md` | Track phases, goals, and progress | After every significant action |
| `notes.md` | Store research, findings, context | After every 2-3 tool calls |
| `deliverable.md` | Final output/artifact | When synthesizing results |

## Workflow Instructions

### Phase 1: Initialize (ALWAYS do this first)

1. Create `task_plan.md` in the working directory:
   ```markdown
   # Task Plan

   ## Goal
   [Clear statement of the objective]

   ## Phases
   - [ ] Phase 1: Research/Discovery
   - [ ] Phase 2: Analysis/Planning
   - [ ] Phase 3: Implementation/Execution
   - [ ] Phase 4: Synthesis/Delivery

   ## Current Status
   Phase: 1
   Last Action: Initialized task plan
   Next Action: [First research step]

   ## Notes
   - Started: [timestamp]
   ```

2. Create empty `notes.md`:
   ```markdown
   # Research Notes

   ## Findings

   ## Key Insights

   ## Questions/Unknowns
   ```

### Phase 2: Execute with Checkpoints

**Critical Rule:** Before EVERY decision, read `task_plan.md` to keep goals in attention window.

**After every 2-3 tool calls:**
1. Append findings to `notes.md`
2. Update `task_plan.md` with:
   - Current status
   - Completed checkboxes
   - Next planned action

**On errors:**
1. Log the error in `notes.md` under a `## Errors` section
2. Update `task_plan.md` with what went wrong
3. NEVER repeat the same failed approach

### Phase 3: Synthesize

1. Read `notes.md` completely
2. Create `deliverable.md` with final output
3. Update all checkboxes in `task_plan.md` to complete
4. Add completion timestamp

## Activation Triggers

Use this workflow when:
- Task requires >5 tool calls
- Research or exploration is needed
- Multi-step implementation
- Information needs to persist across context

Skip this workflow when:
- Simple one-shot questions
- Single file edits
- Quick lookups

## Commands

- `/manus start [goal]` - Initialize new workflow with goal
- `/manus status` - Read current task_plan.md
- `/manus checkpoint` - Force save to notes.md and update plan
- `/manus complete` - Finalize and create deliverable

## Example Session Flow

```
User: /manus start Research best practices for API rate limiting

Claude:
1. Creates task_plan.md with goal and phases
2. Reads task_plan.md (goal in context)
3. Searches for rate limiting patterns
4. Updates notes.md with findings
5. Updates task_plan.md checkbox + status
6. Reads task_plan.md (goal refreshed)
7. Searches for implementation examples
8. Updates notes.md
9. Updates task_plan.md
... continues until complete ...
10. Reads notes.md
11. Creates deliverable.md with synthesis
12. Marks task_plan.md complete
```

## Anti-Patterns (AVOID)

- Starting complex work without creating task_plan.md
- Making >3 tool calls without updating notes.md
- Forgetting to read task_plan.md before decisions
- Repeating failed approaches without logging
- Skipping the deliverable synthesis step
