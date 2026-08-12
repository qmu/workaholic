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
