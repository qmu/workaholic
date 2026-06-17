---
author: a@qmu.jp
created_at: 2026-06-17T23:18:48+09:00
modified_at: 2026-06-17T23:18:48+09:00
title: Workaholic marketplace plugin
environment: production
confirmation_method: other
command: gh release view v<version>
---

# Workaholic marketplace plugin

Workaholic is a Claude Code plugin marketplace plus a cross-agent skills bundle.
It has no server runtime; "production" is the published state on `origin/main`
(which the `skills` CLI and Codex install from by repo path) plus the GitHub
Release/tag for the version. This is a **deploy-on-merge** target: the merge to
`main` is the deployment, and the GitHub Release is published from the merge
commit (by `publish-release.sh` or CI). So the pre-merge confirmation is the
branch/staging-level proof; the release tag is confirmed post-merge.

## Procedure

1. Bump the version across the lockstep files (`.claude-plugin/marketplace.json`
   root + both `plugins[].version`, `plugins/workaholic/.claude-plugin/plugin.json`,
   `plugins/workaholic/.codex-plugin/plugin.json`) and regenerate `outputs/`
   (`node scripts/build-plugins/build.mjs`). `/report` does this.
2. Merge the release PR to `main` — this IS the deployment.
3. Publish the GitHub Release for `v<version>` from the merge commit (handled by
   `publish-release.sh`, which defers to CI when a release workflow exists).

## Confirmation

Pre-merge (branch/staging proof that the artifact is production-ready):

1. `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/`
   is empty — `outputs/` is fresh (the Outputs Freshness CI gate will pass).
2. `node scripts/build-plugins/verify.mjs` and
   `node scripts/build-plugins/validate-metadata.mjs` pass (generated skills
   self-contained; Codex manifests valid and version-aligned).
3. `node scripts/test-workflow-scripts.mjs` passes (hermetic smoke tests).
4. The version in `.claude-plugin/marketplace.json` matches the intended
   `v<version>` and is consistent across all lockstep files.

Post-merge (production promotion is live):

5. `gh release view v<version>` returns the release, targeting the merge commit
   on `main`, so a fresh `npx skills add qmu/workaholic` / plugin install
   resolves the new version.
