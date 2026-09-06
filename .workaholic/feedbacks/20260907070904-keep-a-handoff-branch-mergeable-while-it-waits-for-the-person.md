---
type: Feedback
title: Keep a handoff branch mergeable while it waits for the person
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-07T07:09:04+09:00
author: a@qmu.jp
supersedes: 
---

# Keep a handoff branch mergeable while it waits for the person

# Keep a handoff branch mergeable while it waits for the person

Source: https://github.com/qmu/workaholic/issues/1062

Keep a handoff branch mergeable while it waits for the person, the way a reported claim already is.

Measured, here, now. Mission `report-each-tick-in-the-originating-codex-chat`, claim `work-20260906-023953`, PR **#993**, open ~25 hours. Acceptance **2/3**. Six of its seven tickets are **already driven** and archived on that branch under `.workaholic/tickets/archive/work-20260906-023953/`; the mission's `## Changelog` records all six, plus the branch story and `run recorded (+1.5h)`. The seventh — `20260906022907-prove-the-behaviour-in-the-operator-s-own-codex-chat.md` — carries a prose `verification_handoff:` naming a live run in the operator's own Codex chat, which is a genuine external limitation and must keep its handoff. The claim therefore reads **`awaiting_verification`**, correctly, and PR #1057's mixed-declaration route is working: `claims_declared_split` reads `held == total` with total **1**, because `claims_remaining_tickets` reads the queue at the branch tip. **The branch reads `mergeability: content`**, colliding on `.workaholic/missions/active/report-each-tick-in-the-originating-codex-chat/mission.md`, `CLAUDE.md` and `plugins/workaholic/skills/work/reference/other-agents.md`; its last commit is from 2026-09-06T04:13+09:00 and `main` has taken many merges since.

Why it matters: six tickets of finished work are on a branch that is drifting out of mergeability, and **nothing in the loop is keeping it current**. `catch-up-claim.sh` exists precisely to do that, and `list-catchable-claims.sh` offers only claims whose verdict is `report_undelivered` or `queue_drained`. An `awaiting_verification` claim is excluded — so the one class of branch that is *guaranteed* to sit open for a long time is the one class the catch-up never touches. The handoff route says the pull request opens and stays open; it does not say the work on it should decay while it waits.

The shape asked for is to let `list-catchable-claims.sh` offer an `awaiting_verification` claim on the same terms it already offers the others: `mergeability` of `mechanical` or `content`, this identity's own claim. **The catch-up only, never the delivery.** `catch-up-claim.sh`'s merge half is bound to `queue_drained` for a stated reason and must stay there — a handoff unit's pull request waits on a person by definition, and merging it would be exactly the hand-back this repository forbids in the other direction. So: catch up, regenerate, run the fast checks, push, and report `delivery: not_attempted: awaiting_verification`. Every existing refusal stays — `content_conflict` when the merge itself cannot settle a hunk, `scan_held`, `pull_request_reviewed`, `not_my_claim`, `validation_failed`, `push_failed` — each by its own word, nothing pushed on a refusal.

Non-goals, in the reporter's own words: do not merge a handoff pull request; do not clear, release, resume or retire the claim; do not weaken the handoff declaration or re-derive it; and do not widen the delivery half of `catch-up-claim.sh`.
