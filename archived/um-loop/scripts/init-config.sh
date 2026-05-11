#!/bin/bash

# UM Loop Config Initialization v3.0
# Auto-detects project settings and creates .um-loop/config.yaml
# New: Model routing, git workflow, notifications, GitHub, parallel configs

set -euo pipefail

CONFIG_DIR=".um-loop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Check if config already exists
if [[ -d "$CONFIG_DIR" ]]; then
  echo "Warning: $CONFIG_DIR already exists"
  read -p "Overwrite config? [y/N] " -n 1 -r -t 30 2>/dev/null || REPLY='N'
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

mkdir -p "$CONFIG_DIR"

# ============================================
# AUTO-DETECTION
# ============================================

PROJECT_NAME=$(basename "$PWD")
LANG=""
FRAMEWORK=""
TEST_CMD=""
LINT_CMD=""
BUILD_CMD=""

# Detect from package.json (Node.js projects)
if [[ -f "package.json" ]]; then
  # Get project name
  PKG_NAME=$(jq -r '.name // ""' package.json 2>/dev/null || echo "")
  [[ -n "$PKG_NAME" ]] && PROJECT_NAME="$PKG_NAME"

  # Detect language
  if [[ -f "tsconfig.json" ]]; then
    LANG="TypeScript"
  else
    LANG="JavaScript"
  fi

  # Detect frameworks
  DEPS=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' package.json 2>/dev/null || echo "")
  FRAMEWORKS=()

  echo "$DEPS" | grep -qx "next" && FRAMEWORKS+=("Next.js")
  echo "$DEPS" | grep -qx "nuxt" && FRAMEWORKS+=("Nuxt")
  echo "$DEPS" | grep -qx "@remix-run/react" && FRAMEWORKS+=("Remix")
  echo "$DEPS" | grep -qx "svelte" && FRAMEWORKS+=("Svelte")
  echo "$DEPS" | grep -qE "@nestjs/" && FRAMEWORKS+=("NestJS")
  echo "$DEPS" | grep -qx "hono" && FRAMEWORKS+=("Hono")
  echo "$DEPS" | grep -qx "fastify" && FRAMEWORKS+=("Fastify")
  echo "$DEPS" | grep -qx "express" && FRAMEWORKS+=("Express")

  if [[ ${#FRAMEWORKS[@]} -eq 0 ]]; then
    echo "$DEPS" | grep -qx "react" && FRAMEWORKS+=("React")
    echo "$DEPS" | grep -qx "vue" && FRAMEWORKS+=("Vue")
  fi

  FRAMEWORK=$(IFS=', '; echo "${FRAMEWORKS[*]}")

  # Detect commands from scripts
  SCRIPTS=$(jq -r '.scripts // {}' package.json 2>/dev/null || echo "{}")

  if echo "$SCRIPTS" | jq -e '.test' >/dev/null 2>&1; then
    if [[ -f "bun.lockb" ]]; then
      TEST_CMD="bun test"
    else
      TEST_CMD="npm test"
    fi
  fi

  if echo "$SCRIPTS" | jq -e '.lint' >/dev/null 2>&1; then
    TEST_CMD="${TEST_CMD:-npm run lint}"
    LINT_CMD="npm run lint"
  fi

  if echo "$SCRIPTS" | jq -e '.build' >/dev/null 2>&1; then
    BUILD_CMD="npm run build"
  fi

# Python projects
elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
  LANG="Python"

  PY_DEPS=""
  [[ -f "pyproject.toml" ]] && PY_DEPS=$(cat pyproject.toml 2>/dev/null)
  [[ -f "requirements.txt" ]] && PY_DEPS+=$(cat requirements.txt 2>/dev/null)

  PY_FRAMEWORKS=()
  echo "$PY_DEPS" | grep -qi "fastapi" && PY_FRAMEWORKS+=("FastAPI")
  echo "$PY_DEPS" | grep -qi "django" && PY_FRAMEWORKS+=("Django")
  echo "$PY_DEPS" | grep -qi "flask" && PY_FRAMEWORKS+=("Flask")

  FRAMEWORK=$(IFS=', '; echo "${PY_FRAMEWORKS[*]}")
  TEST_CMD="pytest"
  LINT_CMD="ruff check ."

# Go projects
elif [[ -f "go.mod" ]]; then
  LANG="Go"
  TEST_CMD="go test ./..."
  LINT_CMD="golangci-lint run"

# Rust projects
elif [[ -f "Cargo.toml" ]]; then
  LANG="Rust"
  TEST_CMD="cargo test"
  LINT_CMD="cargo clippy"
  BUILD_CMD="cargo build"
fi

# ============================================
# DETECT GIT INFO
# ============================================

BASE_BRANCH="main"
if git rev-parse --git-dir > /dev/null 2>&1; then
  # Try to detect default branch
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "")
  [[ -n "$DEFAULT_BRANCH" ]] && BASE_BRANCH="$DEFAULT_BRANCH"
fi

# ============================================
# DISPLAY DETECTED SETTINGS
# ============================================

echo ""
echo "Detected:"
echo "  Project:   $PROJECT_NAME"
[[ -n "$LANG" ]] && echo "  Language:  $LANG"
[[ -n "$FRAMEWORK" ]] && echo "  Framework: $FRAMEWORK"
[[ -n "$TEST_CMD" ]] && echo "  Test:      $TEST_CMD"
[[ -n "$LINT_CMD" ]] && echo "  Lint:      $LINT_CMD"
[[ -n "$BUILD_CMD" ]] && echo "  Build:     $BUILD_CMD"
echo "  Git base:  $BASE_BRANCH"
echo ""

# ============================================
# CREATE CONFIG FILE
# ============================================

cat > "$CONFIG_FILE" << EOF
# UM Loop Configuration v3.0
# Auto-generated - edit as needed

# ============================================
# PROJECT INFO
# ============================================

project:
  name: "$PROJECT_NAME"
$(if [[ -n "$LANG" ]]; then echo "  language: \"$LANG\""; fi)
$(if [[ -n "$FRAMEWORK" ]]; then echo "  framework: \"$FRAMEWORK\""; fi)

# ============================================
# COMMANDS
# ============================================

commands:
$(if [[ -n "$TEST_CMD" ]]; then echo "  test: \"$TEST_CMD\""; else echo "  # test: \"npm test\""; fi)
$(if [[ -n "$LINT_CMD" ]]; then echo "  lint: \"$LINT_CMD\""; else echo "  # lint: \"npm run lint\""; fi)
$(if [[ -n "$BUILD_CMD" ]]; then echo "  build: \"$BUILD_CMD\""; else echo "  # build: \"npm run build\""; fi)

# ============================================
# RULES
# ============================================

# Rules the AI must follow (add your own)
rules:
  # - "use TypeScript strict mode"
  # - "follow existing code patterns"
  # - "add tests for new features"
  # - "use server actions not API routes"

# ============================================
# BOUNDARIES
# ============================================

# Files/directories the AI should never modify
boundaries:
  never_touch:
    # - "src/legacy/**"
    # - "*.lock"
    # - ".env*"

# ============================================
# MODEL ROUTING (v3.0)
# ============================================

# Route tasks to specialized models
models:
  default: "claude"
  # research: "gemini"    # Large context analysis
  # planning: "codex"     # Architecture design

# Pattern-based routing rules
routing:
  - pattern: "research|analyze|explore|review|understand|summarize"
    model: gemini
  - pattern: "plan|design|architect"
    model: codex
  - pattern: "implement|build|fix|refactor"
    model: claude

# ============================================
# GIT WORKFLOW (v3.0)
# ============================================

git:
  branch_per_task: false       # Create branch for each task
  auto_commit: true            # Auto-commit after task completion
  auto_merge: false            # Auto-merge task branches when done
  base_branch: "$BASE_BRANCH"
  branch_prefix: "um-loop/"

# ============================================
# NOTIFICATIONS (v3.0)
# ============================================

notifications:
  # Discord webhook
  discord:
    webhook: ""                # Set via env: UM_LOOP_DISCORD_WEBHOOK
    events: [complete, error, milestone]

  # Slack webhook
  slack:
    webhook: ""                # Set via env: UM_LOOP_SLACK_WEBHOOK
    events: [complete]

# ============================================
# GITHUB INTEGRATION (v3.0)
# ============================================

github:
  sync_issues: false           # Sync PRD with GitHub issues
  close_on_complete: false     # Close issues when tasks complete
  labels: ["um-loop"]          # Default labels for created issues

# ============================================
# PARALLEL EXECUTION (v3.0)
# ============================================

parallel:
  enabled: false               # Enable parallel agent mode
  max_agents: 3                # Max concurrent subagents
  strategy: "independent"      # "independent" or "coordinated"

# ============================================
# TASK SOURCES
# ============================================

task_sources:
  - "PRD.md"
  # - "tasks/*.md"
  # - "TODO.md"
EOF

echo "Created $CONFIG_FILE"
echo ""
echo "v3.0 Features:"
echo "  - Model routing (Gemini/Codex/Claude)"
echo "  - Git workflow (branch-per-task, auto-merge)"
echo "  - Notifications (Discord/Slack webhooks)"
echo "  - GitHub integration (issues sync)"
echo "  - Parallel agents (Task subagents)"
echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG_FILE to enable features"
echo "  2. Set webhook URLs for notifications"
echo "  3. Run /um-loop \"your task\" to start"
echo ""
