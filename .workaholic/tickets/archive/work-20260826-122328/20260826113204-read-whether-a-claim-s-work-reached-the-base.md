---
created_at: 2026-08-26T11:32:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Read whether a claim's work reached the base

## Overview

PROPOSED. Ticket 2 of 8. One reader, grain-agnostic, answering a single question: has
this claim branch's work reached the base? It asks whether a **merged pull request** has
that branch as its head — which answers at both grains without reading any relation at
all, and is exactly why the ask names it as the constraint.

Three-valued on purpose: `merged`, `not_merged`, `unanswerable` with a reason. The third
is what lets ticket 3 keep the oracle's "degrades offline" contract instead of guessing.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claim-merged.sh` — NEW (name at the
  implementer's discretion, under `drive/scripts/lib/`). The reader.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the repository's **one** GitHub
  transport. `gh pr` is forbidden by `rules/shell.md` and the suite fails on it.
- `plugins/workaholic/rules/shell.md` — READ. It also notes that a bound session refuses
  `search/*`, so the lookup must use repository-scoped endpoints and filter locally.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the consumer, in ticket 4.
- `scripts/test-workflow-scripts.mjs` — coverage for all three values.

## Implementation Steps

1. Read `rules/shell.md`'s GitHub section whole, including the 2026-08-23 qualification.
   It decides the transport and rules out the obvious shortcut before any code is written.
2. Write the reader taking a branch name and answering `{state, reason}` where `state` is
   `merged` / `not_merged` / `unanswerable`.
3. Resolve it by asking for pull requests whose head is that branch through
   `gh-rest.sh api`, filtering locally — `state=closed` plus a `merged_at`, never a
   `search/*` query, which a bound session refuses.
4. Read **no** `mission:` relation, no artifact and no ticket. That constraint is the
   ask's, and it is what keeps this from becoming a second parser of a many-valued field.
5. Answer `unanswerable` — never `not_merged` — for every failure that is ours rather than
   the repository's: no `gh`, a transport error, a rate limit, an unparseable response.
   Name each reason distinctly enough that ticket 3 can report it.
6. Exit 0 in every case. A reader that exits non-zero turns a degraded read into a failed
   scan, which is the opposite of the contract.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader answers all three states, with a reason on `unanswerable`, and exits 0
  always.
- It reads no `mission:` relation and no artifact.
- It reaches GitHub only through `gather/scripts/gh-rest.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — cases for merged, not merged, and each
  named degradation with a stubbed transport.
- The suite's existing `gh issue|pr|repo` prohibition passes unchanged.

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- This is the mission's one **network** read. Every consumer must treat it as optional,
  which is ticket 3's job; keeping the reader itself simple and total is what makes that
  possible.
- A branch deleted after merge still has its pull request, so head-branch lookup survives
  branch cleanup. Confirm this against a real merged branch before relying on it.

## Final Report

Development completed as planned. `drive/scripts/lib/claim-merged.sh` takes a branch name and
answers `{branch, state, reason}` where `state` is `merged` / `not_merged` / `unanswerable`,
exiting 0 in every case.

**It asks the pull request, not the tree.** "Is there a merged pull request whose head is this
branch?" answers at both grains without reading a `mission:` relation, a ticket or any artifact
— the constraint the ask names, and the thing that keeps this from becoming a second parser of
a many-valued field. A hermetic assertion pins it: the reader's body may not contain `mission:`,
`read-relation.sh`, `ls-tree` or `tickets/archive`.

**Two decisions worth recording.**

*No separate availability probe.* Step 5 asks for `no gh` to be named distinctly, and the
obvious route is `gh-rest.sh available` first. It was not taken: this reader runs once per
claim, so the probe would double the scan's network cost to learn what the call itself reports
— and it is the only classification that stays honest when the transport dies between a probe
and the call. The one call's failure is classified instead, into `gh_unavailable`,
`rate_limited`, `session_refused` and `transport_error`, with `unparseable_response` and
`slug_unresolved` beside them.

*Executed rather than sourced*, against the `lib/` convention beside it (`claims.sh` is sourced,
never run). This is the claim protocol's one network read, and a separate process is what makes
it separable: a caller can decide not to spend it, a test can stub `gh` on PATH and drive every
state, and nothing it defines leaks into `claims_scan`'s flat namespace, which already carries
about thirty `_cs_` locals. Stated in the file's own header so the divergence is deliberate.

**The lookup is repository-scoped and filtered locally**, as `rules/shell.md` requires of a
bound session: `repos/<slug>/pulls?state=closed&head=<owner>:<branch>`, then `merged_at != null`
in `jq`. `state=closed` is the superset of merged, and `merged_at` is what separates a merged
pull request from one somebody closed without merging — which is emphatically not this branch's
work reaching the base, and is asserted with a mixed payload.

### Discovered Insights

- **Insight**: A closed pull request and a merged one are the same `state` in the REST API;
  only `merged_at` separates them.
  **Context**: A reader that filtered on `state=closed` alone would report a rejected branch as
  delivered — the most dangerous possible false positive here, since the consumer stops
  offering the unit for resumption. The mixed-payload test exists to keep that distinction.
- **Insight**: `gh-rest.sh slug` needs no `gh` at all — it reads `remote.origin.url` — so slug
  resolution and transport availability are genuinely separate failures and deserve separate
  reasons.
  **Context**: That is why `slug_unresolved` is answered before any network call is attempted:
  a tree with no remote is not a degraded transport, and reporting it as one would send a reader
  looking for a connectivity problem that does not exist.
