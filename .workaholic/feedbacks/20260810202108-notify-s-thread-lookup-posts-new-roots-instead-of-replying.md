---
type: Feedback
title: notify's thread lookup posts new roots instead of replying
kind: instruction
source: discussion
created_at: 2026-08-10T20:21:08+00:00
author: a@qmu.jp
supersedes: 
---

# notify's thread lookup posts new roots instead of replying

# workaholic:notify's stateless thread lookup fails, posting new threads instead of replying

The workaholic:notify skill's stateless thread-lookup strategy is unreliable: it searches for an existing Slack thread by trying `fb:` and then the related issue/PR number, and when both searches come up empty, it falls back to posting a brand-new thread root in #dev-workaholic (in the status-update format, e.g. "🔵 Proposed") instead of replying into the thread that actually already exists for that item.

A real, observed instance: a routine's own reported behavior was "Ran the workaholic:notify stateless thread lookup (searched fb:, then #355 — both exhausted, no match), so posted a new thread root in #dev-workaholic in the 🔵 Proposed format, carrying the fb: key for future lookups." This fragments the conversation across multiple disconnected top-level threads for what should be one continuous discussion per FB/issue, and makes the lookup strategy self-defeating — it degrades further every time it fails and starts yet another new root.

Devise a more reliable strategy for locating the correct existing Slack thread (e.g. persisting the thread ts/permalink alongside the fb key at creation time, rather than re-deriving it via best-effort search each time) so status updates reliably land in the one correct thread instead of scattering into new ones. Reported via GitHub issue #360.
