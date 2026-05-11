---
name: um-goals
description: Persistent goal execution with auto-decomposition, structured evaluation, budget enforcement, and promotion workflow. v3.
---

# UM Goals v3 — Persistent Goal Execution

Manage and execute persistent goals with auto-decomposition, structured evaluation, and budget enforcement. Runs inside the session — inherits all permissions, MCP servers, and context.

## Quick Start

```bash
# Create a goal (auto-decomposes into verifiable criteria)
/um-goals create Build auth system with JWT

# Run it (orchestrator judges each iteration)
/um-goals run goal-001 -n 20

# Check progress
/um-goals show goal-001

# Manage criteria
/um-goals subgoal goal-001
/um-goals subgoal goal-001 add Test edge cases

# Promote through environments
/um-goals promote goal-001
```

## How It Works

1. **Auto-decomposition**: Goals are automatically broken into verifiable acceptance criteria
2. **Structured evaluation**: An orchestrator judges each iteration's output with evidence-based verdicts
3. **Stickiness**: Completed criteria can't regress — only the user can undo via `subgoal undo`
4. **Budget enforcement**: Turn and token budgets with automatic `budget_limited` status
5. **Fail-open safety**: 3 consecutive failures auto-pause with actionable guidance
6. **Promotion cascade**: `feat → dev → staging → main` with CI monitoring at each stage

```
You ──► /um-goals create "task"  ──► Auto-decomposes into criteria
                                          │
                                          ▼
/um-goals run <id> -n 20  ──► Orchestrator loop
                                    │
                                    ▼
                            ┌───────────────┐
                            │  Find next    │
                            │  [ ] criterion│◄────────┐
                            └───────┬───────┘         │
                                    │                 │
                                    ▼                 │
                            ┌───────────────┐         │
                            │  Spawn Agent  │         │
                            │  fork (worker)│         │
                            └───────┬───────┘         │
                                    │                 │
                                    ▼                 │
                            ┌───────────────┐         │
                            │  Judge result │         │
                            │  (THE JUDGE)  │         │
                            └───────┬───────┘         │
                                    │                 │
                                    ▼                 │
                            ┌───────────────┐         │
                            │ done/partial/ │         │
                            │ blocked/impos │         │
                            └───────┬───────┘         │
                                    │                 │
                                    ▼                 │
                            ┌───────────────┐    No   │
                            │ All criteria  ├─────────┘
                            │ satisfied?    │
                            └───────┬───────┘
                                    │ Yes
                                    ▼
                             COMPLETE + COMMIT
```

## Commands

| Command | Description |
|---------|-------------|
| `/um-goals create <title>` | Create a new goal (auto-decomposes into criteria) |
| `/um-goals list` | Show all goals |
| `/um-goals show <id>` | Show goal details + progress |
| `/um-goals run <id> [-n N]` | Execute goal with structured evaluation |
| `/um-goals pause <id>` | Pause an active goal |
| `/um-goals resume <id>` | Resume a paused goal |
| `/um-goals complete <id>` | Manually mark complete |
| `/um-goals delete <id>` | Delete a goal |
| `/um-goals stats <id>` | Budget/cost summary |
| `/um-goals events <id>` | JSONL event stream |
| `/um-goals subgoal <id> [action]` | Manage acceptance criteria |
| `/um-goals promote <id>` | Merge feat→dev→staging→main with CI monitoring |

## Run Options

| Flag | Description |
|------|-------------|
| `-n, --max-turns N` | Turn budget (default: 20) |
| `--token-budget N` | Token budget (default: unlimited) |
| `--parallel` | Spawn Agent forks for independent criteria |
| `--no-commit` | Disable auto-commit (default: commit every 3 iterations) |
| `--commit-every N` | Commit every N iterations (default: 3) |
| `--branch <name>` | Feature branch name (default: `feat/goal-<id>`) |

## Subgoal Actions

| Action | Description |
|--------|-------------|
| `subgoal <id>` | Show numbered criteria (default) |
| `subgoal <id> add <text>` | Add a new criterion |
| `subgoal <id> mark <N> done` | Mark criterion N as done |
| `subgoal <id> mark <N> impossible` | Mark criterion N as impossible |
| `subgoal <id> undo <N>` | Revert criterion N to pending (user override) |
| `subgoal <id> remove <N>` | Delete criterion N |
| `subgoal <id> clear` | Wipe all criteria + re-decompose on next run |

## Promote Options

| Flag | Description |
|------|-------------|
| `promote <id>` | Full cascade: feat→dev→staging→main |
| `promote <id> --to dev` | Stop after merging to dev |
| `promote <id> --to staging` | Stop after merging to staging |
| `promote <id> --skip-soak` | Skip soak wait (weekends only) |

## Criteria Markers

| Marker | Meaning |
|--------|---------|
| `- [ ]` | Pending — not yet attempted or partially done |
| `- [x]` | Done — evidence confirms completion |
| `- [!]` | Impossible — cannot be satisfied in current environment |

## The Execution Loop

Each iteration follows this cycle:

```
1. LOAD goal file        → Read criteria, state, budget
2. BUDGET CHECK          → Stop if turns/tokens exhausted
3. FIND next [ ]         → First unchecked criterion
4. SPAWN Agent fork      → Worker implements the criterion
5. JUDGE result          → Orchestrator evaluates with evidence
6. UPDATE state          → Mark criterion, log progress, emit event
7. AUTO-COMMIT           → Every N iterations (default: 3)
8. FAIL-OPEN CHECK       → 3 consecutive failures → auto-pause
9. LOOP or STOP          → Continue, budget-limit, or complete
```

## Goal File Structure

Goals are stored at `~/.um-goals/goals/<id>.md` with YAML frontmatter tracking all state:

```yaml
---
id: goal-001
status: active
iteration: 5
turns_used: 5
turn_budget: 20
tokens_used: 12500
token_budget: 0
consecutive_failures: 0
decomposed: true
branch: feat/goal-001
created: 2026-05-11T10:00:00Z
updated: 2026-05-11T10:30:00Z
---
```

## When to Use

- Complex multi-step projects with high-level objectives
- Tasks that need many iterations with persistent memory
- Work requiring MCP tools (Tradier, Gemini, etc.) in each iteration
- End-to-end feature delivery: code → commit → merge → promote → deploy
- Autonomous code generation with structured quality gates

## Best Practices

1. **Set turn budgets** — always use `-n` to prevent runaway execution
2. **Review criteria after create** — auto-decomposition is good but not perfect
3. **Use subgoal commands** — adjust criteria without editing files manually
4. **Check progress with show** — see where the goal stands at any time
5. **Use promote for deployment** — handles the full merge cascade with CI checks
