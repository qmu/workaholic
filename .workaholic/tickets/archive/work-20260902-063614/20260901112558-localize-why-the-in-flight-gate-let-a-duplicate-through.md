---
created_at: 2026-09-01T11:25:58+00:00
status: done
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

### The repair the evidence names (recorded when driving, 2026-09-02)

**Neither hypothesis in this section survived the reproduction, and the reported mechanism was not
at fault** — which step 5 names as a successful outcome of this ticket. `work_waiting` and
`open_proposal` govern whether an **ask** is originated, and not one of the five pairs came from a
machine-originated ask, so there is nothing in `/propose` to repair. The claim protocol also held:
every loop-side branch in the table carries exactly one `Claim a PR-unit` commit for its own unit.
`stop-two-runs-from-claiming-and-driving-one-unit` owns the claim-race shape and is not implicated
by this evidence either.

What the evidence **does** name is downstream of all of them, and is minted as
`20260902065500-close-a-mission-whose-work-landed-by-another-route.md`: when a person implements a
filed finding by hand, the loop's own pull request is closed unmerged, so its tickets are never
archived, its acceptance is never ticked and `close.sh` is never reached — and the mission stays
`active` with its queue full. Measured 2026-09-02: three such missions, 17 queued tickets, all
three offered by that morning's survey over work already on `main`. The minted ticket proposes a
**question to the mission's assignee** and no automatic close and no exclusion, because the only
alternative reading available (*is this already implemented?*) is a judgement about behaviour that
this repository has already refused by name.

The one repair that is **not** proposed anywhere: nothing here asks a person to stop implementing
by hand. That is the operator's own route into their own repository; what the loop owes is to
notice afterwards.

## Final Report

Development completed as planned. Nothing was changed: this is a diagnosis ticket, and
`git diff` over `plugins/workaholic/skills/propose/` and `.../drive/scripts/lib/claims.sh` is
empty, as its own verification method requires.

### The five pairs, reproduced from the record

| # | Pair | Head branch | Claim commit | Opened (UTC) | Outcome | Mechanism |
| - | ---- | ----------- | ------------ | ------------ | ------- | --------- |
| 1 | #790 vs **#789** | `work-20260831-184331` vs `work-20260901-043617` | `Claim a PR-unit` 18:43:33, heartbeats to 19:17 vs **none** (one human commit 19:36:58) | 19:59:20 vs 19:37:28 | #790 closed unmerged ("do not merge — superseded by #789"); #789 merged 19:37:35 | **a person implemented the finding by hand while the loop's claim was live** |
| 2 | #801 vs **#800** | `work-20260831-214435` vs #800's own | `Claim a PR-unit` 21:44:37 vs **none** (one human commit 22:53:22) | 23:12:48 vs 22:53:57 | #801 closed unmerged, its last commit `Record the refused merge on the branch`; #800 merged 22:54:07 | same |
| 3 | #802 vs **#800** | `work-20260831-204424` vs #800's own | `Claim a PR-unit` 20:44:26 vs none | 23:14:11 vs 22:53:57 | #802 closed unmerged, same recorded refusal; #800 merged | same — #800 closed **four** filed findings in one commit |
| 4 | #520 vs #519 | `work-20260818-215157` vs `work-20260818-213641` | `Claim a PR-unit` 21:51:58 vs 21:36:42 | 22:00:17 vs 21:50:23 | #519 merged 21:50:38; #520 closed unmerged | **not a duplicate pair at all** — #519 drove `20260818202706-make-the-housekeep-check-in-carry-its-findings`, #520 drove `20260818203011-turn-off-routine-completion-notifications`; different tickets, different work |
| 5 | #466 vs **#465** | `work-20260814-104146` vs `work-20260814-194029` | **none on either** — both are publish-tree publications | 10:41:50 vs 10:40:34 | #465 merged 10:40:36; #466 closed unmerged | **two `/specificate` runs 19 seconds apart on one human ask**, each writing its own feedback record (`20260814103718-…` and `20260814193737-…`) so the ref-keyed dedup had nothing to match |

### The localization

- **`work_waiting` did not read false, and neither did `open_proposal`.** Both govern whether an
  **ask** is originated by `/propose`; not one of these five pairs came from a machine-originated
  ask. Pairs 1–4 are implementations of asks that already existed, and pair 5 is a human's own
  `discussion`-sourced instruction (`subject: person:tamurayoshiya`). The reported mechanism was
  not at fault.
- **The claim protocol was not at fault either.** Every loop-side branch above carries exactly one
  `Claim a PR-unit` commit for its own unit, and no two loop branches ever held the same unit.
  `stop-two-runs-from-claiming-and-driving-one-unit` owns that shape and is not implicated here.
- **Three of five pairs are one mechanism**: a person implemented a filed finding by hand and
  merged it directly, while the loop was mid-drive on the same finding under a live claim. No gate
  in this loop governs a person's own commit, and none should.
- **One pair is not a pair.** #519 and #520 drove different tickets. #520's ticket
  (`20260818203011-turn-off-routine-completion-notifications.md`) never landed and is **still
  queued today** — a separate, live fact, not a duplicate implementation.
- **One pair predates its repair.** Pair 5's dedup now reads unmerged branches
  (`specificate/scripts/lib/unmerged-branches.sh`, 2026-09-01), which is exactly the reading that
  was missing on 2026-08-14. The second Considerations candidate — *check the dates before
  proposing a repair to code that already moved* — is confirmed for that pair.

### Discovered Insights

- **Insight**: The five "duplicate implementations" are three different mechanisms, and the one
  named in the report is none of them.
  **Context**: Generalizing from one pair would have produced a change to `/propose`'s gate that
  could not have prevented a single one of the five. Step 1's *do not generalize from one pair* is
  the whole reason the ticket found anything.
- **Insight**: A hand-merged fix leaves the loop's bookkeeping untouched, and the bookkeeping is
  what drivability is derived from.
  **Context**: `take-the-moderation-tick-s-log-off-main`,
  `read-the-base-s-colour-past-a-bookkeeping-tip` and `prove-a-claim-branch-is-empty-before-deleting-it`
  all read `active` with `0/3` acceptance and 17 queued tickets on 2026-09-02, and that morning's
  survey offered all three — over behaviour that is already on `main`. Minted as
  `20260902065500-close-a-mission-whose-work-landed-by-another-route.md`.
- **Insight**: Two feedback records for one ask can differ only by the timezone their `created_at`
  was stamped in (`20260814193737` is JST, `20260814103718` is UTC — 19 seconds apart in real
  time).
  **Context**: The stem is the dedup key everywhere downstream, so two runs on one ask are
  invisible to each other by construction unless the dedup reads the unmerged branches, which is
  what it now does.
