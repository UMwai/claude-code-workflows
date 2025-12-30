# claude-code-workflows Architecture

## System Overview

claude-code-workflows provides structured, repeatable workflows for Claude Code, enabling consistent quality and productivity across development tasks.

---

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     WORKFLOW LIBRARY                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│
│  │   Reviews   │  │ Development │  │   Testing   │  │   DevOps    ││
│  │  Workflows  │  │  Workflows  │  │  Workflows  │  │  Workflows  ││
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘│
│         └─────────────────┴─────────────────┴─────────────────┘     │
│                                    │                                 │
│  ┌─────────────────────────────────▼─────────────────────────────┐  │
│  │                    EXECUTION LAYER                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │  │
│  │  │    Slash    │  │   Subagent  │  │  CLAUDE.md  │            │  │
│  │  │   Commands  │  │   Configs   │  │   Snippets  │            │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │  │
│  └─────────────────────────────────┬─────────────────────────────┘  │
│                                    │                                 │
│  ┌─────────────────────────────────▼─────────────────────────────┐  │
│  │                    INTEGRATION LAYER                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │  │
│  │  │  Playwright │  │   GitHub    │  │    CI/CD    │            │  │
│  │  │   Testing   │  │   Actions   │  │   Pipelines │            │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Slash Commands

Slash commands provide quick invocation of workflows from within Claude Code.

**Structure**:
```markdown
# /workflow-name

## Description
Brief description of what this workflow does.

## Usage
```
/workflow-name [options]
```

## Steps
1. Step 1 description
2. Step 2 description
3. Step 3 description

## Output
Description of expected output.
```

**Example: Design Review Slash Command**:
```markdown
# /design-review

## Description
Performs comprehensive UI/UX design review on current changes.

## Usage
```
/design-review           # Review working changes
/design-review --pr 123  # Review specific PR
```

## Steps
1. Identify frontend changes
2. Start Playwright for visual testing
3. Analyze against design principles
4. Generate review report

## Output
Structured design review with:
- Visual hierarchy analysis
- Accessibility findings
- Responsiveness check
- Recommendations
```

### 2. Subagent Configurations

Subagents are specialized Claude instances focused on specific tasks.

**Structure**:
```markdown
# Subagent: [Agent Name]

## Purpose
What this subagent specializes in.

## Configuration
```json
{
  "agent": "subagent-name",
  "focus": ["area1", "area2"],
  "tools": ["tool1", "tool2"]
}
```

## System Prompt
The system prompt for this subagent.

## Handoff Protocol
How to pass context to/from this subagent.
```

**Example: Design Review Subagent**:
```markdown
# Subagent: Design Review Specialist

## Purpose
Expert in UI/UX design principles, accessibility, and visual design.

## Configuration
```json
{
  "agent": "design-review",
  "focus": ["ui", "ux", "accessibility", "visual-design"],
  "tools": ["playwright", "lighthouse"]
}
```

## System Prompt
You are an expert UI/UX design reviewer with deep knowledge of:
- Visual hierarchy and composition
- Accessibility (WCAG AA+)
- Responsive design patterns
- Design systems (Stripe, Airbnb, Linear)

When reviewing, evaluate:
1. Visual hierarchy and information architecture
2. Color contrast and accessibility
3. Responsive behavior
4. Consistency with design system
5. User interaction patterns

## Handoff Protocol
Receives: List of changed files, component screenshots
Returns: Structured review with severity ratings
```

### 3. CLAUDE.md Snippets

Reusable snippets that can be added to project CLAUDE.md files.

**Structure**:
```markdown
# CLAUDE.md Snippet: [Name]

## Purpose
What this snippet enables.

## Installation
Add to your project's CLAUDE.md file.

## Snippet
```markdown
[Actual snippet content]
```

## Usage
How to use the functionality this snippet provides.
```

**Example: Design Principles Snippet**:
```markdown
# CLAUDE.md Snippet: Design Principles

## Purpose
Embeds design review standards into project context.

## Installation
Copy the snippet below to your .claude/CLAUDE.md

## Snippet
```markdown
## Design Standards

### Visual Hierarchy
- Clear heading hierarchy (H1 > H2 > H3)
- Consistent spacing scale
- Logical reading flow

### Accessibility
- WCAG AA minimum compliance
- Keyboard navigation support
- Screen reader compatibility
- Color contrast ratios >= 4.5:1

### Responsiveness
- Mobile-first approach
- Breakpoints: 640px, 768px, 1024px, 1280px
- Touch-friendly targets (min 44px)
```

## Usage
Reference when requesting design reviews or building UI.
```

---

## Workflow Anatomy

### Complete Workflow Structure

```
workflow-name/
├── README.md                 # Workflow overview
│
├── slash-command.md          # Slash command definition
│   ├── Description
│   ├── Usage examples
│   ├── Options/flags
│   └── Expected output
│
├── agent-config.md           # Subagent configuration
│   ├── Purpose
│   ├── System prompt
│   ├── Tool access
│   └── Handoff protocol
│
├── claude-md-snippet.md      # CLAUDE.md integration
│   ├── Context snippet
│   ├── Guidelines snippet
│   └── Commands snippet
│
├── principles/               # Domain-specific principles
│   ├── principles-guide.md
│   └── checklist.md
│
├── examples/                 # Example outputs
│   ├── example-simple.md
│   ├── example-complex.md
│   └── example-edge-case.md
│
└── tests/                    # Workflow validation
    ├── test-scenarios.md
    └── expected-outputs/
```

---

## Workflow Execution Flow

### Single Workflow Execution

```
User Invocation
/design-review
     │
     v
┌─────────────────┐
│  Parse Command  │
│  - Extract args │
│  - Load config  │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Context Gather  │
│ - File changes  │
│ - Screenshots   │
│ - History       │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Subagent Invoke │
│ - System prompt │
│ - Context pass  │
│ - Tool access   │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Process Results │
│ - Parse output  │
│ - Format report │
│ - Apply actions │
└────────┬────────┘
         │
         v
     Output
```

### Multi-Phase Workflow

```
Phase 1: Analysis         Phase 2: Review          Phase 3: Action
┌────────────────┐       ┌────────────────┐       ┌────────────────┐
│ Gather context │──────►│ Evaluate code  │──────►│ Apply fixes    │
│ - Diff files   │       │ - Quality      │       │ - Auto-fix     │
│ - Dependencies │       │ - Standards    │       │ - Suggestions  │
└────────────────┘       └────────────────┘       └────────────────┘
```

---

## Tool Integrations

### Playwright Integration

For visual testing and screenshot capture.

```typescript
// playwright.config.ts
export default {
  use: {
    screenshot: 'on',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'Desktop Chrome', use: { browserName: 'chromium' } },
    { name: 'Mobile Safari', use: { browserName: 'webkit', viewport: { width: 375, height: 667 } } },
  ],
};
```

**Usage in Workflow**:
```markdown
## Step 2: Visual Testing

1. Start Playwright: `npx playwright test --ui`
2. Navigate to changed components
3. Capture screenshots at breakpoints
4. Compare with baseline
```

### GitHub Actions Integration

For automated workflow execution on PRs.

```yaml
# .github/workflows/design-review.yml
name: Design Review
on:
  pull_request:
    paths:
      - 'src/components/**'
      - 'src/pages/**'

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Design Review
        run: |
          # Execute design review workflow
          claude /design-review --pr ${{ github.event.pull_request.number }}
```

### Lighthouse Integration

For performance and accessibility auditing.

```javascript
// lighthouse-config.js
module.exports = {
  extends: 'lighthouse:default',
  settings: {
    onlyCategories: ['accessibility', 'best-practices'],
    emulatedFormFactor: 'mobile',
  },
};
```

---

## Configuration Hierarchy

```
User Project                    Workflow Library
     │                               │
     v                               v
┌──────────────┐           ┌──────────────────┐
│ CLAUDE.md    │◄──────────│ Snippet Template │
│ (project)    │           │                  │
└──────────────┘           └──────────────────┘
     │
     ├── Project context
     ├── Workflow snippets (imported)
     └── Custom overrides

Effective Configuration = Base + Snippets + Project Overrides
```

---

## Quality Standards

### Workflow Completeness Checklist

- [ ] README with clear description
- [ ] Slash command with usage examples
- [ ] Subagent configuration (if applicable)
- [ ] CLAUDE.md snippet (if applicable)
- [ ] At least 2 examples
- [ ] Test scenarios defined

### Output Quality Standards

| Aspect | Standard |
|--------|----------|
| Format | Consistent markdown structure |
| Depth | Actionable recommendations |
| Clarity | No ambiguous findings |
| Completeness | All relevant areas covered |

---

## Extension Points

### Creating New Workflows

1. Copy workflow template
2. Define slash command
3. Configure subagent (optional)
4. Create CLAUDE.md snippet
5. Add examples
6. Document test scenarios

### Customizing Existing Workflows

1. Fork workflow directory
2. Modify configurations
3. Add custom principles
4. Update examples
5. Test modifications

---

*Last Updated: December 2024*
