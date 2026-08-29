---
type: Feedback
title: Land the four pull requests that have been conflicting with main since 2026-08-26
kind: instruction
source: development
subject: observer_ai:tamurayoshiya
created_at: 2026-08-29T09:16:57+00:00
author: a@qmu.jp
supersedes: 
---

# Land the four pull requests that have been conflicting with main since 2026-08-26

The /moderate tick's `stuck-prs` step reported `blocked` on tick `20260829-085055`: four
open pull requests the loop itself opened cannot merge into `main` because they conflict
with it. The oldest has been conflicting since 2026-08-26 — three days of finished,
unmergeable work.

| PR | Title | Head branch | Opened |
| -- | ----- | ----------- | ------ |
| #622 | Validate the moderation tick's window, and report what each step found | `work-20260826-103318` | 2026-08-26 |
| #625 | [Proposal] Say when the loop has run out of direction | `work-20260826-110530` | 2026-08-26 |
| #633 | Deploy the docs site to a Cloudflare Worker on merge to main | `work-20260826-134108` | 2026-08-26 |
| #688 | [Proposal] Deliver what the loop already knows to the person who can act | `work-20260828-122456` | 2026-08-28 |

**Why it is the loop's own debt.** A conflicted pull request is invisible to every other
reader the tick has: `merge-conflicts` reads the same set and reported `none conflicted`,
`stalled-units` reads a claim's tip age rather than its mergeability, and
`undelivered-units` reads a *recorded* merge refusal, which a conflict never produces
because no merge was ever attempted. So the only signal is a `blocked` line in the tick
log, which reaches nobody.

**The repair the finding names.** Give the loop a path from *this unit conflicts with the
base* to *the conflict is resolved and the unit is re-delivered*, on the claim protocol's
own terms: the branch belongs to whoever holds its claim, so a driving run merges the base
into its **own** claim branch, regenerates what the repo's tooling generates rather than
resolving it by hand, validates, and pushes — never a rebase or a force-push, and never a
push into a branch this run does not hold. A unit whose conflict cannot be resolved
mechanically is what stays a question.

**Related, already captured**:
`.workaholic/feedbacks/20260829081653-the-generated-okf-indexes-and-claude-md-are-the-seam-every-stuck-pull-request-collides-on.md`
names the *seam* these four collide on (the generated OKF indexes and `CLAUDE.md`).

**Discrepancy worth checking while repairing**: `merge-conflicts` and `stuck-prs` read the
same seven open pull requests this tick and disagreed — `none conflicted` against four
conflicted. Two readings of one fact drifting is exactly the shape this repository repairs
by giving the fact one reader.

Source: https://github.com/qmu/workaholic/issues/710
