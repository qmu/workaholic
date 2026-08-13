---
created_at: 2026-08-13T11:26:14+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Revive the Strategy artifact with aim schedule and assignee

## Overview

PROPOSED. Issue #436 asks for the deprecated `Strategy` artifact back, "consisted by Aim, Schedule, and Assignee". `Strategy` is not dormant — it was deliberately retired on 2026-07-28 (`tickets/archive/work-20260728-183130/20260728183203-retire-strategy-layer.md`, decision B3 of `docs/loop-engineering-workflow.md`) because long-lived direction accretes in the feedback stream and two direction homes would drift. The shape asked for here is not the retired shape: the retired artifact carried `## Direction` prose with **no completion conditions**, while Aim/Schedule/Assignee is a bounded, dated, owned thing. This is therefore a re-introduction with a new definition, and the work is to state that definition, register the area, and answer the retirement's reasoning rather than silently revert it.

The one live obstacle is `mission/scripts/migrate-strategies.sh`: it still runs at the mission scripts' living-migration seam and **converts any `.workaholic/strategies/` it finds into feedback records and removes the directory**. Revived without touching it, the new artifact is deleted by the next mission-script touch in this repo and in every consuming one.

## Policies

- `workaholic:planning` / `policies/terminology.md` — "strategy" re-enters the artifact vocabulary with a written definition, so the term is not re-litigated
- `workaholic:planning` / `policies/modeling-centric-design.md` — state the model (what a Strategy is, what relates to it) before any script
- `workaholic:design` / `policies/history-structures.md` — the 2026-07-28 retirement stays readable history; this is a recorded inversion, not an erasure
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` for every new script
- `workaholic:implementation` / `policies/objective-documentation.md` — no surviving sentence claims the strategy layer is retired once it is not

## Key Files

- `plugins/workaholic/skills/strategy/` — the skill to (re-)create: SKILL.md plus `scripts/` (create, list, read, close). The retired implementation is recoverable from git at `work-20260728-183130^` and is a starting point, not a template — the schema differs.
- `plugins/workaholic/skills/mission/scripts/migrate-strategies.sh` — the living migration that erases `strategies/`. It must stop running (retire it) or be inverted before anything is written into the area; leaving it wired deletes the revived artifact silently.
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` + `plugins/workaholic/rules/workaholic.md` — register `strategies` in **both, in the same commit** (closed-layout lockstep); a stale allowlist hard-blocks the first write.
- `plugins/workaholic/hooks/` — a write-time floor for the new type (`validate-strategy.sh`, wired in `hooks.json`), matching the mission/story/feedback validators: non-empty `type: Strategy` and the three mandated fields.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — re-add the `strategies/` area so the OKF bundle indexes it.
- `plugins/workaholic/skills/mission/SKILL.md` — append the redefinition record: what strategies were, why they were retired, why they return, and with what different shape.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `plugins/workaholic/rules/workaholic.md` — the docs sweep in the same change.
- `scripts/test-workflow-scripts.mjs` — hermetic cases for the new scripts and for the retired migration.

## Implementation Steps

1. Write the model first: what a `Strategy` is (Aim = the direction's substance; Schedule = the dated shape; Assignee = who carries it), where it lives (`.workaholic/strategies/<slug>/` or a flat file — decide and state it), and what it does **not** do, so the feedback stream stays the home of inbound direction.
2. Settle `migrate-strategies.sh` before writing any strategy file: retire it from the living-migration seam and keep its history readable. Verify no path re-adds it.
3. Register the area in the allowlist and the rules table in one commit; confirm `layout-doctor.sh .` reports `conforming: true` both before and after the first write.
4. Implement `skills/strategy/` with its scripts (create/list/read), following the mission skill's script conventions and its `lib/resolve.sh` layout-migration pattern.
5. Add `validate-strategy.sh` and wire it in `hooks.json`; grandfather git-tracked history exactly as the sibling validators do.
6. Re-add the `strategies/` area to `refresh-index.sh`; regenerate the OKF indexes.
7. Append the redefinition record to `skills/mission/SKILL.md`, then sweep the docs.
8. Argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/` and `policy-index.md`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report — the proposing session had no one to ask.

- **Does a mission link back to a strategy?** The 2026-07-28 retirement deliberately removed `strategy:` from the mission scaffold and folded strategy `assignees` down onto missions. Reviving the artifact does not by itself restore that relation, and restoring it re-opens the ownership hop `mission-owners.sh` used to make. Options: strategy stands free (no relation, no ownership hop); mission carries `strategy:` again; the strategy names its missions. The ask does not say.
- **What does `Schedule` mean?** A target date, a start/end window, or a recurring cadence. Each implies a different field shape and a different upkeep seam, and the derived progress a roadmap could show depends on it.
- **How does a `Strategy` relate to the feedback stream** now that the stream is the home of long-lived direction (B3)? Without an answer the two homes drift, which is exactly the failure the retirement named.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- `.workaholic/strategies/` is registered in the allowlist **and** the rules table, and `layout-doctor.sh .` reports `conforming: true`.
- A created strategy carries `type: Strategy` and non-empty Aim, Schedule, and Assignee; `validate-strategy.sh` rejects a write missing any of them.
- `migrate-strategies.sh` no longer erases the area: creating a strategy and then touching any mission script leaves the file present and unchanged.
- The mission SKILL.md redefinition record states the inversion with its provenance; no document still claims the strategy layer is retired.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, including a case that creates a strategy, runs a mission script, and asserts the file survives.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` and `validate-metadata.mjs` green with `outputs/` committed.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming.

**Gate** — what must pass before approval:

- Suite, build/verify, and layout-doctor green, plus an in-session demo: a strategy created, listed, and still present after a mission-script touch.

## Considerations

- The retirement's reasoning is the strongest argument against this ticket as specified; it is answered by the different shape (bounded, dated, owned) rather than dismissed. Record that answer in the redefinition record so the next reader does not re-litigate it a third time.
- Consuming repositories that already ran `migrate-strategies.sh` have their old strategies as feedback records. Nothing restores them, and nothing should — those records are history.
