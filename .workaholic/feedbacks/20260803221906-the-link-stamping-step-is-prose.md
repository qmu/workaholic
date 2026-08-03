---
type: Feedback
title: The link-stamping step is prose, enforced only by tests over that prose
kind: concern
source: development
created_at: 2026-08-03T22:19:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-link-stamping-step-is-prose
owner: 
mission: [make-acceptance-ticking-measure-satisfaction-not-marker-shape]
tickets: [20260801185301-decide-the-acceptance-to-artifact-link.md, 20260801185302-establish-the-link-when-tickets-are-emitted.md, 20260801185303-make-the-ticker-measure-satisfaction.md]
origin_pr: 173
origin_pr_url: https://github.com/qmu/workaholic/pull/173
origin_branch: work-20260803-212324
origin_commit: be2a3beb
last_seen: 2026-08-03T22:19:06+09:00
---

# The link-stamping step is prose, enforced only by tests over that prose

## Description

The three emitting seams are agent protocols in `mission/SKILL.md` and `propose/SKILL.md`, not scripts, so "run `link-acceptance.sh` after emitting the set" is an instruction an agent can skip. The suite pins the instruction's presence, not its execution — which is exactly the shape of the original defect, one level up.

## How to Fix

The cheapest real check is at the source: have the emitting flow report `progress.sh`'s `unlinked` immediately after writing a mission, so a skipped step is visible in the same output. A write-time hook is the wrong tool — a proposal is legitimately unlinked at the moment it is written.
