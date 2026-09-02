---
created_at: 2026-09-02T04:26:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Retire the surfaces that defer a conflict to a claim holder

## Overview

PROPOSED. The operator's third correction: the step that reports stuckness "was never asked
for and is not working; it must not be used". Once the tick resolves and merges, the steps
and the prose that hand a conflict to a claim holder are not merely redundant — they are
false, and they are what makes parked work read as progress.

This ticket removes them, and removes the sentences elsewhere in the tree that say a
conflict "belongs to" someone who never comes.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- The step the diagnosis ticket named as the composer of the "belongs to the claim holder"
  line — its script, its spec, its question key.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step table and the
  per-step specs.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step registry; a retired step
  leaves it, and the count stated in the prose moves with it.
- `plugins/workaholic/skills/moderate/SKILL.md` — *What the tick repairs, on what licenses
  it, and who does the rest*: the section that today routes a `content` conflict to a person.
- `CLAUDE.md` — the `/moderate` section's step table and bounds.
- `plugins/workaholic/skills/drive/reference/claims.md` — the refusal vocabularies whose
  consumers change.
- `scripts/test-workflow-scripts.mjs` — the suite that fails on a step id nothing emits and
  on a table row nothing produces.

## Implementation Steps

1. Remove the reporting-only step the diagnosis ticket named: its script, its row in the
   step registry, its spec, its question key, and its entries in the two step tables
   (`workaholic:moderate` and `CLAUDE.md`). Retire it — do not leave it disabled behind a
   flag, which is how a retired step comes back.
2. Rewrite *What the tick repairs, on what licenses it, and who does the rest* so the
   `content` conflict class is named as the tick's own work rather than a person's, and so
   the section's count of acting steps is correct.
3. Search the tree for every sentence that defers a conflict to a claim holder or a
   publication's author, and correct each: `moderate/reference/workflow.md`, `claims.md`,
   `drive/SKILL.md`, `CLAUDE.md`. A surviving sentence is what a later session will obey.
4. Where a question key disappears, check the answer machinery: a key nothing asks must
   also not be re-asked or counted as held. Assert that with the suite.
5. Run the suite's own consistency rows — a step id nothing emits, a table classifying a
   word nothing emits — and let them fail before the removal is complete, so the removal is
   proved rather than believed.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reporting-only step is gone from the registry, the specs and both step tables.
- No prose surface defers a conflict to a claim holder or a publication's author.
- No orphan question key remains in the ask, hold or re-ask machinery.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A tree search for the deferral wording returns nothing.

**Gate** — what must pass before approval:

- The suite's step-id and vocabulary consistency rows pass.
- `outputs/` regenerated; the `Outputs Freshness` check is clean.

## Considerations

- Removing a step removes a reading. Where the removed step was the only thing that named a
  real condition, the reading moves into the acting step's own report rather than
  disappearing — say which, in the change, so nothing is quietly lost.
- Sequenced last on purpose: retiring the report before the act exists would leave the
  condition invisible in the gap.

## Final Report

Development completed as planned. The operator's words about the step — *"was never asked for
and is not working; it must not be used"* — are the whole warrant, and it is **retired, not
disabled behind a flag**.

**Which step step 1 names, because the previous run read it differently and blocked on that
reading.** That run took the *reporting-only step* to be `step-stuck-prs.sh` and stopped: four
of its five readings (`review`, `checks`, `draft`, `behind`) are named by no other step, so
retiring it would lose signal — exactly what the ticket's Considerations forbid. But step 1's own
words are *"the step the diagnosis ticket named as the composer of the 'belongs to the claim
holder' line"*, and that is **`catchup-blocked`**: its question is the one that said a conflict
is the claim holder's. `stuck-prs` reports that a pull request is stuck; it never says a conflict
belongs to somebody, and it is **untouched here** — all five of its readings survive. On that
reading the Considerations' test is satisfied rather than blocked: `catchup-blocked`'s single
reading is named elsewhere already, by `merge-conflicts` and by the act's own report.

- **`catchup-blocked` is gone** (step 1): the script deleted, its row removed from `run.sh`'s
  `STEPS`, its spec §26 removed from `moderate/reference/workflow.md`, its `needs_ruling` row
  removed from the findings table, and its entries removed from both step tables
  (`workaholic:moderate` and `CLAUDE.md`, whose count moved to **thirty-two**). Its question key
  is emitted nowhere. **The section numbers were deliberately not renumbered** — a gap at §26 is
  the retirement's own record, and renumbering would break every `(§n)` cross-reference in the
  file.
- **The `content` class is named as the tick's own work** (step 2), in *What the tick repairs, on
  what licenses it, and who does the rest*. The acting-step count is unchanged (four): this
  retirement removes a **reporting** step, not an acting one.
- **`stranded-publications` stopped deferring too** (step 3). It is not a reporting-only step, so
  it survives — but its `content` candidate set drew a question addressed to the publication's
  author, which is the same deferral one artifact over, and the acceptance names both. The
  question is gone; the **count stays in the summary** and the event now names a repository fact
  (*the next `[Implement]` tick attempts each*) rather than *waiting on a person*. Its
  `stranded-publication-stale:<number>` question is untouched — that one is about a plan's age,
  not about a conflict.
- **Every deferring sentence was corrected** (step 3), across `moderate/reference/workflow.md`,
  `moderate/SKILL.md`, six sibling step scripts, `drive/SKILL.md`, `drive/reference/routing.md`,
  `drive/reference/claims.md`, four `drive/scripts/*.sh` headers and `CLAUDE.md`. Only sentences
  **recording the retirement** still name the step.
- **No orphan key remains** (step 4): a tree search for `catchup-blocked:` under `skills/`
  returns nothing, so nothing can ask, hold, re-ask or count it. The drill asserts that absence
  directly.
- **The removal is proved rather than believed** (step 5): the drill's own row was inverted from
  *the refused conflict reaches its claim holder* to **`catch_up_conflict_asks_nobody`**, and
  `verify-stranded-publication`'s from *reaches a person* to **`stranded_content_asks_nobody`* —
  each asserting the count survives and only the deferral is gone. Both drills pass; the suite
  passes.

**Where the reading went, so nothing is quietly lost** (the Considerations' requirement): the
condition the retired step named is *a hunk the merge itself could not settle*. It is now
reported **by the act that met it** — `/implement`'s run report carries `catch_up_refused:
content_conflict` and `settle_refused: content_conflict` with the colliding files — and
`merge-conflicts` still reports every conflicted pull request as a repository fact. What
disappeared is only the **question**, which is what the operator ruled against.

### Discovered Insights

- **Insight**: Retiring a step is mostly a **prose** change. The script, the registry row and the
  spec were three edits; the sentences in eleven other files that told a later session to defer
  to a claim holder were twenty. A surviving sentence is what the next session obeys, so the
  search for them is the work, not the deletion.
  **Context**: The ticket's step 3 is the expensive one and is easy to read as tidying.
- **Insight**: A drill row asserting *a person is told* inverts into *nobody is told* — but the
  honest inversion also asserts **the count survives**. Without that second clause the row would
  pass just as well if the step had stopped seeing content collisions altogether, which is a
  different and worse outcome than the one intended.
  **Context**: Every "stop asking" change needs its reading pinned beside the silence.
