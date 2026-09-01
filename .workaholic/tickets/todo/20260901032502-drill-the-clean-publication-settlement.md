---
created_at: 2026-09-01T03:25:02+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-a-stranded-publication-that-needs-nothing-but-a-merge
merge_policy:
verification_handoff: 
---

# Drill the clean publication settlement

## Overview

`verify-stranded-publication` walks reader → act → delivery → re-run → question for a
publication with a **collision**: its fixture is a real conflict on a real generated index, and
every row it asserts is about `content` being refused or `mechanical` being settled. The class
this mission gives an owner — a publication with no collision at all — appears in no row, so
after the first two tickets land, a regression that puts `clean` back to
`not_mechanical:clean` would pass the whole drill set.

That is the exact failure this mission exists to remove, one level up: a class nothing owns.
This ticket gives the new behaviour a row that fails when it stops holding, and a breaker
written against the behaviour rather than against a return shape — the register's own
requirement, and the difference between a proved drill and an `unproved` one.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the `verify-stranded-publication` arm: its fixture (a bare local
  origin plus a stubbed GitHub transport on `PATH`, no credential and no network), its rows, and
  its breaker.
- `docs/loop-drill-runbook.md` §5t — the drill's prose and its failure-reason→file blame table,
  which gains a row.
- `docs/loop-drill-runbook.md` §9 — the drill register, read by `drive/scripts/drill-register.sh`;
  check whether the `bearing: "breaker"` row still describes what the breaker breaks.
- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — read only; the
  behaviour under test.

## Implementation Steps

1. **Reproduce the hole before filling it.** Run
   `sh scripts/e2e/loop-drill.sh verify-stranded-publication` and record it green. Then revert
   the class gate from the mission's first ticket by hand in a scratch copy — or simply confirm
   by reading the arm — that no row asserts anything about a publication with no collision. A
   drill that stays green while the mission's behaviour is gone is the gap.
2. **Extend the fixture with a clean publication**: a second `work-*` branch with no claim
   commit whose diff against the base has no collision — the same fixture machinery, one more
   branch, still no credential and no network.
3. **Add the row `stranded_clean_is_settled`**: the act over that publication reports
   `outcome: settled`, takes no catch-up (`merged`, `regenerated` and `pushed` all `false`), and
   its delivery is reported in the merge vocabulary. Assert the behaviour, not the JSON shape.
4. **Add the row `stranded_clean_rerun_is_a_noop`** — a second run over the delivered
   publication refuses by name and moves no ref, the same property the existing `mechanical`
   re-run row asserts, so idempotency is proved for both classes rather than one.
5. **Write the breaker against the behaviour.** The existing breaker strips the generated-region
   proof out of `conflict-class.sh` and asserts the settleable collision then reads `content`.
   The analogue here narrows the act's class gate back to `mechanical` alone and asserts the
   clean publication is then refused `not_mechanical:clean` and delivered by nothing — the
   measured incident, reproduced on demand. Keep the ordering constraint the existing breaker
   documents: run it before anything is settled.
6. **Add the blame rows to §5t's table**, naming which file a failure of each new row points at,
   in the table's existing voice.
7. **Check the register in §9** — the drill must stay classified, and its `bearing: "breaker"`
   row must still describe what the breaker actually breaks after step 5.
8. **Run the classified set**: `sh scripts/e2e/loop-drill.sh verify-all`, and confirm the drill
   still runs hermetically (CI runs its hermetic part on every push, one matrix leg per drill).

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `verify-stranded-publication` asserts that a `clean` publication is settled and delivered, and
  that a re-run over it moves no ref.
- Its breaker, run against the new behaviour, makes the drill fail — a drill that cannot fail
  proves nothing.
- The drill stays hermetic: no credential, no network, no seed, no issue number.
- §5t's blame table names a file for every new row, and §9 still classifies the drill.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-stranded-publication`
- `sh scripts/e2e/loop-drill.sh verify-all` — one verdict per drill, non-zero only on a real
  failure
- The breaker, run by hand: the drill goes red, and green again once reverted.
- `node scripts/test-workflow-scripts.mjs` — an unclassified drill fails it.

**Gate** — what must pass before approval:

- No drill is skipped, disabled or quarantined to get green.
- The drill remains `pass`/`fail`/`skipped:<reason>` in its own vocabulary and introduces no
  claim verdict word.

## Considerations

- **Order matters within the mission.** This drill asserts the behaviour the first two tickets
  build, so it is driven last; written first it would simply be red.
- **The existing breaker's ordering constraint applies to the new one too** — §5t records that
  the breaker runs before anything is settled, because afterwards the branch contains the base
  and there is nothing left to misclassify. The clean-publication breaker has the same shape:
  once the publication is delivered there is no open pull request to refuse.
- **What this drill will still not prove** is that a consuming repository's own stranded
  publications are gone; it exercises this checkout's scripts only. §5t already says so and the
  sentence should keep covering both classes.
