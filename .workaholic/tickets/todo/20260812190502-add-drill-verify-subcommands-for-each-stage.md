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
