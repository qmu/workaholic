---
created_at: 2026-07-21T02:07:59+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 1h
commit_hash:
category: Added
depends_on:
mission: reorganize-missions-under-strategies
---

# Add a per-commit changed-lines gate to release-scan

## Overview

`release-scan` currently bounds diff size only **per file** (`MAX_FILE_ADDED_LINES=3000`), **per branch** (`MAX_FILES=100`), and **per file bytes** (`MAX_FILE_BYTES=524288`), all at `size`/override severity. There is **no bound on the total changed lines of a single commit**. This ticket adds a per-commit total-changed-lines gate (added + deleted), with an exemption for generated / bulk-data files so lockfiles and large generated artifacts do not trip it.

The motivation is a measured one. An aggregate study of ~8,600 agent-authored commits (identified by the `Co-Authored-By` Anthropic trailer) across a portfolio of local repositories found the per-commit changed-line distribution is extremely right-skewed: median 79 lines, but a coefficient of variation of ~18 driven almost entirely by a small tail of generated-data / lockfile commits (single commits of hundreds of thousands of lines). Simulating a ~500-line per-commit cap **with the bulk/generated tail exempted** collapses the coefficient of variation from ~18 to ~0.9 — i.e. it makes per-commit size a stable, comparable unit. Standardizing the commit as a unit is what makes "commit count" usable as a team throughput signal; without the cap, count and size are both volatile and neither is comparable across developers or agents.

This gate gives the workaholic pipeline a machine-checkable way to keep agent commits at a reviewable, standardized granularity, which is also good for review quality independent of any KPI use. (Within this mission it is the normalization foundation the commit-count KPI ticket `20260721025720` builds on.)

## Policies

The standard engineering policies that govern this ticket. The implementing session MUST read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — shell/style conventions; the gate is a POSIX script under a skill's `scripts/`
- `workaholic:operation` / `policies/ci-cd.md` — the gate participates in the `/report` (warn) and `/ship` (block) release path; its verdict/severity contract must stay reproducible and script-only

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` — where the `size` findings are produced (`MAX_FILES`, `MAX_FILE_ADDED_LINES`, `MAX_FILE_BYTES`); the new per-commit check belongs alongside these as a new `size` rule
- `plugins/workaholic/skills/release-scan/SKILL.md` — documents the gate's rules and severities; update in the same change
- `outputs/workflows/skills/report/release-scan/scripts/scan-branch-safety.sh` and `outputs/workflows/skills/ship/release-scan/scripts/scan-branch-safety.sh` — generated copies; regenerate with `node scripts/build-plugins/build.mjs`, do not hand-edit
- `CLAUDE.md` (`### Release-safety scan`) — describes the scan's scope; update to mention the per-commit rule

## Implementation Steps

1. Decide the surface: the current scan runs over `git diff <base>..HEAD` (whole branch). A "per-commit" bound needs a per-commit walk (`git rev-list <base>..HEAD` then `git show --numstat` per commit), or an equivalent. Keep it deterministic and script-only — no model judgment in a merge gate.
2. Add a `MAX_COMMIT_CHANGED_LINES` threshold (proposed default ~500) and, for each commit, sum added + deleted lines **excluding** files classed as generated/bulk (e.g. `-` numstat binary rows, lockfiles, and paths matching a small generated-artifact glob / `.gitattributes linguist-generated`, plus a per-file line ceiling that reuses the existing bulk intuition). Emit a `size` finding (`too-large-commit`) citing the commit and its counted line total when it exceeds the threshold.
3. Keep severity `override` (consistent with the other `size` rules) so it warns in `/report` and can be consciously overridden — this is a granularity nudge, not a credential-class hard block.
4. Make the generated/bulk exemption explicit and documented, so the giant generated commits that motivated the tail are never the thing that trips it.
5. Update `SKILL.md` and `CLAUDE.md` in the same change (docs-in-lockstep rule).
6. Regenerate `outputs/` and confirm the freshness gate is clean.

## Quality Gate

**Acceptance criteria**

- A commit whose non-generated changed lines exceed `MAX_COMMIT_CHANGED_LINES` produces exactly one `size` / `too-large-commit` finding citing the commit hash and the counted total.
- A commit consisting solely of generated/bulk/lockfile changes produces **no** `too-large-commit` finding regardless of size.
- Existing `size`/`secret`/`leak` findings are unchanged; the JSON `{verdict, findings[]}` contract is preserved.
- `SKILL.md`, `CLAUDE.md`, and the two generated `outputs/.../scan-branch-safety.sh` copies are updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic cases covering: an over-threshold hand-authored commit (finding present), an over-threshold purely-generated commit (no finding), and threshold-boundary behavior.
- `node scripts/build-plugins/verify.mjs` and the `Outputs Freshness` check pass (generated copies in lockstep).
- POSIX-lint conformance for the script.

**Gate**

- Suite green, lint conforming, outputs fresh, and the new behavior demonstrated on a throwaway repo in-session before approval.

## Considerations

- Per-commit walking is more expensive than the current single whole-branch diff; keep it bounded (the scan already reads the diff once — reuse where possible) so it stays fast on large branches (`scan-branch-safety.sh`).
- The threshold value (~500) and the generated-file classification are policy calls; expose the threshold as a named constant next to `MAX_FILE_ADDED_LINES` so it is trivially tunable and reviewable.
- This gate standardizes commit *size*; commit *count* as a throughput signal is ticket `20260721025720` — a size cap shifts volume into count (a large change becomes several commits), a property to document, not a defect.
- Severity choice: keeping it `override` avoids blocking legitimate large-but-reviewed commits while still surfacing them; a hard block would be the wrong tier for a granularity heuristic.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The generated/bulk exemption is best expressed through `.gitattributes linguist-generated` rather than hard-coded path globs, because it lets each repo mark its own generated trees while keeping `scan-branch-safety.sh` generic. This repo now carries `.gitattributes` marking `outputs/**` linguist-generated, which both exempts bulk regenerations from the per-commit gate and collapses them in GitHub diffs.
  **Context**: A future contributor tempted to hard-code `outputs/` into the scanner should instead extend `.gitattributes` — the scanner's `is_generated_path` deliberately keeps only lockfile/minified globs plus the attr check.
- **Insight**: The per-commit walk reuses the existing per-file `MAX_FILE_ADDED_LINES` ceiling as a bulk cut-off (a file already flagged `large-added-lines` is excluded from the commit sum), so the two size rules never double-count the same bulk file.
  **Context**: `skills/release-scan/scripts/scan-branch-safety.sh` — the coupling is intentional; changing one ceiling shifts the other's exemption boundary.
