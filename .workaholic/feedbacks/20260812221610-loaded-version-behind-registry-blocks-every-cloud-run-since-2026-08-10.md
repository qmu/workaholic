---
type: Feedback
title: loaded_version_behind_registry blocks every cloud run since 2026-08-10
kind: instruction
source: discussion
created_at: 2026-08-12T22:16:10+09:00
author: a@qmu.jp
supersedes: 
---

# loaded_version_behind_registry blocks every cloud run since 2026-08-10

Cloud routine runs on this repository abort with loaded_version_behind_registry before surveying: the container image's baked-in plugin binding (v1.0.133) is behind the harness registry (v1.0.157), and per the 2026-08-05 decision /drive terminates pending on that drift rather than surveying through a superseded binding. First observed 2026-08-10; recurring hourly since 2026-08-12 05:37 UTC (6+ consecutive ticks as of 10:36 UTC) — every scheduled [Implement] fire stops at the gate while the queue stays claimable. The reporter proposes refreshing the container image; recorded here as the reporter's hypothesis, not the adopted design. Reported as qmu/workaholic#380.
