---
created_at: 2026-07-22T09:18:09+09:00
author: a@qmu.jp
type: enhancement
layer: [Application]
effort: 4h
commit_hash:
category: Added
depends_on:
mission:
---

# Corpus-wide concern judge: judge against default-branch HEAD, not the active branch

## Overview

Split off from `20260722004500` (mechanism 1). Today the deferred-concern judge only credits work on the *current* branch (`origin_commit..HEAD`), so a concern fixed by any other branch stays active forever and the corpus only ever grows between deliberate cleanups. Add a **corpus-wide judge pass** — a `/triage` command mode or a report Phase-1 variant — that judges every active concern against the *current default-branch HEAD state* (referenced paths exist? flagged pattern still present? described behavior still reproducible?), applying verdicts through the existing `apply-deferred-concern-verdicts.sh` so the audit trail is identical. This is the highest-value single change: it converts the corpus from append-only to self-cleaning.

## Policies

- `workaholic:implementation` / `objective-documentation` — verdicts leave the same auditable trail as the branch-scoped judge; `resolved` records `resolved_by_*`.
- Thin commands, comprehensive skills — a new `/triage` command is orchestration only; the judging knowledge is a report/skill section a `general-purpose` leaf preloads.
- `workaholic:development` / `qa-engineering` — judge proposes, developer decides; auto-apply only evidence-backed `resolved`, never `accepted`.

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` (Judge Deferred Concerns) — the branch-scoped evidence commands to generalize to default-branch HEAD.
- `plugins/workaholic/skills/report/scripts/apply-deferred-concern-verdicts.sh` — reuse verbatim for the verdict application/audit trail.
- A new `commands/triage.md` (if the command-mode route is chosen) — Claude-only orchestration.

## Implementation Steps

1. Decide the surface: a standalone `/triage` command mode vs a `/report` Phase-1 variant (record the choice).
2. Judge every active concern against default-branch HEAD (not a branch range); reuse `list-active` for the set and `apply-deferred-concern-verdicts.sh` for verdicts.
3. Keep it judge-proposes/developer-decides for anything irreversible.

## Quality Gate

- **Acceptance**: a concern whose fix landed on a *different* branch is judged `resolved` by the corpus-wide pass, with `resolved_by_*` recorded, on a synthetic fixture.
- **Verification**: `node scripts/test-workflow-scripts.mjs` green with a fixture exercising the cross-branch resolution; `verify.mjs` passes.
- **Gate**: no `accepted` closure without developer confirmation; every auto-applied closure writes its evidence.

## Considerations

- The judging itself is a model task (a `general-purpose` leaf), so the hermetic test pins the *plumbing* (set selection, verdict application, audit trail), not the model's judgement.
