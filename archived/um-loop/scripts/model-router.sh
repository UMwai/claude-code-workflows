#!/bin/bash

# UM Loop Model Router
# Routes tasks to appropriate model (Gemini/Codex/Claude) based on task content

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

CONFIG_DIR=".um-loop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Default model
DEFAULT_MODEL="claude"

# Default routing patterns
declare -A DEFAULT_PATTERNS
DEFAULT_PATTERNS["gemini"]="research|analyze|explore|review|understand|summarize|document|explain"
DEFAULT_PATTERNS["codex"]="plan|design|architect|implement|build|code|refactor|create"
DEFAULT_PATTERNS["claude"]=".*"  # Fallback

# ============================================
# ARGUMENT PARSING
# ============================================

ACTION=""
TASK_TEXT=""
OUTPUT_FORMAT="simple"  # simple, json, instructions

usage() {
  cat << 'EOF'
Usage: model-router.sh ACTION [OPTIONS]

ACTIONS:
  route "TASK TEXT"     Determine which model should handle this task
  generate-prompt       Generate prompt with model routing instructions
  list-patterns         Show current routing patterns

OPTIONS:
  --format FORMAT       Output format: simple, json, instructions
  -h, --help            Show this help

EXAMPLES:
  model-router.sh route "Research best practices for caching"
  model-router.sh route "Implement the authentication module"
  model-router.sh generate-prompt

CONFIG:
  Set in .um-loop/config.yaml:
    models:
      default: "claude"
      research: "gemini"
      planning: "codex"

    routing:
      - pattern: "research|analyze|explore"
        model: gemini
      - pattern: "plan|design|architect"
        model: codex
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    --format)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    route|generate-prompt|list-patterns)
      ACTION="$1"
      shift
      ;;
    *)
      if [[ -z "$TASK_TEXT" ]]; then
        TASK_TEXT="$1"
      else
        TASK_TEXT="$TASK_TEXT $1"
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

# Storage for routing rules
declare -a PATTERNS
declare -a MODELS

# Load from config file
load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return
  fi

  # Load default model
  local config_default=$(grep -E '^\s*default:' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*default:\s*//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'" || echo "")
  [[ -n "$config_default" ]] && DEFAULT_MODEL="$config_default"

  # Load routing rules
  local in_routing=false
  local current_pattern=""

  while IFS= read -r line; do
    # Check if entering routing section
    if [[ "$line" =~ ^routing: ]]; then
      in_routing=true
      continue
    fi

    # Check if leaving routing section
    if [[ "$in_routing" == "true" ]] && [[ "$line" =~ ^[a-z]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      in_routing=false
    fi

    if [[ "$in_routing" == "true" ]]; then
      # Extract pattern
      if [[ "$line" =~ pattern: ]]; then
        current_pattern=$(echo "$line" | sed 's/.*pattern:\s*//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'")
      fi

      # Extract model
      if [[ "$line" =~ model: ]] && [[ -n "$current_pattern" ]]; then
        local model=$(echo "$line" | sed 's/.*model:\s*//' | sed 's/^"\(.*\)"$/\1/' | tr -d "'")
        PATTERNS+=("$current_pattern")
        MODELS+=("$model")
        current_pattern=""
      fi
    fi
  done < "$CONFIG_FILE"
}

load_config

# Use defaults if no patterns loaded
if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  PATTERNS+=("${DEFAULT_PATTERNS["gemini"]}")
  MODELS+=("gemini")
  PATTERNS+=("${DEFAULT_PATTERNS["codex"]}")
  MODELS+=("codex")
fi

# ============================================
# ROUTE TASK
# ============================================

route_task() {
  if [[ -z "$TASK_TEXT" ]]; then
    echo "Error: Task text required" >&2
    exit 1
  fi

  local task_lower=$(echo "$TASK_TEXT" | tr '[:upper:]' '[:lower:]')
  local matched_model="$DEFAULT_MODEL"

  # Check each pattern
  for i in "${!PATTERNS[@]}"; do
    if echo "$task_lower" | grep -qiE "${PATTERNS[$i]}"; then
      matched_model="${MODELS[$i]}"
      break
    fi
  done

  case "$OUTPUT_FORMAT" in
    simple)
      echo "$matched_model"
      ;;
    json)
      jq -n \
        --arg task "$TASK_TEXT" \
        --arg model "$matched_model" \
        '{task: $task, model: $model}'
      ;;
    instructions)
      generate_instructions "$matched_model"
      ;;
  esac
}

# ============================================
# GENERATE INSTRUCTIONS
# ============================================

generate_instructions() {
  local model="${1:-$DEFAULT_MODEL}"

  case "$model" in
    gemini)
      cat << 'EOF'
## Model Routing: Use Gemini

This task should be routed to Gemini (via `mcp__gemini-cli__ask-gemini`) because it involves:
- Large context analysis (1M token window)
- Research or exploration
- Codebase-wide understanding
- Documentation review

**How to use:**
```
Use mcp__gemini-cli__ask-gemini with:
  prompt: "@relevant-files.py Analyze/research/summarize..."
```

After Gemini returns, synthesize the results and continue with implementation.
EOF
      ;;
    codex)
      cat << 'EOF'
## Model Routing: Use Codex

This task should be routed to Codex (via `mcp__codex__codex`) because it involves:
- Implementation planning
- Architecture design
- Code generation
- Step-by-step development

**How to use:**
```
Use mcp__codex__codex with:
  prompt: "Plan/implement/build..."
  approval-policy: "never"
  sandbox: "danger-full-access"
```

After Codex returns the plan/code, review and apply the changes.
EOF
      ;;
    claude|*)
      cat << 'EOF'
## Model Routing: Use Claude (Default)

This task should be handled directly by Claude because it involves:
- Tool execution (file writes, git operations)
- Final orchestration
- Safety-critical review
- Interactive refinement

Continue working on this task directly using Claude's tools.
EOF
      ;;
  esac
}

# ============================================
# GENERATE PROMPT
# ============================================

generate_prompt() {
  cat << 'EOF'
## Multi-Model Routing

You have access to multiple AI models for different tasks. Route appropriately:

### Gemini (Large Context Research)
Use `mcp__gemini-cli__ask-gemini` for:
- Research and exploration
- Large file analysis (>50KB)
- Codebase-wide understanding
- Documentation review

Pattern triggers: research, analyze, explore, review, understand, summarize

Example:
```
mcp__gemini-cli__ask-gemini with prompt: "@src/**/*.ts Analyze the authentication patterns used"
```

### Codex (Implementation)
Use `mcp__codex__codex` for:
- Implementation planning
- Architecture design
- Code generation
- Complex refactoring

Pattern triggers: plan, design, architect, implement, build, create

Example:
```
mcp__codex__codex with prompt: "Implement user authentication with JWT" approval-policy: "never" sandbox: "danger-full-access"
```

### Claude (Orchestration)
Handle directly for:
- Tool execution (file writes, git)
- Final decisions and synthesis
- Safety-critical operations
- Interactive refinement

### Workflow Pattern
```
Gemini (gather context) → Codex (plan/implement) → Claude (execute/commit)
```

When working on a task:
1. Identify the primary nature of the task
2. Route to appropriate model if beneficial
3. Synthesize results and continue

Not all tasks need routing - simple tasks can be done directly by Claude.
EOF
}

# ============================================
# LIST PATTERNS
# ============================================

list_patterns() {
  echo "Model Routing Patterns"
  echo "======================"
  echo ""
  echo "Default model: $DEFAULT_MODEL"
  echo ""
  echo "Routing rules:"

  for i in "${!PATTERNS[@]}"; do
    echo "  ${MODELS[$i]}: ${PATTERNS[$i]}"
  done

  echo ""
  echo "Config file: $CONFIG_FILE"
}

# ============================================
# MAIN
# ============================================

case "$ACTION" in
  route)
    route_task
    ;;
  generate-prompt)
    generate_prompt
    ;;
  list-patterns)
    list_patterns
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    usage
    ;;
esac

exit 0
