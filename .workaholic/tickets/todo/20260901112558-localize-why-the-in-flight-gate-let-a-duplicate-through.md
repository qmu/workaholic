---
created_at: 2026-09-01T11:25:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Localize why the in-flight gate let a duplicate through

## Overview

PROPOSED, and **diagnosis-first** — this is a failure report, so it reproduces and localizes before
it designs (`workaholic:discover`, *Diagnosis-First Rule*).

The report: `work_waiting` + `open_proposal` are documented as giving *one mission per strategy in
flight at a time*, and five pairs of duplicate implementations reached pull requests anyway
(`#801`/`#802`/`#790` against `#800`; `#520` against `#519`; `#466` against `#465`). Each cost a
person reading two implementations of one defect and carrying the good parts across by hand.

What is **not** yet established is which mechanism failed. The gate is `/propose`'s, and it governs
whether an *ask* is originated; the duplicate pairs are *implementations*, which the claim protocol
governs. This ticket's whole job is to find out which — and to say so — before anything is changed.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a cause is measured, never assumed

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — where `work_waiting` is
  derived (an active attributed mission OR'd with a queued attributable ticket).
- `plugins/workaholic/skills/propose/scripts/list-open-proposals.sh` — the other half, keyed on the
  `strategy: <slug> / move: <move>` marker; its header states that an unreadable brake proposes
  nothing.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — what `work_waiting` reads
  through; a mission archived on a branch but not on the base is invisible to it by construction.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the claim side: a **fresh** claim mints
  its own `work-*` name, so two runners surveying before either pushes both succeed
  (`stop-two-runs-from-claiming-and-driving-one-unit` is the mission that owns that half).
- The six pull requests named above — the primary evidence.

## Implementation Steps

1. **Reproduce on the record first.** For each of the five duplicate pairs, read both pull
   requests: their branches, their claim commits (or absence of one), their tickets, the missions
   and strategy those tickets belonged to, and the timestamps of each run's survey and first push.
   Write the six-column table into the mission's story; do not generalize from one pair.
2. **Localize.** For each pair decide, from that table, which of these produced the second
   implementation, and say which — the answer may differ per pair:
   - `/propose` originated a second ask because `work_waiting` read false;
   - `/propose` originated a second ask because `open_proposal` read false;
   - the ask was originated once and **two runners claimed and drove it** (the claim-race shape);
   - the second implementation came from an ask a human filed, which no gate governs.
3. **State the finding as a finding**, in the mission's story and in one line of
   `docs/proposal-loop-runbook.md`: which mechanism let each pair through, with the evidence.
4. Only then, and only for whichever mechanism the evidence names, propose the repair — as a
   `## Considerations` note here plus one new ticket if it is in this mission's Experience, or as a
   feedback record if it belongs to another mission. **Do not change a gate in this ticket.**
5. If the evidence shows the gate behaved exactly as documented and the duplicates came from the
   claim side, say that plainly and name
   `stop-two-runs-from-claiming-and-driving-one-unit` as the owning mission. A report that the
   reported mechanism was not at fault is a successful outcome of this ticket.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All five pairs are reproduced from the record, each with its branches, claim commits and run
  timestamps.
- Each pair is attributed to one named mechanism, or explicitly recorded as unattributable with the
  reading that failed.
- The finding is written where a later reader meets it (the story and the runbook).
- No gate, verdict, candidate set or claim behaviour is changed by this ticket.

**Verification method** — the commands/tests/probes that prove them:

- `git diff` over `plugins/workaholic/skills/propose/` and `.../drive/scripts/lib/claims.sh` is
  empty.
- The table names five pairs and cites a pull-request number per row.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes (nothing should have moved).

## Considerations

- **The reporter's hypothesis, recorded as a hypothesis and not as the design**: *whatever the gate
  is reading, it is not catching the case where the second run's ask arrives while the first run's
  work is on a branch rather than in the queue.* That is plausible and mechanically available —
  `attributed-work.sh` reads the checkout, so tickets archived onto an unmerged branch are still in
  `todo/` on the base while a mission closed on that branch still reads `active`. It is also not
  the only candidate, and step 2 exists to tell them apart rather than to confirm this one.
- A second candidate worth testing explicitly: the pairs may predate the `work-kind.sh` /
  `--aim-kind` change to `work_waiting`, in which case the gate that failed no longer exists in
  that form. Check the dates before proposing a repair to code that already moved.
