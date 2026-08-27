---
created_at: 2026-08-27T01:20:31+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Read whether a reported unit ever landed

## Overview

Every claim excluded `claimed_reported` is a unit the loop finished and reported. Nothing
anywhere asks what happened to it afterwards: the pull request may have merged an hour later,
may still be open and green, or may have been closed. Every ticket below keys on that reading,
so it is derived once, in one pure reader, before anything acts on it.

The reading is a **fact about the pull request**, not a decision: is it open, merged or closed,
and — when open — how long has it been open? The script makes no judgement about whether that is
acceptable, offers no next action and writes nothing.

Measured 2026-08-27 00:42 UTC, and reproduced at 01:15 UTC while writing this ticket: pull
requests #622, #625, #633 and #635 were open and unmerged, `backlog_size: 11` with `backlog: []`,
and the oldest ticket excluded `claimed_reported`
(`20260818203011-turn-off-routine-completion-notifications.md`) had been so since 2026-08-18.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a degraded read is named, never rendered
  as an answer

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle; the source of the
  `queue_drained` / `claimed_reported` rows this reader takes as input.
- `plugins/workaholic/skills/drive/scripts/claim-merged.sh` — the claim protocol's existing single
  network read (branch → merged pull request). Read its header first: the three-valued
  `unanswerable` contract and the `offline` / `disabled` skips are the shape this reader follows,
  and reusing it is preferable to opening a second lookup if it can answer the question.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one sanctioned GitHub transport
  (`rules/shell.md`); never `gh pr …`.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where the shared derivation lives, so
  the reader and its consumers cannot disagree.

## Implementation Steps

1. **Reproduce first.** Run `list-claims.sh` and `plan-units.sh` on a current checkout and record
   the rows excluded `claimed_reported`, then check each one's pull request by hand. Confirm the
   measurement above before changing anything — the ticket set below is built on it.
2. **Localize.** Establish where the answer would come from: whether `claim-merged.sh` already
   answers "did this branch's pull request merge" for a reported claim, or whether the open/closed
   distinction and the age need a read it does not make.
3. Add the reader — one script, pure, no writes, no decisions — answering per reported claim:
   the pull request's state, its number/URL, and its age when open.
4. **Degrade by name.** An unreachable transport, a claim with no pull request, and a lookup that
   cannot be made are each their own named reason with exit 0. A reading that could not be made is
   never rendered as one that was; this is `claim-merged.sh`'s `unanswerable` rule and it applies
   here for the same reason.
5. Add hermetic coverage in `scripts/test-workflow-scripts.mjs` over a fixture — no network, no
   `gh`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given a claim excluded `claimed_reported`, the reader answers its pull request's state and, when
  open, its age.
- Every failure to read answers a named reason with exit 0; none is reported as a state.
- The script writes no file and stages nothing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Run the reader over the fixture with the transport stubbed absent and confirm the named
  degradation.

**Gate** — what must pass before approval:

- The hermetic suite passes and the reader makes no `gh issue|pr|repo` call.

## Considerations

- If `claim-merged.sh` can answer this with a widened output rather than a new script, prefer
  that: the claim protocol deliberately holds **one** network read, and a second one is a cost
  this mission should pay only if the question genuinely differs.
- The reader is deliberately blind to *why* a pull request is open. A scan finding holding it and
  a transport refusal look identical here — telling them apart is the later tickets' job, and
  putting that judgement in this script would give two tickets one answer.
