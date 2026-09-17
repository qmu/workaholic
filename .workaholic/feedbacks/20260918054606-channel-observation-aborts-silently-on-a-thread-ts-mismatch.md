---
type: Feedback
title: Channel observation aborts silently on a thread_ts mismatch
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-18T05:46:06+09:00
author: a@qmu.jp
supersedes: 
---

# Channel observation aborts silently on a thread_ts mismatch

# Channel observation aborts silently on a thread_ts mismatch, and a human @-mention under an older thread root goes undiscovered

Source: https://github.com/qmu/workaholic/issues/1193

A human posted an @-mention as a reply under a thread whose root was a day old, and a `/work` session on plugin 1.0.343 did not find it. The reporter traced two separate causes, both in the transport skill.

**1. `capture-inbox.sh` aborts on a `thread_ts` mismatch and the abort surfaces as an empty reason.** `observe-channel.sh` returned `{"observation_proved":false,"unreadable":[""]}` on every run. The native QFS adapter's `read_channel_delta` returns a `thread_broadcast` message with `thread_ts: null` (the provider's channel listing carries null for it), while the same message captured earlier from a `read_thread` result was stored with `thread_ts` set to its root. `capture-inbox.sh` requires the stored `message` object to equal the newly read one byte for byte, so the mismatch takes the `exit 10` branch; under `sh -eu` the failing pipeline aborts the script before the `capture_incomplete` line is printed, so stdout is empty and the observer reports `unreadable: [""]`. The binding cursor has not advanced for two weeks as a result, and no report said why. What would make it done: (a) compare messages by provider id and content rather than by the whole object, or normalise `thread_ts` so a `thread_broadcast` message reads the same from both operations; (b) make the abort emit a typed reason (`capture_incomplete` with the offending provider id) instead of an empty string.

**2. Thread discovery is unavailable on the native QFS route, so a reply under an older root is invisible by construction.** `describe-qfs.sh` lists `thread_discovery_unavailable` for the mount, `list_thread_changes` never runs, and coverage stays `partial`. The mention was only found by reading the thread of the last known mention directly. The reporter offers two remedies: a thread-discovery operation on the native route, or having `observe-channel.sh` re-read the threads of every root that mentioned the bot within the window.

kind: instruction / source: discussion / subject: person:tamurayoshiya
