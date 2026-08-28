---
created_at: 2026-08-28T10:22:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Derive the CI retirement candidate set with no new store

## Overview

PROPOSED. Before CI can take the refused delete, something in CI has to answer *which
branches may be deleted*. This ticket derives that set the way `step-retire-claims.sh`
already derives its own — the `superseded` rows out of `drive/scripts/list-claims.sh` —
and nothing else: no queue, no cursor, no field on any artifact, no second oracle.

`superseded` means the unit's content already reached the base, which is exactly why the
branch can be deleted; the derivation must therefore stay the claim oracle's, not a
re-implementation inside a workflow. A branch already gone reports `already_gone` rather
than an error.

Note the container/CI split this sits on: `list-claims.sh` needs a full-history checkout
and reachable remote refs, so a shallow scan yields nothing to act on and must say so
(`shallow_history`) rather than answer "nothing to retire".

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle; the
  candidate set is read from it and derived nowhere else
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the existing
  derivation to mirror (`.claims[] | select(.resume_reason == "superseded") | .unit`),
  including its `fetched` / `shallow` degradations
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — read only; it emits nothing
  new for this mission
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the writer whose unit
  resolution (`claims_unit_resolution`, the live-row rule) the CI side must not duplicate

## Implementation Steps

1. Read `step-retire-claims.sh`'s candidate derivation and its degradation ladder
   (`claims_unreadable`, `claims_unparseable`, `origin_unreachable`, `shallow_history`)
   in full; the CI side answers the same questions and must not invent new words for them.
2. Add the reader CI will call — one script under `drive/scripts/`, emitting the
   `superseded` units with their branches as JSON, always exit 0, each degradation named.
   Compose `list-claims.sh`; do not re-walk refs and do not read `plan-units.sh`, which
   stages what its living migrations converge.
3. Resolve each unit through `lib/claims.sh`'s live-row rule, never first-match — a unit
   held by a `superseded` branch and a live one must resolve to the live one, and the
   dead branch must govern nothing.
4. Report a branch already absent from origin as `already_gone`, a success rather than a
   degradation, so a re-run is a clean no-op.
5. Add hermetic coverage in `scripts/test-workflow-scripts.mjs` over a bare-origin
   fixture: the set is exactly the `superseded` units, a live claim never appears, and a
   shallow or unfetched scan yields an empty set **with its reason**, never a bare empty.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The candidate set is exactly the `superseded` units `list-claims.sh` reports; a
  judgement verdict never appears in it
- No queue, no cursor, no stored state and no field on any artifact is added
- A unit held by a superseded branch and a live one resolves to the live one
- A degraded scan (unfetched, shallow, unparseable) yields no candidates **and its reason**
- Always exit 0

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` (unchanged by this ticket)

**Gate** — what must pass before approval:

- The two commands above pass, and `git diff` shows no new artifact field and no second
  claim-scanning implementation

## Considerations

- The obvious shortcut — having the workflow shell out to `git for-each-ref` and match
  `work-*` — is the one thing this ticket exists to refuse: it would be a second oracle,
  and it would delete branches nothing proved empty.
- `plan-units.sh` looks like the natural composition and is refused for the reason
  `step-retire-claims.sh`'s header records: the survey runs the living migrations and
  **stages** what they change.
