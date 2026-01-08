# Manus AI Workflow Reference

## Origins

This workflow is reverse-engineered from Manus AI, the autonomous AI agent that gained attention for completing complex multi-step tasks reliably. The key insight: **externalize working memory to files**.

## Why This Works

### The Context Problem

LLMs have limited attention windows. During complex tasks with many tool calls:
- Goals drift out of context
- Earlier findings are forgotten
- Decisions become inconsistent
- Errors get repeated

### The Solution: File-Based Memory

By writing state to markdown files and reading them before decisions:
- Goals stay in the attention window
- Findings persist across tool calls
- Progress is trackable and resumable
- Errors are logged and avoided

## Core Principles

### 1. Read Before Decide

> Before every significant decision, read `task_plan.md` to refresh the goal in your context.

This is the most important principle. It prevents goal drift during long task sequences.

### 2. Write After Learn

> After every 2-3 tool calls, append findings to `notes.md`.

Don't rely on context to remember research. Externalize immediately.

### 3. Log All Errors

> Every error gets logged with cause and attempted resolution.

This prevents repeating failures and creates a debugging trail.

### 4. Never Repeat Failures

> If an approach failed, you must try something different.

Check the error log before retrying anything.

### 5. Synthesize Don't Dump

> The deliverable should be a synthesis, not a copy of notes.

Read all notes, then create a coherent output document.

## Technical Implementation

### Why Markdown?

- Human-readable (users can inspect progress)
- Structured enough for parsing
- Claude handles it natively
- Git-friendly for versioning
- No dependencies

### File Locations

Default: Current working directory
Alternative: `.manus/` subdirectory for cleaner projects

### Context Budget

Reading these files uses context tokens. Keep files focused:
- `task_plan.md`: ~500 tokens max
- `notes.md`: ~2000 tokens max (archive if larger)
- `deliverable.md`: As needed for output

## Comparison to Other Approaches

| Approach | Pros | Cons |
|----------|------|------|
| **Manus Files** | Persistent, inspectable, simple | File I/O overhead |
| **TodoWrite** | Integrated, structured | Less flexible, limited detail |
| **Memory MCP** | Sophisticated | Complex setup, external dependency |
| **System Prompt** | Always in context | Static, no state updates |

## Advanced Patterns

### Archiving Notes

When `notes.md` exceeds ~2000 tokens:
1. Summarize key findings at top
2. Move detailed sections to `notes_archive.md`
3. Reference archive in main notes

### Multiple Deliverables

For projects with multiple outputs:
```
deliverable_api.md
deliverable_tests.md
deliverable_docs.md
```

### Resumable Sessions

If interrupted, the workflow resumes by:
1. Reading `task_plan.md` for current state
2. Checking incomplete checkboxes
3. Reading `notes.md` for context
4. Continuing from last action

## Sources

- [Original Reddit Post](https://www.reddit.com/r/ClaudeAI/comments/1q2p03x/i_reverseengineered_the_workflow_that_made_manus/)
- [Manus Technical Analysis](https://gist.github.com/renschni/4fbc70b31bad8dd57f3370239dccd58f)
- [Planning with Files Repo](https://github.com/OthmanAdi/planning-with-files)
