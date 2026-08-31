---
type: Feedback
title: superseded proves the tickets landed, not that the branch is empty
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-31T20:34:26+00:00
author: a@qmu.jp
supersedes: 
---

# superseded proves the tickets landed, not that the branch is empty

Source: https://github.com/qmu/workaholic/issues/788

kind: instruction / source: development / subject: person:a@qmu.jp

Measured 2026-09-01, on a consuming repository. The tick reported two claims as finished and
asked for their branches to be deleted. Neither branch is finished. Diffed against the base
they were called superseded on, one carried a documentation section of +46 and its English
counterpart of +50 — a whole section recording what a client actually meets at the entrance,
measured from outside — and the other carried three files totalling about three hundred lines,
all absent from the base. Deleting them, as the tick asked, discards all of it: it exists in
no other ref.

`superseded` is one of the two verdicts the claim protocol classifies as a **proof**, and
`retire-claim.sh` acts destructively on exactly that strength — its own header says so. The
proof is that the unit tickets are archived on the base, or that a merged pull request has
this branch as its head. Both branches satisfy the first form: their tickets landed, through
**different** branches, which each drove the same tickets and merged. So the tickets are
archived on the base and the branch that also holds unmerged work reads as proved-empty.

The step from *the tickets are archived* to *the branch holds no work* is the gap. It holds
when a branch carries only its own unit tickets. It fails whenever a branch carries anything
else — a doc section written alongside, a verification script the ticket did not name, a
second run work — and nothing in the derivation notices, because the branch own diff against
the base is never read.

The reasoning is also inverted here. The header states the safety argument as *the branch can
never land and holds no work*, and offers as recovery that a deleted branch is *recoverable
from the base own history, its content is on the base — that is what superseded means*. For
these two branches the parenthesis is false, and it is the load-bearing half: the content is
not on the base, so the stated recovery does not exist.

What makes this hard to catch is that the 403 blocking the delete has been keeping the two
branches alive by accident. A container and a CI job both refuse `git push --delete` here, so
the destructive act has never actually run against them — and the tick has been reporting that
refusal as the problem for five days. Repairing the delete without repairing the verdict would
turn a reported nuisance into a silent loss on the first tick after the fix.

What would settle it: a branch own diff against the base is one call and it is the fact the
verdict is asserting. Reading it — the branch is empty against the base, so there is nothing to
lose — makes `superseded` mean what its header already claims, and costs one `merge-base` plus
one `diff --quiet`. A branch whose tickets are archived but whose diff is non-empty is a real
and different state: the work is stranded, not finished, and it wants a person told rather than
a branch deleted.
