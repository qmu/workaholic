---
type: Feedback
title: Hermetic smoke suite fails off the routine image on the argv-ceiling fixture
kind: instruction
source: discussion
created_at: 2026-08-12T23:18:18+00:00
author: a@qmu.jp
supersedes: 
---

# Hermetic smoke suite fails off the routine image on the argv-ceiling fixture

Source: https://github.com/qmu/workaholic/issues/427 (opened by tamurayoshiya, assigned to tamurayoshiya)

The hermetic smoke suite does not pass off the routine image. Measured 2026-08-12 22:00 UTC on the operator server (Amazon Linux 2023, aarch64): `node scripts/test-workflow-scripts.mjs` ends **2423 passed, 1 failed**. The failing assertion is "and its window_events survived the transport change" (`scripts/test-workflow-scripts.mjs:7122`), which expects `missions[0].window_events` to have length 1 on the argv-ceiling corpus.

The same suite passes in CI (`Validate Plugins`, on every merged pull request today) and in the routine web sessions, so the failure is environment-sensitive rather than a straight regression — the suite is supposed to be hermetic, and a suite that only passes on some machines cannot serve as the local verification gate CLAUDE.md names it as.

The ask, in the reporter's words: reproduce and localize first — run the single fixture on both environments and diff what `scan-window.sh` emits for `window_events`; suspects are locale/tool differences the transport change exposed (the file-not-argv path landed via the PR #391 lineage). Then make the fixture deterministic across environments — fix the script if the event is genuinely dropped, or pin the fixture inputs if the divergence is environmental — keeping the suite hermetic.

The reporter's suspicion (locale/tool differences around the argv-ceiling transport change) is a hypothesis to test, not the diagnosis.
