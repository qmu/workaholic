---
type: Feedback
title: question-liveness reads settled for every live question
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T10:22:32+00:00
author: a@qmu.jp
supersedes: 
---

# question-liveness reads settled for every live question

Source: measured in the `[Moderate]` tick `20260826-101802` (this repository).

## What is wrong

`workaholic:moderate`'s workflow reference tells the agent to settle an already-asked
question's liveness with:

```
question-liveness.sh --key <content-key> --step <owning-step-id> --run <run-report.json|->
```

and `SKILL.md` names `run.sh`'s JSON as that document. But `question-liveness.sh` decides
`live` by asking whether the key appears inside the step row's `needs_agent` payload:

```sh
jq -e --arg k "$KEY" '(.needs_agent // []) | tostring | contains($k)'
```

while `run.sh` emits `needs_agent` as a **count**, not the array (`run.sh` header, and its
own comment: *"`needs_agent` is an array of flat objects; the report only needs its
length"*). So `tostring` yields `"1"`, the key is never contained, and the script falls
through to its final `emit settled`.

## The measurement

This tick's `stalled-units` step raised four live subjects and reported `needs_agent: 1`
in the run report. Fed `run.sh`'s JSON, the gate answered:

```
{"ask": false, "reason": "already_asked", "liveness": "settled"}   x4
```

Fed a document carrying the step's real `needs_agent` array — the same step, the same
tick, re-run — it answered:

```
{"liveness": "live"}   x4
```

All four claims are still stale, still claimed, still unanswered. `settled` was false for
every one of them.

## Why it matters

Two behaviours key on `settled`, and both fail in the direction that produces silence:

1. **A false `✅ 解消を確認`.** A question in state `asked` whose liveness reads `settled`
   gets one confirmation reply into the thread that asked it, logged under
   `human-checkin-confirmed-<slug>` so **a second is impossible by construction**. Posting
   it against a live subject tells the operator a blocker cleared when it did not, and
   burns the one confirmation that question will ever get.
2. **The bounded re-ask is suppressed.** Only a `live` subject is re-asked at the next
   working day. A subject that reads `settled` forever is asked exactly once, ever — which
   is the twenty-hours-of-silence failure the re-ask was built to end.

`unknown` is unaffected (a `blocked` or `degraded` step short-circuits before the payload
test), so the defect hits precisely the steps that ran cleanly and found something.

## The shape of the repair

The reader is correct and the run report is correct for its own purpose; what is missing is
that they are not the same document. Options, in the order they look right:

- Have `run.sh` carry each step's `needs_agent` **array** in a field beside the count
  (the count is what the report renders; the array is what the liveness reader needs), and
  point `--run` at that.
- Or have the SKILL stop naming `run.sh`'s JSON, and require the caller to pass the
  concatenated step outputs it already has.

Either way the fix is one document contract, not a change to the liveness rule: `unknown`
stays load-bearing, the owning step stays an argument, and nothing new is stored.

## What this tick did about it

Nothing was confirmed. The tick re-derived liveness from the step scripts' own output,
read all four stalled subjects as `live`, and posted no `✅` line.
