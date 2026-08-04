---
created_at: 2026-08-04T17:01:11+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-091426
---

# `no_tickets` cannot tell a never-planned mission from a finished one, so a drained mission stalls the loop silently

## Overview

`plan-units.sh` drops a mission from the offer with `no_tickets` when no queued ticket names it. Two opposite situations produce that reason word:

- **Never planned** — the mission has acceptance criteria but its ticket set was never emitted. The fix is a replan.
- **Finished** — every ticket the mission ever had was driven and archived. The fix is `/mission close`.

The survey reports both identically, so a mission in the second state is indistinguishable from one in the first, and `/drive` reports the same unexplained drop every tick forever.

Measured on `main` at `ee78c9dd` (2026-08-04). Four active missions, all reported `no_tickets`:

| mission | archived tickets | queued | `actual_hours` |
| --- | --- | --- | --- |
| `adopt-a-git-flow-branching-model-with-durable-ship-records` | 5 | 0 | 0.7 |
| `make-scheduled-routines-a-configurable-inspectable-part-of-a-repository` | 4 | 0 | 0.56 |
| `make-the-branch-story-concise-by-default` | 3 | 0 | 0.4 |
| `make-the-per-commit-changed-lines-ceiling-a-rule-that-holds` | 3 | 0 | 3 |

Fifteen tickets driven, 4.66 agent-hours recorded, and every one of the four read as if it had never been planned. The state persisted for four days across every hourly tick.

## Why it went unnoticed for four days

The two states were made indistinguishable a second time by an unrelated defect, and the pair compounded. Every one of those missions carried `0/N` acceptance with **zero** linked items (21 items, 0 links), so `tick-acceptance.sh` could never match a driven ticket and the boards never advanced. A reader looking at the roadmap therefore saw `0/8`, `0/3`, `0/3`, `0/7` — which reads as *no work done* — while the survey said `no_tickets` — which reads as *no plan*. Both signals agreed on a wrong story, and the true state (finished, unclosed) was visible from neither.

The acceptance-link half is already addressed: `link-acceptance.sh` and the emitting-seam requirement landed 2026-08-03 (`mission/reference/schema.md`, *The link contract*). This ticket is the survey half, which is unaddressed and is the one a runner reads.

## The distinguishing signal already exists

`queue-size.sh` answers "how many queued tickets name this mission". What it cannot answer alone is whether there were ever any. That is a one-line question against the archive: does any ticket under `.workaholic/tickets/archive/` carry this mission in its `mission:` relation? A mission with archived members and an empty queue is drained; one with neither is unplanned.

Note the relation must be read through `mission/scripts/read-relation.sh`, not re-parsed — the field is many-valued and a bare scalar is one entry.

## Policies

- `workaholic:implementation` / `policies/observability.md` — one reason word covering two opposite states is a masked failure: the run reports confidently and the operator cannot act on it. This is the policy the defect violates most directly.
- `workaholic:implementation` / `policies/objective-documentation.md` — `drive/SKILL.md` states that `no_plan` and `no_tickets` are "deliberately distinct: the first means write the acceptance criteria, the second means emit the ticket set." That sentence is false for a drained mission, and must end up matching the code.
- `workaholic:design` / `policies/history-structures.md` — the archive is the record that distinguishes the two states; the fix reads history rather than storing a new flag.

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — emits the `excluded[]` reason; the change lands here
- `plugins/workaholic/skills/mission/scripts/queue-size.sh` — the current signal, queued-only
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the single sanctioned reader of a `mission:` relation
- `plugins/workaholic/skills/drive/SKILL.md` — §1 documents the reason vocabulary and the `no_plan`/`no_tickets` distinction
- `CLAUDE.md` — the `/drive` row and the claim-protocol section name the same vocabulary
- `scripts/test-workflow-scripts.mjs` — no case covers a mission whose queue drained

## Related History

The reason vocabulary was last amended by decision K1 (2026-07-31), which retired `not_approved` when `status: draft`/`approved` folded into `active`. That change made the *area* the authority for claimability and left `no_plan`/`no_tickets` as the two remaining "not ready" reasons — neither of which anticipated "was ready, is now done".

`plan-units.sh` deliberately does not repair what it observes (it is called inside claim worktrees and must stay side-effect-free). This ticket does not change that: it adds a distinction to what is *reported*, and the close remains a human act.

## Implementation Steps

1. Add a distinct `excluded[]` reason — `queue_drained` — emitted when a mission has **no queued ticket and at least one archived ticket naming it**. Keep `no_tickets` for the genuinely unplanned case. Read the relation through `read-relation.sh`.
2. Decide where the archive lookup lives. Prefer extending `queue-size.sh` to report both counts (`queued`, `archived`) over adding a second script — one reader of "how many tickets name this mission" is easier to keep honest than two. Record the choice and the rejected option.
3. **Do not make `queue_drained` claimable.** A drained mission has nothing to drive; offering it would hand a runner an empty unit. It stays excluded — the change is to the reason word only, so the operator can act.
4. Surface it where a human actually looks: the bare `/mission` roadmap view (`list.sh`) should mark a drained active mission, since "this one is waiting on a close decision" is exactly the developer-facing fact the view exists to carry.
5. Update `drive/SKILL.md` §1's reason list and the sentence claiming the two reasons are exhaustively "not ready", plus `CLAUDE.md`'s matching prose, in the same change.
6. Add a hermetic test: a mission with one archived ticket and an empty queue reports `queue_drained`; one with neither reports `no_tickets`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission whose tickets are all archived is excluded as `queue_drained`, not `no_tickets`.
- A mission that never had a ticket is still excluded as `no_tickets`.
- Neither is offered as claimable.
- `drive/SKILL.md` and `CLAUDE.md` describe the reason vocabulary as implemented.
- The bare `/mission` view distinguishes a drained active mission from an unplanned one.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with the two new hermetic cases above.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the drive and mission skills ship to `outputs/`, so the bundle must be regenerated and committed.
- A live `plan-units.sh` run against a repo with a drained mission reports the new reason.

**Gate** — what must pass before approval:

- Suite green, `outputs/` rebuilt with no diff, and the two prose locations agree with the code.

## Considerations

- **Do not add a stored flag to `mission.md`.** Drained-ness is derivable from the archive on every read, and a stored copy is a second source of truth that goes stale exactly when a ticket is archived on a branch that has not merged.
- **The reason word is not the whole fix, but it is the part a runner reads.** A drained mission still needs a human to judge whether it is `achieved`, `carried`, or `abandoned`, and that judgment is not automatable — the four closed on 2026-08-04 needed all 21 acceptance criteria checked against `main` by hand, and one of them turned out **not** to be achieved (`make-the-branch-story-concise-by-default`, whose stories measurably got longer). Automating the close would have recorded that one as done.
- **Watch the interaction with the acceptance-link contract.** A mission can be drained *and* have unlinked acceptance items, which is exactly the state the four were in. `progress.sh` already reports `unlinked` — consider surfacing it alongside the new reason so the operator sees both halves at once rather than discovering the second after acting on the first.
- Scope note: `no_plan` is untouched. A mission with no acceptance criteria is genuinely not ready regardless of its queue.
