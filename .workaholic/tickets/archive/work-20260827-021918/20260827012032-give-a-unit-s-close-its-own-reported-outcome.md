---
created_at: 2026-08-27T01:20:32+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Give a unit's close its own reported outcome

## Overview

The `review` route reports **which route it took** and never **whether the merge landed**. A run
that opened a pull request and was refused the merge produces the same report line as one that
merged — so the failure is invisible at the only surface that records the run.

`branching/scripts/merge-reason.sh` already classifies the refusal into five honest words
(`merge_not_allowed`, `head_moved`, `session_type_cannot_merge`, `merge_forbidden`,
`merge_failed`), each of which is a different next action by that script's own header. The
vocabulary is correct and does not move; what is missing is that the route **carries it into the
run report**, per unit.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an outcome is reported in its own
  vocabulary, never collapsed

## Key Files

- `plugins/workaholic/skills/drive/reference/routing.md` — §6's `review` route: reads
  `gate-decision.sh`, then `PUT .../pulls/{n}/merge` through `gh-rest.sh`. The place the outcome
  is produced.
- `plugins/workaholic/skills/drive/SKILL.md` — §6 and §7. §7 is the run-report contract; the
  per-unit line is defined there.
- `plugins/workaholic/skills/branching/scripts/merge-reason.sh` — the refusal vocabulary. **Read
  its header before touching anything**: the reasons are deliberately distinct next actions, and
  the session-type rung is keyed on the message with the status as its fallback.
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the other caller of the same
  ladder, for `WORKAHOLIC_AUTO_MERGE`. Its reporting of `merged` / `merge_reason` is the existing
  shape to follow rather than invent a second one.

## Implementation Steps

1. Read §7's per-unit report contract and establish what a unit's line carries today, so the
   merge outcome is added to it rather than reported beside it.
2. Make the `review` route record its merge attempt's result per unit: `merged`, or the
   `merge-reason.sh` word. A route that never attempted the merge (a `hard`/`confirm` scan finding
   held the pull request) reports that as its own outcome — **not** as a merge failure.
3. Carry it into §7's report line so the run report names it for every `review` unit.
4. Document the addition in `drive/SKILL.md` §6/§7 and `drive/reference/routing.md` in the same
   change (CLAUDE.md's *Update the docs in the same change*).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `review` unit's report line names `merged` or the refusal word that stopped it.
- A unit whose merge was never attempted because a `hard`/`confirm` finding held its pull request
  is reported as that, distinctly from a refused merge.
- `merge-reason.sh`'s five words are unchanged in derivation and format.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Exercise `merge-reason.sh` over each rung's response text and confirm the report renders that
  word.

**Gate** — what must pass before approval:

- The hermetic suite passes; the scan-held and refused cases render differently.

## Considerations

- The `auto` route already distinguishes "shipped" from "demoted, with the gate that caused it".
  Reuse that wording rather than minting a parallel vocabulary for the same distinction.
- `/specificate`'s own `WORKAHOLIC_AUTO_MERGE` publish hits the identical refusal — pull request
  #625 in the measurement is a `[Proposal]`, not a driven unit. That seam is **out of this
  ticket's scope** (the ask names the `review` route), but the shape chosen here should not make
  the same fix there harder.

## Final Report

Development completed as planned.

The `review` route now carries its merge attempt's result into the run report, per unit, as one
of three outcomes: `merged`, `merge_refused: <word>` (the word being `merge-reason.sh`'s own,
unchanged in derivation and format), and `merge_not_attempted: <hard|confirm>` when a scan
finding held the pull request and no merge was tried. The three are defined once in
`drive/reference/routing.md` §6 and named in `drive/SKILL.md` §6 and §7.

The scan-held case is stated as **not** a merge failure in both documents rather than left to be
inferred. That is the ticket's second acceptance criterion and the one a later reader is most
likely to collapse: a scan-held pull request is the gate working, a refused merge is the loop
stopping, and one word for both would hide the failure the outcome exists to surface. The `auto`
route's existing `shipped` / `demoted, with the gate that caused it` wording is reused for the
same distinction, per the Considerations.

`session_type_cannot_merge` is documented with its sanctioned second attempt
(`mcp__github__merge_pull_request`, `rules/shell.md`) and the rule that the **retry's** outcome
is what gets reported — reporting the REST refusal after a successful connector merge would name
a failure that did not happen.

### Discovered Insights

- **Insight**: The route is prose, so the checkable half is that the contract names the
  vocabulary and that its two documents cannot drift apart on it.
  **Context**: The agent performs the merge and writes the report, so no script produces the
  outcome and no fixture can assert one. What a test *can* pin is that `routing.md` and
  `drive/SKILL.md` each name all three outcomes, all five `merge-reason.sh` rungs, and the
  sentence separating the scan-held case from a refusal — asserted against the same `cases`
  array the ladder itself is tested with, so adding a rung to the script fails the doc pin until
  both documents name it.

- **Insight**: The `/specificate` seam hits the identical refusal and was deliberately left out.
  **Context**: The measurement behind this mission includes #625, a `[Proposal]` published by
  `WORKAHOLIC_AUTO_MERGE` rather than a driven unit. The ticket scoped that out, and the shape
  chosen here does not make it harder: `publish-tree-pr.sh` already reports `merged` /
  `merge_reason` in exactly this vocabulary, so that seam needs a reporting change and no new
  words.
