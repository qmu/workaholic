---
created_at: 2026-01-28T01:28:37+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 330c4e4
category: Changed
---
---

# Enforce Ticket Frontmatter Rules

## Overview

The create-ticket skill defines required frontmatter fields but they're frequently skipped or filled incorrectly. The effort field is especially broken - some tickets use hours (0.1h), others use t-shirt sizes (XS). Effort MUST be numeric hours so it can be calculated/summed.

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Frontmatter rules buried in prose
- `plugins/core/skills/drive-workflow/SKILL.md` - Instructs to fill effort after implementation

## Implementation Steps

1. Move frontmatter template to the TOP of create-ticket skill, before any prose

2. Add explicit "REQUIRED - DO NOT SKIP" labels

3. Enforce effort as numeric hours (NOT t-shirt sizes):
   - Valid: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h
   - Invalid: XS, S, M, L, XL, 10m

4. Update drive-workflow skill to emphasize numeric hours for effort

5. Show the exact template:

```markdown
---
created_at: <run: date -Iseconds>
author: <run: git config user.email>
type: <enhancement | bugfix | refactoring | housekeeping>
layer: [<UX | Domain | Infrastructure | DB | Config>]
effort: <hours: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h>
commit_hash: e953636
category: Changed
---
```

## Final Report

Development completed as planned.
