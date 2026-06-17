---
allowed-tools:
  - Read
  - Edit
  - Bash
---

# Release Command

Release a new version of the marketplace by incrementing the semantic version.

## Arguments

- `$ARGUMENTS`: Version bump type - `major`, `minor`, or `patch` (default: `patch`)

## Instructions

The authoritative list of version files is CLAUDE.md's **Version Management**
section — follow it. As of the single-plugin layout, all version files must stay
at the same semver:

1. Read `.claude-plugin/marketplace.json` and parse the current `version` (MAJOR.MINOR.PATCH).
2. Compute the new version from the argument:
   - `major`: increment MAJOR, reset MINOR and PATCH to 0 (e.g., 1.2.3 → 2.0.0)
   - `minor`: increment MINOR, reset PATCH to 0 (e.g., 1.2.3 → 1.3.0)
   - `patch` (default): increment PATCH (e.g., 1.2.3 → 1.2.4)
3. Update **`.claude-plugin/marketplace.json`**: the root `version` AND every
   `plugins[].version` entry (`workaholic` and `workflows`).
4. Update **`plugins/workaholic/.claude-plugin/plugin.json`** `version`.
5. Update **`plugins/workaholic/.codex-plugin/plugin.json`** `version`.
6. Regenerate the committed cross-agent artifacts so the generated Codex manifest
   (`outputs/workflows/.codex-plugin/plugin.json`) picks up the new version:
   ```bash
   node scripts/build-plugins/build.mjs
   ```
7. Verify alignment: `node scripts/build-plugins/validate-metadata.mjs` (asserts
   the Codex manifests match the marketplace version).
8. Stage and commit all of the above (including `outputs/`) with message:
   `Release v{new_version}`
9. Push to remote.

## Output

Report the old version, the new version, and confirm the commit was pushed.

## Notes

- This command only bumps the version and commits it. The `.github/workflows/release.yml`
  CI workflow publishes the GitHub Release on push to `main` (it reads the version
  and the latest note under `.workaholic/release-notes/`). Keep these
  responsibilities distinct — `/release` bumps; CI publishes.
- `outputs/` is generated and committed; never hand-edit it — step 6 regenerates it.
