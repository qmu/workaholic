---
created_at: 2026-02-02T14:06:45+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Discussion Section to Ticket When Drive Is Not Approved

## Overview

When a user does not approve a `/drive` implementation and provides feedback comments, Claude Code should first update the ticket by adding a "Discussion" section before making any code changes. This section records the user's viewpoint and documents the direction change, creating a traceable history of feedback and pivots.

## Key Files

- `plugins/core/commands/drive.md` - Main drive command that handles approval flow (lines 58-100)
- `plugins/core/skills/request-approval/SKILL.md` - Current approval options (Approve, Approve and stop, Abandon)
- `plugins/core/skills/handle-abandon/SKILL.md` - Pattern for appending sections to tickets

## Related History

Historical tickets show the approval flow has been refined over time with additional options added. The "Abandon" flow already has a pattern for appending analysis sections to tickets, which can be reused.

Past tickets that touched similar areas:

- [20260128211728-add-fail-option-to-drive-approval.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211728-add-fail-option-to-drive-approval.md) - Added approval option with ticket modification pattern
- [20260125113309-drive-approve-and-stop-option.md](.workaholic/tickets/archive/feat-20260124-200439/20260125113309-drive-approve-and-stop-option.md) - Previous extension of approval options

## Implementation Steps

### 1. Add "Needs revision" Option to request-approval Skill

Update `plugins/core/skills/request-approval/SKILL.md` to add a fourth approval option:

```json
{
  "options": [
    {"label": "Approve", "description": "Proceed to commit and continue to next ticket"},
    {"label": "Approve and stop", "description": "Commit this ticket but stop driving"},
    {"label": "Needs revision", "description": "Provide feedback, update ticket, revise implementation"},
    {"label": "Abandon", "description": "Write failure analysis, discard changes, continue to next"}
  ]
}
```

### 2. Add Post-Selection Handling for "Needs revision"

In `request-approval/SKILL.md`, add:

```markdown
- **Needs revision**: Follow handle-revision skill, then re-implement
```

### 3. Create handle-revision Skill

Create `plugins/core/skills/handle-revision/SKILL.md`:

```markdown
---
name: handle-revision
description: Handle revision request by recording discussion and re-implementing.
user-invocable: false
---

# Handle Revision

When user selects "Needs revision", record their feedback before revising.

## 1. Prompt for Feedback

Ask user: "What changes would you like?" (open-ended text input)

## 2. Append Discussion Section

Add to the ticket file (before ## Final Report if exists, otherwise at end):

```markdown
## Discussion

### Revision 1 - <timestamp>

**User feedback**: <verbatim user feedback>

**Direction change**: <Claude's interpretation of how to change approach>

**Action taken**: <brief description of revision made>
```

For subsequent revisions, append as "### Revision 2", etc.

## 3. Re-implement

Apply the revised approach following the user's feedback, then return to approval flow.
```

### 4. Update drive.md to Handle "Needs revision"

In `plugins/core/commands/drive.md`, add handling after line 100:

```markdown
**"Needs revision"**:
1. Follow **handle-revision** skill (prompt for feedback, append Discussion section)
2. Re-implement changes based on feedback
3. Return to Step 2.2 (request approval again)
```

### 5. Register Skill in drive.md Frontmatter

Add `handle-revision` to the skills list in `drive.md` frontmatter.

## Considerations

- **Multiple revisions**: The Discussion section supports multiple revision entries, creating a clear history of the conversation
- **Timestamp format**: Use ISO 8601 format for consistency with ticket frontmatter
- **Open-ended input**: Unlike other approval options that use selectable choices, revision feedback requires free-form text input
- **Loop protection**: Consider adding a maximum revision count to prevent infinite revision loops (optional, could be future enhancement)
- **Preserving context**: By recording the discussion in the ticket, future readers understand why implementation differs from original spec
