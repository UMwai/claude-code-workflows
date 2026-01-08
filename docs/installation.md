# Installation Guide

## Prerequisites

- [Claude Code CLI](https://claude.ai/download) installed
- Git (for cloning)

## Installation Methods

### Method 1: Copy Skills (Recommended)

This is the simplest approach and keeps your skills self-contained.

```bash
# Clone the repository
git clone https://github.com/UMWai/claude-code-workflows.git
cd claude-code-workflows

# Create skills directory if it doesn't exist
mkdir -p ~/.claude/skills

# Copy all skills
cp -r skills/* ~/.claude/skills/
```

### Method 2: Symlink (For Development)

If you want to modify skills and have changes apply immediately:

```bash
git clone https://github.com/UMWai/claude-code-workflows.git
cd claude-code-workflows

# Symlink specific skill
ln -s $(pwd)/skills/manus-workflow ~/.claude/skills/manus-workflow
```

### Method 3: Direct Download

No git required:

```bash
mkdir -p ~/.claude/skills
curl -L https://github.com/UMWai/claude-code-workflows/archive/main.tar.gz | \
  tar -xz --strip-components=2 -C ~/.claude/skills claude-code-workflows-main/skills
```

## Verify Installation

After installation, verify the skill is available:

```bash
ls ~/.claude/skills/manus-workflow/
```

You should see:
```
SKILL.md
reference.md
examples.md
templates/
```

## Using Skills

Once installed, invoke skills in Claude Code:

```
/manus start Your task description here
```

## Updating

To update to the latest version:

```bash
cd claude-code-workflows  # or wherever you cloned
git pull

# If using copy method, re-copy
cp -r skills/* ~/.claude/skills/
```

## Uninstalling

```bash
rm -rf ~/.claude/skills/manus-workflow
```

## Troubleshooting

### Skill not recognized

1. Check the skill exists: `ls ~/.claude/skills/manus-workflow/SKILL.md`
2. Restart Claude Code
3. Ensure SKILL.md has correct "Invoke with:" header

### Permission errors

```bash
chmod -R 755 ~/.claude/skills/
```

### Skills directory doesn't exist

```bash
mkdir -p ~/.claude/skills
```
