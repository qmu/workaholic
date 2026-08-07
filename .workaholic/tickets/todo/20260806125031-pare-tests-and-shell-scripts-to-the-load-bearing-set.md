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
