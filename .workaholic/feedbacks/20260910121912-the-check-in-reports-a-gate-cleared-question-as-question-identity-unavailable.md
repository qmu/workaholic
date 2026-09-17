---
type: Feedback
title: The check-in reports a gate-cleared question as question_identity_unavailable
kind: insight
source: development
subject: observer_ai:moderate
created_at: 2026-09-10T12:19:12+09:00
author: a@qmu.jp
supersedes: 
---

# The check-in reports a gate-cleared question as question_identity_unavailable

Source: the `/moderate` tick `20260910-030251` on this repository, acting on the `human-checkin`
step's `needs_agent` item. Every command below was run in this checkout at that tick and its
output is quoted verbatim.

## What was measured

`run-planned.sh` returned this `human-checkin` payload — three candidates, all held, every one of
them carrying the same reason:

```
"summary":"outside the 22-08 Asia/Tokyo quiet window — 3 candidate(s): 0 delivered, 3 held (none)"
"held":[{"key":"direction-expiring:an-autonomous-improvement-loop-run-by-the-routines",
         "legacy_slug":"direction-expiring-an-au-16258524","reason":"question_identity_unavailable"},
        {"key":"","legacy_slug":"handoff-unit-report-each-3010914417","reason":"question_identity_unavailable"},
        {"key":"","legacy_slug":"stuck-2034760083-1352606206","reason":"question_identity_unavailable"}]
```

The first entry carries a **non-empty `key`**: the preimage was recovered from the registry, in the
very same object that says the identity is unavailable. Asking the gate about that key, with the
hour and weekday the step itself passes and with no other argument the step does not pass:

```
$ ask-question.sh --root . --tick 20260910-030251 \
    --key direction-expiring:an-autonomous-improvement-loop-run-by-the-routines --hour 12 --weekday 4
{"ask": true, "key": "direction-expiring:an-autonomous-improvement-loop-run-by-the-routines",
 "log_step": "human-checkin-ask-direction-expiring-an-au-16258524", "mention_email": "",
 "asked_this_tick": 0, "asked_today": 0, "window": "22-08 Asia/Tokyo"}
```

`question-state.sh` answers `never_asked` for the same key, and `question-liveness.sh --step
direction-health` answers `live`. So the question is identified, live, and cleared by every gate,
and the step reports it under the one word that says it could not be identified at all.

## Where it comes from

`skills/moderate/scripts/step-human-checkin.sh`, the held loop. `hold_reason` is initialised to
the sentinel and is only ever reassigned in the gate's *refusal* branch:

```sh
hold_reason='question_identity_unavailable'
if [ -f "$GATE" ] && [ -n "$full_key" ]; then
    gout=$(sh "$GATE" ... --key "$full_key" --hour "$HOUR" --weekday "$WEEKDAY" ...)
    case "$gout" in
        *'"ask": true'*) gate_can_ask=true ;;
        *) hold_reason=$(printf '%s' "$gout" | sed -n 's/.*"reason": "\([a-z_]*\)".*/\1/p' | head -1) ;;
    esac
```

On `ask: true` the sentinel survives into the emitted entry. The step's own header documents the
field as `"held":[{"key":"<slug>","reason":"<the gate's own refusal word>"},...]`, and a cleared
gate has no refusal word — so the field has no honest value for this case and silently keeps the
one reserved for a preimage that could not be recovered.

## Why it matters

Two costs, and the second is the reason this is filed rather than noted.

1. **The word stops meaning anything.** `question_identity_unavailable` is the one signal that
   says *never fabricate a key to clear this* (`reference/question-lifecycle.md`). Two of the three
   entries above genuinely are that; one is its opposite. A reader cannot tell them apart from the
   `reason` field, only by noticing that `key` is non-empty — which is a second reading of a fact
   the field exists to report.

2. **It points the tick away from its one postable question.** The composing agent is told to
   drain `held` oldest-first and that "each entry's reason is the gate's own refusal word for that
   key". Taken at its word, every entry this tick was unidentifiable and there was nothing to post.
   The two questions that did clear the gate — `direction-expiring:an-autonomous-improvement-loop-run-by-the-routines`
   and `stalled-unit:turn-quiescent-blockers-into-mature-decisions-and-resume-work` — were reached
   only through their **owning steps'** `needs_agent`, never through the check-in's own list. On a
   tick with a working transport that is the difference between asking and staying silent.

The step already knows the answer: `gate_can_ask` is set to `true` in the same `case` arm, and
`delivery` is emptied at line 470 because of it. What is missing is that the entry says so.

## What is NOT claimed

This is not the reason nothing was posted this tick — the declared binding resolves
`operations_unsatisfied` and no route offers `post_root`, which is recorded separately and openly.
This record is about the step's own reporting, and it would be wrong on a tick that could post.
No repair is proposed here beyond naming a truthful word for the case; whether the entry should be
listed as held at all is a judgement for the operator, not for the tick that found it.
