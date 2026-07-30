---
type: Feedback
title: The proposal cursor cannot survive an ephemeral runner
kind: concern
source: discussion
created_at: 2026-07-30T11:06:59+00:00
author: noreply@anthropic.com
supersedes: 
---

# The proposal cursor cannot survive an ephemeral runner

## Description

This run executed the proposal batch from a Claude Code on the web scheduled routine, where the runner is an ephemeral container cloned fresh from `origin/main`. `cursor.sh read` returned `{"commit": "6963e59e...", "initialized": true}` — the cold-start bootstrap — which is exactly where the `/propose` workflow stops by contract (step 2: "On `initialized: true`, report the bootstrap and stop"). No window was ever read.

The cursor is runner-local by design (decision C1), and it lives outside the repository twice over: the state file `.workaholic/proposal-cursor` is untracked, and the ignore itself is written to `.git/info/exclude`, which is not committed either. Neither survives a fresh clone. So on an ephemeral runner every firing cold-starts, every cold-start bootstraps to the current tip, and the batch proposes nothing — permanently, not merely on a first tick. `docs/proposal-loop-runbook.md` §4's rationale ("a fresh runner must not spam proposals for months of history") is sound for the long-lived server cron the runbook describes; it silently degrades a web-scheduled runner to a no-op.

Measured here: the window between the last `Propose mission` commit (`8b4d0b8`, 2026-07-30 10:20 UTC) and the tip held 9 newly merged feedback records the batch never saw. All nine were `kind: concern`, so the judgment bar would have produced silence anyway — but that outcome was reached by hand, not by the batch, and on a tick where the window held an instruction the difference would matter.

## How to Fix

Nothing on the server path the runbook documents. If the loop is to run from an ephemeral runner, anchor the window on state that lives in the repository rather than beside it. The `Propose mission <slug>` commit ledger already exists and the runbook already names it the loop's observability trail (§5), so `git log --grep='^Propose mission' -1` is a persistent anchor that introduces no new artifact; dedup through `list-proposed-refs.sh` already makes a replayed window safe, which is the property that makes anchoring on it cheap. Whichever anchor is chosen, the choice belongs in the runbook beside the cold-start paragraph — the two rules only make sense read together.
