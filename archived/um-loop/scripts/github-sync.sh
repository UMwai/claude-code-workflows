#!/bin/bash

# UM Loop GitHub Issues Sync
# Pulls GitHub issues into PRD.md and optionally closes them when complete

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

CONFIG_DIR=".um-loop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
PRD_FILE="PRD.md"

# ============================================
# ARGUMENT PARSING
# ============================================

ACTION=""
FILTER=""
CLOSE_ON_COMPLETE=false
LABELS=""
ISSUE_NUMBERS=""

usage() {
  cat << 'EOF'
Usage: github-sync.sh ACTION [OPTIONS]

ACTIONS:
  pull          Pull issues into PRD.md
  sync          Update issue status from PRD.md
  close ISSUE   Close a specific issue

OPTIONS:
  --labels "bug,feature"     Filter by labels (comma-separated)
  --issues "#123,#124"       Specific issue numbers
  --limit N                  Maximum issues to pull (default: 20)
  --prd FILE                 Target PRD file (default: PRD.md)
  --close-on-complete        Mark issues closed when PRD task is done

EXAMPLES:
  github-sync.sh pull --labels "um-loop"
  github-sync.sh pull --issues "#123,#124,#125"
  github-sync.sh sync --close-on-complete
  github-sync.sh close 123

CONFIG:
  Set in .um-loop/config.yaml:
    github:
      sync_issues: true
      close_on_complete: true
      labels: ["um-loop"]
EOF
  exit 0
}

LIMIT=20

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    pull|sync|close)
      ACTION="$1"
      shift
      ;;
    --labels)
      LABELS="$2"
      shift 2
      ;;
    --issues)
      ISSUE_NUMBERS="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --prd)
      PRD_FILE="$2"
      shift 2
      ;;
    --close-on-complete)
      CLOSE_ON_COMPLETE=true
      shift
      ;;
    *)
      # For close action, this is the issue number
      if [[ "$ACTION" == "close" ]]; then
        ISSUE_NUMBERS="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  echo "Error: ACTION required (pull, sync, close)" >&2
  usage
fi

# ============================================
# LOAD CONFIG
# ============================================

if [[ -f "$CONFIG_FILE" ]]; then
  # Load github config
  CONFIG_LABELS=$(grep -A10 '^\s*github:' "$CONFIG_FILE" 2>/dev/null | grep 'labels:' | sed 's/.*labels:\s*//' | tr -d '[]"' || echo "")
  CONFIG_CLOSE=$(grep -A10 '^\s*github:' "$CONFIG_FILE" 2>/dev/null | grep 'close_on_complete:' | sed 's/.*close_on_complete:\s*//' || echo "false")

  # Use config values if not overridden
  LABELS="${LABELS:-$CONFIG_LABELS}"
  [[ "$CONFIG_CLOSE" == "true" ]] && CLOSE_ON_COMPLETE=true
fi

# ============================================
# CHECK PREREQUISITES
# ============================================

if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) is not installed" >&2
  echo "Install: https://cli.github.com/" >&2
  exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null 2>&1; then
  echo "Error: Not authenticated with GitHub CLI" >&2
  echo "Run: gh auth login" >&2
  exit 1
fi

# Check if in a git repo with GitHub remote
if ! gh repo view &> /dev/null 2>&1; then
  echo "Error: Not in a GitHub repository" >&2
  exit 1
fi

# ============================================
# HELPER FUNCTIONS
# ============================================

# Get repo info
get_repo_info() {
  gh repo view --json nameWithOwner -q '.nameWithOwner'
}

# Slugify issue title for branch names
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | head -c 50
}

# Extract issue number from PRD line
extract_issue_number() {
  local line="$1"
  echo "$line" | grep -oP '#\K\d+' | head -1
}

# Check if issue is completed in PRD
is_issue_completed() {
  local issue_num="$1"

  if [[ -f "$PRD_FILE" ]]; then
    # Look for [x] line with this issue number
    if grep -qP '^\s*-\s*\[x\].*#'"$issue_num" "$PRD_FILE"; then
      return 0
    fi
  fi

  return 1
}

# ============================================
# PULL ISSUES INTO PRD
# ============================================

pull_issues() {
  echo "Pulling GitHub issues..."

  local repo=$(get_repo_info)
  local query_args=("--state" "open" "--limit" "$LIMIT" "--json" "number,title,body,labels,assignees")

  # Build label filter
  if [[ -n "$LABELS" ]]; then
    # Split labels and add to query
    IFS=',' read -ra LABEL_ARR <<< "$LABELS"
    for label in "${LABEL_ARR[@]}"; do
      label=$(echo "$label" | xargs) # trim whitespace
      query_args+=("--label" "$label")
    done
  fi

  # Get issues
  local issues
  if [[ -n "$ISSUE_NUMBERS" ]]; then
    # Specific issue numbers
    issues="[]"
    IFS=',' read -ra NUMS <<< "$ISSUE_NUMBERS"
    for num in "${NUMS[@]}"; do
      num=$(echo "$num" | tr -d '#' | xargs)
      issue=$(gh issue view "$num" --json number,title,body,labels,assignees 2>/dev/null || echo "null")
      if [[ "$issue" != "null" ]]; then
        issues=$(echo "$issues" | jq --argjson issue "$issue" '. + [$issue]')
      fi
    done
  else
    issues=$(gh issue list "${query_args[@]}" 2>/dev/null || echo "[]")
  fi

  local count=$(echo "$issues" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    echo "No issues found matching criteria"
    return 0
  fi

  echo "Found $count issues"

  # Create or update PRD.md
  local prd_content=""

  if [[ -f "$PRD_FILE" ]]; then
    # Preserve existing content before Tasks section
    prd_content=$(sed '/^## Tasks/,$d' "$PRD_FILE")
  else
    prd_content="# PRD from GitHub Issues

## Objective

Complete the following GitHub issues.
"
  fi

  # Add tasks section
  prd_content+="
## Tasks
"

  # Add each issue as a task
  echo "$issues" | jq -c '.[]' | while read -r issue; do
    local num=$(echo "$issue" | jq -r '.number')
    local title=$(echo "$issue" | jq -r '.title')
    local labels=$(echo "$issue" | jq -r '.labels | map(.name) | join(", ")')

    # Check if already in PRD (completed)
    if [[ -f "$PRD_FILE" ]] && grep -qP '^\s*-\s*\[x\].*#'"$num" "$PRD_FILE"; then
      prd_content+="- [x] #$num: $title"
    else
      prd_content+="- [ ] #$num: $title"
    fi

    if [[ -n "$labels" ]]; then
      prd_content+=" ($labels)"
    fi
    prd_content+="
"
  done

  # Add issue details section
  prd_content+="
## Issue Details
"

  echo "$issues" | jq -c '.[]' | while read -r issue; do
    local num=$(echo "$issue" | jq -r '.number')
    local title=$(echo "$issue" | jq -r '.title')
    local body=$(echo "$issue" | jq -r '.body // "No description"' | head -20)

    prd_content+="
### #$num: $title

$body
"
  done

  echo "$prd_content" > "$PRD_FILE"
  echo "Created $PRD_FILE with $count issues"
}

# ============================================
# SYNC PRD STATUS TO ISSUES
# ============================================

sync_issues() {
  echo "Syncing PRD status to GitHub issues..."

  if [[ ! -f "$PRD_FILE" ]]; then
    echo "Error: $PRD_FILE not found" >&2
    exit 1
  fi

  local closed_count=0
  local comment_count=0

  # Find all completed items with issue numbers
  grep -P '^\s*-\s*\[x\].*#\d+' "$PRD_FILE" 2>/dev/null | while read -r line; do
    local issue_num=$(extract_issue_number "$line")

    if [[ -n "$issue_num" ]]; then
      # Check if issue is still open
      local state=$(gh issue view "$issue_num" --json state -q '.state' 2>/dev/null || echo "")

      if [[ "$state" == "OPEN" ]]; then
        if [[ "$CLOSE_ON_COMPLETE" == "true" ]]; then
          # Close the issue
          gh issue close "$issue_num" --comment "Completed via UM Loop" 2>/dev/null
          echo "Closed issue #$issue_num"
          ((closed_count++)) || true
        else
          # Just add a comment
          gh issue comment "$issue_num" --body "Task marked complete in UM Loop PRD" 2>/dev/null
          echo "Commented on issue #$issue_num"
          ((comment_count++)) || true
        fi
      fi
    fi
  done

  echo "Sync complete. Closed: $closed_count, Commented: $comment_count"
}

# ============================================
# CLOSE SPECIFIC ISSUE
# ============================================

close_issue() {
  local issue_num="$1"

  if [[ -z "$issue_num" ]]; then
    echo "Error: Issue number required" >&2
    exit 1
  fi

  issue_num=$(echo "$issue_num" | tr -d '#')

  gh issue close "$issue_num" --comment "Completed via UM Loop"
  echo "Closed issue #$issue_num"
}

# ============================================
# MAIN
# ============================================

case "$ACTION" in
  pull)
    pull_issues
    ;;
  sync)
    sync_issues
    ;;
  close)
    close_issue "$ISSUE_NUMBERS"
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    usage
    ;;
esac

exit 0
