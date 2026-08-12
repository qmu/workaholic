---
created_at: 2026-08-12T19:05:01+00:00
author: a@qmu.jp
assignees:
depends_on:
mission: make-the-propose-implement-loop-drillable-on-demand
merge_policy: auto
---

# Add the loop drill script (seed / status / reset)

## Overview

Exercising the propose–implement loop today takes a hand-built GitHub issue, a
hand-written Slack post, and afterwards a hand-audit of stray branches — enough
friction that the loop is only ever tested by its own hourly failures. This ticket
collapses seeding and abort-recovery into single invocations: an operator-side
`scripts/e2e/loop-drill.sh` (POSIX `#!/bin/sh -eu`, outside the plugin — it assumes
the server's full `gh` and `qfs`, which plugin skills must not).

`seed` preflights and refuses loudly when the drill would be polluted: the
assigned-open-issue inbox is non-empty (`gh api
"repos/{owner}/{repo}/issues?assignee=<login>&state=open"` — discovery has no title
filter, so any stray assigned issue is taken as an ask), or an unmerged remote
`work-*` branch exists (a live claim AND a dedup ref). On a clean base it mints a
timestamped, uniquely-worded, instruction-shaped issue via REST (assignee = the
operator login from `gh api user`), then posts the `dev-workaholic` Slack root via
`qfs` as the user, carrying the ask summary and the issue URL verbatim on its own
line (the issue URL goes into Slack, never a Slack permalink into the issue).

`status` reports one JSON object: open drill issues, unmerged `work-*` branches
(the git-native claim oracle), drill tickets in `todo/` and `archive/`. `reset`
recovers an aborted run only: it closes stray drill issues/PRs and deletes
drill-owned unmerged branches, refuses anything it did not mint, and never writes
under `.workaholic/` (feedback records are immutable history).

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/command-scripts.md` — script ergonomics and contracts
- `workaholic:implementation` / `policies/test.md` — hermetic, deterministic test design

## Key Files

- `scripts/e2e/loop-drill.sh` — new; the drill entry point (subcommands seed/status/reset)
- `scripts/test-workflow-scripts.mjs` — the hermetic suite the guard tests join
- `plugins/workaholic/skills/propose/scripts/list-inbound-issues.sh` — the discovery
  contract the seeded issue must satisfy (assigned, open, this repo)
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle
  `status`/preflight must agree with

## Implementation Steps

1. Scaffold `scripts/e2e/loop-drill.sh` with the three subcommands; every outcome is
   one JSON line on stdout, non-zero exit names the blocker (`inbox_dirty`,
   `claim_dirty`, `identity_unresolved`, `slack_failed`, …).
2. `seed`: preflight (inbox, claims, `gh api user`), mint `RUN_ID` (UTC timestamp),
   open the issue via REST with a drill marker in the body (`drill:<RUN_ID>`), post
   the Slack root via `qfs run --commit "insert into
   /slack-me/qmu/dev-workaholic/messages values ('…')"`. Emit
   `{issue_url, issue_number, slack_posted}`. A Slack failure after the issue is
   minted reports `slack_posted: false` and leaves the issue (advisory surface).
3. `status`: read-only aggregation via REST + `git ls-remote`/`branch -r`; no `gh`
   GraphQL anywhere in the script.
4. `reset`: enumerate residue carrying the `drill:` marker (issue body, PR branch
   names from seed-minted asks), close/delete only those, re-run preflight, exit 0
   idempotently on a second consecutive run.
5. Extend `scripts/test-workflow-scripts.mjs` with stub `gh`/`qfs` shims on PATH in
   throwaway repos: pin the JSON shapes, the preflight refusals, and reset's
   refuse-foreign-branch behavior. No network.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `seed` exits non-zero naming the blocker on a dirty precondition; on success emits
  `{issue_url, issue_number, slack_posted}` with the issue assigned to the operator
  and the Slack root containing the issue URL verbatim
- Re-invoking `seed` after a clean pass mints a distinct, non-colliding pair
- `reset` refuses any branch or issue not drill-minted, is a no-op on its second
  consecutive run, and never writes under `.workaholic/`
- The script contains no GraphQL-backed `gh` subcommand

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new stubbed cases
- One live `seed` → `status` → `reset` cycle against this repository

**Gate** — what must pass before approval:

- Hermetic suite passes offline; added test code stays under the 500-added-line
  per-commit ceiling

## Considerations

- The drill script is operator tooling, not a plugin skill: it may assume `gh`,
  `qfs`, and the server environment, which is exactly why it lives in `scripts/`
  and ships to no other agent.
- The seeded ask must be generic and leak-safe (release-scan `leak` family): a
  trivial, uniquely-worded instruction about this repository, never client context.
- Slack access today: the `/slack-me` mount posts to `dev-workaholic`
  (measured 2026-08-12); the team-bot mount cannot see the private channel. The
  script should name the mount in one variable so a rebind is a one-line change.

## Final Report

Development completed as planned. `scripts/e2e/loop-drill.sh` ships with `seed`,
`status` and `reset`; every outcome is one JSON line, and the blockers
(`inbox_dirty`, `claim_dirty`, `identity_unresolved`, `gh_unavailable`,
`list_failed`, `issue_failed`) carry distinct non-zero exit codes (3 = dirty
precondition, 4 = the environment could not answer). Two hermetic cases join
`scripts/test-workflow-scripts.mjs` with stub `gh`/`qfs` shims on PATH.

The live `seed` → `status` → `reset` cycle named in the verification method is
**deferred to the operator**: it mints a real GitHub issue, which fires the
`[Propose]` routine on the next tick, and the base currently carries this run's own
claim — which the preflight correctly refuses. The refusals are what the hermetic
cases pin, and they are the half a live cycle cannot rehearse safely.

### Discovered Insights

- **Insight**: `seed`'s inbox preflight makes the drill self-serializing — a second
  seed over an unfinished pass is refused, because the first drill issue is still
  open and assigned.
  **Context**: the pass is finished by the merged proposal's `Closes #<N>`, not by
  the drill. So "re-runnable" means *after* a clean pass, and the first hermetic
  test asserted the wrong model until the script refused it. Residue deletion is
  never the path to re-runnability; fresh minting is.
- **Insight**: a helper that reports a blocker must never be called from inside
  `$(...)`.
  **Context**: `x="$(helper)"` swallows the helper's JSON into `x` and its `exit`
  kills only the subshell, so the caller dies with a bare status and nothing on
  stdout — the exact silent-failure shape the drill exists to detect. Every fallible
  call in this script is an `if ! x="$(...)"` in the current shell.
- **Insight**: `[ cond ] && var=value` under `set -eu` exits the script when the
  condition is false.
  **Context**: the AND-list's own non-zero status triggers `-e` when the list is the
  last command in the body. Two accumulator updates were written that way and had to
  become `if` blocks.
