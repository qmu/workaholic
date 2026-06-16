---
created_at: 2026-06-17T08:22:42+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Rewrite the /release command for the single-plugin layout

## Overview

`.claude/commands/release.md` is badly stale and now broken after the plugin
merge. It still instructs updating `plugins/core/.claude-plugin/plugin.json` and
`plugins/tdd/.claude-plugin/plugin.json` (neither exists — `tdd` was removed long
ago and `core` was merged into `workaholic`), and it reads
`plugins/core/commands/sync-work.md` (also gone). A `/release` run today would fail
or silently miss every version file. (Carried concern `42/43-…-release-workflow-divergence`.)

Rewrite it to the consolidated version-file set documented in CLAUDE.md's Version
Management section:
- `.claude-plugin/marketplace.json` — root `version` + the `workaholic` and
  `workflows` `plugins[].version` entries.
- `plugins/workaholic/.claude-plugin/plugin.json`.
- `plugins/workaholic/.codex-plugin/plugin.json`.
- Regenerate `outputs/workflows/` so its Codex manifest picks up the new version.

## Key Files

- `.claude/commands/release.md` - The stale command. Replace steps 5-9 (the `core`/`tdd`/`sync-work` updates) with the consolidated single-plugin version-file set + a regenerate step. Keep the major/minor/patch arg parsing and the commit/push.
- `CLAUDE.md` (Version Management section) - The authoritative list this command must mirror; already updated to the single-plugin file set. Use it as the source of truth.
- `scripts/build-plugins/build.mjs` - The regenerate step (`node scripts/build-plugins/build.mjs`) that refreshes `outputs/workflows/.codex-plugin/plugin.json` from the new marketplace version.

## Related History

- This branch's plugin-merge work consolidated the version files from three plugin manifests to one; CLAUDE.md's Version Management was updated to match, but `.claude/commands/release.md` was not — this ticket closes that gap.

## Implementation Steps

1. Rewrite `.claude/commands/release.md` instructions to:
   - Read + bump `version` in `.claude-plugin/marketplace.json` (root + `workaholic` + `workflows` entries).
   - Update `plugins/workaholic/.claude-plugin/plugin.json` and `plugins/workaholic/.codex-plugin/plugin.json`.
   - Run `node scripts/build-plugins/build.mjs` to regenerate `outputs/workflows/`.
   - Commit `Release v{new_version}` and push.
2. Remove all references to `plugins/core`, `plugins/tdd`, and `sync-work.md`.
3. Keep the `major|minor|patch` argument handling and the Output report.
4. Sanity-check against the actual files (the version is currently 1.0.52 across them).

## Considerations

- **`.claude/commands/` is project-local, not a plugin.** This command lives outside
  `plugins/` (it operates ON the repo's manifests), so editing it here is correct
  and does not require a `dist/outputs` rebuild of its own. (`.claude/commands/release.md`)
- **Mirror CLAUDE.md exactly.** The Version Management section is the single source
  of truth for which files carry the semver; the command must not drift from it
  again. Consider having the command reference that section rather than
  re-enumerate, to prevent future divergence. (`CLAUDE.md` Version Management)
- **Don't hand-edit `outputs/`.** The command regenerates via `build.mjs`; the
  generated Codex manifest version is read from marketplace.json at build time.
  (CLAUDE.md "Generated (do NOT hand-edit)")
- Note the overlap with CI `release.yml` (which publishes the GitHub Release on
  push to main): `/release` bumps the version + commits; CI then cuts the release.
  Keep responsibilities distinct. (`.github/workflows/release.yml`)
