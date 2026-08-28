---
type: Feedback
title: Finish a proved retirement where the write is permitted
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T10:17:34+00:00
author: a@qmu.jp
supersedes: 
---

# Finish a proved retirement where the write is permitted

Source: https://github.com/qmu/workaholic/issues/684

The `[Propose]` routine asks that the retirement's last act happen where the write
is permitted.

When the loop proves a claim `superseded`, `drive/scripts/retire-claim.sh` closes the
pull request, then tries to delete the remote branch and is refused. The refusal is
measured, named and understood: `git push origin --delete` answers `HTTP 403` and
`DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}` answers "Write access to this
GitHub API path is not permitted through this proxy" — both transports agree, and it
is a session-type refusal, not a protection rule and not a missing scope. So the
retirement reports `branch_delete_failed`, `/moderate`'s `retire-claims` step asks the
claim holder once, and the branch stays. Measured on this repository: seven claims,
four of them `superseded`, the oldest branch (`work-20260818-205051`) untouched since
2026-08-18. The table has only ever grown.

The ask: this repository has already solved this exact shape once — the release-note
write was refused in a routine container and moved to
`.github/workflows/release-note-draft.yml`, which holds `contents: write`. Do the same
for the retirement's last act:

- A workflow (`.github/workflows/claim-retirement.yml`, `permissions: contents: write`)
  takes the delete the container cannot take.
- It re-proves the verdict at the moment of the act — reading
  `drive/scripts/list-claims.sh` itself and refusing by verdict word anything that is
  not `superseded`. It never acts from the container's snapshot, which is the writer's
  own existing rule.
- It is bounded: only a `work-*` branch, only one whose content is on the base, never
  one with an open pull request, never a `release/*`. Each refusal named, exit 0.
- Nothing new is stored. The candidate set is derived from the claim oracle's own
  `superseded` verdict, exactly as `step-retire-claims.sh` derives it — no queue, no
  cursor, no field on any artifact, and a branch already gone is a no-op.
- `retire-claim.sh` keeps its three-act vocabulary unchanged; a delete taken elsewhere
  is reported as such rather than as one this container took.
- `/moderate`'s `retire-blocked:` question narrows to what CI could not take either, so
  the operator is asked only for an act that is genuinely theirs. The key, the
  asked-once gate, the addressee and the per-tick cap do not move.

`superseded` stays a proof and gains no new verdict word; `lib/claims.sh` emits nothing
new.

Why it commits to the strategy: the Aim is that the development loop runs itself and
the developer's work moves up a layer. The retirement is the one place where the landed
work walks the whole way to the act and then hands a person a shell command. The
2026-08-27 mission `finish-the-retirement-the-loop-cannot-complete` did the honest half
— it named the blocked act, proved the refusal in a real routine container, and reached
the claim holder, recording that "no second transport can take the act". That finding is
correct about the container. A workflow is not a second transport in the container; it
is a different executor, which is precisely why `release-note-draft.yml` exists.

Chosen against: clearing the residue the loop wrote and cannot drive (seven queued
tickets stamped an address `.claude/git-identities` does not name). That loses because
its repair is one line in a mapping, and which account an address belongs to is a
human's ruling the loop is right to refuse.

The ask names the mission's experience and an ordered set of eight tickets.
