---
created_at: 2026-08-26T02:23:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826022347-judge-a-whole-mission-not-one-change.md
mission: turn-the-loop-at-mission-granularity
merge_policy:
verification_handoff: 
---

# Emit the mission the ask already planned

## Overview

Once `/propose` proposes a mission with its ordered ticket set, `/specificate` must stop
re-deriving the decomposition. Its form precedence already sends a decomposable ask to the
mission form; what it lacks is the rule that an ask which **already names** the mission's
title, experience and ticket order is emitted as that plan rather than re-judged into a
different one. Two sessions deciding the same decomposition is how the ask's plan and the
emitted mission drift apart, and the operator would then be reading a roadmap that does not
match the proposal they approved.

## Policies

- `workaholic:planning` / `policies/scoping.md` — the plan is decided once
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md` — *The form follows the work's shape*, and
  the *strategy is not a mission factory* rule that governs extend-versus-mint
- `plugins/workaholic/skills/specificate/reference/workflow.md` — steps 7, 8 and 9
- `plugins/workaholic/skills/specificate/scripts/scaffold-draft.sh` — the mission scaffold
- `plugins/workaholic/skills/specificate/scripts/scaffold-proposed-ticket.sh` — the ticket scaffold
- `plugins/workaholic/skills/mission/scripts/check-floor.sh` — the floor the emitted set meets

## Implementation Steps

1. State the rule in `specificate/SKILL.md`: an ask that names a mission — title, experience,
   ordered ticket set — is emitted as **that** mission, in that order. The run does not
   re-decompose it.
2. Keep every existing gate over the top of it, and say so: the two-ticket floor still runs;
   the acceptance ceiling (≤3 items, ~60 lines / 2 KB) still bounds the mission; the
   `verification_handoff` and `## Open Decisions` rules are untouched.
3. Preserve the run's right to **refuse**: an ask whose named plan breaches a floor is
   reported by name and demoted (loose ticket or record-only) rather than trimmed silently.
   The run reports which it did, as `precedence:<form>` already requires.
4. Reconcile with *A strategy is not a mission factory*: a mission-shaped ask against a
   strategy whose mission is still active lands as **tickets into that mission**, not a new
   mission beside it — unless that mission's `## Experience` cannot honestly cover the work.
   The run reports which of the two it judged. This is the seam where the coarser proposal
   and the anti-proliferation rule meet, so state it rather than leaving it to be inferred.
5. Update `reference/workflow.md` steps 7–9 to match, keeping the scaffold invocations
   unchanged where they already do the right thing.
6. Regenerate `outputs/` and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ask naming a mission's title, experience and ticket order is emitted as that mission,
  in that order
- A named plan that breaches the ticket floor or the mission ceiling is reported by name and
  demoted, never trimmed silently
- The extend-versus-mint judgment against an active mission is stated and reported
- The `verification_handoff` and `## Open Decisions` rules are unchanged

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-specificate`
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The drill passes and the SKILL, the reference and `CLAUDE.md` state one contract

## Considerations

- The receiving run keeps its judgment; what it gives up is **re-planning what was already
  planned**. An ask it judges unbuildable is still record-only, reported with its reason.
- Watch the mission ceiling: a 7–8 ticket plan compressed into ≤3 acceptance items is the
  binding constraint, and it is the reason the acceptance sketch is a sketch.

## Final Report

Development completed as planned. `specificate/SKILL.md` now states the rule beside the four
forms — an ask naming a mission's title, experience and ordered ticket set is emitted as **that**
plan, in that order, and the run does not re-decompose it — and `reference/workflow.md` carries it
at steps 7, 8 and 9. Every gate stays over the top of the named plan and is listed rather than
implied (the two-ticket floor, the mission ceiling, the carry floor, `verification_handoff`,
`## Open Decisions`); a named plan that breaches one is **demoted and reported by name**, never
trimmed to fit. Step 9 opens with the extend-or-mint judgment reconciling this with *A strategy is
not a mission factory*: a mission-shaped ask against a strategy whose active mission still exists
lands as tickets **into** that mission — read through `attributed-work.sh`'s new
`waiting_mission_slugs`, the one attribution reader — and the run reports which of the two it
judged.

`sh scripts/e2e/loop-drill.sh verify-specificate` is in the Quality Gate but needs a seeded issue
number and a live loop (`verify-specificate <issue>`); it is not runnable from an unattended
container without opening a GitHub issue, so it was **not run**. The change is prose in two
documents with no script behind it, and the hermetic suite, the build and the verifier all pass.

### Discovered Insights

- **Insight**: The extend-or-mint judgment belongs at the **top** of step 9, not at step 8.
  **Context**: Step 8 drafts the mission; if the judgment lived there, an *extend* outcome would
  already have scaffolded one. Putting it first makes "skip step 8 entirely" the natural reading.
- **Insight**: The rule this ticket adds is a *subtraction* from the run's job, not an addition.
  **Context**: Row 1 of the precedence already sent a decomposable ask to the mission form. What
  was missing was only the instruction not to re-derive a plan the ask had already made — which is
  why the change is prose and no scaffold invocation moved.
