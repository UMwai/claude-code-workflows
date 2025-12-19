# Claude Code Workflows

Battle-tested workflows and configurations for [Claude Code](https://claude.ai/code), Anthropic's official CLI.

Built from real-world experience at an AI-native startup, using Claude Code daily since launch.

---

## Workflows

### [Design Review](./design-review/)

Automated design review system for frontend code changes.

**What it does:**
- Provides comprehensive UI/UX feedback on PRs and working changes
- Uses Playwright to test actual UI components (not just static code analysis)
- Evaluates against design standards from Stripe, Airbnb, Linear
- Checks accessibility (WCAG AA+), responsiveness, visual hierarchy

**Features:**
- `/design-review` slash command for on-demand reviews
- Specialized subagent configuration
- CLAUDE.md snippets for design principles
- Multi-phase review process

---

## Setup

1. Clone this repo
2. Copy the relevant workflow files to your project's `.claude/` directory
3. Customize the configurations for your design system
4. Run the slash commands or trigger via PR hooks

---

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Video Tutorial](https://www.youtube.com/watch?v=xOO8Wt_i72s) - Walkthrough of the design review workflow

---

## License

MIT
