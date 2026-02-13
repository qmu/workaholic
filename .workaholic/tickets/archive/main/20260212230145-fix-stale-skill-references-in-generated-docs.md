---
created_at: 2026-02-12T23:01:45+08:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.5h
commit_hash: 2f9f7cb
category: Changed
---

# Fix Stale References to Renamed Skills in Generated Documentation

## Overview

Spec documents, policy documents, and term documents under `.workaholic/` contain stale references to three renamed skills: `manage-branch` (now `branching`), `managers-policy` (now `managers-principle`), and `leaders-policy` (now `leaders-principle`). These are generated documentation produced by `/scan` and will be corrected on the next `/scan` run. This ticket tracks running `/scan` to regenerate the affected documents.

## Key Files

- `.workaholic/specs/infrastructure.md` - References `leaders-policy`, `managers-policy`, `manage-branch` in skill descriptions and explicit annotations
- `.workaholic/specs/infrastructure_ja.md` - Japanese translation with same stale references
- `.workaholic/specs/feature.md` - References `managers-policy` and `leaders-policy` in constraint setting and policy tables
- `.workaholic/specs/feature_ja.md` - References `manage-branch` in auto-branch creation table
- `.workaholic/specs/data.md` - References `managers-policy` and `leaders-policy` in skill invocability and agent tier tables
- `.workaholic/specs/data_ja.md` - Japanese translation with same stale references
- `.workaholic/specs/usecase.md` - References `manage-branch` in sequence diagram and `managers-policy` in explicit annotation
- `.workaholic/specs/usecase_ja.md` - Japanese translation with same stale references
- `.workaholic/specs/component.md` - References `managers-policy` in skill listing
- `.workaholic/specs/component_ja.md` - References `manage-branch` in skill descriptions and ticket-organizer flow
- `.workaholic/policies/recovery.md` - References `manage-branch` skill and path `plugins/core/skills/manage-branch/sh/create.sh`
- `.workaholic/policies/recovery_ja.md` - Japanese translation with same stale reference
- `.workaholic/terms/core-concepts.md` - Contains stale skill name entries for `managers-policy` and `leaders-policy`
- `.workaholic/terms/core-concepts_ja.md` - Japanese translation with same stale entries

## Related History

The skill renames were completed in the current branch (`drive-20260212-122906`), but the generated documentation was intentionally left for the next `/scan` run rather than being manually updated. The current branch story explicitly notes this as a known gap.

Past tickets that touched similar areas:

- [20260212164717-rename-manage-branch-skill.md](.workaholic/tickets/archive/drive-20260212-122906/20260212164717-rename-manage-branch-skill.md) - Renamed manage-branch to branching; noted spec documents would be corrected on next /scan (same skill rename)
- [20260212173856-rename-policy-skills-to-principle.md](.workaholic/tickets/archive/drive-20260212-122906/20260212173856-rename-policy-skills-to-principle.md) - Renamed managers-policy and leaders-policy to managers-principle and leaders-principle; explicitly noted spec documents contain stale references (direct cause of this ticket)

## Implementation Steps

1. Run `/scan` to regenerate all spec, policy, and term documents under `.workaholic/`
2. Verify that stale references to `manage-branch`, `managers-policy`, and `leaders-policy` have been replaced with `branching`, `managers-principle`, and `leaders-principle` in the regenerated documents
3. Confirm no regressions in other document content

## Considerations

- Story files (`.workaholic/stories/`) and archived tickets (`.workaholic/tickets/archive/`) also contain these old skill names but they are historical records and must NOT be updated (`.workaholic/stories/`, `.workaholic/tickets/archive/`)
- The CHANGELOG.md references to old skill names are also historical and should not be changed (`CHANGELOG.md`)
- Some spec files (e.g., `ux.md`, `application.md`, `model.md`) already contain contextual "formerly known as" references that document the rename itself -- these are correct and should be preserved by the scan agents (`.workaholic/specs/ux.md`, `.workaholic/specs/application.md`, `.workaholic/specs/model.md`)
- The `/scan` run may take significant time as it invokes all 14 documentation agents; this is expected and does not block other work
- This ticket does not block release, as noted in the branch story (`drive-20260212-122906`)

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: Targeted find-and-replace is more efficient than running /scan for simple rename propagation
  **Context**: The ticket suggested running /scan (14 agents, significant time), but since the change was purely mechanical string replacement across known files, direct replace_all on the 14 affected files was faster and equally correct. Historical/contextual references in ux.md, application.md, model.md, and accessibility.md were correctly preserved.
