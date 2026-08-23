---
type: Mission
title: Give the tick a route for the records it writes
slug: give-the-tick-a-route-for-the-records-it-writes
status: achieved
merge_policy:
created_at: 2026-08-22T14:14:02+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822141342-moderate.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-144244
---

# Give the tick a route for the records it writes

## Goal

`/moderate`'s steps 2 and 5 write feedback records through `create.sh`, which stages them and
stops. A tick's container is discarded, so the records die with it — and no sanctioned route
exists to carry them: `persist-log.sh` publishes `moderations/` and nothing else, and the only
branch shape the guard permits is the claim shape the tick may not create. Measured on tick
`20260821-085204`: two records written, both reported `filed`/`persisted`, zero on `origin/main`.

The loss is silent because the dedup reads the tick log, not the records. The next tick reads
`inbound-sweep-filed` and believes both exist.

## Experience

A record a tick writes reaches the base in the same tick, by the same direct seam the log
already uses. A record that did not reach the base is reported as not persisted, so the next
tick re-derives the finding instead of trusting a line that was never true.

## Acceptance

- [x] A feedback record written during a tick reaches the base without a `work-*` branch, a
      claim or a pull request (#20260822141436-persist-the-tick-s-own-feedback-records-to-the-base.md)
- [x] A record that did not reach the base is reported by name, and the dedup does not treat
      it as filed (#20260822141436-stop-reporting-a-record-the-tick-did-not-persist.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-23 — ticket archived — 20260822141436-persist-the-tick-s-own-feedback-records-to-the-base.md
- 2026-08-23 — ticket archived — 20260822141436-stop-reporting-a-record-the-tick-did-not-persist.md
- 2026-08-23 — mission achieved — mission.md
