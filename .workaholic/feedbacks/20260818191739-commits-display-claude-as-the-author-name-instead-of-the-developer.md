---
type: Feedback
title: Commits display Claude as the author name instead of the developer
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-18T19:17:39+00:00
author: a@qmu.jp
supersedes: 
---

# Commits display Claude as the author name instead of the developer

GitHub shows every workaholic-made commit as authored by "Claude", because the container's global git config sets `user.name=Claude` and the web bootstrap only overrides `user.email` repo-locally (`.claude/git-identities`). The email is correct, so the commit is attributable — but the display name every external reader sees is the machine, not the person who did the work.

The ask: stamp the actual committing developer's name as the commit author name. Two mechanisms named by the reporter as candidates (their words, not a decision): recover the name from the commit message body/metadata, or resolve it from the email through the GitHub API.

Impact as stated: all workaholic-routed commits record "Claude" as the author display name, so who actually did the work is invisible from outside.

Source: https://github.com/qmu/workaholic/issues/510
