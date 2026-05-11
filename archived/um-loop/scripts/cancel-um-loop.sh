#!/bin/bash

# Cancel active UM Loop

set -euo pipefail

STATE_FILE=".claude/um-loop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No active UM Loop found."
  exit 0
fi

# Get iteration count before removing
ITERATION=$(grep '^iteration:' "$STATE_FILE" 2>/dev/null | sed 's/iteration: *//' || echo "unknown")

rm "$STATE_FILE"

echo "Cancelled UM Loop (was at iteration $ITERATION)"
echo ""
echo "Files preserved:"
echo "  - PRD.md (your task list)"
echo "  - progress.md (work log)"
echo "  - PROMPT.md (agent instructions)"
echo ""
echo "To resume: /um-loop (will continue from where you left off)"
