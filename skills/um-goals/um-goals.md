# um-goals — Persistent Goal Execution (v3)

Manage and execute persistent goals with auto-decomposition, structured evaluation, and budget enforcement.
Runs **inside the session** — inherits all permissions, MCP servers, and context.

## Arguments

`$ARGUMENTS` is the subcommand + args (e.g., "create Build auth system", "run goal-001 -n 20", "subgoal goal-001 add Test edge cases")

## Instructions

Parse `$ARGUMENTS` to determine the subcommand:

### If empty or "help":

Show this usage summary:

```
um-goals — Persistent Goal Execution v3

COMMANDS:
  /um-goals create <title>         Create a new goal (auto-decomposes into criteria)
  /um-goals list                   Show all goals
  /um-goals show <id>              Show goal details + progress
  /um-goals run <id> [-n N]        Execute goal with structured evaluation
  /um-goals pause <id>             Pause an active goal
  /um-goals resume <id>            Resume a paused goal
  /um-goals complete <id>          Manually mark complete
  /um-goals delete <id>            Delete a goal
  /um-goals stats <id>             Budget/cost summary
  /um-goals events <id>            JSONL event stream
  /um-goals subgoal <id> [action]  Manage acceptance criteria
  /um-goals promote <id>           Merge feat→dev→staging→main with CI monitoring

SUBGOAL ACTIONS:
  /um-goals subgoal <id>                    Show numbered criteria (default)
  /um-goals subgoal <id> add <text>         Add a new criterion
  /um-goals subgoal <id> mark <N> done      Mark criterion N as done
  /um-goals subgoal <id> mark <N> impossible  Mark criterion N as impossible
  /um-goals subgoal <id> undo <N>           Revert criterion N to pending (user override)
  /um-goals subgoal <id> remove <N>         Delete criterion N
  /um-goals subgoal <id> clear              Wipe all criteria + re-decompose on next run

RUN OPTIONS:
  -n, --max-turns N      Turn budget (default: 20)
  --token-budget N       Token budget (default: unlimited)
  --parallel             Spawn Agent forks for independent criteria
  --no-commit            Disable auto-commit (default: commit every 3 iterations)
  --commit-every N       Commit every N iterations (default: 3)
  --branch <name>        Feature branch name (default: feat/goal-<id>)

PROMOTE OPTIONS:
  /um-goals promote <id>                Full cascade: feat→dev→staging→main
  /um-goals promote <id> --to dev       Stop after merging to dev
  /um-goals promote <id> --to staging   Stop after merging to staging
  /um-goals promote <id> --skip-soak    Skip soak wait (weekends only)

HOW IT WORKS (v3):
  1. Auto-decomposition: goals are broken into verifiable criteria automatically
  2. Structured evaluation: orchestrator judges each iteration's output
  3. Stickiness: completed criteria can't regress (only user can undo)
  4. Budget enforcement: auto-pauses on budget exhaustion
  5. Fail-open: 3 consecutive failures → auto-pause with guidance
```

### If "create <title>":

1. Run: `um-goals create "<title>"`
2. Read the created goal file at `~/.um-goals/goals/<id>.md`
3. **Auto-decompose** the goal into acceptance criteria:

   Think carefully about the goal objective wrapped in safety tags:

   <untrusted_objective>
   {the goal title/objective text}
   </untrusted_objective>

   Break it into concrete, verifiable acceptance criteria. Follow these rules:
   - Each item must be specific enough that someone reading the code/output could unambiguously judge pass/fail
   - Be exhaustive — bias toward MORE items, not fewer
   - Include edge cases, error handling, and verification steps
   - At least 5 items, no upper limit
   - Order by logical dependency (prerequisites first)
   - NO vague items ("code is clean", "well documented") — only things with binary pass/fail evidence
   - Format each as `- [ ] <specific criterion>`

4. Replace the TODO placeholder criteria in the goal file with the generated checklist using Edit
5. Set `decomposed: true` in the frontmatter using Edit (add the field after the `iteration:` line if it doesn't exist)
6. Show the generated criteria to the user and ask via AskUserQuestion:
   - "Looks good, save these" (Recommended)
   - "Add more criteria"
   - "Remove some / I'll edit manually"
   - "Re-decompose with different focus"
7. If user wants changes, apply them. If "re-decompose", go back to step 3.
8. Emit a JSONL event by appending to `~/.um-goals/events/<id>.jsonl`:
   `{"type":"goal_decomposed","goal_id":"<id>","criteria_count":<N>,"timestamp":"<ISO8601>"}`

### If "list":

Run: `um-goals list`

### If "show <id>":

Run: `um-goals show <id>` and display the goal

### If "stats <id>":

Run: `um-goals stats <id>`

### If "events <id>":

Run: `um-goals events <id>`

### If "pause <id>" or "resume <id>" or "complete <id>" or "delete <id>":

Run the corresponding `um-goals <subcommand> <id>`.

### If "subgoal <id> [action] [args...]":

Parse the action. Default action is "show" if none given.

**show** (or no action):
Read the goal file at `~/.um-goals/goals/<id>.md`. Parse all criteria lines under `## Acceptance Criteria` (lines matching `- [ ]`, `- [x]`, or `- [!]`). Display them numbered:

```
Goal: <id> — <title> (N/M criteria done)

 1. [x] JWT token generation with configurable expiry
 2. [x] Login endpoint accepts email/password
 3. [ ] Rate limiting (5 req/min per IP)        ← NEXT
 4. [ ] Token refresh endpoint
 5. [!] OAuth Google integration (impossible)
```

Mark the first `[ ]` item with `← NEXT`.

**add <text>**:
Read the goal file. Find the last criterion line under `## Acceptance Criteria`. Insert a new `- [ ] <text>` line after it using Edit.

**mark <N> done|impossible|pending**:
Read the goal file. Find criterion number N (1-indexed). Edit the line:
- `done` → change to `- [x] <text>` and add evidence line: `  > Marked done by user: <YYYY-MM-DD HH:MM>`
- `impossible` → change to `- [!] <text>` and add reason line: `  > Marked impossible by user: <YYYY-MM-DD HH:MM>`
- `pending` → change to `- [ ] <text>` (remove any evidence/reason blockquote lines below it)

**undo <N>**:
Same as `mark <N> pending`. This is the ONLY way to revert a completed or impossible criterion.

**remove <N>**:
Read the goal file. Find criterion number N. Delete that line (and any blockquote metadata lines below it) using Edit.

**clear**:
Read the goal file. Remove all lines under `## Acceptance Criteria` up to the next `##` heading. Replace with:
```
- [ ] (criteria cleared — will re-decompose on next run)
```
Set `decomposed: false` in the frontmatter using Edit.

### If "run <id> [options]":

This is the core execution loop. Do NOT shell out to `um-goals run`. Execute it here.

**Parse options from remaining args:**
- `-n N` or `--max-turns N` → turn budget (default: 20)
- `--token-budget N` → token budget (default: 0 = unlimited)
- `--parallel` → enable parallel Agent forks for independent criteria
- `--no-commit` → disable auto-commit
- `--commit-every N` → commit every N iterations (default: 3)
- `--branch <name>` → feature branch name (default: `feat/goal-<id>`)

**Step 1: Load goal + validate**

Read the goal file at `~/.um-goals/goals/<id>.md`.

Extract from frontmatter:
- `status` — must not be "complete"
- `iteration` — current count
- `decomposed` — whether auto-decomposition has run
- `turn_budget` — max turns (use CLI `-n` override if provided)
- `turns_used` — turns consumed so far
- `token_budget` — max tokens (use CLI `--token-budget` override if provided)
- `tokens_used` — tokens consumed so far
- `consecutive_failures` — for fail-open logic
- `branch` — feature branch name

If status is "complete" → tell user "Goal already complete." Stop.
If status is "budget_limited" → tell user "Budget exhausted (turns_used/turn_budget turns). Use `-n N` to increase turn budget, or `/um-goals resume <id>`." Stop.
If status is "pending" or "paused":
```bash
um-goals resume <id>
```

**Override budgets from CLI args** (if provided, write to frontmatter via Edit):
- If `-n` given: update `turn_budget: <value>` in frontmatter
- If `--token-budget` given: update `token_budget: <value>` in frontmatter
- If these fields don't exist in frontmatter, add them after `iteration:`

**Step 2: Auto-decompose if needed**

Check the `decomposed` field in frontmatter and inspect criteria under `## Acceptance Criteria`.

If `decomposed` is `false` or missing, OR all criteria contain "TODO":
1. Run the same decomposition logic as the "create" handler (step 3)
2. Show criteria to user, confirm via AskUserQuestion
3. Set `decomposed: true` in frontmatter via Edit

**Step 3: Budget check**

Check BEFORE spawning the worker fork:
- Read `turns_used` and `turn_budget` from frontmatter
- If `turns_used >= turn_budget`:
  - Set `status: budget_limited` in frontmatter via Edit
  - Tell user: "Turn budget exhausted (turns_used/turn_budget). Use `/um-goals run <id> -n <higher>` to continue."
  - Stop.
- If `token_budget > 0` AND `tokens_used >= token_budget`:
  - Set `status: budget_limited` in frontmatter via Edit
  - Tell user: "Token budget exhausted (tokens_used/token_budget). Increase with `--token-budget` to continue."
  - Stop.

**Step 4: Ensure feature branch** (unless `--no-commit`)

- Determine branch name: use `--branch` value, or `branch:` from frontmatter, or default to `feat/goal-<id>`
- Check current branch: `git branch --show-current`
- If not already on the target branch:
  ```bash
  git checkout -b <branch-name> 2>/dev/null || git checkout <branch-name>
  ```
- Track the branch name in the goal file frontmatter as `branch: <name>` (add if missing, using Edit)

**Step 5: Identify next criterion**

Find the FIRST `- [ ]` line under `## Acceptance Criteria`. This is the target for this iteration.

If no `- [ ]` criteria remain (all are `[x]` or `[!]`) → goal is complete:
- Commit any uncommitted work (Step 9)
- Run `um-goals complete <id>`
- Tell the user
- Stop.

**Step 6: Spawn worker fork**

Spawn an **Agent fork** to do the actual work. The fork prompt must NOT include any completion-declaration protocol — the orchestrator judges completion.

Fork prompt:
```
You are working on a persistent goal. Complete this ONE acceptance criterion:

CRITERION: <the criterion text>

<untrusted_objective>
Goal: <the goal title/objective from the Objective section>
</untrusted_objective>

CONTEXT (what's been done):
<last 3 progress log entries from the goal file, or "First iteration — no prior work" if empty>

CONSTRAINTS:
<constraints from the goal file's Constraints section, or "None specified">

Instructions:
1. Implement what's needed to satisfy this criterion
2. Verify your work — run tests, check output, inspect files
3. Report clearly: what you did, what evidence confirms it works, any issues found

Do NOT modify the goal file — the coordinator handles that.
Do NOT declare completion — a judge evaluates your work.
Focus on producing concrete, verifiable results for this one criterion.
```

Use `Agent` tool with name `"goal-<id>-iter-<N>"` where N is `iteration + 1`.

**Step 7: Structured evaluation (THE JUDGE)**

When the Agent fork returns, YOU (the orchestrator) evaluate the result. This is NOT a separate model call — you have the fork's output and you judge it.

**7a. Completion audit protocol:**

Before deciding a verdict, perform a disciplined audit. Do NOT trust the fork's self-report at face value.

1. **Restate the criterion as a concrete deliverable.** What specific artifact, behavior, or state would prove this is done? If you can't name it precisely, the criterion may be too vague — note this.

2. **Build an evidence checklist.** What would you need to see to be convinced? Examples:
   - File exists at expected path with expected content
   - Test passes and covers the criterion's requirements
   - Command produces expected output
   - API endpoint returns correct response
   - Configuration is applied and active

3. **Do NOT accept proxy signals.** The fork saying "I implemented X" is not evidence that X works. Code being written is not evidence that code is correct. A test file existing is not evidence that it passes.

4. **Do NOT rely on intent or partial progress.** "I started working on..." or "The framework is in place for..." means partial at best.

5. **Treat uncertainty as not-done.** If you're unsure whether the criterion is fully met, the verdict is `partial`, not `done`.

**7b. Independent verification** (spot-check the fork's claims):

Do NOT skip this step. The fork may claim success but not deliver. Verify by actually checking:

```bash
# Check what the fork actually changed
git diff --stat

# If the fork claimed to create/modify specific files, verify they exist
ls -la <claimed-file-path>

# If the fork claimed tests pass, re-run them
<test-command-for-this-project>

# If the fork claimed a specific behavior, spot-check it
<relevant verification command>
```

Pick the 1-2 most important claims from the fork's output and verify them directly. You don't need to verify everything — but you MUST verify at least one concrete claim before marking `done`.

If verification fails (file doesn't exist, test fails, output differs from claim), downgrade the verdict to `partial` regardless of what the fork reported.

**7c. Determine verdict:**

Based on the audit and verification:

   **done** — The audit checklist is satisfied AND independent verification confirms it. Tests pass, files exist and contain expected content, commands succeed.

   **partial** — Progress was made but the audit found gaps, or verification revealed discrepancies between claims and reality.

   **blocked** — The fork couldn't make meaningful progress due to an external dependency, missing resource, or environmental issue.

   **impossible** — The criterion fundamentally cannot be satisfied in the current environment (missing APIs, wrong platform, incompatible requirements).

**7d. Apply the verdict** to the goal file:

   **If done:**
   - Edit the goal file: change `- [ ] <criterion text>` to `- [x] <criterion text>`
   - Add evidence blockquote on the next line(s) — include what you independently verified:
     ```
     - [x] <criterion text>
       > Evidence: <what you verified — e.g., "test_auth.py::test_jwt passes, auth/jwt.py exists with generate_token()">
       > Verified: <what specific check you ran — e.g., "ran pytest test_auth.py, confirmed file exists">
       > Completed: <YYYY-MM-DD HH:MM>
     ```
   - Set `consecutive_failures: 0` in frontmatter via Edit
   - **Do NOT stop here** — "done" means this criterion is done, not the goal. Continue to Steps 8-11.

   **If partial:**
   - Leave as `- [ ] <criterion text>` (do NOT check the box)
   - Set `consecutive_failures: 0` in frontmatter (progress was made)

   **If blocked:**
   - Leave as `- [ ] <criterion text>`
   - Increment `consecutive_failures` in frontmatter via Edit

   **If impossible:**
   - Edit the goal file: change `- [ ] <criterion text>` to `- [!] <criterion text>`
   - Add reason blockquote:
     ```
     - [!] <criterion text>
       > Reason: <why this criterion cannot be satisfied>
       > Marked: <YYYY-MM-DD HH:MM>
     ```
   - Set `consecutive_failures: 0` in frontmatter

5. **Discovered criteria:** If the fork's work revealed something that should be an acceptance criterion (a gap, edge case, or dependency not originally listed), add it as a new `- [ ]` line at the end of the criteria section:
   ```
   - [ ] <new criterion description> (discovered: iteration N)
   ```

6. **Stickiness rule (CRITICAL):** NEVER change a `- [x]` back to `- [ ]`. NEVER change a `- [!]` back to `- [ ]`. Only the user can revert these via `/um-goals subgoal <id> undo <N>`. If you encounter an already-completed or impossible criterion, skip it entirely.

**Step 8: Update state**

After evaluation, update the goal file:

1. Increment `iteration` in frontmatter via Edit (e.g., `iteration: 3` → `iteration: 4`)
2. Increment `turns_used` in frontmatter via Edit
3. Update `updated:` timestamp in frontmatter
4. Estimate tokens from the fork's output: count approximate characters / 4, add to `tokens_used` in frontmatter
5. Append a progress log entry to the `## Progress Log` section:
   ```
   ### Iteration N (YYYY-MM-DD HH:MM)
   - Criterion: <the criterion text that was worked on>
   - Result: <brief summary of what the fork accomplished>
   - Verdict: <done | partial | blocked | impossible>
   ```
6. Emit JSONL event by appending to `~/.um-goals/events/<id>.jsonl`:
   ```
   {"type":"iteration_end","goal_id":"<id>","iteration":<N>,"criterion":"<text>","verdict":"<verdict>","timestamp":"<ISO8601>"}
   ```

**Step 9: Auto-commit checkpoint** (unless `--no-commit`)

After every `commit-every` iterations (default: 3), OR when all criteria are complete:

1. Verify you're on the correct branch:
   ```bash
   git branch --show-current
   ```
   If not on the expected branch, switch back before committing.

2. Stage and commit changed files:
   ```bash
   git status --short
   ```
   - Stage relevant files (NOT `.env`, credentials, or secrets)
   - Use a descriptive commit message:
     ```bash
     git add <specific files> && git commit -m "$(cat <<'EOF'
     feat(goal-<id>): <short summary of criteria completed>

     Iterations <start>–<end>:
     - <criterion 1 summary>
     - <criterion 2 summary>
     - <criterion 3 summary>
     EOF
     )"
     ```
3. Push to remote:
   ```bash
   git push origin <branch-name> -u
   ```

4. Log the commit in the progress section:
   ```
   **Checkpoint commit:** <short SHA> pushed to <branch-name>
   ```

**Important:** Do NOT skip the commit on the final iteration. When all criteria complete, always commit+push remaining work before marking the goal complete.

**Step 10: Fail-open check**

Read `consecutive_failures` from frontmatter. If >= 3:
- Set `status: paused` in frontmatter via Edit
- Tell the user:
  ```
  Goal auto-paused: 3 consecutive iterations produced no progress.

  Suggestions:
  - Review the current criterion — it may need to be split into smaller steps
  - Use `/um-goals subgoal <id>` to view and adjust criteria
  - Use `/um-goals resume <id>` to continue after adjusting
  ```
- Emit JSONL event: `{"type":"auto_paused","goal_id":"<id>","reason":"consecutive_failures","timestamp":"<ISO8601>"}`
- Stop.

**Step 11: Continue the loop (MANDATORY)**

⚠️ **CRITICAL: You MUST call ScheduleWakeup at the end of every iteration unless one of the two exit conditions below is met. Failing to call ScheduleWakeup kills the goal loop. This is the most important step.**

**Check exit conditions IN THIS ORDER:**

1. **All criteria done?** (no `- [ ]` lines remain — all are `[x]` or `[!]`):
   → Commit any uncommitted work (Step 9)
   → Run `um-goals complete <id>`
   → Tell the user with a summary of what was accomplished
   → **EXIT — do NOT call ScheduleWakeup.**

2. **Budget exhausted?** (`turns_used >= turn_budget` or `tokens_used >= token_budget`):
   → Set `status: budget_limited` in frontmatter
   → Commit any uncommitted work (Step 9)
   → Tell user
   → **EXIT — do NOT call ScheduleWakeup.**

3. **EVERY OTHER CASE → MUST call ScheduleWakeup.** This includes after a successful "done" verdict, after "partial", after "blocked" — any verdict that doesn't trigger exit conditions 1 or 2 above. Call ScheduleWakeup with:
   - `delaySeconds: 60` (minimum — stays within prompt cache window)
   - `prompt`: `/um-goals run <id> -n <turn_budget>` (re-enter with the same turn budget)
   - `reason`: `"um-goals iteration <N+1>: <next criterion summary>"`
   
   **Do this IMMEDIATELY after updating state. Do not output a summary to the user and stop — that kills the loop.**

**Important rules for the run loop:**
- **NEVER end a turn without calling ScheduleWakeup** unless ALL criteria are done or budget is exhausted — this is the #1 failure mode
- ONE criterion per iteration — go deep, not wide
- The orchestrator judges completion, not the worker fork
- Stickiness: never regress a `[x]` or `[!]` criterion
- If a criterion is partially done, leave it `- [ ]` and note progress — it will be retried next iteration
- If blocked, note the blocker in progress log — consecutive failures trigger auto-pause
- Use `--parallel` to spawn multiple Agent forks for independent criteria simultaneously
- The goal file at `~/.um-goals/goals/<id>.md` is the source of truth
- Auto-commit happens every 3 iterations (configurable) — never let work pile up uncommitted
- After judging a criterion as "done", there are likely MORE criteria remaining — check and continue, do not stop

### If "promote <id> [options]":

This handles the full merge cascade: feature branch → dev → staging → main, with CI/CD monitoring at each stage.

**Parse options:**
- `--to <target>` → stop after reaching this stage (dev | staging | main). Default: main
- `--skip-soak` → skip soak waits (only allowed on weekends when markets closed)

**Step P1: Load goal + validate**

```bash
um-goals show <id>
```

- Read the `branch:` field from frontmatter. If missing, error: "No branch recorded for this goal. Run the goal first."
- Check goal status — must be "complete" or "active" (warn if active: "Goal is still active — promoting partial work")
- Verify the branch exists and has commits ahead of dev:
  ```bash
  git log origin/dev..origin/<branch> --oneline
  ```
  If no commits ahead, tell user "Nothing to promote" and stop.

**Step P2: Feature → dev**

1. Ensure local dev is up to date:
   ```bash
   git fetch origin dev
   ```

2. Create the PR:
   ```bash
   gh pr create --base dev --head <branch> --title "feat(<goal-id>): <goal title>" --body "$(cat <<'EOF'
   ## Summary
   Automated promote from um-goals goal <id>.

   ## Criteria completed
   <list checked criteria from goal file>

   ## Iterations
   <count> iterations completed.
   EOF
   )"
   ```

3. **Monitor CI/CD** (see CI Monitoring Protocol below)

4. Merge on CI green:
   ```bash
   gh pr merge <PR#> --merge --admin
   ```

5. If `--to dev`, STOP here. Tell user "Promoted to dev. PR #<N> merged."

**Step P3: Dev → staging**

1. Check soak policy:
   - Run `TZ=America/New_York date "+%u"` to get day of week (6=Sat, 7=Sun)
   - If weekend OR `--skip-soak`: proceed immediately
   - If weekday: tell user "Soak policy requires ≥1 trading session on dev. Use `--skip-soak` on weekends or wait." → STOP (use ScheduleWakeup to resume next trading day if desired)

2. Create promotion PR:
   ```bash
   gh pr create --base staging --head dev --title "promote: <goal title> → staging" --body "$(cat <<'EOF'
   ## Summary
   Promotion from dev to staging for goal <id>.

   ## What's included
   <list of commits from git log origin/staging..origin/dev --oneline>
   EOF
   )"
   ```

3. **Monitor CI/CD** (see CI Monitoring Protocol below)

4. Merge on CI green:
   ```bash
   gh pr merge <PR#> --merge --admin
   ```

5. **Post-merge: apply kustomize if needed** (CD only does `kubectl set image`, not kustomize apply):
   - Check if any files in `cluster-bootstrap/`, `overlays/`, or kustomize manifests changed:
     ```bash
     git diff origin/staging~1..origin/staging --name-only | grep -E '(cluster-bootstrap|overlays|kustomization)'
     ```
   - If yes, remind user: "Kustomize manifests changed. Run: `kubectl apply -k overlays/hedge-fund-staging/` after CD completes."

6. If `--to staging`, STOP here.

**Step P4: Staging → main**

1. Check soak policy (same as Step P3 — requires ≥1 trading session on staging)

2. Pre-check: verify no other commits on staging that haven't soaked:
   ```bash
   git log origin/main..origin/staging --oneline
   ```
   If there are commits beyond this goal's work, warn user: "Other commits on staging will also promote to main: <list>"

3. Create promotion PR:
   ```bash
   gh pr create --base main --head staging --title "main: <goal title>" --body "$(cat <<'EOF'
   ## Summary
   Production promotion for goal <id>.

   ## What's included
   <list of commits from git log origin/main..origin/staging --oneline>

   ## Soak status
   - Dev soak: <duration>
   - Staging soak: <duration>
   EOF
   )"
   ```

4. **Monitor CI/CD** (see CI Monitoring Protocol below)

5. Merge on CI green:
   ```bash
   gh pr merge <PR#> --merge --admin
   ```

6. Post-merge kustomize check (same as Step P3 but for production overlays).

7. Tell user: "Goal <id> promoted to main (LIVE). PR #<N> merged."

---

### CI Monitoring Protocol

Used by the promote command at each merge stage. Polls PR check status until resolved.

**Step M1: Wait for checks to start** (up to 60s)
```bash
sleep 15 && gh pr view <PR#> --json statusCheckRollup --jq '.statusCheckRollup | length'
```
If 0 checks after 60s, warn user "No CI checks found — PR may not have a required workflow."

**Step M2: Poll checks until completion**

Use ScheduleWakeup to poll every 30-60 seconds:
```bash
gh pr view <PR#> --json statusCheckRollup --jq '[.statusCheckRollup[] | {name: .name, status: .status, conclusion: .conclusion}]'
```

Parse the output:
- If ALL checks have `status: "COMPLETED"`:
  - If ALL have `conclusion: "SUCCESS"` → CI GREEN, proceed with merge
  - If ANY have `conclusion: "FAILURE"` → CI RED, handle failure
- If any check still `status: "IN_PROGRESS"` or `"QUEUED"` → continue polling

**Polling cadence:**
- First 2 minutes: poll every 60s (ScheduleWakeup minimum)
- After 2 minutes: poll every 90s
- After 10 minutes: poll every 180s
- After 30 minutes: give up, tell user "CI timed out after 30 minutes"

Use ScheduleWakeup with:
- `delaySeconds`: as described above
- `prompt`: `/um-goals promote <id> --monitor-pr <PR#> --stage <stage> --poll-count <N>`
- `reason`: `"um-goals CI monitor: waiting on <check-name> for PR #<N>"`

**Step M3: Handle CI failure**

If any check fails:
1. Show the user which check(s) failed:
   ```bash
   gh pr view <PR#> --json statusCheckRollup --jq '[.statusCheckRollup[] | select(.conclusion == "FAILURE")]'
   ```
2. Attempt to get failure details:
   ```bash
   gh run view <run-id> --log-failed 2>/dev/null | tail -50
   ```
3. Ask user whether to:
   - **Fix and retry**: spawn an Agent fork to diagnose and fix, then re-push
   - **Skip**: close the PR and stop promotion
   - **Force merge**: merge despite failure (admin override)

---

### Internal: `--monitor-pr` handler

If `$ARGUMENTS` contains `--monitor-pr <PR#> --stage <stage> --poll-count <N>`:

This is a ScheduleWakeup callback for CI polling. Do NOT show the help text.

1. Check PR status:
   ```bash
   gh pr view <PR#> --json statusCheckRollup --jq '[.statusCheckRollup[] | {name: .name, status: .status, conclusion: .conclusion}]'
   ```

2. If all complete + all success → merge and continue to next stage (or stop if at target)
3. If any failed → handle failure (Step M3)
4. If still in progress → increment poll count, compute next delay, ScheduleWakeup again
5. If poll count > 30 (roughly 30 min) → timeout, tell user

---

## Key Differences from v2

- **Auto-decomposition**: Goals are automatically broken into verifiable criteria (no more manual TODO placeholders)
- **Structured evaluation**: Orchestrator judges each iteration with evidence-based verdicts (no more regex CRITERION_DONE)
- **Stickiness**: Completed criteria cannot regress — only user can undo via `/um-goals subgoal undo`
- **Budget enforcement**: Turn and token budgets with automatic `budget_limited` status
- **Fail-open safety**: 3 consecutive failures → auto-pause with actionable guidance
- **Subgoal controls**: Add, mark, undo, remove criteria without editing files
- **`[!]` impossible marker**: Criteria that can't be satisfied are marked distinctly, not left unchecked

## When to Recommend

- Complex multi-step projects with high-level objectives (decomposition handles the details)
- Tasks that need many iterations with persistent memory
- Work requiring MCP tools (Tradier, Gemini, etc.) in each iteration
- End-to-end feature delivery: code → commit → merge → promote → deploy
- Autonomous code generation with structured quality gates
