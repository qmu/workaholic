---
created_at: 2026-09-03T10:42:22+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# State the composed squash body where the merge rule lives

## Overview

The squash-merge rule already has a home: `CLAUDE.md`'s *Every pull request this loop merges is
squash-merged* bullet, which names `merge-method.sh` and its four call sites. That bullet is now
wrong in two ways — the call sites are five, and the merge composes a body. Leaving it is the
defect this repository calls out by name: outdated documentation. This ticket also records the
non-goal, so a later session does not read the mission as licence to rewrite history.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `CLAUDE.md` — the squash-merge bullet under *Enforcement gates*, and the commit-trailers bullet
  that must name the housekeeping marker.
- `plugins/workaholic/skills/gather/scripts/merge-method.sh` — its header, where the neighbouring
  derivation is explained.
- `plugins/workaholic/skills/commit/SKILL.md` — *The trailer block*.
- `plugins/workaholic/skills/drive/reference/routing.md` — the route's own description of the
  merge.
- `README.md` — where the merge behaviour is described for a reader outside the loop.


## Implementation Steps

1. Rewrite the squash-merge bullet: the method and the body are two derivations, the call sites
   are enumerated correctly, and the suite protects both.
2. State the measurement that produced the change — 190 commits carrying `Refresh heartbeat`, one
   267-line body — where the rule is stated, in the voice the surrounding bullets use.
3. State the non-goal explicitly: commits already on the trunk stay, and history is not rewritten
   for tidiness.
4. Name the housekeeping trailer in the commit-trailers bullet and in `skills/commit/SKILL.md`.
5. Update `drive/reference/routing.md` and `README.md` where either describes the merge.
6. Regenerate `outputs/` with `node scripts/build-plugins/build.mjs`.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every document that describes the merge names the composed body and the correct call sites.
- The non-goal is stated where the rule is stated.
- `outputs/` is regenerated and the freshness check passes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No document still says four call sites or omits the body.
- The generated bundle carries no diff after a rebuild.


## Considerations

- This ticket runs last on purpose: documenting a behaviour before it exists is how a document
  drifts in the other direction.
