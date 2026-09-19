---
type: Feedback
title: Keep a coherent feedback batch one mission one PR one report
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T09:50:27+09:00
author: a@qmu.jp
supersedes: 
---

# Keep a coherent feedback batch one mission one PR one report

Source: https://github.com/qmu/workaholic/issues/1110

Workaholic over-fragmented one coherent UI review batch into many loose tickets, and then treated
"one bounded PR-unit" as though it implied one small issue per pull request. On a consuming
repository one continuation thread was published as **nine independent loose tickets** in a single
proposal pull request, then driven through **four separate implementation pull requests**. The
developer's judgment is that the reviewed changes were cohesive enough to be **one mission, one
pull request, and one report**.

The result was unnecessary version/merge/report churn, fragmented development context, and
notification complexity. It also encouraged implementation to begin before the whole feedback
batch and its shared interaction model had been considered together.

## Expected behavior

- Do not equate a ticket boundary with a pull-request boundary. A bounded PR-unit may contain
  multiple tickets when they share one review surface, one feedback thread, and one coherent
  acceptance walk.
- When two or more related feedback tickets form a single user-visible correction pass,
  `/specificate` should prefer one mission unless there is concrete release, dependency, ownership
  or risk evidence that requires separation.
- The mission should preserve the individual feedback-to-ticket traceability while routing the
  whole mission as one implementation claim, one pull request, and one branch story/report.
- Granularity judgment must consider the developer's desired review unit and cognitive cost, not
  maximize atomicity mechanically.
- Before issuing multiple versions or merging multiple small pull requests for one feedback batch,
  finish ingesting and reconciling the batch so shared foundations and interactions can be
  designed together.
- If the developer corrects granularity mid-flight, stop new claims at the next safe boundary and
  replan the remaining loose tickets into one mission. Do not continue the old fragmentation
  merely because the loose tickets already exist.
- Progress posts can still enumerate each linked issue, but they should point to the shared
  mission/pull-request outcome rather than producing one lifecycle message per tiny unit.
