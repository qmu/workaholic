---
created_at: 2026-09-03T10:42:22+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Compose the squash body at the three recovery merges

## Overview

Three further call sites merge pull requests: `retry-undelivered.sh` (the delivery retry),
`catch-up-claim.sh` (the catch-up's own delivery) and `settle-stranded-publication.sh` (the
stranded publication's settle). Each carries the same default, and each merges exactly the
branches whose bookkeeping is longest — a branch that needed catching up has more commits on it,
not fewer.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` — the call site around line 189.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — around line 478.
- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — around line 331.
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — the derivation.


## Implementation Steps

1. At each of the three, read the composer before the REST merge and pass the two fields.
2. A catch-up branch carries merge commits from `catchup-main.sh`; confirm the composer's
   `story` source still resolves for such a branch, and that the fallback covers it when it does
   not.
3. Leave every refusal word at all three untouched — `scan_held`, `content_conflict`,
   `not_undelivered`, `not_mechanical` and the rest still refuse before any body is composed.
4. Report the `source` in each script's own output field, beside its existing `delivery` /
   `merge_outcome` word.
5. Extend the hermetic coverage of each.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- All three merges land a composed squash body.
- Every existing refusal word at the three scripts is byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- No literal body field spelled at any of the three call sites.
- The composer runs after every gate, never before one.


## Considerations

- `catch-up-claim.sh` merges inside a turn that has just pushed; the composer must read the
  pushed tip rather than a stale local ref.

## Final Report

**Outcome**: implemented.

All three now read the composer before their REST merge and pass the two fields:
`drive/scripts/retry-undelivered.sh`, `drive/scripts/catch-up-claim.sh` and
`branching/scripts/settle-stranded-publication.sh`. Each reports the composer's word as its own
`body_source` field beside its existing `merge_outcome` / `delivery`.

**The catch-up's timing question from step 2 is answered where it arises.** `catch-up-claim.sh` composes
**after** its own push, so the branch story and the commit range the composer reads are the ones the
merge will actually squash — not a stale local ref. The comment at the call site says so. A branch
carrying `catchup-main.sh`'s merge commits still resolves its story (the composer reads the story file
by branch name, from the checkout or from the ref), and where it does not, `fallback` covers it.

**Every refusal at all three is byte-identical and still runs before the composer** — `scan_held`,
`content_conflict`, `not_undelivered`, `not_mechanical`, `no_open_pull_request` and the rest — so no
body is composed for a merge that will not be attempted.

**Verified**: `node scripts/test-workflow-scripts.mjs`; the call-site enumeration covers all three.
