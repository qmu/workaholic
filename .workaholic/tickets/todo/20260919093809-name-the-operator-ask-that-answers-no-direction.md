---
created_at: 2026-09-19T09:38:09+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: never-let-the-routine-that-originates-work-converge-on-silence
merge_policy:
verification_handoff:
---

# Name the operator ask that answers no direction

## Overview

Operator's ask: **issue #907**, item 3 — *a move is declared against a strategy, so an ask with no
direction can never be originated. `unattributed` exists on the inbound path and has no
counterpart here.* Measured: the operator's own stated immediate priority belonged to no active
strategy, so `/propose` was structurally incapable of proposing it and spent two days proposing
against the directions that did exist.

**What this repository already has, established before the ticket was written.**
`strategy/scripts/unattributed-work.sh` names what no direction claims — active missions by slug
with their queued-ticket counts, and loose queued tickets. `survey-strategies.sh` carries it per
row as `residue`. Both readings are about **work already emitted**. Nothing reads the other side:
an **operator ask** sitting in the inbox that no active direction covers is visible to nobody —
`/propose` surveys strategies and never reads the inbox, and the inbox reader
(`list-inbound-issues.sh`) knows nothing about directions.

**The boundary, stated first because it shapes the whole ticket.** `/propose` does **not** gain an
origination path that bypasses a strategy. `rules/workaholic.md`, *What May Originate a Mission*,
permits a human's ask or a human-authored strategy and nothing else — and an inbound operator ask
is already originable, by `/specificate`, through the path built for it. So the missing piece is
not a new origination route; it is that the ask is **unreachable in the report and unnamed to a
person**, which is why an operator priority can be captured and still never be worked on. This
ticket makes it named.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — the governing policy: a captured ask
  nobody is working on must be answerable from the outside without anyone reading a run report
- `workaholic:implementation` / `policies/test.md` — the reading and its degradation are pinned
  hermetically and offline

## Key Files

- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — the existing half: work no
  direction claims. The new reading is its mirror on the **ask** side and must compose it rather
  than re-walking the tree.
- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` — the inbox reader. It
  already classifies every row (`already_planned`, `captured_on_branch`, `self_originated`,
  `recorded_unplanned`, `uncaptured`); the direction question is a new axis over rows it already
  returns, not a second listing.
- `plugins/workaholic/skills/strategy/scripts/list.sh` and `read.sh` — the active directions and
  their `feedback:` refs; `read.sh` resolves the absent-stage default, and nothing may re-derive it.
- `plugins/workaholic/skills/propose/reference/loop.md` (step 5) — where the run report names its
  evidence, in the same voice `pace`, `arrived` and `expiring` are named in.
- `plugins/workaholic/skills/moderate/scripts/steps.json` and `step-direction-health.sh` — the seam
  that reaches a person, and the model for a step that asks the assignee once and writes nothing.
- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — how long the ask has been
  standing, for the question body.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Reproduce the gap.** In this checkout, run `list-inbound-issues.sh` and `strategy/scripts/
   list.sh`, and record which open assigned asks fall under no active Aim. That set is the
   subject; capture it as the before-state.
2. **Write the reading, and put it where the existing one lives.** Add
   `strategy/scripts/unattributed-asks.sh` beside `unattributed-work.sh`: the open inbound asks
   this identity holds that no active direction covers, each with its number, title, age and the
   reason it is uncovered. It **composes** `list-inbound-issues.sh` and `strategy/scripts/list.sh`;
   it adds no relation, no field on any artifact and no second walker.
3. **Attribution here is a judgement and must be reported as one.** An ask's direction is decided
   by an explicit `feedback:` line, else an explicit slug, else a judgement against the active Aims
   — the same ladder `/specificate` step 7 already uses, and a script cannot perform the third
   rung. So the script answers only the two mechanical rungs and reports the rest as
   **`undecidable_here`**, which the consumer names as *no line and no slug* rather than as *no
   direction*. Do not let a script assert an Aim judgement.
4. **A degraded read is named, never rendered as an empty set.** An unreadable inbox, an
   unreadable strategy set, or a failed walk answers `readable: false` with its reason and **null**
   counts — never `no_unattributed_asks`, which means the opposite.
5. **Name it in `/propose`'s run report** (loop.md step 5), in the same voice as `pace` and
   `arrived`: evidence, never a verdict, and it gates nothing. No `refusal`, no sort, no `selected`
   and no token reads it, and `survey-strategies.sh` is untouched.
6. **Reach the person through `/moderate`.** Add the reading to the step that already asks a
   direction's assignee — or a sibling step if that one's subject cannot honestly hold it — asking
   once whether the named ask wants a direction, using the existing ask seam, the existing
   asked-once gate and `condition-age.sh` for its age. The loop creates no strategy and amends
   none: `create.sh` and `amend.sh` keep their three writers.
7. **State the boundary in the skill prose.** `workaholic:propose` gains one short paragraph: an
   ask that answers no direction is **named**, not originated, and why — citing
   `rules/workaholic.md`, *What May Originate a Mission*, rather than restating it.
8. **Hermetic rows** over a fabricated tree and a stubbed inbox: an ask whose `feedback:` line
   names an active direction is not listed; an ask naming none is listed with
   `undecidable_here`; an unreadable inbox answers `readable: false` with null counts; the
   `/propose` survey is byte-identical across the change; and two runs over an unchanged tree
   produce identical output.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `unattributed-asks.sh` exists beside `unattributed-work.sh`, composes the existing readers, and
  adds no relation and no field to any artifact.
- An ask carrying a `feedback:` line that resolves to an active direction is **not** reported;
  one carrying no line and no slug **is**, marked `undecidable_here`.
- A degraded inbox or strategy read answers `readable: false` with its reason and **null** counts.
- `survey-strategies.sh` is **byte-identical to `origin/main`** — the reading gates nothing.
- `strategy/scripts/create.sh` and `amend.sh` are **byte-identical to `origin/main`** — the loop
  creates and amends no direction on this reading.
- The `/moderate` question is asked at most once per subject and writes nothing into the tree
  beyond the tick log line.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and the new rows fail when reverted.
- `git diff origin/main -- plugins/workaholic/skills/propose/scripts/survey-strategies.sh plugins/workaholic/skills/strategy/scripts/create.sh plugins/workaholic/skills/strategy/scripts/amend.sh` is empty.
- `sh plugins/workaholic/skills/strategy/scripts/unattributed-asks.sh` run twice in this checkout
  emits identical output and exits 0 both times.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- No path in the change lets `/propose` open a proposal not chosen against a named strategy.
- The suite is green, the bundle rebuild is diff-clean, `layout-doctor.sh` reports
  `conforming: true`.
- POSIX `sh` throughout.

## Considerations

- **The ask says "give origination a path"; this ticket gives it visibility and says so.** The
  difference is deliberate and is stated in the Overview: an origination path that bypasses the
  strategy would breach the repository's own origination rule, which exists because of a measured
  day of waste. If the operator wants the stronger reading, the artifact they would add is a
  **direction** for that priority — which is exactly what the question in step 6 asks for.
- **This must not become an hourly status line.** Keep clock-derived values out of the summary so
  an unchanged set renders no new root line; two keyed roots have already been retired here for it.
- **The third attribution rung is deliberately not automated.** A script that judged an ask against
  an Aim would be asserting a reading the repository keeps as a judgement in exactly one place
  (`/specificate` step 7), and two judges of one question drift.
