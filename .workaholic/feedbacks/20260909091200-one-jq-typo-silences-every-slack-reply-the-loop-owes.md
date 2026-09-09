---
type: Feedback
title: One jq typo silences every Slack reply the loop owes
kind: defect
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T09:12:00+09:00
author: a@qmu.jp
supersedes: 
---

# One jq typo silences every Slack reply the loop owes

`adapters/qfs-native.sh:63` guards the commit of a `post_root` / `post_reply` on

```sh
jq -e '.committed == false and (.preview.rows|type)=="array" and .total_affected > 0' "$tmp/preview"
```

QFS answers the preview with the count nested one level down, at `.preview.total_affected`, as
`{"exact": 1}`. The top-level `.total_affected` is `null`, `null > 0` is `false` in jq, and the
guard therefore fails on a **correct** preview. Every post the loop attempts returns
`deferred qfs_preview_refused`, and the commit on line 65 is unreachable.

Measured on `osbrjp/coop-planner` against `/slack-yodex`, 2026-09-09: the one-word body `'テスト'`
and a body carrying emoji and links both refuse identically, while
`(.preview.total_affected.exact // 0) > 0` on the same preview answers `true`.

**What it costs, measured rather than estimated.** The route is not read-only by design —
`describe-native-qfs.sh /slack-yodex qmu C0BKV34JK39 yodex` offers `read_channel_delta`,
`read_thread`, `search_exact` **and `post_reply`**, with `thread_map_verified: true`. So the
adapter refuses an operation its own describe advertises. On this repository the loop has run
about fifty ticks without delivering one reply: not the answers it owed under human roots, not the
`📥 受理` receipts, not the four landed-ask finish lines that sit at `post_failed:
qfs_preview_refused`, not a single `🔴 Blocked` for nine consecutive production deploy failures.
The operator's own message went unanswered and unreacted for hours, which is how the defect was
found — from the outside, by a person asking why nothing came back.

The failure mode is the expensive part. `qfs_preview_refused` is a *deferred* result, so the loop
stays green: it reports a healthy tick, an ordinary quiet channel, and a degradation named in a
line nobody reads. A silence that reports itself as health is indistinguishable from a quiet hour.

## Two things found alongside it

**`describe-native-qfs.sh` blames the mount for a bad argv.** Its usage is positional — `MOUNT
WORKSPACE CHANNEL ACCOUNT` — and `mount=$1`, so a flag-shaped first argument lands in `$mount` and
line 8 answers `{"ok":false,"reason":"invalid_mount"}`. That reads as *this mount is not a Slack
mount*, which is a fact about the declaration, when the truth is *you called me wrong*. Two
independent sessions on this repository reached the same wrong conclusion within an hour on
2026-09-09, one of them recording "no permitted transport" in a filed issue on that basis; both
had passed `--mount /slack-yodex`. The same call made positionally answers `ok: true`.
`unrecognised_arguments` costs one `case` arm and would have stopped both.

**The undelivered-root rule states no dedup key.** `moderate/SKILL.md:87` says only "File an
undelivered root through the existing feedback path". Its neighbouring paragraph establishes
`tick-day:<YYYYMMDD>` — one standing root per speaking *day* — but the filing sentence inherits
nothing from it, and a session on 2026-09-09 read it as owing one issue per speaking *tick* and
recorded that every future tick owes another until the transport returns. It filed
`osbrjp/coop-planner#774` on that reading. Which of the two is meant is not decidable from the
text; whichever it is, saying the key out loud in that sentence is what stops a transport outage
from becoming an issue tracker full of one issue per hour.

## Fixing line 63 restores replies and not roots — measured after the above was written

`post_root` is **not offered on this route at all**, so the jq fix does not on its own let a
maintenance tick speak. `describe-native-qfs.sh /slack-yodex qmu C0BKV34JK39 yodex` answers
`ok: true` and `channel_verified: true`, but `map_verified: false` with the limitation
`root_map_unverified_or_ambiguous`, and its `operations` are `read_channel_delta`, `read_thread`,
`search_exact`, `post_reply` — no root operation. The adapter's own guard reads
`flag=map_verified; [ "$TRANSPORT_OPERATION" != post_reply ] || flag=thread_map_verified`, so a
`post_root` is refused `qfs_map_unverified` one step before it ever reaches line 63.

The consequence is exact: a day's **first** speaking tick must open a root, and no route can. With
`SLACK_BOT_TOKEN` unset and no permitted connector fallback, the two failures compose into total
silence, and only one of them (#774, on `osbrjp/coop-planner`) is written down anywhere. Repairing
the guard would let the loop answer inside threads whose coordinates it already holds — which is
most of what it owes a person — and would still leave every day's first post undeliverable.

## The day-root search token can never match, because the same file forbids rendering it

`commands/moderate.md:43` says to resolve the day's standing root "by the stateless exact-string
lookup in `workaholic:notify`, searching the rendered `token` (`tick-day:<YYYYMMDD>`) and nothing
else". Twenty-seven lines later, `commands/moderate.md:70` lists what a rendered post carries
**none** of, and names that exact token first: "a dedup key or a search token —
`tick-day:<YYYYMMDD>`, `fb:<stem>`, a question id or a step id."

So the string being searched for is one the posts are forbidden to contain. Verified against the
channel `coop-planner`: neither surviving `🔎 Moderation` root (2026-09-07, 2026-09-08) contains
`tick-day:`. Every speaking tick therefore takes the not-found branch and opens a new root — which
is the regression the 2026-09-01 day-key change was made to end. `search_exact` on this route
cannot even prove absence: it is a substring filter over a bounded 100-message table returning
`complete: false`.

Whichever of the two rules is meant to win, one of them has to move. If the token must stay out of
the prose, the day root needs a coordinate the loop keeps rather than a string it searches for.
