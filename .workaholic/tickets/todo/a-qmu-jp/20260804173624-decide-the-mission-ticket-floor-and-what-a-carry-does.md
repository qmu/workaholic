---
created_at: 2026-08-04T17:36:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission: make-a-mission-impossible-to-create-without-its-ticket-set
merge_policy: review
---

# Decide the mission ticket floor's exact boundary, and what a carried close does now that a bare successor is forbidden

## Overview

The rule is settled: **a mission is created with two or more tickets, or it is not a mission** (`.workaholic/feedbacks/20260804173526-a-mission-is-created-with-two-or-more-tickets-or-it-is-not-a-mission.md`). What is not settled is the boundary — the three questions an implementer will otherwise answer differently in each of the four seams.

This ticket decides them and records the reasoning. It writes no enforcement; the next ticket does that against the answers.

## The three questions

**1. What counts toward the floor, and when is it counted?**

The candidate answer: tickets carrying this mission in their `mission:` relation, present in the **same publication commit** as the `mission.md`. Counted at the publish seam, not at the write of `mission.md`.

This matters because the ordering is real, not incidental. `mission/SKILL.md` already documents that acceptance criteria are legitimately written before their tickets exist — the same is true of the mission file itself. A `PostToolUse` hook on `mission.md` fires when the file is written, which is *before* the interrogation has emitted anything, so a write-time floor would refuse the normal authoring order. The floor belongs where the mission and its tickets become one artifact: the publish commit.

**2. Is the floor exactly two, and is a one-ticket mission refused or warned?**

Two, and refused. The feedback record states the reason: one ticket has nothing to group, so the wrapper adds a board, a progress fraction and a close decision to a unit that already had its tracking. A warning would preserve the ambiguity the rule exists to remove.

Note the existing instance before deciding: `drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` (archived, 1 ticket) shipped fine. The rule is not that it did harm — it is that "mission" and "ticket" must not both name it.

**3. What does a carried close do?**

This is the one with a real cost and no obviously free answer. `close.sh --successor-title` mints a successor from the predecessor's unmet acceptance items and emits **no tickets at all** — so under the rule it produces a violation by construction, every time. It did so on 2026-08-04, and that instance is live on `main`.

Three options, and the ticket must pick one and record why:

- **(a) The close emits the successor's ticket set in the same pass.** Consistent with the rule and with how every other creation seam will work. Cost: `close.sh` is a bookkeeping script that would gain a planning responsibility, and the planning input (what the remaining tickets *are*) is not derivable from the unmet acceptance items — a person or an interrogation must supply it.
- **(b) `--successor-title` is refused; a carry must name an existing mission (`--successor <slug>`).** Cheapest to implement and keeps `close.sh` bookkeeping-only. Cost: a genuine "this direction continues but nothing suitable exists yet" carry has no path, and the developer must create the successor first — which is fine, because creating it *is* the interrogation that produces its tickets.
- **(c) A carried successor is exempt from the floor.** Rejected on its face and recorded as rejected: the live violation was produced exactly this way, and an exemption that covers the only seam that has ever produced a violation is not a rule.

**Recommend (b)**, with the mission-creation path as the sanctioned way to mint a successor. It keeps each script's responsibility where it is, and the thing it forces — plan the successor before declaring it — is the behavior the rule is asking for. Record (a) and its cost as the rejected alternative.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — the boundary must be written where the next implementer reads it, not inferred from four separate call sites
- `workaholic:design` / `policies/history-structures.md` — the artifact kinds (feedback / ticket / mission) are the repository's record structure; a floor that keeps them disjoint is a structural decision, not a lint
- `workaholic:implementation` / `policies/observability.md` — a refusal that names only the rule and not the alternative leaves the author unable to act

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md` — the Creation Interrogation, and where the decided boundary is written
- `plugins/workaholic/skills/mission/reference/schema.md` — carries the acceptance-link contract, whose ordering argument this decision reuses
- `plugins/workaholic/skills/mission/scripts/close.sh` — the carry seam; question 3 is about this file
- `plugins/workaholic/skills/mission/scripts/create.sh` — mints the scaffold, currently with no floor
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` — the unattended creation path
- `.workaholic/feedbacks/20260804173526-a-mission-is-created-with-two-or-more-tickets-or-it-is-not-a-mission.md` — the rule and its rationale

## Related History

The measurement behind the rule: 11 missions ever created, 9 with 3+ tickets, one with 1, one with 0. Both sub-floor cases came from seams that mint without emitting, never from a deliberate choice.

The ordering argument in question 1 is the same one that put acceptance-link stamping at the emitting seam rather than at authoring time (2026-08-03, `mission/reference/schema.md`, *The link contract*). That contract was written after 37 acceptance items across six missions were found unlinked — the failure mode of putting a check where the data does not exist yet is already recorded in this repository.

## Implementation Steps

1. Answer question 1 and write it into `mission/SKILL.md` beside the Creation Interrogation, with the "why not a write-time hook" reasoning stated (an implementer's first instinct will be `validate-mission.sh`).
2. Answer question 2 and record the one-ticket case explicitly, naming the existing archived instance so the rule is not read as a judgment on it.
3. Answer question 3, record the chosen option **and the rejected ones with their costs** — this is the decision that changes a script's responsibility, so the next session must be able to see what was traded.
4. State where the check lives (the publish seam) in one place that the next ticket implements against, rather than describing it four times.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All three questions have a written answer in `mission/SKILL.md`, each with its reasoning.
- The carry decision names the rejected options and their costs, not only the chosen one.
- The check's location (publish seam, not write-time hook) is stated once and is unambiguous enough to implement against.
- Nothing is enforced yet — this ticket changes prose only.

**Verification method** — the commands/tests/probes that prove them:

- Read-back: a reader who has not seen this ticket can answer "what happens if I run `close.sh <slug> carried --successor-title X`" from `mission/SKILL.md` alone.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `mission/SKILL.md` ships to `outputs/`, so the bundle must be rebuilt and committed.

**Gate** — what must pass before approval:

- The three answers are present, the carry trade-off is recorded, and `outputs/` is fresh.

## Considerations

- **Do not implement enforcement here.** Splitting the decision from the enforcement is deliberate: the carry answer changes what `close.sh` is responsible for, and that is worth deciding on its own before code depends on it.
- **Do not put the floor in `validate-mission.sh`.** It is a `PostToolUse` hook on a single file write and cannot see tickets that do not exist yet. This is the same shape as the already-rejected idea of validating `claim:` in a hook.
- The floor counts tickets, but the *reason* is the artifact partition. If a future case argues for an exception, check it against that reason rather than against the number.
