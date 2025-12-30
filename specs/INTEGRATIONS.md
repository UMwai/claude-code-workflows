# claude-code-workflows Integrations

## Overview

claude-code-workflows integrates with various development tools to provide comprehensive workflow automation.

---

## Claude Code Integration

### Slash Commands

The primary integration method is through slash commands in Claude Code.

**Installation**:
```bash
# Copy slash command to your project
cp workflows/design-review/slash-command.md .claude/commands/design-review.md
```

**Usage**:
```
/design-review
/code-review --strict
/security-review
```

### CLAUDE.md Integration

Add workflow snippets to your project's CLAUDE.md:

```markdown
# CLAUDE.md

## Project Commands

### /design-review
Runs comprehensive design review on frontend changes.
See: .claude/commands/design-review.md

### /code-review
Runs code quality review on all changes.
See: .claude/commands/code-review.md
```

### Settings Configuration

```json
// .claude/settings.local.json
{
  "permissions": {
    "allow": [
      "Bash(npx playwright*)",
      "Bash(npx lighthouse*)",
      "Read(*)",
      "Write(*)"
    ]
  },
  "workflows": {
    "design-review": {
      "enabled": true,
      "autorun_on_pr": true
    }
  }
}
```

---

## Playwright Integration

### Purpose
Visual testing, screenshot capture, and responsive testing.

### Setup

```bash
# Install Playwright
npm install -D @playwright/test

# Install browsers
npx playwright install
```

### Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'on',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'Desktop Chrome',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
    {
      name: 'Tablet',
      use: {
        viewport: { width: 768, height: 1024 },
      },
    },
  ],
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: true,
  },
});
```

### Usage in Workflows

```markdown
## Design Review Step 2: Visual Testing

1. Start the dev server: `npm run dev`
2. Run Playwright tests: `npx playwright test --ui`
3. Capture screenshots at each breakpoint
4. Compare with baseline images
```

---

## Lighthouse Integration

### Purpose
Performance, accessibility, and best practices auditing.

### Setup

```bash
# Install Lighthouse
npm install -D lighthouse
```

### Configuration

```javascript
// lighthouse.config.js
module.exports = {
  extends: 'lighthouse:default',
  settings: {
    onlyCategories: ['accessibility', 'best-practices', 'performance'],
    emulatedFormFactor: 'desktop',
    throttling: {
      cpuSlowdownMultiplier: 1,
    },
  },
};
```

### Usage in Workflows

```bash
# Run Lighthouse audit
npx lighthouse http://localhost:3000 \
  --config-path=lighthouse.config.js \
  --output=json \
  --output-path=./lighthouse-report.json
```

---

## GitHub Actions Integration

### PR Automation

```yaml
# .github/workflows/design-review.yml
name: Design Review
on:
  pull_request:
    paths:
      - 'src/components/**'
      - 'src/pages/**'
      - '**/*.css'
      - '**/*.scss'

jobs:
  design-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Start dev server
        run: npm run dev &
        env:
          PORT: 3000

      - name: Wait for server
        run: npx wait-on http://localhost:3000

      - name: Run design review
        run: |
          # Run Playwright visual tests
          npx playwright test

          # Run Lighthouse
          npx lighthouse http://localhost:3000 --output=json

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: design-review-results
          path: |
            test-results/
            lighthouse-report.json
```

### Code Review Automation

```yaml
# .github/workflows/code-review.yml
name: Code Review
on:
  pull_request:
    branches: [main]

jobs:
  code-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get changed files
        id: changed
        run: |
          echo "files=$(git diff --name-only origin/main...HEAD | tr '\n' ' ')" >> $GITHUB_OUTPUT

      - name: Run linting
        run: npm run lint

      - name: Run type check
        run: npm run typecheck

      - name: Run tests
        run: npm test -- --coverage
```

### Security Review Automation

```yaml
# .github/workflows/security-review.yml
name: Security Review
on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  security-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/security-audit

      - name: Check for secrets
        uses: gitleaks/gitleaks-action@v2

      - name: Dependency audit
        run: npm audit
```

---

## ESLint Integration

### Purpose
Code quality and consistency checking.

### Configuration

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
  ],
  plugins: ['@typescript-eslint', 'react', 'react-hooks'],
  rules: {
    // Custom rules for code review
    'no-console': 'warn',
    'react/prop-types': 'off',
    '@typescript-eslint/explicit-function-return-type': 'warn',
  },
};
```

### Usage in Workflows

```bash
# Run ESLint on changed files
npx eslint --ext .ts,.tsx src/
```

---

## TypeScript Integration

### Purpose
Type checking and type-related code review.

### Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### Usage in Workflows

```bash
# Type check
npx tsc --noEmit

# Type check with details
npx tsc --noEmit --pretty
```

---

## axe-core Integration

### Purpose
Automated accessibility testing.

### Setup

```bash
npm install -D @axe-core/playwright
```

### Usage

```typescript
// tests/accessibility.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('accessibility check', async ({ page }) => {
  await page.goto('/');

  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze();

  expect(results.violations).toEqual([]);
});
```

---

## Jest/Vitest Integration

### Purpose
Test generation and coverage tracking.

### Configuration

```javascript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      thresholds: {
        global: {
          branches: 80,
          functions: 80,
          lines: 80,
        },
      },
    },
  },
});
```

### Usage in Workflows

```bash
# Run tests with coverage
npm test -- --coverage
```

---

## Husky Pre-commit Integration

### Purpose
Run workflows before commits.

### Setup

```bash
npm install -D husky lint-staged
npx husky install
```

### Configuration

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{css,scss}": [
      "prettier --write"
    ]
  }
}
```

```bash
# .husky/pre-commit
npx lint-staged
```

---

## Environment Variables

```bash
# .env.local
# Workflow configuration
WORKFLOW_SEVERITY_THRESHOLD=minor
WORKFLOW_AUTO_FIX=true

# Tool configuration
LIGHTHOUSE_CHROME_FLAGS="--headless"
PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# CI configuration
CI=true
```

---

## Integration Summary

| Tool | Purpose | Integration Type |
|------|---------|------------------|
| Playwright | Visual testing | npm package |
| Lighthouse | Performance/a11y audit | npm package |
| ESLint | Code linting | npm package |
| TypeScript | Type checking | npm package |
| axe-core | Accessibility testing | Playwright plugin |
| Jest/Vitest | Unit testing | npm package |
| GitHub Actions | CI/CD automation | Workflow files |
| Husky | Git hooks | npm package |

---

*Last Updated: December 2024*
