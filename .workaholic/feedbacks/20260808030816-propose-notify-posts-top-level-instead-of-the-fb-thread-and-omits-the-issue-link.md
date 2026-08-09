---
type: Feedback
title: [Propose] notify posts top-level instead of the FB thread and omits the issue link
kind: instruction
source: slack
created_at: 2026-08-08T03:08:16+00:00
author: a@qmu.jp
supersedes: 
---

# [Propose] notify posts top-level instead of the FB thread and omits the issue link

Issue qmu/workaholic#306 (source: <https://github.com/qmu/workaholic/issues/306>): while running the [Propose] routine on FB #304's design/propose notifications (2026-08-07, #dev-workaholic), two deviations from the workaholic:notify skill's documented template were observed:

1. Wrong thread placement — the 'started designing' / 'proposed' notifications were posted as new top-level channel messages instead of as replies within the originating FB issue's Slack thread. The documented model ('One thread per feedback item') expects every event of an item's life to stay threaded under its own root.
2. Missing link — the documented template renders the issue/PR reference as a markdown link (e.g. '[#123 FB Issue Title](<url>)'), but the actual posted messages rendered the reference as plain text ('Designing for #304 [FB] ...') with no hyperlink, so a reader cannot click through.

Ask: investigate why the notify lookup is not finding/replying to the FB issue's stored Slack thread and why the markdown link is not rendered, and fix the workaholic:notify implementation (and/or the [Propose] routine template) so both the thread placement and the link rendering match the documented template exactly.
