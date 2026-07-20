---
created_at: 2026-07-21T02:57:21+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260721025715-add-strategy-artifact-and-skill.md, 20260721025716-link-missions-to-strategies-at-creation.md]
mission: reorganize-missions-under-strategies
---

# Document granularity discipline across artifacts

## Overview

Land the **redefinition and the granularity discipline** as documentation, in one coherent pass, once the strategy machinery (deps) exists. The four description layers — **commit message** (one normalized change, ~a few hundred lines), **ticket** (one drive-able change with its own quality gate), **mission** (an overnight-executable execution plan bundling tickets: hours of agent time, a fairly immediate developer request interrogated to question-free readiness), **strategy** (long-lived direction, no completion conditions) — each describe code change and its planning at *their own* granularity, and **no artifact restates a lower level's detail**. The balance test cuts both ways: a mission re-narrating its tickets' specifics is over-written; a ticket that says essentially what its mission says means the mission is under-sized (a mission must be bigger than any one ticket).

This also retires the old framing where the *mission* was the long-lived container: longevity moves up to strategy; the mission's "durable goal spanning many tickets over a long horizon" language across the docs is rewritten to the execution-plan definition.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — docs land in their conventional homes (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conformance in touched files (applies to all code work)
- `workaholic:planning` / `policies/terminology.md` — the four terms used identically everywhere; the redefinition recorded with reasons; no leftover "epic/milestone/long-lived mission" phrasing
- `workaholic:planning` / `policies/modeling-centric-design.md` — the hierarchy documented as a model (elements + relations + granularity rule), which the per-skill prose then instantiates
- `workaholic:implementation` / `policies/objective-documentation.md` — the discipline stated as checkable rules (the both-ways balance test), not vibes

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md` — opening definition rewritten (execution plan of a strategy; overnight-executable; the mission-vs-trip-vs-epic block gains strategy); a **Granularity** section carrying the four-layer table and the both-ways balance test (the single home of the rule — others link here).
- `plugins/workaholic/skills/strategy/SKILL.md` — links to the granularity section; states the strategy side (direction, no completion conditions, missions as its execution plans).
- `plugins/workaholic/skills/create-ticket/SKILL.md` — a short granularity note in the writing guidelines: a ticket duplicating its mission's statement signals an under-sized mission — surface that at creation instead of writing the duplicate.
- `plugins/workaholic/skills/commit/SKILL.md` — one line tying the commit unit to the normalized size (reference the release-scan gate ticket, no thresholds restated).
- `CLAUDE.md` — `/mission` row and the architecture prose ("durable, information-rich goal" phrasing), plus the sources×executors paragraph where missions are described; add strategy to the `.workaholic/` OKF type list if ticket `20260721025715` has not already.
- `README.md`, `.workaholic/README.md` — user-facing description of the hierarchy and the daytime-planning/after-hours-execution workflow.
- `plugins/workaholic/hooks/mission-lens.sh` docs paragraph in CLAUDE.md — verify wording still true after redefinition (behavior unchanged).
- `outputs/workflows` — mission/create-ticket/commit skills are built targets: run the argument-less build after edits.

## Implementation Steps

1. Write the Granularity section in the mission SKILL (four-layer table, both-ways test, the redefinition record: what "mission" used to mean here, why longevity moved to strategy — dated, with the mission slug of this reorganization as provenance).
2. Sweep every doc naming missions ("long-lived", "durable", "epic") — `grep -ri` across `plugins/`, `CLAUDE.md`, `README.md`, `.workaholic/README.md` — and align each to the new definitions; keep diffs surgical (this checkout predates the `work-20260719-075112` doc changes: where a file conflicts with that branch, prefer minimal edits localized to the definition sentences so the later merge reconciles cleanly).
3. Add the linked notes in strategy/create-ticket/commit SKILLs.
4. Full build; verify freshness.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo (doc ticket: the demo is the sweep evidence).

**Acceptance criteria**

- One home for the granularity rule (mission SKILL); every other mention links rather than restates.
- `grep -ri 'long-lived' plugins/workaholic/skills/mission plugins/workaholic/commands/mission.md` (and the epic/durable variants) returns only the redefinition-record context, no live definitional uses; strategy carries the longevity language instead.
- The redefinition record names the old meaning, the new one, the reason, and the date.
- All touched built skills rebuilt; docs consistent in the same change.

**Verification method**

- The grep sweep results captured in the drive log as evidence.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; `node scripts/test-workflow-scripts.mjs` still green (no behavior change intended).

**Gate**

- Sweep clean, build/verify green, suite green, and a read-through confirming the four-layer table matches what the sibling tickets actually implemented.

## Considerations

- This is the last ticket in dependency order on purpose: it documents what the others built; writing it first would document intentions (`depends_on`).
- Do not edit the qmu.co.jp policy hard copies under `skills/<pillar>/policies/` — the granularity rule is repo doctrine, not a corporate policy rewrite (mission Scope).
- The `work-20260719-075112` merge will touch overlapping prose (monitor/mission rows); surgical, definition-scoped edits minimize the conflict surface (Implementation Step 2).
