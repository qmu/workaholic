---
type: Feedback
title: Asking the developer to review an implement PR is the wrong seam
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-16T05:07:28+00:00
author: a@qmu.jp
supersedes: 
---

# Asking the developer to review an implement PR is the wrong seam

# Asking the developer to review an /implement pull request is the wrong seam

The order given upfront is the authorization; a second look at the pull request adds
nothing the developer values. There is also no notification that would bring them to one
— `/implement` posts a single 🟢 finish line per unit into the feedback item's thread,
and a human merge is announced by nobody since `[Consent]` retired (2026-08-06), so a
pull request left open "for review" is left open for a review nobody is called to.

Measured on this run (2026-08-14): both claimed units were `merge_policy` absent ⇒
`review`, both drained their queues, both went green on CI, and both were held open by
the branch-safety `size` gate — `too-large-commit`, 527 added lines on `cdf0dd93`
(PR #467) and 509 on `8e0cf1bf` (PR #468), against a 500 ceiling. The `size` rule is
`severity: override`, overridable only by a human ruling, so the unattended run demoted
both units to the pull-request path and stopped. The developer's response: the size gate
must not hold a `review` unit's pull request open waiting for a ruling that adds no
value, and the two pull requests were to be merged.

Neither commit was oversized because the change was: `archive.sh` stages with
`git add -A`, and the run wrote a unit's later tickets before archiving its first, so
those diffs rode into the first archive commit. Neither ticket alone approaches the
ceiling.
