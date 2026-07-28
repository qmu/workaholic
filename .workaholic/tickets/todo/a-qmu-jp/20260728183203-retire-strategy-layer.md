---
created_at: 2026-07-28T18:32:03+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain, Config]
effort: 4h
commit_hash:
category: Removed
depends_on: 20260728183202-carry-mission-ownership-on-assignees.md
mission: loop-engineering-foundation
---

# Retire the strategy layer

## Overview

Remove **strategy** as an artifact layer. Decision B3 of `docs/loop-engineering-workflow.md` (2026-07-28): in the feedback-driven model, long-lived direction is carried by the feedback stream itself — the corpus of human clues the proposal batch reads — so a separate direction artifact above missions is a second home for the same knowledge. The mission becomes the top *work* artifact; ownership already lives on it (`20260728183202`).

This inverts the 2026-07-21 decision that introduced strategies (mission `reorganize-missions-under-strategies`). Record the inversion honestly in the mission SKILL.md's redefinition records: what strategies were for (direction above bounded missions), why they are retired (direction now accretes as feedback; two direction homes would drift), and the provenance (this mission + the decision record). The granularity ladder becomes commit → ticket → mission, with "why are these missions launched" answered by the feedback corpus.

The mission's definition is rewritten at the same time (decision B5 of the record): a mission is the **epic-equivalent, optional grouping** of a batch of tickets for management and efficiency — typically pre-built as a set and executed together (often overnight) — **never a required parent**. The ticket stays the first-class standalone unit: `/ticket` → `/drive` with an empty `mission:` is a fully sanctioned path, exactly as the mechanism already behaves (`create-ticket`'s optional field, `validate-ticket.sh`'s present-value-only check, `/drive`'s per-ticket prompt). The 2026-07-21 phrase "overnight-executable execution plan of a strategy" is superseded on both ends — strategy (B3) and the mandatory-sounding framing (B5). Sweep for prose that implies every ticket belongs to a mission or that overnight-mission execution is *the* model rather than one of two modes.

Migration principle: **nothing is deleted from knowledge, only from structure.** Each live strategy's `## Direction` prose survives verbatim as a `source: discussion` feedback entry (authored by the strategy's author), and its `assignees` fold down into each linked active mission's `assignees` where empty.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:planning` / `policies/terminology.md` — "strategy" leaves the artifact vocabulary; the SKILL.md redefinition record states the retirement so the term is not re-litigated
- `workaholic:planning` / `policies/modeling-centric-design.md` — the model change (three-layer ladder, direction in the feedback corpus) is stated before the mechanics
- `workaholic:design` / `policies/history-structures.md` — archived missions keep their `strategy:` frontmatter as history, tolerated and never retro-blocked; the migration is a recorded transition, not an erasure
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` for the migration script (applies to all code work)
- `workaholic:implementation` / `policies/objective-documentation.md` — the docs sweep leaves no sentence claiming a strategy layer exists

## Key Files

- `plugins/workaholic/skills/strategy/` — remove the skill (SKILL.md + scripts). Grep the tree for every reference (`read-strategy-relation`, `read-assignees`, `strategy/scripts`, `workaholic:strategy`) and unwire each.
- `plugins/workaholic/skills/mission/scripts/mission-owners.sh` — drop the strategy hop; order becomes mission `assignees` → legacy `assignee`.
- `plugins/workaholic/skills/mission/scripts/migrate-strategies.sh` — new living migration, invoked from `lib/resolve.sh`'s migration seam like the flat-layout one (idempotent, best-effort, `git mv`/`git add` aware): when `.workaholic/strategies/` exists — convert each strategy file to a feedback entry via the feedback skill's `create.sh`, fold `assignees` down into linked active missions' empty `assignees`, then remove the directory. Runs in this repo during this ticket and in any other repo on its next mission-script touch.
- `plugins/workaholic/commands/mission.md` + `skills/mission/SKILL.md` — remove the Strategy-resolution step from create (3a) and replan; remove `strategy:` from the scaffold frontmatter (readers stay tolerant of the key on legacy files); rewrite the Granularity table to three layers with the feedback corpus answering "why"; append the redefinition record.
- `plugins/workaholic/hooks/validate-mission.sh` — drop the strategy-link requirement from the authorized floor (owner via `mission-owners.sh`, Experience, Acceptance remain).
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — drop the `strategies/` area (tolerate its absence and its lingering presence in not-yet-migrated repos).
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` + `plugins/workaholic/rules/workaholic.md` — remove `strategies` from **both** in this same commit, after the in-repo migration has emptied the directory (closed-layout lockstep; a stale row is a correctness bug in either direction).
- `scripts/test-workflow-scripts.mjs` — strategy suite removed; migration cases added.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `plugins/workaholic/rules/workaholic.md` — full docs sweep (project structure, runtime-OKF paragraph, `/mission`/`/monitor` command rows, mission-lens ownership prose).

## Implementation Steps

1. Reconcile with main (this worktree predates the unmerged ownership-move branch; land on the caught-up state — if strategies with `assignees` are present, the migration folds them; if the older assignee-on-mission state is present, the fold step is a no-op).
2. Implement `migrate-strategies.sh` (idempotent; feedback conversion + assignees fold + directory removal) and wire it into the mission scripts' living-migration seam.
3. Run the migration in this repo: `agent-orchestrated-development`'s Direction becomes a feedback entry; affected missions gain `assignees`; `.workaholic/strategies/` is gone.
4. Unwire the strategy skill everywhere (commands, mission skill, validator, okf indexer, monitor/ship/catch references), then delete `skills/strategy/`.
5. Update the allowlist and rules table (same commit as the removal).
6. Update tests; append the redefinition record; docs sweep.
7. Argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/` and `policy-index.md`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record `docs/loop-engineering-workflow.md`); verification depth ruling: hermetic suite + repo-state audit, per repo precedent.

**Acceptance criteria**

- No strategy step remains in mission creation/replan; `validate-mission.sh` authorizes a mission with owner + Experience + Acceptance and no `strategy:` value; legacy `strategy:` keys on archived missions are tolerated.
- `migrate-strategies.sh` is idempotent and converts Direction → feedback + folds assignees before removing the directory; a repo without `strategies/` is untouched.
- `.workaholic/strategies/` is absent from this repo, the allowlist, and the rules table — all in the same commit; `layout-doctor.sh .` reports `conforming: true`.
- `grep -r` for `strategy/scripts`, `read-strategy-relation`, `workaholic:strategy` over `plugins/` returns nothing; the redefinition record (including the B5 optional-grouping repositioning) and three-layer Granularity table are in place, and no remaining prose implies a ticket requires a mission.
- Docs sweep complete in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green (strategy suite removed, migration cases green).
- `node scripts/build-plugins/build.mjs` then `verify.mjs` + `validate-metadata.mjs` green; regenerated `outputs/` committed; `layout-doctor.sh .` conforming.
- POSIX lint conformance for the migration script.

**Gate**

- Suite green, build/verify green, layout-doctor conforming, and an in-session demo: `list.sh`/`mission-owners.sh` resolve this mission's owner from its own `assignees`, and the retired strategy's Direction is readable in `.workaholic/feedbacks/`.

## Considerations

- This mission's own `mission.md` carries `strategy: agent-orchestrated-development`; the validator change and the migration must land in the same drive so the authorized floor never briefly refuses the very mission being driven.
- Do not resurrect a "strategy" synonym (theme, initiative, epic) anywhere in the sweep — direction questions route to the feedback corpus and the decision record (`workaholic:planning` / `terminology`).
- `/monitor`, mission-lens, `summary.sh` need no behavioral change beyond what `20260728183202` already delivered — they read the oracle; verify, don't fork.
- The archived mission `reorganize-missions-under-strategies` and its tickets stay exactly as written — history is grandfathered, and the inversion is recorded forward in the redefinition record, not by editing the past.

