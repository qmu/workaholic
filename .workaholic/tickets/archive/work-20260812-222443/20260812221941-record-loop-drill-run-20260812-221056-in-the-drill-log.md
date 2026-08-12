---
created_at: 2026-08-12T22:19:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812221909-record-loop-drill-run-20260812-221056-in-the-drill-log.md]
merge_policy:
claim: work-20260812-222443
---

# Record loop-drill run 20260812-221056 in the drill log

## Overview

<!-- PROPOSED. Merging the pull request this was published on turns it into queued work. -->

Loop-drill pass `20260812-221056` (issue #423, minted by `scripts/e2e/loop-drill.sh seed`)
asks for one line in the drill log of `docs/loop-drill-runbook.md` recording that the pass
exercised the propose–implement loop end to end.

Unlike the previous pass, the log already exists: §8 ("Drill log") was added by run
`20260812-215314` (issue #419) together with its first row, and its preamble states the
convention — a row is appended by whoever ran the pass, at the end of it, using the run id
`seed` minted. This ticket therefore appends the **second row** to an existing table; it
creates no section and changes no other prose.

§7 already explains why this recurs: a pass never cleans up after itself, it mints a fresh
issue, so every drill produces its own row. That recurrence is the log working as designed,
not a duplicate of the previous ticket.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the drill log is the operator's index over the loop's own history

## Key Files

- `docs/loop-drill-runbook.md` — the only file this ticket changes. §8 ("Drill log",
  `:214-223`) holds the table; the new row goes directly beneath the
  `20260812-215314` row, keeping the log in chronological order.

## Implementation Steps

1. Read §8 of `docs/loop-drill-runbook.md` and confirm the table's column order
   (Run id | Date | Issue | Outcome) and the existing row's formatting — backticked run
   id, ISO date, `[#N](https://github.com/qmu/workaholic/issues/N)` issue link.
2. Append one row beneath the existing one:
   `| ` + backticked `20260812-221056` + ` | 2026-08-12 | [#423](https://github.com/qmu/workaholic/issues/423) | exercised the propose–implement loop end to end |`.
   Match the surrounding row's spacing exactly; add nothing else to the section.
3. Leave §1–§7 untouched — this pass surfaced no change to the procedure, the timing
   windows, or the blame tables.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `docs/loop-drill-runbook.md` §8 contains a row whose run id is `20260812-221056`,
  linking issue #423, directly after the `20260812-215314` row.
- The table still renders as a well-formed Markdown table (same column count on every
  row, header and separator unchanged).
- No file other than `docs/loop-drill-runbook.md` is modified.

**Verification method** — the commands/tests/probes that prove them:

- `grep -n '20260812-221056' docs/loop-drill-runbook.md` — exactly one hit, inside §8.
- `sed -n '214,230p' docs/loop-drill-runbook.md` — read the rendered section and confirm
  row order and column count by eye.
- `git diff --stat` — one file changed, one line added.

**Gate** — what must pass before approval:

- The diff is a single added table row; the drill log's preamble and §1–§7 are byte-identical.

## Considerations

- The outcome wording is the drill's own claim ("exercised the propose–implement loop end
  to end"). If the pass in fact aborted, the driving session records what actually
  happened instead — the log is the honest index, not a formality.
- Should the log ever grow past a screenful, a future ticket can decide whether to cap or
  roll it. That is out of scope here: two rows is not a size problem.

## Final Report

Development completed as planned. One row appended to §8 of `docs/loop-drill-runbook.md`,
directly beneath the `20260812-215314` row, matching its column order and formatting.

The outcome wording was checked rather than copied, per the ticket's own Considerations:
issue #423 is `closed` (2026-08-12T22:20:41Z, closed by the merged `Closes #423` of PR
#424, `[Proposal] Record loop-drill run 20260812-221056 in the drill log`), so the propose
leg of the pass provably ran end to end, and this `[Implement]` run is its implement leg.
"Exercised the propose–implement loop end to end" is therefore the honest row.

### Discovered Insights

- **Insight**: `plugin-src.sh`'s `checkout` candidate is only trustworthy *after* the
  Unified Run's freshen step, because the working tree's `plugins/` content is whatever
  branch is checked out — and step 0b can move it. This run resolved `src` to the checkout
  (1.0.172), then `git checkout main` landed on a stale baked-clone tip (77c462d, 200
  behind) and the plugin source silently reverted with it, to a `sync-main.sh` predating
  its own §5 realignment. That older copy reported `diverged` and would have terminated the
  tick — the exact loss §5 exists to prevent.
  **Context**: the registry cache path (`…/cache/workaholic/workaholic/<version>/`) is
  version-pinned and immune to checkout state, so it is the safe source for the scripts that
  run *before* and *during* the freshen. Ticket
  `20260812223046-pin-the-plugin-source-across-the-freshen-step.md` was minted for the fix.
