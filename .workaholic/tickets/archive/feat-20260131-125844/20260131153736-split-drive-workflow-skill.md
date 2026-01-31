---
type: refactoring
layer: Config
effort: 0.5h
commit_hash: f1d1e8bcreated_at: 2026-01-31T15:37:40+09:00
category: Changedauthor: a@qmu.jp
---

# Split drive-workflow Skill into Composable Skills

## Overview

Refactor the monolithic `drive-workflow` skill (~200 lines) into smaller, focused skills that can be composed together. This follows the established pattern of extracting reusable knowledge into dedicated skills. The new skills will cover: approval flow, final report writing, discovered insights, and failure handling.

## Related History

| Ticket | Relevance |
|--------|-----------|
| [extract-drive-ticket-skills](../archive/feat-20260126-214833/20260127100902-extract-drive-ticket-skills.md) | Original extraction of drive-workflow from /drive command |
| [extract-agent-content-to-skills](../archive/feat-20260126-214833/20260127204529-extract-agent-content-to-skills.md) | Pattern: extract comprehensive skills from orchestrators |
| [add-discovered-insights-to-final-report](../archive/feat-20260128-012023/20260128210112-add-discovered-insights-to-final-report.md) | Added insights discovery to final report |
| [enforce-selectable-options-in-drive](../archive/feat-20260131-125844/20260131134135-enforce-selectable-options-in-drive.md) | Approval flow must use selectable options |

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/skills/drive-workflow/SKILL.md` | Current monolithic skill to split |
| `plugins/core/skills/archive-ticket/SKILL.md` | Already extracted commit skill |
| `plugins/core/commands/drive.md` | Command that preloads drive-workflow |

## Implementation

### 1. Create `request-approval` Skill

Extract Step 3 (approval flow) into `plugins/core/skills/request-approval/SKILL.md`:

```yaml
---
name: request-approval
description: User approval flow with selectable options for implementation review.
user-invocable: false
---
```

Contents:
- Approval prompt format (ticket title, summary, changes list)
- AskUserQuestion JSON with three options (Approve, Approve and stop, Abandon)
- Critical rule: ALWAYS use selectable options, NEVER open-ended questions
- Post-approval behavior for each option

### 2. Create `write-final-report` Skill

Extract Step 4 (final report and insights) into `plugins/core/skills/write-final-report/SKILL.md`:

```yaml
---
name: write-final-report
description: Write final report section with optional discovered insights.
user-invocable: false
---
```

Contents:
- Effort field update guidelines (0.1h to 4h, numeric hours only)
- Final Report section template
- Discovered Insights subsection structure
- What makes a good insight (architectural patterns, code relationships, historical context, edge cases)
- Insight guidelines (actionable, specific, future-benefiting)

### 3. Create `handle-abandon` Skill

Extract abandon flow into `plugins/core/skills/handle-abandon/SKILL.md`:

```yaml
---
name: handle-abandon
description: Handle abandoned implementation with failure analysis.
user-invocable: false
---
```

Contents:
- Discard changes procedure (`git restore .`)
- Failure Analysis section template (What Was Attempted, Why It Failed, Insights for Future Attempts)
- Move to fail directory procedure
- Commit the abandonment with proper message format

### 4. Create `format-commit-message` Skill

Extract commit message format into `plugins/core/skills/format-commit-message/SKILL.md`:

```yaml
---
name: format-commit-message
description: Structured commit message format with title, motivation, UX, and architecture sections.
user-invocable: false
---
```

Contents:
- Full commit message template (title, Motivation, UX Change, Arch Change, Co-Authored-By)
- Field guidelines (50 char title, present-tense verb, no prefixes)
- Examples of good UX Change and Arch Change descriptions
- "None" usage for internal-only or no-structural-change cases

### 5. Update drive-workflow to Preload New Skills

Refactor `drive-workflow/SKILL.md` to:

```yaml
---
name: drive-workflow
description: Implementation workflow for processing tickets.
skills:
  - request-approval
  - write-final-report
  - handle-abandon
  - format-commit-message
user-invocable: false
---
```

Reduce content to:
- High-level workflow overview (Steps 1-5)
- Step 1: Read and understand ticket (brief)
- Step 2: Implement ticket (brief)
- Step 3: Reference request-approval skill
- Step 4: Reference write-final-report skill
- Step 5: Reference archive-ticket skill (already external)
- After Committing: brief behavior summary
- If Abandon: Reference handle-abandon skill

Target: ~50-60 lines (down from ~200)

### 6. Update archive-ticket Skill

Update `archive-ticket/SKILL.md` to preload format-commit-message:

```yaml
---
name: archive-ticket
description: Complete commit workflow - format, archive, update changelog, and commit.
skills:
  - format-commit-message
allowed-tools: Bash
user-invocable: false
---
```

Remove duplicated commit message format section (now in format-commit-message skill).

## Verification

1. Verify each new skill file exists with proper frontmatter
2. Verify drive-workflow preloads all four new skills
3. Verify drive-workflow is reduced to ~50-60 lines
4. Verify archive-ticket preloads format-commit-message
5. Run `/drive` on a test ticket to verify workflow still functions

## Final Report

Development completed as planned.
