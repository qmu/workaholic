---
type: Feedback
title: The tick can only behave like a bot: a per-tick thread key, a banned recency match, and a string-diff post gate
kind: instruction
source: development
subject: person:the operator of a consuming repository
created_at: 2026-09-01T12:20:46+00:00
author: a@qmu.jp
supersedes: 
---

# The tick can only behave like a bot: a per-tick thread key, a banned recency match, and a string-diff post gate

kind: instruction / source: development / subject: person:the operator of a consuming repository

Source: https://github.com/qmu/workaholic/issues/843

# The tick can only ever behave like a bot: its thread key is unique per tick, recency is banned by name, its post gate is a string diff, and resolving is forbidden to it

Measured on a consuming repository, 2026-09-01, against plugin 1.0.266. The operator asked "why
can it only ever post like a bot?" — reposts of near-identical status lines push the information
they need out of the channel. What they want instead is an agent that reads the room, adds only
the DELTA as a reply inside the most recent tick's thread, mentions them, and then goes and
resolves what the tick found. Counted in one channel window: **14 Moderation roots, 12 of them
carrying zero questions** — twelve top-level posts addressed to nobody.

Five rules compose into that outcome, and no one of them is wrong on its own.

**The thread key cannot match the previous tick, by construction.** The lookup is stateless and
keyed on an exact string, and `render-tick-post.sh` stamps the root `tick:<tick-id>` where the id
is that tick's own timestamp. `tick:...-160000` can never match `tick:...-150000`, so case 4 (no
match -> open a new root) is the only branch a tick will ever take. The threading machinery that
would give the operator what they want is present and unreachable.

**Recency is prohibited by name** — "never a similarity match, never the most recent thread that
looks related, never recency" — written after a 2026-08-05 misfire. That ban is right for a
feedback record, where the wrong thread is a mis-attribution. For an hourly tick, "the previous
tick's root" is not a guess: it is a single, well-defined object the tick already knows the id of
(`previous_tick` is in the render output). The ban was authored for one shape and now binds a
shape it was not measured against.

**The post decision is `cmp`, not judgement.** `render-tick-post.sh` sorts two files of
`(step, status, stabilized summary)` and compares them. Nowhere in the run does anything ask
whether this hour deserves a person's attention. And the stabilizer only strips timestamps, shas
and clock times — so `stuck-prs`, whose summary embeds the pull-request list and each one's state,
churns on nearly every tick. Nine consecutive ticks read: `(403:unknown 407:unknown 409:unknown)`
four times, then `4 pull requests ...`, then `1 pull request conflicting`, then `5 pull requests ...`,
then `1 pull request with a failing check` twice. The same pull request went unknown -> conflict ->
unknown -> checks without the repository moving; those states are the list endpoint's lazy answer,
which is exactly the class of value the stabilizer exists to strip. **So the gate built to stop
hourly noise is what produces it.**

**The wording is fixed by contract**, which closes the last door: the post shapes' tokens belong
to the notify skill and are to be reproduced exactly, so a session that wanted to write like a
person is instructed not to.

**And resolving is forbidden to the step that finds the problem.** `/moderate` says of itself:
never merges, never rewrites another runner's branch; it finds, files through the existing seams,
and says what needs a human. So "reports problems and resolves nothing" is not a defect in the
implementation — it is the design, working. On the day this was filed, five conflicted pull
requests were unblocked and merged by a person's session in an afternoon; the tick had been
reporting them hourly for days.

## What is asked, in the order that would help most

1. Give the tick a **stable** thread key — the day, or the loop, not the tick — so an hour with
   something to add REPLIES into the standing thread with the delta and a mention, and a new root
   is what a new day earns. Carve the tick out of the recency ban explicitly rather than leaving
   it to be inferred; `previous_tick` is already known, so no fuzzy match is needed.
2. Stabilize a summary whose volatility is the transport's rather than the repository's — the
   pull-request state list first — so the fourth gate stops firing on values that moved without
   anything moving.
3. Decide whether a step that can repair a thing may repair it, or say plainly in the skill that
   the tick is a reporter and name who does the repairing. Today the answer is neither: it files
   into a queue drained by a human question budget of ten a day, and the operator discovers the
   backlog by asking.
