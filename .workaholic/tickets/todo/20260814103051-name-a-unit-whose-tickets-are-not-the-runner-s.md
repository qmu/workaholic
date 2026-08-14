---
created_at: 2026-08-14T10:30:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-the-runner-from-taking-path-owned-legacy-tickets
merge_policy:
verification_handoff: 
---

# Name a unit whose tickets are not the runner's

## Overview

PROPOSED. The reporter's third ask, and the one the other two tickets do not
cover: a developer who enabled `[Implement]` under their own identity expected it
to take their own and genuinely team-owned work. It took colleagues' work and, on
the immediate-merge route, merged it — through no human gate and with nothing in
the run report or the Slack finish line saying whose work it was.

The sibling tickets fix the *legacy-layout* case. This one covers what stays true
afterwards: a genuinely unowned ticket (empty `assignees:`) is still claimable by
anyone by design, and when a runner takes one, the fact that someone else wrote
it should be visible where a human reads the outcome. This is disclosure, not a
policy change — the ask's own "at minimum" — and the larger question it raises is
recorded under `## Open Decisions` rather than answered here.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — already carries an
  `author` field on `resumable` entries; the offered units are where it is needed.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the run report's contract.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the finish-line
  shapes (`🟢 Implemented`, `🚀 Auto Merge`, `🟡 Handoff`, `🔴 Blocked`).
- `plugins/workaholic/skills/notify/SKILL.md` — which events earn a post and the
  one-finish-per-thread rule any addition must not break.
- `plugins/workaholic/skills/gather/scripts/owners.sh` / `owns.sh` — the oracle;
  authorship is read beside ownership, never as ownership.
- `plugins/workaholic/skills/workaholify/routines/implement.md` — the routine
  prompt names the formats it authorizes; a new line must be authorized there.
- `scripts/test-workflow-scripts.mjs` — pins the routine-template copies against
  drift; a changed shape must be updated in lockstep.
- `CLAUDE.md` — the `/implement` row states what the run report names.

## Implementation Steps

1. **Reproduce and localize first.** Drive a unit whose ticket carries an empty
   `assignees:` and an `author:` other than the runner's identity, and capture
   what the run report and the finish line actually say today. The expectation is
   that neither mentions authorship — confirm it rather than assume it.
2. Decide where the fact is computed, once: read each unit's tickets' `author:`
   through the gather scripts and compare by slug (`user-slug.sh`), the same
   comparison `owns.sh` uses. Do not add a second identity comparison.
3. Surface it in the **run report** first — it is the surface that always exists,
   including when Slack is unreachable. Name the authors of a claimed unit whose
   tickets were not authored by the runner, per unit, in `/implement`'s existing
   per-unit reporting rather than as a new trailing section.
4. Surface it on the **finish line** without adding a post: the one-finish-
   per-thread rule holds, so this is a body line on the existing shape, not a
   fifth shape and not a second message.
5. Keep the line honest when the fact is unreadable: an unresolved runner
   identity is `unresolved`, distinct from "authored by the runner" — the same
   distinction `owns.sh` exists to preserve.
6. Authorize the changed shape in `workaholify/routines/implement.md` and update
   whatever `scripts/test-workflow-scripts.mjs` pins, in the same change.
7. Update the `/implement` row in `CLAUDE.md` and the drive SKILL §7 contract.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An `/implement` run that claims a unit whose tickets were authored by another
  identity names those authors in its run report, per unit.
- The unit's finish line carries the same fact as a body line on the existing
  shape — no fifth shape, no second post, one finish per thread.
- A unit whose tickets are all the runner's own adds no line anywhere.
- An unresolvable runner identity reports `unresolved`, not "authored by me".

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (routine-template pins updated).
- Manual replay of step 1's reproduction against the patched run.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green; the notify reference, the
  routine template, drive SKILL §7 and `CLAUDE.md` updated in the same commit.

## Open Decisions

- Whether `/implement` should keep taking genuinely team-owned work at all —
  options: (A) keep "empty `assignees:` = claimable by anyone" and rely on this
  ticket's disclosure, vs (B) narrow the unattended runner to `mine` only and
  leave unowned work to attended `/drive`. Neither is recommendable from here:
  (A) preserves the ownership model P2 and B3/B4 settled and keeps team-owned
  work from stranding, but leaves an unattended runner merging work its operator
  did not write; (B) removes the surprise but makes "team-owned" mean "nobody's"
  for the one executor that runs most of the time. This is the operator's ruling,
  and the driving session must record which it took in its Final Report rather
  than choosing silently.

## Considerations

- **Disclosure only.** This ticket changes no ownership semantics; it makes an
  existing, deliberate behavior legible. Do not fold the Open Decision above into
  it by quietly narrowing the survey.
- `author:` is immutable history and explicitly not ownership
  (`gather/scripts/owners.sh` header). Reading it for a report line is fine;
  reading it for a claim decision would re-create the defect P2 removed.
- The finish line's audience is a Slack thread, so keep the added line short and
  do not introduce a mention token — a `<@U…>` on a routine's own post has
  re-triggered the Slack app before (`workaholic:notify`).
