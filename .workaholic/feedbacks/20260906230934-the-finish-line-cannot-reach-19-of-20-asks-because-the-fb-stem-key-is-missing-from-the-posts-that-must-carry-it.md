---
type: Feedback
title: The finish line cannot reach 19 of 20 asks, because the fb:<stem> key is missing from the posts that must carry it
kind: instruction
source: development
subject: observer_ai:tamura.yoshiya@gmail.com
created_at: 2026-09-06T23:09:34+09:00
author: a@qmu.jp
supersedes: 
---

# The finish line cannot reach 19 of 20 asks, because the fb:<stem> key is missing from the posts that must carry it

Source: https://github.com/qmu/workaholic/issues/1048

`/infinite-development`'s finish-line step resolves an ask's Slack thread by the `fb:<stem>`
exact string, and deliberately refuses every fallback: no fuzzy match, and the keyed root of
`workaholic:notify` case 4 is named as unavailable here. That is the right call on its own — a
wrong thread is worse than none. But it assumes the `📝 FB` post that opened the thread carries
the key, and in `osbrjp/coop-planner` it almost never does.

Measured 2026-09-06 in `#coop-planner`, searching `":memo: FB" after:2026-08-30`: 20 posts, of
which exactly 1 carries an `fb:<stem>` line. The other 19 carry the record title as a markdown
link, the one-line description, and the session URL — the stem appears only inside the link's
URL, which the required exact-string search does not match.

The consequence is not a slow path, it is a closed one. On the tick that measured this,
`list-unannounced-closed-asks.sh` returned 10 candidates (`truncated: true`, so there are more).
Nine resolved to `thread_unresolved` and were correctly left alone. The tenth — #665, the single
post that carries its key — resolved, and its thread already held three `🟢 Implemented` lines,
so the dedup fired. Every ask whose work landed is announced or silent purely according to
whether its opening post happened to include one line.

What makes it hard to notice is that the failure is per-item and looks healthy.
`thread_unresolved: no_match` is a legitimate outcome word, reported one candidate at a time; a
tick reporting nine of them looks like nine unusual asks rather than one broken seam. Nothing
counts the ratio, so the feature can be dead for months while every tick reports conformantly.

Older posts did carry it: the August corpus in this same channel is full of `fb:` lines. So this
is a regression in the emitting shape rather than a convention that never existed. It does not
track the sender either — the one keyed post came from the ChatGPT-driven routine, and other
posts from that same routine (2026-09-05 04:06, for one) omit it.

## What should happen

The `📝 FB` post shape should emit `fb:<stem>` unconditionally, since it is the only key the
finish line can resolve by, and a post without it silently forfeits its own completion notice.
Whatever writes that post should treat the line as required rather than decorative.

Separately, and worth having regardless: the finish-line step should be able to say that it
could not resolve most of what it looked at. A run that reports `thread_unresolved` for nine of
ten candidates has found a broken seam, not nine odd asks, and only the ratio distinguishes the
two.
