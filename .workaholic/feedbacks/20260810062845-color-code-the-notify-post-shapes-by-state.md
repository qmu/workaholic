---
type: Feedback
title: Color-code the notify post shapes by state
kind: instruction
source: discussion
created_at: 2026-08-10T06:28:45+00:00
author: a@qmu.jp
supersedes: 20260807190939-adopt-the-six-color-notify-state-emoji-set-keeping-the-rocket-for-auto-merge.md
---

# Color-code the notify post shapes by state

Color-code the notify post shapes by state, so a developer scanning a dev- Slack thread reads a unit's state from the emoji alone: Blue = Proposed ([Propose] routine's finish and thread root when none exists), Orange = Implementing ([Implement] unit's start), Yellow = Handoff (unchanged), Green = Implemented (ordinary review-stop finish), Red = Blocked (unchanged), Rocket = Auto Merge (unchanged, deliberately outside the color set). One color maps to exactly one state. The current design-glyph (Designing/Proposed) and tool-glyph (Implementing/Implemented) each cover two states, so start and finish of a phase are indistinguishable at a glance; the design-start post should adopt the state color of what it opens (blue family) or be judged in the design. Scope: supersedes the un-implemented six-color ruling in FB 20260807190939 (its purple half is moot since #317). Spans workaholic:notify's SKILL.md and reference/notifications.md (the shape catalog), both routine prompt templates in skills/workaholify/routines/, and the prompt-is-the-ceiling rule's example text — likely a design ticket plus an implementation ticket, i.e. a mission. Line wording stays as-is (issue #300's two-line format); only the leading emoji and state words change. Source: https://github.com/qmu/workaholic/issues/330
