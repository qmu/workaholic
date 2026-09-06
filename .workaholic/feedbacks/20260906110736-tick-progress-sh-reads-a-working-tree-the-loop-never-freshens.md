---
type: Feedback
title: tick-progress.sh reads a working tree the loop never freshens
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T11:07:36+09:00
author: a@qmu.jp
supersedes: 
---

# tick-progress.sh reads a working tree the loop never freshens

Source: https://github.com/qmu/workaholic/issues/1004

`skills/loops/scripts/tick-progress.sh` walks the working tree — `.workaholic/tickets/todo/`
and `.workaholic/missions/active/` as they sit in the checkout the coordinator runs in.
Nothing in the loop ever freshens that checkout, and that is deliberate: `/implement` drives
in a claim worktree and `/specificate` writes through a publish tree, both leaving the
caller's checkout byte-identical by design. So the one reading that answers *is the work
moving?* is taken from a tree that, by construction, never moves.

Measured 2026-09-06, one hour into a `/work` session:

    local HEAD:   b4a59298a
    origin/main:  c04a1146c        (2 commits ahead)
    local todo:   13 tickets
    origin todo:  17 tickets

Those two commits were the loop's own output from that same hour. The tick reported
`queue_total: 13` on every tick after the merge, because it was reading the tree as it stood
before the session started.

Why this is worse than ordinary staleness: the reading's whole job is to be a trend — this
tick's reading beside the last one is what says *draining* or *stuck*. A reading pinned to a
frozen tree produces a perfectly stable series, which reads as `stuck` — the opposite of what
was happening, which was the queue growing by four and a mission being archived. The longer
the session runs the more confident the wrong answer looks. It degrades silently, because from
the reader's point of view the tree it was pointed at is perfectly readable.

The shape of the fix the ask names: take the reading against the base, the way every other
survey in the loop already is — `plan-units.sh` freshens and reports `current` / `surveyed_sha`
/ `base_sha` precisely so a caller can tell a stale survey from a live one. Whatever it reads,
it must be able to say that it is behind. And it must not make the tick pull or check out
anything: the caller's checkout belongs to a person.

This record is knowledge, not an ask the loop may act on: it was written by a loop session
about the loop's own apparatus, so `/specificate` refused it `self_authored` under
`rules/workaholic.md`, *What May Originate a Mission*. The operator rules on it.
