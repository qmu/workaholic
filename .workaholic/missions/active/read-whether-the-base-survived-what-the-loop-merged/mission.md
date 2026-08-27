---
type: Mission
title: Read whether the base survived what the loop merged
slug: read-whether-the-base-survived-what-the-loop-merged
status: active
merge_policy:
created_at: 2026-08-27T16:19:11+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827161640-read-whether-the-base-survived-what-the-loop-merged.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Read whether the base survived what the loop merged

## Goal

Nothing here reads a check run. The loop merges its own work onto `main` every
half hour and never learns what the base's checks then said, so a green base and
a base nobody looked at are one reading. Read, attribute, report, ask once — and
act on nothing.

## Experience

The loop answers "did the base survive what I merged?" without anyone opening the
Actions tab. A red base is named — with the merge that caused it and the checks
that failed — in the driving run's report and as one question to the person whose
merge it was. A green base is silent; a read that could not be made says so rather
than passing for green. Nothing merges differently and the QA window owns quality.

## Acceptance

<!-- PROPOSED sketch. Approval replans this to drive-ready. -->

- [ ] One reader answers `green`/`red`/`unanswerable`, and a red base names the
      merge that turned it red or answers `unattributable` (#20260827161954-write-read-base-checks-sh-the-one-checks-reader.md)
- [ ] A red base reaches the attributed author once per commit, renders as an
      event, and is named in the driving run's report (#20260827161956-add-the-moderate-step-base-health.md)
- [ ] The reading gates nothing, is pinned as a judgement, and a network-free
      drill proves it (#20260827162003-drill-the-base-reading-with-no-network.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
