---
type: Feedback
title: The record publication seam carries a feedback record to main without refreshing the area index
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-09T20:27:03+09:00
author: a@qmu.jp
supersedes: 
---

# The record publication seam carries a feedback record to main without refreshing the area index

Measured on moderation tick `20260909-110700`, immediately after
`moderate/scripts/persist-log.sh --tick 20260909-110700 --record <two paths>` reported
`{"persisted": true, "status": "filed", ... "state": "carried"}` for both.

`CLAUDE.md` states the OKF floor plainly: `okf/scripts/refresh-index.sh` regenerates the bundle
indexes **before each knowledge commit**. A feedback record is knowledge, and `--record` is the
one seam that carries one to `main`. It does not refresh.

Verified against the base straight after the carry:

    git show origin/main:.workaholic/feedbacks/index.md | grep -c 20260909202359   -> 0
    git show origin/main:.workaholic/feedbacks/index.md | grep -c 20260909202412   -> 0

Both record files are on `origin/main`; neither is named by the base's own index. The same is
true of `20260909181740-...`, carried by an earlier tick today — so this is not a one-off: the
base's `feedbacks/index.md` is behind by every record the moderation tick has ever carried.

Two consequences, both measured here:

1. **The index on `main` is wrong.** `feedbacks/index.md` is the area's entry point and it does
   not name records the base holds. Anything reading the stream through the index cannot see
   them.
2. **It manufactures residue in every checkout.** `feedback/scripts/create.sh` refreshes the
   indexes locally, so the caller's `feedbacks/index.md` gains the lines the base lacks. That
   diff never goes away by itself: the base is never updated, so every later local refresh
   reproduces it, `sync-main.sh` refuses `dirty_workspace`, and the path is classified
   `regenerable` — which `clear-proved-residue.sh` "clears" by re-running the generator that
   just produced it. Together with
   `20260909202359-a-proved-residue-clear-restores-to-head-while-its-proof-is-against-the-base-and-the-index-generator-re-creates-the-residue.md`
   this is a closed loop the checkout cannot leave.

The repair the finding names: the record publication is a knowledge commit, so it must run
`refresh-index.sh` **inside the publish tree** — where the base's own state is what is being
regenerated — and carry the refreshed area index in the same commit as the record. It must not
sweep the caller's locally regenerated index, which is the sweep `persist-log.sh`'s contract
already refuses by name.

Nothing was changed by this report. `persist-log.sh` was not modified and no index was pushed.
