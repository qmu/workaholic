---
created_at: 2026-08-29T11:05:00+00:00
status:
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260829-111906
---

# Make the channel-default assertions hermetic

## Overview

FOUND at accounting time by `/implement` on 2026-08-29, on a base whose CI reads green.

`node scripts/test-workflow-scripts.mjs` reports **4 failed** on `main` and has since PR #713
merged. All four belong to `step-unanswered-asks.sh`'s slice and all four have one cause:

```
FAIL  the channel defaults to the repository's own name, with no prefix
       expected "source-repo", got "dev-workaholic"
FAIL  the unreadable case routes through the existing keyed question
FAIL  the resolved channel name rides the summary
FAIL  and the contract asks for it in the report too
```

PR #713 set `WORKAHOLIC_INBOUND_SLACK_CHANNEL=dev-workaholic` in this repository's own
`.claude/settings.json` `env` block — correctly, and that setting is not the defect. The
defect is that the slice's fixture invocation inherits `process.env`, so the variable the
repository sets for its *runtime* reaches the assertion about the *default derivation* and
overrides exactly the term under test.

The slice already knows how to do this: line ~2638 passes
`env: { ...process.env, WORKAHOLIC_INBOUND_SLACK_CHANNEL: "elsewhere", ... }` for the case
that wants the variable set. The default-derivation case wants it **unset** and says nothing,
so it reads whatever the developer's own repository happens to declare.

**Why it is worth a ticket rather than a shrug.** A permanently red suite is not merely
untidy here: `drive/scripts/catch-up-claim.sh` runs `node scripts/test-workflow-scripts.mjs`
as its pre-push validation gate, so every catch-up on this repository now refuses
`validation_failed:test-workflow-scripts.mjs` over a branch whose own work is sound. A red
suite that nobody can distinguish from a real regression also costs every later run the
judgment call this one had to make.

**It is invisible to CI**, which is why it survived a merge: the base's checks read `green`
(`freshness`, and the release workflow) — the suite is a local gate, not a check run.

## Key Files

- `scripts/test-workflow-scripts.mjs` — the four failing assertions and the fixture that
  spawns the step (search `step-unanswered-asks`)
- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — the reader under
  test; **it is not expected to change**

## Steps

1. Reproduce: `node scripts/test-workflow-scripts.mjs` on a clean `main` — 4 failed.
   Then reproduce the cause directly: `env -u WORKAHOLIC_INBOUND_SLACK_CHANNEL node
   scripts/test-workflow-scripts.mjs` and confirm the same four pass. That comparison is the
   diagnosis; do not change anything before it is in hand.
2. Localize the leak to the fixture that spawns `step-unanswered-asks.sh` for the
   default-derivation assertions, and confirm which of the four inherit it (the ticket
   asserts all four; the run's own reading governs).
3. Make the assertion state its own environment rather than inherit one: the case that wants
   the variable **unset** must unset it explicitly, exactly as the case at ~line 2638 sets it
   explicitly. Prefer the narrowest form that the surrounding fixtures already use.
4. Do **not** repair this by changing the default, by changing
   `.claude/settings.json`, or by relaxing the assertion to accept either answer — each of
   those trades a hermeticity defect for a weaker test.
5. Consider, and record the judgment either way, whether the fixture helper should strip the
   whole `WORKAHOLIC_*` family rather than this one name. An answer of "no, name them one at
   a time" is acceptable and should be written down, because the next such leak will ask the
   same question.

## Considerations

- The variable is read by two callers (`/propose`'s inbound sweep and the tick's
  `unanswered-asks` step). Only the step's slice is failing; if the sweep's slice turns out to
  inherit the same variable and pass by luck, fix it in the same change and say so.
- `.claude/settings.json`'s `env` is read at **session start**, so a developer whose session
  predates PR #713 sees a green suite and a developer whose session is newer sees a red one.
  That is what makes this look intermittent from the outside; it is not.

## Policies

- Development: the repository's own verification command must be runnable and meaningful from
  any developer's checkout; a test that reads the developer's environment tests the developer.
- Implementation: do not weaken an assertion to make it pass.

## Quality Gate

- `node scripts/test-workflow-scripts.mjs` passes with **0 failed** from a checkout whose
  `.claude/settings.json` declares `WORKAHOLIC_INBOUND_SLACK_CHANNEL`, and also with the
  variable unset in the environment — the two runs agree.
- `step-unanswered-asks.sh` is unchanged, or the change to it is argued in the commit body.
- No assertion was deleted, skipped or loosened to reach green.

## Final Report

The repair landed before this ticket reached a survey, and this run verified it rather than
re-implementing it. The same defect was met independently an hour earlier by the `/implement`
run driving `point-the-inbound-readers-at-the-channel-that-exists`: that unit's own Quality Gate
named `node scripts/test-workflow-scripts.mjs`, the suite came back `5024 passed, 4 failed`, and
the four failures were these four. It was fixed inside that unit and merged as
[#717](https://github.com/qmu/workaholic/pull/717), which is why this ticket's queue arrived
already satisfied. Recorded plainly so the archive does not read as work this branch performed.

**Step 5 is the one this ticket asked to be decided rather than assumed, and it was decided the
broad way.** The fix strips the whole `WORKAHOLIC_*` family once at suite startup rather than
naming `WORKAHOLIC_INBOUND_SLACK_CHANNEL` at the one call site. The judgment is written into the
code beside the strip: a per-call-site exclusion is one more thing every future test must
remember, and the failure it prevents is invisible until somebody happens to set the variable —
so the narrow form fixes this occasion while leaving the class open. A test that needs a value
sets it on its own `run`, which is exactly what the override assertions beside these four already
do, so the broad strip costs nothing and closes the class.

**The Consideration about the sweep's slice is answered by construction.** The ticket asked that
if `/propose`'s inbound-sweep slice inherited the same variable and passed by luck, it be fixed in
the same change. A family-wide strip at startup covers every slice at once, so no second site
needed finding — which is a second, independent reason the broad form was the right one.

**Quality Gate, verified in this claim's own worktree at the merged base:**

- `node scripts/test-workflow-scripts.mjs` → `5036 passed, 0 failed`, from a checkout whose
  `.claude/settings.json` declares `WORKAHOLIC_INBOUND_SLACK_CHANNEL` and whose session carries it.
- `env -u WORKAHOLIC_INBOUND_SLACK_CHANNEL node scripts/test-workflow-scripts.mjs` →
  `5036 passed, 0 failed`. The two runs agree, which is the gate's own wording.
- `step-unanswered-asks.sh` is unchanged — confirmed, and it was never touched.
- No assertion was deleted, skipped or loosened: the count rose (5024 → 5036, the four repaired
  plus tests arriving from other merges) and none was removed.

Step 1's prescribed reproduction (`env -u …` against a red `main`) was not run in this order,
because the red base it names no longer exists — #717 is merged. The equivalent comparison the
gate actually asks for, both environments agreeing at 0 failed, is in hand above.

### Discovered Insights

- **Insight**: Two independent `/implement` runs met this defect within the hour and answered it
  differently — one fixed it inside the unit whose gate it blocked, the other queued it.
  **Context**: Both were correct under the failure contract, and the duplication cost only this
  verification pass. It is a mild argument that a defect blocking a unit's *own* named Quality
  Gate is in that unit's scope by construction, which is the reading #717 took.
