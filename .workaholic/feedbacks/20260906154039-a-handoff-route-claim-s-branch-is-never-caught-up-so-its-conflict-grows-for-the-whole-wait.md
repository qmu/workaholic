---
type: Feedback
title: A handoff-route claim's branch is never caught up, so its conflict grows for the whole wait
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T15:40:39+09:00
author: a@qmu.jp
supersedes: 
---

# A handoff-route claim's branch is never caught up, so its conflict grows for the whole wait

# A handoff-route claim's branch is never caught up, so its conflict grows for the whole wait

Source: https://github.com/qmu/workaholic/issues/1032

## What was measured

Claim `report-each-tick-in-the-originating-codex-chat`, branch `work-20260906-023953`,
pull request #993, on 2026-09-06 at 06:30 UTC:

- `list-claims.sh`: `reported: true`, `declared_handoff: true`, `stale: false`,
  `resume_reason: awaiting_verification`, `mergeability: content`.
- `claim-mergeability.sh`: 7 conflicted files — 5 `mechanical`
  (`.claude-plugin/marketplace.json`, `.workaholic/stories/index.md`,
  `outputs/workflows/.codex-plugin/plugin.json`, both `plugin.json` manifests) and
  2 `content` (`.workaholic/missions/active/report-each-tick-in-the-originating-codex-chat/mission.md`,
  `CLAUDE.md`).
- `list-catchable-claims.sh`: `count: 0`.
- `loops/scripts/claimable-units.sh`: `catchable: 0`, `claimable: 0`.

The branch's last commit is 2026-09-06T04:13:25+09:00. Six of the unit's seven tickets are
already implemented and archived on it; only the proof ticket remains, and its handoff was
verified real — it needs a tick run in the operator's own Codex chat, which no session here
can reach.

## The gap

`list-catchable-claims.sh` answers this identity's **reported** claims whose mergeability is
`mechanical` or `content`, and the catch-up act (`catch-up-claim.sh`) delivers only a
`queue_drained` claim. An `awaiting_verification` claim is therefore reached by neither: its
pull request stays open by design for as long as the handoff waits, and nothing ever catches
its branch up to the base.

So the conflict is not a state the loop passes through — it is a state that **grows** for the
whole duration of a handoff. Every merge into `main` adds to it. Here, a version-manifest and
generated-index set (all `mechanical`) plus `CLAUDE.md` and the mission's own file.

The distinction the current shape misses is that **catching a branch up is not delivering it**.
The handoff's bound is that the loop must not *merge* the pull request; keeping the branch
mergeable takes no decision away from the person who eventually will.

## Why this matters here specifically

This is the pull request carrying the Codex external-process work the operator asked for. It
holds finished work that cannot land, and the longer the handoff waits the more of that work
sits behind a conflict a person will have to resolve by hand.

## What this record does NOT ask for

No gate is proposed for removal. The handoff route itself is correct and this record does not
argue the pull request should be merged. Whether an `awaiting_verification` claim should be
catchable — and if so, whether the act must refuse delivery explicitly rather than by verdict —
is an engineering judgement for the operator, not one this loop should make about its own
apparatus.

## Provenance

Written by the loop about the loop's own machinery (`subject: observer_ai`), so it is
record-only under the `self_authored` rule and originates no mission.
