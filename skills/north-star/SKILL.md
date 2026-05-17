---
name: north-star
description: Evaluate whether current work serves the project's ultimate goal. Scores branches, goals, and commits against declared pillars/objectives. Flags drift and misalignment.
---

# North Star — Ultimate Goal Alignment Check

Evaluate whether the current work serves the project's declared ultimate goal. Scores current branch, active goals, and recent changes against the project's core objectives. Flags drift, gaps, and misaligned work.

## Quick Start

```bash
# Full alignment audit of current session
/north-star

# Quick 2-3 sentence check
/north-star session

# Score only the current branch
/north-star branch

# Score only active um-goals
/north-star goals

# Retrospective: classify last 20 commits by objective
/north-star retro
```

## How It Works

1. **Load the project's north star** — reads `ULTIMATE_GOALS.md` (or equivalent) from the repo root. Extracts core objectives, pillars, stage progress, anti-goals, and remaining gaps.

2. **Gather current work context** — branch diff vs main/dev, active um-goals, recent commits, changed files.

3. **Classify every change** — each file, commit, and goal maps to a pillar/objective (or is flagged as drift).

4. **Score alignment** — overall verdict: ALIGNED, ENABLING, DRIFTING, or OFF-MISSION.

5. **Gap analysis** — which objectives this work advances, which are untouched, which are most urgent.

6. **Actionable recommendations** — concrete next steps based on alignment state.

## Setup

The skill requires a **goal definition file** in your repo root. Create one of:

- `ULTIMATE_GOALS.md` (preferred)
- `GOALS.md`
- `NORTH_STAR.md`
- A `## Goals` or `## Objectives` section in your `CLAUDE.md`

### Minimal `ULTIMATE_GOALS.md` template

```markdown
# Ultimate Goals

## Prime Directive
> One sentence describing what success looks like for this project.

## Pillars
1. **Pillar Name** — what this pillar delivers
   - Stage 0: ... (status: shipped / in-progress / planned)
   - Stage 1: ...
2. **Pillar Name** — ...

## "Are We Getting Closer?" Checklist
1. Question about pillar 1 progress (YES/NO test)
2. Question about pillar 2 progress (YES/NO test)

## Anti-Goals
- Things we explicitly do NOT do
- Bright lines we don't cross

## Remaining Gaps
- What's still missing before the system is "done"
```

## Output Format

```
## North Star Alignment — {date}

### Current Work
Branch: {branch}
Active Goals: {count}
Files Changed: {count}

### Pillar Scorecard
| Pillar | Stage | Advancing? | Detail |
|--------|-------|------------|--------|
| ... | ... | ... | ... |

### Overall: {ALIGNED / ENABLING / DRIFTING / OFF-MISSION}
{one-line summary}

### "Are We Getting Closer?"
1. {checklist question}: {YES/NO} — {evidence}
2. ...

### Gaps & Priorities
- Closest to closing: {gap}
- Most urgent unaddressed: {gap}
- This work's contribution: {what it closes}

### Recommendations
{actionable next steps}
```

## Scoring Rules

| Score | Meaning | Action |
|-------|---------|--------|
| **ALIGNED** | Work directly advances at least one pillar | Confirm and continue |
| **ENABLING** | Infrastructure that unblocks a specific pillar (must name which) | Valid, but tie it to a pillar |
| **DRIFTING** | Doesn't clearly map to any pillar | Ask for justification |
| **OFF-MISSION** | Contradicts an anti-goal or delays pillar progress | Flag and suggest alternatives |

## Design Principles

1. **Read-only** — never modifies files, goals, or branches
2. **Honest** — if work is drifting, say so. No rationalizing.
3. **Actionable** — every finding comes with a concrete next step
4. **Fast in session mode** — 2-3 sentences, under 30 seconds
5. **Anti-goals are bright lines** — if anything approaches one, name it explicitly
6. **Infrastructure is valid** — but it must be tied to a pillar to score ENABLING
