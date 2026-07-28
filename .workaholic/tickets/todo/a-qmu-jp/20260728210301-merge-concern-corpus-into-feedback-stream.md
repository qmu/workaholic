---
created_at: 2026-07-28T21:03:01+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain, Config]
effort: 4h
commit_hash:
category: Changed
depends_on:
mission: loop-engineering-proposal-loop
---

# Merge the concern corpus into the feedback stream

## Overview

Execute decision H2 of `docs/loop-engineering-workflow.md`: **concern becomes a `kind` of feedback**, and the separate `concerns/` artifact retires. A deferred concern is inbound project context like any other — the distinction survives as the axis value (`kind: concern`), not as a second corpus with its own lifecycle machinery. Timing follows H3: concern records are written at the **carry-over seams** (ship-time extraction), and resolution is a **superseding record**, never a status flip.

Target record shape (`.workaholic/feedbacks/<ts>-<concern_id>.md`, `ts` from `first_seen`):

```yaml
type: Feedback
title: <concern title>
kind: concern
source: development        # NEW enum value — a concern arrives from the development process, not a meeting/chat
created_at: <first_seen>
author: <email>
supersedes:                # a resolution record points back at the record it moots
severity: <low|moderate|urgent>   # producer fields ride along (OKF tolerates extensions)
concern_id: <id>
mission: [...]
tickets: [...]
origin_pr: <n>
origin_pr_url: <url>
origin_branch: <branch>
origin_commit: <hash>
```

**The open set is computed, never stored**: a concern is open iff no record names it in `supersedes` (and it carries no migration-only `closed:` field — see Steps). The lifecycle machinery this replaces — triage prompt, `merge-concerns.sh`, `re-grade.sh`, `close-concern.sh`, `propose-demotions.sh`, `demote-concern.sh`, `migrate-concern-identity.sh`, the promotion floor (`CONCERN_PROMOTE_MIN`), the `(carried from PR #N)` prepending — **retires**: curation becomes the reader's judgment over the stream (H2), and a story's section 6 records only *this branch's* concerns.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:planning` / `policies/terminology.md` — one concept, one word: "concern" stays the *kind*, the artifact is a *feedback*; record the merger in the feedback SKILL.md so it is not re-litigated
- `workaholic:design` / `policies/history-structures.md` — resolution is an append-only superseding record; the migration is a recorded transform, and git history preserves the old corpus
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` (applies to all code work)
- `workaholic:implementation` / `policies/directory-structure.md` — conventional placement of the new scripts (applies to all code work)
- `workaholic:implementation` / `policies/objective-documentation.md` — the open-set rule and the seam timing are documented in verifiable language

## Key Files

- `plugins/workaholic/skills/feedback/SKILL.md` + `hooks/validate-feedback.sh` — add `development` to the `source` enum; document `kind: concern` producer fields and the computed open-set rule; update the "concern boundary" paragraph (the merger has landed).
- `plugins/workaholic/skills/feedback/scripts/list-open-concerns.sh` — NEW: the single reader of the open concern set (kind `concern`, minus superseded, minus migration-`closed:`); JSON envelope replacing `report/scripts/list-active-deferred-concerns.sh`'s (keep `active_count`/`my_lane_count`/`owner_counts` keys so `/report` consumers stay stable; lane owner from the record's `mission:` via `mission-owners.sh` as today).
- `plugins/workaholic/skills/feedback/scripts/migrate-concerns.sh` — NEW living migration (modeled on `migrate-strategies.sh`, wired the same way from the extraction/report seams plus a direct entry): active concern files → open records; `concerns/archive/` files → records stamped with a migration-only `closed: <resolved|accepted|demoted|superseded>` frontmatter field (one-time transform; post-migration closures are superseding records); then remove `concerns/` (git rm when tracked). Idempotent, best-effort, deterministic filenames from `first_seen` + `concern_id`.
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` — rewrite: run the migration first, then write each section-6 concern as a `kind: concern` record (identity-keyed update-in-place by `concern_id` becomes **append-only**: a re-shipped identical concern is skipped by id, never rewritten). **Promotion floor retired** — every severity is recorded (the stream is append-forever by design; `Keep:` becomes a no-op, tolerated in old stories). Mission changelog rolling (`concern deferred (stuck)`) unchanged.
- `plugins/workaholic/skills/report/SKILL.md` + `scripts/apply-deferred-concern-verdicts.sh` — Phase 1 judge reads `list-open-concerns.sh` and, for each concern this branch resolved, writes a **superseding record** (`kind: concern`, `supersedes: <filename>`, body naming the resolving PR/commit) — rewrite `apply-deferred-concern-verdicts.sh` to emit those records (keep the expected-count fail-loud contract). Phase 1b (triage) and the carried-from prepending are **removed** from the SKILL; `review-sections` loses the still-active prepend input.
- **Deleted**: `report/scripts/{merge-concerns,re-grade,close-concern,propose-demotions,demote-concern,migrate-concern-identity,list-active-deferred-concerns}.sh` and their tests.
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` + `plugins/workaholic/rules/workaholic.md` — remove `concerns` from both in the same commit as the in-repo migration (closed-layout lockstep).
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — drop the `concerns` area (tolerate lingering trees in unmigrated repos).
- `scripts/test-workflow-scripts.mjs` — extraction/judge/migration suites reworked; concern-lifecycle suites removed.
- `CLAUDE.md` (runtime-OKF paragraph: promotion-floor/demotion prose replaced by the stream model), `README.md` (lifecycle table + concerns sections), `.workaholic/README.md` — docs swept in the same change.

## Implementation Steps

1. Extend the feedback schema (`source: development`, producer fields, open-set rule) in SKILL.md + validator; add `list-open-concerns.sh`.
2. Implement `migrate-concerns.sh` (active → open records; archived → `closed:`-stamped records; directory removal) and wire it into the extraction/report seams.
3. Rewrite `extract-deferred-concerns.sh` (append-only record writer, floor retired, migration-first).
4. Rewrite the report judge seam: `apply-deferred-concern-verdicts.sh` emits superseding records; strip Phase 1b + carried-from from `report/SKILL.md` and `review-sections`.
5. Delete the retired lifecycle scripts and their tests; rework the remaining suites (extraction round trip, resolution supersedes, migration idempotency + seam, open-set reader).
6. Run the migration in this repo; remove `concerns` from allowlist + rules table in the same commit; `layout-doctor.sh .` conforming.
7. Docs sweep; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record H2/H3); verification depth ruling: hermetic suite + in-repo migration demo, per repo precedent.

**Acceptance criteria**

- Ship extraction writes conformant `kind: concern` records for **all** severities and never rewrites an existing id; the mission changelog roll still fires.
- `/report` resolution emits a superseding record naming the resolved record and the resolving PR/commit; `list-open-concerns.sh` then excludes it; the expected-count fail-loud contract survives.
- The lifecycle scripts are gone; `grep -rn "propose-demotions\|demote-concern\|merge-concerns\|re-grade\|close-concern\|list-active-deferred-concerns\|CONCERN_PROMOTE_MIN\|carried from PR" plugins/` returns nothing live.
- This repo's corpus (6 active + archive) is migrated; `.workaholic/concerns/` is absent from tree, allowlist, and rules table in the same commit; `layout-doctor.sh .` reports `conforming: true`.
- Docs updated in the same change; suite/build/verify/metadata green.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the reworked suites; `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; posix-lint conforming.

**Gate**

- Suite green, layout-doctor conforming, and an in-session demo: the six live concerns readable via `list-open-concerns.sh` from `.workaholic/feedbacks/`, with one resolution round-trip exercised in a hermetic repo.

## Considerations

- Keep the section-6 story format untouched — it is the immutable in-branch record (H2) and the extraction parser's input; only the *destination* of extraction changes.
- Do not add any mutable state to feedback records: no `status`, no in-place severity edits. A re-graded severity, should it ever matter again, is a new superseding record with the new severity.
- `list-open-concerns.sh` keeping the old envelope keys is deliberate transition safety for `/report`'s prose; drop `should_triage` (always false — the trigger died with the triage).
- Unmigrated repos: the extraction/report seams run the migration first (same pattern as `migrate-strategies.sh`), so `concerns/` disappears from any repo on its next ship or report — never require a manual step.

