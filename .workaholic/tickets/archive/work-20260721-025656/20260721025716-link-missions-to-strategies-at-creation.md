---
created_at: 2026-07-21T02:57:16+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort: 2h
commit_hash:
category: Changed
depends_on: [20260721025715-add-strategy-artifact-and-skill.md]
mission: reorganize-missions-under-strategies
---

# Link missions to strategies at creation

## Overview

Every mission is an **execution plan of a strategy**, so mission creation (and replan, for legacy/thin missions) must resolve the link. The resolution follows the decide-and-record doctrine (ticket `20260721025722`): the agent **infers the strategy from context** — the request, existing strategies via `strategy/scripts/list.sh`, the repo — and (a) links silently when exactly one active strategy plausibly covers the mission, recording the inference in the mission changelog; (b) creates the strategy on the spot when none fits (deriving its `## Direction` from the mission's own Goal, one level more general and end-condition-free), records that too; and (c) asks the developer **only** when several active strategies genuinely compete and no recommendation is honest — the sole unrecommendable case.

The link is `strategy: <slug>` in `mission.md` frontmatter — single-valued by convention (one plan, one strategy), read only through `strategy/scripts/read-strategy-relation.sh`.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX scripts, style (applies to all code work)
- `workaholic:planning` / `policies/modeling-centric-design.md` — the linkage encodes the strategy→mission relation of the model; keep it a frontmatter relation + single reader, not scattered parsing
- `workaholic:development` / `policies/overnight-ai.md` — the linkage step must not add questions to the front-loaded flow beyond the genuinely unrecommendable case
- `workaholic:implementation` / `policies/objective-documentation.md` — record the inferred-vs-asked-vs-created outcome as a changelog line, verifiable after the fact

## Key Files

- `plugins/workaholic/skills/mission/scripts/create.sh` — add `strategy:` to the scaffold frontmatter (empty at scaffold; stamped by the command during interrogation, like `drive_authorized`).
- `plugins/workaholic/skills/mission/SKILL.md` — Schema section gains `strategy:`; Creation Interrogation gains a **Strategy resolution** step (before Direction round 1 output is written): the infer/create/ask tri-state above, each outcome recorded via `append-changelog.sh` (`strategy linked — <slug>` / `strategy created — <slug>`; add both to the standard-events list). Replan section: an active mission with an empty `strategy:` gets the same resolution on its next replan.
- `plugins/workaholic/commands/mission.md` — create flow step 3b and replan step 3 reference the resolution step; the ask branch uses `AskUserQuestion` with the `[<project label>]` prefix and one option per candidate strategy plus "create new".
- `plugins/workaholic/hooks/validate-mission.sh` — extend the `drive_authorized: true` floor: a non-empty `strategy:` key joins owner/Experience/Acceptance. Archive missions stay never-retro-blocked; missions not yet authorized may have it empty (scaffold passes).
- `plugins/workaholic/skills/monitor/scripts/preflight.sh` — surface each mission's `strategy` slug in the pre-flight facts (read via the reader) so the roadmap headline can group by strategy later; an empty one on an authorized legacy mission is reported as a replan item, not a blocker.
- `scripts/test-workflow-scripts.mjs` — cases: scaffold contains the key; validate-mission rejects `drive_authorized: true` + empty `strategy:` on an active mission and passes archive/unauthorized ones; changelog events append idempotently.
- `outputs/workflows` — mission skill is built: run the argument-less `node scripts/build-plugins/build.mjs`.
- `CLAUDE.md` (`/mission` row, mission-validation hook description), `README.md`, `.workaholic/README.md` — same change.

## Implementation Steps

1. Add `strategy:` to `create.sh`'s scaffold heredoc and the SKILL.md schema block.
2. Write the **Strategy resolution** step into the mission SKILL's Creation Interrogation (tri-state, decide-and-record, changelog events) and mirror it in the Replan section for unlinked actives.
3. Update `commands/mission.md` create/replan flows to run the step and record outcomes.
4. Extend `validate-mission.sh`'s authorized-floor check with the `strategy:` key; keep the scaffold-pass and archive exemptions intact.
5. Extend `preflight.sh` to report `strategy` per mission.
6. Add the hermetic tests; run the full build; update docs.
7. **Live demo (also the mission's own backfill):** create the bootstrap strategy for this repository — title on the lines of "Agent-orchestrated development" whose `## Direction` states the daytime-planning / after-hours-execution / throughput-measured model from this mission's Goal — via `strategy/scripts/create.sh`, then stamp `strategy: <its-slug>` into **this** mission's `mission.md` with the `strategy linked` changelog line.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo.

**Acceptance criteria**

- A freshly scaffolded mission carries an empty `strategy:` key; an authorized mission without one is rejected at write time; archived missions are never retro-blocked.
- The interrogation resolves the link by infer/create/ask with ask **only** on genuine multi-candidate ambiguity, and every outcome lands as an idempotent changelog line.
- This mission (`reorganize-missions-under-strategies`) ends the ticket linked to a real strategy created through the new flow.
- Built `outputs/workflows` mission skill carries the changes; docs updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the new validate-mission/scaffold/changelog cases.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green.
- POSIX lint for touched scripts.

**Gate**

- Suite green, build/verify green, and the in-session demo performed: bootstrap strategy exists, this mission's `strategy:` stamped, `strategy/scripts/list.sh` shows the rollup containing this mission's slug.

## Considerations

- The floor is at `drive_authorized` stamping, not scaffold time, so `create.sh` (which cannot interrogate) keeps passing and hand-authored thin missions surface the gap at replan instead of breaking (`plugins/workaholic/hooks/validate-mission.sh`).
- `/monitor`'s unattended runs never create or link strategies — an unlinked authorized legacy mission is a pre-flight replan item resolved in the up-front batch (`plugins/workaholic/skills/monitor/scripts/preflight.sh`).
- Keep the relation single-valued in prose but parse-tolerant of list form via the reader, so a future many-valued turn needs no migration (`plugins/workaholic/skills/strategy/scripts/read-strategy-relation.sh`).
- Do not add a strategy-side mission list — rollups stay computed (`strategy/scripts/list.sh`), or archives dangle.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The strategy skill enters the cross-agent `outputs/workflows` bundle automatically the moment the mission SKILL.md references `strategy/scripts/...` — the build reports `built mission: closure=[gather, mission, okf, strategy]`. No build.mjs edit was needed; the reference in the Strategy resolution prose is what pulls it in.
  **Context**: `scripts/build-plugins/build.mjs` `computeClosure` follows SKILL_REF patterns in SKILL.md, so documenting the resolution step with real script paths is also what makes the scripts ship.
- **Insight**: `validate-mission.sh` reads `strategy:` tolerantly of the inline-list form (`strategy: []` is treated as empty and rejected on an authorized mission), matching the reader's contract, so a malformed empty-list value cannot slip past the floor.
  **Context**: `plugins/workaholic/hooks/validate-mission.sh` — the sed strips `[ ]` before the emptiness test.
- **Insight**: This mission is now the live demo: `strategy: agent-orchestrated-development` is stamped on its own mission.md and `strategy/scripts/list.sh` shows the rollup containing `reorganize-missions-under-strategies`.
  **Context**: `.workaholic/missions/active/reorganize-missions-under-strategies/mission.md`.
