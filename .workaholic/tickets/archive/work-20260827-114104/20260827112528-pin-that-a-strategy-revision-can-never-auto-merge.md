---
created_at: 2026-08-27T11:25:28+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Pin that a strategy revision can never auto-merge

## Overview

PROPOSED. A strategy-touching proposal has not auto-merged since 2026-08-14, and that
exemption is **prose only**: `publish-tree-pr.sh` merges whenever
`WORKAHOLIC_AUTO_MERGE=1` is set, and nothing stops a run from setting it. That was
tolerable while the only strategy writes were a create and a close, both rare and both
already surrounded by the rule. A third writer makes the exemption load-bearing — it is
the entire premise on which a third writer is admissible — so this ticket moves it from
prose into the seam and pins it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — section 5, the
  `WORKAHOLIC_AUTO_MERGE=1` branch; the one place a proposal merges itself.
- `scripts/test-workflow-scripts.mjs` — where the pin lands, beside the existing
  strategy-writer assertions.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 10's instruction
  to leave the variable unset; it becomes a statement of what the seam enforces.

## Implementation Steps

1. In `publish-tree-pr.sh`, before the auto-merge branch, ask whether the commit this
   call is publishing touches any path under `.workaholic/strategies/`. Derive it from
   the tree the script is already publishing — a diff against the base — never from a
   caller-supplied flag, because a flag is the same prose one layer down.
2. When it does, **skip the merge** and report it as its own outcome:
   `merged: false`, `merge_reason: strategy_touching`. This is not a failure and must not
   read as one — it is the exemption, and the pull request is left open for the operator
   exactly as it is today.
3. Leave every other path byte-identical: a proposal touching no strategy still merges
   under `WORKAHOLIC_AUTO_MERGE=1`, and a scan finding still holds a pull request open
   under its own reason.
4. Pin it hermetically: a publish whose tree touches `.workaholic/strategies/` never
   merges even with `WORKAHOLIC_AUTO_MERGE=1` set, and one that does not is unaffected.
   Drive it over a local fixture with the transport stubbed — no network.
5. Restate step 10's instruction as what it now is: the caller leaves the variable unset,
   and the seam refuses regardless. Belt and seam, because the caller is a judgement.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A publish touching `.workaholic/strategies/` reports `merge_reason: strategy_touching`
  and leaves the pull request open, whatever `WORKAHOLIC_AUTO_MERGE` says.
- A publish touching no strategy merges exactly as before.
- The pin fails when the refusal is removed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Deliberately break the seam and confirm the new test goes red.

**Gate** — what must pass before approval:

- The suite is green, and the deliberate break was observed failing.

## Considerations

- This is the ticket that keeps the third writer from becoming a second **author**. If
  only one thing in this mission survives review, it should be this one.
- A close (`9c`) and a create (`9b`) are covered by the same refusal, which is a
  strengthening of an existing rule rather than a new one — say so where the rule is
  recorded, so a reader does not read it as a change in their behaviour.

## Final Report

Development completed as planned. `publish-tree-pr.sh` section 5 now asks, before the
auto-merge branch, whether the commit it is publishing touches any path under
`.workaholic/strategies/` — derived from a diff against the base, never from a
caller-supplied flag — and when it does it skips the merge and reports `merged: false`,
`merge_reason: strategy_touching` with the pull request left open. Every other path is
byte-identical: a proposal touching no strategy still merges under
`WORKAHOLIC_AUTO_MERGE=1`, and a scan finding still holds a pull request open under its own
reason. A create, a close and an amendment are covered by the one refusal, which is stated
where the rule is recorded as a strengthening rather than a change in anyone's behaviour.
`/specificate`'s step 10 is restated as belt and seam: the caller still leaves the variable
unset, and the seam refuses regardless.

**The deliberate break was observed.** Neutralising the refusal (forcing the derived count
to zero) made the strategy-touching publish report `merged: true, merge_reason: merged` —
which is assertion 1 of the new test — and the seam was restored byte-identical afterwards.

### Discovered Insights

- **Insight**: two `publish-tree-pr.sh` calls in the same wall-clock second against one
  origin collide on `work-$(date +%Y%m%d-%H%M%S)` and report `branch_collision`. The new
  test hit it and now gives each scenario its own fixture, exactly as
  `testPublishTreePrClosesIssue` already documents.
  **Context**: independent origins never share that namespace, so this is a fixture rule
  rather than a race to sleep around — worth knowing before writing any two-publish test.
- **Insight**: the refusal returns before the scan runs, so a strategy-touching publish
  spends no scan and reports no scan reason.
  **Context**: the exemption is about *authorship*, not safety; conflating the two would
  have made `strategy_touching` look like a finding.
