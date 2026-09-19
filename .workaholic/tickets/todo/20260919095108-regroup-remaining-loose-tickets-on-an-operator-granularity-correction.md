---
created_at: 2026-09-19T09:51:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-one-coherent-feedback-batch-one-mission-one-pull-request-one-report
merge_policy:
verification_handoff:
---

# Regroup remaining loose tickets on an operator granularity correction

## Overview

Operator's ask: **issue #1110**, item 6 — *if the developer corrects granularity mid-flight, stop
new claims at the next safe boundary and replan the remaining loose tickets into one mission. Do
not continue the old fragmentation merely because the loose tickets already exist.* The ask's own
closing paragraph is such a correction, naming five remaining issues on a consuming repository and
stating that the session stopped before another claim so regrouping could happen on resume.

**What exists and what does not.** Nothing in this repository moves a queued loose ticket into a
mission. `mission/scripts/` has `create.sh`, `close.sh`, `archive.sh`, `append-changelog.sh`,
`tick-acceptance.sh` and `link-acceptance.sh`; the `mission:` relation is written at scaffold time
by `specificate/scripts/scaffold-proposed-ticket.sh` and by a mint inside a drive
(`workaholic:drive`, which inherits the provoking ticket's relation). A ticket already in `todo/`
with no `mission:` has no writer that can give it one.

**The shape this act must take is already decided elsewhere, and copying it is the safest part of
this ticket.** `strategy/scripts/carry-attribution.sh` is the precedent: it fires **only** on an
explicit operator announcement naming both slugs, it writes one relation and nothing else, it is
idempotent (`already`), it refuses every bound by its own word, and its publication does not
auto-merge because it carries a ruling. Every one of those properties is required here, for the
same reasons — `CLAUDE.md`'s planning job states plainly that the loop **may not merge two
missions** and **may not retire a ticket it judges mooted**, so a regroup that fired on the loop's
own reading would be exactly the act that is forbidden.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/persistence.md` — the relation is stored data other
  readers key on; a partial write must leave the tree unchanged
- `workaholic:implementation` / `policies/test.md` — every refusal is pinned hermetically, offline
- `workaholic:implementation` / `policies/observability.md` — a regroup names every ticket it moved
  and every one it refused, with the reason

## Key Files

- `plugins/workaholic/skills/strategy/scripts/carry-attribution.sh` — the precedent to copy: explicit
  announcement, one relation, idempotent, refusals by name. Read the whole script before writing.
- `plugins/workaholic/skills/specificate/reference/workflow.md` (step 9e) — how such an
  announcement is recognised and executed inside the publish tree, and why its publication does
  not auto-merge.
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the one reader of the `mission:`
  relation; the writer must round-trip through it.
- `plugins/workaholic/skills/mission/scripts/link-acceptance.sh` and `append-changelog.sh` — the
  idempotent mutators the regroup composes rather than reimplementing.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `mission_member` and `mission_closed`;
  a regrouped ticket must leave the loose offer and arrive inside its mission's unit, with no
  exclusion becoming silent.
- `plugins/workaholic/skills/drive/reference/claims.md` — the proof discipline the act inherits:
  re-derive at the moment of the act, idempotent, refuse by its own word, write nothing on refusal.
- `plugins/workaholic/hooks/validate-ticket.sh` — the ticket floor a rewritten ticket must still
  pass.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Read the precedent in full** — `carry-attribution.sh` and workflow step 9e — before writing
   anything, and record which of its properties carry over and which do not.
2. **Write the act as one script**, in the mission skill beside the other mutators: given a
   mission slug and an explicit list of queued ticket filenames, it writes the `mission:` relation
   onto each and appends one changelog line. It writes **nothing else** — no acceptance item, no
   ticket body edit, no reordering, no ticket creation and no deletion.
3. **It fires on an explicit announcement and on nothing else.** Both the mission and every ticket
   are named by the operator's ask. A run never regroups on its own reading that tickets look
   related; that reading is the executor's grouping judgement and belongs in this mission's other
   ticket, where it changes a *unit* and not an artifact.
4. **Refuse every bound by its own word, writing nothing**: `mission_not_found`, `not_active` (a
   closed mission acquires no work), `ticket_not_found`, `not_queued` (an archived or claimed
   ticket is not regrouped), `already_in_mission` (a success word, idempotent), `claimed` — a
   ticket inside a live claim is another run's work and is refused, which is the *next safe
   boundary* the ask names.
5. **All-or-nothing over the named set.** A refusal on any member leaves every member byte-identical,
   so a half-regrouped batch cannot exist. Report the refusals and the set together.
6. **Recognise the announcement at the ingest seam**, as step 9e's sibling: an ask naming a mission
   slug and a set of queued ticket filenames takes this route instead of the four forms, inside the
   publish tree, and its publication **does not auto-merge** — it carries a ruling, and the
   operator's merge is the authorship. State whether `publish-tree-pr.sh`'s `ruling_touching`
   derivation already catches the shape; if it does not, say so plainly rather than implying the
   seam enforces it, exactly as step 9e records its own weaker guarantee.
7. **Stopping new claims is the operator's act, not a new mechanism.** The ask's *stop at the next
   safe boundary* is satisfied by the existing claim protocol — a claimed ticket is refused in step
   4, and a live claim is never interrupted. Do not add a hold, a flag or a second control path.
8. **Hermetic rows**: a named queued ticket gains the relation and leaves the loose offer; a
   claimed one refuses `claimed` with the tree byte-identical; a re-run answers `already_in_mission`
   and changes nothing; a set with one bad member writes nothing at all; and every regrouped ticket
   still passes `validate-ticket.sh`.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The act fires only on an explicit announcement naming the mission and every ticket; no path lets
  the loop regroup on its own reading.
- Every refusal has its own word, writes nothing, and exits 0; the set is all-or-nothing.
- A re-run is idempotent and reports `already_in_mission`.
- A claimed ticket is refused and no claim, branch or worktree is touched.
- A regrouped ticket leaves the loose offer as `mission_member` and is driven inside its mission's
  unit; no exclusion becomes silent.
- The publication carrying the regroup does not auto-merge, and if the seam cannot derive that, the
  ticket's own text says so rather than implying it.
- No ticket is created, deleted, reordered or edited beyond the `mission:` relation.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and each refusal row fails when reverted.
- `git diff` over a refused fixture is empty.
- `plan-units.sh` over a regrouped fixture offers the mission unit and no longer offers the tickets
  loose, with `mission_member` reported.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The script header names `carry-attribution.sh` as its precedent and states the four bounds it
  inherits, citing `drive/reference/claims.md` rather than restating it.
- The suite is green, the bundle rebuild is diff-clean, `layout-doctor.sh` reports
  `conforming: true`.
- POSIX `sh` throughout.

## Considerations

- **The riskiest reading is that this becomes a general re-planner.** It is not: one relation, one
  explicit set, no judgement. Anything beyond that is `/mission <instruction>`, which a person runs.
- **A regrouped batch may breach the mission ceiling.** Say what happens — the ceiling is normative
  and the mission is a person's own instruction, so the honest answer is to report the breach and
  let the operator decide, not to silently trim or to refuse their ruling.
- **The ask's concrete continuation names five issues on another repository.** Nothing here reaches
  another repository; what ships is the mechanism, which that repository's own operator then uses.
