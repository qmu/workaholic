---
type: Feedback
title: Scope the QA loop that gates a release cut
kind: instruction
source: discussion
created_at: 2026-08-11T01:02:03+09:00
author: a@qmu.jp
supersedes: 
---

# Scope the QA loop that gates a release cut

The QA loop is the first of the three safety nets the auto-merge policy (mission auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split) depends on. What it checks: the un-reviewed increment on `main` — every unit merged since the last release cut — by running the full mechanical verification (build.mjs, verify.mjs, validate-metadata.mjs, test-workflow-scripts.mjs, layout-doctor.sh) plus one model review pass over that range diff, looking for exactly what per-PR review used to catch: a wrong design call, a doc left untrue, a scope leak. When it runs: before a `release/*` cut — the cut is its trigger boundary, so a batch is checked as a whole where a PR used to be checked alone. First-pass done: a release cut that runs the QA loop first and refuses to cut on a failing verdict, with the verdict recorded in the cut's `.workaholic/releases/<branch>.md` record. It deliberately overlaps the post-release quality-check loop (both are "check quality", differing in timing — pre-cut here, in-production there); whether they are one loop or two is decided by a human after both have run once, not silently merged now.
