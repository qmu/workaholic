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

## Final Report

Development completed as planned, on the helper the discovery ticket placed at
`gather/scripts/gh-rest.sh`.

### Diagnosability first, transport second

Step 2 was done before the conversion, as the ticket directs. `gh pr create` was invoked
with `2>/dev/null`, so the measured 403 never reached the operator and `pr_failed` was
indistinguishable from a network blip, an expired token, or a policy denial. The call now
captures stderr and carries the underlying message into `pr_failed`'s `detail` alongside
the standing "the artifact IS pushed; open the pull request by hand" instruction. This
alone would have made the original incident self-describing.

### What was converted

| Call site | Was | Now |
| --------- | --- | --- |
| `publish-tree-pr.sh` PR creation | `gh pr create --body-file` | `POST repos/{slug}/pulls`, payload on **stdin** |
| `publish-tree-pr.sh` auto-merge | `gh pr merge --merge` | `PUT repos/{slug}/pulls/{n}/merge`, `merge_method: merge` |
| `ship/merge-pr.sh` merge | `gh pr merge --merge --delete-branch=false` | same `PUT`; REST never deletes the head branch, which is what the flag asked for |
| `ship/merge-pr.sh` confirmation | `gh pr view --json mergeCommit` | `GET repos/{slug}/pulls/{n}` → `merge_commit_sha` |
| `ship/pre-check.sh` lookup | `gh pr list --head --state all` | `GET repos/{slug}/pulls?head={owner}:{branch}&state=all` |

The PR body goes in on **stdin** rather than through argv, deliberately: a body carries the
whole story and a single argv entry is capped at 128 KiB on Linux — the same ceiling the
sibling scan-window ticket documents. Converting it to a `--field` would have traded one
transport bug for a size bug.

### Contracts held, and the two shapes that had to be remapped

`WORKAHOLIC_AUTO_MERGE` is still gated on the scan's `pass` verdict, a `block` still leaves
the PR open, `WORKAHOLIC_PR_TITLE` and `WORKAHOLIC_CLOSES_ISSUE` are untouched, and
`pr_failed` still means "pushed but unpublished". Two REST/GraphQL shape differences needed
explicit remapping rather than inheritance:

- **`state`**: `gh pr list` reports `MERGED`; REST reports `closed` with `merged_at` set.
  `pre-check.sh` remaps to the old vocabulary so every downstream caller is untouched.
- **`merge_reason` stays honest** rather than collapsing every non-200 into `merge_failed`:
  405 (GitHub refusing the merge — conflict or an unsatisfied required check) is
  `merge_not_allowed` and 409 (the head moved) is `head_moved`, because those are different
  next actions for whoever reads the line.

### Discovered Insights

- **Insight**: Four suite failures were assertions pinned to the *transport* rather than to
  the *property* — one asserted the source text contained `gh pr view --json mergeCommit`.
  It was rewritten to assert what actually matters (GitHub is asked for the merge commit,
  not the branch head) plus a new check that no GraphQL subcommand is invoked at all,
  applied to non-comment lines so the header can still record what it replaced.
  **Context**: A test that names the mechanism blocks the mechanism from changing. When a
  conversion breaks assertions, the question is whether each one was protecting a behavior
  or merely describing an implementation.

- **Insight**: The stubs that broke did so in the informative direction — they returned a
  bare URL where the script now needs `{html_url, number}` JSON, so a half-done conversion
  fails loudly rather than passing on a coincidence.
  **Context**: Worth preserving as the remaining call sites convert in ticket 3: stub the
  response *shape*, never just a success string.
