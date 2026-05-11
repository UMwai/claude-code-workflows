#!/bin/bash

# UM Loop Git Workflow
# Handles branch-per-task, auto-commit, and auto-merge functionality

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

CONFIG_DIR=".um-loop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
STATE_FILE=".claude/um-loop.local.md"

# Defaults
BRANCH_PER_TASK=false
AUTO_COMMIT=true
AUTO_MERGE=false
BASE_BRANCH="main"
BRANCH_PREFIX="um-loop/"

# ============================================
# ARGUMENT PARSING
# ============================================

ACTION=""
TASK_NAME=""
TASK_ID=""
COMMIT_MSG=""

usage() {
  cat << 'EOF'
Usage: git-workflow.sh ACTION [OPTIONS]

ACTIONS:
  create-branch TASK_ID TASK_NAME   Create a new task branch
  commit TASK_ID "MESSAGE"          Commit changes for a task
  merge TASK_ID                     Merge task branch to base
  merge-all                         Merge all completed task branches
  status                            Show branch status
  cleanup                           Delete merged task branches

OPTIONS:
  --base BRANCH      Base branch (default: main)
  --prefix PREFIX    Branch prefix (default: um-loop/)
  --no-push          Don't push to remote

EXAMPLES:
  git-workflow.sh create-branch 1 "Add authentication"
  git-workflow.sh commit 1 "Implement login endpoint"
  git-workflow.sh merge 1
  git-workflow.sh status

CONFIG:
  Set in .um-loop/config.yaml:
    git:
      branch_per_task: true
      auto_commit: true
      auto_merge: true
      base_branch: "main"
      branch_prefix: "um-loop/"
EOF
  exit 0
}

NO_PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    --base)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --prefix)
      BRANCH_PREFIX="$2"
      shift 2
      ;;
    --no-push)
      NO_PUSH=true
      shift
      ;;
    create-branch|commit|merge|merge-all|status|cleanup)
      ACTION="$1"
      shift
      ;;
    *)
      if [[ -z "$TASK_ID" ]]; then
        TASK_ID="$1"
      elif [[ -z "$TASK_NAME" ]] && [[ "$ACTION" == "create-branch" ]]; then
        TASK_NAME="$1"
      elif [[ -z "$COMMIT_MSG" ]] && [[ "$ACTION" == "commit" ]]; then
        COMMIT_MSG="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  echo "Error: ACTION required" >&2
  usage
fi

# ============================================
# LOAD CONFIG
# ============================================

if [[ -f "$CONFIG_FILE" ]]; then
  # Parse git config section
  GIT_CONFIG=$(sed -n '/^git:/,/^[a-z]/p' "$CONFIG_FILE" 2>/dev/null | head -n -1 || echo "")

  if [[ -n "$GIT_CONFIG" ]]; then
    CONFIG_BRANCH_PER_TASK=$(echo "$GIT_CONFIG" | grep 'branch_per_task:' | sed 's/.*branch_per_task:\s*//' || echo "")
    CONFIG_AUTO_COMMIT=$(echo "$GIT_CONFIG" | grep 'auto_commit:' | sed 's/.*auto_commit:\s*//' || echo "")
    CONFIG_AUTO_MERGE=$(echo "$GIT_CONFIG" | grep 'auto_merge:' | sed 's/.*auto_merge:\s*//' || echo "")
    CONFIG_BASE_BRANCH=$(echo "$GIT_CONFIG" | grep 'base_branch:' | sed 's/.*base_branch:\s*//' | sed 's/^"\(.*\)"$/\1/' || echo "")
    CONFIG_BRANCH_PREFIX=$(echo "$GIT_CONFIG" | grep 'branch_prefix:' | sed 's/.*branch_prefix:\s*//' | sed 's/^"\(.*\)"$/\1/' || echo "")

    [[ "$CONFIG_BRANCH_PER_TASK" == "true" ]] && BRANCH_PER_TASK=true
    [[ "$CONFIG_AUTO_COMMIT" == "false" ]] && AUTO_COMMIT=false
    [[ "$CONFIG_AUTO_MERGE" == "true" ]] && AUTO_MERGE=true
    [[ -n "$CONFIG_BASE_BRANCH" ]] && BASE_BRANCH="$CONFIG_BASE_BRANCH"
    [[ -n "$CONFIG_BRANCH_PREFIX" ]] && BRANCH_PREFIX="$CONFIG_BRANCH_PREFIX"
  fi
fi

# ============================================
# HELPER FUNCTIONS
# ============================================

# Slugify task name for branch
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | head -c 40
}

# Get current branch
current_branch() {
  git rev-parse --abbrev-ref HEAD
}

# Check if branch exists
branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1" 2>/dev/null
}

# Check if on task branch
is_task_branch() {
  local branch=$(current_branch)
  [[ "$branch" == "${BRANCH_PREFIX}"* ]]
}

# Get task branch name
task_branch_name() {
  local task_id="$1"
  local task_name="$2"

  if [[ -n "$task_name" ]]; then
    echo "${BRANCH_PREFIX}task-${task_id}-$(slugify "$task_name")"
  else
    echo "${BRANCH_PREFIX}task-${task_id}"
  fi
}

# Check for uncommitted changes
has_changes() {
  ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet 2>/dev/null
}

# Check for untracked files
has_untracked() {
  [[ -n "$(git ls-files --others --exclude-standard)" ]]
}

# Update state file with current branch
update_state_branch() {
  local branch="$1"

  if [[ -f "$STATE_FILE" ]]; then
    # Check if current_branch field exists
    if grep -q '^current_branch:' "$STATE_FILE"; then
      sed -i "s/^current_branch:.*/current_branch: \"$branch\"/" "$STATE_FILE"
    else
      # Add after started_at line
      sed -i "/^started_at:/a current_branch: \"$branch\"" "$STATE_FILE"
    fi
  fi
}

# ============================================
# CREATE BRANCH
# ============================================

create_branch() {
  if [[ -z "$TASK_ID" ]]; then
    echo "Error: TASK_ID required" >&2
    exit 1
  fi

  local branch_name=$(task_branch_name "$TASK_ID" "$TASK_NAME")

  # Check if already on this branch
  if [[ "$(current_branch)" == "$branch_name" ]]; then
    echo "Already on branch: $branch_name"
    return 0
  fi

  # Stash any changes if needed
  local stashed=false
  if has_changes || has_untracked; then
    echo "Stashing uncommitted changes..."
    git stash push -u -m "um-loop: switching to task $TASK_ID"
    stashed=true
  fi

  # Make sure we're on base branch first
  if [[ "$(current_branch)" != "$BASE_BRANCH" ]]; then
    git checkout "$BASE_BRANCH" 2>/dev/null || git checkout -b "$BASE_BRANCH"
    git pull --ff-only origin "$BASE_BRANCH" 2>/dev/null || true
  fi

  # Create and switch to task branch
  if branch_exists "$branch_name"; then
    git checkout "$branch_name"
    echo "Switched to existing branch: $branch_name"
  else
    git checkout -b "$branch_name"
    echo "Created new branch: $branch_name"
  fi

  # Update state file
  update_state_branch "$branch_name"

  # Restore stashed changes
  if [[ "$stashed" == "true" ]]; then
    git stash pop || true
  fi
}

# ============================================
# COMMIT
# ============================================

commit_changes() {
  if [[ -z "$TASK_ID" ]]; then
    echo "Error: TASK_ID required" >&2
    exit 1
  fi

  if [[ -z "$COMMIT_MSG" ]]; then
    COMMIT_MSG="um-loop: Complete task $TASK_ID"
  fi

  # Check for changes
  if ! has_changes && ! has_untracked; then
    echo "No changes to commit"
    return 0
  fi

  # Stage all changes
  git add -A

  # Commit
  git commit -m "$COMMIT_MSG"
  echo "Committed: $COMMIT_MSG"

  # Push if not disabled
  if [[ "$NO_PUSH" != "true" ]]; then
    local branch=$(current_branch)
    git push -u origin "$branch" 2>/dev/null || git push origin "$branch"
    echo "Pushed to origin/$branch"
  fi
}

# ============================================
# MERGE
# ============================================

merge_branch() {
  if [[ -z "$TASK_ID" ]]; then
    echo "Error: TASK_ID required" >&2
    exit 1
  fi

  local branch_name=$(task_branch_name "$TASK_ID" "$TASK_NAME")

  # If task name not provided, try to find matching branch
  if [[ -z "$TASK_NAME" ]]; then
    local matching=$(git branch --list "${BRANCH_PREFIX}task-${TASK_ID}*" | head -1 | tr -d ' *')
    if [[ -n "$matching" ]]; then
      branch_name="$matching"
    fi
  fi

  if ! branch_exists "$branch_name"; then
    echo "Error: Branch $branch_name does not exist" >&2
    exit 1
  fi

  local current=$(current_branch)

  # Switch to base branch
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH" 2>/dev/null || true

  # Merge task branch
  if git merge --no-ff "$branch_name" -m "Merge $branch_name into $BASE_BRANCH"; then
    echo "Merged: $branch_name -> $BASE_BRANCH"

    # Push if not disabled
    if [[ "$NO_PUSH" != "true" ]]; then
      git push origin "$BASE_BRANCH"
      echo "Pushed to origin/$BASE_BRANCH"
    fi

    # Delete merged branch
    git branch -d "$branch_name"
    git push origin --delete "$branch_name" 2>/dev/null || true
    echo "Deleted branch: $branch_name"
  else
    echo "Merge conflict! Please resolve manually." >&2
    exit 1
  fi
}

# ============================================
# MERGE ALL
# ============================================

merge_all() {
  echo "Merging all task branches..."

  local branches=$(git branch --list "${BRANCH_PREFIX}*" | tr -d ' *')
  local count=0

  for branch in $branches; do
    # Extract task ID from branch name
    local task_id=$(echo "$branch" | sed "s/${BRANCH_PREFIX}task-//" | sed 's/-.*//')

    if [[ -n "$task_id" ]]; then
      TASK_ID="$task_id"
      TASK_NAME=""
      merge_branch && ((count++)) || true
    fi
  done

  echo "Merged $count branches"
}

# ============================================
# STATUS
# ============================================

show_status() {
  echo "Git Workflow Status"
  echo "==================="
  echo ""
  echo "Base branch: $BASE_BRANCH"
  echo "Current branch: $(current_branch)"
  echo "Branch prefix: $BRANCH_PREFIX"
  echo ""
  echo "Config:"
  echo "  branch_per_task: $BRANCH_PER_TASK"
  echo "  auto_commit: $AUTO_COMMIT"
  echo "  auto_merge: $AUTO_MERGE"
  echo ""

  local branches=$(git branch --list "${BRANCH_PREFIX}*" | tr -d ' *')

  if [[ -n "$branches" ]]; then
    echo "Task branches:"
    for branch in $branches; do
      local ahead=$(git rev-list --count "$BASE_BRANCH..$branch" 2>/dev/null || echo "?")
      local behind=$(git rev-list --count "$branch..$BASE_BRANCH" 2>/dev/null || echo "?")
      echo "  $branch (+$ahead/-$behind)"
    done
  else
    echo "No task branches"
  fi
}

# ============================================
# CLEANUP
# ============================================

cleanup_branches() {
  echo "Cleaning up merged task branches..."

  local count=0

  # Delete local branches that have been merged
  for branch in $(git branch --merged "$BASE_BRANCH" | grep "${BRANCH_PREFIX}" | tr -d ' *'); do
    git branch -d "$branch" 2>/dev/null && ((count++)) || true
    git push origin --delete "$branch" 2>/dev/null || true
  done

  echo "Deleted $count merged branches"
}

# ============================================
# MAIN
# ============================================

# Check if in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

case "$ACTION" in
  create-branch)
    create_branch
    ;;
  commit)
    commit_changes
    ;;
  merge)
    merge_branch
    ;;
  merge-all)
    merge_all
    ;;
  status)
    show_status
    ;;
  cleanup)
    cleanup_branches
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    usage
    ;;
esac

exit 0
