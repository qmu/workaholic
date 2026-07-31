---
type: Feedback
title: Raise the too-large-commit ceiling by 1.5x to 750 lines
kind: instruction
source: slack
created_at: 2026-07-31T17:14:56+00:00
author: noreply@anthropic.com
supersedes: 
---

# Raise the too-large-commit ceiling by 1.5x to 750 lines

Reported by the requester as [qmu/workaholic#129](https://github.com/qmu/workaholic/issues/129).
Recorded in the reporter's own words.

## The instruction

The `too-large-commit` size gate is too strict and its ceiling should be raised by a factor of
1.5. The current threshold is 500 non-generated changed lines per commit; a genuine, in-scope
commit landed at 685 changed lines and tripped the gate (flagged in PR #124), which is the kind
of case the requester considers over-blocking rather than catching a real problem. The requested
fix is to raise the ceiling to 750 changed lines (500 x 1.5).

## What was measured (2026-07-31)

`MAX_COMMIT_CHANGED_LINES=500` sits at `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh:40`,
and all four breaches on record reproduce exactly under the gate's own counting rules:
[fa8033d3](https://github.com/qmu/workaholic/commit/fa8033d3) 502 (spec batch),
[5b2b2a7b](https://github.com/qmu/workaholic/commit/5b2b2a7b) 685 (PR #124, the commit named
above), [044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b) 701 (pure relocation), and
[1179d916](https://github.com/qmu/workaholic/commit/1179d916) 772 (implementation). A 750 ceiling
clears the first three and still flags the fourth — the one the open mission says *should* stay
flagged. Across the last 153 non-merge commits, 13 breach at 500 (8.5%) and 7 still breach at 750
(4.6%), so the raise clears 6 of the 13.
