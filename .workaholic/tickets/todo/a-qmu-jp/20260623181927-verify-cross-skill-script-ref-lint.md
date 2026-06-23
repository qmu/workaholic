---
created_at: 2026-06-23T18:19:27+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort:
commit_hash:
category:
depends_on:
---

# Make verify.mjs catch fragile cross-skill script references before they ship broken

## Overview

Cross-skill script references in source `SKILL.md` must use the full `${SCRIPT_DIR}/../../../../<skill>/scripts/<x>.sh` form with literal uppercase `SCRIPT_DIR` for `build.mjs`'s `SCRIPT_CROSS_REF` regex to detect the dependency and copy the closure into `outputs/`. A shorter relative form resolves in the Claude-Code source tree but is **invisible to the build**, so the generated bundle ships to Codex and the `skills` CLI with a missing script (exit 127 at runtime). Add a deterministic lint to `verify.mjs` that flags any cross-skill script path not in the build-detectable form, turning a silent ship-time break into a pre-merge failure.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — cross-skill references and the generated `outputs/` closure are a structural contract; the lint enforces it mechanically.
- `workaholic:implementation` / `policies/coding-standards.md` — style/convention conformance for the verify-script change.
- `workaholic:implementation` / `policies/command-scripts.md` — script references and their resolution rules are the subject of this check.

## Key Files

- `scripts/build-plugins/verify.mjs` - PRIMARY. Add a pass that scans each source `SKILL.md` for cross-skill script paths and asserts they match the build-detectable `${SCRIPT_DIR}/../…/scripts/*.sh` form (and that the referenced script exists).
- `scripts/build-plugins/build.mjs` - Reuse / reference the existing `SCRIPT_CROSS_REF` regex so the lint and the build agree on exactly one accepted form (single source of truth).
- `plugins/workaholic/skills/*/SKILL.md` - The corpus the lint scans; confirm all current references already pass.

## Related History

Carried-over concern resolved into this ticket: [42-spec-relative-cross-skill-references-can.md](.workaholic/concerns/archive/42-spec-relative-cross-skill-references-can.md) (origin PR #42), re-surfaced through PRs #43/#44 before being canonicalized and ticketed in the 2026-06-23 concerns triage.

## Implementation Steps

1. Export or share the `SCRIPT_CROSS_REF` pattern from `build.mjs` so `verify.mjs` checks against the identical regex (avoid a second, drifting copy).
2. In `verify.mjs`, scan every source `SKILL.md` for cross-skill script invocations (a `scripts/*.sh` reference pointing outside the skill's own directory). For each, assert it uses the full literal-`SCRIPT_DIR` form the build can detect, and that the target script exists on disk.
3. Fail `verify.mjs` with a clear message naming the offending file, line, and the expected form when a reference would be invisible to the build.
4. Run `verify.mjs` against the current tree to confirm zero false positives; add/adjust a fixture or hermetic check if the existing smoke-test harness covers it.

## Considerations

- The lint and the build MUST share one pattern definition; a divergent copy would let a reference pass the lint yet be missed by the build, reintroducing the exact failure (`scripts/build-plugins/build.mjs`, `scripts/build-plugins/verify.mjs`).
- Keep the check deterministic and dependency-free (plain Node), consistent with the existing build tooling style.
