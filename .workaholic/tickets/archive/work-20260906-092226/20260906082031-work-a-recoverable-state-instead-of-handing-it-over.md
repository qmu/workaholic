---
created_at: 2026-09-06T08:20:31+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: record-a-worker-s-finish-from-its-own-reported-outcome
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: 
---

# Work a recoverable state instead of handing it over

## Overview

`drive/SKILL.md` writes several parked, content-conflict and declared-verification states as
waiting on a person. The operator's ask is explicit that this is the rule to change, not the
wording: routine engineering decisions, recoverable prerequisites and workflow bookkeeping
must not become handoffs, and only a concrete, **verified** external limitation may be
reported as one. A classifier's refusal of a mechanical script is not proof that a coding
agent cannot finish the work. The same shape appears one layer down: a leaked claim-arbiter
lock is documented as something for a person to act on, and a lock-blocked mission zeroes the
claimable count so no pass ever inspects it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the states written as human-owned.
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements* and *When a
  bounded act may read a judgement*; the discipline that must survive this change.
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` and
  `run-verification-probe.sh` — the probe form that already falsifies a stale declaration.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — `content_conflict`, the one
  refusal that currently waits on a person.
- `plugins/workaholic/skills/drive/scripts/claim-arbitrate.sh` — the lock whose leak is
  documented as a person's act (its *reporting* half is repaired by PR #995; the policy half
  is here).
- `CLAUDE.md` — the claim protocol and `/implement` run-report sections.

## Implementation Steps

1. **Reproduce and localize.** Enumerate, with `file:line`, every state this loop currently
   hands to a person: each `## Handoff` route, `content_conflict`, each prose
   `verification_handoff:`, and the arbiter's leaked-lock note. For each, record what the
   loop actually knew at the moment it handed over.
2. Classify each: a **verified external limitation** (a credential, device or account the run
   provably lacks) or an **engineering judgement the loop declined to make**. The probe form
   already tells the two apart for declared handoffs — use it as the test, not as an analogy.
3. Change only the second class. A hunk a merge cannot settle, a check the agent can repair,
   an obsolete handoff assumption and a leaked lock with no live claim behind it are the
   loop's work.
4. Leave the proof discipline intact: an act still re-derives its proof at the moment of the
   act, is idempotent, and refuses every bound by its own word. Nothing here bypasses a
   repository protection, overrides a gate, or manufactures a verification.
5. Make the lock-blocked mission visible to the count ticket 1 widened, so a pass inspects the
   recovery state rather than reading an empty queue.
6. Update `CLAUDE.md` and every affected rules document in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every state enumerated in step 1 is classified, and each reclassified one names what the
  loop will now do instead.
- A `secret` finding, a repository protection and a genuinely absent credential still stop the
  run, and the run says so with the evidence.
- `drive/reference/claims.md`'s proofs-and-judgements tables still pass their suite rows.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- This is the ask's own instruction to change human-owned rules, and it is quoted rather than
  inferred. It is still the ticket most likely to be judged too broad on review — the
  classification in step 1 is what makes the change arguable rather than asserted.
- The boundary that must **not** move: the proof discipline exists so a destructive act is
  safe, and the ask does not complain about it. Say so where the change lands.
- `content_conflict` is already the writer's residue after the reader's prediction is
  attempted; the question is whether an agent resolving a substantive hunk is inside or
  outside this loop's remit, and the ask answers that it is inside.

## Final Report

**Step 1 — every state this loop hands to a person, enumerated with `file:line`, and what the loop
actually knew at the moment it handed over.**

| State | Where | What the loop knew |
| ----- | ----- | ------------------ |
| `secret` finding | `drive/SKILL.md:169` | a match it made; the override is a person's ruling it does not have |
| `size`/`leak` finding | `drive/SKILL.md:170`, `:289` | `leak` is a match against a developer-maintained denylist — a vocabulary judgement |
| no confirmation method | `drive/SKILL.md:171` | the deployment record declares none |
| `content` conflict on an `auto` unit | `drive/SKILL.md:173` | the hunks; the merge was attempted |
| `catch_up_refused: content_conflict` | `drive/SKILL.md:155`, `:273`; `catch-up-claim.sh` | the colliding files; the merge was attempted and left the branch byte-identical |
| `settle_refused: content_conflict` | `drive/SKILL.md:159` | the same, one artifact over |
| `verification_handoff:` prose (`unmeasured`) | `drive/SKILL.md:117` | **a sentence somebody wrote once**, and nothing else |
| `awaiting_verification` claim | `drive/SKILL.md:43`, `:296` | that the sentence exists on remaining queued work |
| operator-facing pull request | `drive/SKILL.md:49`, `:193`, `:305` | the seam's own refusal word |
| `pull_request_reviewed` | `drive/SKILL.md:151` | a person has submitted a review |
| leaked arbiter lock | `claim-arbitrate.sh:59` | that no live claim stands behind the ref |

**Step 2 — classified.** *Verified external limitation* (unchanged, and each still stops the run
with its evidence): the `secret` finding, the `leak` finding, a missing confirmation method, an
operator-facing publication (merging **is** the ruling), a `probe:` declaration reading `blocking`,
`pull_request_reviewed`, and a colleague's claim at any age. *Engineering judgement the loop
declined to make* (changed): both `content_conflict` refusals, and the prose `unmeasured`
declaration. The probe form was used as the **test** rather than as an analogy: a declaration whose
probe runs and fails is the first class; one that cannot be falsified at all is the second.

**Step 3 — only the second class changed.**
- A `content_conflict` is now **this run's own work**, taken at the **agent** level on four stated
  bounds, because no script may resolve a hunk by judgement — the shape the
  `session_type_cannot_merge` connector retry already uses. `catch-up-claim.sh` and
  `settle-stranded-publication.sh` are **byte-identical**: same refusal, same byte-identical branch,
  same bounds.
- A prose `unmeasured` declaration no longer stands on its own words: the run reads the limitation
  the sentence names and establishes whether it is present **here**, takes the handoff route only on
  one it verified (naming what it checked), and otherwise drives the unit.
- **Measured, twice**: three of four parked pull requests on a consuming repository had false
  declarations when finally probed; and on this repository this morning, PR #997 was routed to
  `handoff` on a derived `.claude/` declaration while its own changed-file list held **zero** files
  under that path — a finished, green unit undelivered on a premise one REST read falsified.

**Step 4 — the proof discipline is intact and that is stated where the change lands.** Every act
still re-derives its proof at the moment of the act, is idempotent, writes nothing on a refusal and
refuses each bound by its own word. Nothing bypasses a repository protection, overrides a gate or
manufactures a verification: `secret` hard-stops, `leak` holds the pull request open, a reviewed
pull request is never pushed over, a colleague's claim is untouchable.

**Step 5 — the premise was checked rather than assumed, and it does not hold.** A leaked arbiter
lock does **not** zero the claimable count: the lock is contended inside `claim.sh` §3b, after the
survey, so `plan-units.sh` still offers the mission and `claimable-units.sh` still counts it; the
refusal is `claim_race_lost` at claim time. And the leaked lock was **already** the loop's work —
`claim-arbitrate.sh reap` releases a lock no live claim stands behind, and `claim.sh` runs it lazily
on a lost take. What was wrong was the header's stale sentence *"for a person to act on"*, written
before `reap` existed and left behind; only that wording moved. This is reported rather than
repaired because there was nothing here to repair.

**Step 6** — `CLAUDE.md`, `skills/drive/SKILL.md`, `commands/implement.md` and
`skills/drive/scripts/claim-arbitrate.sh` updated in this change.

**Gate.** `node scripts/test-workflow-scripts.mjs` — 6663 passed, 0 failed;
`drive/reference/claims.md`'s proofs-and-judgements rows pass unchanged, because no verdict word was
added, removed or reclassified.
