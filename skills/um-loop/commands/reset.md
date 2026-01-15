---
description: "Reset UM Loop progress"
---

# UM Loop Reset

Reset the current UM Loop:

1. **Check if PRD.md exists** - If not, report "No active UM Loop to reset"

2. **If exists**:
   - Read PRD.md
   - Change all `- [x]` back to `- [ ]`
   - Clear progress.md (keep header, remove entries)
   - Report: "UM Loop reset. All tasks unchecked, progress cleared."

3. **Confirm** before resetting - Ask user "Reset UM Loop? This will uncheck all PRD items and clear progress.md"
