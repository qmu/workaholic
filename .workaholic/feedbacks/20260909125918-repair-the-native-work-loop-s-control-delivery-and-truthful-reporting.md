---
type: Feedback
title: Repair the native work loop's control, delivery and truthful reporting
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T12:59:18+09:00
author: a@qmu.jp
supersedes: 
---

# Repair the native work loop's control, delivery and truthful reporting

GitHub Issue: https://github.com/qmu/workaholic/issues/1126

The operator asks Workaholic maintainers to repair the failures captured in a 2026-09-08
retrospective of a Claude Code native `/work` session — roughly 3.5 hours and 39 ticks in which
useful changes landed but progress depended on repeated human intervention, the loop stalled for
over two hours, it never posted as the explicitly requested QFS identity, it continued after
promising to wait, and it ended with a failed production database migration. Worker implementation
ability was not the problem: coordination, delivery, observation and truthful reporting were.

The ask is one consolidated repair request over seven areas, in the operator's own priority order:

1. Honor human interruptions before dispatch (highest priority; continues #1125). After saying it
   would wait, the session serviced nine more scheduled ticks. A hold must preserve the schedule
   while suspending new dispatch; an explicit stop must stop the schedule and its workers; elapsed
   time must not stand in for permission to resume.
2. Make native role completion and delivery observable. Zero `loop-finish-<role>` records for all
   three roles, while readers treat an empty record set as due. Two runners stopped with
   `merge_refused: session_type_cannot_merge` while an operator-authorized `gh pr merge --squash`
   later succeeded. And completion was claimed from a worker's word with zero merges, six queued
   tickets and two unreconciled pull requests.
3. Wire the transport contract into the actual execution path — the roles used direct `qfs run`
   calls rather than `workaholic:transport`; the requested identity delivered zero posts while
   fallback posts appeared as the human operator; a generic provider failure was repeated for
   fifteen ticks and a missing write scope was inferred from a different API's `missing_scope`.
4. Retire stale questions and make notification roots reachable (continues #1117). Six of ten
   supposedly human-blocked questions were already resolved; nine feedback items had no
   `fb:<stem>` root, so landed-ask notifications had no destination.
5. Complete the existing scheduling and digest fixes (#1115, #1116, #1118) and verify them in the
   native loop rather than only through helper tests.
6. Separate upstream QFS defects from Workaholic integration defects, and track the upstream
   limitations explicitly rather than diagnosing them by guessing scopes or changing identity.
7. Verify migrations against existing data and report runtime failures honestly. A stricter CHECK
   constraint passed against an empty database and then failed the existing-row copy in a
   production rebuild.

The operator states the observations are the retrospective's own and are not independently
reproduced in the filing; claims that a command never calls transport, or that a provider lacks a
scope, require source or runtime verification before being treated as established causes. The
request is for working end-to-end behavior and evidence — adding more instructions without wiring
and exercising the actual native runtime would repeat the failure the feedback describes.
