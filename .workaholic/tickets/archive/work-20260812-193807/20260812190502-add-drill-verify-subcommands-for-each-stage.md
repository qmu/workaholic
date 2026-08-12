---
created_at: 2026-08-12T19:05:02+00:00
author: a@qmu.jp
assignees:
depends_on: 20260812190501-add-the-loop-drill-script-seed-status-reset.md
mission: make-the-propose-implement-loop-drillable-on-demand
merge_policy: auto
---

# Add drill verify subcommands for each stage

## Overview

After a routine fire, "did it work" is currently answered by reading a session
transcript. The artifacts are the truth — the proposal PR, the feedback record, the
ticket queue, the claim branches — and they are all readable from `origin/main` and
REST `gh`. This ticket adds `verify-propose` and `verify-implement` subcommands to
`scripts/e2e/loop-drill.sh`, asserting each stage's artifacts as one JSON pass/fail
row per check so the operator's change→test loop has a machine verdict per fire.

`verify-propose <issue_number>`: the `[Proposal]` PR exists and is **merged**
(auto-merge on opening) with `Closes #N`; the issue is closed; on `origin/main` a
feedback record under `.workaholic/feedbacks/` names `/issues/<N>` (load-bearing
for `already_captured` dedup); a ticket in `tickets/todo/` carries the `feedback:`
ref and the issue's assignee. `verify-implement <issue_number>`: the drill ticket
moved `tickets/todo/` → `tickets/archive/<branch>/`; a story exists under
`.workaholic/stories/`; no unmerged `work-*` branch remains (merge released the
claim); the unit's PR is merged.

Slack checks — the 🔵/🟢 finish lines threaded under the seed root, read via `qfs`
— are **advisory rows only**: reported, never load-bearing, because the
notification surface must never decide a stage that the artifacts already decided.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/command-scripts.md` — script ergonomics and contracts
- `workaholic:implementation` / `policies/test.md` — hermetic, deterministic test design

## Key Files

- `scripts/e2e/loop-drill.sh` — the entry point gaining two subcommands
- `plugins/workaholic/skills/propose/reference/workflow.md` — the abort reasons
  `verify-propose` distinguishes (`nothing_in_hand`, `list_failed`, `pr_failed`, …)
- `plugins/workaholic/skills/drive/SKILL.md` — the reconciliation-line and terminal
  token contract `verify-implement` reads against
- `scripts/test-workflow-scripts.mjs` — the hermetic suite

## Implementation Steps

1. `verify-propose`: fetch `origin/main`, locate the feedback record and ticket by
   the `/issues/<N>` ref; REST-read the PR (`gh api repos/{o}/{r}/pulls?state=…` /
   `search/issues` is GraphQL-free) and the issue state. One row per check:
   `{check, pass, detail}`.
2. `verify-implement`: fetch `origin/main`; assert the archive move, the story, the
   merged unit PR, and claim release via `git branch -r --no-merged origin/main`.
3. Advisory Slack rows via `qfs` read of the seed thread; a `qfs` failure renders
   `{check: "slack_…", pass: null}` and never affects the exit code.
4. Exit code reflects load-bearing rows only; `--json` emits the full row set.
5. Hermetic tests: throwaway repos with pre-seeded `.workaholic/` state and stub
   `gh`/`qfs` shims pin every row's machine token (`check` names, `pass` values) —
   no prose pinning.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each row names the artifact checked; the exit code reflects load-bearing rows
  only, and a Slack row can never fail a stage
- A missing artifact yields a failing row naming the file/ref it expected, not a
  script error
- No GraphQL-backed `gh` subcommand anywhere

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the stubbed row-shape cases
- One live `verify-propose` + `verify-implement` against a real drill pass

**Gate** — what must pass before approval:

- Hermetic suite passes offline; POSIX sh throughout

## Considerations

- The verify surface reads the same oracles the loop itself uses (`origin/main`,
  unmerged branches, REST issues) — never a session transcript, which is diagnosis
  material, not a verdict.
- Distinguish "stage not yet run" (no artifacts, issue still open) from "stage
  failed" (abort reason visible in artifacts): the former is `pending`, not `fail`.

## Final Report

Development completed as planned. `verify-propose <issue>` and
`verify-implement <issue>` emit one JSON line carrying `{check, pass, detail,
bearing}` rows. Load-bearing rows read `origin/main`, the unmerged-branch scan and
REST issue/pull-request state — never a session transcript. Slack rows are
`bearing: advisory` and can only ever be `pass: null`/`true`/`false` without touching
the exit code. `--json` emits the full row set; the terse default carries only the
rows an operator must act on.

Three verdicts with distinct exit codes: `pass` (0), `fail` (1), `pending` (5) —
the last for a stage nobody fired yet, which is reported with `load_bearing.failed:
0` so a poller can tell "wait" from "broken".

Verified with `node scripts/test-workflow-scripts.mjs` (2394 passed, 0 failed),
including two new cases pinning the row contract. The live `verify-propose` +
`verify-implement` pass against a real drill is deferred with the live cycle in the
previous ticket — it needs a real seeded issue and two routine fires.

### Discovered Insights

- **Insight**: a TAB is an IFS **whitespace** character, so `while IFS="$TAB" read -r
  a b c d e` silently shifts every field after an empty one.
  **Context**: measured here — an UNMERGED pull request has an empty `merged_at`, so
  the body arrived holding the title and `verify-propose` reported "no pull request
  carries Closes #N" about a pull request that carried it. Exactly the row this drill
  exists to recognise. The fix is a `-` sentinel from jq (`.merged_at // "-"`), not a
  different reader. Every other TSV reader in this repository escapes the same trap
  only by never emitting an empty middle field — worth knowing before adding one.
- **Insight**: the archive path *is* the unit's branch
  (`tickets/archive/<branch>/<file>`), so the ticket's landing place names the pull
  request and the claim to check.
  **Context**: that is why nothing has to be carried between the two verify stages —
  each relation is read back out of the artifacts, which is the same statelessness the
  notification lookup relies on.
- **Insight**: `claim_released` is checked narrowly — this unit's branch is gone from
  the unmerged set, not "the repository holds no claims".
  **Context**: the literal reading would go red on a colleague's live claim, which is
  a failure the operator cannot act on. In the drill's own window (seed refuses a dirty
  base) the two readings coincide.
