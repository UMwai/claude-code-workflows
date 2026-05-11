---
description: "Autonomous task completion loop v3.0"
argument-hint: "[TASK] | status | cancel | --init | --config | --prd FILE | --from-issues FILTER | --parallel"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)", "Read", "Write", "Edit", "Glob", "Grep", "Bash", "Task"]
---

# UM Loop Command v3.0

Parse the arguments to determine the action:

## Argument Routing

Check `$ARGUMENTS` for these patterns:

---

### If "status" or "--status"

Show current loop status:

1. Check if `.claude/um-loop.local.md` exists
2. If exists:
   - Read iteration count from state file
   - Read PRD.md and count checkboxes
   - Read v3.0 features (parallel, branch-per-task, multi-model)
   - Show: iteration N, X/Y tasks complete, features enabled, next task
3. If not exists: "No active UM Loop. Start with `/um-loop [task]`"

---

### If "cancel" or "--cancel"

Cancel active loop:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/cancel-um-loop.sh"
```

---

### If "--init"

Initialize project config:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/init-config.sh"
```

---

### If "--config"

Show current config:

1. Check if `.um-loop/config.yaml` exists
2. If exists: display the file contents with highlights for v3.0 features
3. If not: "No config found. Run `/um-loop --init` to create one."

---

### If "--add-rule" followed by text

Add a rule to config:

1. Check if `.um-loop/config.yaml` exists (create with --init if not)
2. Append the rule under the `rules:` section
3. Confirm: "Added rule: [rule text]"

---

### If "--from-issues" followed by filter

Pull GitHub issues into PRD:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/github-sync.sh" pull --labels "FILTER" --prd PRD.md
```

Or for specific issues:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/github-sync.sh" pull --issues "FILTER" --prd PRD.md
```

Then start the loop with the generated PRD.

---

### If "--sync-issues"

Sync PRD completion status to GitHub issues:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/github-sync.sh" sync --close-on-complete
```

---

### If "--help" or "-h"

Run the help script:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-um-loop.sh" --help
```

---

### If any other arguments (task description or options)

Start/continue the loop by running the setup script:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-um-loop.sh" $ARGUMENTS
```

Then follow the instructions output by the script to begin working on the task.

**New v3.0 flags to pass through:**
- `--parallel` - Enable parallel agent mode
- `--branch-per-task` - Create git branch for each task
- `--multi-model` - Enable multi-model routing
- `--no-notify` - Skip notifications

---

### If no arguments

Continue an existing loop:

1. Check if `.claude/um-loop.local.md` exists
2. If exists:
   - Read PRD.md to find first unchecked `- [ ]` item
   - Read progress.md to see what's been done
   - Check for v3.0 features in state file
   - Work on the next item (using parallel/multi-model if enabled)
   - Update progress.md with what you did
   - Mark the checkbox `[x]` in PRD.md
3. If not exists:
   - Check if PRD.md exists
   - If PRD.md exists: Start the loop with `"${CLAUDE_PLUGIN_ROOT}/scripts/setup-um-loop.sh" --prd PRD.md`
   - If not: "No active loop. Start with `/um-loop [task]`"

---

## The Loop Cycle

Once the loop is active, follow this cycle every iteration:

```
1. READ PRD.md        -> Find first unchecked [ ] item
2. READ progress.md   -> Know what's been done
3. IMPLEMENT          -> Complete that ONE item
4. VERIFY             -> Run tests/lint if configured
5. UPDATE progress.md -> Append timestamped entry
6. UPDATE PRD.md      -> Mark [ ] as [x]
7. EXIT               -> Stop hook will restart you
```

## v3.0 Features

### Parallel Mode (--parallel)

When parallel mode is enabled:
1. Analyze tasks for dependencies
2. Spawn Task subagents for independent tasks
3. Coordinate agent completion
4. Mark checkboxes when agents finish

Use the Task tool with `subagent_type: "general-purpose"` to spawn agents.

### Branch Per Task (--branch-per-task)

When branch-per-task is enabled:
1. Each task gets its own git branch
2. Commits are made automatically
3. Branches merge to base when complete

### Multi-Model Routing (--multi-model)

Route tasks to specialized models:
- **Gemini**: Research, analysis, large context
- **Codex**: Planning, architecture, code generation
- **Claude**: Tool execution, final decisions

## Completion

The loop ends when:
- All PRD checkboxes are `[x]`
- Max iterations reached
- `## DONE` marker in progress.md
- User runs `/um-loop cancel`
