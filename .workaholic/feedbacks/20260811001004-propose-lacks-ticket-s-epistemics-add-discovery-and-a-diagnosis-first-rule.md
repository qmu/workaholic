---
type: Feedback
title: propose lacks ticket's epistemics — add discovery and a diagnosis-first rule
kind: instruction
source: discussion
created_at: 2026-08-11T00:10:04+00:00
author: a@qmu.jp
supersedes: 
---

# propose lacks ticket's epistemics — add discovery and a diagnosis-first rule

Source: GitHub issue #374 (https://github.com/qmu/workaholic/issues/374), filed by claude[bot], assigned to tamurayoshiya.

The #360 chain shipped a ticket that adopted the reporter's proposed mechanism (persist the thread key) and a store candidate (committed frontmatter) that collides with the recorded P9 withdrawal — and the actual root cause (dev- is a private channel, so the default public-only Slack search returns zero for any `fb:` key by construction; verified live 2026-08-11, FB `20260811084546`) was never examined. Two structural gaps let it through:

1. The unattended propose path lacks /ticket's recognition machinery. /ticket runs history/source/policy discovery and interrogates the developer on unrecommendable forks (§2, §4b) — "where to persist" would have been asked and P9 surfaced. /propose reads only missions/queue/commits as constraints, never the decision record, and may not prompt. Fix: give /propose a discovery pass (history at minimum) before scaffolding, and have it record genuinely unrecommendable forks as explicit `open_decision` items the implementing tick must stop at, instead of silently inheriting the reporter's framing.
2. Neither path measures a failing mechanism. Discovery reads; nothing probes the live surface the failure lives on. Fix: a diagnosis-first rule for both /ticket and /propose — an ask reporting a failure of an existing mechanism yields a ticket whose step 1 is "reproduce and localize the failure" (measure the live surface), with the reporter's proposed fix recorded as a hypothesis in Considerations, never as the design.
