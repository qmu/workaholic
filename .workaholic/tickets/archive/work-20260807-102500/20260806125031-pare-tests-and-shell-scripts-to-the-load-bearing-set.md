---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Pare tests and shell scripts to the load-bearing set

## Overview

<!-- PROPOSED. Sharpened by the mission's approval interrogation. -->

FB item 4: tests and shell scripts have multiplied beyond what the loop needs.
Remove tests that assert retired behavior or duplicate coverage, and collapse or
delete scripts that no live skill/command/hook calls — keeping the ones on the
`/drive`/`/ship` critical path. Reduction is by deletion of the unneeded, verified
by the remaining suite still passing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/*/scripts/*.sh` — audit for callers; delete the uncalled.
- `scripts/test-workflow-scripts.mjs` and other test entrypoints — prune retired/duplicate cases.
- `plugins/workaholic/hooks/*` — confirm nothing pruned is still referenced.

## Implementation Steps

1. Build a caller map: which scripts are referenced by any SKILL/command/hook/test.
2. Delete scripts with no live caller; note each removal.
3. Prune tests asserting retired behavior or duplicating another test.
4. Run the full local verification set; ensure green.

## Quality Gate

**Acceptance criteria:**

- No orphaned scripts remain; every kept script has a live caller.
- The test suite is smaller and still passes.

**Verification method:**

- `node scripts/test-workflow-scripts.mjs`, `verify.mjs`, `validate-metadata.mjs` all pass.

**Gate:**

- No loss of coverage for the `/drive`/`/ship` critical path.

## Considerations

<!-- "Load-bearing" needs a defensible definition so a needed edge-case test is
     not cut; the approval interrogation should set the bar. -->

## Final Report

Development completed as planned. A full caller map over the 151 shell scripts (SKILL.md, reference/, commands/, hooks, scripts, build tooling, CI, tests as callers) found exactly one orphan — `ship/scripts/backfill-deferred-concerns.sh`, a one-time migration with zero callers — deleted with its three generated copies. Everything else is live; the conservative keeps (posix-lint.sh named by rules/shell.md, push-outcome.sh sourced by four ship scripts) are recorded. The test suite went from 58 deliberate failures (prose pins over relocated command/skill content) to 2,415 passed / 0 failed: 54 assertions retargeted to the files now carrying the rules, 1 deleted (it pinned dropped retirement narration), 1 pruned as duplicate coverage. No live rule was lost — zero source regressions surfaced.

### Discovered Insights

- **Insight**: The script inventory was already load-bearing — the multiplication the ticket assumed was mostly in prose pins, not in scripts.
  **Context**: The caller map is the reusable artifact here; run it again after any future skill restructuring.
