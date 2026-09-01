---
type: Feedback
title: A clean stranded publication is delivered by nothing
kind: instruction
source: development
subject: observer_ai:tamurayoshiya
created_at: 2026-09-01T03:24:09+00:00
author: a@qmu.jp
supersedes: 
---

# A clean stranded publication is delivered by nothing

Source: https://github.com/qmu/workaholic/issues/814

A publish-tree publication whose auto-merge was refused is delivered by nothing when its mergeability reads `clean`. Measured 2026-09-01 and reproduced by this run: `list-stranded-publications.sh` names six open publications and **five of them are `clean`** — #813, #799, #688, #635, #625 — the oldest (#625, #635) opened 2026-08-26, six days ago; every one is green, mergeable and unmerged.

The asymmetry is the finding: the loop repairs the conflicted publication and reports the one needing a person, while the publication that needs nothing but a merge is the one it drops. Three acts cover the hard case and the impossible case and drop the easy one. `settle-stranded-publication.sh` acts on `mechanical` alone and refuses everything else by name — its own header says `not_mechanical:<class>`, "`content` needs a person, `clean` needs no catch-up at all", which is true and stops there: a publication needing no catch-up also never reaches the one REST merge that follows the catch-up. `retry-undelivered.sh` is keyed on a claim's `report_undelivered` verdict, and a publish tree carries no `Claim …` commit, so the oracle gives a publication no row and that act never sees one. And `/moderate`'s `stranded-publication:<number>` question fires on `mergeability == content` only (`step-stranded-publications.sh` selects `content` for its candidates, `unanswerable` for its unreadable count and `mechanical` for its settleable count — `clean` is selected by nothing), so a `clean` publication asks nobody.

So a `clean` stranded publication is named once per `/implement` run report — a surface that dies with its container — and is otherwise invisible, indefinitely.

How it happens: `publish-tree-pr.sh` opens the pull request and attempts the merge in the same breath, so CI has not started; GitHub answers 405 and `merge-reason.sh` classifies it `merge_not_allowed`. That word is correct and not retryable by the caller — only `session_type_cannot_merge` may be retried through the connector — so the publication is stranded by a race with its own CI rather than by anything wrong with it. Reproduced on #813: refused `merge_not_allowed` at `mergeable_state: unstable`, then 35/35 checks green and `mergeable_state: clean` seven minutes later, with no mechanism that will ever deliver it.

What is asked for: give the `clean` class an owner. Either `settle-stranded-publication.sh` accepts `clean` — skipping the catch-up it does not need, re-deriving the class at the moment of the act, and taking the same single REST merge it already takes, so the act stays idempotent, reversible and refused by its own word — or the `stranded-publication` question widens past `content` so a person is told. Not both silently: the point is that exactly one of them owns the class today, and neither does.
