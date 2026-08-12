---
created_at: 2026-08-12T17:27:13+00:00
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-workflow-scripts-survive-a-graphql-restricted-gh
merge_policy:
---

# Read the inbound issue inbox through REST

## Overview

PROPOSED. `list-inbound-issues.sh` discovers a `[Propose]` tick's asks with
`gh issue list`, a GraphQL-backed subcommand. Measured 2026-08-12 17:19 UTC in this
repository's own routine session, that call returned HTTP 403 — "This GraphQL query
is not enabled for this session; only the pinned set of PR-review operations is
served. Use REST via `gh api repos/{owner}/{repo}/...` instead." The script's own
contract held (it reported `list_failed` rather than inventing an empty inbox), so
the defect is underneath it: the discovery step has no path to the data in a session
that serves REST only, and the hourly routine then ingests nothing until the
session's policy happens to change.

This ticket carries the shared REST helper the rest of the mission builds on, and
converts the first consumer. Restoring ingestion is what makes the remaining tickets
worth driving — a loop that cannot read its inbox has nothing to publish.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/list-inbound-issues.sh` — the failing
  call site (`gh issue list --assignee ... --json ... --jq ...`, line ~79)
- `plugins/workaholic/skills/gather/scripts/` — where a shared REST helper would
  live if `gather` is chosen as its home (see Open Decisions)
- `scripts/test-workflow-scripts.mjs` — the hermetic suite; currently never calls
  `gh`, so a stubbed-`gh` harness is a new capability for it
- `plugins/workaholic/skills/propose/SKILL.md` — *Clock-fired discovery* documents
  the mechanism and must move with it

## Implementation Steps

1. **Reproduce before changing anything.** The restriction cannot be summoned on
   demand — it is per-session — so build the reproduction instead: a stub `gh` early
   on `PATH` that exits non-zero with the measured 403 body for any `issue`/`pr`
   subcommand and proxies `api` to the real binary. Confirm the current script
   reports `list_failed` under it.
2. **Localize.** Confirm the failure is the GraphQL surface and not auth or
   assignment: with the same credential, `gh api user` and
   `gh api "repos/{owner}/{repo}/issues?state=open&assignee=<login>"` both answer.
   Record which `gh` operations are REST-backed and which are not.
3. Write the REST reader — `gh api` against
   `repos/{owner}/{repo}/issues?state=open&assignee=<login>&per_page=<limit>`,
   filtering out rows carrying `.pull_request` (the REST issues endpoint returns
   pull requests too — the GraphQL path did not, and this is the one behavioral
   difference the conversion must not lose).
4. Repoint `list-inbound-issues.sh` at it, preserving every documented behavior:
   oldest-first ordering, the `already_captured` exclusion and its reporting, the
   `WORKAHOLIC_PROPOSE_ISSUE_LIMIT` cap, and `{"ok": false, ...}` with exit 0 for
   every unreadable-inbox case.
5. Decide and implement the fallback direction — REST-only, or REST-after-GraphQL —
   and state the reason in the script header, since a future reader will ask.
6. Update the SKILL's *Clock-fired discovery* section and `CLAUDE.md`'s `/propose`
   row in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Under the stubbed restricted `gh`, `list-inbound-issues.sh` returns `ok: true`
  with the assigned open issues, oldest-first
- Under an unrestricted `gh`, its output is unchanged from today's for the same
  repository state
- Pull requests never appear as issues; `already_captured` exclusions are still
  reported with their reason
- A genuinely unreadable inbox still yields `{"ok": false, "reason": ...}` exit 0

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — extended with the stubbed-`gh` case
- `bash plugins/workaholic/skills/propose/scripts/list-inbound-issues.sh` run live
  against this repository, compared against
  `gh api "repos/qmu/workaholic/issues?state=open&assignee=$(gh api user --jq .login)"`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The hermetic suite passes and stays hermetic (the stub must not reach the network)
- Documentation updated in the same commit (`CLAUDE.md`, propose `SKILL.md`)

## Open Decisions

- **Where the shared REST helper lives.** `gather` is the stated home of common
  operations, but its scripts are read-only context gatherers, and the later tickets
  need PR *writes* through the same helper; `branching` owns the publish seam but is
  not a general-purpose home. A third option is a `lib/` beside each consumer, as
  `drive/scripts/lib/` already does, accepting duplication. Not resolvable without
  the developer's architectural preference — resolve it explicitly when driving and
  record the choice in the Final Report.

## Considerations

- The reporter's proposed fix (swap `gh issue list` for `gh api`) is a hypothesis
  carried from the failing run, not a design: step 1 exists to confirm the failure
  mode before it is adopted.
- REST pagination differs from `--limit`; the cap semantics must be preserved
  deliberately rather than inherited from whatever `per_page` does.
- `gh api` still needs a resolvable `{owner}/{repo}`; deriving it from the remote
  is a step, not an assumption.
