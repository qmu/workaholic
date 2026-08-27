---
created_at: 2026-08-27T01:20:35+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Never report ok over an undelivered unit

## Overview

`/implement`'s terminal token is `ok` only when nothing claimable remains and the survey was
current and readable — the `/goal /implement ok` contract. A unit the loop finished and could not
deliver satisfies that today: its queue is drained, its claim is excluded, nothing is claimable,
and the run reports `ok` while its work sits at an open pull request nobody was told about.

Two states must be told apart and only one of them moves the token:

- A unit stopped by a **transport refusal** is outstanding work. It forbids `ok`.
- A unit held at its pull request by a **`hard` (`secret`) or `confirm` (`leak`) scan finding** is
  a human's business, exactly as it is today. It leaves `ok` exactly as it is.

The precedent is `report_incomplete`, which already forbids `ok` on the same grounds (a dead
run's remains, not a unit waiting on a person) — and `claimed_superseded`, which deliberately does
**not**, because a claim holding no work is the opposite of outstanding work.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a completion signal never covers
  incomplete work

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §7's terminal-token table and its
  `report_incomplete` / `claimed_superseded` precedents. **Read §7 whole**: which readings move the
  token and which deliberately do not is stated there, and the distinction is the ticket.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — where the exclusion reasons are
  produced (see the sibling ticket that splits them).
- `plugins/workaholic/skills/drive/reference/routing.md` — the demotion doctrine: a scan finding
  holding a pull request is not a failure of the run.
- `plugins/workaholic/skills/release-scan/scripts/gate-decision.sh` — the severity tiers
  (`hard` / `confirm` / `override_only`) that decide which of the two states a held pull request
  is in.

## Implementation Steps

1. Read §7's token table and list every reading that currently forbids `ok`, so this is added as a
   sibling rather than as a second mechanism.
2. Forbid `ok` while any unit this run finished sits undelivered on a transport refusal, keyed on
   the outcome the sibling ticket records rather than on a re-derivation.
3. Leave the scan-held case exactly as it is — `hard` and `confirm` findings still let the run
   report `ok`, because that pull request is waiting on a person by design.
4. Name the withheld token's reason in the run report, so a run that is not `ok` says which unit
   and which refusal.
5. Update §7 and `CLAUDE.md`'s `/implement` row in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run whose unit was refused its merge by the transport does not report `ok`, and names the unit
  and the refusal.
- A run whose only open pull request is held by a `hard` or `confirm` scan finding reports `ok`,
  unchanged.
- No other reading's effect on the token moves.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Walk both cases over a fixture and compare the terminal token.

**Gate** — what must pass before approval:

- The hermetic suite passes and the scan-held case is byte-identical to today's behaviour.

## Considerations

- `backlog_all_excluded` deliberately **moves no token** (§7's table belongs to one mission at a
  time). This ticket does not reverse that; it moves the token on a unit *this run* finished, which
  is a different fact from a survey that could offer nothing.
- Getting this wrong in the permissive direction restores today's silence; getting it wrong in the
  strict direction makes `ok` unreachable and trains the operator to ignore the token. The
  scan-held carve-out is what keeps it reachable, so implement it in the same change, not after.
