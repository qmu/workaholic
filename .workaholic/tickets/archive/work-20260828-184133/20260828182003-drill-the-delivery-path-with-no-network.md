---
created_at: 2026-08-28T18:20:03+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Drill the delivery path with no network

## Overview

PROPOSED. Add `verify-checkin-delivery` to `scripts/e2e/loop-drill.sh`: walk the whole
delivery path over a fixture log spanning several days, with no network, so the channel that
carries every machine finding to a person is provable on demand rather than by waiting for a
tick and noticing nothing arrived.

The unit tests pin `ask-question.sh` in isolation. This drills the **path** — gate, ordering,
step, event, root — which is where the defect actually lived: each part was internally
consistent and the delivery failed in the seams.

## Policies

- `workaholic:implementation` / `policies/testable-design.md` — gaps in reasoning made machine-checkable early
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the new `cmd_verify_checkin_delivery` and its dispatch row
  (the table sits at lines 4947–4970).
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file blame
  table, which every drill carries.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — under drill.
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — under drill.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — under drill, for the
  root's gate.
- `CLAUDE.md` — the drill list in the Routines section names every `verify-*`.

## Implementation Steps

1. **Build one fixture log spanning several days** under a throwaway root, written through
   `log-append.sh`: `human-checkin-ask` lines on earlier days at or above `max_per_day`,
   `human-checkin-held` lines first held on three different days, and none of either on the
   tick's own day. No network, no `gh`, no touch of the working tree.
2. **Drill the five properties the mission promises**, each asserted by name:
   - the **held question lands** — a candidate held on an earlier day is asked on a working
     weekday inside the window, where the current tree refuses it `day_cap`;
   - the **second tick does not re-ask it** — `already_asked`, unchanged;
   - the **drain honours `max_per_tick`** — with more candidates than the per-tick cap, the
     tick asks exactly that many, **oldest-held first**, and the remainder stays held;
   - a **genuinely spent day still holds** — `max_per_day` lines **on the tick's own day**
     still refuse `day_cap` with `hold: true`, so the drill proves the cap was kept and not
     removed;
   - a **tick that delivered nothing supplies its event** and the root carries it, while a
     quiet hour supplies none and posts nothing.
3. **Carry a breaker row**, as every drill here does: a deliberately broken seam that **must
   fail**, firing the moment the day count is unbounded again — point the count at the
   unbounded reader and assert the drill reports failure. A drill that cannot fail proves
   nothing, and this is the exact regression the mission exists to prevent.
4. **Keep the tick's own posting stubbed**: the drill asserts what `render-tick-post.sh`
   answers, never posting to Slack. Every assertion is over script output.
5. **Register it**: the dispatch row beside the other `verify-*` commands, the runbook's
   procedure and blame table, and the drill list in `CLAUDE.md`'s Routines section.
6. Prove it fails on a tree without the repair and passes with it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` passes on the repaired tree.
- It asserts all five properties by name, including that a genuinely spent day still holds.
- Its breaker row fails the drill when the day count is unbounded again.
- It makes no network call, runs no `gh` command, posts nothing to Slack, and leaves the
  working tree untouched.
- The dispatch row, the runbook and `CLAUDE.md`'s drill list all name it.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` — passes.
- The same command against a tree with the repair reverted — fails, naming the unbounded count.
- `node scripts/test-workflow-scripts.mjs` — unaffected and green.

**Gate** — what must pass before approval:

- No network, no `gh`, no Slack post, no working-tree mutation.
- The drill is deterministic: the tick id supplies the day, so it does not pass or fail by the
  date it is run on — the reason `--hour` and `--weekday` are already injectable.

## Considerations

- `loop-drill.sh` is operator tooling outside the plugin and assumes the server's full `gh`
  and `qfs`; this drill must not add a dependency beyond what the file already assumes, and it
  needs none, since every assertion is local.
- Run it on a **weekday and inside the window** by injecting `--hour` and `--weekday`: the
  working-week gate's very first suite run was on a Saturday and reported `off_day` for
  everything, which is exactly why both are injectable.
- The breaker row is the load-bearing part. Write it against the **count**, not against the
  gate's output shape, so a future refactor that keeps the shape and loses the bound still
  fires it.

## Final Report

Development completed as planned. `verify-checkin-delivery` walks the whole delivery path.

- **One fixture log spanning several days**, written through `log-append.sh`: ten
  `human-checkin-ask` lines (`max_per_day` exactly) across five earlier days, holds first
  recorded on three different days in a deliberately anti-alphabetical order, and none of
  either on the tick's own day. No network, no `gh`, no Slack, no touch of the working tree.
- **All five properties the mission promises are asserted by name**, plus the two the drill
  needs to be honest: `checkin_held_lands`, `checkin_not_reasked`, `checkin_drain_order`,
  `checkin_drain_capped`, `checkin_remainder_held`, `checkin_spent_day_holds`,
  `checkin_failure_is_an_event`, `checkin_root_carries_it`, `checkin_quiet_hour_silent`,
  `checkin_breaker`, `checkin_writes_nothing`.
- **The breaker row is written against the count**, as the ticket's Consideration insists: a
  copy of `ask-question.sh` with `asked_today` pointed back at the unbounded reader must
  refuse the held question `day_cap`. A refactor that keeps the gate's output shape and loses
  the bound still fires it.
- **The tick's posting is stubbed out entirely** — every assertion is over
  `render-tick-post.sh`'s answer, never a post — and the drill is deterministic: the day comes
  from the tick id and `--hour 14 --weekday 3` are injected, so it does not pass or fail by
  the date it is run on.
- **Registered in all three places**: the dispatch row and the usage string in
  `scripts/e2e/loop-drill.sh`, the stage table and a new §5s (procedure plus the row → file
  blame table) in `docs/loop-drill-runbook.md`, and the drill list in `CLAUDE.md`'s Routines
  section.

Verification — `sh scripts/e2e/loop-drill.sh verify-checkin-delivery --json`: **pass, 11
load-bearing rows, 0 failed**. It was proved to fail on a tree without the repair: pointing
the day count at the unbounded reader is what `checkin_breaker` does on every run, and the
same substitution against `checkin_held_lands` turns the drill red.
`node scripts/test-workflow-scripts.mjs` is unaffected and green.

### Discovered Insights

- **Insight**: a tick id that fails `log-append.sh`'s own shape check writes **nothing** and
  says so only in its JSON, which a fixture builder discards.
  **Context**: the first draft computed tick ids arithmetically and produced one seven-digit
  time, so the fixture landed nine asks against a cap of ten — and both the day-cap row and
  the breaker row passed for the wrong reason, because nine is under the cap. Fixture tick
  ids are now written out literally, and the comment says why.
- **Insight**: recording an ask under two log lines counts it twice against `tick_cap`.
  **Context**: the gate's `log_step` (`human-checkin-ask-<slug>-<digest>`) already
  prefix-matches the held key, so it is the only line the agent needs; the drill's first
  draft added a second and the drain stopped at three questions instead of five.
