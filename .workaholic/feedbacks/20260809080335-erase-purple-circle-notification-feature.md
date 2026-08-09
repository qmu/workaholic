---
type: Feedback
title: Erase purple circle (🟣) notification feature
kind: instruction
source: slack
created_at: 2026-08-09T08:03:35+00:00
author: a@qmu.jp
supersedes: 
---

# Erase purple circle (🟣) notification feature

tamura_yoshiya asked (2026-08-09, in #dev-workaholic) to erase the purple-circle (🟣) notification format entirely.

The `workaholic:notify` skill's reference documentation (plugins/workaholic/skills/notify/reference/notifications.md) defines a fixed notification shape that uses a purple circle emoji (🟣, "Merged by <@U…>") as one of its indicators, for the human-merge finish line. The ask is to remove this format from the skill's reference documentation, along with any related notify-skill behavior that emits it, so it is no longer part of the notification vocabulary.

Filed via GitHub issue qmu/workaholic#317 as design input for a downstream implementation pass; no repository investigation was performed while filing the issue itself.
