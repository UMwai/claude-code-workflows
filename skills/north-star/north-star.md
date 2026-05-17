# North Star — Ultimate Goal Alignment Check

Evaluate whether the current work serves the project's ultimate goal. Scores current branch, active goals, and recent changes against declared pillars/objectives. Flags drift, gaps, and misaligned work.

## Arguments: $ARGUMENTS

- (empty) — full alignment audit of current session's work
- `branch` — score only the current branch's changes
- `goals` — score only active um-goals
- `session` — quick check: "is what I'm doing right now moving a pillar forward?"
- `retro` — retrospective: what did the last N commits accomplish against the pillars?

## Instructions

### Phase 0: Load North Star

Search for the project's goal definition. Check in order:
1. `ULTIMATE_GOALS.md` in repo root
2. `GOALS.md` in repo root
3. `NORTH_STAR.md` in repo root
4. `## Goals` or `## Objectives` section in `CLAUDE.md`

If none found, tell the user: "No goal definition found. Create an `ULTIMATE_GOALS.md` in your repo root — see `/north-star` SKILL.md for a template."

Extract from the goal file:
- **Prime Directive** — the one-sentence success definition
- **Pillars** — the major objectives and their current stage status
- **Checklist** — the "Are We Getting Closer?" questions
- **Anti-goals** — bright lines that must not be crossed
- **Remaining gaps** — what's still missing

This is the scoring rubric. Every piece of work gets judged against it.

### Phase 1: Gather Current Work Context

Run these in parallel:

```bash
TZ=America/New_York date "+%A %B %d, %Y %I:%M %p ET" 2>/dev/null || date "+%A %B %d, %Y %I:%M %p"
```

```bash
git branch --show-current
```

```bash
git log --oneline -20
```

```bash
# What's changed on this branch vs the main integration branch
MAIN_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)
DEV_BRANCH=$(git branch -r --list 'origin/dev' | head -1 | tr -d ' ')
BASE=${DEV_BRANCH:-origin/$MAIN_BRANCH}
git diff ${BASE}...HEAD --stat 2>/dev/null || git diff HEAD~5 --stat
```

```bash
# Active um-goals (if um-goals is installed)
if [ -d ~/.um-goals/goals ]; then
  for f in ~/.um-goals/goals/goal-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    status=$(grep -m1 "^status:" "$f" | cut -d' ' -f2)
    title=$(grep -m1 "^title:" "$f" | sed 's/^title: //' | tr -d '"')
    [ "$status" = "active" ] || [ "$status" = "pending" ] && echo "$id ($status): $title"
  done
else
  echo "(um-goals not installed — skipping goal check)"
fi
```

```bash
# What files are being touched
MAIN_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)
DEV_BRANCH=$(git branch -r --list 'origin/dev' | head -1 | tr -d ' ')
BASE=${DEV_BRANCH:-origin/$MAIN_BRANCH}
git diff ${BASE}...HEAD --name-only 2>/dev/null || git diff HEAD~5 --name-only
```

### Phase 2: Classify Changes by Pillar

For each changed file / active goal / recent commit, classify it into the pillars defined in the goal file.

Use the pillar definitions from Phase 0 to build a mapping. For each pillar, identify:
- Which directories / file patterns are relevant
- Which goal titles map to this pillar
- Which commit messages reference this pillar's concerns

Classify each change as:

**Pillar N** — directly advances this pillar's objectives

**Infrastructure / Enabler** — supports pillars but isn't one itself (CI/CD, infra, observability, tooling). Valid ONLY if it unblocks a specific pillar stage.

**Drift / Off-mission** — doesn't map to any pillar:
- Refactors without a pillar justification
- Features outside the project's declared scope
- Anything that violates an anti-goal

### Phase 3: Score Alignment

For each pillar, produce:

| Pillar | Current Stage | This Work Advances? | Stage Movement | Evidence |
|--------|--------------|---------------------|----------------|----------|
| {name} | S{N} of {M} | Yes/No/Partial | S{N}→S{N+1} / within-stage | specific files/commits |

**Overall alignment score:**
- **ALIGNED** — Work directly advances at least one pillar
- **ENABLING** — Work is infrastructure that unblocks a specific pillar (must name which one)
- **DRIFTING** — Work doesn't clearly map to any pillar. Not necessarily wrong, but needs justification.
- **OFF-MISSION** — Work contradicts an anti-goal or actively delays pillar progress

### Phase 4: "Are We Getting Closer?" Quick Check

Answer each checklist question from the goal file:
- Use git history, file state, and goal status as evidence
- Answer YES/NO with specific evidence
- If the question references a timeframe (e.g., "in the last 7 days"), check accordingly

### Phase 5: Gap Analysis

From the "Remaining gaps" section:
- Which gaps this work closes (or moves toward closing)
- Which gaps remain untouched
- Which gaps are most urgent (blocking the next stage transition)

### Phase 6: Recommendations

**If ALIGNED or ENABLING:**
- Confirm the work is on-mission
- Suggest any quick wins that could advance another pillar in the same PR
- Note if any anti-goal is at risk

**If DRIFTING:**
- Name what's drifting and why it doesn't map
- Suggest how to re-frame or scope the work to serve a pillar
- Ask: "Is this intentional? If so, what's the justification?"

**If OFF-MISSION:**
- Flag clearly: "This work doesn't serve the ultimate goal"
- Explain which anti-goal it violates or which pillar it delays
- Suggest alternatives that would be on-mission

### Phase 7: Present Results

Format the output as:

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
{one-line summary of why}

### "Are We Getting Closer?"
1. {question}: {YES/NO} — {evidence}
2. ...

### Gaps & Priorities
- Closest to closing: {gap}
- Most urgent unaddressed: {gap}
- This work's contribution: {what it closes or advances}

### Recommendations
{actionable next steps}
```

## Argument-Specific Behavior

**If `$ARGUMENTS` is "branch":** Skip goal loading in Phase 1, focus only on git diff analysis. Faster, narrower.

**If `$ARGUMENTS` is "goals":** Skip branch analysis in Phase 1, focus only on active um-goals. Good for planning sessions.

**If `$ARGUMENTS` is "session":** Ultra-fast version — just answer "Is what I'm doing right now moving a pillar forward?" in 2-3 sentences. No tables, no deep analysis. Read the branch name + last 3 commits + current goal status, match to pillars, give verdict.

**If `$ARGUMENTS` is "retro":** Look at the last 20 commits on the current branch and classify each by pillar. Show a histogram of where effort went. Flag any commits that don't map. Good for end-of-session reflection.

## Important Rules

1. **Read-only** — this skill never modifies files, goals, or branches
2. **Honest** — if work is drifting, say so. Don't rationalize. The user wants truth, not validation.
3. **Actionable** — every finding should come with a concrete next step
4. **Fast for "session" mode** — under 30 seconds, 2-3 sentences max
5. **Reference anti-goals explicitly** — if anything approaches a bright line, name it
6. **Don't penalize infrastructure** — infra is valid when it unblocks a pillar, but it must be tied to one
7. **Graceful without um-goals** — the skill works with git history alone; um-goals integration is optional
