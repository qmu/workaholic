---
created_at: 2026-08-12T17:27:13+00:00
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-workflow-scripts-survive-a-graphql-restricted-gh
merge_policy:
---

# Open and merge pull requests through REST

## Overview

PROPOSED. Ingestion is only half the loop. `publish-tree-pr.sh` opens the pull
request with `gh pr create` and auto-merges it with `gh pr merge`; `ship/merge-pr.sh`
merges with `gh pr merge` and confirms the merge commit with `gh pr view`. All are
GraphQL-backed, and `gh pr list` was measured returning the same HTTP 403 as
`gh issue list` in the session this mission's feedback record documents.

The consequence is the worse half of the failure: a run in a restricted session
writes its record and its tickets, pushes the branch, and then dies at `pr_failed` —
the one abort the workflow declares unrecoverable-by-retry, requiring a human to
open the pull request by hand. Every `/propose` and `/implement` tick in such a
session ends with pushed-but-unpublished work.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — `gh pr create`
  (~line 233) and the `WORKAHOLIC_AUTO_MERGE` `gh pr merge` (~line 255)
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` — `gh pr merge` (~line 72)
  and the `gh pr view --json mergeCommit` confirmation (~line 108)
- `plugins/workaholic/skills/ship/scripts/pre-check.sh` — `gh pr list` (~line 29),
  whose swallowed-exit-127 comment is prior art for this exact class of bug
- `plugins/workaholic/skills/propose/reference/workflow.md` — step 10 documents the
  `pr_failed` contract this ticket changes the likelihood of

## Implementation Steps

1. **Reproduce first**, with the stubbed restricted `gh` from the discovery ticket:
   drive a publish tree to the point of `gh pr create` and confirm the run reports
   `pr_failed` with the branch pushed. Do the same for `ship/merge-pr.sh`.
2. **Fix the diagnosability before the transport.** `gh pr create` is invoked with
   `2>/dev/null`, so the 403 never reaches the operator — `pr_failed` today is
   indistinguishable from a network blip, an auth failure, or a policy denial.
   Capture stderr and carry a `detail` into the `pr_failed` line. This alone would
   have made the measured incident self-describing.
3. Convert PR creation to `POST repos/{owner}/{repo}/pulls` via `gh api`, returning
   the same `pr_url` shape the callers already parse.
4. Convert the merge to `PUT repos/{owner}/{repo}/pulls/{number}/merge`
   (`merge_method: merge`, matching today's `gh pr merge --merge`), and the merge
   confirmation to `GET repos/{owner}/{repo}/pulls/{number}` reading `merge_commit_sha`
   — preserving `merge-pr.sh`'s documented precedence for resolving the merge commit.
5. Keep every existing contract intact: `WORKAHOLIC_AUTO_MERGE` still gated on the
   release scan's `pass` verdict, any finding still leaving the PR open,
   `WORKAHOLIC_PR_TITLE` and `WORKAHOLIC_CLOSES_ISSUE` unchanged, and `pr_failed`
   still meaning "pushed but unpublished, open it by hand".
6. Update `propose/reference/workflow.md` and `drive/reference/routing.md` where they
   name `gh pr merge` explicitly.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Under the stubbed restricted `gh`, a publish tree opens its pull request and, with
  `WORKAHOLIC_AUTO_MERGE=1` and a passing scan, merges it
- `pr_failed` carries a `detail` naming the underlying cause
- The auto-merge gate is unchanged: a `block` verdict still leaves the PR open, and
  `merged` / `merge_reason` report what happened
- `ship/merge-pr.sh` resolves the same merge commit SHA as before for a given PR

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — extended with a stubbed-`gh` publish case
- A live end-to-end publish of a throwaway artifact branch on this repository,
  confirming PR URL, merge, and `Closes #<N>` rendering
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No regression in the scan gate: a deliberately failing scan must still block merge
- The hermetic suite stays hermetic — the stub must not reach the network

## Considerations

- Merge conflicts and required-check failures surface differently through REST than
  through `gh pr merge`'s messages; `merge_reason` must stay honest rather than
  collapsing every non-200 into `merge_failed`.
- `gh pr create` also resolves the base repository for forks; the REST call needs the
  owner/repo derived explicitly.
- Depends on the shared helper from the discovery ticket, including wherever its
  Open Decision lands it.
