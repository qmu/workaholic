---
type: Feedback
title: Notify lookup fails from search scope not search unreliability
kind: insight
source: discussion
created_at: 2026-08-11T08:45:46+09:00
author: a@qmu.jp
supersedes: 
---

# Notify lookup fails from search scope not search unreliability

Measured 2026-08-11, and it reframes issue #360: the notify thread lookup does not fail because search is inherently unreliable — it fails because it runs in the wrong scope. `#dev-workaholic` is a **private** channel, and `slack_search_public` (the default, consent-free search tool) covers public channels only, so it returns zero results for any `fb:<stem>` key by construction, however perfectly the root carries it. Verified live: the exact key `fb:20260810215745-…` returns 0 results through `slack_search_public` and both the root and its reply instantly through `slack_search_public_and_private`. The tool guidance telling agents to wait for user consent before the private-inclusive search is why an unattended routine always takes the empty-scope path, always misses, and posts a new root on every event — the self-defeating scattering #360 reported. Q1 defined the exact-string queries, the fuzzy prohibition and the two-query bound, but never pinned the search surface; that unwritten detail is the whole defect (`include_bots` defaulting to false is the same class of silent scope shrink). Consequence: the primary fix for ticket `20260810163359` is a lookup-specification fix — the notify lookup runs through the private-inclusive search with bots included, the developer's consent to that being a one-time recorded ruling for the repository's own dev channel — and the persisted-key mechanism is deferred until a scope-corrected search is measured to still miss, which also moots the storage-location question (FB `20260811084130`) unless that day comes.
