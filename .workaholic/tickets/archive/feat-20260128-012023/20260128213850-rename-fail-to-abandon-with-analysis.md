---
title: Rename "Fail" to "Abandon" with failure analysis report
created_at: 2026-01-28T21:38:50+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: ca85887
---
category: Changed
# Rename "Fail" to "Abandon" with failure analysis report

## Overview

Rename the "Fail" option in `/drive` approval prompt to "Abandon" for more natural English, and require a failure analysis report before moving the ticket to capture insights from the failed attempt.

## Key Files

- `plugins/core/skills/drive-workflow/SKILL.md` - Contains approval options and fail handling logic
- `plugins/core/commands/drive.md` - Example workflow shows approval options

## Related History

- [20260128211728-add-fail-option-to-drive-approval.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211728-add-fail-option-to-drive-approval.md) - Added original "Fail" option

## Implementation Steps

1. **Rename "Fail" to "Abandon" in drive-workflow skill**
   - Update step 3 AskUserQuestion options
   - Update approval prompt format example
   - Rename section "If User Selects 'Fail'" to "If User Selects 'Abandon'"

2. **Add failure analysis report requirement**
   - Before moving ticket to `fail/`, append a `## Failure Analysis` section
   - Include: what was attempted, why it failed, insights for future attempts
   - Format similar to Final Report but focused on learning from failure

3. **Update the abandon workflow**
   - Run `git restore .` to discard implementation changes (modern git syntax)
   - Append Failure Analysis section to ticket
   - Move ticket to `fail/`
   - Commit the ticket move (preserves the analysis)
   - Continue to next ticket

4. **Update drive.md example**
   - Change `[Approve / Approve and stop / Needs changes / Fail]` to `[Approve / Approve and stop / Needs changes / Abandon]`

## Considerations

- Using `git restore .` instead of `git checkout -- .` for modern git consistency
- The Failure Analysis should be committed with the ticket move so insights are preserved in git history
- Keep the analysis lightweight but useful for future reference

## Final Report

Development completed as planned.
