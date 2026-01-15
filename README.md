# Claude Code Workflows

A collection of Claude Code skills for enhanced AI-assisted development workflows.

## Featured: Manus Workflow

The main skill implements the [Manus AI workflow pattern](https://gist.github.com/renschni/4fbc70b31bad8dd57f3370239dccd58f) - a file-based "working memory" system that enables Claude to handle complex, multi-step tasks without losing context.

### The Three-File System

| File | Purpose |
|------|---------|
| `task_plan.md` | Track phases and progress with checkboxes |
| `notes.md` | Store research findings (not in context) |
| `deliverable.md` | Final synthesized output |

### Why This Works

> "Markdown is my working memory on disk. Since I process information iteratively and my active context has limits, Markdown files serve as scratch pads for notes, checkpoints for progress, and building blocks for final deliverables."

This pattern allows Claude to:
- Maintain focus across 50+ tool calls
- Never repeat failed approaches
- Resume interrupted sessions
- Produce consistent, thorough results

## Installation

### Method 1: Copy to Skills Directory (Recommended)

```bash
# Clone this repo
git clone https://github.com/UMWai/claude-code-workflows.git

# Copy skills to your Claude config
cp -r claude-code-workflows/skills/* ~/.claude/skills/
```

### Method 2: Symlink

```bash
git clone https://github.com/UMWai/claude-code-workflows.git
ln -s $(pwd)/claude-code-workflows/skills/manus-workflow ~/.claude/skills/manus-workflow
```

### Method 3: Direct Download

```bash
mkdir -p ~/.claude/skills
curl -L https://github.com/UMWai/claude-code-workflows/archive/main.tar.gz | \
  tar -xz --strip-components=2 -C ~/.claude/skills claude-code-workflows-main/skills
```

## Usage

### Start a Manus Workflow

```
/manus start [your goal here]
```

Example:
```
/manus start Research and implement rate limiting for our API
```

### Commands

| Command | Description |
|---------|-------------|
| `/manus start [goal]` | Initialize new workflow |
| `/manus status` | Check current progress |
| `/manus checkpoint` | Force save to notes |
| `/manus complete` | Finalize deliverable |

### When to Use

**Use this workflow for:**
- Multi-step research tasks
- Complex implementations
- Bug investigations
- Anything requiring >5 tool calls

**Skip for:**
- Simple questions
- Single file edits
- Quick lookups

## Also Included: UM Loop

An iterative task completion workflow based on the Ralph Wiggum technique. Uses PRD checkboxes to track progress across iterations.

### The Three-File System

| File | Purpose |
|------|---------|
| `PRD.md` | Requirements with checkboxes to track completion |
| `progress.md` | Log of actions (append-only memory) |
| `PROMPT.md` | Agent instructions for autonomous work |

### Usage

```
/um-loop start Build a REST API with CRUD operations
```

Then continue with `/um-loop` to work on the next item.

### Commands

| Command | Description |
|---------|-------------|
| `/um-loop start [task]` | Initialize new loop |
| `/um-loop` | Continue (do next item) |
| `/um-loop status` | Check progress |

### When to Use Which

| Scenario | Use |
|----------|-----|
| Research, exploration, context-heavy | Manus Workflow |
| Implementation, clear deliverables | UM Loop |
| Complex project | Manus first, then UM Loop |

---

## Skills Included

| Skill | Description | Status |
|-------|-------------|--------|
| `manus-workflow` | File-based planning workflow | ✅ Ready |
| `um-loop` | Iterative task completion with PRD checkboxes | ✅ Ready |

## Repository Structure

```
claude-code-workflows/
├── README.md
├── LICENSE
├── skills/
│   ├── manus-workflow/
│   │   ├── SKILL.md          # Main skill definition
│   │   ├── reference.md      # Deep dive on principles
│   │   ├── examples.md       # Usage examples
│   │   └── templates/
│   │       ├── task_plan.md
│   │       ├── notes.md
│   │       └── deliverable.md
│   └── um-loop/
│       ├── SKILL.md          # Main skill definition
│       └── templates/
│           ├── PROMPT.md     # Agent instructions
│           ├── PRD.md        # Task requirements
│           └── progress.md   # Progress log
└── docs/
    └── installation.md
```

## Contributing

PRs welcome! To add a new skill:

1. Create `skills/your-skill/SKILL.md`
2. Add any templates or supporting files
3. Update README with skill description
4. Submit PR

## Credits

- Workflow pattern inspired by [Manus AI](https://manus.im)
- Technical analysis from [@renschni](https://gist.github.com/renschni/4fbc70b31bad8dd57f3370239dccd58f)
- [planning-with-files](https://github.com/OthmanAdi/planning-with-files) reference implementation

## License

MIT
