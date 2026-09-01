---
type: Feedback
title: The moderation check-in can no longer ask, and its morning root cannot open
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-27T00:58:50+00:00
author: a@qmu.jp
supersedes: 
---

# The moderation check-in can no longer ask, and its morning root cannot open

The moderation tick's check-in can no longer reach a person, and its morning root cannot
open. Two defects, both measured on this repository during tick `20260827-005147`.

## 1. The day cap is a lifetime cap

`moderate/scripts/ask-question.sh` computes `asked_today` as
`count_log_prefix human-checkin-ask ""`, which calls `log-read.sh --step-prefix
human-checkin-ask` with **no `--since` and no `--tick`** — so it counts every
`human-checkin-ask-*` line in the whole of `.workaholic/moderations/`, not today's.

Measured: `count: 12, days: 4`, spanning 2026-08-18 to 2026-08-26, against
`max_per_day: 10`. Every new question key this tick raised was refused
`{"ask": false, "reason": "day_cap", "hold": true, "asked_today": 12}` —
`stalled-unit:...`, `undrivable-unit:...` and `stuck-1470719101` alike.

The log is append-only and **never pruned by a machine** (a deliberate rule), so the
count only rises. The gate is therefore not a bound on a day's attention; it is a
permanent, silent end to first asks on any repository whose tick history reaches ten.
Only the bounded once-more re-ask escapes it, because that branch returns before the cap
is consulted. `held: true` is honest about the mechanism and misleading about the
outcome: held is not dropped, but nothing will ever release these.

## 2. `run.sh`'s report drops `needs_agent`, and two consumers read it

`run.sh`'s header documents each row as
`{"step","status","reason","summary","event","needs_agent":[...],"logged"}` and its
emitter writes the **length** instead (`needs=$(json_array_len needs_agent "$out")`),
with the comment "the report only needs its length". Two documented consumers of that
same report read the entries:

- `question-liveness.sh` matches `(.needs_agent // []) | tostring | contains($key)`.
  Fed the run report, that can never match, so **every** already-asked question reads
  `settled`. Measured: `stalled-unit:batch-20260818215156` read `liveness: "settled"` on
  the very tick whose `stalled-units` step raised it again (194h stalled, at an open pull
  request). That kills the once-more re-ask, which requires `live` — and it would arm the
  `✅ 解消を確認` confirmation, which fires on `asked` + `settled`. This tick declined to
  post that confirmation: it would have told the developer a stalled unit had settled on
  the same tick the tick measured it stalled.
- `render-tick-post.sh`'s morning-digest gate matches the literal
  `render_the_morning_digest_at_the_top_of_the_root`, which lives only in the step's
  `needs_agent` payload. Fed the run report it can never fire, so the digest's second
  gate is dead. Measured: with `strategy-digest` reporting a ready digest (1 strategy,
  193 commits) and four changed steps, the render returned
  `{"post": false, "reason": "no_question"}` — so no root posted on 2026-08-27, and the
  integrated standup the developer asked to find in that thread was not written.

`workaholic:moderate`'s **The run** section names the pipeline explicitly
(`run.sh`'s JSON | `render-tick-post.sh`), so this is not a caller using the wrong
input.

## Why the two belong together

They have one measured consequence: on 2026-08-27 the tick read the repository
correctly at every step — a 194h stalled claim, seven queued units owned by an address
`.claude/git-identities` does not name, three pull requests conflicting with main and one
clean and unmerged — and **told nobody anything**. The check-in refused every question
mechanically, and the root that would have carried the morning digest did not open. The
tick log is the only surface that saw it, which is precisely the silence
`stalled-units`, `direction-health` and `unanswered-asks` were each added to end.

## What must become true

A question is refused for the day only when a *day's* worth of questions has been asked,
and a tick that has something to say to a person says it. Whether `needs_agent` returns
to the report or the two consumers are fed the step output is a design call; what must
not survive is a documented producer and a documented consumer disagreeing about a field,
where the disagreement's only symptom is silence.

Seams: `moderate/scripts/ask-question.sh` (`count_log_prefix`, `asked_today`),
`moderate/scripts/run.sh` (the row emitter, ~line 174, and its header contract ~line 52),
`moderate/scripts/question-liveness.sh`, `moderate/scripts/render-tick-post.sh`
(`digest_ready`), and `scripts/test-workflow-scripts.mjs` for the proof.
