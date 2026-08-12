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

## Final Report

Development completed as planned. The reporter's hypothesis survived the reproduction and
was adopted.

### The reproduction, recorded before the fix

The restriction is per-session and cannot be summoned, so it was built: a stub `gh` early
on `PATH` that exits 1 with the measured 403 body for `issue`/`pr`/`search` and proxies
`api` to the real binary. Against the unmodified script:

```
{"ok": false, "reason": "list_failed", "detail": "HTTP 403: This GraphQL query
 (RepositoryInfo, sent by gh issue list) is not enabled for this session — only the
 pinned set of PR-review operations is served. Use REST via `gh api
 repos/{owner}/{repo}/...` instead."}
```

### Localization: the GraphQL surface, not auth and not assignment

Under the *same* stub and the same credential, both REST calls answered: `gh api user`
returned `tamurayoshiya`, and `gh api "repos/qmu/workaholic/issues?state=open&assignee=…"`
returned a well-formed (currently empty) array. So the credential is valid, the assignment
filter is serviceable, and the failure is specifically the GraphQL-backed subcommand —
which is what makes a transport conversion the fix rather than a retry or a re-auth.

After the change, the same stub yields `{"ok": true, "identity": "tamurayoshiya",
"limit": 20, "issues": [], "excluded": []}` — byte-identical to the unrestricted run.

### Open Decision — resolved: `gather/scripts/gh-rest.sh`, invoked, not sourced

**Where the shared helper lives.** Ruled: `gather`, as an executable invoked through the
established cross-skill form.

- Six skills reach GitHub in this mission's scope — `propose`, `branching`, `ship`,
  `report`, `mission`, `feedback`. A `lib/` beside each consumer means six copies of one
  transport, and drift between them would be invisible in exactly the way this defect was.
- `gather` is the documented home of common operations (CLAUDE.md, *Design principles*),
  and a GitHub transport used by six skills is the definition of one.
- The recorded objection — gather's scripts are read-only gatherers, and later tickets need
  PR *writes* — is answered by the script's **shape**, not by its address: `gh-rest.sh`
  performs no operation of its own. It resolves a slug and forwards a call whose method the
  caller chooses, so the write remains the caller's act and gather gains a transport rather
  than a mutator.
- `branching` was rejected as a home because it owns the publish seam only; `/fb`'s issue
  crossing and `/ship`'s merge confirmation would sit oddly there.
- **Invoked, not sourced**: every existing cross-skill call in this plugin runs another
  skill's script with `sh`, and the bundle build's closure detection is tuned for that form
  (`${SCRIPT_DIR}/../../<skill>/scripts/`, enforced by `verify.mjs`). Cross-skill sourcing
  has no precedent here and would be invisible to the build, shipping an incomplete closure.

### The fallback direction — resolved: REST-only, no GraphQL ladder

Recorded in the script header. REST answers in both restricted and unrestricted sessions,
so a REST-after-GraphQL ladder would preserve a slower path, leave two behaviors to reason
about, and still fail whenever the 403 arrives in a shape the ladder did not anticipate.
One always-available transport cannot drift from itself.

### The two REST differences handled deliberately

- **Pull requests share the issues endpoint.** `GET /issues` returns them; `gh issue list`
  did not. Rows carrying `.pull_request` are filtered, and the suite pins it — without this
  a routine would begin proposing against its own pull requests.
- **Pagination replaces `--limit`.** `per_page` carries the cap so a single page reproduces
  the old ceiling, rather than inheriting whatever the endpoint's default paging does.

### Discovered Insights

- **Insight**: The script's own error contract was never the defect — it correctly reported
  `list_failed` instead of inventing an empty inbox, which is why nothing looked broken. The
  failure was one layer beneath the contract: there was no path to the data at all in a
  session serving REST only.
  **Context**: A well-behaved "I could not read this" is not evidence that the reader is
  fine. When an honest failure recurs on a schedule, the question to ask is whether the
  *capability* it depends on is static — here it was per-session, and the code assumed
  otherwise.

- **Insight**: The hermetic suite gained a stubbed-`gh` shape that pipes a canned payload
  through the *real* `jq` using the expression the script actually passed (`$4` of `gh api
  <path> --jq <expr>`). That keeps the test hermetic while still exercising the production
  filter rather than a re-implementation of it.
  **Context**: Worth reusing for the remaining conversions in this mission — a stub that
  hard-codes the expected output would have passed even if the `.pull_request` filter were
  dropped.
