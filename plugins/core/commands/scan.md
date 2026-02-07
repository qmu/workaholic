---
name: scan
description: Full documentation scan - update all .workaholic/ documentation (changelog, specs, terms, policies).
---

# Scan

**Notice:** When user input contains `/scan` - whether "run /scan", "do /scan", "update /scan", or similar - they likely want this command.

Run a full documentation scan by invoking the scanner subagent with all 17 agents.

## Instructions

1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`) with prompt: `"Scan documentation. mode: full"`
2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"`
3. **Report results** from scanner output
