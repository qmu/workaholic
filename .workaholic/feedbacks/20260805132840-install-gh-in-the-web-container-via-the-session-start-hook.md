---
type: Feedback
title: Install `gh` in the web container via the session-start hook
kind: instruction
source: slack
created_at: 2026-08-05T13:28:40+00:00
author: a@qmu.jp
supersedes: 
---

# Install `gh` in the web container via the session-start hook

In Claude Code on the web, the container has no `gh` CLI, so any workaholic script that shells out to it cannot complete: `branching/scripts/publish-tree-pr.sh` pushes the artifact branch and then reports `no_gh` instead of opening the pull request, and `/ship`'s merge seam cannot run at all, which is why a cloud `auto` unit is demoted to the PR path on every run. The request is that this repository's `.claude/hooks/session-start.sh` install `gh` (for example `apt-get install -y gh`) as part of session startup, so downstream steps find it rather than each installing it ad hoc. Raised as qmu/workaholic#260 from the Slack thread linked there; two earlier records, 20260801134606 and 20260801181923, recorded the same absence as concerns asking for the container image itself to ship `gh`.
