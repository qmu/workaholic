---
created_at: 2026-08-12T19:05:03+00:00
author: a@qmu.jp
assignees:
depends_on: 20260812190502-add-drill-verify-subcommands-for-each-stage.md
mission: make-the-propose-implement-loop-drillable-on-demand
merge_policy: auto
---

# Write the loop drill runbook

## Overview

The drill's mechanics (seed → fire → verify → fire → verify → reset) span two
trigger ids, a cron race window, a JSON verdict per stage, and an abort playbook.
Scattered across skills and transcripts, that knowledge costs a re-derivation per
incident. This ticket writes `docs/loop-drill-runbook.md`: the single document an
operator follows from seed to a clean pass, with a failure-reason→file blame table
for every named abort reason.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — docs state
  behavior, not narrative
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `docs/loop-drill-runbook.md` — new; the deliverable
- `docs/proposal-loop-runbook.md`, `docs/drive-loop-runbook.md` — the sibling
  runbooks whose layout and voice this one follows
- `plugins/workaholic/skills/propose/reference/workflow.md` — abort-reason source
- `plugins/workaholic/skills/drive/SKILL.md` + `reference/` — terminal-table source
- `CLAUDE.md` — gains one line pointing at the runbook (docs updated in the same
  change)

## Implementation Steps

1. Stage table: exact commands per stage — `loop-drill.sh seed`, the two manual
   fires by trigger id (`[Propose]`, `[Implement]`) via the trigger API, the
   `list_runs`/`get_run_log` reading order, `verify-propose`/`verify-implement`.
2. Timing: the cron race windows (avoid ~:10–:20 for `[Propose]`, ~:25–:40 for
   `[Implement]`, hourly `15`/`30 * * * *`) and why a scheduled tick taking the ask
   verifies identically.
3. Blame tables: every abort reason in propose's workflow (`nothing_in_hand`,
   `list_failed`, `identity_unresolved`, `commit_failed`, `pr_failed`,
   `branch_collision`, `merge_failed`, …) and drive's terminal table (`pending` +
   exclusion reasons, claim refusal, `pr_error`, `handoff`, `blocked`) → the one
   file to read for each.
4. Abort playbook: `pr_failed` means the branch IS pushed — open the PR by hand,
   never re-publish; a half-driven unit is a live claim — merge its PR or
   explicitly `release-claim.sh`; everything else → `loop-drill.sh reset`.
5. Residue policy: what a clean pass intentionally leaves on `main` (feedback
   record, archived ticket, story, closed issue) and why re-runnability comes from
   fresh issue minting, never residue deletion. Mark both Slack surfaces advisory.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An operator reaches a clean pass from `seed` using only this document
- Every abort reason named by the propose workflow and the drive terminal table
  maps to exactly one file to read
- The runbook states the fresh-minting re-runnability rule and marks the Slack
  checks non-load-bearing

**Verification method** — the commands/tests/probes that prove them:

- Walk one full drill pass with the document as the only reference
- Cross-check the blame tables against `reference/workflow.md` and the drive
  terminal table for coverage

**Gate** — what must pass before approval:

- `CLAUDE.md` names the runbook in the same commit; no duplicated rule text (the
  runbook points at skills for rules, per the thin-pointer convention)

## Considerations

- The runbook documents the drill, not the loop's internals — rules stay in the
  skills that own them; the runbook links.
- Trigger ids are account-scoped configuration: name them as "the `[Propose]` /
  `[Implement]` routines' trigger ids (from the trigger API's list)", not as
  hard-coded values that rot.

## Final Report

Development completed as planned. `docs/loop-drill-runbook.md` takes an operator from
`seed` to a clean pass without another document: a stage table with the exact command
per stage, the cron race windows (`:10–:20` for `[Propose]`, `:25–:40` for
`[Implement]`), the row/verdict contract with its three exit codes, two blame tables,
an abort playbook, and the residue policy. `CLAUDE.md` names the runbook and the drill
script in this same commit; `README.md`'s documentation map gains its row.

Coverage was cross-checked mechanically rather than by eye: every `[a-z_]`-shaped
reason token in `propose/SKILL.md`, `propose/reference/workflow.md` and the drive
skill's §7 terminal table was tested for presence in the runbook, and the three real
gaps that check found (`deferred_by_operator`, `claimed_reported`, and the publish
seam's `push_failed`/`nothing_to_commit`) were added.

### Discovered Insights

- **Insight**: the abort reasons a drill actually meets are mostly **not** the propose
  skill's own — they belong to the publish seam (`publish-tree-pr.sh`:
  `commit_failed`, `branch_collision`, `push_failed`, `pr_failed`, `merge_failed`) and
  to `gh-rest.sh`.
  **Context**: a blame table built only from the skill that names the loop would send
  the operator to the wrong file for the most common failures. The reason lives where
  the script that prints it lives.
- **Insight**: three abort states must never be answered with `reset` —
  `pr_failed` (the branch is pushed; re-publishing duplicates the artifact), a
  half-driven unit (a live claim; merge its pull request or `release-claim.sh`), and a
  `secret` finding (an exposure, not residue).
  **Context**: this is why the playbook is ordered "read the outcome, then act" rather
  than "when in doubt, reset" — the safe-looking default is the destructive one in
  exactly the cases that matter.
- **Insight**: `deferred_by_operator` cannot occur in a drill.
  **Context**: the drill fires `/implement`, which asks nothing. Seeing it means an
  attended `/drive` took the unit instead — which makes it a useful diagnostic rather
  than an omission, and worth a row saying so.
