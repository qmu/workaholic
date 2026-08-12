---
created_at: 2026-08-12T17:27:13+00:00
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-workflow-scripts-survive-a-graphql-restricted-gh
merge_policy:
---

# Cover the remaining gh readers and pin the dependency

## Overview

PROPOSED. With discovery and publishing converted, three readers and one writer
still reach GitHub through GraphQL-backed subcommands: `report/create-or-update.sh`
(`gh pr list`, `gh pr create`), `ship/pre-check.sh` (`gh pr list`),
`mission/list-related-prs.sh` (`gh pr list --search`) and `feedback/open-issue.sh`
(`gh issue create` — the cross-repository crossing). Left alone they reintroduce the
same stop at `/report`, `/ship`, `/mission` and `/fb`'s crossing.

This ticket also closes the loop the first two open: nothing today prevents the next
script from reaching for `gh pr list` again, and the failure is invisible until an
hourly routine silently does nothing in a session nobody reads. The mission is only
finished when a regression is caught by the suite rather than by a developer reading
a transcript.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/report/scripts/create-or-update.sh` — `gh pr list` /
  `gh pr create` (~lines 68-72)
- `plugins/workaholic/skills/ship/scripts/pre-check.sh` — `gh pr list` (~line 29)
- `plugins/workaholic/skills/mission/scripts/list-related-prs.sh` — `gh pr list
  --search` (~line 34); the search qualifier has no direct REST equivalent
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — `gh issue create`
  (~line 50), the sanctioned cross-repository crossing
- `scripts/test-workflow-scripts.mjs` — where the regression check lands
- `plugins/workaholic/rules/shell.md` — where the convention would be written down

## Implementation Steps

1. Convert the three readers to `gh api`: `GET repos/{owner}/{repo}/pulls?head=...`
   for the head-branch lookups in `create-or-update.sh` and `pre-check.sh`, keeping
   `pre-check.sh`'s `state=all` semantics and its `mergedAt` reading.
2. Handle `list-related-prs.sh` separately: its `--search "<slug> in:title,body"` maps
   to the REST search API (`GET search/issues?q=...`), which has different rate limits
   and result shapes. Verify the slug-matching behavior is preserved, or state
   plainly what changed.
3. Convert `feedback/open-issue.sh` to `POST repos/{owner}/{repo}/issues`, preserving
   the crossing's contract exactly — the verbatim human confirmation, the masking
   judgment and the scans all happen before this call and must not move.
4. **Pin the dependency so it cannot silently return.** Add a check to the hermetic
   suite that fails when a workflow script invokes a GraphQL-backed `gh` subcommand
   (`gh issue|pr <verb>`) outside an explicitly allowlisted set, and record the rule
   in `rules/shell.md` with the reason.
5. Sweep for call sites this ticket's list may have missed
   (`grep -rn "gh \(issue\|pr\|search\)" plugins/workaholic/skills`), and confirm the
   `workaholify` bootstrap's `gh` probe still reports usefully.
6. Update `CLAUDE.md` and every skill doc naming the converted commands.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/report`, `/ship`, `/mission` and `/fb`'s crossing complete under the stubbed
  restricted `gh`
- No workflow script invokes a GraphQL-backed `gh` subcommand outside the allowlist
- The regression check fails when such a call is deliberately reintroduced
- `list-related-prs.sh` returns the same PRs for a known slug as it does today

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including a deliberately reintroduced
  violation, to prove the check bites
- A live `/report` on a throwaway branch and a `mission/list-related-prs.sh` run
  against an existing slug, compared before and after
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The crossing flow's human confirmation and scan order are provably unchanged
- The allowlist is documented with its reason, not just enforced

## Considerations

- The REST search API is rate-limited more tightly than the GraphQL one; if that
  proves material for `list-related-prs.sh`, degrading to a git-native branch scan
  (as `list-proposed-refs.sh` already does) is the fallback worth weighing.
- `feedback/open-issue.sh` writes to *another* repository; its conversion deserves
  the most conservative review in this mission.
- The allowlist must not become a loophole — if it ends up holding most call sites,
  the check is theatre and should be reconsidered rather than kept.

## Final Report

Development completed as planned, with two findings that changed the design.

### The sweep found a call site the ticket's list did not name

`grep` over `plugins/workaholic/skills` and `hooks` turned up
**`branching/scripts/list-worktrees.sh:29`** (`gh pr list --head … --state open`), which
none of the mission's three tickets mentions. `/report`'s `worktree` context routes on
that call's `has_pr`, so under a restricted `gh` every claim worktree would have read as
un-PR'd. This is the concrete argument for step 4: the enumerated list was already
missing one, and nothing structural stopped the next.

### `search/issues` is refused too — one layer further out than GraphQL

`list-related-prs.sh`'s `--search "<slug> in:title,body"` has an exact REST translation,
and it was implemented and **measured against the live session first**:

```
{"message":"This GitHub API path is not available: sessions are bound to their
configured repositories. Use repository-scoped endpoints (repos/{owner}/{repo}/...)."}
```

So the mission's premise — "REST answers in both" — holds only for *repository-scoped*
REST. The query moved to `GET repos/{slug}/pulls?state=open&per_page=100` with the
`in:title,body` match done locally in `jq`. The question asked is identical; `headRefName`
is now a real value rather than one the search shape would have lost. What changed is
stated in the script: one page of 100 open PRs instead of server-side pagination.

That attempt also exposed a defect the conversion nearly shipped: **`gh api` prints its
error body to stdout**, so `available: true` was reported with the error object sitting
where the caller expects a PR list. The script now requires the answer to be a JSON array
before calling the read available, and two assertions pin it.

### What changed

| file | from | to |
| ---- | ---- | -- |
| `report/scripts/create-or-update.sh` | `gh pr list`, `gh pr create`, `gh repo view` | REST throughout; base branch now resolved explicitly via `gather/scripts/base-ref.sh` (the subcommand used to infer it), body on stdin |
| `branching/scripts/list-worktrees.sh` | `gh pr list --head` | REST; slug resolved once outside the loop |
| `mission/scripts/list-related-prs.sh` | `gh pr list --search` | repo-scoped `pulls` + local `jq` match + array-shape validation |
| `feedback/scripts/open-issue.sh` | `gh issue create` | `POST repos/{slug}/issues`, payload on stdin |
| `scripts/test-workflow-scripts.mjs` | — | the regression check, plus a new `list-related-prs` suite |
| `rules/shell.md`, `CLAUDE.md` | — | the convention, its measured reason, and the enforcement |

`ship/scripts/pre-check.sh` was already converted by an earlier ticket in this mission and
needed nothing.

### The pin (step 4)

`testNoGraphqlGhCalls` walks every `*.sh` under `skills/` and `hooks/`, strips full-line
comments, and fails on `gh issue|pr|repo <verb>`. `GRAPHQL_GH_ALLOWLIST` is **empty**, and
the check proves it bites: it plants a violation next to a comment naming the same
command and asserts exactly one hit, at the right line. `gh release` is deliberately not
prohibited — it is REST-backed and `ship/scripts/publish-release.sh` uses it correctly;
banning it would be the theatre this ticket's Considerations warn about.

### Verification

- `node scripts/test-workflow-scripts.mjs` → **2317 passed, 0 failed** (from 2290 on the
  merge base), including the new check, the new `list-related-prs` suite, and the two
  rewritten pin sites.
- The crossing's pinned assertions were **rewritten, not deleted**: the target, the title
  and "the body never rides argv" are all still asserted, now against the stdin payload.
- `create-or-update.sh`'s test gained a real origin and remote-tracking ref, because REST
  needs what `gh pr create` used to infer — the behaviour change made visible rather than
  papered over.
- Live: `list-related-prs.sh` returns `available: true` with `prs: []` against this
  repository (ground truth: 0 open PRs), where the old GraphQL version returns
  `available: false` in this same session — the mission's whole point, demonstrated.
- The `workaholify` bootstrap probe (`gh api user`) is REST already and answers here
  (`tamurayoshiya`); `gh-rest.sh available` → `{"ok": true}`.
- `posix-lint.sh` → `conforming: true, count: 0`; `build.mjs` / `verify.mjs` /
  `validate-metadata.mjs` clean; release scan `pass`.

### Gate

- The crossing's confirmation and scan order are **provably unchanged**: composition,
  masking, the verbatim confirmation, `scan-outbound-body.sh` and `check-outbound-body.sh`
  all run before `open-issue.sh` is invoked, and this change touches only the wire call
  inside it. Nothing was added to or removed from that sequence.
- The allowlist is documented with its reason in `rules/shell.md`, not merely enforced.

### Discovered Insights

- **Insight**: "REST works where GraphQL is blocked" is too coarse. A bound session also
  refuses non-repository-scoped REST paths (`search/*`), with a *different* message from
  the GraphQL 403.
  **Context**: any future conversion should reach for `repos/{owner}/{repo}/…` and do the
  filtering locally, rather than assuming the REST equivalent of a search qualifier is
  available. The mission's own premise sentence is now narrower than when it was written.
- **Insight**: `gh api` writes its error body to **stdout**, not stderr, and callers that
  test only for a non-empty string will treat an error as data.
  **Context**: this is the same shape that bit `resolve-target.sh`'s `visibility` field
  (recorded in `feedback/reference/crossing.md`). Any `gh api` reader needs a type check
  on the answer, not an emptiness check — `list-related-prs.sh` now has one.
- **Insight**: `gh api` has no `--arg`; its `--jq` takes a filter string only.
  **Context**: a slug or any other datum must go through a real `jq` pipe with `--arg`, or
  it gets interpolated into filter text and breaks on the first quote character.
