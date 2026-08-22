---
type: Mission
title: Take the dedup key out of the read post
slug: take-the-dedup-key-out-of-the-read-post
status: active
merge_policy:
created_at: 2026-08-21T15:09:58+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
assignee:
predicted_hours:
actual_hours:
feedback: [20260821150943-drop-the-fb-key-line-from-every-slack-post-template.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260822-232014
---

# Take the dedup key out of the read post

## Goal

Every Slack post ends with a line a human is not meant to read — `fb:<stem>`, and its siblings
`stuck:`, `deploy:`, `standup:`, `unit:`. The ask is to delete it. It cannot simply be deleted:
it is the **dedup key**, and case 2 of the stateless thread lookup finds a feedback item's
existing thread by searching for that exact string. Remove it from the text and case 2 never
matches, so one item accumulates one thread per tick — the failure #360 and FB `20260811084546`
were spent fixing. The one obvious home for it was already refused: a `thread_ref` committed
to this public repository is the exposure the P9 withdrawal found irretractable.

So the key needs a home outside both the read text and the repository — or a shape short enough
to stop being noise.

## Scope

`notify/reference/notifications.md`'s post shapes, the thread lookup's cases 2 and 4, and the
routine templates that mirror them. Not the notification model's event bar.

## Experience

A person reads a Slack post and sees only what a person needs. The next tick still finds that
item's thread and replies into it, exactly once.

## Acceptance

- [x] The path that printed the observed key is identified, not assumed (#20260821151007-find-which-path-printed-the-visible-key.md)
- [ ] What the Slack search surface matches is measured before anything is designed on it (#20260821151007-measure-what-the-slack-search-surface-matches.md)
- [ ] No post carries a key a human reads, and one item still owns exactly one thread (#20260821151007-take-the-key-out-of-the-post-body.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-22 — ticket archived — 20260821151007-find-which-path-printed-the-visible-key.md
