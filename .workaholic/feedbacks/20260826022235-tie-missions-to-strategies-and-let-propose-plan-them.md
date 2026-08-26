---
type: Feedback
title: Tie missions to strategies and let /propose plan them
kind: instruction
source: slack
subject: person:tamura_yoshiya
created_at: 2026-08-26T02:22:35+00:00
author: a@qmu.jp
supersedes: 
---

# Tie missions to strategies and let /propose plan them

## 依頼（原文ママ、#dev-workaholic）

> ミッションはストラテジに紐つく設計にしたい（必須でなくて良いが、通常ストラテジを先に作って、その文脈で指示を出していくので、今後多くのミッションはストラテジに紐つくはず）。またProposeがハウスキープに収斂しないよう、提案の粒度を大きくしたいです。Proposeにはストラテジに対する新しいミッションの立案を担わせルールがミッション単位で回るような形に整えてみて下さい。ドキュメントのアップデートも忘れず。

Source: https://github.com/qmu/workaholic/issues/604
Slack: https://qmu.slack.com/archives/C0BLL9J7FMY/p1787710134088969

## What was asked

1. **Missions should be designed to hang off a strategy.** Not mandatory — but the normal
   working order is that a strategy is created first and instructions are given in its
   context, so most missions from here on should belong to one.
2. **`/propose`'s proposals must be coarser**, so the routine does not converge on
   housekeeping.
3. **`/propose` takes on planning a new mission for a strategy**, and the loop is reshaped
   to turn at **mission** granularity rather than one change at a time.
4. **The documentation is updated in the same change.**

## Where this meets what is already built

- `/propose` is a **pure reader** of this repository: its only write is a GitHub issue,
  outside the tree. Its granularity today is one evolutionary move (`depth` |
  `breadth` | `contraction`) declared against the nearest strategy's Aim, and its
  anti-housekeeping brakes are `describing_move` and `no_evolutionary_move`.
- `/specificate` already decides cardinality: an ask that decomposes into two or more
  units becomes a mission with its whole ordered ticket set. A mission-shaped ask is
  therefore something the receiving side can already emit — what is missing is a proposing
  side that judges at that scale.
- The **strategy→mission link already exists** and adds no field:
  `strategy/scripts/attributed-work.sh` walks `strategy.feedback[] ∩ artifact.feedback[]`,
  plus the hop through a mission (`via_mission:<slug>`). `/propose` already puts the
  strategy's own `feedback:` refs on the issue it opens, and `/specificate` carries them
  onto what it emits. The retired `strategy:` relation is what a no-new-field rule
  preserves — and the ask's own "必須でなくて良い" points the same way, since a mandatory
  frontmatter field is the opposite of an optional link.
- The scale the operator ruled on 2026-08-24 — one mission of roughly 7–8 tickets per
  strategy, extended by at most one follow-up mission of 3–4 repair tickets — is the
  target this larger granularity has to hit, not exceed.
