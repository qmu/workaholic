---
created_at: 2026-08-30T02:21:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Drill the condition age offline

## Overview

PROPOSED. `verify-condition-age`: walk the whole chain — log → reader → bound → question → report
— over a tick-log fixture spanning several days, with **no network**, no `gh` and no Slack post,
carrying a breaker row written against the **behaviour** rather than a return shape: the reader
wired at the current tick only, so every age reads 1.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — a new `verify-condition-age` `case` arm; `verify-all` derives what
  it runs from these arms plus the register, so no list is kept in two places.
- `docs/loop-drill-runbook.md` §9 — the drill register; a row `| `verify-condition-age` |
  `hermetic` | yes | `say-how-long-the-loop-has-been-stuck` |`. An unclassified drill is
  `skipped:unclassified` and the suite fails on it.
- `.github/workflows/loop-drills.yml` — runs the hermetic set, one matrix leg per drill, so the
  check run that goes red is named after the drill and `drill-health` can name it.

## Implementation Steps

1. Build a throwaway repository with `.workaholic/moderations/` day files spanning several days,
   whose `human-checkin-ask-<slug>` lines are written by `ask-question.sh --record-ask` rather than
   hand-authored, so the drill exercises the real writer and cannot pass against a shape the writer
   never produces.
2. Assert the reader: a key first named days ago reads that tick and a `ticks` above 1; a key the
   ledger never carried reads `first_seen: null`, `ticks: 0` and **no** `readable` field; an
   unreadable log reads `readable: false` with a named reason and **null** counts.
3. Assert the bound: with the log longer than `WORKAHOLIC_CONDITION_AGE_MAX_DAYS`, `truncated:
   true` and `first_seen_is_floor: true` with real counts and no `readable: false`; with the log
   shorter, the reading is byte-identical to the unbounded one.
4. Assert the questions: each of the four steps attaches an `age`, each step's **summary is
   byte-identical** to its pre-change form for the same inputs, and every candidate **key** is
   byte-identical — so no question is re-asked by the changed wording. Run two ticks and assert the
   second asks nothing new.
5. Assert the reading **gates nothing**: the survey is byte-identical with an old blocker and a
   fresh one, and no script in the driving or proposing chain reaches the reader.
6. Register the drill and give it a `bearing: "breaker"` row — a drill with none is **`unproved`**
   and counted outside the passing total. Write the breaker against the behaviour: wire the reader
   to read only the current tick, and the drill must show every age collapsing to 1, not merely a
   changed return shape.
7. Confirm it needs no credential: `sh scripts/e2e/loop-drill.sh verify-condition-age` passes with
   no network, and `verify-all` picks it up with no list edited anywhere else.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The drill passes offline with no network, no `gh` and no Slack post.
- Its breaker row is proved to fail with the reader wired at the current tick only.
- The register carries its row, and `verify-all` runs it without a second list.
- `node scripts/test-workflow-scripts.mjs`'s unclassified-drill row passes.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-condition-age`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill passes; its breaker is observed to fail; `verify-all` and the suite pass; the CI
  matrix leg is green.

## Considerations

- Writing the fixture's ledger lines by hand would be the quick path and would prove nothing about
  the writer: `verify-ci-retirement` passed on every push while production was silent precisely
  because its fixture configured for itself the one term production lacked. Drive the fixture
  through `ask-question.sh --record-ask`.
- The step summaries are the fragile part: a summary that gains an age marks its step changed every
  tick and reinstates the hourly restatement two roots were retired for, so the byte-identity
  assertions in step 4 are the drill's most load-bearing rows.

## Final Report

Development completed as planned. `verify-condition-age` walks log → reader → bound → question
→ report over a throwaway fixture whose ledger lines are written by `ask-question.sh
--record-ask`, with no network, no `gh` and no Slack post: 13 load-bearing rows and one breaker,
registered in `docs/loop-drill-runbook.md` §9 as `hermetic` with a prose section at §5r.
`verify-all --list --kind hermetic` picks it up with no second list edited anywhere.

### Discovered Insights

- **Insight**: A `grep`-based "this script never reaches X" row passes silently when the path
  is wrong, so it has to check the file exists first.
  **Context**: The gate row was written against
  `plugins/workaholic/skills/strategy/scripts/survey-strategies.sh` — the script actually lives
  under `propose/scripts/` — and `grep` over a missing file matches nothing, so the row reported
  *gates nothing* about a script nobody had read. The same typo threw in the suite (`ENOENT`
  from `readFileSync`), which is how it was caught; the drill needed an explicit `[ ! -f ]` arm
  to be as honest.
- **Insight**: Only one of the four age consumers can be exercised end to end in a hermetic
  drill, and the boundary is worth stating rather than papering over.
  **Context**: `undrivable-units` walks `.workaholic/` through the ownership readers and needs
  nothing else. The other three read the claim oracle, which fetches; standing up a bare origin
  per step would drill the oracle rather than the age. Those keep a composition assertion here
  and the acting-call-site bans in `testProofJudgementSplit`.
