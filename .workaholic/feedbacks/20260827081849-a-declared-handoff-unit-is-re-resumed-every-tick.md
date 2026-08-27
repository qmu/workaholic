---
type: Feedback
title: A declared handoff unit is re-resumed every tick
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-08-27T08:18:49+00:00
author: a@qmu.jp
supersedes: 
---

# A declared handoff unit is re-resumed every tick

# A declared handoff unit is re-resumed every tick

Source: https://github.com/qmu/workaholic/issues/651

A unit whose remaining ticket declares `verification_handoff:` is being re-resumed every tick,
which is the one thing that declaration exists to prevent. `CLAUDE.md` states the intent in as
many words — *"a gate item is re-claimed and re-failed every tick forever, while a standing
handoff claim is not re-surveyed and costs nothing per tick"* — written against a measured
failure of nine consecutive resumes over nine hours for zero lines of implementation. Measured
on PR #647 (`work-20260827-003544`, unit `make-workaholify-converge-the-account-s-routines`) on
2026-08-27: `c7965a58` at 02:14 UTC was the `[Implement]` run that routed the unit to `handoff`
and opened #647; `036b18f4` at 06:43 was a later tick taking the same unit over again; and
`0c8c8656` at 06:45 recorded hours against it. The second resume could implement nothing — the
ticket's step 1 is a measurement against a live account routine, and no clock-fired container
carries a `RemoteTrigger`-family tool — so it produced two commits and a CI run. The reporter
localizes it to the claim oracle having no reading for *this unit's remaining work is declared
undrivable here*: after `/story` opens the pull request the claim reads `parked_with_pr`,
`resumable: true`, whose own contract assumes the follow-up tickets on the branch are drivable,
and nothing downstream consults `verification-handoff.sh` again after the route. `drive/SKILL.md`
§6 says a handoff unit's claim stays standing, and it does — but standing is not the same as
unoffered. What the ask wants is a reading that keeps a **declared** handoff out of `resumable[]`
while its declaration still holds, with three things ruled on explicitly rather than assumed:
whether the seam is a new claim verdict or an exclusion in `plan-units.sh`; what makes such a
unit resumable **again** once the declaration is satisfied and the ticket driven, since an
undroppable unit is the failure in the other direction; and whether `parked_with_pr` should
narrow or a sibling reason should sit beside it, the `report_undelivered` split of 2026-08-27
being the recent precedent for the second shape. The reporter states this is a report and not a
diagnosis: the localization should be reproduced before anything changes, since the survey and
the claim oracle each have their own reasons for the current behaviour.

The ask declared `source: pr-event`, which is outside `create.sh`'s closed set; recorded as
`development`, the channel a PR event arrives through.
