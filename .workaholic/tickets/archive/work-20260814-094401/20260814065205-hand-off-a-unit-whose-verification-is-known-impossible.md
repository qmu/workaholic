---
created_at: 2026-08-14T06:52:05+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260814065157-introduce-handoff-pr-status-for-credential-blocked-verification.md]
merge_policy:
claim: work-20260814-094401
---

# Hand off a unit whose verification is known impossible

## Overview

PROPOSED. Most of what the ask names already exists: `handoff` is one of the unit
outcomes (`workaholic:drive`, *A unit may also end in `handoff`*), it writes the
non-droppable `## Handoff` PR section, it posts `🟡 Handoff` as the unit's one finish
line, and it forces the run's terminal token to `pending`. What does **not** exist is
the **entry condition** the ask describes: a unit whose real-world verification is
known impossible *in advance* — the credentials are not in the routine's environment —
must end in handoff rather than being merged and announced `🟢 Implemented`. Today
that unit drains its queue, so nothing stops it from shipping with its verification
silently unrun.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the three-condition definition of `handoff` and the token table (`handoff` → `pending`); the entry condition is added or deliberately kept out here.
- `plugins/workaholic/skills/drive/reference/routing.md` — *Handoff* (what the unit writes and pushes) and the demote-to-PR path a failed gate already takes.
- `plugins/workaholic/skills/ship/SKILL.md` §1-4 — the existing precedent: a target declaring **no confirmation method** already halts the ship, which is the same shape as "verification cannot run here".
- `plugins/workaholic/skills/report/SKILL.md` — the `## Handoff` section's author.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `🟡 Handoff` shape; reuse it, do not invent a new one.
- `CLAUDE.md` (`/implement` row, Merge policy bullet) — the statement that a `size`/`leak` block or a missing confirmation method demotes a unit to the PR path.

## Implementation Steps

1. Reproduce first: take a ticket whose Quality Gate names a verification the routine environment cannot run (a missing credential), drive it under `/implement`, and record what actually happens today — whether it merges, what it posts, and what the run report says. The ask asserts it is marked `🟢 Implemented`; confirm that before changing routing.
2. Decide where the signal lives. It has to be readable **before** the unit routes: the ticket's Quality Gate is the natural carrier, and the FB issue that requested the work is where the ask says it is known. Prefer an explicit field over inference — a routing decision made by guessing at prose is the failure mode to avoid.
3. Resolve the Open Decision below, then implement the routing: the unit does not merge, its pull request stays open carrying the handoff marker, and the finish line is `🟡 Handoff` with the person mentioned.
4. Make the reason visible in the pull request itself — which verification could not run and what a human must do to run it. A handoff whose PR does not say what is missing hands off nothing.
5. Keep the token honest: a run with such a unit ends `pending`, never `ok`.
6. Update `CLAUDE.md` and the drive runbook in the same commit; regenerate `outputs/` and run the local verification set.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A unit declared unverifiable in this environment is not merged and does not post `🟢 Implemented`.
- Its pull request stays open, carries the handoff marker, and names the verification that could not run.
- The run's terminal token is `pending`, and the run report names the unit's outcome and notification surface.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-implement` extended with an unverifiable-unit fixture
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && git diff --exit-code outputs/`

**Gate** — what must pass before approval:

- The commands above pass, and step 1's reproduction is recorded in the Final Report — the routing change is only justified by what the current behaviour actually is.

## Considerations

- `handoff` must never become a soft landing for work a run did not want to attempt — the drive skill says so explicitly. Whatever signal is introduced must be **declared in advance on the artifact**, never decided by the running session mid-drive.
- The daily aggregation of Handoff-state pull requests is named in the ask as a *future consideration*, and is deliberately **not** proposed here. It also depends on the repository-routine scope proposed separately for issue #451; if both land, that is where it belongs.
- `/ship`'s existing halt on a target with no confirmation method is the closest precedent in the tree. Reuse its shape rather than inventing a parallel one.
- "Marked" may mean a GitHub label rather than the PR body section. A label is a new surface for this repository — decide it deliberately, and note that the loop reaches GitHub over REST only.

## Open Decisions

- **Widen `handoff`, or add a distinct demotion that borrows its shape?** `handoff` is currently defined by three conditions holding together, the first being that the unit's queue is **not drained**. A unit whose work is complete but whose verification cannot run here has a **drained** queue, so it is not half-driven in the current sense. **(a)** Widen the definition to "not drained **or** its verification cannot be run in this environment", keeping one outcome and one 🟡 shape; **(b)** keep the three-condition `handoff` intact and route this case through the existing demote-to-PR path with a handoff marker, so "half-driven" keeps its meaning and the new case gets its own name. This session cannot recommend either — (a) is simpler and matches the ask's wording, (b) preserves a distinction the drive skill wrote down deliberately. Resolve it explicitly and record the resolution in the Final Report.

## Final Report

Development completed as planned.

### Step 1 — what happens today, measured over the code that decides

The reproduction was run against the routing path rather than by driving a live
credential-blocked unit, because the path is short enough to be read exhaustively and
that reading is what the change had to be justified by:

- `grep -rl "Quality Gate" plugins/workaholic/skills/drive/scripts/` → **no matches**.
  Nothing in the executor reads a ticket's Quality Gate, so a verification named there
  cannot influence a route.
- `effective-policy.sh` (the whole pre-change route input) calls `fm_field` exactly once,
  on `merge_policy`. It is the only frontmatter field the routing path reads.

So a unit whose gate names a verification the environment cannot run drained its queue
like any other, took the `review` route, merged as soon as `/report` opened its PR and the
scan passed, and posted `🟢 Implemented`. The ask's assertion is confirmed, and the defect
is located precisely: **not the router, but the absence of an input** — which is why the
fix is a declared field and not a smarter reading of prose.

### Open Decision — resolved: (a), widen `handoff`

`handoff` now has **two entry paths** (half-driven, or declared unverifiable) rather than
three conditions. Reasoning:

- Every consequence the case needs is already exactly what `handoff` produces — PR open,
  non-droppable `## Handoff`, `🟡` finish line, `pending` token. An outcome is defined by
  its consequences, not by how it was reached, so (b) would have been two names for one
  state, and the daily Handoff-state aggregation the ask foresees would have had to query
  both.
- The "queue not drained" condition existed to stop `handoff` becoming a soft landing for
  work a run did not want to attempt. That guard is not weakened but **strengthened**: the
  new path requires a declaration written on the artifact *before* the drive, so no run can
  reach it by giving up. A condition a run could satisfy by its own conduct is replaced by
  one it cannot write at all.
- Cost accepted and written down: "half-driven" is no longer a synonym for `handoff`, so
  `drive/SKILL.md` §7 states two entry paths explicitly.

### Discovered Insights

- **Insight**: The declaration is safe for `/propose` to write even though `merge_policy`
  deliberately is not.
  **Context**: The two fields look like the same kind of blank and are not. `merge_policy`
  grants a permission the unattended proposer does not hold; `verification_handoff` records
  a fact about the environment that the ask already stated, and its effect is to *withhold*
  a merge rather than allow one. The direction of the risk is what decides who may write a
  field — a rule worth reusing the next time a proposal-time field is proposed.
- **Insight**: A mission-shaped credential-blocked ask needs no mission-level writer.
  **Context**: `verification-handoff.sh` reads missions too, but any member ticket declaring
  it carries the whole unit (the unit is one merge), and a proposed mission's tickets all
  come from `scaffold-proposed-ticket.sh`. One writer covers both shapes, which is why no
  new argument was added to `mission/scripts/create.sh`.
- **Insight**: The drill's new fixture is selected by reading the archived ticket, never by
  a flag.
  **Context**: `verify-implement` inverts its last two rows when the drill ticket carries
  the declaration, so the drill and the run route on the same file and cannot disagree about
  which fixture was seeded — the same "nothing is carried between stages" rule the propose
  stage already follows.
