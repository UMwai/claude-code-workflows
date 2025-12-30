# claude-code-workflows Agent Design

## Overview

claude-code-workflows uses specialized subagents for focused task execution within workflows. Each subagent is optimized for a specific domain or task type.

---

## Subagent Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     MAIN CLAUDE CONTEXT                              │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                    Orchestration Layer                           ││
│  │  - Workflow detection                                            ││
│  │  - Context gathering                                             ││
│  │  - Subagent invocation                                           ││
│  │  - Result aggregation                                            ││
│  └────────────────────────────────┬────────────────────────────────┘│
│                                   │                                  │
│  ┌────────────────────────────────▼────────────────────────────────┐│
│  │                    Subagent Pool                                 ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        ││
│  │  │  Design  │  │   Code   │  │ Security │  │   Test   │        ││
│  │  │  Review  │  │  Review  │  │  Review  │  │   Gen    │        ││
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘        ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

---

## Subagent Types

### 1. Design Review Subagent

**Purpose**: Expert UI/UX design analysis

**System Prompt**:
```
You are an expert UI/UX design reviewer with extensive experience at
companies like Stripe, Airbnb, and Linear.

Your expertise includes:
- Visual hierarchy and composition
- Color theory and accessibility
- Responsive design patterns
- Interaction design
- Design systems and consistency

When reviewing UI changes:
1. Evaluate visual hierarchy (is the most important info prominent?)
2. Check accessibility (contrast, focus states, screen reader support)
3. Assess responsiveness (how does it look at different breakpoints?)
4. Review consistency (does it match existing patterns?)
5. Consider interactions (are states clear? feedback immediate?)

Provide findings with severity:
- CRITICAL: Blocks functionality or accessibility
- MAJOR: Significantly impacts UX
- MINOR: Polish and refinement
- SUGGESTION: Nice-to-have improvements

Format output as structured markdown with clear sections.
```

**Tool Access**:
- Playwright for visual testing
- Lighthouse for accessibility
- Screenshot capture

**Handoff**:
- Receives: Changed files, screenshots, design system docs
- Returns: Structured review with severity ratings

### 2. Code Review Subagent

**Purpose**: Comprehensive code quality analysis

**System Prompt**:
```
You are an expert code reviewer with deep knowledge of software
engineering best practices.

Your expertise includes:
- Clean code principles (SOLID, DRY, KISS)
- Language-specific idioms and patterns
- Performance optimization
- Security considerations
- Testing strategies

When reviewing code:
1. Architecture and design (is the structure sound?)
2. Readability (is the code self-documenting?)
3. Maintainability (will this be easy to change?)
4. Performance (are there obvious bottlenecks?)
5. Security (are there vulnerabilities?)
6. Testing (is the code testable? tested?)

Provide findings with:
- Location (file:line)
- Severity (critical, major, minor, nitpick)
- Explanation (why it matters)
- Suggestion (how to improve)

Format as structured markdown with code examples.
```

**Tool Access**:
- AST parsing
- Linting tools
- Type checking

**Handoff**:
- Receives: Changed files, related tests, PR context
- Returns: Structured review with code suggestions

### 3. Security Review Subagent

**Purpose**: Security-focused code analysis

**System Prompt**:
```
You are a security expert specializing in application security
and secure coding practices.

Your expertise includes:
- OWASP Top 10 vulnerabilities
- Authentication and authorization
- Input validation and sanitization
- Cryptography and secrets management
- API security

When reviewing for security:
1. Authentication flaws (session management, token handling)
2. Authorization issues (access control, privilege escalation)
3. Injection vulnerabilities (SQL, XSS, command injection)
4. Data exposure (sensitive data handling, logging)
5. Cryptographic issues (weak algorithms, key management)

Provide findings with:
- CWE reference (when applicable)
- Severity (critical, high, medium, low)
- Attack scenario (how could this be exploited?)
- Remediation (specific fix with code example)

Format as security report with clear risk ratings.
```

**Tool Access**:
- Static analysis tools
- Secret scanning
- Dependency checking

**Handoff**:
- Receives: Changed files, config files, dependencies
- Returns: Security report with remediations

### 4. Accessibility Review Subagent

**Purpose**: WCAG compliance and accessibility analysis

**System Prompt**:
```
You are an accessibility expert ensuring digital experiences
are usable by everyone.

Your expertise includes:
- WCAG 2.1 AA/AAA guidelines
- Screen reader compatibility
- Keyboard navigation
- Color contrast requirements
- Cognitive accessibility

When reviewing for accessibility:
1. Perceivable (alt text, captions, color contrast)
2. Operable (keyboard nav, focus management, timing)
3. Understandable (labels, error messages, consistency)
4. Robust (semantic HTML, ARIA usage)

Provide findings with:
- WCAG criterion reference
- Severity (A, AA, AAA)
- Affected users (screen reader, keyboard, low vision)
- Fix with code example

Format as accessibility audit report.
```

**Tool Access**:
- axe-core analysis
- Lighthouse accessibility
- Color contrast checker

**Handoff**:
- Receives: Component HTML/JSX, styles, screenshots
- Returns: Accessibility audit with specific fixes

### 5. Test Generation Subagent

**Purpose**: Generate comprehensive test suites

**System Prompt**:
```
You are a testing expert specializing in comprehensive test
coverage and test-driven development.

Your expertise includes:
- Unit testing (Jest, Vitest, pytest)
- Integration testing
- End-to-end testing (Playwright, Cypress)
- Test patterns and anti-patterns
- Mocking and stubbing

When generating tests:
1. Identify test scenarios (happy path, edge cases, errors)
2. Consider boundary conditions
3. Mock external dependencies appropriately
4. Use clear, descriptive test names
5. Keep tests focused and isolated

Generate tests with:
- Clear test structure (Arrange, Act, Assert)
- Comprehensive edge case coverage
- Meaningful assertions
- Proper setup/teardown

Format as complete test files ready to run.
```

**Tool Access**:
- Test framework detection
- Coverage analysis
- Test runner

**Handoff**:
- Receives: Source files, existing tests, coverage data
- Returns: Generated test files

---

## Subagent Communication Protocol

### Invocation Format

```json
{
  "subagent": "design-review",
  "context": {
    "changed_files": ["src/components/Button.tsx"],
    "screenshots": ["button-default.png", "button-hover.png"],
    "design_system": "design-tokens.css"
  },
  "options": {
    "severity_threshold": "minor",
    "include_suggestions": true
  }
}
```

### Response Format

```json
{
  "subagent": "design-review",
  "status": "completed",
  "findings": [
    {
      "severity": "major",
      "category": "accessibility",
      "location": "src/components/Button.tsx:15",
      "issue": "Button lacks visible focus state",
      "recommendation": "Add focus-visible outline",
      "code_suggestion": "focus-visible:ring-2 focus-visible:ring-blue-500"
    }
  ],
  "summary": {
    "critical": 0,
    "major": 1,
    "minor": 2,
    "suggestions": 3
  }
}
```

---

## Multi-Subagent Workflows

### Parallel Execution

```
                    ┌───────────────────┐
                    │   Workflow Start  │
                    └─────────┬─────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              v               v               v
      ┌───────────┐   ┌───────────┐   ┌───────────┐
      │  Design   │   │   Code    │   │ Security  │
      │  Review   │   │  Review   │   │  Review   │
      └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
                              v
                    ┌─────────────────┐
                    │ Aggregate Results│
                    └─────────┬───────┘
                              │
                              v
                    ┌─────────────────┐
                    │  Combined Report │
                    └─────────────────┘
```

### Sequential Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Code    │───►│ Security │───►│  Test    │───►│  Report  │
│ Analysis │    │  Check   │    │   Gen    │    │ Generate │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

---

## Subagent Configuration

### Configuration File Format

```yaml
# subagent-config.yaml
subagents:
  design-review:
    enabled: true
    system_prompt: |
      [System prompt here]
    tools:
      - playwright
      - lighthouse
    options:
      severity_threshold: minor
      include_screenshots: true

  code-review:
    enabled: true
    system_prompt: |
      [System prompt here]
    tools:
      - eslint
      - typescript
    options:
      include_suggestions: true
      max_findings: 50

  security-review:
    enabled: true
    system_prompt: |
      [System prompt here]
    tools:
      - semgrep
      - gitleaks
    options:
      fail_on_critical: true
```

### Per-Project Overrides

```yaml
# .claude/subagents.yaml (in project)
overrides:
  design-review:
    options:
      design_system: "./design-tokens.json"
      brand_colors: ["#1a1a1a", "#ffffff", "#0066cc"]

  code-review:
    options:
      language_rules: "strict"
      custom_patterns:
        - pattern: "console.log"
          message: "Remove debug logs"
          severity: "minor"
```

---

## Creating Custom Subagents

### Step-by-Step Guide

1. **Define Purpose**
   - What specific task does this subagent handle?
   - What expertise does it require?

2. **Write System Prompt**
   - Clear role definition
   - Specific expertise areas
   - Evaluation criteria
   - Output format specification

3. **Configure Tools**
   - What tools does it need access to?
   - How should tools be used?

4. **Define Handoff Protocol**
   - What context does it receive?
   - What does it return?

5. **Create Examples**
   - Sample inputs
   - Expected outputs
   - Edge cases

### Template

```yaml
# custom-subagent.yaml
name: custom-review
version: "1.0"

purpose: |
  Brief description of what this subagent does.

system_prompt: |
  You are an expert in [domain].

  Your expertise includes:
  - [Skill 1]
  - [Skill 2]

  When [task]:
  1. [Step 1]
  2. [Step 2]

  Provide findings with:
  - [Format item 1]
  - [Format item 2]

tools:
  - tool-name-1
  - tool-name-2

handoff:
  receives:
    - changed_files: "List of modified files"
    - context: "Additional context"
  returns:
    - findings: "Structured findings array"
    - summary: "Summary statistics"

options:
  severity_threshold:
    type: string
    default: minor
    options: [critical, major, minor, suggestion]

examples:
  - name: "Basic usage"
    input: {...}
    output: {...}
```

---

*Last Updated: December 2024*
