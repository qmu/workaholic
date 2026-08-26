---
type: Feedback
title: persist-log.sh carries a record to the base but never its OKF index entry
kind: insight
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T03:00:18+00:00
author: a@qmu.jp
supersedes: 
---

# persist-log.sh carries a record to the base but never its OKF index entry

`persist-log.sh --record <path>` puts a tick's feedback record on `main`, and `feedback/scripts/create.sh`
also regenerates `.workaholic/feedbacks/index.md` and stages it. The persist carries **only the named
record paths** — it contains no reference to `index.md`, `refresh-index.sh` or the OKF bundle at all —
so the record lands on the base and the index that is supposed to list it does not.

Measured on tick `20260826-025113`. Two records were carried (`persist-log.sh` reported
`"records": [{"state": "carried"}, {"state": "carried"}]`, commit `c6908aa`) and both are present in
`origin/main`'s tree. `origin/main:.workaholic/feedbacks/index.md` ends at
`20260826022235-tie-missions-to-strategies-and-let-propose-plan-them.md` and names neither of them.
The regenerated index stayed behind in the caller's checkout, which a routine's container then discards.

This breaks the OKF floor on the one area a routine writes most often: `.workaholic/README.md` states
the bundle indexes are regenerated before each knowledge commit, and a reader who trusts the index —
including `refresh-index.sh`'s own idempotency check on the next run — sees an area whose newest records
do not exist. It compounds silently: nothing reports it, because the persist truthfully reports the
record as `carried`.

The fix is not obviously "carry index.md too". The index is a *generated projection* of a whole area, so
two containers persisting on the same day would each carry a projection derived from a different base and
the last write would drop the other's entry — which is exactly the clobbering the record-level union was
designed to prevent. Regenerating the index **inside the publish tree**, after the records are staged
there and before the commit, is the shape that survives concurrency: the projection is then derived from
the base the commit is actually built on. Either way it is a ruling, and it belongs with whoever owns the
`--record` seam added on 2026-08-23.
