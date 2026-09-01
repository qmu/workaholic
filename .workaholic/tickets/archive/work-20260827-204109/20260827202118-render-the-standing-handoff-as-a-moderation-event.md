---
created_at: 2026-08-27T20:21:18+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Render the standing handoff as a moderation event

## Overview

PROPOSED. Every `/moderate` step supplies `event` beside its log-facing `summary`: the summary
is the audit trail a maintainer reads, the event is the phrase the hourly `🔎 Moderation` root
renders for a person scanning a channel. A step with **no** event renders no line at all, which
is the independent guard against a nothing-happened line reaching the root even when the change
diff calls the step changed.

`handoff-units` must supply one, and only when a standing handoff exists. A tick with none
renders nothing.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the root carries repository events, never the tick's bookkeeping

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — the `emit` helper's
  fifth argument.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the singular/plural
  event pair to follow, and the empty-event-on-`ok` path.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the renderer, and the
  normalisation (a timestamp, a bare hex object name, a clock time — and only those) that the
  summary must not defeat.
- `plugins/workaholic/skills/moderate/SKILL.md` — where the step's contract is stated.

## Implementation Steps

1. Supply `event` only on the branch where at least one standing handoff was found; leave it
   empty on the `ok`-with-nothing path and on every degraded path.
2. Word it as a repository event, not a counter: what is true of the repository is that a
   finished unit is waiting on a named human act. Follow the singular/plural pair
   `step-undelivered-units.sh` uses.
3. Keep the reason and the pull request **out** of the event: the root line links the item and
   the question beneath it carries the detail. A root line that restates the question is the
   duplication the two-speech-act design exists to avoid.
4. Confirm the summary is stable across ticks for an unchanged finding — no age, no timestamp —
   so the change diff does not mark the step changed every hour by construction.
5. Verify the whole rendering end to end: a tick with a standing handoff renders one line
   linking the unit; a tick with none renders no line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick with one or more standing handoffs renders exactly one root line for this step
- A tick with none, or a degraded read, renders no line at all
- The step's summary for an unchanged finding is byte-identical across consecutive ticks
- The event names a repository event, not the tick's counters

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Render two consecutive ticks over an unchanged fixture and assert the second is not
  reported as changed

**Gate** — what must pass before approval:

- The hermetic suite passes and no line appears on a quiet tick

## Considerations

- The gate on the root is a **question**, not a change: a tick whose only news is this event
  and which has no question to ask posts nothing. That is correct and should not be "fixed" —
  the standing handoff always carries its question unless the ledger has already spent it.
- Once the key is spent, later ticks still see the finding and still render the event while
  asking nothing. Check that this does not reintroduce an hourly restatement; if it does, the
  event belongs only on the tick that asks.

## Final Report

`step-handoff-units.sh` supplies `event` as the `emit` helper's fifth argument, **only** on the
branch where at least one standing handoff was found and could be named. The `ok`-with-nothing
path, the reason-unresolvable path and every degraded path leave it empty, so the renderer emits
no line at all — the independent guard, working regardless of what the change diff decides.

Worded as a repository event on `step-undelivered-units.sh`'s singular/plural pair: *a finished
unit is waiting on a verification only a person can run* / *N finished units are waiting on
verifications only a person can run*. The declared reason and the pull request are deliberately
**out** of it — the root line links the item, the question beneath it carries the detail.

**The Consideration is answered by construction, and checked rather than assumed.** Once the
`handoff-unit:<unit>` key is spent, later ticks still see the finding, and render nothing:
`render-tick-post.sh` calls a step changed when its **summary** differs from the same step's an
hour ago, and this summary is counts only — no age, no timestamp, nothing the normalisation would
have to strip. So the event does not need to be restricted to the tick that asks.

Verified end to end over a scratch tick log, three consecutive ticks:

- unchanged summary + event → `change_count: 0`, no root line (`root_text` is the header alone)
- changed summary + event → `change_count: 1`, exactly one line, the event verbatim
- no standing handoff (empty event) → `change_count: 0`, no line

`node scripts/test-workflow-scripts.mjs` — 4111 passed, 0 failed. The step's contract, including
the event rule, is stated in `moderate/reference/workflow.md` §21.
