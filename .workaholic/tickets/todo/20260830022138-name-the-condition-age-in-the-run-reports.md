---
created_at: 2026-08-30T02:21:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Name the condition age in the run reports

## Overview

PROPOSED. `/implement` and `/propose` already name `pace`, `expiring`, `arrived`, the base's
health and what is waiting on the operator — each as **evidence, never a verdict**, each moving
no token and gating nothing. Name the condition age in that same voice, and in that voice only.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §1's readings and §7's token table; the age joins
  the readings and adds **no row** to the table.
- `plugins/workaholic/skills/drive/reference/routing.md` — the run report's full field list.
- `plugins/workaholic/skills/propose/SKILL.md` — the run report beside `pace` / `expiring` /
  `arrived` / the operator-facing pull requests.
- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — the one reader both compose.

## Implementation Steps

1. In `/implement`'s report, name the age beside the readings it already carries — once per run,
   not once per unit, on the same ground the base's health and the operator-facing pull requests
   are read once per run: it is a fact about the repository.
2. In `/propose`'s report, name it beside `pace`, `expiring` and `arrived`, with the same
   sentence about why it is evidence: an hourly routine's report is read by nobody on the day it
   matters, which is exactly why nothing there is ever a brake.
3. **It moves no token**, and say so where the other no-token readings say it: a standing blocker's
   age is not a fact about the unit *this* run drove, so `ok` stays reachable over one. Add no row
   to §7's table.
4. **It gates nothing**: no route, no demotion, no claim, no merge, no survey and no refusal reads
   it. State it, so a later reader does not "fix" the omission.
5. A `readable: false` age is reported **as unreadable, by its reason**, and never as *nothing
   standing* — the same rule a degraded base read and a degraded membership read already carry.
6. Name the person the age reaches instead: `/moderate`'s own questions (tickets 3–5), never this
   token.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both skills document the age as a run-report reading, once per run, with the evidence-never-a-
  verdict wording and the explicit moves-no-token / gates-nothing sentences.
- §7's token table gains no row, and no script in the driving or proposing chain reaches
  `condition-age.sh` from a gate, refusal, sort or survey.
- A degraded reading is documented as reported-by-reason.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a row asserting no gating call site reaches the
  reader (the shape the base-health and publication pins already use), and a prose row over the
  moves-no-token sentence.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- Suite and build/verify pass; `outputs/` regenerated and committed.

## Considerations

- The tempting error is to withhold `ok` on the grounds that an old blocker is blocking the queue.
  It is — and `/implement` may not ask, so a withheld token would report a failure hour after hour
  into a report nobody opens while the person who can act is reached by the tick's question. This
  is the reasoning `backlog_all_excluded`, the base's health and the operator-facing pull requests
  each already record, and it applies here unchanged.
- Documentation-only in the plugin skills, so `outputs/` must be rebuilt in the same change.
