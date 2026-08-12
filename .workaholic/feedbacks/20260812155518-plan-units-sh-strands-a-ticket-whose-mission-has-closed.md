---
type: Feedback
title: plan-units.sh strands a ticket whose mission has closed
kind: instruction
source: discussion
created_at: 2026-08-12T15:55:18+00:00
author: a@qmu.jp
supersedes: 
---

# plan-units.sh strands a ticket whose mission has closed

Source: https://github.com/qmu/workaholic/issues/382

Reported as an inbound issue: `skills/drive/scripts/plan-units.sh` excludes a ticket from the
backlog offer whenever `read-relation.sh` returns any mission relation at all — the exclusion
reason is `mission_member`. That is correct while the mission is active, because the ticket is
then offered as part of its mission unit. It becomes wrong the moment the mission closes: only
missions under `missions/active/` are offered as mission units, so a ticket stamped with an
archived mission is offered by neither path. It sits in `todo/` and no survey, attended
(`/drive`) or unattended (`/implement`), ever proposes it again.

Reported reproduction: create a mission with three tickets, drive two, close the mission
`achieved` leaving the third in `todo/`, then run `plan-units.sh` — the third ticket appears
under `excluded` with reason `mission_member` and never under `backlog`.

Reported impact: in one repository six tickets minted from the feedback stream had been
unreachable for weeks; five were still genuinely open work. The backlog showed one claimable
item and read as a healthy, nearly-drained queue; after the stale stamps were cleared by hand
it showed nine. The failure mode named by the reporter is that the queue does not look broken,
it looks finished. Nothing is silent in the JSON — the exclusion is reported exactly as the
script's contract promises — but `mission_member` reads as "it will come through its mission",
which for a closed mission is untrue, so the report does not carry the fact that matters.

Reporter's suggested shape (a hypothesis, not an accepted design): plan-units.sh resolves each
stamped mission and counts a ticket as `mission_member` only when at least one of its missions
is still active; a ticket whose missions have all closed falls through to the ordinary backlog,
with a distinct reason such as `mission_closed` so an operator can see that a repair happened.

Two related calls the reporter explicitly left to a maintainer:

- The close path is the other candidate site — closing a mission could clear (or offer to
  clear) the stamp on each unfinished ticket, which is what a developer does by hand today.
  The reporter judges the survey-time fix stronger because it also repairs queues closed
  before the fix ships, and notes doing both is defensible.
- Liveness probably belongs next to the relation reader: `read-relation.sh` answers "which
  missions does this ticket name" with no notion of whether they are alive, and the "is this
  mission still active" question likely belongs beside that reader rather than being
  re-derived in each caller.
