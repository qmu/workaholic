---
type: Feedback
title: Implement routine over-blocks on unbound_in_claude_session
kind: instruction
source: discussion
created_at: 2026-08-10T07:01:10+00:00
author: a@qmu.jp
supersedes: 
---

# Implement routine over-blocks on unbound_in_claude_session

During the [Implement] routine for PR #331 (mission color-code-the-notify-post-shapes-by-state), check-deps/scripts/check.sh reported unbound_in_claude_session: true (the workaholic plugin was installed at SessionStart but never bound as Skill/Command tools this session), and the run stopped pending a human /reload-plugins per drive/SKILL.md's terminate-pending rule, posting a 🔴 drive blocked notice to the item's Slack thread.

Developer correction (live, in-session): treating this as a hard stop was a mistake. The plugin's own scripts under plugins/workaholic/skills/ remain directly runnable via Bash from the checkout regardless of whether the Skill/Command tool abstraction is bound, and the PreToolUse safety hooks (guard-git-commit.sh, guard-git-branch.sh, guard-ticket-structure.sh, guard-working-directory.sh, guard-repo-confinement.sh) stay registered and active independent of that binding. The developer instructed the session to continue driving the mission by invoking the scripts directly instead of waiting on a manual /reload-plugins.
