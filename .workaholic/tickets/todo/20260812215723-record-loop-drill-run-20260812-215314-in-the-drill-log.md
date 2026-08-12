---
created_at: 2026-08-12T21:57:23+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812215702-record-loop-drill-run-20260812-215314-in-the-drill-log.md]
merge_policy:
---

# Record loop-drill run 20260812-215314 in the drill log

## Overview

<!-- PROPOSED. Merging the pull request this was published on turns it into queued work. -->

Loop-drill pass `20260812-215314` (issue #419, minted by `scripts/e2e/loop-drill.sh seed`)
asks for one line in the drill log of `docs/loop-drill-runbook.md` recording that the pass
exercised the propose–implement loop end to end.

The runbook has no drill log today. Its sections run stages → timing → verdicts → the two
blame tables → abort playbook → residue (§1–§7), and §7 states that a clean pass
deliberately leaves its artifacts on `main` as the loop's own immutable history. What is
missing is the operator-readable index **over** that history: which passes were run, when,
and how each ended. Reconstructing that today means walking closed issues and merged pull
requests by hand.

This ticket adds the log section and its first row. It is deliberately one edit to one
documentation file — the drill's own ask, not a redesign of the drill.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the drill's record is the operator's signal about the loop's health

## Key Files

- `docs/loop-drill-runbook.md` — the only file this ticket changes. §7 ("Residue, and why
  re-runnability is fresh minting", `:200-212`) is the section the log belongs beside: it
  already argues that a pass's artifacts are the durable record, and the log is the index
  over them.
- `scripts/e2e/loop-drill.sh:186-201` — `drill_issue_title` / `drill_issue_body`, which
  mint the run id and the marker (`drill:<run-id>`) a log row cites. Read-only here.
- `.workaholic/tickets/archive/work-20260812-193807/20260812190501-add-the-loop-drill-script-seed-status-reset.md`
  — the ticket that established the drill's vocabulary (run id, stages, verdicts); the log
  row's wording follows it rather than inventing new terms.

## Implementation Steps

1. Add a `## 8. Drill log` section at the end of `docs/loop-drill-runbook.md`, after §7,
   with one sentence saying what the log is for (an index over the passes whose artifacts
   §7 keeps) and how a row is added (at the end of a pass, by whoever ran it).
2. Give the section a table with the columns the drill already names — run id, date,
   issue, outcome — so a row is readable without opening GitHub.
3. Add the first row: run `20260812-215314`, 2026-08-12, issue #419, and the outcome
   ("exercised the propose–implement loop end to end").
4. Keep the runbook's own rule intact: it documents the **drill**, not the loop, so a row
   records what a pass did and never restates a rule that lives in a skill.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `docs/loop-drill-runbook.md` carries a drill-log section listing run `20260812-215314`
  with its date, issue #419, and its end-to-end outcome.
- The section states how a later pass appends its own row, so the log's shape is not
  re-invented each time.
- No other file changes.

**Verification method** — the commands/tests/probes that prove them:

- `grep -n "20260812-215314" docs/loop-drill-runbook.md` — the row exists.
- `grep -n "^## " docs/loop-drill-runbook.md` — the new section is the last one and the
  existing §1–§7 headings are unchanged.
- `git diff --name-only <base>..HEAD` — `docs/loop-drill-runbook.md` is the only path.

**Gate** — what must pass before approval:

- The runbook still reads as the drill's operator page: no rule that belongs to
  `workaholic:propose` / `workaholic:drive` / `workaholic:notify` is restated in the row.

## Open Decisions

- **Who writes a row — the operator, or the script?** This ticket writes the row by hand,
  which is what the ask says. The alternative is `loop-drill.sh verify-implement`
  appending it on a passing verdict, which would make the log complete by construction but
  gives a verifier a write side effect (it is read-only today, and `reset` would then have
  residue it did not mint). Recorded rather than resolved: the first row does not depend on
  the answer, and a later pass can adopt either without rewriting the section.

## Considerations

- The log accretes one row per pass forever. If it outgrows the runbook, the section is a
  natural thing to move under `.workaholic/` — but that would need a layout-allowlist
  registration (`hooks/workaholic-layout-allowlist.txt` plus `rules/workaholic.md`, in the
  same commit), so it is not worth doing for one row.
- §7's "the drill never edits or deletes" rule applies to the pass's artifacts, not to this
  documentation file; appending a row is not an edit of history.
