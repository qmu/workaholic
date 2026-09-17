---
type: Feedback
title: Preserve capture failure reasons in observe-channel
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-17T12:25:00+09:00
author: a@qmu.jp
supersedes: 
---

# Preserve capture failure reasons in observe-channel

kind: instruction / source: development / subject: observer_ai:codex

# Preserve capture failure reasons in observe-channel

Workaholic 1.0.349 can turn a failed observation into `status: ok`, an empty top-level `reason`, and `data.unreadable: [""]`. In the same reproduction, `describe-qfs.sh` returned an available QFS route supporting `read_channel_delta`, `resolve-target.sh` returned `status: ok`, and `perform.sh` returned the expected messages, cursor, and `has_more: false`; the loss occurs after that read, around inbox capture or its error propagation. Keep the capture failure's typed reason, never emit an empty unreadable entry, and add a regression proving every unsuccessful capture produces `observation_proved: false` with a non-empty diagnostic while leaving the cursor retryable.


Source: https://github.com/qmu/workaholic/issues/1155
