---
created_at: 2026-08-01T03:04:20+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260731-185904
---

# Retire `status: draft` — the pull request *is* the draft, and a mission that reaches main has an owner

## Overview

A mission has no business carrying a `draft` state, because **the pull request already is the draft.** A mission sitting in an unmerged PR is exactly a mission under discussion; discussing and reviewing it there is what makes it one. So the rule is simply: **merged to `main` means do it.** A mission that merges while still marked `draft` has been reviewed once and then gated a second time by `/mission approve`, whose only remaining job is to undo the first gate.

**And a mission that reaches `main` names who will do it.** "Merged means do it" is only meaningful if somebody is doing it — an owner is not bookkeeping that approval happened to carry, it is part of what makes a mission actionable at all. So the owner requirement does not disappear with the gate; it becomes a property of every mission on `main`, and the PR is where it gets filled in.

The `draft` state made sense in the world it was designed for: `/propose` pushed a mission straight to `main` (J1), so *something* had to stop `/drive` claiming work nobody had looked at, and `status: draft` was that something. J4 replaced the premise. The review moved to the PR, and the flag stayed — so today `/propose` opens a reviewable PR **and** marks its content unapproved, which is the same gate twice with the second one requiring a manual command.

The observable cost is on `main` right now: six active missions, every one `draft` or `no_tickets`, none claimable, and `/drive` reporting `pending` tick after tick with nothing it may touch.

## What replaces it

**Merging the pull request is the approval.** A mission on `main` is a mission the project accepted. What `approve.sh` carries today has to land somewhere else rather than disappear:

- **`merge_policy`** — recorded at *creation* instead of at approval, adopting the ticket rule exactly: **absent means `review`**, the conservative default. A mission that arrives with no policy routes to a PR, which is the safe reading.
- **Ownership** — **kept and required**, not dropped. A mission on `main` must name who will do it (developer's ruling, 2026-08-01). What changes is only *when* it is filled in: at approval before, at proposal time now.

  **`/propose` derives the owner rather than leaving it empty**, and it has the material to do so: the owner is **the original requester of the feedback the mission grew from** — the record's `author`, which is who reported it — **or whoever that requester named instead**, when the record says so. A mission's `feedback:` list already points at those records, so this is a lookup, not a guess. Only when neither can be resolved does the mission arrive unowned, and then it **cannot merge until its PR assigns one**.
- **The floor** (`hooks/validate-mission.sh`: an owner, a real `## Experience`, at least one `## Acceptance` item) — **kept whole, and re-aimed**. It currently fires on `status: approved`; it must fire on **any mission in `missions/active/`**, because "the thing that can be claimed" is no longer marked by a status word. All three requirements survive, ownership included.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the status vocabulary is read by `plan-units.sh`, `list.sh`, `summary.sh`, `approve.sh`, `close.sh`, `lib/resolve.sh`, `validate-mission.sh`, and `mission-lens.sh`; removing a value from it is a change to a shared reader set, not one file
- `workaholic:implementation` / `policies/objective-documentation.md` — the surviving vocabulary and the new drivability condition must be written down where a reader finds them, with the rejected alternatives named, or the next session re-derives this argument
- `workaholic:development` / `policies/review.md` — the claim being made is that PR review *is* the approval; the change is only sound if the PR is genuinely where a mission's necessity gets judged

## Key Files

- `plugins/workaholic/skills/mission/scripts/approve.sh` — the command being retired; its three payloads are redistributed above
- `plugins/workaholic/skills/mission/scripts/create.sh` — must record `merge_policy` at creation
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` — writes `status: draft` today; its output becomes an ordinary mission whose PR is the review
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the `not_approved` exclusion disappears; `no_tickets` and `no_plan` stay
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` — the living migration; it already folds legacy `status: active`, and must now fold `draft` too
- `plugins/workaholic/hooks/validate-mission.sh` — the floor moves from "on approved" to "on any active mission", with ownership relaxed
- `plugins/workaholic/commands/mission.md` — the `approve <slug>` subcommand and its Position Report go
- `CLAUDE.md` — the lifecycle is documented as `draft | approved | achieved | abandoned | carried` in several places

## Related History

Decision I2 (2026-07-28) collapsed `drive_authorized` into `status: approved` to make the lifecycle one axis. This ticket removes the other half of that axis for the same reason the merge did: one concept, one place. Decision J4 (2026-08-01) is what makes it possible — before the PR path existed, `draft` was the only gate.

The mission `drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` already contains this analysis and should be **closed as `carried` into this ticket, or abandoned**, rather than left as a sixth unclaimable draft. Its second half (`/drive` owning its worktree from refreshed main) is already done — J3's `sync-main.sh`.

## Implementation Steps

1. **Decide and write down the surviving vocabulary** before touching code: `active` (in `missions/active/`, claimable when it has tickets) versus the three end states in `archive/`. Record the rejected alternative — keeping `draft` as an optional marker — and why it loses (an optional gate that only some artifacts carry is a gate nobody can rely on).
2. **Record `merge_policy` at creation** in `create.sh` and `scaffold-draft.sh`, absent reading as `review`. In the same pass, **seed `assignees` in `scaffold-draft.sh` from the source feedback's `author`** (or the designee it names), leaving it empty only when neither resolves.
3. **Remove the `not_approved` exclusion** from `plan-units.sh`; a mission with tickets is claimable.
4. **Re-aim `validate-mission.sh`**: the owner / Experience / Acceptance floor applies to any mission in `missions/active/` — **all three**, ownership included. This is the load-bearing step: it is what stops the gate's removal from also removing the floor.
5. **Retire `approve.sh` and the `/mission approve` subcommand**, leaving a migration note; `close.sh` is untouched.
6. **Extend the living migration** in `lib/resolve.sh` so an existing `status: draft` file becomes an ordinary active mission on the next mission-script touch, and every reader keeps a legacy-tolerance branch.
7. **Close or carry** the `drop-the-draft-gate-…` mission so it stops occupying the roadmap.
8. **Update the docs in the same change** — `CLAUDE.md`, `mission/SKILL.md`, `propose/SKILL.md`, `commands/mission.md`, `drive/SKILL.md`.
9. **Rebuild** `outputs/` (`build.mjs`).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission written by `create.sh` or by `/propose` carries no `status: draft`, and `plan-units.sh` offers it as claimable as soon as it has at least one ticket.
- `plan-units.sh` never emits `not_approved`; `no_tickets` and `no_plan` still do.
- An existing `status: draft` mission on `main` is folded to an ordinary active mission by the living migration, and is not retro-blocked by any validator.
- `validate-mission.sh` rejects an active mission with no owner, an empty `## Experience`, or an empty `## Acceptance` — an **unowned** mission on `main` is rejected, because merged means somebody does it.
- No path writes `status: approved` any more, and `/mission approve` is gone from the command surface.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with cases for: a freshly created mission being claimable, a legacy `draft` file migrating, the surviving floor rejections, and the absence of `not_approved`.
- A live `/drive` survey in this repository offers the previously-stuck missions once they have tickets.

**Gate** — what must pass before approval:

- The suite is green, the six currently-stuck missions are either claimable or closed, and the docs listed in step 8 tell the truth.

## Considerations

- **The floor is the thing that must not be lost.** Removing the gate is right; removing the *floor* would let a mission with an empty `## Experience`, or no owner at all, be claimed and driven. Step 4 is the load-bearing step, not step 3 (`plugins/workaholic/hooks/validate-mission.sh`).
- **`/propose` seeds the owner from the feedback it proposed from** — the record's `author` (the original requester), or the person that requester designated when the record names one. `scaffold-draft.sh` currently hardcodes `assignees: []`; it needs the derivation and a reader for it, alongside the existing `read-feedback-relation.sh` (`plugins/workaholic/skills/propose/scripts/scaffold-draft.sh`).
- **Unowned survives only as the unresolvable case**, and then the PR must assign before merge — so "who does this" is still a question the pull request answers out loud rather than a state that can reach `main`.
- Six missions on `main` are currently `draft`. The migration must be a fold, not a rewrite — the files stay, one key changes (`plugins/workaholic/skills/mission/scripts/lib/resolve.sh`).
- `/propose` currently advances its cursor when the PR is *open*, not merged. With the PR as the sole approval, a proposal that is never merged is a proposal that was rejected — which is correct, but worth re-reading in `propose/SKILL.md` once `draft` is gone.
