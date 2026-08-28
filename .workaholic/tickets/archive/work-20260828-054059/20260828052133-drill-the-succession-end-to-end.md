---
created_at: 2026-08-28T05:21:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# Drill the succession end to end

## Overview

The succession spans the close, the reading, the announcement, the carry, the attribution and
the next `/propose` tick — six seams no single unit test walks. Drill it end to end with no
network, as every other loop property in this repository is drilled.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — NEW verb `verify-succession`
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame table
- `plugins/workaholic/skills/strategy/scripts/closing-residue.sh` — read in the walk
- `plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh` — the carry's wiring point the breaker targets

## Implementation Steps

1. Add `verify-succession` over a **git-backed** fixture with the transport stubbed and no network,
   following `verify-arrival`'s and `verify-residue`'s shape.
2. Walk: close a direction → read the leaving → announce a successor by explicit slug → the carried
   refs land on the successor → `attributed-work.sh` attributes the predecessor's work to it →
   `/propose` proposes against it on the next tick.
3. Carry a **breaker row** that fires when the carry is wired at `create.sh` rather than at the ask
   line, so the drill is proved able to fail.
4. Assert the negatives too: nothing closed a direction on its own reading, nothing authored one,
   and the strategy-touching publish did not auto-merge.
5. Register the verb in the usage string and the dispatch table beside the existing ones.
6. Document the procedure and the blame table in the runbook.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-succession` passes with no network
- The breaker row fails when the carry is wired at `create.sh`
- The drill asserts that nothing closed, authored or auto-merged a direction

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-succession`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill makes no network call and needs no credential
- The runbook names the verb and its blame table

## Considerations

- The drill is operator tooling outside the plugin and assumes the server's full `gh` and `qfs`,
  as every other verb does.

## Final Report

Development completed as planned.

`sh scripts/e2e/loop-drill.sh verify-succession` walks all six seams over a git-backed fixture
with no network: close a direction, read what it leaves, announce a successor by explicit
slug, land the carried refs, attribute the predecessor's work to the successor, and see
`/propose` propose against it. It also asserts the negatives — the readers reach no writer of
the strategy artifact, and a strategy-touching publish is left open under
`WORKAHOLIC_AUTO_MERGE=1`. The breaker row
`succession_carry_is_wired_at_the_ask_line` proves the drill can fail, by running the same
detection against a copy of `create.sh` with the succession wired into it. The verb is in the
usage string, the dispatch table and the runbook's blame table.

### Discovered Insights

- **Insight**: the drill's fixture must be a real git repository, not a bare file tree.
  **Context**: `landed[]` is a `git log --since` read, so a file tree makes every attribution
  row vacuously true — the same reason `verify-arrival` and `verify-residue` are git-backed.
