---
created_at: 2026-02-02T18:46:01+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Merge Approval Flow Skills into Unified drive-approval Skill

## Overview

Consolidate three related skills (`request-approval`, `handle-revision`, `handle-abandon`) into a single unified `drive-approval` skill. These skills are all part of the `/drive` command's approval flow and are tightly coupled - they are always preloaded together by the drive command, share the same context (user approval decisions), and form a cohesive workflow. Merging them reduces cognitive overhead and makes the approval flow easier to understand and maintain as a single unit.

## Key Files

- `plugins/core/skills/request-approval/SKILL.md` - Approval prompt format and options (to be merged and removed)
- `plugins/core/skills/handle-revision/SKILL.md` - Revision request handling (to be merged and removed)
- `plugins/core/skills/handle-abandon/SKILL.md` - Abandonment handling (to be merged and removed)
- `plugins/core/skills/drive-approval/SKILL.md` - New unified skill (to be created)
- `plugins/core/commands/drive.md` - Update skills list to reference drive-approval
- `.workaholic/specs/architecture.md` - Update skills listing
- `.workaholic/specs/architecture_ja.md` - Update skills listing (Japanese)

## Related History

Historical tickets show the pattern of first splitting skills for modularity, then re-merging when the split proves too granular. The approval flow skills were extracted from drive-workflow, but their tight coupling suggests they should be reunified under a single skill.

Past tickets that touched similar areas:

- [20260131153736-split-drive-workflow-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131153736-split-drive-workflow-skill.md) - Original split that created request-approval, handle-abandon (same skills being merged)
- [20260131194500-per-ticket-approval-in-drive-loop.md](.workaholic/tickets/archive/feat-20260131-125844/20260131194500-per-ticket-approval-in-drive-loop.md) - Moved approval to command level, established current approval architecture
- [20260128002032-merge-create-pr-and-manage-pr.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002032-merge-create-pr-and-manage-pr.md) - Same pattern: merged related skills when separation was too granular

## Implementation Steps

### 1. Create drive-approval skill

Create `plugins/core/skills/drive-approval/SKILL.md` with frontmatter:

```yaml
---
name: drive-approval
description: User approval flow for drive implementations including approval, revision, and abandonment.
user-invocable: false
---
```

### 2. Structure the unified skill content

Organize the merged content into clear sections:

```markdown
# Drive Approval

User approval flow for implementation review during `/drive`. This skill covers the complete approval cycle: requesting approval, handling revision feedback, and handling abandonment.

## 1. Request Approval

[Content from request-approval/SKILL.md]
- When to use
- Approval prompt format
- AskUserQuestion format with 4 options
- Post-approval behavior summary (detailed handling in sections 2-4)

## 2. Handle Approval and Commit

- Follow write-final-report skill
- Run archive-ticket script
- Continue or stop based on option selected

## 3. Handle Revision

[Content from handle-revision/SKILL.md]
- Prompt for feedback
- Append Discussion section
- Re-implement and return to approval

## 4. Handle Abandonment

[Content from handle-abandon/SKILL.md]
- Discard changes
- Append Failure Analysis section
- Move to abandoned directory
- Commit abandonment
- Continue to next ticket
```

### 3. Migrate request-approval content

Copy the following from `request-approval/SKILL.md`:
- "When to Use" section
- "Approval Prompt Format" section
- "AskUserQuestion Format" section with the 4 options
- Update "Post-Approval Behavior" to reference sections 2-4 within the same skill

### 4. Migrate handle-revision content

Copy the following from `handle-revision/SKILL.md`:
- "Prompt for Feedback" section
- "Append Discussion Section" section with template
- "Re-implement" section with approval loop reference

### 5. Migrate handle-abandon content

Copy the following from `handle-abandon/SKILL.md`:
- "Discard Implementation Changes" section
- "Append Failure Analysis Section" section with template
- "Move Ticket to Abandoned Directory" section
- "Commit the Abandonment" section
- "Continue to Next Ticket" section

### 6. Update drive.md command

Update the skills frontmatter in `plugins/core/commands/drive.md`:

Before:
```yaml
skills:
  - drive-workflow
  - request-approval
  - write-final-report
  - handle-abandon
  - handle-revision
  - archive-ticket
```

After:
```yaml
skills:
  - drive-workflow
  - drive-approval
  - write-final-report
  - archive-ticket
```

### 7. Update drive.md references

Update any inline references in drive.md:
- Change "Follow **request-approval** skill" to "Follow **drive-approval** skill (Section 1)"
- Change "Follow **handle-revision** skill" to "Follow **drive-approval** skill (Section 3)"
- Change "Follow **handle-abandon** skill" to "Follow **drive-approval** skill (Section 4)"

### 8. Remove old skill directories

Delete the following directories:
- `plugins/core/skills/request-approval/`
- `plugins/core/skills/handle-revision/`
- `plugins/core/skills/handle-abandon/`

### 9. Update architecture specs

Update `plugins/core/skills/` listing in `.workaholic/specs/architecture.md`:

Remove:
```
handle-abandon/
  SKILL.md           # Handles abandoned implementations
handle-revision/
  SKILL.md           # Handles revision requests with discussion tracking
request-approval/
  SKILL.md           # User approval flow for implementations
```

Add:
```
drive-approval/
  SKILL.md           # Complete approval flow: request, revision, abandonment
```

Apply the same changes to `.workaholic/specs/architecture_ja.md`.

## Considerations

- **Cohesion over modularity**: These three skills always appear together and handle related concerns. A single skill is easier to reason about than three interdependent skills.
- **Section references**: Use numbered sections (Section 1, 2, 3, 4) so drive.md can reference specific parts of the unified skill.
- **No shell scripts**: Unlike archive-ticket, these skills are pure documentation with no bundled scripts, so merging is straightforward.
- **Skill size**: The merged skill will be ~100-120 lines, within the recommended 50-150 line range for comprehensive skills.
- **drive-workflow unchanged**: The drive-workflow skill remains separate as it covers implementation steps, not approval flow.
