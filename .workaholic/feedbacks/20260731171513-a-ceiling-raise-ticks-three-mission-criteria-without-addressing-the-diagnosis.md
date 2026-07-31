---
type: Feedback
title: A ceiling raise ticks three mission criteria without addressing the diagnosis
kind: concern
source: slack
created_at: 2026-07-31T17:15:13+00:00
author: noreply@anthropic.com
supersedes: 
---

# A ceiling raise ticks three mission criteria without addressing the diagnosis

Registered while measuring [qmu/workaholic#129](https://github.com/qmu/workaholic/issues/129)
against the open mission *Make the per-commit changed-lines ceiling a rule that holds*.

## The concern

The mission lists four candidate answers and names raising the ceiling as the last of them. A
750 ceiling would satisfy **three of its seven acceptance criteria exactly as written** — 502
and 701 stop yielding a finding, 772 still yields one — while changing nothing about the
diagnosis the mission recorded. That diagnosis is not that the line sits too low but that the
rule counts the wrong thing: `too-large-commit` sums added **plus** deleted lines, so a pure
relocation pays twice (moving 260 lines costs 520), and `create-ticket` caps a split at 2-4
tickets that run 110-140 lines each, so a full spec batch breaches by construction. Both
structural cases survive the raise — at 750 a relocation of more than 375 lines still breaches
— and the mission board would read as progress regardless.

This is the failure shape the other active mission, *Make acceptance ticking measure
satisfaction, not marker shape*, exists to catch: an acceptance item that a cruder change
satisfies literally without satisfying what it was written to mean. Raising the ceiling may well
be the right call — 685 is a reasonable commit and 6 of 13 recent breaches clear — but it should
be taken as the decision the mission asks for, with the reason recorded in the scan's `lib/`,
rather than as a threshold edit that also closes three criteria on the way past.
