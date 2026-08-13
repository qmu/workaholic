---
created_at: 2026-08-13T07:26:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refresh-the-outdated-documentation-to-match-current-behavior
merge_policy:
---

# Bring the docs runbooks in line with the shipped loops

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

The `docs/` runbooks are what an operator reads when a loop misbehaves, so a retired
contract left standing there is worse than one in the README: it is read under
pressure and acted on. Two of them describe a `/setup-routines` that no longer exists.

The ask names no passage, so this ticket **locates the drift first**. Measured against
`origin/main` at `cdcbfe1`:

- `docs/proposal-loop-runbook.md:73-87` — "Either command renders a **copy-paste setup
  sheet** … The plugin does not create it", and `:97-100` "**An agent never creates or
  re-points a routine at all** … the plugin renders the setup sheet and **manages
  nothing**". `/setup-routines` now *configures* the routines through a
  `RemoteTrigger`-family tool on every run and reports per-routine changes; the sheets
  are the recovery path of the `no_transport` refusal, not the product (the achieved
  mission `configure-routines-automatically-via-remotetrigger`).
- `docs/drive-loop-runbook.md:102-104` — the same retired "renders copy-paste setup
  sheets and **manages nothing**" statement.
- `docs/drive-loop-runbook.md:106-110` — "The cloud routine is merge-triggered; the
  clock in this runbook is the fallback (2026-08-06)". `[Implement]` fires on the
  hourly schedule `30 * * * *`; a routine cannot subscribe to a repository event at all
  (the API's trigger surface is `cron_expression` / `run_once_at` / API token).

`docs/proposal-loop-runbook.md:59-65` is **already correct** on the clock-fired trigger —
evidence that these documents drifted in patches, which is why step 1 is a read-through
rather than a search-and-replace.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an operator document must describe the running system
- `workaholic:development` / `policies/commit-change-history.md` — the change and its docs land together

## Key Files

- `docs/proposal-loop-runbook.md` — operator runbook for `[Propose]`.
- `docs/drive-loop-runbook.md` — operator runbook for `[Implement]`.
- `docs/loop-drill-runbook.md` — the on-demand drill; written 2026-08-12, check rather than assume.
- `docs/loop-engineering-workflow.md` — **decision history**, not a current-behavior doc.
- `CLAUDE.md` — the reference the operator instructions are measured against.
- `plugins/workaholic/skills/workaholify/SKILL.md`, `plugins/workaholic/commands/setup-routines.md`
  — the current routine-configuration contract.

## Implementation Steps

1. **Localize before editing.** Read each `docs/*.md` against `CLAUDE.md` and the shipped
   skills, and list every operator instruction that no longer matches. Confirm or drop
   each item above and add what it missed.
2. Correct the `/setup-routines` passages in `docs/proposal-loop-runbook.md` and
   `docs/drive-loop-runbook.md` to the configure-first contract, with the setup sheets
   named as the `no_transport` refusal's recovery path.
3. Correct `docs/drive-loop-runbook.md`'s trigger description to the hourly schedule and
   state plainly that a repository-event trigger is not available.
4. Check `docs/loop-drill-runbook.md` the same way and correct whatever step 1 found.
5. **Do not rewrite history.** `docs/loop-engineering-workflow.md` and the dated decision
   sections inside the runbooks record what was decided when; where such a passage is
   superseded, mark it superseded in place (dated, naming what replaced it) instead of
   editing the record to read as though the old decision never happened.
6. Re-read each runbook's failure-mode tables against the corrected prose so a table row
   does not point at a procedure the surrounding text just changed.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No operator instruction in `docs/` describes a contract the shipped code does not have.
- The three measured drifts above are corrected, or the Final Report says why one was not
  drift after all.
- Every superseded dated passage is marked superseded rather than silently rewritten, and
  `docs/loop-engineering-workflow.md`'s decision entries keep their original wording.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "manages nothing" docs/` returns nothing outside an explicitly superseded block.
- `grep -rniE "merge-triggered|merge trigger" docs/drive-loop-runbook.md` returns only history-marked text.
- The corrected `/setup-routines` description is diffed against `CLAUDE.md`'s command row.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green (regression guard on a prose-only edit).
- `git diff --name-only <base>..HEAD` lists only files under `docs/`.

## Considerations

- These runbooks mix two genres — operator procedure and dated decision record — in one
  file. Correcting the first while preserving the second is the whole difficulty of this
  ticket; when a passage is ambiguous, treat it as history and supersede rather than edit.
- If the drift turns out to be in the shipped behavior rather than the document (a runbook
  describing something better than what ships), that is a finding for the feedback stream,
  not a code change smuggled into a documentation ticket.
