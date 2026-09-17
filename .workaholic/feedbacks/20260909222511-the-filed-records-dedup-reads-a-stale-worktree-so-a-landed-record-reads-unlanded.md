---
type: Feedback
title: The filed-records dedup reads a stale worktree, so a landed record reads unlanded
kind: concern
source: development
subject: observer_ai:moderate
created_at: 2026-09-09T22:25:11+09:00
author: a@qmu.jp
supersedes: 
---

# The filed-records dedup reads a stale worktree, so a landed record reads unlanded

Source: the `/moderate` tick `20260909-130713` on this repository, from its own dedup read.

## What was measured

`filed-records.sh --step inbound-sweep --root .` answered, at this tick:

```
unlanded: .workaholic/feedbacks/20260909202359-a-proved-residue-clear-restores-to-head-…-re-creates-the-residue.md
          .workaholic/feedbacks/20260909202412-question-liveness-retires-an-escalation-key-…-as-a-string-node.md
```

Both records **are on the base**. They were added by `38e040d7b Record the tick's feedback
findings`, which `git branch -a --contains` reports on `remotes/origin/main`:

```
20260909202359: worktree=absent  origin/main=present
20260909202412: worktree=absent  origin/main=present
git rev-list --count HEAD..origin/main -> 4
```

The reader is behaving exactly as written. Its contract is stated in
`moderate/reference/workflow.md`: *"A container is a fresh clone of the base, so present-in-the-tree
is on-the-base."* It asks the **worktree** whether the path is there, and treats an absence as
`unlanded`, which the same paragraph defines as *"treated as not filed so the next tick re-derives
the finding."*

## Why the premise no longer holds

That premise was true while the tick ran in a routine-fired container that was discarded after
every run. Since 2026-09-02 the loop turns **locally**, in a session whose checkout persists
between ticks — the same change that took `.workaholic/moderations/` off git entirely, on the
stated ground that *"the tick's container is discarded"* had stopped being true.

A persistent checkout is normally **behind** the base: `/moderate` runs no `sync-main.sh` (that is
`/drive` §1's seam), and `persist-log.sh --record` pushes the record to `main` without moving the
caller's `HEAD`. So a record this tick carries is on the base and, an hour later, every record
carried by *another* worker in the meantime reads `unlanded` here. Four commits of drift was
enough to falsify two of the four claims read this tick.

## The consequence is duplicate records, which the loop is already paying for

`unlanded` means *not filed*, so the next tick re-derives the finding and files it again. That is
the same failure mode `20260909171204` measured on the issue side — one standing condition
producing one artifact per hour until a brake it starves. Here the false negative is in the dedup
itself, so nothing even reports the duplication.

It composes with `20260909202703` (the record publication carries a record to `main` without
refreshing the area index) rather than duplicating it: that record is about what the carry
**writes**, this one is about what a later tick can **read back**. Both come from the same root
cause — the publication seam writes to the base and leaves the caller's checkout where it was.

## What this names

The reading `filed-records.sh` wants is *is this path on the base*, and the worktree is only a
proxy for it. Asking git directly — `git cat-file -e <base>:<path>`, with the base resolved the
way every other reader here resolves it — answers the actual question in a checkout of any age,
costs no network, and keeps `readable: false` meaning *could not look* exactly as it does now. A
path present in neither the worktree nor the base stays `unlanded`, which is the case the rule was
written for.

## Non-goals

No change to the append-only log, no pruning of any claim line, no sync or fetch added to
`/moderate`, and no relaxation of *an `unlanded` record counts as not filed* — the repair is to
stop misreading a landed record as unlanded, not to trust the claim line.
