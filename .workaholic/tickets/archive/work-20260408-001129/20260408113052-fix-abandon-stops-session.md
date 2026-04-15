---
created_at: 2026-04-08T11:30:52+09:00
author: a@qmu.jp
type: bugfix
layer: [UX]
effort: 0.1h
commit_hash: eb2f7a4
category: Changed
---

# Fix drive "Abandon" behavior to stop session instead of silently continuing

## Overview

When a user selects "Abandon" during drive approval, the drive command silently proceeds to the next ticket without asking the user. The user expects the session to pause after abandonment so they can decide what to do next. This is a UX violation of the principle that the drive command should never autonomously continue without user consent after a disruptive action like abandonment. The fix changes "Abandon" to stop the drive session and ask the user what to do, mirroring the "Approve and stop" pattern rather than the "Approve" pattern.

## Key Files

- `plugins/work/commands/drive.md` - The drive command orchestrator; lines 101-103 instruct "Continue to next ticket" after abandonment, which is the root cause
- `plugins/work/skills/drive/SKILL.md` - The drive skill; line 132 describes Abandon as "continue to next" in the option description, and line 235 says "Continue to next ticket automatically" at the end of the Handle Abandonment section

## Related History

The drive command's approval flow has been through multiple iterations of refinement, with past tickets addressing autonomous ticket moves, destructive git operations, and approval prompt context. The pattern of preventing autonomous behavior without user consent is well established in this codebase.

Past tickets that touched similar areas:

- [20260201103205-stop-story-moving-tickets-to-icebox.md](.workaholic/tickets/archive/drive-20260131-223656/20260201103205-stop-story-moving-tickets-to-icebox.md) - Removed automatic ticket migration from /story; same principle of not acting autonomously on ticket lifecycle decisions
- [20260204173959-strengthen-git-safeguards-in-drive.md](.workaholic/tickets/archive/drive-20260204-160722/20260204173959-strengthen-git-safeguards-in-drive.md) - Strengthened safeguards in abandonment flow; touched the same Handle Abandonment section
- [20260306065407-enforce-ticket-context-in-drive-approval.md](.workaholic/tickets/archive/drive-20260302-213941/20260306065407-enforce-ticket-context-in-drive-approval.md) - Enforced ticket title/summary in approval prompt; same approval flow section
- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Merged approval skills into unified drive skill; created the current Handle Abandonment section structure
- [20260207003033-refactor-drive-command-reduce-redundancy.md](.workaholic/tickets/archive/drive-20260205-195920/20260207003033-refactor-drive-command-reduce-redundancy.md) - Refactored drive.md to thin orchestration; established the current concise "Abandon" handling in drive.md

## Implementation Steps

1. **Update the Abandon option description in the drive skill** (`plugins/work/skills/drive/SKILL.md` line 132): Change the description from "Write failure analysis, discard changes, continue to next" to "Write failure analysis, discard changes, stop session". This sets the user's expectation at the point of selection.

2. **Update the Handle Abandonment section ending in the drive skill** (`plugins/work/skills/drive/SKILL.md` line 235): Replace "Continue to next ticket automatically." with instructions to stop the session. After the commit of the abandoned ticket, the skill should indicate that the session stops and the user is asked what to do next.

3. **Update the Abandon handler in the drive command** (`plugins/work/commands/drive.md` lines 101-103): Replace "Continue to next ticket" with "Stop the drive session" behavior. After following the drive skill's Handle Abandonment, break out of the ticket loop and go to Phase 4 (Completion), similar to how "Approve and stop" works.

4. **Verify the Phase 4 summary still works correctly**: Phase 4 summarizes what was done. After an abandonment that stops the session, the summary should reflect that a ticket was abandoned and the session was stopped at user's request.

## Patches

### `plugins/work/skills/drive/SKILL.md`

```diff
--- a/plugins/work/skills/drive/SKILL.md
+++ b/plugins/work/skills/drive/SKILL.md
@@ -129,7 +129,7 @@
     "options": [
       {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
       {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
-      {"label": "Abandon", "description": "Write failure analysis, discard changes, continue to next"}
+      {"label": "Abandon", "description": "Write failure analysis, discard changes, stop session"}
     ],
     "multiSelect": false
   }]
```

```diff
--- a/plugins/work/skills/drive/SKILL.md
+++ b/plugins/work/skills/drive/SKILL.md
@@ -232,1 +232,1 @@
-Continue to next ticket automatically.
+Stop the drive session. Return control to the drive command to present the completion summary.
```

### `plugins/work/commands/drive.md`

```diff
--- a/plugins/work/commands/drive.md
+++ b/plugins/work/commands/drive.md
@@ -101,2 +101,2 @@
 **"Abandon"**:
 1. Follow **drive** skill (Approval section, Handle Abandonment)
-2. Continue to next ticket
+2. Break loop, skip Phase 3, go directly to Phase 4 (same as "Approve and stop")
```

> **Note**: Line offsets in these patches are approximate -- verify against actual file content before applying.

## Considerations

- The change makes "Abandon" behave like "Approve and stop" in terms of session flow, but the ticket handling is different: abandoned tickets go to `.workaholic/tickets/abandoned/` with a Failure Analysis section, while approved tickets go to archive. The session-stopping behavior is the only thing being aligned. (`plugins/work/commands/drive.md` lines 77-103)
- The Critical Rules section at the bottom of drive.md already establishes the principle that ticket lifecycle decisions require developer approval. This fix extends that principle to post-abandonment session continuation. (`plugins/work/commands/drive.md` lines 136-148)
- If a user abandons the first ticket and wants to continue driving the remaining tickets, they can simply run `/drive` again. The abandoned ticket will no longer be in todo, so the remaining tickets will be presented. This is a minor friction trade-off in exchange for never surprising the user with autonomous continuation. (`plugins/work/commands/drive.md`)
- The Phase 4 completion summary should naturally handle the abandonment case since it already tracks "Total tickets implemented" and "List of all commit hashes" -- the abandonment commit will appear in that list. (`plugins/work/commands/drive.md` lines 125-133)

## Final Report

### Changes Made

1. **`plugins/work/skills/drive/SKILL.md`** — Changed Abandon option description from "continue to next" to "stop session"; changed Handle Abandonment ending from "Continue to next ticket automatically" to "Stop the drive session"
2. **`plugins/work/commands/drive.md`** — Changed Abandon handler from "Continue to next ticket" to "Break loop, skip Phase 3, go directly to Phase 4"

### Test Plan

- [ ] Select "Abandon" during drive approval and verify session stops
- [ ] Run `/drive` again after abandonment and verify remaining tickets are presented

### Release Prep

- No version bump needed (behavior fix in plugin instructions)
