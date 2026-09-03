---
created_at: 2026-09-03T09:02:50+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-red-base-impossible-for-the-loop-to-miss
merge_policy:
verification_handoff: 
---

# Name an unverified suite wherever the base colour is reported

## Overview

A reading nothing reports changes nothing. The base's colour is stated in two places — the
`base-health` step of the hourly tick and the top of `/implement`'s run report — and both were
written against a two-or-three-valued answer. This ticket carries `unverified: <suite>` into both,
under the rule those surfaces already hold: a degraded read is reported as degraded and never as
green.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-base-health.sh` — the tick's own reporting of the colour
- `plugins/workaholic/skills/moderate/reference/workflow.md` — that step's spec and its question
- `plugins/workaholic/commands/implement.md` — the ceiling stating the run report's base-health line
- `plugins/workaholic/skills/drive/SKILL.md` — the run report contract
- `CLAUDE.md` — the two paragraphs stating what the base-health reading says

## Implementation Steps

1. **Reproduce and localize first.** Read both surfaces and quote what each says today for a
   `green`, a `red` and an `unanswerable` reading; name the sentence each would have to gain.
2. Report an unverified suite by name on both, beside the colour rather than instead of it — a tip
   can carry a green verdict and an unverified suite at once, and collapsing them loses the fact.
3. Keep the token rules exactly as they are: this is evidence, and whether it moves `/implement`'s
   terminal token is decided here explicitly and stated, not left implicit.
4. Update `CLAUDE.md` and the step's spec in the same change.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Both surfaces name every unverified suite beside the colour, and neither renders one as green
- The effect on `/implement`'s terminal token is stated explicitly wherever the token rules are stated
- The documentation this change alters is updated in the same commit

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The suite passes and no surface reports a colour without its unverified set

## Considerations

- Depends on the sibling ticket: without `unverified` in the reader there is nothing to report.
- Whether an unverified suite should forbid `ok` is a judgement this ticket must make out loud
  rather than inherit; the ask does not decide it.

## Final Report

**Outcome**: implemented.

**Reproduced and localized first.** The colour is stated in two places. `step-base-health.sh`
emitted `the base is green at <sha>` (or `…, N commit(s) behind the tip`), `the base's checks could
not be read (<reason>)`, or `the base is red at <sha>; … failing: <names>`. `/implement`'s ceiling
and `workaholic:drive` §7 state the run-report line in the same three-valued shape. Neither had a
sentence for *a suite that left no verdict*.

**Both now name it beside the colour, never instead of it.** The step reads the tip once through
`read-base-checks.sh --declared` and appends one clause to the `summary` on **all three** paths —
green, `unanswerable` and red alike — because a tip can carry a green verdict and an unverified
suite at once. A degraded declared-read renders *which declared suites ran on the tip could not be
read (<reason>)* rather than silence, under the rule that surface already holds: a degraded read is
reported as degraded and never as green.

**Step 3's judgement, made explicitly rather than inherited.** An unverified suite **moves no
token**. The reasoning is the base colour's own, already written in `workaholic:drive` §7: it is a
fact about the *repository*, not about the unit this run drove, and a run that drove its unit
cleanly reports `ok` while naming it. Withholding `ok` would put the token out of reach for as long
as a path filter keeps a workflow from running, which is indefinitely — and the person who must act
is reached by the tick's `🔴 Blocked` report, not by this token. It is stated in that section, in
the `/implement` ceiling and in `CLAUDE.md`.

**Documentation updated in the same change**: `CLAUDE.md`'s base-health bullet and `/moderate` step
table, `commands/implement.md`, `workaholic:drive` §7, and the step's own spec in
`moderate/reference/workflow.md`.

**Verified**: the step's live output on this tip now reads *the base is green at 5c11616b…;
unverified on the tip (no run there): Docs Deploy*.
