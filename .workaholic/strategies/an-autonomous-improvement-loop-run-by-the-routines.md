---
type: Strategy
title: An autonomous improvement loop run by the routines
slug: an-autonomous-improvement-loop-run-by-the-routines
status: active
target_date: 2026-08-31
assignees: [a@qmu.jp]
feedback: [20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
created_at: 2026-08-21T16:25:23+09:00
author: a@qmu.jp
---

# An autonomous improvement loop run by the routines

## Aim

The development loop runs itself, and the developer's work moves up a layer.

Today the loop has two turning routines and one inbound dependency it cannot supply:
`[Specificate]` (`:15`) turns an ask into a record and the work it warrants, `[Implement]`
(`:30`) drives that work to a pull request — and the **ask** has to come from a person. An
hour in which nobody opened an issue is an hour in which the loop reads an empty inbox and
reports `nothing_in_hand`. The loop is a machine with a human-shaped hole in it, and the
hole is the part that matters least for a person to fill: writing the next ticket.

This direction closes that hole from the direction of the **strategy**, not the backlog. A
third routine, `[Propose]`, reads the running identity's own active strategies, judges what
would move each closer to its aim before its date, and opens that judgment as a GitHub
issue assigned to the strategy's owner — the one surface `[Specificate]`'s unattended
entrance actually reads. Three routines then turn one loop: `/specificate` → `/implement` →
`/propose` → `/specificate`. What a person supplies is no longer the ticket but the
**direction**: an Aim, a Schedule, an Assignee. Enriching that is the work that is left.

**It is evolutionary, not maintenance.** A proposal commits to the strategy or it is not
emitted. It must be one of three moves against the aim — going **deeper** into what the aim
already covers than the landed work has gone, going **broader** into a part of the aim
nothing has touched, or **contracting** something the landed work made inconsistent with the
aim. "Tidy this up", "add a test", "the docs drifted" are `/moderate`'s job and are refused
here by name. This is deliberately the first unattended routine in the repository to drop
the conservative *when unsure, record only* bar, and it is the reason the direction needs a
brake rather than a bar.

**The brake is mechanical and derived, never a judgment the run can talk itself past.** A
strategy is proposed against only while it is live, owned by the running identity, inside
its date, **legible to the attribution reader**, carrying no work already waiting, and not
already proposed against today. A strategy the lossy reader cannot see into gets a named
refusal rather than a guess — which is what keeps "widen the depth here, contract there"
from being judged on a blind read.

Reached when the three routines have turned the loop unattended: a proposal opened by
`[Propose]`, ingested by `[Specificate]`, driven by `[Implement]`, and visible back on the
strategy it came from through the attribution reader that already exists — with no field
added to any artifact and no second inbox created.

## Schedule

Target: 2026-08-31

Filed 2026-08-21 from issue #555. Target 2026-08-31. The first turn is the routine itself: /propose ships with its skill, its command and its developer-scoped [Propose] template at :40, and the loop is proved end to end on this repository before the date. Each subsequent turn is a proposal this strategy's own routine opens, ingested at the next :15 and driven at the next :30 — so progress after the first turn is measured in turns of the loop, not in scheduled milestones.
