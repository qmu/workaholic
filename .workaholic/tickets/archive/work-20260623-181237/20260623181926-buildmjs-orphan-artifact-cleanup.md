---
created_at: 2026-06-23T18:19:26+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 0.25h
commit_hash: d504f0b
category: Changed
depends_on:
---

# Add an orphan-cleanup pass to build.mjs so renamed/removed skill scripts don't leave stale artifacts in outputs/

## Overview

When a bundled skill script is renamed or removed, `scripts/build-plugins/build.mjs` regenerates `outputs/` with the new name but does **not** delete the orphaned old artifact. The stale file lingers until someone manually stages its deletion, and the `Outputs Freshness` CI gate fails on the unexpected diff. Add a cleanup pass that removes generated artifacts no longer produced by the current source, so renames are safe without manual `git status -- outputs/` housekeeping.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — `outputs/` is generated, committed, and must stay in lockstep with source; the cleanup must keep that invariant.
- `workaholic:implementation` / `policies/coding-standards.md` — style/convention conformance for the build script changes.
- `workaholic:operation` / `policies/ci-cd.md` — the Outputs Freshness CI gate is the enforcement point; the cleanup makes the source→artifact contract self-healing rather than reliant on a manual step.

## Key Files

- `scripts/build-plugins/build.mjs` - PRIMARY. The assembly step that writes `outputs/workflows/`; add a pass that removes generated files absent from the freshly computed source closure (write to a temp dir, diff against the committed tree, or clear the target subtree before reassembly).
- `scripts/build-plugins/verify.mjs` - Verifies generated skills are self-contained; confirm it still passes after the cleanup pass.
- `.github/workflows/outputs-freshness.yml` - The CI gate that currently catches orphans by failing; the cleanup should make a rename produce a clean rebuild.

## Related History

Carried-over concern resolved into this ticket: [41-script-rename-requires-stale-artifact-cleanup.md](.workaholic/concerns/archive/41-script-rename-requires-stale-artifact-cleanup.md) (origin PR #41), re-surfaced through PRs #42/#43/#44 before being canonicalized and ticketed in the 2026-06-23 concerns triage.

## Implementation Steps

1. Identify where `assembleWorkflowsPlugin` writes the generated `outputs/workflows/skills/**` tree in `build.mjs`.
2. Before (or after) writing fresh artifacts, remove any generated file under the managed output subtree that the current build did not produce — e.g. clear the managed subtree at the start of assembly, or compute the produced-file set and unlink stragglers. Scope the deletion strictly to build-owned paths so nothing hand-authored is touched.
3. Run a rename smoke check: rename a bundled script in a workflow skill, run `node scripts/build-plugins/build.mjs`, and confirm `git status --porcelain outputs/` shows the old artifact deleted and the new one added (no orphan).
4. Re-run `verify.mjs`, `validate-metadata.mjs`, and `test-workflow-scripts.mjs`; revert the smoke-test rename.

## Considerations

- Scope deletions to build-owned output paths only — never a blanket `rm -rf` that could catch a hand-authored or co-located file (`scripts/build-plugins/build.mjs`).
- The cleanup must leave a no-op build with an empty `git status -- outputs/` (the Outputs Freshness contract), so run a second build and assert no diff (`.github/workflows/outputs-freshness.yml`).
