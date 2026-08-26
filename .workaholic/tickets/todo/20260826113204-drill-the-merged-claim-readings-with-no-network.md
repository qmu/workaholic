---
created_at: 2026-08-26T11:32:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Drill the merged-claim readings with no network

## Overview

PROPOSED. Ticket 8 of 8. Extend `scripts/e2e/loop-drill.sh` with a subcommand proving all
four readings — merged mission claim, merged batch claim, genuinely in-flight claim, and
an unanswerable read — hermetically and with no `gh` call, in the manner of
`verify-direction-health`. Update the record in the same change.

The documentation half is not optional and is not a backstop: `CLAUDE.md` currently states
that `superseded` "answers for batch units and leaves mission units on today's reading",
which this mission reverses. Leaving it is a defect by this repository's own rule.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill. `verify-direction-health` and `verify-propose`
  are the two most recent precedents for a no-network subcommand.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file
  blame table.
- `plugins/workaholic/skills/drive/reference/claims.md` — the protocol record.
- `plugins/workaholic/skills/drive/SKILL.md` — the Claims section.
- `CLAUDE.md` — the claim-protocol bullet carrying the sentence this mission reverses.

## Implementation Steps

1. Read `verify-direction-health`'s implementation in `loop-drill.sh` whole. It is the
   shape to follow — a hermetic fixture, no network, named failures — and following it is
   cheaper than inventing a second style.
2. Add the subcommand, driving all four readings against a throwaway repository, stubbing
   the transport for the merged and unanswerable cases so no `gh` call is made.
3. Extend `docs/loop-drill-runbook.md` with the new subcommand and its failure-reason →
   file blame rows.
4. Update `drive/reference/claims.md` and `skills/drive/SKILL.md` for the mission-grain
   answer and the network-versus-local split between the two grains.
5. Update `CLAUDE.md`'s claim-protocol bullet: replace the "answers for batch units and
   leaves mission units on today's reading" sentence with what is now true, and state the
   evidence that reversed it — three merged mission claims measured 2026-08-26, one
   offered resumable five days after its pull request merged.
6. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) since skill content
   moved, and confirm the freshness gate is clean.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The subcommand proves all four readings and makes no network call.
- `CLAUDE.md` no longer states the reversed sentence and names the evidence that reversed
  it.
- `outputs/` is regenerated and the freshness gate is clean.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh <new-subcommand>` with no credentials in the environment.
- `node scripts/build-plugins/build.mjs && git status --porcelain outputs/` is empty.
- `node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- The drill is operator tooling outside the plugin and assumes the server's full `gh`;
  this subcommand must not, since its whole value is proving the readings without one.
