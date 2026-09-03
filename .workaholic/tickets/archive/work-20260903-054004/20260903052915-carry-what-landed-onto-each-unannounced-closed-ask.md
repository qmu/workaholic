---
created_at: 2026-09-03T05:29:15+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
merge_policy:
verification_handoff: 
---

# Carry what landed onto each unannounced closed ask

## Overview

A finish line must name **what landed**. The reader from the previous ticket names the item;
it does not yet say what closed it. GitHub records the closing event, and the pull requests that
reference the issue carry the title, the merger and the merge time — the same three facts
`reconcile-candidates.sh` already needs `merged_by` and `merged_at` for. This ticket carries
them onto each candidate, emitting them **empty rather than invented** when they cannot be read.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh` — the reader this
  extends.
- `plugins/workaholic/skills/moderate/scripts/reconcile-candidates.sh` — the precedent for a
  bounded single-object GET carrying `merged_by`/`merged_at`, and for emitting an unresolvable
  one empty.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one transport.

## Implementation Steps

1. For each candidate, read the issue's timeline/closing reference through `gh-rest.sh` and
   collect the pull requests that closed it: number, title, `merged_by`, `merged_at`.
2. Bound that read exactly as `reconcile-candidates.sh` bounds its own — one bounded read per
   candidate, capped by the same `--limit`, never a sweep.
3. Attach `landed: [{"number", "title", "url", "merged_by", "merged_at"}]` to each candidate.
   A candidate closed with no merged pull request carries `landed: []` and
   `closed_unmerged: true` — a person closed it, which is a different sentence.
4. An unresolvable field is emitted **empty**; the composing step states it as unresolved and
   never invents a name or a time.
5. Report the per-candidate read outcome so a partial read is visible as partial.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- Each candidate carries `landed[]` with the closing pull requests, or an empty list with
  `closed_unmerged` set.
- An unresolvable `merged_by`/`merged_at` is empty, never substituted.
- The added reads stay bounded by the reader's existing limit.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic cases in `node scripts/test-workflow-scripts.mjs` over a stubbed transport.

**Gate** — what must pass before approval:

- No unbounded listing is introduced; the read count stays a function of `--limit`.

## Considerations

- A merged pull request and a hand-closed issue are different outcomes and the finish line
  must be able to say which; folding them into one field is how the two drift.

## Final Report

Development completed as planned. Each candidate now carries `landed[]` —
`{number, title, url, merged_by, merged_at}` per merged pull request that cross-referenced the
issue — plus `closed_unmerged`, `landed_read` and `landed_truncated`.

The read is bounded as `reconcile-candidates.sh` bounds its own: one timeline read per candidate,
plus one single-pull GET for each merged cross-reference, that second capped by
`WORKAHOLIC_ANNOUNCE_LANDED_MAX` (default 5) and reporting `landed_truncated`. The whole read
count therefore stays a function of `--limit` and never of the repository's size. An unresolvable
`merged_by` is emitted empty; the other four fields come off the timeline and survive a refused
GET intact.

`closed_unmerged` is claimed only on a positive reading — the timeline was read and named no
merged pull request. A timeline that could not be read answers `landed_read:
timeline_unreadable` with `closed_unmerged: false`, so *nobody merged anything* and *I could not
see what merged* never read alike.

### Discovered Insights

- **Insight**: The issue timeline's `cross-referenced` event carries the whole referencing pull
  request inline at `source.issue` — `number`, `title`, `html_url` and `pull_request.merged_at`
  — so four of the five fields a finish line needs cost no second call. `merged_by` is the sole
  exception and lives only on the single-pull GET, which is exactly why
  `reconcile-candidates.sh` spends that same GET for the same field.
  **Context**: A future reader wanting *which pull requests touched this issue* should reach for
  the timeline rather than for a search, which a bound session refuses outright.
- **Insight**: An unmerged cross-reference is not a landing. A pull request that mentioned the
  issue and was then closed appears in the timeline identically to one that merged, separated
  only by `pull_request.merged_at`, so the filter belongs in the jq program rather than in the
  caller's judgement.
  **Context**: Announcing a closed-unmerged pull request as what landed would put a real,
  checkable pull request number behind a false sentence.
- **Insight**: A `gh` stub that answers one canned body cannot serve a reader that calls three
  endpoints. The dispatcher here selects a fixture by endpoint and must live in its own file:
  chaining to it through `sh -c "<body>"` lets the outer shell expand `$1` and `$prog` before
  the inner shell ever sees them, which fails as a reader bug rather than a fixture bug.
  **Context**: The same trap waits for any test that wants one endpoint of several to fail.
