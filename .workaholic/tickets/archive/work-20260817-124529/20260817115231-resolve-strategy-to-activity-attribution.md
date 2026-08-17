---
created_at: 2026-08-17T11:52:31+00:00
status: done
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

## Final Report

Development completed as planned.

**The Open Decision is resolved: (b), attribution through the feedback stream.** Work reaches a
strategy along the citation that already exists, and **no field is added anywhere**:

| Hop | Rule | `attribution` |
| --- | ---- | ------------- |
| 1 | the artifact's `feedback:` refs intersect the strategy's | `direct` |
| 2 | a **mission** attributed by hop 1 is named by the artifact's `mission:` relation | `via_mission:<slug>` |

Hop 2 is load-bearing rather than a convenience: `/propose` puts the `feedback:` refs on the
mission and its ticket set carries `mission:` instead, so a one-hop reader would have seen
almost nothing on the corpus this repository actually has.

**The 2026-08-13 removal's reasoning, answered rather than ignored** (the ticket's Gate). That
decision declined to revive `strategy:` on a mission because the relation gave ownership a
*second resolution path* — the "ownership hop" `mission-owners.sh` used to make — and because a
mission's owner belongs on the mission. (b) does not answer that objection by out-arguing it; it
answers it by **never creating the relation**. There is no new field, so there is no second
resolution path to rebuild, nothing for `owners.sh` to hop through, and no write floor, hook or
migration to ship — which is also why step 3 of the Implementation Steps and the "any new field
carries a registered migration" acceptance criterion are satisfied vacuously rather than skipped.
The retired relation stays retired and the citation stays one-way.

The other three candidates and why each lost are recorded in the reader's own header, beside the
rule that won: (a) would have to re-answer the removal and reopen the ownership model for a
read-only digest; (c) needs a **third writer** of a live strategy, which the two-writer design
refuses; (d) ships without a ruling and is not what was asked for.

**One reader, and the lossiness is reported rather than hidden.**
`skills/strategy/scripts/attributed-work.sh` is the only answer to "which work belongs to
strategy X in window W", and it parses neither relation itself — each hop goes through that
relation's existing single reader (`propose/scripts/read-feedback-relation.sh`,
`mission/scripts/read-relation.sh`), so a second parser cannot disagree with the first. Work that
answers a strategy without citing the same record is invisible to both hops; every artifact
therefore carries the hop that caught it, and every consumer is required to state what it could
not attribute instead of implying the answer is exhaustive.

**A quiet strategy is an answer, never an error**: `empty_reason` is `no_feedback_refs`,
`no_citing_artifacts` or `no_activity_in_window`, and every degradation — including an unknown
slug and a missing argument — exits 0 so a digest can call the reader unguarded.

### Discovered Insights

- **Insight**: the artifact→feedback relation already had a single reader, and it was in the
  `propose` skill (`read-feedback-relation.sh`), not the `feedback` skill.
  **Context**: the obvious move when adding a consumer is to write "the feedback relation
  reader" in the skill that owns the artifact; doing that would have created the second parser
  this repository's one-reader rule exists to prevent. The rule is about the *relation*, and its
  reader lives wherever it was first needed — check for one before adding one.

- **Insight**: attribution had to be transitive to see anything at all, because of where
  `/propose` puts the refs.
  **Context**: a mission carries `feedback:`; the tickets it emits carry `mission:` and usually
  no `feedback:` of their own. Any future reader that walks refs one hop from an artifact will
  measure near-zero on this corpus and look correct while doing it — the emptiness is a property
  of the emitter, not of the tree.

- **Insight**: a large-corpus reader can keep the one-reader rule *and* stay cheap by
  prefiltering with grep and confirming with the reader.
  **Context**: 800+ tickets means a per-file call to a relation reader is 800 process spawns
  (`catch/scripts/scan-window.sh` pays exactly that). Grepping the corpus for the literal stems
  first and calling the reader only on the hits keeps the authoritative parse in one place while
  reading a handful of files — the grep decides "worth reading", never attribution.

- **Insight**: `jq` filters carrying literal `0x1e`/`0x1f` separators are fragile in a way that
  fails loudly but confusingly — the split silently degrades to per-character.
  **Context**: the separators survive in the file but are invisible in a diff and can be dropped
  by any tool that touches the line, and the failure mode (441 one-character "records" out of a
  five-artifact fixture) reads like a parsing bug rather than a lost byte. `scan-window.sh` has
  the same shape; a fixture assertion on the record count is what catches it.
