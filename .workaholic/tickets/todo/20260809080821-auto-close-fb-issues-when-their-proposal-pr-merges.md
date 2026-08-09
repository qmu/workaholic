---
created_at: 2026-08-09T08:08:21+00:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [20260809080752-fb-issues-are-not-auto-closing-when-their-proposal-pr-merges.md]
merge_policy:
---

# Auto-close FB issues when their Proposal PR merges

## Overview

The developer reported (#319) that "[FB] ***" GitHub issues stay open after their
corresponding "[Proposal]" pull request merges, even though a mechanism was believed to
exist for auto-closing them.

Investigation (this proposal) found there is **no such mechanism anywhere in the
plugin** — no script or routine template calls `gh issue close`, and no generated PR body
contains a `Closes #<N>` / `Fixes #<N>` line. The most likely explanation is that the
developer was relying on **GitHub's own native "closing keyword" behavior** (a merged PR
whose body contains `Closes #123` auto-closes issue #123) — but `propose/scripts/
list-proposed-refs` … `branching/scripts/publish-tree-pr.sh` never emits that keyword,
because the proposal pipeline never captures the triggering GitHub issue's *number* at
all: it only threads a local `.workaholic/feedbacks/<stem>.md` filename through
`feedback:` frontmatter, which has no relation to a GitHub issue number. The `[Consent]`
routine that used to announce a merge into the feedback thread was retired 2026-08-06
and never closed issues either (`skills/workaholify/reference/routines.md`).

This ticket implements the missing half: when `/propose`'s ask originates from a GitHub
issue, capture that issue's number/URL and have the resulting `[Proposal]` pull request
body carry a `Closes #<N>` line, so GitHub's native merge-closes-issue behavior fires. A
cloud `[Propose]` routine run has the number available as `CCR_TRIGGER_ISSUE_NUMBER`
(confirmed live in this session's own environment); a hand-typed `/propose #319 ...`
invocation needs the same number parsed from the argument.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/logging-and-monitoring.md` — the merge-closes-issue link must be legible/verifiable, not silently assumed

## Key Files

- `plugins/workaholic/skills/propose/reference/workflow.md` — step 9's `publish-tree-pr.sh` invocation is where the PR body is assembled; needs a `Closes #<N>` line appended when an issue number is in hand
- `plugins/workaholic/skills/propose/scripts/` — step 1 ("take the ask in hand") needs to capture/pass the triggering issue number through to step 9; consider a new optional argument/env read here rather than a new script
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the single call that opens the PR; confirm whether the closing-keyword line belongs in its `<why>`/`<changes>` args or needs a new explicit param
- `plugins/workaholic/commands/propose.md` — the command's argument contract; document that a `#<N>`/issue-URL in the argument (or `CCR_TRIGGER_ISSUE_NUMBER` under a routine) is what wires the auto-close
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` routine template/prompt; confirm no change needed here (the closing keyword is mechanical, not a notification format, so it should NOT go in this prompt — `workaholic:notify`'s *self-authorize* rule (#298) forbids adding notification-shaped behavior the prompt doesn't specify, but this is not a notification)
- `plugins/workaholic/skills/propose/SKILL.md` — document the closing-keyword behavior once implemented

## Implementation Steps

1. Confirm the exact GitHub "closing keyword" syntax GitHub honors in a PR body (`Closes #<N>`, case-insensitive, must target an issue in the same repository) and that it fires on a squash/merge-button merge (not just a fast-forward), since `/ship` and human merges both apply here.
2. In the propose workflow's step 1 (take the ask in hand), extract the triggering issue number when present — from `CCR_TRIGGER_ISSUE_NUMBER` (routine-provided env var) or from a `#<N>` / issue URL appearing in the command argument — and keep it in hand through to step 9. No `AskUserQuestion`; if no number is found, proceed exactly as today (record-only/mission/ticket forms are unaffected — this is additive).
3. Thread the captured issue number into the `publish-tree-pr.sh` call at step 9 so the generated PR body includes a `Closes #<N>` line (in addition to, not instead of, the existing summary content).
4. Verify end to end against a disposable test issue/PR in this repository: open a small ask as a GitHub issue, run `/propose` against it, confirm the resulting `[Proposal]` PR body contains `Closes #<N>`, merge it, and confirm the issue auto-closes.
5. Update `SKILL.md`/`reference/workflow.md` documentation for the new behavior, and note in `CLAUDE.md`'s `/propose` row that a merge now closes the originating issue when one was in hand (doc-drift rule).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `/propose` run triggered from a GitHub issue (via `CCR_TRIGGER_ISSUE_NUMBER` or a `#<N>`/URL in the argument) produces a `[Proposal]` PR body containing a GitHub closing keyword referencing that issue.
- Merging that pull request auto-closes the originating "[FB] ***" issue, verified live against a real disposable issue/PR in this repository.
- A `/propose` run with no issue number in hand (a hand-authored ask, a superseding record) is unaffected — same PR body shape as before, no crash, no closing-keyword line.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — add a hermetic case asserting the PR body carries the closing keyword when an issue number is supplied to the propose scripts, and that it is absent when none is supplied.
- A live end-to-end run against a disposable test issue in this repository (per Implementation Step 4), observed and reported in the Final Report.

**Gate** — what must pass before approval:

- The hermetic test suite (`node scripts/test-workflow-scripts.mjs`) is green.
- `node scripts/build-plugins/build.mjs` / `verify.mjs` / `validate-metadata.mjs` clean (this ticket touches `propose`, a script-bearing skill whose closure feeds `outputs/workflows`).
- The live end-to-end auto-close was actually observed, not merely inferred from reading GitHub's docs.

## Considerations

- FB issues filed through `/fb`'s cross-repository mode (`gh issue create -R <target>`) are the same shape as any other GitHub issue and should close the same way once their number is threaded through — no separate handling should be needed, but confirm during implementation.
- GitHub's closing-keyword behavior requires the PR and the issue to be in the **same repository**; a cross-repository `/fb` ask that is *itself* proposed in the target repo already satisfies this, so no cross-repo edge case is expected — but verify, since `/propose` never crosses repositories itself.
- Do not conflate this with `workaholic:notify`'s Slack notification model (#298/#300) — closing a GitHub issue is a GitHub-native mechanical act, not a new notification shape, and should not be added to the `[Propose]` routine's prompt.
- If GitHub's closing keyword turns out not to fire reliably on this repository's merge method (e.g. squash-merge via the GitHub MCP `merge_pull_request` tool), the fallback is an explicit `gh issue close`/`issue_write` call at the same point the PR body is assembled or at ship-time — note whichever approach was actually used and why in the Final Report.
