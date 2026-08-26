---
created_at: 2026-08-26T11:32:04+00:00
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
