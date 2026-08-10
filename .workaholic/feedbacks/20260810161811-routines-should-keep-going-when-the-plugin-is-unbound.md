---
type: Feedback
title: Routines should keep going when the plugin is unbound
kind: instruction
source: discussion
created_at: 2026-08-10T16:18:11+00:00
author: a@qmu.jp
supersedes: 
---

# Routines should keep going when the plugin is unbound

Two scheduled runs in this repo recently stopped without doing their work instead of completing the task: an [Implement] schedule tick, and a merge-announcement run triggered by a PR closing.

Both hit the same condition: the workaholic plugin shows enabled via ListPlugins, but Skill("workaholic:drive") fails with "Unknown skill" and ListSkills returns empty — the documented unbound_in_claude_session case, where a SessionStart install can report success while leaving the skill surface unreachable for the rest of that session.

Being unbound should not, by itself, be a reason to stop. The repository checkout is present and current in these sessions, and the skills are plain files under plugins/workaholic/skills/ — when the skill tool is unreachable, the routine should read the needed scripts directly (via Read/Bash) and carry out the task itself, rather than halting and only posting a notification.

Stopping is still the right call when the work genuinely cannot proceed without the skill surface — e.g. an AskUserQuestion-driven flow, or logic too risky to hand-reconstruct from source. Those cases should keep failing safe; only the blanket "unbound → stop" default needs to change.

Source: GitHub issue qmu/workaholic#356 (filed by the [Implement] routine).
