#!/bin/bash

# UM Loop Stop Hook v3.0
# Prevents session exit when um-loop is active
# Checks PRD.md completion status and feeds prompt back for next iteration
# New: Notifications, git workflow, parallel agent tracking

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get script directory for calling other scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

# State file location
UM_LOOP_STATE=".claude/um-loop.local.md"
CONFIG_FILE=".um-loop/config.yaml"

# Check if um-loop is active
if [[ ! -f "$UM_LOOP_STATE" ]]; then
  # No active loop - allow exit
  exit 0
fi

# ============================================
# PARSE STATE FILE
# ============================================

FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$UM_LOOP_STATE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
PRD_FILE=$(echo "$FRONTMATTER" | grep '^prd_file:' | sed 's/prd_file: *//' | sed 's/^"\(.*\)"$/\1/')
PROGRESS_FILE=$(echo "$FRONTMATTER" | grep '^progress_file:' | sed 's/progress_file: *//' | sed 's/^"\(.*\)"$/\1/')

# v3.0 features
PARALLEL_MODE=$(echo "$FRONTMATTER" | grep '^parallel_mode:' | sed 's/parallel_mode: *//' || echo "false")
BRANCH_PER_TASK=$(echo "$FRONTMATTER" | grep '^branch_per_task:' | sed 's/branch_per_task: *//' || echo "false")
MULTI_MODEL=$(echo "$FRONTMATTER" | grep '^multi_model:' | sed 's/multi_model: *//' || echo "false")
BASE_BRANCH=$(echo "$FRONTMATTER" | grep '^base_branch:' | sed 's/base_branch: *//' | sed 's/^"\(.*\)"$/\1/' || echo "main")
CURRENT_BRANCH=$(echo "$FRONTMATTER" | grep '^current_branch:' | sed 's/current_branch: *//' | sed 's/^"\(.*\)"$/\1/' || echo "")

# Default file locations
PRD_FILE="${PRD_FILE:-PRD.md}"
PROGRESS_FILE="${PROGRESS_FILE:-progress.md}"

# ============================================
# VALIDATE STATE
# ============================================

if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Warning: um-loop state corrupted (invalid iteration). Stopping loop." >&2
  rm "$UM_LOOP_STATE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Warning: um-loop state corrupted (invalid max_iterations). Stopping loop." >&2
  rm "$UM_LOOP_STATE"
  exit 0
fi

# ============================================
# CHECK MAX ITERATIONS
# ============================================

if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "UM Loop: Max iterations ($MAX_ITERATIONS) reached."

  # Send notification
  if [[ -x "$SCRIPT_DIR/notify.sh" ]]; then
    "$SCRIPT_DIR/notify.sh" milestone "Max iterations ($MAX_ITERATIONS) reached. Loop stopped." 2>/dev/null || true
  fi

  rm "$UM_LOOP_STATE"
  exit 0
fi

# ============================================
# CHECK COMPLETION STATUS
# ============================================

TOTAL_TASKS=0
COMPLETED_TASKS=0
INCOMPLETE_TASKS=0

if [[ -f "$PRD_FILE" ]]; then
  TOTAL_TASKS=$(grep -c '^\s*- \[.\]' "$PRD_FILE" 2>/dev/null || echo "0")
  COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$PRD_FILE" 2>/dev/null || echo "0")
  INCOMPLETE_TASKS=$(grep -c '^\s*- \[ \]' "$PRD_FILE" 2>/dev/null || echo "0")

  # All tasks complete?
  if [[ "$TOTAL_TASKS" -gt 0 ]] && [[ "$INCOMPLETE_TASKS" -eq 0 ]]; then
    echo "UM Loop Complete! All $TOTAL_TASKS tasks finished."

    # Mark completion in progress file
    if [[ -f "$PROGRESS_FILE" ]]; then
      echo "" >> "$PROGRESS_FILE"
      echo "---" >> "$PROGRESS_FILE"
      echo "## DONE" >> "$PROGRESS_FILE"
      echo "All PRD tasks completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS_FILE"
    fi

    # Git: Merge all task branches if branch-per-task enabled
    if [[ "$BRANCH_PER_TASK" == "true" ]] && [[ -x "$SCRIPT_DIR/git-workflow.sh" ]]; then
      echo "Merging task branches..."
      "$SCRIPT_DIR/git-workflow.sh" merge-all --base "$BASE_BRANCH" 2>/dev/null || true
    fi

    # GitHub: Sync issue status
    if [[ -x "$SCRIPT_DIR/github-sync.sh" ]]; then
      "$SCRIPT_DIR/github-sync.sh" sync --close-on-complete 2>/dev/null || true
    fi

    # Send completion notification
    if [[ -x "$SCRIPT_DIR/notify.sh" ]]; then
      "$SCRIPT_DIR/notify.sh" complete "All $TOTAL_TASKS tasks completed successfully!" 2>/dev/null || true
    fi

    rm "$UM_LOOP_STATE"
    exit 0
  fi
fi

# Check for explicit DONE marker in progress file
if [[ -f "$PROGRESS_FILE" ]] && grep -q '^## DONE' "$PROGRESS_FILE"; then
  echo "UM Loop: Detected DONE marker in progress.md"

  # Send completion notification
  if [[ -x "$SCRIPT_DIR/notify.sh" ]]; then
    "$SCRIPT_DIR/notify.sh" complete "Loop marked as DONE" 2>/dev/null || true
  fi

  rm "$UM_LOOP_STATE"
  exit 0
fi

# ============================================
# MILESTONE NOTIFICATIONS
# ============================================

# Send milestone notifications at 25%, 50%, 75%
if [[ "$TOTAL_TASKS" -gt 0 ]]; then
  PERCENT=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))

  # Check if we should send a milestone notification
  SHOULD_NOTIFY=false
  MILESTONE=""

  if [[ $PERCENT -ge 75 ]] && [[ $PERCENT -lt 100 ]]; then
    MILESTONE="75%"
    SHOULD_NOTIFY=true
  elif [[ $PERCENT -ge 50 ]] && [[ $PERCENT -lt 75 ]]; then
    MILESTONE="50%"
    SHOULD_NOTIFY=true
  elif [[ $PERCENT -ge 25 ]] && [[ $PERCENT -lt 50 ]]; then
    MILESTONE="25%"
    SHOULD_NOTIFY=true
  fi

  # Check if we already sent this milestone notification
  if [[ "$SHOULD_NOTIFY" == "true" ]]; then
    if ! grep -q "milestone.*$MILESTONE" "$UM_LOOP_STATE" 2>/dev/null; then
      if [[ -x "$SCRIPT_DIR/notify.sh" ]]; then
        "$SCRIPT_DIR/notify.sh" milestone "$MILESTONE complete ($COMPLETED_TASKS/$TOTAL_TASKS tasks)" 2>/dev/null || true

        # Record that we sent this notification
        # (Simple approach: append to state file comments)
        echo "# milestone_sent: $MILESTONE" >> "$UM_LOOP_STATE"
      fi
    fi
  fi
fi

# ============================================
# GIT: AUTO-COMMIT CURRENT WORK
# ============================================

if [[ "$BRANCH_PER_TASK" == "true" ]] && [[ -x "$SCRIPT_DIR/git-workflow.sh" ]]; then
  # Check if there are uncommitted changes
  if ! git diff --quiet HEAD 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
    # Get current task name for commit message
    CURRENT_TASK=""
    if [[ -f "$PRD_FILE" ]]; then
      # Find the task that was just completed (last [x] item)
      CURRENT_TASK=$(grep '^\s*- \[x\]' "$PRD_FILE" | tail -1 | sed 's/.*\[x\]\s*//' | head -c 60)
    fi

    if [[ -n "$CURRENT_TASK" ]]; then
      "$SCRIPT_DIR/git-workflow.sh" commit "$ITERATION" "um-loop: $CURRENT_TASK" --no-push 2>/dev/null || true
    fi
  fi
fi

# ============================================
# CONTINUE LOOP
# ============================================

NEXT_ITERATION=$((ITERATION + 1))

# Update iteration count in state file
TEMP_FILE="${UM_LOOP_STATE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$UM_LOOP_STATE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$UM_LOOP_STATE"

# ============================================
# BUILD PROMPT
# ============================================

# Read from PROMPT.md if exists, otherwise use embedded prompt
PROMPT_FILE="PROMPT.md"
if [[ -f "$PROMPT_FILE" ]]; then
  PROMPT_TEXT=$(cat "$PROMPT_FILE")
else
  # Extract prompt from state file (after second ---)
  PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$UM_LOOP_STATE")
fi

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "Warning: No prompt found. Stopping loop." >&2

  # Send error notification
  if [[ -x "$SCRIPT_DIR/notify.sh" ]]; then
    "$SCRIPT_DIR/notify.sh" error "No prompt found - loop stopped" 2>/dev/null || true
  fi

  rm "$UM_LOOP_STATE"
  exit 0
fi

# ============================================
# BUILD STATUS MESSAGE
# ============================================

SYSTEM_MSG="UM Loop iteration $NEXT_ITERATION"

if [[ -f "$PRD_FILE" ]]; then
  SYSTEM_MSG="$SYSTEM_MSG | Tasks: $COMPLETED_TASKS/$TOTAL_TASKS complete"

  # Get next task
  NEXT_TASK=$(grep '^\s*- \[ \]' "$PRD_FILE" 2>/dev/null | head -1 | sed 's/.*\[ \]\s*//' | head -c 50 || echo "")
  if [[ -n "$NEXT_TASK" ]]; then
    SYSTEM_MSG="$SYSTEM_MSG | Next: $NEXT_TASK"
  fi
else
  SYSTEM_MSG="$SYSTEM_MSG | Check PRD.md for tasks"
fi

# Add v3.0 feature indicators
FEATURES=""
[[ "$PARALLEL_MODE" == "true" ]] && FEATURES="${FEATURES} parallel"
[[ "$BRANCH_PER_TASK" == "true" ]] && FEATURES="${FEATURES} git-branches"
[[ "$MULTI_MODEL" == "true" ]] && FEATURES="${FEATURES} multi-model"

if [[ -n "$FEATURES" ]]; then
  SYSTEM_MSG="$SYSTEM_MSG | Features:$FEATURES"
fi

# ============================================
# GIT: CREATE BRANCH FOR NEXT TASK
# ============================================

if [[ "$BRANCH_PER_TASK" == "true" ]] && [[ -x "$SCRIPT_DIR/git-workflow.sh" ]]; then
  # Get next task ID and name
  if [[ -f "$PRD_FILE" ]]; then
    NEXT_TASK_LINE=$(grep -n '^\s*- \[ \]' "$PRD_FILE" 2>/dev/null | head -1 || echo "")
    if [[ -n "$NEXT_TASK_LINE" ]]; then
      TASK_NUM=$(echo "$NEXT_TASK_LINE" | cut -d: -f1)
      TASK_NAME=$(echo "$NEXT_TASK_LINE" | sed 's/.*\[ \]\s*//' | head -c 40)

      # Create branch for next task if not already on one
      "$SCRIPT_DIR/git-workflow.sh" create-branch "$TASK_NUM" "$TASK_NAME" 2>/dev/null || true
    fi
  fi
fi

# ============================================
# OUTPUT: BLOCK EXIT AND FEED PROMPT
# ============================================

jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
