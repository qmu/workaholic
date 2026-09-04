---
type: Feedback
title: Carry a claim's liveness somewhere other than an empty commit on the work branch
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-03T22:22:58+09:00
author: a@qmu.jp
supersedes:
---

# Carry a claim's liveness somewhere other than an empty commit on the work branch

# Carry a claim's liveness somewhere other than an empty commit on the work branch

Source: https://github.com/qmu/workaholic/issues/968

The claim protocol keeps claims alive with empty `Refresh heartbeat` commits on work branches. Across two weeks this produced 220 empty commits, including 90 in one day, padding review history and risking permanent trunk noise under merge-commit or rebase routes. Move this short-lived operational liveness signal off the pull-request work branch while preserving whatever reachability the claim protocol genuinely requires.
