---
created_at: 2026-06-17T00:03:02+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Rename the generated artifacts directory `dist/` to `outputs/`

## Overview

The committed, generated cross-agent artifacts live under `dist/` (specifically
`dist/workflows/`), produced by `scripts/build-plugins/build.mjs` from
`plugins/core` and served to Codex and the `skills` CLI via two manifests. Rename
that directory to `outputs/` everywhere it is referenced, in one self-consistent
commit, and regenerate so the new tree is committed and the freshness guard stays
green.

The directory is **generated and committed (not gitignored)**, so the rename is
performed by changing the build's output-path constants and running the
argument-less build — not by hand-editing files inside the tree. The committed
tree itself contains **no internal `dist` path references** (the Codex
`plugin.json` uses a relative `"skills": "./skills/"`), so a `git mv dist outputs`
preserves history and a regenerate confirms a clean diff.

Scope is confined to build scripts, the two manifests, the CI guard, and prose.
**Claude Code reads `plugins/` directly and consumes nothing from the generated
dir**, so no `${CLAUDE_PLUGIN_ROOT}` skill/command/agent path changes. Do **not**
touch the unrelated words `distribution` / `distinct` / `distributed`, and leave
immutable historical records under `.workaholic/stories/` and
`.workaholic/release-notes/` unchanged.

## Key Files

**Functional reference sites (must all move together):**

- `scripts/build-plugins/build.mjs` - PRIMARY producer. `const DIST_ROOT = join(REPO_ROOT, "dist")` (line ~34) is the one hardcoded output literal; everything else (`WORKFLOWS_PLUGIN = join(DIST_ROOT, "workflows")` line ~39, the `rmSync`/`mkdirSync`/`writeFileSync` calls, the final printed path) derives from it. Rename the literal to `"outputs"`, the constant `DIST_ROOT` → `OUTPUTS_ROOT`, and fix the `// dist/workflows` comments.
- `scripts/build-plugins/verify.mjs` - Second checker. `const DIST_ROOT = join(REPO_ROOT, "dist")` (line ~11) plus the error strings `"no dist/ — run build.mjs first"` (line ~22), the `dist/<agent>/` comment (line ~24), and `"no dist/<agent>/skills — run build.mjs first"` (line ~34).
- `.agents/plugins/marketplace.json` - Codex manifest: `workflows` entry `source.path: "./dist/workflows"` → `"./outputs/workflows"`.
- `.claude-plugin/marketplace.json` - skills-CLI/Claude manifest: `workflows` entry `"source": "./dist/workflows"` (line ~56) → `"./outputs/workflows"`. Leave the `plugins/core`, `plugins/standards`, `plugins/work` source entries unchanged.
- `.github/workflows/dist-freshness.yml` - CI guard. Path filters `- 'dist/**'` (lines ~12, ~18) → `outputs/**`; diff target `git diff --exit-code -- dist/` (line ~44) → `outputs/`; step names, comments, and echo strings ("Regenerate dist/…", "Assert dist/ matches…", "committed dist/ is out of sync", "dist/ is in sync"). Rename the file to `outputs-freshness.yml` and the `name: Dist Freshness` → `name: Outputs Freshness` for consistency.

**Cosmetic / prose:**

- `.github/workflows/validate-plugins.yml` - No functional change (line ~84 resolves `source` from the manifest generically). Update only the stale comment at line ~85 ("…or dist/ (generated, …)").
- `CLAUDE.md` - Many mentions: the Project Structure tree (`dist/` line + comment), the "Cross-agent distribution" section (`dist/workflows/`, "dist/ is committed, not gitignored", the `Dist Freshness` CI sentence and `.github/workflows/dist-freshness.yml` path), "consumes nothing from dist/", the Local Verification "regenerate dist/" line, and the Version Management "Generated" list (`dist/workflows/.codex-plugin/plugin.json`).
- `README.md` - "generated into portable artifacts under dist/", "committed plugin under dist/workflows/", the regenerate comment, and the `Dist Freshness` mention.
- `scripts/build-plugins/README.md` - Several `dist/workflows` mentions and the `Dist Freshness` CI reference.

**No change needed:** `.gitignore` (does not list `dist/`; the new `outputs/` must likewise stay committed — do not add an ignore rule).

## Related History

The `dist/` tree and its guard were built across the `work-20260518-235327`
branch; this rename repeats, one level up, the exact surface those tickets
established. The repo has a strong precedent of doing directory renames as
dedicated, self-consistent single-commit tickets.

- [20260527142130-relocate-cross-agent-output-into-dist.md](.workaholic/tickets/archive/work-20260518-235327/20260527142130-relocate-cross-agent-output-into-dist.md) - Origin of committed `dist/`: retargeted the build constants, removed the gitignore line, repointed the Codex manifest. Defines the rename surface and the "never leave the tree broken" discipline.
- [20260527142131-add-opencode-generated-target.md](.workaholic/tickets/archive/work-20260518-235327/20260527142131-add-opencode-generated-target.md) - Renamed `dist/codex` → `dist/workflows` and added the `workflows` entry to both manifests; closest precedent for the build-constant + dual-manifest repoint.
- [20260527142132-add-dist-freshness-ci-check.md](.workaholic/tickets/archive/work-20260518-235327/20260527142132-add-dist-freshness-ci-check.md) - Added `dist-freshness.yml`; its diff path and path filters are part of this rename.
- [20260527142133-update-docs-for-plugins-dist-topology.md](.workaholic/tickets/archive/work-20260518-235327/20260527142133-update-docs-for-plugins-dist-topology.md) - Template for the doc-sweep half; enumerates every prose surface naming `dist/`.

## Implementation Steps

1. **Move the tree with history**: `git mv dist outputs` (preserves the committed `outputs/workflows/` contents and their history).
2. **Build producer**: in `build.mjs`, change the `DIST_ROOT` literal `"dist"` → `"outputs"`, rename the constant `DIST_ROOT` → `OUTPUTS_ROOT` (and `WORKFLOWS_PLUGIN`'s derivation/comment), and update comment mentions.
3. **Checker**: in `verify.mjs`, change the `DIST_ROOT` literal and the three `dist/` error/comment strings; rename the constant for consistency.
4. **Manifests**: repoint `./dist/workflows` → `./outputs/workflows` in both `.agents/plugins/marketplace.json` and `.claude-plugin/marketplace.json`.
5. **CI guard**: update `dist-freshness.yml` path filters, diff target, and strings; rename the file to `outputs-freshness.yml` and its `name:` to `Outputs Freshness`. Update the stale comment in `validate-plugins.yml`.
6. **Docs**: sweep `CLAUDE.md`, `README.md`, and `scripts/build-plugins/README.md`, replacing `dist/` → `outputs/` and `Dist Freshness` → `Outputs Freshness` (leave `distribution`/`distinct` words intact).
7. **Regenerate and verify**: run `node scripts/build-plugins/build.mjs`, then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs`. Confirm `git diff` shows no unexpected drift under `outputs/` (the regenerate should reproduce the moved tree byte-for-byte at version 1.0.51).
8. **Final grep**: `grep -rn 'dist/' --exclude-dir=.workaholic .` should return only intentional/unrelated hits; confirm nothing functional still names the old directory.

## Considerations

- **Atomic, lockstep change.** Producer (`build.mjs`/`verify.mjs` constants), consumers (both manifests' `source` paths), guard (CI path filters + diff target), and prose must all move in one commit — a stale path in either manifest breaks install for that agent family, and a stale CI diff target silently stops the freshness guard from protecting the artifacts. (`standards:implementation` machine-checkable reachability; `standards:operation` CI/CD self-answering guard)
- **Regenerate, don't hand-edit the tree.** Per CLAUDE.md, the generated dir is do-not-hand-edit and CI-guarded. After `git mv`, the regenerate must reproduce `outputs/workflows/` identically; if `git diff` shows content drift, investigate before committing. (`CLAUDE.md` GENERATED/committed rule)
- **Keep `outputs/` committed.** The artifacts are committed, not gitignored. Do not add `outputs/` to `.gitignore`; Codex and the `skills` CLI install by reading the committed path. (`.gitignore`)
- **Version alignment preserved.** Regenerate so `outputs/workflows/.codex-plugin/plugin.json` reproduces at the shared semver (currently 1.0.51), read from the marketplace `workflows` entry. (`CLAUDE.md` Version Management)
- **Source-vs-artifact split untouched.** Only the artifact directory's name changes; `plugins/core` source, `${CLAUDE_PLUGIN_ROOT}` tokens, `metadata.internal`, and `publicizeSkillMd` behavior stay as-is. (`scripts/build-plugins/build.mjs`)
- **Naming thoroughness.** This ticket renames the full surface — directory, the `DIST_ROOT` constant, and the `dist-freshness.yml` workflow file/name — so nothing still reads "dist". If a lighter touch is preferred (move the directory but keep the internal constant/workflow names), drop steps 2's constant-rename, 3's constant-rename, and 5's file/name rename; the directory move + literal/manifest/path-filter updates are the minimum that keeps everything working.
- **Leave history immutable.** `.workaholic/stories/` and `.workaholic/release-notes/` are point-in-time records that legitimately reference `dist/`; do not rewrite them.
