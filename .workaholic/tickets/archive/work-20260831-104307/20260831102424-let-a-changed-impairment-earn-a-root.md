---
created_at: 2026-08-31T10:24:24+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260831102424-read-the-impairment-off-the-tick-s-own-rows.md
mission: name-the-steps-a-tick-could-not-read
merge_policy:
verification_handoff: 
---

# Let a changed impairment earn a root

## Overview

PROPOSED. The previous ticket names the impairment on every root **that posts**. The worst
case measured is the one where nothing posts at all: with `questions == 0`, no morning
digest and no delivery failure, the gate emits `post: false` (`idle` or `no_question`) — so
a tick with six blind steps is byte-identical, to the operator, to a quiet hour. That is the
silence the operator found four days later by asking.

This ticket adds the **fourth gate**, on the precedent the third one set: the question
gate's own expression is left untouched and a second condition is OR'd beside it. An
impairment whose reading **changed since the previous tick** earns a root with no question;
an unchanged one does not.

**Where the diff belongs, and where it does not.** The line is outside the diff (it must be
said every tick, until it clears). The **gate** is inside it — exactly as `delivery_failure`
is set inside the diff loop — so a standing impairment does not open a root every hour for
days, which is precisely what `📦 Release Preparation` was retired for. Appearing and
clearing both break silence; persisting does not.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a mechanism that could not read must never announce quiet

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the three-condition
  gate (`QUESTIONS`, `digest_ready`, `delivery_failure`) and the `idle` / `no_question`
  early returns.
- `plugins/workaholic/skills/moderate/reference/workflow.md` §"The post this step
  produces" — states the gate; must move with it.

## Implementation Steps

1. Reproduce: a tick with `impaired_count > 0` and `--questions 0` emits `post: false`.
   That is the case the operator could not see, made concrete.
2. Derive **`impairment_changed`** by comparing this tick's impaired set against the
   previous tick's, read from the log the renderer **already reads** for the diff — no new
   store, no cursor, no field on any artifact.
3. Compare the set of `(step, status, reason)` triples, not the count: six steps degraded
   for one reason and six for another are different facts, and a count would call them the
   same. Clearing to empty is a change like any other.
4. OR `impairment_changed` beside `QUESTIONS`, `digest_ready` and `delivery_failure` in the
   gate, leaving all three untouched — the same shape the third gate used.
5. When the impairment is what earned the root, `root_text` still renders normally; the
   clause from the previous ticket is what carries the finding, so no second wording exists.
6. Give a root earned this way its own `reason` value so a reader of the JSON can tell it
   from `ready` earned by a question.
7. Handle the boundaries: `no_previous_tick` and `no_log` still post nothing (everything
   would read as changed, and a mechanism that could not read must not announce), and a
   first-ever impairment on the first tick after a readable predecessor does earn a root.
8. Update `reference/workflow.md`'s gate wording in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick whose impaired set differs from the previous tick's posts a root even with
  `questions == 0`, and that root names the impaired steps.
- A tick whose impaired set is **unchanged** from the previous tick and has no question, no
  digest and no delivery failure posts nothing.
- An impairment that **cleared** (non-empty to empty) earns exactly one root, then silence.
- `no_previous_tick` and `no_log` still post nothing, unchanged.
- The question, digest and delivery-failure conditions are byte-identical to the pre-change
  expressions.

**Verification method** — the commands/tests/probes that prove them:

- A three-tick fixture: healthy → impaired → impaired(same) → healthy, asserting
  post/silent/silent-until-clear/post.
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The middle tick of the fixture is silent. Without that this is the hourly status root
  this repository has retired twice.

## Considerations

- Posting on **every** impaired tick regardless of change was weighed against the ask's own
  words ("every tick, until it clears") and split: the **statement** is every tick, the
  **post** is on change. The operator gets the standing impairment on every root they see,
  and does not get twenty-four identical roots a day. If they want the stricter reading,
  the change is one condition and is recorded here as the deliberate alternative.
- Escalating a long-standing impairment into a `human-checkin` question was considered and
  is **out of scope**: it needs a subject key and an age reading, and this mission's
  Experience is about the post. It belongs to a later ask if the post proves insufficient.
- `impairment_changed` deliberately does not consult `condition-age.sh`: no gate in this
  repository may read an age, and this is a gate.

## Final Report

Development completed as planned, with one implementation step resolved against the tree
rather than as written. That resolution is stated in full below.

Reproduced first: a tick with three impaired steps and `--questions 0` emits
`post: false, reason: idle` — the operator's four-day silence, made concrete.

`IMPAIRMENT_CHANGED` is derived by comparing this tick's impaired set against the previous
tick's, read from the log the renderer already reads for the change diff. No new store, no
cursor, no field on any artifact. It is OR'd beside `QUESTIONS`, `digest_ready` and
`delivery_failure`, all three left byte-identical. A root earned by the impairment alone
reports `reason: ready_impairment`.

### The one resolved ambiguity: the triple is `(step, status, stabilized summary)`

Step 3 specifies comparing `(step, status, reason)` triples. **`reason` never reaches the tick
log.** `log-append.sh` writes `- <step>: <status> — <summary>` and nothing else, and
`log-read.sh` returns `{day, tick, step, status, summary}` — so the previous tick's reason is
not recoverable from the only cross-tick memory there is, and step 2 forbids adding a store
for it. Confirmed by reading the writer before coding against it.

The comparison therefore uses the log's `summary` as the third term. It is the richest
per-step text the previous tick left, it is already what the change diff compares, and it
moves when the cause moves. The resulting set is **strictly finer** than `(step, status)`
alone, so the resolution errs toward opening a root rather than toward silence — the safe
direction for a reading whose whole purpose is that an impairment must never look like a
quiet hour. What is lost is narrow and stated: a step whose `reason` moves while its `status`
*and* its `summary` both stay identical will not earn a root, though it is still named on
every root the tick posts for any other cause.

`stabilize()` is applied to both sides. Two steps embed a timestamp or a sha in their summary
and would otherwise differ every tick by construction — that would fire this gate hourly and
reproduce the exact defect it exists to avoid. Proved with a fixture whose summary carries a
moving ISO8601 timestamp: silent.

### Verified

A five-tick fixture, each tick logged through the real writer:

| Tick | State | Expected | Got |
| --- | --- | --- | --- |
| 09:45 | healthy | silent | `post: false, idle` |
| 10:45 | impairment appears | root, 0 questions | `ready_impairment`, names both steps |
| 11:45 | impairment unchanged | **silent** | `post: false, idle` |
| 12:45 | cleared | exactly one root | `ready_impairment`, `✅ every step read this tick` |
| 13:45 | still healthy | silent | `post: false, idle` |

The 11:45 row is the Gate, and it holds. Beside it: the same unchanged impairment *with* one
question posts a root whose reason is `ready` (not `ready_impairment`) and whose clause still
rides; `no_previous_tick` and `no_log` still post nothing, both carrying the impairment in the
JSON while posting silence.

`node scripts/test-workflow-scripts.mjs`: 5422 passed, 0 failed.
`node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`: clean.
`reference/workflow.md`'s gate wording moved in the same change.

### Discovered Insights

- **Insight**: The tick log is the loop's only cross-tick memory and it is **lossier than the
  run report**: `status` and `summary` survive, `reason`, `event` and `needs_agent` do not.
  **Context**: Any future reading that wants to compare this tick against the last is bounded
  by those two fields. Two designs in this mission needed the previous tick and both had to be
  written against `summary`; a third that needs `reason` cross-tick would have to change
  `log-append.sh`'s line format, which is append-only history and not a free change.

- **Insight**: A gate that posts and a clause that states are separate decisions about the
  same fact, and this file now holds one of each for the impairment — outside the diff for the
  statement, inside it for the gate.
  **Context**: Reading either alone makes the other look wrong. The pair is what satisfies
  both halves of the ask ("every tick, until it clears") without becoming the hourly status
  root retired twice, and a later reader tempted to "make them consistent" would break exactly
  one of the two properties.

- **Insight**: A root earned by a *clearing* renders nothing about its own cause unless the
  clause has a cleared state — head, no body, which is the content-free status line.
  **Context**: The ticket's acceptance requires a root on clearing and its step 5 says no
  second wording exists. Both are satisfied by giving the one clause two states rather than
  adding a second clause; the distinction is worth keeping if the wording is ever revisited.
