---
created_at: 2026-09-19T09:47:01+09:00
status: done
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

## Final Report

Development completed as planned, with one deliberate deviation from the ticket's own
suggestion and one measured surprise, both recorded below.

**The before-state, reproduced (step 1).** A tree-wide walk for `expected_surface` returned
`work/scripts/feedback-outcome.sh:3,17,18`, `work/scripts/delivery-ledger.sh:44,70` and the
fixtures in `scripts/tests/agentic-loop/repair-contracts.test.mjs`. In both scripts it is an
**input**; no artifact carried it and no writer existed. The finding is exactly as the ticket
stated it.

**The artifact chosen, and the two rejected (step 2).** The **feedback record**. The reasons
are written in the writer's own header (`feedback/scripts/create.sh`) rather than here: it is
the grain `feedback-outcome.sh` reconciles — its items are keyed on `.feedback` — so the reader
resolves the value with no second walk and no relation; it has exactly one writer; and it is
**immutable**, which is what stops the party implementing the work from editing the expectation
it is judged against. The **ticket** was rejected because a request routinely becomes several
tickets (the reader would have to fold N values and rule on a disagreement) and because a replan
rewrites tickets. The **mission** was rejected because it is the loop's own decomposition rather
than the ask, it is mutable, and an ask answered by a loose ticket has no mission at all. The
ticket's own worry about immutability — that a wrong surface could never be corrected — is
answered by the stream's existing mechanism: a new record naming the old in `supersedes`.

**Deviation from step 4/7, stated.** The ticket proposed extending
`scaffold-proposed-ticket.sh` and documenting in `create-ticket/reference/ticket-format.md` and
`specificate/reference/workflow.md` **step 9**. Those are the ticket's seams, and the chosen
artifact is the record — so the writer is `feedback/scripts/create.sh --review-surface`, the
schema documentation is `feedback/SKILL.md` plus `feedback/reference/schema.md`, and the
`/specificate` instruction is **step 3**, where the record is registered, beside `--subject`.
The ticket anticipated this with "(or the chosen writer)"; nothing was added to the ticket
schema, and `scaffold-proposed-ticket.sh` is byte-identical.

**Absent and unreadable are kept apart (step 6).** `feedback/scripts/review-surface.sh` answers
`readable: true` with an empty `surface` for a record naming none, and `readable: false` with
`record_not_found` / `record_unreadable` / `no_feedback_ref` otherwise. The consumer's ladder
answers `surface_unresolved` for the first and a **new** word `surface_unreadable` for the
second, with `surface_reason` on the row naming which. `surface_unreadable` is deliberately not
folded into the existing `unreadable`, which means *the queue could not be read* — one word for
two different absences is how two readings drift.

**A caller fact can no longer override.** The resolution happens in `feedback-outcome.sh`, the
one derivation, and `delivery-ledger.sh` composes it — so `expected_surface` was removed from
that fold's forwarded fields entirely rather than being passed and then ignored. A caller that
still supplies the field is **ignored, never refused**, so no existing call site breaks.
`verified_surface` is still forwarded: it is what the run observed, which is the claim being
checked.

### Discovered Insights

- **Insight**: a cross-skill script reference inside a skill's own text pulls that whole skill,
  and everything it transitively reaches, into the generated `outputs/workflows/` closure.
  Writing `review-surface.sh` into `skills/work/` and naming it from `feedback/SKILL.md` added
  **18** untracked directories of unrelated skill (`moderate/`, `work/`, `workaholify/` under six
  bundles) at the next `build.mjs`.
  **Context**: `drive/SKILL.md` already names this hazard for the condition-age reader and
  deliberately writes the path without the `${CLAUDE_PLUGIN_ROOT}` invocation form. The repair
  here was to move the reader into the skill that owns the artifact it reads — `feedback/` — so
  the closure gains one file rather than three skills. A reader of a record belongs with the
  record's schema; the placement that looked natural (beside its one consumer) was the expensive
  one.

- **Insight**: an apostrophe inside a comment in a single-quoted jq program terminates the shell
  string, and the failure surfaces as `jq: syntax error, unexpected end of file` followed by the
  remainder of the program being executed as shell commands.
  **Context**: `rules/shell.md` classifies an uncompilable embedded jq program as our own defect
  rather than an empty answer, and `test-workflow-scripts.mjs` compiles every extractable one —
  but a program broken *by the shell quoting around it* is a different failure and is caught only
  by a fixture that actually runs the script. Write such comments without apostrophes.

- **Insight**: an ask that names no review surface can never reach `implemented_and_verified`,
  and that was already true before this change — an absent caller-supplied `expected_surface`
  answered `surface_unresolved` too.
  **Context**: it matters more now that the mission's third ticket will close a source issue only
  on `implemented_and_verified`. Most asks are not about a rendered screen, so most items will
  reconcile `surface_unresolved` and stay open with that word named. That is the safe direction
  the mission chose, and it is a real cost: the operator will see open issues carrying
  `surface_unresolved` rather than a closure. It is recorded here rather than repaired, because
  making an unresolved surface a pass is precisely the hole this ticket closed.
