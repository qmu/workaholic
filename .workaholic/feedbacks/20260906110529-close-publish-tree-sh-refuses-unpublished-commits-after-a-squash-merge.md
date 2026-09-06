---
type: Feedback
title: close-publish-tree.sh refuses unpublished_commits after a squash merge
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T11:05:29+09:00
author: a@qmu.jp
supersedes: 
---

# close-publish-tree.sh refuses unpublished_commits after a squash merge

Source: https://github.com/qmu/workaholic/issues/1002

`close-publish-tree.sh`'s `unpublished_commits` guard asks *is this tip on a remote ref?* to
answer *would closing lose work?* Two rulings this repository made for good reasons pulled
those two questions apart: every pull request the loop merges is squash-merged (2026-09-01),
which leaves the branch tip on no ancestry path from the base, and `delete_branch_on_merge`
removes the branch at the merge (`/workaholify` §2). After both, the publish tree's tip is
reachable from no remote ref at all, and the guard concludes the work would be lost when in
fact it has already landed by the very merge that made the tip unreachable.

Measured 2026-09-06 by a `/specificate` run that had just landed
https://github.com/qmu/workaholic/pull/1001 successfully: every artifact was verified present
on `origin/main` and the close step still refused, so the run discarded the tree by hand.

Blast radius: the publish tree is the only way an artifact writer reaches the base, so this
sits on the tail of every `/specificate`, every `/ticket` and every `/mission` publication —
the whole intake side of the loop. It stays invisible because the refusal arrives after the
merge, so the artifacts are safe and the run reports success on everything a person looks at.
What it costs is the close: each run makes that judgement itself, which is the shape where one
of them eventually judges wrong and discards something that had not landed.

The repair the ask names is not to delete the guard but to give it a term that survives a
squash: ask whether the tree's content reached the base, the way `superseded` already answers
exactly this question from the tree rather than from ancestry, precisely because a
squash-merged branch is never an ancestor of the base.

Note beside the record: this run's own publication for issue #1000 closed cleanly minutes
before this record was written, so the refusal is not universal on every close — what is
established is the shape and the one measurement, not a rate.

This record is knowledge, not an ask the loop may act on: it was written by a loop session
about the loop's own apparatus, so `/specificate` refused it `self_authored` under
`rules/workaholic.md`, *What May Originate a Mission*. The operator rules on it.
