#!/bin/bash

# UM Loop Notification Script
# Sends webhook notifications to Discord/Slack for key events

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

CONFIG_DIR=".um-loop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
STATE_FILE=".claude/um-loop.local.md"

# ============================================
# ARGUMENT PARSING
# ============================================

EVENT_TYPE=""
MESSAGE=""
TITLE=""
COLOR=""

usage() {
  cat << 'EOF'
Usage: notify.sh [OPTIONS] EVENT_TYPE MESSAGE

EVENT_TYPE:
  start       - Loop started
  complete    - All tasks finished
  error       - Error occurred
  milestone   - Progress milestone (e.g., 50% done)
  task        - Single task completed

OPTIONS:
  --title TEXT    Custom title for the notification
  --color HEX     Custom color (Discord only, e.g., 65280 for green)
  -h, --help      Show this help

EXAMPLES:
  notify.sh complete "All 7 tasks finished successfully"
  notify.sh milestone "50% complete (4/8 tasks)"
  notify.sh error "Build failed on task 3"
  notify.sh task "Completed: Add authentication module"
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --color)
      COLOR="$2"
      shift 2
      ;;
    *)
      if [[ -z "$EVENT_TYPE" ]]; then
        EVENT_TYPE="$1"
      elif [[ -z "$MESSAGE" ]]; then
        MESSAGE="$1"
      else
        MESSAGE="$MESSAGE $1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$EVENT_TYPE" ]] || [[ -z "$MESSAGE" ]]; then
  echo "Error: EVENT_TYPE and MESSAGE required" >&2
  echo "Usage: notify.sh EVENT_TYPE MESSAGE" >&2
  exit 1
fi

# ============================================
# LOAD CONFIG
# ============================================

DISCORD_WEBHOOK=""
DISCORD_EVENTS=""
SLACK_WEBHOOK=""
SLACK_EVENTS=""

if [[ -f "$CONFIG_FILE" ]]; then
  # Parse Discord config
  DISCORD_WEBHOOK=$(grep -A5 '^\s*discord:' "$CONFIG_FILE" 2>/dev/null | grep 'webhook:' | sed 's/.*webhook:\s*//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'" || echo "")
  DISCORD_EVENTS=$(grep -A5 '^\s*discord:' "$CONFIG_FILE" 2>/dev/null | grep 'events:' | sed 's/.*events:\s*//' | tr -d '[]' || echo "")

  # Parse Slack config
  SLACK_WEBHOOK=$(grep -A5 '^\s*slack:' "$CONFIG_FILE" 2>/dev/null | grep 'webhook:' | sed 's/.*webhook:\s*//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'" || echo "")
  SLACK_EVENTS=$(grep -A5 '^\s*slack:' "$CONFIG_FILE" 2>/dev/null | grep 'events:' | sed 's/.*events:\s*//' | tr -d '[]' || echo "")
fi

# Check environment variables as fallback
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-${UM_LOOP_DISCORD_WEBHOOK:-}}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-${UM_LOOP_SLACK_WEBHOOK:-}}"

# ============================================
# HELPER FUNCTIONS
# ============================================

# Check if event should trigger notification
should_notify() {
  local events="$1"
  local event="$2"

  # Empty events list means all events
  if [[ -z "$events" ]]; then
    return 0
  fi

  # Check if event is in the list
  if echo "$events" | grep -qi "$event"; then
    return 0
  fi

  return 1
}

# Get color based on event type
get_color() {
  case "$EVENT_TYPE" in
    start)
      echo "3447003"  # Blue
      ;;
    complete)
      echo "65280"    # Green
      ;;
    error)
      echo "16711680" # Red
      ;;
    milestone)
      echo "16776960" # Yellow
      ;;
    task)
      echo "8421504"  # Gray
      ;;
    *)
      echo "7506394"  # Purple (default)
      ;;
  esac
}

# Get emoji based on event type
get_emoji() {
  case "$EVENT_TYPE" in
    start)
      echo ":rocket:"
      ;;
    complete)
      echo ":white_check_mark:"
      ;;
    error)
      echo ":x:"
      ;;
    milestone)
      echo ":chart_with_upwards_trend:"
      ;;
    task)
      echo ":heavy_check_mark:"
      ;;
    *)
      echo ":information_source:"
      ;;
  esac
}

# Get default title based on event type
get_default_title() {
  case "$EVENT_TYPE" in
    start)
      echo "UM Loop Started"
      ;;
    complete)
      echo "UM Loop Complete!"
      ;;
    error)
      echo "UM Loop Error"
      ;;
    milestone)
      echo "UM Loop Progress"
      ;;
    task)
      echo "Task Completed"
      ;;
    *)
      echo "UM Loop Notification"
      ;;
  esac
}

# Get project name from config or directory
get_project_name() {
  local project_name=""

  if [[ -f "$CONFIG_FILE" ]]; then
    project_name=$(grep '^\s*name:' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*name:\s*//' | sed 's/^"\(.*\)"$/\1/' || echo "")
  fi

  echo "${project_name:-$(basename "$PWD")}"
}

# Get iteration info from state file
get_iteration_info() {
  if [[ -f "$STATE_FILE" ]]; then
    local iteration=$(grep '^iteration:' "$STATE_FILE" | sed 's/iteration: *//')
    echo "Iteration: ${iteration:-unknown}"
  else
    echo ""
  fi
}

# ============================================
# SEND NOTIFICATIONS
# ============================================

# Send Discord notification
send_discord() {
  local webhook="$1"

  if [[ -z "$webhook" ]]; then
    return 0
  fi

  # Check if this event should trigger notification
  if ! should_notify "$DISCORD_EVENTS" "$EVENT_TYPE"; then
    return 0
  fi

  local title="${TITLE:-$(get_default_title)}"
  local color="${COLOR:-$(get_color)}"
  local project=$(get_project_name)
  local iteration_info=$(get_iteration_info)

  # Build the payload
  local payload=$(jq -n \
    --arg title "$title" \
    --arg desc "$MESSAGE" \
    --arg color "$color" \
    --arg project "$project" \
    --arg iter "$iteration_info" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      embeds: [{
        title: $title,
        description: $desc,
        color: ($color | tonumber),
        fields: [
          { name: "Project", value: $project, inline: true },
          { name: "Info", value: (if $iter != "" then $iter else "N/A" end), inline: true }
        ],
        timestamp: $timestamp,
        footer: { text: "UM Loop v3.0" }
      }]
    }')

  # Send the request
  if curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$webhook" > /dev/null 2>&1; then
    echo "Discord notification sent: $EVENT_TYPE"
  else
    echo "Warning: Failed to send Discord notification" >&2
  fi
}

# Send Slack notification
send_slack() {
  local webhook="$1"

  if [[ -z "$webhook" ]]; then
    return 0
  fi

  # Check if this event should trigger notification
  if ! should_notify "$SLACK_EVENTS" "$EVENT_TYPE"; then
    return 0
  fi

  local title="${TITLE:-$(get_default_title)}"
  local emoji=$(get_emoji)
  local project=$(get_project_name)
  local iteration_info=$(get_iteration_info)

  # Build the payload
  local payload=$(jq -n \
    --arg title "$title" \
    --arg msg "$MESSAGE" \
    --arg emoji "$emoji" \
    --arg project "$project" \
    --arg iter "$iteration_info" \
    '{
      blocks: [
        {
          type: "header",
          text: { type: "plain_text", text: ($emoji + " " + $title) }
        },
        {
          type: "section",
          text: { type: "mrkdwn", text: $msg }
        },
        {
          type: "context",
          elements: [
            { type: "mrkdwn", text: ("*Project:* " + $project) },
            { type: "mrkdwn", text: (if $iter != "" then ("*" + $iter + "*") else "" end) }
          ]
        }
      ]
    }')

  # Send the request
  if curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$webhook" > /dev/null 2>&1; then
    echo "Slack notification sent: $EVENT_TYPE"
  else
    echo "Warning: Failed to send Slack notification" >&2
  fi
}

# ============================================
# MAIN
# ============================================

# Check if any webhook is configured
if [[ -z "$DISCORD_WEBHOOK" ]] && [[ -z "$SLACK_WEBHOOK" ]]; then
  # No webhooks configured - silent exit (not an error)
  exit 0
fi

# Send notifications
send_discord "$DISCORD_WEBHOOK"
send_slack "$SLACK_WEBHOOK"

exit 0
