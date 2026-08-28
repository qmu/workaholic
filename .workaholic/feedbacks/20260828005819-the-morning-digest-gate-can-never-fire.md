---
type: Feedback
title: The morning digest gate can never fire
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-28T00:58:19+00:00
author: a@qmu.jp
supersedes: 
---

# The morning digest gate can never fire

The morning digest gate in `render-tick-post.sh` can never fire, because it matches a string `run.sh` does not emit.

## What was measured

Tick 20260828-005129 ran at 09:51 JST on 2026-08-28. Its `strategy-digest` step reported:

```
morning digest ready for 2026-08-28: 1 strategies, 164 commits
```

with a `needs_agent` entry whose action is `render_the_morning_digest_at_the_top_of_the_root`. The renderer, handed `run.sh`'s report, answered:

```
{"post": false, "reason": "no_question", "change_count": 6, "questions": 0}
```

so the day's opening statement was not posted.

## Where it comes from

`render-tick-post.sh` decides the second gate by matching the piped report:

```sh
case "$INPUT" in
    *'"step": "strategy-digest"'*'render_the_morning_digest_at_the_top_of_the_root'*) digest_ready=1 ;;
esac
```

That string lives only inside a step's `needs_agent` **payload**. `run.sh` does not carry the payload: it emits the array's length (`run.sh`, `needs_agent is an array of flat objects; the report only needs its length`), so every step row reads `"needs_agent": 1` and the pattern cannot match on any tick. The two are also out of step with `run.sh`'s own documented output, which still shows `"needs_agent":[...]`.

## Why it matters

The digest is the root's second gate by design (2026-08-24, the developer's ruling that folded the retired `[Standup]` routine into this tick, because the morning root is where they asked to find it). With the gate dead, the morning root posts only when the tick also has a cleared question -- and it currently has none, for the separate reason recorded in the day-cap finding filed by the same tick. Both together mean the tick has been silent with a ready digest and six changed steps.

## The shape of the repair

Give the gate a fact the report actually carries. The cheapest is the step's own signal: `strategy-digest` already reports `status: ok` with a summary naming the JST day, and the log carries `strategy-digest-rendered:<jst-day>` once a root posts, which is what keeps a second morning render impossible. Reading the step row rather than a payload string keeps `run.sh`'s length-only report untouched. Whichever fact is chosen, `run.sh`'s header comment should stop showing an array it does not emit.

Reported by the 20260828-005129 tick of `/moderate`, whose digest was ready and unposted.
