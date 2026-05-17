# Claude Code Workflows

A collection of Claude Code skills for enhanced AI-assisted development workflows.

## Featured: UM Goals (v3)

**Persistent goal execution** with auto-decomposition, structured evaluation, and budget enforcement. Create a goal, let Claude break it into verifiable criteria, then execute with an orchestrator that judges each iteration.

```bash
/um-goals create Build a REST API with CRUD operations
/um-goals run goal-001 -n 20
```

### Key Features

| Feature | Description |
|---------|-------------|
| **Auto-Decomposition** | Goals are broken into concrete, verifiable acceptance criteria |
| **Structured Evaluation** | Orchestrator judges each iteration with evidence-based verdicts |
| **Stickiness** | Completed criteria can't regress — only the user can undo |
| **Budget Enforcement** | Turn and token budgets with automatic pause on exhaustion |
| **Fail-Open Safety** | 3 consecutive failures auto-pause with actionable guidance |
| **Promotion Cascade** | `feat → dev → staging → main` with CI monitoring |
| **Parallel Agents** | Spawn Agent forks for independent criteria |

```bash
# Full example with options
/um-goals create "Build microservices" 
/um-goals run goal-001 -n 30 --parallel --branch feat/microservices

# Manage criteria
/um-goals subgoal goal-001 add "Add health check endpoint"
/um-goals subgoal goal-001 mark 3 done

# Promote through environments
/um-goals promote goal-001 --to staging
```

---

## Installation

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and configured

### Step 1: Clone the Repository

```bash
git clone https://github.com/UMWai/claude-code-workflows.git
cd claude-code-workflows
```

### Step 2: Install the Command

The um-goals skill is a slash command. Copy it to your Claude Code commands directory:

```bash
mkdir -p ~/.claude/commands
cp skills/um-goals/um-goals.md ~/.claude/commands/um-goals.md
```

### Step 3: Install the CLI Helper

The `um-goals` shell script manages goal files on disk:

```bash
# Make executable and symlink to PATH
chmod +x skills/um-goals/um-goals
sudo ln -sf $(pwd)/skills/um-goals/um-goals /usr/local/bin/um-goals
```

### Step 4: Verify Installation

```bash
um-goals help
```

### Step 5: Restart Claude Code

Start a new Claude Code session. The `/um-goals` command should now appear in your slash command menu.

---

## How It Works

UM Goals uses an **orchestrator-worker pattern**. The orchestrator manages state, spawns Agent forks to do work, and judges results with structured evaluation.

```
You ──► /um-goals create "task"  ──► Auto-decomposes into criteria
                                          │
/um-goals run <id> -n 20                  │
         │                                ▼
         ▼                    ┌──────────────────────┐
    Orchestrator              │  ~/.um-goals/goals/  │
         │                    │  <id>.md             │
         ├─► Spawn fork ──►   │  (source of truth)   │
         │   (worker)         └──────────────────────┘
         │                                │
         ├─► Judge result ◄───────────────┘
         │   (THE JUDGE)
         │
         ├─► Update state + commit
         │
         └─► Next criterion or stop
```

### The Judge

After each worker fork returns, the orchestrator evaluates the result:

| Verdict | Meaning | Action |
|---------|---------|--------|
| **done** | Clear evidence criterion is satisfied | Mark `[x]`, log evidence |
| **partial** | Progress made but criterion not fully met | Leave `[ ]`, retry next iteration |
| **blocked** | External dependency or missing resource | Leave `[ ]`, increment failure counter |
| **impossible** | Criterion fundamentally cannot be satisfied | Mark `[!]`, log reason |

---

## Commands Reference

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

### Run Options

| Flag | Description |
|------|-------------|
| `-n, --max-turns N` | Turn budget (default: 20) |
| `--token-budget N` | Token budget (default: unlimited) |
| `--parallel` | Spawn Agent forks for independent criteria |
| `--no-commit` | Disable auto-commit |
| `--commit-every N` | Commit every N iterations (default: 3) |
| `--branch <name>` | Feature branch name (default: `feat/goal-<id>`) |

### Subgoal Actions

```bash
/um-goals subgoal <id>                     # Show numbered criteria
/um-goals subgoal <id> add <text>          # Add a new criterion
/um-goals subgoal <id> mark <N> done       # Mark criterion N as done
/um-goals subgoal <id> mark <N> impossible # Mark criterion N as impossible
/um-goals subgoal <id> undo <N>            # Revert criterion N to pending
/um-goals subgoal <id> remove <N>          # Delete criterion N
/um-goals subgoal <id> clear               # Wipe all + re-decompose on next run
```

### Promote Options

```bash
/um-goals promote <id>                # Full cascade: feat→dev→staging→main
/um-goals promote <id> --to dev       # Stop after merging to dev
/um-goals promote <id> --to staging   # Stop after merging to staging
/um-goals promote <id> --skip-soak    # Skip soak wait (weekends only)
```

---

## North Star — Goal Alignment Check

**On-demand alignment checker** that evaluates whether your current work serves the project's declared ultimate goal. Scores branches, commits, and goals against your pillars/objectives.

```bash
/north-star              # Full alignment audit
/north-star session      # Quick 2-3 sentence verdict
/north-star branch       # Score only current branch
/north-star goals        # Score only active um-goals
/north-star retro        # Classify last 20 commits by pillar
```

### Setup

Create an `ULTIMATE_GOALS.md` in your repo root with your pillars, checklist, and anti-goals. The skill reads it as the scoring rubric. See `skills/north-star/SKILL.md` for the template.

### Scores

| Score | Meaning |
|-------|---------|
| **ALIGNED** | Work directly advances at least one pillar |
| **ENABLING** | Infrastructure that unblocks a specific pillar |
| **DRIFTING** | Doesn't clearly map — needs justification |
| **OFF-MISSION** | Contradicts an anti-goal or delays progress |

### Installation

```bash
cp skills/north-star/north-star.md ~/.claude/commands/north-star.md
```

Or for project-level:

```bash
cp skills/north-star/north-star.md <your-project>/.claude/commands/north-star.md
```

---

## Also Included: Manus Workflow

The [Manus AI workflow pattern](https://gist.github.com/renschni/4fbc70b31bad8dd57f3370239dccd58f) — file-based "working memory" for complex research tasks.

```bash
/manus start Research and implement rate limiting for our API
```

| File | Purpose |
|------|---------|
| `task_plan.md` | Track phases with checkboxes |
| `notes.md` | Store research findings |
| `deliverable.md` | Final output |

---

## Repository Structure

```
claude-code-workflows/
├── README.md
├── skills/
│   ├── um-goals/
│   │   ├── SKILL.md                 # Skill definition
│   │   └── um-goals.md             # Slash command (copy to ~/.claude/commands/)
│   ├── north-star/
│   │   ├── SKILL.md                 # Skill definition + setup template
│   │   └── north-star.md            # Slash command (copy to ~/.claude/commands/)
│   └── manus-workflow/
│       ├── SKILL.md
│       ├── reference.md
│       └── examples.md
├── archived/
│   └── um-loop/                    # Legacy um-loop skill (superseded by um-goals)
└── docs/
    └── installation.md
```

---

## Credits

- [Ralph Wiggum technique](https://ghuntley.com/ralph/) by Geoffrey Huntley
- [Manus workflow pattern](https://manus.im) from Manus AI

## License

MIT
