---
created_at: 2026-09-07T02:38:55+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: hand-off-the-members-that-declare-and-drive-the-rest
merge_policy:
verification_handoff: 
---

# Drive the non-declaring members and hand off the rest

## Overview

PROPOSED. §6 reads the verification axis per unit and routes the **whole** unit
to `handoff` when the reader answers `handoff: true`. With the previous ticket landed, a mixed
unit reaches the route; this ticket makes the route drive the members that declare nothing and
hand off only those that do. The mechanism the split needs mostly exists: the `handoff` route
already opens a pull request with the work pushed, writes a non-droppable `## Handoff`, leaves
undriven tickets stamped in `todo/` and keeps the claim standing (`drive/SKILL.md`, the
half-driven entry path). What changes is which members are the undriven remainder — the ones
that earned the handoff, rather than every member of the unit that contains them.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §6 (the verification axis is read
  before merge policy; the probe's four words; *a run never declares a handoff for its own
  unit*) and the `handoff` entry paths at ~line 194.
- `plugins/workaholic/skills/drive/reference/routing.md` — the route's own contract and the
  `## Handoff` section's rules.
- `plugins/workaholic/commands/implement.md` and `plugins/workaholic/commands/drive.md` — the
  routine-fired ceilings; a rule the run must read to act is inlined there byte-identically.
- `plugins/workaholic/skills/drive/scripts/run-verification-probe.sh` — run at claim time; its
  four words (`clean` / `blocking` / `unmeasured` / `unreadable`) are per unit today and must
  become per member without changing what any word means.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — reads the axis when a ticket moves.
- `CLAUDE.md` — the verification-axis paragraph stating the whole-unit rule.

## Implementation Steps

1. **Reproduce first.** Confirm against the base that a mixed unit
   reaching §6 routes whole: record the reader's `handoff: true`, the single declaring member,
   and that the run drives none of the other members.
2. Read §6 and `reference/routing.md` in full, and the `handoff` entry paths, before editing.
3. Partition at the route from the reading the claim row already carries (previous ticket) —
   never a fresh judgement about what a ticket needs, and never prose read anywhere but the
   declaration itself.
4. Drive the non-declaring members through the ordinary ticket workflow. Leave the declaring
   members in `todo/`, undriven, exactly as the half-driven path already leaves undriven work.
5. Write one `## Handoff` naming **only** the declaring members and quoting each declaration's
   own reason verbatim (or its probe output, for a `blocking` probe). The section must not
   claim the driven members need a person.
6. Run the probe **per declaring member** at claim time, unchanged in meaning: `clean` removes
   that member from the declaring set and it is driven; `blocking` keeps it, with the probe's
   own output and exit status as the reason; `unmeasured` is verified here before it is
   honoured; `unreadable` leaves the declaration standing.
7. A unit whose members **all** declare still takes the handoff route whole, and a unit whose
   members declare **nothing** takes its ordinary route — both byte-identical to today.
8. Report both sets in the run report and in the pull-request body: which members were driven
   and which were handed off, each with its reason.
9. Update `drive/SKILL.md`, `reference/routing.md`, both command ceilings and `CLAUDE.md` in
   the same change, and extend the suite to pin the inlined ceiling text byte-identically.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mixed unit drives every non-declaring member to a pull request and leaves every declaring
  member queued and undriven.
- The `## Handoff` names only the declaring members, each with its own verbatim reason, and is
  non-droppable.
- The finish line is `🟡 Handoff`, the claim stays standing, the pull request stays open, and
  the token is `pending` — unchanged.
- An all-declaring unit and a no-declaring unit route exactly as they do today.
- The run never declares, clears or invents a declaration for its own unit.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all` — the handoff drill extended to the mixed case,
  with a breaker row written against the behaviour.
- `node scripts/test-workflow-scripts.mjs` — the ceiling-text pins across both commands.
- A dry drive of the reproduction mission showing six tickets driven and one left queued.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Acceptance criteria** — the checkable conditions that must hold:

- <proposed>

**Verification method** — the commands/tests/probes that prove them:

- <proposed>

**Gate** — what must pass before approval:

- <proposed>

## Considerations

- The non-goal is explicit in the ask: do not weaken the handoff. A
  declaring member is still handed off, still on its own declaration, still with the claim
  standing — only the members that declared nothing move.
- The pull request now carries work while the unit is still handed off. That is already the
  half-driven path's shape, so no new pull-request state is introduced; state it in
  `routing.md` rather than leaving a reader to infer it.
- Do not resolve the reproduction mission's own `content` conflict as part of this — the ask
  names that as a non-goal.
