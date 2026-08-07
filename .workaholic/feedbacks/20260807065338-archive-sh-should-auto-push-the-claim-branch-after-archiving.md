---
type: Feedback
title: archive.sh should auto-push the claim branch after archiving
kind: instruction
source: slack
created_at: 2026-08-07T06:53:38+00:00
author: noreply@anthropic.com
supersedes: 
---

# archive.sh should auto-push the claim branch after archiving

During `/drive` and `/implement` runs, `archive.sh` commits the ticket archive onto the claim branch, but pushing that branch afterward is currently left to the session's own discretion rather than being part of the script's job.

This causes two concrete problems when the push is forgotten:

- The claim's heartbeat can expire, making the unit look "resumable" again even though an archive commit already exists locally.
- Reviewers looking at the remote branch see a stale branch that doesn't yet include the archive commit.

An archive commit is a progress signal that should always reach the remote, so the fix should make `archive.sh` itself responsible for pushing the claim branch immediately after it makes the archive commit, rather than relying on the session to remember to push separately.

Source: https://github.com/qmu/workaholic/issues/290
Slack thread: https://qmu.slack.com/archives/C0BLL9J7FMY/p1786085345893689
