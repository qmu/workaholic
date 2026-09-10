---
type: Feedback
title: Ten of the operator's own FB issues can never be ingested because they carry no assignee
kind: insight
source: development
subject: observer_ai:moderate
created_at: 2026-09-09T22:23:16+09:00
author: a@qmu.jp
supersedes: 
---

# Ten of the operator's own FB issues can never be ingested because they carry no assignee

Source: the `/moderate` tick `20260909-130713` on this repository, from its own `issue-triage`
step and one REST read per candidate issue.

## What was measured

`issue-triage` reported *18 open issue(s): 0 landed but still open, 15 never ingested*. Reading
each open issue over `gather/scripts/gh-rest.sh`, **ten of the never-ingested issues were opened
by the operator's own account and carry no assignee at all**:

```
#1125 2026-09-08  tamurayoshiya  assignees: []   The loop has no hold state …
#1118 2026-09-08  tamurayoshiya  assignees: []   IMPLEMENT_FANOUT can never engage …
#1117 2026-09-08  tamurayoshiya  assignees: []   Questions answered outside their own thread …
#1116 2026-09-08  tamurayoshiya  assignees: []   The morning-digest gate never fires …
#1115 2026-09-08  tamurayoshiya  assignees: []   The strategy-digest dedup key can never be written …
#1110 2026-09-08  tamurayoshiya  assignees: []   Preserve a coherent feedback batch …
#1104 2026-09-08  tamurayoshiya  assignees: []   Verify each feedback item on its actual review surface …
#1044 2026-09-06  tamurayoshiya  assignees: []   A mission whose remaining tickets need a person …
#908  2026-09-02  tamurayoshiya  assignees: []   The sweep's receipt can be judged away …
#907  2026-09-02  tamurayoshiya  assignees: []   /propose converges on silence …
```

Three others (#1041, #989, #806) are assigned to `tamurayoshiya` and are a different case.

## Why they will never be ingested

`.workaholic/feedbacks/20260805130926-scope-each-user-s-routine-to-the-fb-issues-assigned-to-that-user.md`
is the operator's own instruction: a routine triggers on an FB issue **assigned to that user**,
not on the title. That record states the consequence in the same breath — *"an unassigned or
misassigned issue reaches nobody's routine rather than everyone's"* — and carries the second half
that makes it safe: *"an FB issue must always be opened with the correct assignee."*

The mechanism enforces the first half and nothing enforces the second. `open-issue.sh` takes
`--assignee` as an option and its own header records the choice deliberately: *"A dropped
assignment does NOT fail issue creation — a filed ask with no assignee is [preserved]"*. An issue
opened by hand on GitHub, which is how all ten of these arrived, passes through no seam at all.
The result is that ten of the operator's own asks — one of them seven days old — sit open,
unread by `[Specificate]`, while `issue-triage` re-derives them as `never_ingested` every hour
and hands them to an agent that is bound to *propose, never perform*.

The oldest, #907, is itself about the loop running out of inbound work. It has been unreachable by
the intake for a week for a reason nothing reports: it has no assignee.

## What this names

The gap is a **reading nobody makes**, not a missing capability. `issue-triage` already computes
`never_ingested`; what it does not compute is *why*, and an unassigned issue is the one cause a
file test settles. Two bounded possibilities, and choosing between them is the operator's:

1. Split `never_ingested` into `never_ingested_unassigned` (an ask no routine can ever reach) and
   `never_ingested_assigned` (an ask a routine can reach and has not), so the first becomes a
   question addressed to the issue's author naming the one act — assign it — rather than a count
   in a summary.
2. Or have the intake also take an unassigned `[FB]` issue whose author is a known identity,
   which re-opens the fan-out `20260805130926` was written to close and is therefore the larger
   change.

## Non-goals

This proposes no closure, assignment, consolidation or deletion of any issue — `issue-triage`
proposes and never performs, and an assignee is the operator's own act on their own ask. It does
not re-litigate `20260805130926`, whose first half is working exactly as instructed.
