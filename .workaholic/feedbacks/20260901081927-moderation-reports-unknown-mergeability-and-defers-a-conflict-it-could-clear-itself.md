---
type: Feedback
title: Moderation reports unknown mergeability and defers a conflict it could clear itself
kind: instruction
source: development
subject: person:the operator of a consuming repository
created_at: 2026-09-01T08:19:27+00:00
author: a@qmu.jp
supersedes: 
---

# Moderation reports unknown mergeability and defers a conflict it could clear itself

The operator of a consuming repository reports that `/moderate` "only spews reports and shows no sign of resolving anything", and that a real moderation would "line the URLs up in order and resolve the conflicts so they can be merged in order". Measured 2026-09-01 against plugin 1.0.266, three defects hold that pattern in place.

**`stuck-prs` reports GitHub's lazy answer as a fact.** Its hourly line read `blocked: 4 pull requests whose mergeability GitHub has not computed yet (403:unknown 407:unknown 409:unknown 430:unknown)`. GitHub returns `mergeable: null` from the **list** endpoint because it computes mergeability lazily; reading each pull request individually forces the computation and answers immediately. One extra call per pull request turned all four `unknown`s into a definite answer on the first try: one `MERGEABLE/CLEAN` and three `CONFLICTING/DIRTY`. The step should do that read before it reports, and never emit `unknown` as a finding.

**`merge-conflicts` names a conflict it could resolve itself, and the conflict is the loop's own output.** All four conflicting pull requests conflicted on `.workaholic/stories/index.md` — the generated OKF index the loop writes on every unit branch. Two of the four conflicted on nothing else. Concurrent unit branches append to the same sorted block, so any two of them collide by construction; the loop manufactures the blockage and then reports it every hour as an external one.

**The `merge=union` repair does not apply where it is needed.** `.gitattributes` carries `.workaholic/index.md merge=union` and `.workaholic/**/index.md merge=union`, landed 2026-08-31 to stop exactly this, and the branch story recorded it as done. It works locally — `git --attr-source=<base> merge-tree --write-tree <base> <branch>` merges both index-only branches clean — but GitHub applies no `.gitattributes` merge strategy when it computes mergeability or when the merge button runs, so those pull requests still show `CONFLICTING` and cannot be merged from the web. Merging the base into the branch locally, where union applies, and pushing is what actually clears it: by hand that took four of five open pull requests from `CONFLICTING` to `MERGEABLE`, and the fifth needed a real content merge.

What is asked: make `stuck-prs` force the per-pull-request read before reporting; give the conflict step the repair for the case it can actually fix — merge the base into the branch where the union attribute applies and push, so an index-only conflict never reaches a person — and correct the record that says the union attribute solved this, because on GitHub it did not. As it stands the finding's own escalation path is a dead end: the step defers to a queue drained by a human question budget (20 findings held on the tick that prompted this, with the day's question slots spent), so a conflict a machine can clear waits on a person capped at ten questions a day.

Source: https://github.com/qmu/workaholic/issues/830
