---
created_at: 2026-08-22T15:52:50+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: tell-an-unanswered-question-from-an-answered-one
merge_policy:
verification_handoff: 
---

# Read whether an asked question's subject is still live

## Overview

`ask-question.sh`'s `already_asked` gate matches on the step id derived from the question's
content key and refuses a second ask. That is exactly what ticket `20260819061902` fixed it to
do, and it must keep doing it for ordinary questions.

What it cannot currently express is the difference between **asked and settled** and **asked
and still blocking**. It reads one fact — was this key asked before — from the tick log, and
nothing else. The tick already re-derives every finding each hour, so the information needed to
tell the two apart is produced every run and then discarded.

This ticket adds only the reading. What is done with the answer is the sibling ticket's
subject, so this one can land and change no observable behaviour.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the four gates; `already_asked`
  is the one that gains the second axis. Read its header before touching it.
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — lines ~82-94, the held /
  already-asked read over `log-read.sh --step-prefix human-checkin-ask-<key>`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the reader; whether the liveness
  fact belongs in the log or is re-derived is decided here.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the only writer of the log.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where each step's findings are produced,
  and therefore where a question's subject can be checked against this tick's own output.

## Implementation Steps

1. **Reproduce before designing.** Post a question through the gate, leave it unanswered, and
   run the tick again; confirm from `ask-question.sh` and `step-human-checkin.sh` — not from the
   report — that the second run refuses on `already_asked` with no reference to whether the
   subject still holds.
2. **Localize.** Confirm `ask-question.sh` is the only gate consulted, and that the liveness
   fact exists in the same tick's step output.
3. Decide where the liveness answer comes from and write the reason down: re-derived from this
   tick's own step findings (no new state, costs nothing, but only works for findings a step
   still produces), or carried on the log line (durable, but adds a field the log did not have).
   Prefer re-derivation unless the measurement shows it cannot answer.
4. Expose it as a value the gate can read — an asked question resolves to `settled` or `live`,
   with `unknown` as an honest third answer when the tick could not tell. `unknown` must not
   silently mean either of the other two.
5. Change **no** observable behaviour in this ticket: the gate still refuses a second ask. Only
   the answer becomes available.
6. Update `SKILL.md` and `reference/workflow.md` for the moderate skill in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An asked question resolves to `settled` / `live` / `unknown`, and `unknown` is distinct from
  both.
- The `already_asked` refusal is unchanged in this ticket — no question is asked twice yet.
- The log stays append-only; if a field was added, no existing line is rewritten.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A two-tick hermetic run asserting the resolved value for a question left unanswered, and for
  one whose subject was resolved between the ticks.

**Gate** — what must pass before approval:

- All three criteria hold, the suite and the moderate drill are clean, and the tick's observable
  posting behaviour is byte-identical to before.

## Considerations

- The `unknown` answer is load-bearing, not a placeholder: a step that degraded cannot report
  its finding, and treating that as `settled` would re-create the exact silence this mission
  exists to end.
- Do not make the gate re-read the repository for every asked key — that turns an hourly tick
  into a scan. The tick's own findings are the source.
