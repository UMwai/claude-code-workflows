---
name: um-loop
description: Autonomous task completion loop with PRD checkboxes. v3.0 adds parallel agents, multi-model routing, notifications, GitHub integration, and auto-merge.
---

# UM Loop v3.0

Autonomous task completion with PRD checkboxes. A true Ralph-style loop that runs until all tasks are done.

## What's New in v3.0

| Feature | Description |
|---------|-------------|
| **Parallel Agents** | Spawn Task subagents for independent tasks |
| **Multi-Model Routing** | Route tasks to Gemini/Codex/Claude based on task type |
| **Notifications** | Discord/Slack webhooks for progress and completion |
| **GitHub Integration** | Pull issues into PRD, close when complete |
| **Auto-Merge** | Branch-per-task with automatic commits and merges |

## Quick Start

```bash
# Single task - creates PRD and loops until complete
/um-loop Build a REST API with CRUD operations --max-iterations 20

# With v3.0 features
/um-loop "Add authentication" --parallel --multi-model --branch-per-task

# From GitHub issues
/um-loop --from-issues "label:um-loop" --max-iterations 50

# Initialize project config first (recommended)
/um-loop --init
/um-loop "Add authentication"
```

## How It Works

UM Loop implements the [Ralph Wiggum technique](https://ghuntley.com/ralph/) using a **stop hook**:

1. You run `/um-loop "task"` once
2. Claude creates PRD.md with checkbox items
3. Claude works on the first `- [ ]` item
4. Claude tries to exit
5. **Stop hook intercepts** and feeds the prompt back
6. Claude sees its previous work in files
7. Continues until all `- [x]` or max iterations

```
You ──► /um-loop "Build API" ──► Creates PRD.md, progress.md
                                       │
                                       ▼
                               ┌───────────────┐
                               │  Work on      │
                               │  first [ ]    │◄────────┐
                               └───────┬───────┘         │
                                       │                 │
                                       ▼                 │
                               ┌───────────────┐         │
                               │  Mark [x]     │         │
                               │  Update log   │         │
                               └───────┬───────┘         │
                                       │                 │
                                       ▼                 │
                               ┌───────────────┐         │
                               │  Try to exit  │         │
                               └───────┬───────┘         │
                                       │                 │
                                       ▼                 │
                               ┌───────────────┐    No   │
                               │ All [x] done? ├─────────┘
                               └───────┬───────┘
                                       │ Yes
                                       ▼
                                    DONE!
```

## Commands

| Command | Description |
|---------|-------------|
| `/um-loop [task]` | Start loop with task (creates PRD) |
| `/um-loop --prd FILE` | Use existing PRD file |
| `/um-loop` | Continue existing loop |
| `/um-loop status` | Show progress (iteration, tasks) |
| `/um-loop cancel` | Stop the loop |
| `/um-loop --init` | Create project config |
| `/um-loop --config` | View config |
| `/um-loop --add-rule "rule"` | Add rule to config |
| `/um-loop --from-issues FILTER` | Pull GitHub issues into PRD |
| `/um-loop --sync-issues` | Sync PRD status to GitHub |

## Options

### Core Options

| Flag | Description |
|------|-------------|
| `--max-iterations N` | Stop after N iterations (safety net) |
| `--prd FILE` | Use specific PRD file |
| `--test "CMD"` | Run test command after each task |
| `--lint "CMD"` | Run lint command after each task |
| `--no-tests` | Skip test verification |
| `--no-lint` | Skip lint verification |
| `--fast` | Skip both tests and lint |

### v3.0 Options

| Flag | Description |
|------|-------------|
| `--parallel` | Enable parallel agent mode |
| `--branch-per-task` | Create git branch for each task |
| `--multi-model` | Enable multi-model routing |
| `--from-issues FILTER` | Pull GitHub issues (e.g., "label:bug") |
| `--no-notify` | Skip Discord/Slack notifications |

## v3.0 Features

### 1. Parallel Agents

Spawn Task subagents for independent tasks:

```bash
/um-loop "Build a web app" --parallel --max-iterations 30
```

PRD format for parallel tasks:

```markdown
## Tasks
- [ ] @agent:1 Set up Express server
- [ ] @agent:2 Create database models
- [ ] Implement endpoints (blocked by: 1, 2)
- [ ] Add tests
```

The coordinator:
1. Analyzes task dependencies
2. Spawns subagents for independent tasks
3. Waits for agent completion
4. Marks checkboxes when done

Config:

```yaml
parallel:
  enabled: true
  max_agents: 3
  strategy: "independent"  # or "coordinated"
```

### 2. Multi-Model Routing

Route tasks to specialized models:

```bash
/um-loop "Research and implement caching" --multi-model
```

| Model | Use For | MCP Tool |
|-------|---------|----------|
| Gemini | Research, large files, exploration | `mcp__gemini-cli__ask-gemini` |
| Codex | Planning, architecture, code gen | `mcp__codex__codex` |
| Claude | Tool execution, final decisions | Direct |

Pattern-based routing in config:

```yaml
routing:
  - pattern: "research|analyze|explore"
    model: gemini
  - pattern: "plan|design|architect"
    model: codex
  - pattern: "implement|build|fix"
    model: claude
```

Workflow pattern:
```
Gemini (gather context) → Codex (plan/implement) → Claude (execute/commit)
```

### 3. Notifications

Get Discord/Slack notifications for loop events:

```bash
export UM_LOOP_DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
/um-loop "Build feature" --max-iterations 20
```

Events:
- `start` - Loop started
- `complete` - All tasks finished
- `error` - Error occurred
- `milestone` - Progress milestone (25%, 50%, 75%)
- `task` - Individual task completed

Config:

```yaml
notifications:
  discord:
    webhook: "https://discord.com/api/webhooks/..."
    events: [complete, error, milestone]
  slack:
    webhook: "https://hooks.slack.com/services/..."
    events: [complete]
```

### 4. GitHub Integration

Pull issues directly into PRD:

```bash
# By label
/um-loop --from-issues "label:um-loop"

# Specific issues
/um-loop --from-issues "#123,#124,#125"

# Sync status back to GitHub
/um-loop --sync-issues
```

Config:

```yaml
github:
  sync_issues: true
  close_on_complete: true
  labels: ["um-loop"]
```

### 5. Auto-Merge

Branch-per-task with automatic git workflow:

```bash
/um-loop "Refactor auth" --branch-per-task --max-iterations 15
```

Branches created:
```
main
├── um-loop/task-1-set-up-server (completed, merged)
├── um-loop/task-2-create-models (completed, merged)
└── um-loop/task-3-implement-endpoints (in progress)
```

Config:

```yaml
git:
  branch_per_task: true
  auto_commit: true
  auto_merge: true
  base_branch: "main"
  branch_prefix: "um-loop/"
```

## The Three-File System

| File | Purpose | Updated |
|------|---------|---------|
| `PRD.md` | Task list with checkboxes | Mark `[x]` when done |
| `progress.md` | Append-only work log | After each task |
| `PROMPT.md` | Agent instructions | Usually unchanged |

Plus: `.claude/um-loop.local.md` (state file for stop hook)

## Project Config

Initialize with auto-detection:

```bash
/um-loop --init
```

Creates `.um-loop/config.yaml`:

```yaml
project:
  name: "my-app"
  language: "TypeScript"
  framework: "Next.js"

commands:
  test: "npm test"
  lint: "npm run lint"

rules:
  - "use TypeScript strict mode"
  - "follow existing patterns"

boundaries:
  never_touch:
    - "src/legacy/**"
    - "*.lock"

# v3.0 features
models:
  default: "claude"
  research: "gemini"
  planning: "codex"

git:
  branch_per_task: false
  auto_commit: true
  auto_merge: false

notifications:
  discord:
    webhook: ""
    events: [complete, error]

github:
  sync_issues: false
  close_on_complete: false

parallel:
  enabled: false
  max_agents: 3
```

See `templates/config-full.yaml` for complete reference.

## Examples

### Basic Task

```bash
/um-loop "Add user authentication with JWT" --max-iterations 20
```

### With All v3.0 Features

```bash
/um-loop "Build REST API" \
  --parallel \
  --multi-model \
  --branch-per-task \
  --max-iterations 30
```

### From GitHub Issues

```bash
/um-loop --from-issues "label:sprint-1" --branch-per-task --max-iterations 50
```

### With Verification

```bash
/um-loop "Refactor the cache layer" --test "npm test" --lint "npm run lint" --max-iterations 30
```

## The Loop Cycle

Every iteration follows this exact cycle:

```
1. READ PRD.md        → Find first unchecked [ ] item
2. READ progress.md   → Know what's been done
3. IMPLEMENT          → Complete that ONE item
4. VERIFY             → Run tests/lint if configured
5. UPDATE progress.md → Append timestamped entry
6. UPDATE PRD.md      → Mark [ ] as [x]
7. EXIT               → Stop hook restarts you
```

## Completion

The loop ends when:
- All `- [ ]` items become `- [x]`
- Max iterations reached
- `## DONE` marker in progress.md
- User runs `/um-loop cancel`

## Best Practices

### 1. Always Set Max Iterations

```bash
# Good - has safety net
/um-loop "task" --max-iterations 30

# Risky - runs forever if stuck
/um-loop "task"
```

### 2. Use Parallel for Independent Tasks

```bash
# Tasks that modify different files
/um-loop "Build microservices" --parallel

# Don't parallelize if tasks share files
/um-loop "Refactor single module"  # No --parallel
```

### 3. Use Multi-Model for Complex Tasks

```bash
# Research + implementation
/um-loop "Analyze codebase and add caching" --multi-model

# Simple implementation (skip routing)
/um-loop "Fix typo in README"
```

### 4. Set Up Notifications for Long Tasks

```bash
export UM_LOOP_DISCORD_WEBHOOK="..."
/um-loop "Major refactor" --max-iterations 50
# Get notified at 25%, 50%, 75%, and completion
```

### 5. Use Branch-Per-Task for Safe Refactoring

```bash
/um-loop "Refactor auth system" --branch-per-task
# Each task gets its own branch
# Easy to review and rollback
```

## Troubleshooting

### Loop won't stop

```bash
/um-loop cancel
```

### Lost track of progress

```bash
/um-loop status
cat progress.md
```

### Want to restart

```bash
/um-loop cancel
rm PRD.md progress.md PROMPT.md
/um-loop "new task"
```

### Config not loading

```bash
/um-loop --config  # Check if exists
/um-loop --init    # Recreate if needed
```

### Notifications not sending

1. Check webhook URL is set in config or env var
2. Check `events` array includes your event type
3. Run `scripts/notify.sh complete "test"` manually to debug

### GitHub issues not syncing

1. Run `gh auth status` to verify authentication
2. Check `gh repo view` works in current directory
3. Verify issue labels match config

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `setup-um-loop.sh` | Initialize loop with PRD and state |
| `cancel-um-loop.sh` | Cancel active loop |
| `init-config.sh` | Create project config |
| `notify.sh` | Send webhook notifications |
| `github-sync.sh` | GitHub issues integration |
| `git-workflow.sh` | Branch/commit/merge automation |
| `model-router.sh` | Multi-model routing logic |

## Philosophy

> "Each iteration starts fresh, but progress persists in files. The PRD is the contract, progress.md is the memory, and checkboxes are the scoreboard."

v3.0 adds: "Parallel agents multiply throughput, multi-model routing leverages specialized strengths, and notifications keep humans in the loop."
