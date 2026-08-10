---
type: Feedback
title: Routines should read repo resources directly instead of stopping when plugin is unbound
kind: instruction
source: discussion
created_at: 2026-08-10T16:01:24+00:00
author: a@qmu.jp
supersedes: 
---

# Routines should read repo resources directly instead of stopping when plugin is unbound

Two consecutive scheduled sessions in this repository hit the unbound_in_claude_session condition ([Implement] on a schedule tick, then a pull_request.closed-triggered merge-announcement run for PR #352): the workaholic plugin showed enabled in ListPlugins, but Skill("workaholic:drive") failed with "Unknown skill" and ListSkills returned no workaholic entries. Both sessions treated this as a hard stop and only sent a push notification, even though the repository checkout itself was present and current on the base branch.

The developer's instruction: when a scheduled/routine session finds the plugin skills unbound, do not simply halt and notify. The repository is right there and its skill scripts are plain files under plugins/workaholic/skills/ (source) or the installed plugin cache — read the specific scripts a task needs directly (Read/Bash, not the Skill tool) and carry out the task's actual steps by running them, the way this session did afterward for its own /fb publish. Stopping is only the right move when the underlying work genuinely cannot be done without the unavailable skill surface (e.g. an AskUserQuestion-driven flow, or logic too complex to safely hand-reconstruct from scripts) — a missing Skill binding should not by itself end the run when the equivalent scripts are readable and runnable in-repo.
