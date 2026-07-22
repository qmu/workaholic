---
created_at: 2026-07-22T09:18:11+09:00
author: a@qmu.jp
type: enhancement
layer: [Application]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# Extraction hygiene: refuse/split aggregate "carried N items" concern blocks

## Overview

Split off from `20260722004500` (mechanism 3). ~13% of an audited corpus were aggregate placeholder blocks ("N carried items from earlier PRs") that name no single risk, were created at extraction time, and survived every judge pass because nothing can "fix" an aggregate. Make `extract-deferred-concerns.sh` **refuse** (or split into linked singles) any section-6 block whose title matches an aggregate carry shape (`carried N items`, `持ち越しN件`), and add an idempotent migration that collapses existing placeholder aggregates into their member concerns or closes them as `superseded`.

## Policies

- `workaholic:implementation` / `objective-documentation` — the migration records what it collapsed/closed and why.
- Backward compatibility — the migration is idempotent and best-effort, like `migrate-concern-identity.sh`.
- Shell Script Principle — the aggregate-shape test lives in the extractor/migration scripts.

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` — reject/split the aggregate block at extraction.
- `plugins/workaholic/skills/report/scripts/migrate-concern-identity.sh` (or a sibling migration) — collapse existing aggregates idempotently.

## Quality Gate

- **Acceptance**: a section-6 block titled like an aggregate carry is not written as a single concern (refused or split), demonstrated on a fixture; an existing aggregate file is collapsed/superseded by the migration, with the trail visible in `archive/`.
- **Verification**: `node scripts/test-workflow-scripts.mjs` green with the new fixtures; `verify.mjs` passes.
- **Gate**: the migration never deletes without recording a `superseded`/close rationale.

## Considerations

- Match the aggregate shape conservatively (a clear "N items"/"N件" carry title), so a legitimately-titled concern is never mistaken for debris.
