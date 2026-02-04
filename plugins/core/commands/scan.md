---
name: scan
description: Update .workaholic/ documentation (changelog, specs, terms).
---

# Scan

**Notice:** When user input contains `/scan` - whether "run /scan", "do /scan", "update /scan", or similar - they likely want this command.

Update `.workaholic/` documentation by invoking the scanner subagent.

## Instructions

1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`)
2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ && git commit -m "Update documentation"`
3. **Report results** from scanner output
