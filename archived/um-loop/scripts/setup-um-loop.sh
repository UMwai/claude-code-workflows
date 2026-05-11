#!/bin/bash

# UM Loop Setup Script v3.0
# Initializes the um-loop with PRD, progress tracking, and state management
# New features: parallel agents, multi-model routing, GitHub issues, auto-merge

set -euo pipefail

# ============================================
# GET SCRIPT DIRECTORY
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# ============================================
# ARGUMENT PARSING
# ============================================

TASK=""
MAX_ITERATIONS=0
PRD_FILE="PRD.md"
PROGRESS_FILE="progress.md"
PROMPT_FILE="PROMPT.md"
SKIP_TESTS=false
SKIP_LINT=false
TEST_CMD=""
LINT_CMD=""
CONFIG_DIR=".um-loop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# New v3.0 flags
PARALLEL_MODE=false
BRANCH_PER_TASK=false
FROM_ISSUES=""
MULTI_MODEL=false
NOTIFY_START=true

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
UM Loop v3.0 - Autonomous task completion with PRD checkboxes

USAGE:
  /um-loop [TASK...] [OPTIONS]
  /um-loop --prd FILE [OPTIONS]
  /um-loop --from-issues FILTER [OPTIONS]

ARGUMENTS:
  TASK...    Task description (creates PRD.md with task breakdown)

OPTIONS:
  --prd FILE              Use existing PRD file (default: PRD.md)
  --max-iterations <n>    Stop after N iterations (default: unlimited)
  --test "CMD"            Run test command after each task
  --lint "CMD"            Run lint command after each task
  --no-tests              Skip test verification
  --no-lint               Skip lint verification
  --fast                  Skip both tests and lint
  -h, --help              Show this help

NEW IN v3.0:
  --parallel              Enable parallel agent mode
  --branch-per-task       Create git branch for each task
  --from-issues FILTER    Pull tasks from GitHub issues
                          Examples: "label:bug", "#123,#124"
  --multi-model           Enable multi-model routing (Gemini/Codex/Claude)
  --no-notify             Skip Discord/Slack notifications

CONFIG:
  /um-loop --init         Create .um-loop/config.yaml with auto-detection
  /um-loop --config       Show current config
  /um-loop --add-rule "rule"  Add rule to config

EXAMPLES:
  /um-loop Build a REST API with CRUD operations
  /um-loop "Add authentication" --parallel --max-iterations 20
  /um-loop --from-issues "label:um-loop" --branch-per-task
  /um-loop --prd tasks.md --multi-model --max-iterations 50

The loop continues until:
  - All PRD checkboxes are marked [x]
  - Max iterations reached
  - DONE marker written to progress.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations requires a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --prd)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --prd requires a file path" >&2
        exit 1
      fi
      PRD_FILE="$2"
      shift 2
      ;;
    --test)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --test requires a command" >&2
        exit 1
      fi
      TEST_CMD="$2"
      shift 2
      ;;
    --lint)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --lint requires a command" >&2
        exit 1
      fi
      LINT_CMD="$2"
      shift 2
      ;;
    --no-tests)
      SKIP_TESTS=true
      shift
      ;;
    --no-lint)
      SKIP_LINT=true
      shift
      ;;
    --fast)
      SKIP_TESTS=true
      SKIP_LINT=true
      shift
      ;;
    # New v3.0 flags
    --parallel)
      PARALLEL_MODE=true
      shift
      ;;
    --branch-per-task)
      BRANCH_PER_TASK=true
      shift
      ;;
    --from-issues)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --from-issues requires a filter (e.g., 'label:bug' or '#123,#124')" >&2
        exit 1
      fi
      FROM_ISSUES="$2"
      shift 2
      ;;
    --multi-model)
      MULTI_MODEL=true
      shift
      ;;
    --no-notify)
      NOTIFY_START=false
      shift
      ;;
    *)
      # Collect task description
      if [[ -n "$TASK" ]]; then
        TASK="$TASK $1"
      else
        TASK="$1"
      fi
      shift
      ;;
  esac
done

# ============================================
# LOAD CONFIG IF EXISTS
# ============================================

if [[ -f "$CONFIG_FILE" ]]; then
  # Load test/lint commands from config if not specified
  if [[ -z "$TEST_CMD" ]] && [[ "$SKIP_TESTS" != "true" ]]; then
    TEST_CMD=$(grep '^\s*test:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*test:\s*//' | sed 's/^"\(.*\)"$/\1/' || echo "")
  fi
  if [[ -z "$LINT_CMD" ]] && [[ "$SKIP_LINT" != "true" ]]; then
    LINT_CMD=$(grep '^\s*lint:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*lint:\s*//' | sed 's/^"\(.*\)"$/\1/' || echo "")
  fi

  # Load v3.0 config values
  CONFIG_PARALLEL=$(grep '^\s*enabled:' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*enabled:\s*//' || echo "")
  CONFIG_BRANCH=$(grep '^\s*branch_per_task:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*branch_per_task:\s*//' || echo "")
  CONFIG_MULTI_MODEL=$(grep -A5 '^models:' "$CONFIG_FILE" 2>/dev/null | grep 'default:' | sed 's/.*default:\s*//' || echo "")

  # Apply config if not overridden by flags
  [[ "$CONFIG_PARALLEL" == "true" ]] && PARALLEL_MODE=true
  [[ "$CONFIG_BRANCH" == "true" ]] && BRANCH_PER_TASK=true
  [[ -n "$CONFIG_MULTI_MODEL" ]] && MULTI_MODEL=true
fi

# ============================================
# HANDLE GITHUB ISSUES
# ============================================

if [[ -n "$FROM_ISSUES" ]]; then
  echo "Pulling tasks from GitHub issues..."

  # Determine filter type
  if [[ "$FROM_ISSUES" == "#"* ]] || [[ "$FROM_ISSUES" =~ ^[0-9] ]]; then
    # Specific issue numbers
    "$SCRIPT_DIR/github-sync.sh" pull --issues "$FROM_ISSUES" --prd "$PRD_FILE"
  else
    # Label filter
    LABEL=$(echo "$FROM_ISSUES" | sed 's/label://')
    "$SCRIPT_DIR/github-sync.sh" pull --labels "$LABEL" --prd "$PRD_FILE"
  fi

  # Set task from PRD objective
  if [[ -f "$PRD_FILE" ]]; then
    TASK=$(grep -A1 '## Objective' "$PRD_FILE" | tail -1 || echo "Complete GitHub issues")
  fi
fi

# ============================================
# VALIDATION
# ============================================

# Need either a task or existing PRD
if [[ -z "$TASK" ]] && [[ ! -f "$PRD_FILE" ]]; then
  echo "Error: Provide a task description or use --prd with existing file" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  /um-loop Build a REST API" >&2
  echo "  /um-loop --prd existing-tasks.md" >&2
  echo "  /um-loop --from-issues 'label:bug'" >&2
  echo "" >&2
  echo "For help: /um-loop --help" >&2
  exit 1
fi

# ============================================
# CREATE FILES
# ============================================

mkdir -p .claude

# If task provided, we'll let Claude create the PRD
# If PRD exists, read it to understand scope
if [[ -n "$TASK" ]] && [[ ! -f "$PRD_FILE" ]]; then
  CREATE_PRD=true
else
  CREATE_PRD=false
fi

# Create progress.md if doesn't exist
if [[ ! -f "$PROGRESS_FILE" ]]; then
  cat > "$PROGRESS_FILE" << EOF
# UM Loop Progress Log

## Session Started
$(date -u +%Y-%m-%dT%H:%M:%SZ)

## Objective
${TASK:-$(head -5 "$PRD_FILE" 2>/dev/null | grep -v '^#' | head -1 || echo "See PRD.md")}

## Configuration
- Parallel mode: $PARALLEL_MODE
- Branch per task: $BRANCH_PER_TASK
- Multi-model: $MULTI_MODEL

---

<!-- Progress entries appended below -->
EOF
fi

# ============================================
# SELECT PROMPT TEMPLATE
# ============================================

if [[ "$PARALLEL_MODE" == "true" ]]; then
  TEMPLATE_FILE="$PLUGIN_ROOT/templates/PROMPT-parallel.md"
else
  TEMPLATE_FILE="$PLUGIN_ROOT/templates/PROMPT.md"
fi

# Create PROMPT.md with agent instructions
if [[ -f "$TEMPLATE_FILE" ]]; then
  cp "$TEMPLATE_FILE" "$PROMPT_FILE"
else
  # Fallback to embedded prompt
  cat > "$PROMPT_FILE" << 'EOF'
# UM Loop Agent Instructions

You are in an autonomous UM Loop. Your goal: complete all tasks in PRD.md.

## Your Cycle (EVERY iteration)

1. **READ PRD.md** - Find the first unchecked `- [ ]` item
2. **READ progress.md** - See what's been done (don't repeat work)
3. **IMPLEMENT** - Complete that ONE item
4. **VERIFY** - Test your work (run tests if configured)
5. **UPDATE progress.md** - Append what you did with timestamp
6. **UPDATE PRD.md** - Change `- [ ]` to `- [x]` for completed item
7. **STOP** - The loop will restart you automatically

## Critical Rules

- **ONE ITEM PER ITERATION** - Do not try to complete multiple items
- **VERIFY BEFORE MARKING** - Only mark [x] when truly complete
- **ALWAYS UPDATE BOTH FILES** - PRD.md checkbox AND progress.md log
- **LEAVE CODE WORKING** - Each iteration must be committable

## Completion

When ALL `- [ ]` items become `- [x]`:
- Write `## DONE` as final line in progress.md
- The loop will automatically stop

## Progress Entry Format

```markdown
## [TIMESTAMP]

### Completed: [Task name from PRD]
- What you did
- How you verified it
- Any notes for next iteration
```
EOF
fi

# Add verification instructions if test/lint configured
if [[ -n "$TEST_CMD" ]] || [[ -n "$LINT_CMD" ]]; then
  cat >> "$PROMPT_FILE" << EOF

## Verification Commands

EOF
  if [[ -n "$TEST_CMD" ]]; then
    echo "- **Tests**: \`$TEST_CMD\` - Run after each task, fix failures before marking complete" >> "$PROMPT_FILE"
  fi
  if [[ -n "$LINT_CMD" ]]; then
    echo "- **Lint**: \`$LINT_CMD\` - Run after each task, fix issues before marking complete" >> "$PROMPT_FILE"
  fi
fi

# Add multi-model instructions if enabled
if [[ "$MULTI_MODEL" == "true" ]]; then
  cat >> "$PROMPT_FILE" << 'EOF'

## Multi-Model Routing

Route tasks to appropriate models based on their nature:

### Gemini (Large Context Research)
Use `mcp__gemini-cli__ask-gemini` for:
- Research and exploration
- Large file analysis (>50KB)
- Codebase-wide understanding

Pattern triggers: research, analyze, explore, review, understand

### Codex (Implementation)
Use `mcp__codex__codex` for:
- Implementation planning
- Architecture design
- Code generation

Pattern triggers: plan, design, architect, implement, build

### Claude (Orchestration)
Handle directly for:
- Tool execution (file writes, git)
- Final decisions and synthesis
- Safety-critical operations

### Workflow
```
Gemini (gather context) → Codex (plan/implement) → Claude (execute/commit)
```
EOF
fi

# Load rules from config if exists
if [[ -f "$CONFIG_FILE" ]]; then
  RULES=$(sed -n '/^rules:/,/^[a-z]/{ /^rules:/d; /^[a-z]/d; p; }' "$CONFIG_FILE" 2>/dev/null | grep '^\s*-' | sed 's/^\s*-\s*//' || echo "")
  if [[ -n "$RULES" ]]; then
    cat >> "$PROMPT_FILE" << EOF

## Project Rules (from .um-loop/config.yaml)

EOF
    echo "$RULES" | while read -r rule; do
      echo "- $rule" >> "$PROMPT_FILE"
    done
  fi
fi

# ============================================
# GIT BRANCH SETUP
# ============================================

CURRENT_BRANCH=""
if [[ "$BRANCH_PER_TASK" == "true" ]]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo "Branch-per-task enabled. Starting from: $CURRENT_BRANCH"
  else
    echo "Warning: --branch-per-task requires a git repository" >&2
    BRANCH_PER_TASK=false
  fi
fi

# ============================================
# CREATE STATE FILE
# ============================================

cat > ".claude/um-loop.local.md" << EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
prd_file: "$PRD_FILE"
progress_file: "$PROGRESS_FILE"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
test_cmd: "$TEST_CMD"
lint_cmd: "$LINT_CMD"

# v3.0 features
parallel_mode: $PARALLEL_MODE
branch_per_task: $BRANCH_PER_TASK
multi_model: $MULTI_MODEL
$(if [[ -n "$CURRENT_BRANCH" ]]; then echo "base_branch: \"$CURRENT_BRANCH\""; fi)
$(if [[ -n "$CURRENT_BRANCH" ]]; then echo "current_branch: \"$CURRENT_BRANCH\""; fi)

# Agent tracking (for parallel mode)
agents: []

# Notifications sent
notifications_sent: []
---

${TASK:-Continue working on PRD.md tasks}
EOF

# ============================================
# SEND START NOTIFICATION
# ============================================

if [[ "$NOTIFY_START" == "true" ]] && [[ -x "$SCRIPT_DIR/notify.sh" ]]; then
  "$SCRIPT_DIR/notify.sh" start "UM Loop started: ${TASK:-PRD.md tasks}" 2>/dev/null || true
fi

# ============================================
# OUTPUT
# ============================================

echo "UM Loop v3.0 activated!"
echo ""
echo "Configuration:"
echo "  PRD file: $PRD_FILE"
echo "  Progress: $PROGRESS_FILE"
echo "  Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)"
if [[ -n "$TEST_CMD" ]]; then
  echo "  Test command: $TEST_CMD"
fi
if [[ -n "$LINT_CMD" ]]; then
  echo "  Lint command: $LINT_CMD"
fi
echo ""
echo "v3.0 Features:"
echo "  Parallel mode: $PARALLEL_MODE"
echo "  Branch per task: $BRANCH_PER_TASK"
echo "  Multi-model: $MULTI_MODEL"
echo ""
echo "The stop hook is now active. When you try to exit, you'll be"
echo "fed the prompt again until all PRD tasks are complete."
echo ""
echo "To monitor: cat .claude/um-loop.local.md"
echo "To cancel: /um-loop cancel"
echo ""

# If we need to create PRD, instruct Claude to do so
if [[ "$CREATE_PRD" == "true" ]]; then
  cat << EOF
---

FIRST: Create $PRD_FILE for this task:

**Task:** $TASK

Create a PRD with:
1. ## Objective section explaining the goal
2. ## Tasks section with checkbox items (- [ ] Task description)
3. Break the task into 3-8 logical, independently verifiable steps
4. Each checkbox should be completable in one iteration
EOF

  if [[ "$PARALLEL_MODE" == "true" ]]; then
    cat << 'EOF'

**Parallel Mode Enabled:**
- Identify which tasks can run independently
- Mark with @agent:N for parallel assignment
- Note dependencies in parentheses

Example:
```
- [ ] @agent:1 Set up server
- [ ] @agent:2 Create database models
- [ ] Implement endpoints (blocked by: 1, 2)
```
EOF
  fi

  echo ""
  echo "Then begin working on the first checkbox item."
else
  cat << EOF
---

PRD loaded from $PRD_FILE

Read the PRD and progress.md, then work on the first unchecked item.
EOF
fi
