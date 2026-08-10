---
type: Feedback
title: Scope the post-release quality-check loop
kind: instruction
source: discussion
created_at: 2026-08-11T01:03:37+09:00
author: a@qmu.jp
supersedes: 
---

# Scope the post-release quality-check loop

The post-release quality-check loop is the third safety net behind the auto-merge policy (mission auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split). What it checks once something is in production: that the released increment actually behaves — re-run the deployment confirmation method the release recorded (`confirm-release.sh`'s own evidence seam), plus whatever production signal the consuming project names (a health probe, an error-rate read, a smoke path). When it runs: after each release confirmation, once immediately and once on a delay (the first tick catches a dead-on-arrival release, the delayed one catches a slow leak). What it does on a problem: it never rolls back or redeploys on its own authority — it writes one `kind: concern`/`kind: instruction` feedback record naming the release branch and the failing signal, which the ordinary `[Propose]` → `[Implement]` chain turns into work; the release branch already being the rollback boundary, the human decision it enables is cheap and explicit. First-pass done: one scheduled check per confirmed release writing its verdict beside the release record in `.workaholic/releases/`. Deliberate overlap with the QA loop flagged rather than merged: same checks, different timing — pre-cut versus in-production — and a human decides after both have run once whether they are one loop or two.
