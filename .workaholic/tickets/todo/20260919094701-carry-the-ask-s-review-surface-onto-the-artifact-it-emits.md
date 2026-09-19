---
created_at: 2026-09-19T09:47:01+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-a-feedback-item-only-on-evidence-from-the-surface-the-person-reviews
merge_policy:
verification_handoff:
---

# Carry the ask's review surface onto the artifact it emits

## Overview

Operator's ask: **issue #1104**, item 1 — *preserve the named or contextually established review
surface as an acceptance dimension*. Measured on a consuming repository: a request about a
**public prototype** screen was implemented in the **application package's** shell, the item was
closed, and the channel summary claimed the work landed.

**Established against this tree.** The reconciliation reader already exists and already has the
term: `work/scripts/feedback-outcome.sh:17-18` refuses `surface_unresolved` on an empty
`expected_surface` and `surface_mismatch` when it differs from `verified_surface`, and
`work/scripts/delivery-ledger.sh:44,70` carries both through the multi-pull-request fold. **But a
tree-wide walk finds `expected_surface` in exactly those two files, and in both it is an
INPUT.** No artifact carries it: not the feedback record, not the mission, not the ticket. So the
value the gate compares is whatever the agent composing the facts writes at report time — the one
party whose claim the gate exists to check. A gate whose input is asserted by the party it checks
is not a gate, which is the same rule this repository states for `open_proposal` and for every
proof in `drive/reference/claims.md`.

**So the surface must be persisted where the ask is turned into work, and read back at report
time.** That is one write seam (`/specificate`) and one read (the two readers above).

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/persistence.md` — the surface becomes stored data read
  back by a later run; absent and unreadable must not collapse into one answer
- `workaholic:implementation` / `policies/test.md` — the carry and its absence are pinned
  hermetically
- `workaholic:implementation` / `policies/observability.md` — an unresolved surface must be
  visible as unresolved rather than as a pass

## Key Files

- `plugins/workaholic/skills/work/scripts/feedback-outcome.sh` (lines 3, 17-18) — the consumer and
  its two refusal words. Its input schema is where the read-back lands.
- `plugins/workaholic/skills/work/scripts/delivery-ledger.sh` (lines 44, 70) — the same fields
  through the several-pull-requests fold; both readers must read the persisted value the same way.
- `plugins/workaholic/skills/specificate/scripts/scaffold-proposed-ticket.sh` — the one writer of a
  proposed ticket. Its existing `--verification-handoff` option is the precedent for a
  ticket-level fact read off the ask rather than inferred.
- `plugins/workaholic/skills/specificate/reference/workflow.md` (steps 7, 9) — where the ask is
  judged and the tickets are emitted; the surface is read off the ask here or nowhere.
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the ticket's own schema;
  whatever field is added must be documented here in the same change.
- `plugins/workaholic/hooks/validate-ticket.sh` — the ticket floor. Decide deliberately whether the
  new field is floored; an ask that names no surface is the ordinary case and must not be refused.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Reproduce the finding.** Walk the tree for `expected_surface` and confirm it appears only as
   an input to the two readers, with no writer and no artifact field. Record that as the
   before-state.
2. **Decide where the value lives, and record why.** The candidates are the **ticket** (closest to
   the work, and the grain `feedback-outcome.sh` reconciles), the **mission** (one surface for a
   whole correction pass) and the **feedback record** (immutable, closest to the person's words,
   and therefore unable to be corrected by a later replan). Choose one, name the two rejected and
   the reason, in the writer's own header. Do **not** add the same field in two places.
3. **Read it off the ask, never infer it.** The value is what the ask names — a package, a route, a
   screen — or the empty case. An absent surface is the ordinary answer and stays empty; a guessed
   one is worse than none, because the gate would then compare a guess against a guess.
4. **Write it at the one seam.** Extend `scaffold-proposed-ticket.sh` (or the chosen writer) with
   an explicit option, following `--verification-handoff`'s precedent exactly: passed only when the
   ask states it, never inferred from what this batch itself wrote.
5. **Read it back in both readers.** `feedback-outcome.sh` and `delivery-ledger.sh` take
   `expected_surface` from the artifact rather than from the caller's facts. Keep
   `surface_unresolved` as the answer for an artifact that names none — an absent surface must not
   silently pass the mismatch test.
6. **Absent and unreadable are different.** An artifact that names no surface is
   `surface_unresolved`; an artifact that could not be read is its own reason and never rounds to
   either a pass or an absence.
7. **Document** the field in `ticket-format.md` (or the chosen artifact's schema) and in
   `specificate/reference/workflow.md` step 9, beside `--verification-handoff`.
8. **Hermetic rows**: an ask naming a surface produces an artifact carrying it; an ask naming none
   produces one that does not, and the reader answers `surface_unresolved`; a persisted surface
   differing from the verified one answers `surface_mismatch`; an unreadable artifact answers its
   own reason; and a caller-supplied `expected_surface` no longer overrides the persisted one.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Exactly one artifact carries the review surface, written by exactly one writer, documented in
  that artifact's schema.
- `feedback-outcome.sh` and `delivery-ledger.sh` read the surface from the artifact; a caller fact
  cannot override a persisted value.
- An ask naming no surface is accepted, persists nothing, and reconciles as `surface_unresolved` —
  never as a pass and never as a publish refusal.
- An unreadable artifact answers its own reason, distinct from `surface_unresolved`.
- `surface_mismatch` still fires on a persisted surface that differs from the verified one.
- No inference: nothing writes a surface the ask did not state.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and each new row fails when reverted.
- A fixture ask naming a surface, driven through the scaffold, produces an artifact whose surface
  string is byte-equal to the ask's.
- A fixture where the caller supplies a different `expected_surface` from the persisted one
  reconciles against the **persisted** value.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The chosen artifact and the two rejected candidates are named, with reasons, in the writer's
  header. A field added with no recorded choice does not pass.
- The suite is green, the bundle rebuild is diff-clean, `layout-doctor.sh` reports
  `conforming: true`.
- POSIX `sh` throughout.

## Considerations

- **A new field on an artifact is a cost this repository has refused before** (the retired
  `strategy:` relation, the 2026-08-17 no-new-field ruling). The argument for paying it here is
  that the alternative is a gate whose input is asserted by the party being gated; state that
  argument in the pull request so a reviewer can reject it on its merits.
- **The value is prose and will sometimes be wrong.** That is acceptable — a wrong *persisted*
  surface is arguable by the person who wrote the ask, where a wrong *asserted* one is invisible.
- **Do not floor it.** An ask that names no review surface is the common case (most asks are not
  about a rendered screen), and refusing to publish one would turn a reading into an outage.
