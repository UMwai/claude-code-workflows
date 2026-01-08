# Manus Workflow Examples

## Example 1: API Research Task

### User Request
```
/manus start Research authentication best practices for REST APIs
```

### task_plan.md (Initial)
```markdown
# Task Plan

## Goal
Research and document authentication best practices for REST APIs

## Phases
- [ ] Phase 1: Research authentication methods
- [ ] Phase 2: Compare approaches
- [ ] Phase 3: Document recommendations

## Current Status
Phase: 1
Last Action: Initialized
Next Action: Search for API auth methods
```

### After Research (notes.md)
```markdown
# Research Notes

## Findings

### Authentication Methods
1. **API Keys** - Simple, good for server-to-server
2. **OAuth 2.0** - Industry standard, complex but secure
3. **JWT** - Stateless, good for microservices
4. **Basic Auth** - Simple but less secure

### Security Considerations
- Always use HTTPS
- Rotate credentials regularly
- Implement rate limiting
- Use short-lived tokens

## Key Insights
- OAuth 2.0 is preferred for user-facing APIs
- API keys work well for internal/partner APIs
- JWT enables stateless auth but needs careful handling
```

### task_plan.md (Updated)
```markdown
## Phases
- [x] Phase 1: Research authentication methods
- [ ] Phase 2: Compare approaches
- [ ] Phase 3: Document recommendations

## Current Status
Phase: 2
Last Action: Documented auth methods and security considerations
Next Action: Create comparison matrix
```

---

## Example 2: Bug Investigation

### User Request
```
/manus start Investigate why user sessions expire randomly
```

### Workflow Progression

**tool call 1:** Search codebase for session handling
**tool call 2:** Read session configuration
→ Update notes.md with findings

**tool call 3:** Read task_plan.md (refresh goal)
**tool call 4:** Search for timeout settings
**tool call 5:** Read related middleware
→ Update notes.md with findings

**Error encountered:** Permission denied reading config
→ Log error in notes.md

**tool call 6:** Read task_plan.md (refresh goal)
**tool call 7:** Alternative approach - check environment vars
→ Found the issue! Document in notes.md

### Final deliverable.md
```markdown
# Bug Investigation: Random Session Expiry

## Root Cause
Session timeout configured via `SESSION_TIMEOUT` env var
was being overridden by load balancer health checks
resetting the session store.

## Solution
1. Exclude health check endpoints from session middleware
2. Add session affinity to load balancer config

## Files to Modify
- `middleware/session.js` - Add endpoint exclusion
- `nginx.conf` - Add ip_hash directive
```

---

## Example 3: Feature Implementation

### User Request
```
/manus start Add dark mode toggle to settings page
```

### task_plan.md
```markdown
# Task Plan

## Goal
Implement dark mode toggle in user settings

## Phases
- [ ] Phase 1: Research existing theme system
- [ ] Phase 2: Design state management
- [ ] Phase 3: Implement toggle component
- [ ] Phase 4: Add CSS variables
- [ ] Phase 5: Test and refine

## Detailed Steps

### Phase 1
- [ ] Find existing CSS/theme files
- [ ] Check for CSS variable usage
- [ ] Identify settings page location

### Phase 2
- [ ] Decide: localStorage vs user preference API
- [ ] Design theme context/store

### Phase 3
- [ ] Create Toggle component
- [ ] Wire up to theme state
- [ ] Add to settings page

### Phase 4
- [ ] Define CSS variables for both themes
- [ ] Update components to use variables

### Phase 5
- [ ] Test theme persistence
- [ ] Test system preference detection
```

### notes.md (During Implementation)
```markdown
# Research Notes

## Findings

### Existing Structure
- CSS in `src/styles/`
- No existing CSS variables
- Settings at `src/pages/Settings.jsx`
- Using React Context for state

### Decisions
- Use localStorage for persistence
- Create ThemeContext provider
- CSS variables for colors

## Code Snippets

ThemeContext pattern:
\`\`\`jsx
const ThemeContext = createContext();
export const useTheme = () => useContext(ThemeContext);
\`\`\`

## Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| Flash on load | Theme loads after render | Move script to head |
```

---

## Anti-Pattern Examples

### Bad: Skipping the Workflow
```
User: Research microservices patterns
Claude: *immediately starts searching without task_plan.md*
        *makes 10 tool calls*
        *forgets original goal*
        *provides scattered, incomplete answer*
```

### Bad: Not Updating Notes
```
User: /manus start Complex refactoring task
Claude: *creates task_plan.md*
        *makes 8 tool calls without updating notes*
        *loses track of what was found*
        *has to re-research the same things*
```

### Bad: Not Reading Plan Before Decisions
```
Claude: *reads some code*
        *starts implementing without checking task_plan*
        *implements wrong feature*
        *has to redo work*
```

---

## Quick Reference

| Trigger | Action |
|---------|--------|
| Starting complex task | Create task_plan.md |
| Every 2-3 tool calls | Update notes.md |
| Before any decision | Read task_plan.md |
| On error | Log to notes.md |
| Task complete | Create deliverable.md |
