---
created_at: 2026-08-17T11:52:31+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: add-the-standup-daily-per-strategy-summary
merge_policy:
verification_handoff: 
---

# Resolve strategy to activity attribution

## Overview

The mission's precondition. `/standup` summarises recent development activity **per
strategy**, and today nothing in the repository says which work belongs to which strategy.
That is not an oversight to patch — it is a decision that was made on purpose and has to be
revisited deliberately.

When the strategy artifact was revived on 2026-08-13 (issue #436), `workaholic:mission`
recorded what did **not** come back with it: "the `strategy:` relation on a mission, and the
ownership hop it fed. A mission's owner is on the mission; a strategy's owner is on the
strategy. A legacy `strategy:` key in an old mission stays tolerated history and is still
read by nothing." `/drive` never surveys strategies, and the artifact's only citation runs
**strategy → feedback**, one way. So the summary's input does not exist, and this ticket
decides how it comes to exist — or that it does not, and the digest is scoped differently.

## Policies

- `workaholic:planning` / `policies/scoping.md` — how direction connects to executable work
- `workaholic:implementation` / `policies/data-modeling.md` — a relation is added once, in one direction, with one reader
- `workaholic:development` / `policies/change-history.md` — reviving a removed relation needs the removal's reasoning answered

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md`, *The strategy layer: retired, then
  redefined* and *What did not return* — the decision this ticket reopens, and the reasoning
  any revival must answer.
- `plugins/workaholic/skills/strategy/scripts/list.sh`, `read.sh`, `create.sh`, `close.sh` —
  the artifact's four scripts and its **exactly two writers**. Nothing edits a live
  strategy's fields, which constrains any design that would store the link on the strategy.
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the many-valued `mission:`
  relation and the single-reader pattern any new relation should copy.
- `plugins/workaholic/skills/gather/scripts/owners.sh` — the ownership oracle whose
  "ownership hop" the retired relation fed; the reason the relation was costly.
- `plugins/workaholic/hooks/validate-strategy.sh` — the write floor: `target_date`,
  non-empty `assignees`, non-empty `## Aim` / `## Schedule`.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — the existing "recent activity in
  a window" reader, and the natural input once attribution exists.

## Implementation Steps

1. Settle the Open Decision. Everything else in this ticket follows from it.
2. Implement the chosen attribution as a **single reader** — one script that answers "which
   artifacts belong to strategy X in window W" — so a second parser can never disagree with
   the first, the rule `read-relation.sh` already embodies.
3. If the answer adds a field to an artifact, add it to that artifact's write floor and its
   validation hook in the same change, and ship the living migration plus its registration
   in `converge-layout.sh` — the registry is checked mechanically by
   `test-workflow-scripts.mjs`.
4. Make the reader degrade honestly: a strategy with no attributable work returns an empty
   set with a reason, never an error and never a guess.
5. Document the relation's direction and its single reader in the strategy skill.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Exactly one reader answers the attribution question, and every consumer goes through it.
- A strategy with no attributable activity returns an explicit empty result.
- Any new field is enforced at its write floor and carries a registered migration.
- Nothing writes to a live strategy's Aim, Schedule or Assignee.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the migration-registry check.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- The reader run against a fixture with two strategies and overlapping work.

**Gate** — what must pass before approval:

- The Open Decision resolved and recorded in the Final Report, with the 2026-08-13 removal's
  reasoning explicitly answered rather than ignored.

## Open Decisions

1. **How is work attributed to a strategy?** Four candidates, none recommendable outright:
   (a) **Revive `strategy:` on a mission** — the most direct and the one that was removed on
   purpose; reviving it means answering why the ownership hop it fed will not come back with
   it. (b) **Attribute through the feedback stream** — a strategy already cites the records
   it grew from, and missions and tickets carry `feedback:` refs, so strategy → feedback →
   artifact is a path that needs **no new field at all**; its weakness is that it is
   transitive and lossy (work that answers a strategy without citing the same record is
   invisible). (c) **A strategy-side list of slugs** — simple to read, but the artifact has
   exactly two writers and neither edits a live strategy, so keeping it current would need a
   third writer, which the design refuses. (d) **No attribution; scope the digest to the
   repository** — the digest becomes "yesterday in this repository, with the strategy set
   listed alongside", which is buildable today and is **not** what the ask asked for. Note
   that (b) is the only one that adds nothing, and (d) is the only one that ships without a
   ruling.

## Considerations

- The repository holds **zero** strategies today, so every option is testable only against a
  fixture. Build the fixture first; a design validated against an empty set is not
  validated.
- Whatever is chosen, the citation direction should stay one-way. The strategy → feedback
  link is one-way by explicit design, and a bidirectional attribution would reintroduce the
  bookkeeping that made the old relation expensive.
