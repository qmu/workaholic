---
created_at: 2026-08-31T15:05:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260831-152743
---

# Beat the heartbeat while one ticket is driven

## Overview

MINTED MID-RUN (2026-08-31, by the `/implement` run driving `batch-20260831141002`).
A unit whose **first** ticket takes longer than the staleness window loses its own
claim by construction, because nothing beats the heartbeat until that ticket is
archived.

`workaholic:drive` §4 says to run `heartbeat.sh <unit-id>` "roughly every ten
minutes or once per ticket (each `archive.sh` refreshes it for free)". For a unit
of several short tickets those two cadences coincide and the claim never lapses.
For a unit that is **one long ticket** they do not: the only free beat is the
archive at the very end, so the whole implementation runs on the claim commit's
own timestamp.

**Measured on `batch-20260831141002`** (one ticket,
`20260831064500-read-doc-drift-against-the-published-base`): claimed at 14:10:27,
implementation and its hermetic rows finished at ~14:55, `archive.sh` committed
locally — and the push was rejected non-fast-forward, because a second
`[Implement]` tick had already run `claim.sh resume` at **14:43:13** and
heartbeated at 14:49:04. The protocol worked exactly as designed: the heartbeat
had lapsed, so the claim was resumable, and it was resumed. The losing run stood
down rather than force-pushing over an actively-driven branch, so its commit
(the fix plus three hermetic rows) never reached origin and the second run
re-drove the same ticket from the top.

**No mechanism is broken, and that is the point.** `claim.sh resume` is correct,
the staleness window is correct, and the driving run is the thing that was
non-conformant. What the ticket asks is whether "beat roughly every ten minutes"
should stay a prose instruction an agent must remember mid-implementation, when
the one seam that beats for free fires only at the end of the work.

## Policies

<!-- The standard engineering policies this implementation would answer to. -->

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a liveness signal nobody emits is not a liveness signal

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` §4 — where the cadence is stated as
  prose ("roughly every ten minutes or once per ticket").
- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — the beat itself; an
  empty commit against a scratch index, already cheap and already idempotent.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — the seam that beats for
  free today, and only at the end of a ticket.
- `plugins/workaholic/skills/drive/reference/claims.md` — the staleness window
  (`WORKAHOLIC_CLAIM_STALE_HOURS`) and the resume contract this interacts with.
- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` — the per-ticket
  steps, where a mid-ticket beat would have to be named if it belongs to a step
  rather than to the agent's memory.

## Implementation Steps

1. **Establish which window actually bit.** The resume happened 33 minutes after
   the claim, so read whether that is `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`
   (the resume gate) rather than `WORKAHOLIC_CLAIM_STALE_HOURS` (the *reported*
   staleness), and fix against the one that governs `claim.sh resume`. Do not
   change either default — the window is not what this ticket questions.
2. **Decide where a mid-ticket beat belongs, and record the decision.** The
   candidates are: a named step in `reference/ticket-workflow.md` that the agent
   runs before starting implementation on a ticket; a beat inside an existing
   per-ticket seam that already runs early; or leaving it prose and instead
   making the *loss* visible. Prefer whichever needs no new store, no cursor and
   no field on any artifact.
3. **Do not make the beat a background timer.** Nothing in this loop runs
   concurrently with the agent's own work, and a script that beats on a schedule
   would be a second liveness authority beside the branch tip, which is the one
   oracle.
4. Report the case this ticket could not settle by itself: whether a **losing**
   run should be able to hand its work over rather than discard it. That is a
   larger question than the beat and belongs to its own ask.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose first ticket runs longer than the resume window keeps its claim.
- No new store, cursor, or field on any artifact; the branch tip stays the one
  liveness oracle.
- `claim.sh resume`, the staleness verdicts and both windows' defaults are
  byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a hermetic row over a claim whose
  tip is aged past the resume window, asserting the drive path beats before it
  lapses.
- `git diff` shows no change to `lib/claims.sh`'s verdict derivation.

**Gate** — what must pass before approval:

- The chosen home for the beat is argued against the two alternatives named in
  step 2, not merely asserted.

## Considerations

- The cost of the measured failure is bounded but real: one ticket's
  implementation was written twice, and the first copy — which was complete,
  validated and locally committed — was thrown away because pushing it would have
  meant force-pushing over a branch another run was actively driving. The rule
  that forbids that is right; what it exposes is that a losing run has no
  hand-over path at all.
- This ticket carries **no `feedback:` refs and no `mission:`**, deliberately:
  the provoking unit carried none either (`unit-feedback-stems.sh` answered
  `count: 0`), so there is nothing to inherit and nothing to attribute. The
  stated cost is that its own finish line will have no thread to land in.
- `/moderate`'s `raced-units` step will not surface this shape: it reads
  `ambiguous_claim` (two *live* claims), and a resume leaves exactly one. Whether
  a resumed-out-from-under run deserves its own reading is part of step 4's
  question, not an assumption this ticket makes.

## Final Report

Development completed as planned.

**Step 1 — which window bit.** `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`, default **30**
(`lib/claims.sh:980`), which is the gate `claim.sh resume` reads. The measured resume was 33
minutes after the claim, so it is that window and not the 24-hour `WORKAHOLIC_CLAIM_STALE_HOURS`
(`:969`), which is the *reported* staleness and governs no takeover. Neither default was changed.

**Step 2 — where the beat belongs, and why not the other two.** It is **step 0 of the per-ticket
workflow** (`drive/reference/ticket-workflow.md`), and `drive/SKILL.md` §4's *"roughly every ten
minutes or once per ticket"* is replaced by that fixed point. A cadence is something an agent must
track while its attention is on the implementation; a step is discharged where the workflow already
stops. The two alternatives are refused with their reasons, in the document itself:

- **A beat inside an existing per-ticket seam** — the only seam that runs early is
  `gather/scripts/ticket-metadata.sh`, a **pure reader shared with other callers**, and giving a
  reader a side effect is how a script acquires behaviour nobody expects.
- **Making the loss visible instead** — a reading that says the claim was taken does not return the
  work. The measured cost was a finished, validated implementation discarded; naming it afterwards
  recovers none of it.

It adds no store, no cursor and no field on any artifact — it is the empty commit `heartbeat.sh`
already makes against a scratch index.

**Step 3 — no background timer.** Refused outright and said so in the document: it would be a
second liveness authority beside the branch tip, which is the one oracle.

**Step 4 — the case this ticket could not settle.** Whether a **losing** run should be able to hand
its work over rather than discard it is a larger question and is reported, not answered here. What
is now true is that the losing case is much rarer; what is unchanged is that when it happens the
work is still thrown away, and the rule that forbids force-pushing over an actively-driven branch
is still right. That ask needs its own ticket.

**The prose is pinned.** Because the repair is a step an agent runs, the suite carries a row that
proves the *behaviour* (a claim aged past the window is resumable; after one beat it is not — the
beat being the only thing that changed between the two reads) **and** that the per-ticket workflow
still opens with it and the retired cadence has not survived anywhere.

### Discovered Insights

- **Insight**: the two windows are easy to confuse and only one governs a takeover —
  `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` (30, the resume gate) versus
  `WORKAHOLIC_CLAIM_STALE_HOURS` (24, reported and never acted on).
  **Context**: a reader who sees "stale: false" on a claim row and concludes the claim is safe is
  reading the wrong one. The row's `stale` is the 24-hour reading; resumability is decided an order
  of magnitude sooner.
- **Insight**: this ticket's own unit reproduced the failure it describes — one long ticket, and
  the run had to beat by hand before it could work on it.
  **Context**: the fix was applied to the run applying it, which is the strongest available
  evidence that step 0 belongs where it was put.
