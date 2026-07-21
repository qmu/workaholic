---
created_at: 2026-07-21T02:57:18+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort: 2h
commit_hash:
category: Added
depends_on:
mission: reorganize-missions-under-strategies
---

# Add monitor completion report and reflection

## Overview

`/monitor` must end each run by making two things explicit, per driven mission: **(1) did it complete as planned, and if not, concretely why** — categorized from `status.sh` + the leaf JSON reports (escalation-blocked with the blocking decision named; deferred mid-run items; failed ticket gates; wave budget exhausted with N tickets remaining) — and **(2) a recorded 反省 (reflection)**: what stopped or would have stopped question-free autonomy this run, and what the next mission planning should front-load to prevent it. The reflection is the feedback loop of the overnight model: planning quality is measured by how few judgment calls leaked into the night, and the leak list is exactly what sharpens the next Creation Interrogation.

The reflection is **recorded in the mission artifact**, not just narrated in the report: a new append-only `## Reflection` section in `mission.md`, one dated entry per run, written through a new idempotent mutator. The next `/mission` creation **reads recent reflections back** (active + recently archived missions) before composing its interrogation, so recurring leak patterns become pre-answered questions.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX scripts (applies to all code work)
- `workaholic:development` / `policies/overnight-ai.md` — this is the "begin the workday by reviewing the previous night's results" loop, made into a recorded artifact; reflection exists to eliminate causes of stopping before the next run
- `workaholic:development` / `policies/review.md` — reflection corrects the **planning/policy side** that produced question-laden tickets; it is not code review and must not grow into reading back generated code
- `workaholic:development` / `policies/qa-engineering.md` — outcomes reported honestly; a reflection never softens the terminal token or reclassifies a blocked mission
- `workaholic:development` / `policies/explanations-on-demand.md` — reflections land as structured source information in the artifact (composable, one fact in one place), not only inside a finished report
- `workaholic:design` / `policies/history-structures.md` — `## Reflection` is append-only, dated, never rewritten

## Key Files

- `plugins/workaholic/skills/mission/scripts/append-reflection.sh` — new mutator: args `<mission> <run-id> <date>`, body on stdin; appends one dated entry under `## Reflection` (creating the section after `## Changelog` if absent), idempotent per `(run-id)` — a re-run appends nothing; git-stages. Entry format: `### <YYYY-MM-DD> run <run-id>` followed by three fixed bullets: `blocked:` (what stopped autonomy, or `none`), `leaked questions:` (judgment calls that surfaced mid-run, or `none`), `front-load next:` (what the next planning should pre-answer).
- `plugins/workaholic/skills/mission/SKILL.md` — schema: `## Reflection` joins the body sections (after `## Changelog`; explicitly outside `progress.sh`'s scope); Creation Interrogation: a new preparatory step "read recent reflections" (scan active + archived missions' `## Reflection` via a small read-only `list-reflections.sh`, fold recurring `front-load next:` items into the round-4 pre-answers).
- `plugins/workaholic/skills/mission/scripts/list-reflections.sh` — new read-only: emit recent reflection entries across areas as JSON `[{slug, date, run_id, blocked, leaked, front_load}]` (bounded, newest first).
- `plugins/workaholic/skills/monitor/SKILL.md` + `plugins/workaholic/commands/monitor.md` — §5: after the reconciliation line is computed, per driven mission (a) state completed-as-planned or the categorized reasons, (b) compose the three-bullet reflection from the run's own evidence (leaf reports, deferred-escalation list, status.sh) and write it via `append-reflection.sh` — the model composes the prose, the script owns placement and idempotency; the terminal token computation is untouched and emitted after.
- `plugins/workaholic/hooks/validate-mission.sh` — confirm the new section is tolerated (no floor change; reflections are optional).
- `.workaholic/concerns/monitor-s-decision-loop-has-no.md`, `.workaholic/concerns/monitor-s-dev-environment-lifecycle-has.md` — re-judge these two open concerns while in this code: resolve what this ticket's tests now cover, or re-defer with the reason updated.
- `scripts/test-workflow-scripts.mjs` — mutator/reader coverage.
- `outputs/workflows` — mission skill built: run the argument-less build. `CLAUDE.md` (`/monitor` row), `README.md`, `.workaholic/README.md` in the same change.

## Implementation Steps

1. Implement `append-reflection.sh` (idempotent per run-id, section-creating, append-only) and `list-reflections.sh` (read-only JSON).
2. Add `## Reflection` to the mission SKILL schema, with the fixed three-bullet entry contract and the explicit non-interference with `progress.sh`/`next-acceptance.sh` (assert in tests: a checklist-looking line inside `## Reflection` never counts).
3. Wire the §5 per-mission completion/reasons block and the reflection write into the monitor skill + command; reasons vocabulary is fixed (escalation-blocked / deferred / gate-failed / wave-exhausted / complete).
4. Add the read-back step to the mission Creation Interrogation (and replan round 4).
5. Re-judge the two open monitor concerns; record verdicts.
6. Hermetic tests; full build; docs.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo.

**Acceptance criteria**

- `append-reflection.sh` appends exactly one entry per `(mission, run-id)` across repeated calls, creates the section when absent, and never alters existing lines.
- A `- [ ]`-shaped line inside `## Reflection` changes neither `progress.sh` counts nor `next-acceptance.sh` output.
- `list-reflections.sh` returns entries across active+archive, newest first, parsing the three fixed bullets.
- Monitor §5 prose produces per-mission completed/reasons + reflection write; terminal token logic byte-identical in behavior (ok only on genuine completion).
- The two monitor concerns carry updated verdicts; docs and built outputs updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with mutator idempotency, section-creation, progress-isolation, and reader cases.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; POSIX lint.

**Gate**

- Suite green, build/verify green, and an in-session demo: append a reflection twice with one run-id to a throwaway mission (single entry results), then `list-reflections.sh` shows it.

## Considerations

- The reflection's prose is model-composed from run evidence — keep the *contract* (three bullets, dated, idempotent placement) in scripts so the artifact stays machine-readable even though the judgment is not (`skills/mission/scripts/append-reflection.sh`).
- Reflection must never become a fourth escalation channel: it records causes, the escalation list records pending decisions; do not blur them (`skills/monitor/SKILL.md` §5).
- Bound `list-reflections.sh` (e.g. latest N entries) so the interrogation read-back stays cheap as archives grow.
- An interrupted run that never reaches §5 writes no reflection — acceptable; `/carry`'s mission-monitor context already captures mid-run state, and the next completed run reflects over its own evidence.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: `## Reflection` is naturally outside `progress.sh`/`next-acceptance.sh` scope because any `## ` heading ends the `## Acceptance` section — so a `- [ ]`-shaped decoy inside a reflection bullet never counts. No guard code was needed; the existing section-scoping already isolates it, and a test now pins that.
  **Context**: `plugins/workaholic/skills/mission/scripts/progress.sh` scopes to `## Acceptance`; the reflection test asserts a checklist-shaped reflection line leaves 1/2 progress and next-acceptance unchanged.
- **Insight**: The two open monitor concerns were re-judged and both **re-deferred**, not resolved: reflection records *causes* and feeds the next interrogation, but the ticket's own doctrine forbids blurring that with the escalation list's *pending decisions* — so cross-run deferral memory (concern monitor-s-decision-loop) stays open, and the dev-environment lifecycle test gap (concern monitor-s-dev-environment-lifecycle) is untouched by this ticket.
  **Context**: `.workaholic/concerns/monitor-s-decision-loop-has-no.md` and `.workaholic/concerns/monitor-s-dev-environment-lifecycle-has.md` carry dated re-judgment notes.
