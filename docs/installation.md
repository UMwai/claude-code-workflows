# Installation Guide

## Prerequisites

- [Claude Code CLI](https://claude.ai/download) installed
- Git (for cloning)

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/UMWai/claude-code-workflows.git
cd claude-code-workflows
```

### Step 2: Install um-goals

The um-goals skill has two components: a slash command (for Claude Code) and a CLI helper (for managing goal files).

**Install the slash command:**

```bash
mkdir -p ~/.claude/commands
cp skills/um-goals/um-goals.md ~/.claude/commands/um-goals.md
```

**Install the CLI helper:**

```bash
chmod +x skills/um-goals/um-goals
sudo ln -sf $(pwd)/skills/um-goals/um-goals /usr/local/bin/um-goals
```

### Step 3: Install Manus Workflow (Optional)

```bash
mkdir -p ~/.claude/skills
cp -r skills/manus-workflow ~/.claude/skills/manus-workflow
```

### Step 4: Verify Installation

```bash
# Check um-goals CLI
um-goals help

# Check slash command exists
ls ~/.claude/commands/um-goals.md
```

### Step 5: Restart Claude Code

Start a new Claude Code session. The `/um-goals` command should appear in your slash command menu.

## Updating

```bash
cd claude-code-workflows
git pull

# Re-copy the command file
cp skills/um-goals/um-goals.md ~/.claude/commands/um-goals.md
```

## Uninstalling

```bash
# Remove slash command
rm ~/.claude/commands/um-goals.md

# Remove CLI helper
sudo rm /usr/local/bin/um-goals

# Remove goal data (optional)
rm -rf ~/.um-goals

# Remove manus workflow (if installed)
rm -rf ~/.claude/skills/manus-workflow
```

## Troubleshooting

### `/um-goals` not appearing in slash command menu

1. Check the file exists: `ls ~/.claude/commands/um-goals.md`
2. Restart Claude Code session
3. Verify frontmatter is intact at the top of the file

### `um-goals` CLI not found

1. Check the symlink: `ls -la /usr/local/bin/um-goals`
2. Or add the script directory to your PATH: `export PATH="$PATH:/path/to/claude-code-workflows/skills/um-goals"`

### Permission errors

```bash
chmod +x skills/um-goals/um-goals
chmod 644 ~/.claude/commands/um-goals.md
```
