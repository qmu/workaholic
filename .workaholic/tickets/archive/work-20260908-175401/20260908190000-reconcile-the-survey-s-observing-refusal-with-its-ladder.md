---
created_at: 2026-09-08T19:00:00+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-quiescent-blockers-into-mature-decisions-and-resume-work
feedback: 20260908123159-make-quiescent-loops-surface-decision-ready-blockers-and-reopen-after-answers.md
merge_policy:
verification_handoff:
---

# Reconcile the survey's observing refusal with its ladder

## Overview

`propose/scripts/survey-strategies.sh` documents an `observing` refusal — *the operator DECLARED
this direction 観察中 — settled, the loop reactive only*, with three paragraphs on where it sits
in the ladder and why — and its refusal expression does not emit that word. `commands/propose.md`
states the current rule instead (`観察中` permits observation work and guides the hypothesis), so
the header describes a gate that was retired and the sort comment still asserts it
(*観察中 never reaches this sort at all — it is refused `observing` one step above*).

Observed while driving `20260908123303-judge-whether-a-human-decision-is-mature-enough-to-block`:
the first draft of the maturity ladder keyed a rung on `reason == "observing"` and was dead code.
The reader now tests the declared stage off the row instead, which is correct either way — this
ticket is about the documentation that misled it, not about that reader.

Decide which is true and make one statement of it: either the ladder should refuse `observing`
and the code is missing a rung, or the refusal is retired and three blocks of prose describe a
gate that does not exist. This ticket does **not** presume the answer; it requires that the tree
stop saying both.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the header's gate table
  (the `observing` entry), the refusal ladder, and the sort comment that names the refusal.
- `plugins/workaholic/commands/propose.md` — states the current rule (`観察中` permits
  observation work).
- `plugins/workaholic/skills/propose/SKILL.md` — the stage's role in the hypothesis.
- `plugins/workaholic/skills/moderate/scripts/decision-maturity.sh` — a reader that tests the
  declared stage rather than the refusal word, and says why in its own header.

## Implementation Steps

1. Establish which rule is current — whether a `観察中` direction may be proposed against — from
   `commands/propose.md`, `SKILL.md` and the git history of the ladder.
2. Make the tree state it once: either restore the rung, or delete the retired gate's prose from
   the header table and correct the sort comment.
3. Leave `decision-maturity.sh` reading the declared stage either way, and say in its header why
   it does not depend on another script's refusal word.
4. Pin the outcome in `scripts/test-workflow-scripts.mjs` so the ladder and its documentation
   cannot drift apart again.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The refusal ladder and every sentence describing it agree on whether `observing` is emitted.
- No consumer keys on a refusal word the ladder does not produce.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, with a row asserting the ladder's emitted refusal
  words match the set its own header documents.

**Gate** — what must pass before approval:

- The origination behaviour of a `観察中` direction is unchanged unless the investigation
  concludes the code was the defect, and the change says which conclusion it took.

## Considerations

The two readings have different blast radii: restoring the rung silences origination for every
`観察中` direction, while deleting the prose changes no behaviour at all. Prefer the one the
evidence supports, and state the other explicitly as the fork not taken.

## Final Report

Development completed as planned.

**The conclusion taken: the `observing` refusal is retired, and the prose was the defect.**
Four independent readings agree and none supports the other fork:

- `plugins/workaholic/commands/propose.md` — "`観察中` permits observation work".
- `plugins/workaholic/skills/propose/SKILL.md`, *観察中 permits observation work* — records the
  retirement explicitly, dated to the week the declared stage shipped (2026-08-29).
- `survey-strategies.sh`'s own `refusal:` expression emits eight words and none of them is
  `observing`; its sort comment already said 観察中 participates in the sort.
- `scripts/test-workflow-scripts.mjs`, `propose: 観察中 remains eligible context`, asserts such
  a direction stays in `selected[]`, and `scripts/e2e/drills/verify-stage.sh` carries a
  **breaker** that restores the retired gate and proves the assertion then fails.

**The fork not taken, stated rather than implied**: restoring the rung would silence
origination for every `観察中` direction — a behaviour change nothing in the evidence asks for,
and the wider blast radius of the two. The header now says so in place of describing the gate.

What changed:

- `propose/scripts/survey-strategies.sh` — the stage note is out of the gate table (it was a
  bare sentence sitting between two rungs, reading as one). The table is now the **complete**
  documented set, delimited by two sentinel lines, with `attribution_unreadable` and
  `wip_limit` added as the rows the ladder always emitted and the header never listed. One
  paragraph states the retirement and the fork not taken.
- `moderate/scripts/decision-maturity.sh` — its **header** now says why `retire`'s third
  premise reads the declared stage off the row rather than another script's refusal word; the
  reasoning existed only as a comment inside the jq program.
- `specificate/SKILL.md` and `strategy/SKILL.md` — the two surfaces still asserting `/propose`
  is refused `observing`. These were the tree saying both things at once.
- `scripts/test-workflow-scripts.mjs` — one new row, `propose: the refusal ladder agrees with
  its documented words`.

No behaviour moved: the ladder, the sort, every gate and `decision-maturity.sh`'s verdicts are
byte-identical in effect.

### Discovered Insights

- **Insight**: A sentinel-delimited comment block is only extractable if the sentinel is
  spelled exactly once. The first draft of this pin put the closing sentinel's name inside the
  paragraph that explained it, so the extractor's `findIndex` landed on the explanation and
  read an empty documented set — a passing-looking extraction of nothing, which is worse than
  a parse error.
  **Context**: Any future machine-read block in this tree needs the same discipline: refer to
  the sentinels indirectly ("the two sentinel lines below") and never quote them in prose.

- **Insight**: `decision-maturity.sh` is the only script that compares the strategy survey's
  `reason` against string literals, so "no consumer keys on a refusal word the ladder does not
  produce" is checkable as a one-file token walk rather than a tree-wide grep.
  **Context**: That is what makes the pin a behaviour/token assertion rather than prose
  matching, and it is the check that would have caught this ticket's original defect — a rung
  keyed on `observing` after the ladder stopped emitting it.

- **Insight**: This branch's own mission work had already reached `main` through PR #1131 while
  its own pull request (#1124) was closed unmerged, so catching the 223-hour-stale branch up
  left a tree differing from `origin/main` by exactly one appended line in
  `.workaholic/stories/index.md`.
  **Context**: A `content` mergeability class on such a branch is not a real disagreement — the
  three conflicted paths were the base's own evolved descendants of the branch's copies, and
  taking the base's side reverted nothing. Worth checking before treating a long-parked claim's
  conflict as substantive.
