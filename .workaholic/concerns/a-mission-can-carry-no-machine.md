---
type: Concern
concern_id: a-mission-can-carry-no-machine
mission: 
tickets: []
origin_pr: 84
origin_pr_url: https://github.com/qmu/workaholic/pull/84
origin_branch: work-20260714-000543
origin_commit: a1bb87a
created_at: 2026-07-16T11:11:08+09:00
first_seen: 2026-07-14T16:15:36+09:00
last_seen: 2026-07-16T11:11:08+09:00
severity: moderate
status: active
compound: true
resolved_by_pr: 
resolved_by_commit: 
---

# A mission can carry no machine-checkable bar at all, and may now drive unattended

## Description

Three scaffolds are empty-by-default at creation and nothing requires any of them to be filled before a mission drives itself. `create.sh` still writes `## Acceptance` as a bare comment, so a mission is born 0/0 (the missions-are-born-matching-the-lens half). 54e5ec65 demoted `gate_type`/`gate_target`/`gate_assert` to optional-and-normally-empty, and `gate.sh` remains declaration-and-ports only with the server start and Playwright drive outside the hermetic suite (the mission-quality-gate-server-start-and half). `## Experience`, which 54e5ec65 made the mission's substance, is itself a comment-only scaffold. So a mission can legitimately exist with no gate, no Experience and no Acceptance: nothing to run, nothing to read, 0/0. b9d893e6 then lets exactly that mission be stamped `drive_authorized: true`, after which drive/SKILL.md does not issue the Step 2.2 prompt at all -- while its own text concedes the gate 'becomes the only bar the agent holds itself to' unattended. That is the bar which can be absent in all three places. The Creation Interrogation (3ead50ae) is mandatory and is supposed to fill Experience and Acceptance, and commands/mission.md forbids stamping a partial interrogation -- but both are PROSE, not machine-checked, so nothing detects a stamped-but-empty mission. Each piece is defensible on its own; the set has no floor.

## How to Fix

Give the authorization a machine-checked floor rather than a prose rule: have `mission/scripts/drive-authorized.sh` refuse to authorize a mission whose `## Acceptance` is empty (progress.sh already computes total; total==0 means the plan does not exist), and consider requiring a non-comment `## Experience`. That puts the check where the decision is made and where a test can reach it -- the same argument that made the resolver a script rather than prose in the first place. Alternatively require create.sh to scaffold a first acceptance criterion, which is what missions-are-born-matching-the-lens asked for.
