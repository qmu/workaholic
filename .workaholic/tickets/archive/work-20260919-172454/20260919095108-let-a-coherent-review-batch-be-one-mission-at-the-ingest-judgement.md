---
created_at: 2026-09-19T09:51:08+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-one-coherent-feedback-batch-one-mission-one-pull-request-one-report
merge_policy:
verification_handoff:
---

# Let a coherent review batch be one mission at the ingest judgement

## Overview

Operator's ask: **issue #1110**, item 2 — *when two or more related feedback tickets form a single
user-visible correction pass, `/specificate` should prefer one mission unless there is concrete
release, dependency, ownership or risk evidence that requires separation.* Measured: one
continuation thread published as nine loose tickets on one proposal pull request.

**The rule that produced that shape is recent, deliberate and measured, and this ticket must
reconcile with it rather than overwrite it.** `workaholic:specificate`, *The form follows the
work's shape*, row 1 carries **two** terms since 2026-09-03: the ask must decompose into two or
more units **and** there must be a mid-term plan to hold. Its own measurement is on the record —
*eight asks arrived from the channel, seven became missions and forty-eight tickets inside
twenty-one minutes* — and its explicit fallback is that *an ask that decomposes but carries no such
plan takes the next row it fits*, which for nine same-surface corrections is loose tickets. The
loop did what it was told.

**So the two rules are not in conflict about the same question, and saying which is which is this
ticket's real content.** The 2026-09-03 rule answers *does this ask deserve a mid-term container*
and exists to stop mission proliferation at ingest volume. #1110 answers *is this batch one
person's single review pass* and exists to stop fragmentation of one coherent correction. A batch
sharing **one review surface, one feedback thread and one coherent acceptance walk** is a
container by the developer's own definition of the review unit — which `rules/workaholic.md`,
*What a Mission Must Be Able to Hold*, rule 2 already makes a stated judgement rather than a
count. The repair is to name that case in the judgement, not to relax rule 1's floor and not to
delete the mid-term term.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` for any script touched
- `workaholic:implementation` / `policies/observability.md` — the judgement is reported by name on
  both surfaces so a reader can disagree with it
- `workaholic:implementation` / `policies/test.md` — what the suite can hold here is the wording
  and the reported vocabulary, not the judgement

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md` (*The form follows the work's shape*, row 1 and
  the two bullets under it) — the home of the mid-term-plan term and of `precedence:<form>` /
  `mid_term_plan:<yes|no>`. The new case is named here.
- `plugins/workaholic/skills/specificate/reference/workflow.md` (step 7) — the ordered precedence
  the run executes; the same wording must appear here, byte-identical.
- `plugins/workaholic/rules/workaholic.md` (*What a Mission Must Be Able to Hold*) — the rule both
  sides cite. Decide deliberately whether rule 2 needs a clause, and if so write it **there** and
  cite it from both skills, never restate it.
- `plugins/workaholic/skills/specificate/SKILL.md` (*A strategy is not a mission factory*) — the
  extend-before-mint rule; a batch arriving as several issues must extend one mission rather than
  mint several, and the interaction is stated here.
- `plugins/workaholic/skills/mission/scripts/check-floor.sh` and `size.sh` — the floor and the
  ceiling, both untouched by this ticket.
- `scripts/test-workflow-scripts.mjs` — pins the reported vocabulary and byte-identical pairs.

## Implementation Steps

1. **Read both rules in full before writing a word** — `rules/workaholic.md`'s *What a Mission Must
   Be Able to Hold* and `specificate/SKILL.md`'s row 1, including the measurements each cites. The
   whole of each page, not the paragraph: this repository has a recorded failure from a partial
   read of one table.
2. **Name the case, in the one place the rule lives.** A batch whose items share **one review
   surface, one feedback thread and one coherent acceptance walk** is a mid-term container: the
   ordering and allocation it wants is the person's single review pass. Write it as a clause of
   rule 2 in `rules/workaholic.md` and **cite** it from `specificate/SKILL.md` and
   `reference/workflow.md` rather than restating it.
3. **Keep the separation evidence explicit** (the ask's own wording): concrete **release,
   dependency, ownership or risk** evidence splits the batch. Absent such evidence, one mission.
   The evidence is named in the report when it is used.
4. **Report the judgement by name on both surfaces.** Beside the existing `precedence:<form>` and
   `mid_term_plan:<yes|no>`, the run says when the batch term decided — the word must be its own,
   so a mission held by a person's review unit and one held by an ordinary mid-term plan are not
   reported alike.
5. **Traceability is preserved, and that is a floor, not an aspiration** (the ask's item 3): every
   ticket in the batch keeps its own `feedback:` ref to the item it answers, so the
   feedback-to-ticket link survives the grouping. `check-carry-floor.sh` already refuses a lost
   resolved ref; confirm it covers a mission whose members answer *different* records, and say what
   it does in the story.
6. **Change no floor and no ceiling.** The two-ticket floor and the mission size ceiling refuse
   exactly as before; a batch that breaches the ceiling is demoted and reported by name, which is
   the existing rule.
7. **Suite rows**: the new word appears in the reported vocabulary; the wording is byte-identical
   across `SKILL.md` and `reference/workflow.md`; and the mid-term-plan sentence is still present
   in both, because this ticket adds a case and removes none.
8. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The new case is written in `rules/workaholic.md` once and cited, never restated, in both
  `/specificate` surfaces.
- The 2026-09-03 mid-term-plan term is still present and still refuses an ask with no plan.
- The run reports which rule decided, with a word of its own for the batch case.
- `check-floor.sh` and `size.sh` are **byte-identical to `origin/main`**.
- Every member of a grouped batch still carries its own `feedback:` ref.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and the new rows fail when reverted.
- `git diff origin/main -- plugins/workaholic/skills/mission/scripts/check-floor.sh plugins/workaholic/skills/mission/scripts/size.sh` is empty.
- A fixture batch whose members answer different records passes `check-carry-floor.sh`.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The pull request states, in prose, why this does not reopen the 2026-09-03 decision, citing that
  decision's own measurement. A change that reads as a silent reversal does not pass.
- The suite is green and the bundle rebuild is diff-clean.

## Considerations

- **The honest risk is mission proliferation returning**, which is exactly what the 2026-09-03 rule
  measured. The bound that keeps it from returning is that the new case requires **all three**
  shared terms, not any one of them; a run that can only name one of them is in the old fallback.
- **This is a judgement and no script decides it**, which the ticket states rather than implies.
  What the suite holds is that the judgement is reported; whether a given batch was one review
  pass is arguable by the person who reviewed it, which is the point.
- **Do not extend this to the inbound volume case.** The ask is about one thread's corrections; an
  hour of unrelated channel asks is the case the mid-term-plan term exists for and is untouched.

## Final Report

Development completed as planned.

Rule 2 in `plugins/workaholic/rules/workaholic.md` gained one named case — a batch sharing
one review surface, one feedback thread and one coherent acceptance walk is a mid-term
container and takes row 1 — with all three terms required and concrete release, dependency,
ownership or risk evidence separating it. Both `/specificate` surfaces cite it in one
byte-identical wording; the 2026-09-03 mid-term-plan term is untouched and still refuses an
ask with no plan. The reported vocabulary gained `mission_held_by:review_batch` /
`mission_held_by:mid_term_plan` and `separated_by:<release|dependency|ownership|risk>`, so a
mission held by a person's review unit and one held by an ordinary mid-term plan cannot
report alike. `check-floor.sh` and `size.sh` are byte-identical to `origin/main`.

### Discovered Insights

- **Insight**: `check-carry-floor.sh` proves the refs on the artifacts the *caller names* and
  its own header states that a mission's tickets need not repeat the mission's refs.
  **Context**: the review-batch case is exactly the shape where members answer *different*
  records, so the per-member `feedback:` ref is carried by the scaffold call
  (`scaffold-proposed-ticket.sh` writes `feedback:` on a mission member when `--feedback` is
  passed) and is **not** gated by that floor. The rule now states this rather than implying
  the floor covers it — a traceability claim nobody checks is worse than one stated as
  carried.
- **Insight**: the two rules never conflicted about one question.
  **Context**: the 2026-09-03 term answers *does this ask deserve a mid-term container* and
  exists against ingest volume; issue #1110 answers *is this batch one person's single review
  pass* and exists against fragmentation of one correction. Naming the second as a case of
  rule 2 keeps both measurements standing; relaxing rule 1's floor would have reopened the
  proliferation the first was measured against.
