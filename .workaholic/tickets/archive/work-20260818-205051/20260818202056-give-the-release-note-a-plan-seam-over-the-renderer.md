---
created_at: 2026-08-18T20:20:56+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-draft-release-note-an-agent-s-release-plan
merge_policy:
verification_handoff: 
---

# Give the release note a plan seam over the renderer

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`draft-release-note.sh` is a pure renderer whose header states the property the
whole cadence rests on: *the same base state renders byte-identical output*. That
property is not a defect to remove — it is what makes the daily cadence idempotent
and a re-render diff-free. But it also structurally forecloses the agent judgment
issue #512 asks for, because a judgment is not a function of the base state alone.

This ticket separates the two so neither has to lose: the renderer keeps deriving
the **facts** (the boundary, the unreleased set, per-merge detail), and gains a
seam that renders an **agent-authored plan** over those facts when one exists,
falling back to today's list when none does. It writes no plan and runs no agent —
that is the next ticket. What it delivers is the artifact's shape and the contract
the writer and the planner both read.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/delivery.md` — the release path this note describes

## Key Files

- `plugins/workaholic/skills/ship/scripts/draft-release-note.sh` — the pure
  renderer; its header carries the idempotency contract this ticket must restate
  rather than silently break.
- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — owns the
  boundary and attribution; the facts half is already here and is not re-derived.
- `plugins/workaholic/skills/ship/scripts/run-note-cadence.sh` — the caller whose
  `changed` / idempotency reporting must stay meaningful across the seam.
- `plugins/workaholic/skills/ship/scripts/sync-release-note.sh` — writes the
  non-authoritative copy as a projection; both copies must stay identical by
  construction once a plan is in play.
- `plugins/workaholic/skills/ship/SKILL.md` §7 — the written record of which
  writer designs were refused and why; the seam must be stated there.

## Implementation Steps

1. Read `draft-release-note.sh`'s header and `ship/SKILL.md` §7 end to end before
   changing anything: both carry decisions (idempotency, the three refused writer
   designs, story-preferred-over-commit-list) that this seam must answer, not
   overwrite.
2. Define what an arranged release plan *is*, in writing, before any code: the
   fields a planner must produce — grouping (what ships together), ordering, risk
   or coupling notes, and what is deliberately held back — and the fields it may
   not invent. Record it in `ship/reference/`.
3. Choose and document the plan's storage so it is addressable by both the writer
   and the planner, and so a plan can be recognised as **stale** against the base
   state it was written for (a plan authored two merges ago must not silently
   present itself as current).
4. Give `draft-release-note.sh` a `--plan <path-or-stdin>` style seam: with a
   plan, render the plan's arrangement over the derived facts; without one, render
   exactly today's output, byte-for-byte. Prove the no-plan path is unchanged.
5. Restate the idempotency contract honestly in the header: *the same base state
   plus the same plan renders byte-identical output*. Do not delete the original
   sentence — supersede it in place, naming what changed and why.
6. Make a stale plan visible rather than authoritative: the render says which base
   state the plan was written for when that is not the current one.
7. Update `CLAUDE.md`, `ship/SKILL.md` §7 and `.workaholic/README.md` in the same
   change — a behaviour change with stale docs is a defect by this repo's own rule.

## Quality Gate

<!-- Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- With no plan supplied, `draft-release-note.sh` output is byte-identical to the
  pre-change output for the same base state.
- With a plan supplied, the rendered note reflects the plan's grouping and order.
- A plan written for a different base state is rendered as stale, not as current.
- The plan's schema is written down where a later reader finds it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Render before/after on the same base and `diff` the no-plan output.
- Render with a hand-written plan fixture and with a deliberately stale one.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The no-plan diff is empty, the smoke tests pass, and the superseded idempotency
  sentence is present in the header with its reason.

## Considerations

- The temptation is to delete the determinism contract because #512 calls it the
  problem. It is not the problem — the *absence of judgment* is. Determinism over
  (base state + plan) keeps the cadence idempotent and keeps re-renders diff-free
  for a human reader, which is a property the ask never asked to lose.
- Where the plan is stored is deliberately left to this ticket rather than assumed:
  the next ticket's Open Decision (where the agent runs) constrains it, so pick a
  storage that does not pre-commit that fork if you can.

## Final Report

Development completed as planned.

**The seam.** `draft-release-note.sh --plan <path|->` renders an agent-authored
arrangement over the facts the script already derives; `render-release-plan.sh` is the
arranging half, split out so the renderer keeps its line-at-a-time shell shape and the
plan gets a real parser. The line a merge renders as is composed **once** and appended
both to the derived list and to the facts a plan arranges, so a planned note and a
planless one can never disagree about what a merge says.

**Storage was chosen by not choosing a path.** The plan is whatever file the caller
hands over; the renderer looks in no well-known location, exactly as `--out` already
behaves. What *is* fixed is what any home must respect: never inside git (§7's measured
self-counting refusal applies unchanged — for a target declaring no `paths:`, the commit
storing the plan increments the count the plan is about), addressable by both sides, and
never trusted for freshness, which is why the document carries its own `base_sha`. That
leaves the next ticket's Open Decision — where the planner runs — untouched, which the
Considerations asked for.

**Staleness** is a rendering state, not an error: a plan whose `base_sha` is not the
rendered base is rendered *and* said to be stale, in the note (a line naming both shas)
and in the JSON (`plan.stale`). Everything that landed after the plan's base falls into
*Not arranged by the plan*, so the reader sees what the plan did not know about without
comparing shas. A stale plan is never silently refreshed — that would mean authoring the
judgment the plan exists to carry.

Verification: the whole hermetic suite passes at **3120 assertions**, of which 25 are the
new `release note: the plan seam over the renderer` fixture — arrangement, order, the
derived line with the plan's note appended, held-back, unarranged, an out-of-range
reference, staleness, three refusals, and the restated idempotency contract. The
byte-identity of the no-plan path was proved against the **pre-change script itself**:
`git show HEAD:…/draft-release-note.sh` and the new one rendered this repository's
`marketplace` target into two directories and `diff -r` reported them identical, with the
same `body_sha`. `posix-lint.sh` is clean, and `build.mjs` / `verify.mjs` /
`validate-metadata.mjs` / `layout-doctor.sh` all pass.

### Discovered Insights

- **Insight**: the two sides of the staleness comparison legitimately carry different sha
  widths — the renderer holds whatever `read-deploy-state.sh --base-rev` abbreviated it
  to, while a planner running `git rev-parse` writes all forty.
  **Context**: an equality test marked every current plan stale (caught by the fixture on
  its first run). The comparison is by common prefix, which is also why the reference
  document states the field is compared that way rather than leaving it to be discovered.
- **Insight**: a plan can only address a merge that carries a pull request number, and the
  renderer's own facts include merges that carry none.
  **Context**: those merges are unaddressable by construction, so they land unarranged
  rather than being dropped — the same no-selection doctrine that keeps the section
  uncapped. A planner cannot make them disappear even by trying.
- **Insight**: `--plan -` had to be slurped once at startup rather than per target.
  **Context**: the render loop runs per target, so a stdin plan consumed by the first
  target would leave every later one planless for a reason nothing would have reported.
