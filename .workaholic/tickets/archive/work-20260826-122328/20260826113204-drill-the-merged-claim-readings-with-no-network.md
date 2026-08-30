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

## Final Report

Development completed as planned. `sh scripts/e2e/loop-drill.sh verify-merged-claim` proves all
four readings — merged batch, merged mission, live, unanswerable — over a real squash-merged
fixture with the transport stubbed on `PATH`, so no `gh` call is made and no credential is
needed.

**The squash is the whole fixture, and the drill asserts that before anything else.** A normal
merge takes `base..ref` to zero and `claims_scan` drops the branch before any verdict is
reached, so the drill would pass while proving nothing. `merged_claim_fixture` checks the branch
is still ahead of the base and fails the whole stage if it is not.

**The two grains are answered by different means and the drill keeps them apart.** The batch
claim is answered from the tree with the transport stubbed to return nothing, which is what
proves it needs no network; the mission claim is answered only by a merged pull request, because
`mission.md` is never archived. The `live` row sits between them so the mission-grain verdict
cannot pass by being a blanket answer.

**The `unanswerable` row is the one the drill exists for.** It compares the verdict under a
refusing stub against the verdict the same claim had with the lookup answering `not_merged`, and
asserts the branch is named in `merged_lookup_unanswered` with its reason. A wrong `merged`
releases work still in flight; a wrong `in flight` only delays a claim.

**The documentation half was not a backstop.** `CLAUDE.md` said `superseded` "answers for batch
units and leaves mission units on today's reading", which this mission reverses; that sentence
is replaced across `CLAUDE.md`, `drive/SKILL.md` and `drive/reference/claims.md`, each naming
the evidence that reversed it — three merged mission claims measured 2026-08-26, one offered
resumable five days after its pull request merged. `docs/loop-drill-runbook.md` gains §5i with
the per-row blame table and the quick-reference entry.

**One pre-existing flake was fixed rather than tolerated.** The stalled-units test's second
claim collided on the claim branch name, which is minted from the clock to the second — the
suite already has `tickSecond()` for exactly this and the new fixture had not used it. The claim
is now asserted to succeed, so the next occurrence names its own cause instead of failing on a
JSON parse.

### Discovered Insights

- **Insight**: `git merge --squash` is a two-step operation (`merge --squash`, then `commit`),
  and chaining two of them in a single `&&` list leaves the second merging against a state the
  first has not finished committing. Splitting them into separate subshells was what turned the
  first version of this fixture from a `shallow_history` misreading into a working drill.
  **Context**: Any fixture needing several squash merges should do one per subshell. The symptom
  was not a git error — the drill reported a plausible-looking wrong verdict, which is the worst
  possible failure for a tool whose job is to tell right verdicts from wrong ones.
- **Insight**: A claim commit must *touch* the file it stamps. The artifact list is "files this
  commit touched that still carry the stamp at the tip", so a claim commit that stamps a file in
  an earlier commit reports an empty artifact list and every downstream verdict collapses.
  **Context**: The first fixture used `--allow-empty` plus a later amend and produced claims with
  no artifacts. One commit that both writes the stamp and carries the `Unit:` trailer is the
  shape `claim.sh` actually creates and the only one worth drilling against.
