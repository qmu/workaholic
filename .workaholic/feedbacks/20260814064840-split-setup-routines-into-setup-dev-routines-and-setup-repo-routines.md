---
type: Feedback
title: Split /setup-routines into /setup-dev-routines and /setup-repo-routines
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-14T06:48:40+00:00
author: a@qmu.jp
supersedes: 
---

# Split /setup-routines into /setup-dev-routines and /setup-repo-routines

# Split /setup-routines into /setup-dev-routines and /setup-repo-routines

Split the existing `/setup-routines` command into two. **`/setup-dev-routines`** configures the current routines (Propose / Implement) — the existing behavior of `/setup-routines`. **`/setup-repo-routines`** configures routines that belong to the repository rather than the developer: these are intended to be configured by only one account within the dev team (either one designated person, or a project/service account), not by every team member individually. As the initial trial routine to implement under `/setup-repo-routines`, the ask names a routine that runs `/ship` once per hour to update the release notes.

Source: https://github.com/qmu/workaholic/issues/451
