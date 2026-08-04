---
created_at: 2026-08-04T22:13:47+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission: propose-at-the-capture-seam
merge_policy:
---

# Judge and propose inside the capture session

## Overview

Per FB `20260804221328` (the developer's ruling): the [Propose] capture routine is
not fixed to "record feedback only". Its session receives the ask with full
context in hand, so the judgment — the same conservative bar `/propose` states —
happens **there**, and the session emits in **one publish-tree PR** the feedback
record together with whatever the judgment warrants: a mission with its ticket
set, a loose ticket, or the record alone. Merging that PR approves both at once.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:planning` / modeling policies — the judgment lives where the information is; a later sweeper re-deriving it from artifacts is a weaker copy

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — re-scope: the primary mode takes the ask and the just-written record as direct input; the judgment bar (instruction originates; missions/queue/commits constrain; silence = record-only) and the cardinality rule (mission ≥2 / loose ticket / drop) keep their exact substance
- `plugins/workaholic/commands/propose.md` — becomes "propose from what is in hand": an ask, a record file, or the session context; no cursor step, no window step
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the [Propose] template's prompt: record, judge, scaffold in the same publish tree when warranted; drop the "do NOT run /propose here" prohibition (its premise — the window — is retired by the sibling ticket)
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh`, `scaffold-proposed-ticket.sh`, `mission/scripts/link-acceptance.sh`, `check-floor.sh` — unchanged writers the session calls; verify they compose in one publish tree with the feedback record
- `plugins/workaholic/skills/propose/scripts/list-proposed-refs.sh`, `survey-state.sh` — the dedup set and the state constraints survive (dedup still vetoes re-asks; state still shrinks proposals); `survey-state.sh` loses its cursor argument in favor of an explicit range or none

## Implementation Steps

1. Rewrite `propose/SKILL.md`'s flow: input = the ask + record in hand; read the
   state constraints from `main` (`survey-state.sh`), dedup against
   `list-proposed-refs.sh`; decide cardinality; scaffold into the **open publish
   tree beside the record**; stamp acceptance links; one `publish-tree-pr.sh`
   call carries record + proposal.
2. Update `commands/propose.md` to the in-hand contract; a bare `/propose`
   with nothing in hand reports `nothing_in_hand` instead of sweeping.
3. Update the [Propose] routine template's prompt to the record-judge-scaffold
   sequence, with record-only named as the judged fallback, and the `[Proposal]`
   PR-title prefix kept.
4. Keep the floor and the loose form exactly as shipped (`check-floor.sh`,
   `--loose` with mandatory `feedback:` refs).
5. Hermetic tests: one-PR composition (record + mission + tickets in a single
   commit), record-only fallback, dedup veto of a repeated ask.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A single publish-tree PR can carry the record plus a floor-satisfying mission and its tickets, links stamped
- Record-only is produced only by the judgment, never by a mechanical inability to see the record
- The judgment bar's substance (originate/constrain/veto, cardinality, floor) is unchanged in meaning

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new composition cases green)

**Gate** — what must pass before approval:

- Hermetic suite green; `build.mjs`/`verify.mjs` clean (propose/feedback skills ship in the bundle); docs updated in the same change

## Considerations

- The sibling ticket removes the window machinery; drive this one first so the
  new flow exists before the old one is deleted, and the branch never has a gap
  where nothing can propose.
- The live [Propose] routine needs a /setup-routines refresh after merge — a
  human act, out of scope here.

## Final Report

Development completed as planned. The propose skill's flow, the command, and the
`[Propose]` routine template now take the ask in hand as their input; the record
and whatever the judgment warrants leave in one publish-tree pull request, and
record-only is the third row of the cardinality table rather than a mechanical
silence. `survey-state.sh` lost its required cursor argument for an optional
range that reports how it was chosen. Three hermetic cases were added
(composition, record-only, dedup input at the seam) plus three on the survey's
new range contract; the suite is green at 2190 (baseline on `main`: 2169).

### Discovered Insights

- **Insight**: `publish-tree-pr.sh`'s `branch_collision` recovery does not work as
  its own detail describes. The detail says "the commit is intact in the publish
  tree and the next call succeeds", but the next call runs `commit.sh` first,
  which stages nothing because the commit was already made, so it reports
  `nothing_to_commit` and never retries the push. The artifact is then stranded
  in the publish tree with no scripted way out.
  **Context**: The branch name is minted per second, so two publications in the
  same second collide — plausible once several capture sessions run in a fleet.
  Measured while writing the composition test, which now spaces its publishes
  rather than relying on the advertised retry. Recorded as a concern on this
  branch's story rather than fixed here: it belongs to `workaholic:branching`,
  not to the propose seam.
- **Insight**: The dedup set cannot key on the record a capture session just
  wrote — nothing references it yet, by construction. The veto therefore keys on
  the records an ask *restates*, which the seam reads from the base through
  `list-proposed-refs.sh` before it scaffolds anything.
  **Context**: Under the retired window model the cursor did most of the
  idempotence work and dedup was the backstop. At the capture seam dedup is the
  whole mechanism, so where it is read from and when it is read both matter.
