---
type: Feedback
title: The day-root lookup searches a token the root is forbidden to carry
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-10T18:34:01+09:00
author: a@qmu.jp
supersedes: 
---

# The day-root lookup searches a token the root is forbidden to carry

The `🔎 Moderation` root is threaded on the day key `tick-day:<YYYYMMDD>`
(`skills/moderate/scripts/lib/tick-thread-key.sh`), and `plugins/workaholic/commands/moderate.md`
tells the run to "resolve the day's standing root first by the stateless exact-string lookup in
`workaholic:notify`, searching the rendered `token` (`tick-day:<YYYYMMDD>`) and nothing else".

The same command file forbids the root from carrying that string. Its
*Nothing the tick knows about itself reaches a rendered post* clause lists, first, "a dedup key or
a search token — `tick-day:<YYYYMMDD>`, `fb:<stem>`, a question id or a step id". And
`render-tick-post.sh`'s own header states the decision it implements: "`token` IS NOT PRINTED AT A
READER (2026-08-22). It was rendered as a `tick:<id>` line on the root until then, and NOTHING
EVER SEARCHED IT."

Since 2026-09-01 something does search it. So the lookup searches for an exact string that no root
this loop posts can ever contain, the search takes the not-found branch every time, and every
speaking tick of a day opens its own root — which is exactly the failure the day key was
introduced to cure (`tick-thread-key.sh`: "14 roots in one window, 12 of them carrying zero
questions").

Measured here, tick `20260910-091903`: `render-tick-post.sh` answered `post: true`,
`token: tick-day:20260910`, and its `root_text` is

```
🔎 Moderation - 5 change(s), 2 question(s)
0 issue(s) whose work has landed are still open; 15 have never been ingested
a direction is about to reach its date — <…|an-autonomous-improvement-loop-run-by-the-routines>
a claimed unit has not moved for a day or more
1 mission(s) met their acceptance with work still queued
morning per-strategy digest (1 strategies, 16 commits since yesterday)
📋 0 direction(s) advancing, 1 held; new work is being held — 1 mission(s) in flight against a limit of 3
⚠️ 2 deployment target(s) waiting: docs-site, marketplace — a question for step 10, never a status post
```

— no `tick-day:20260910` anywhere in it. `search_exact` for `tick-day:20260910` over
`/slack-cc01-qmu` returned 0 messages.

The defect is masked on this repository today because no described route offers `post_root`, so no
root is posted at all. It becomes live the moment the transport is repaired, and it will be
invisible when it does: two roots an hour is not an error anyone's tooling reports.

`workaholic:notify` already contains the shape of the answer, for the feedback-item lookup, and it
is not applied here: "the standing objection — *a root without the key regresses the whole lookup*
— is answered rather than overruled: case 2 now searches `<stem>.md`, which the root carries by
construction because it links the record." The moderation root has no equivalent
carried-by-construction string. Whatever is chosen must satisfy both standing rules at once — the
root stays free of machine ids, and the lookup stays a single exact string it derives rather than a
recency or similarity match.

This is not the `add_reaction` / `post_root` map gap already recorded in
`20260909222245`, and not the duplicated no-transport condition recorded in `20260909171204`. Those
are about which operations a route offers. This one is about a string two shipped surfaces disagree
about, and it survives any transport repair.
