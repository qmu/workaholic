---
type: refactoring
effort: 0.2h
created_at: 2026-01-31T22:37:39+09:00
author: a@qmu.jp
---

# Rename fail/ Directory to abandoned/

## Overview

The `.workaholic/tickets/fail/` directory should be renamed to `.workaholic/tickets/abandoned/` to match the terminology used in the UI. When users select "Abandon" during `/drive` approval, it's confusing that tickets go to a directory named `fail/`. The directory name should match the action name.

## Key Files

- `plugins/core/skills/handle-abandon/SKILL.md` - Contains bash commands with `fail/` path (lines 39-40)
- `.workaholic/tickets/README.md` - Documents directory structure (lines 19, 34-36)
- `.workaholic/terms/file-conventions.md` - Defines `fail` directory term (lines 123-139)
- `.workaholic/terms/file-conventions_ja.md` - Japanese version
- `.workaholic/terms/workflow-terms.md` - Directory path reference (line 43)
- `.workaholic/terms/workflow-terms_ja.md` - Japanese version
- `.workaholic/terms/artifacts.md` - References `fail/` path (line 230)
- `.workaholic/terms/artifacts_ja.md` - Japanese version

## Related History

- `20260128213850-rename-fail-to-abandon-with-analysis.md` - Previous ticket renamed UI option from "Fail" to "Abandon" but didn't rename the directory
- `20260128211728-add-fail-option-to-drive-approval.md` - Original implementation that added the fail directory

## Implementation Steps

1. **Rename physical directory**
   ```bash
   mv .workaholic/tickets/fail .workaholic/tickets/abandoned
   ```

2. **Update handle-abandon skill**
   - Change path references from `fail/` to `abandoned/`

3. **Update tickets README**
   - Rename directory in structure diagram
   - Update "Failed Tickets" section heading and content

4. **Update terms documentation** (both English and Japanese)
   - file-conventions.md: Rename term from `fail` to `abandoned`
   - workflow-terms.md: Update directory path
   - artifacts.md: Update directory path reference

## Considerations

- The term "abandoned" is more accurate - tickets aren't "failed", they were intentionally set aside
- UI already uses "Abandon" as the action, so directory should match
- Keep the failure analysis feature intact, just rename the destination
