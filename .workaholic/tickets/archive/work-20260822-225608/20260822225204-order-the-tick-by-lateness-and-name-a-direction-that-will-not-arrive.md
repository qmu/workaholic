---
created_at: 2026-08-22T22:52:04+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: read-a-strategy-s-pace-against-its-date
merge_policy:
verification_handoff: 
---

# Order the tick by lateness, and name a direction that will not arrive

## Overview

With the sibling landed, the survey knows which directions are behind. This ticket spends that:
the tick advances the late ones first, and a direction that will not arrive is **said**, not left
to silence.

The second half is the one that matters. Today a starving direction produces no signal at all —
every gate fires correctly and reports correctly, and the sum of twenty correct hourly refusals
is that nobody notices a direction has not moved for a day. That was measured with `over_cap`,
which reported itself by name every single tick and still hid a day of starvation.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the `sort_by(days_to_target)`
  ordering and the `refused[]` list.
- `plugins/workaholic/skills/propose/SKILL.md` — the gate list, and the record of why `over_cap`
  was retired (a per-tick refusal reads as a delay; twenty of them read as nothing).
- `plugins/workaholic/commands/propose.md` — what the run reports.
- `plugins/workaholic/skills/workaholify/routines/propose.md` — the routine's own reporting; a
  new surface must be authorized there if one is added.

## Implementation Steps

1. Resolve the `## Open Decisions` item below before writing code; record the ruling and its
   reasoning in the Final Report.
2. **Reproduce.** Take two eligible strategies, one late and one on course, and confirm the tick
   treats them identically today.
3. Order eligible strategies by **lateness first**, then by `days_to_target` as it does now. A
   tick that dies partway must have advanced the direction least likely to arrive.
4. Report a direction that will not arrive, by name, with what the reading was based on. This is
   the run's report — not a new Slack post — unless the Open Decision rules otherwise.
5. Keep every gate exactly as it is: this changes order and reporting, never eligibility. A late
   direction that is `work_waiting` is still `work_waiting`.
6. Keep `unknown` out of the lateness ordering: a direction whose pace could not be read must not
   be promoted or demoted on a guess. Order it as it is ordered today and say the reading failed.
7. Update `propose/SKILL.md`, `commands/propose.md` and `CLAUDE.md` in the same commit.

## Open Decisions

- **Where a "will not arrive" reading is said.**

  Sources read: `workaholic:propose` (the run reports every refusal by name and posts **nothing**
  to Slack — `mcp: []` on the template, and the record that a Slack copy would be the same noise
  twice because the issue's assignee is already notified); `workaholic:notify` (*an event earns
  its post*, and the retirement of `🔧 Needs a decision` and `📦 Release Preparation` on the
  ground that a status line addressed to nobody is noise whatever its dedup key); this
  repository's 2026-08-22 finding that a correct per-tick refusal repeated twenty times is
  invisible. Together these establish that a *status* line is refused and that repetition is not
  visibility — they do not settle where a lateness reading belongs.

  - **(a) The run report only.** No new surface, consistent with `/propose` posting nothing. Cost:
    the run report is read by whoever opens the session, which for an hourly routine is nobody
    on the day it matters — the exact invisibility this ticket exists to end.
  - **(b) Into the proposal issue it opens.** The direction is late *and* a proposal is being
    made, so the reading rides an artifact a person already receives. Cost: says nothing when the
    direction is late and **gated**, which is the case that starves.
  - **(c) A question through `/moderate`'s check-in.** The tick that asks humans things asks this
    too, addressed to the strategy's assignee, once. Cost: couples two routines, and `/propose`
    would have to leave the finding somewhere the tick reads.

  The driving session rules explicitly and records why. It may not pick silently, and it may not
  invent a fourth surface without saying so.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Eligible strategies are ordered late-first, with `days_to_target` as the tie-break.
- A direction that will not arrive is reported by name, on the surface the Open Decision ruled.
- A direction whose pace is `unknown` is neither promoted nor demoted, and the failed reading is
  said.
- No gate's eligibility changes; a late direction that is gated stays gated.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- Fixtures: late+eligible, on-course+eligible, late+gated, unknown-pace.

**Gate** — what must pass before approval:

- All four criteria hold, the suite and the propose drill are clean, and the Open Decision is
  resolved in the Final Report.

## Considerations

- Drive this after its sibling; without the pace reading there is no lateness to order by.
- The temptation is to make lateness *lift* a gate — to propose against a late direction even
  though its work is in flight. Do not: that would produce two proposals for one direction, which
  is what `work_waiting` exists to prevent, and the answer to "the work is in flight but not
  moving" is not more proposals.
