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

1. Read the file `.claude-plugin/marketplace.json`
2. Parse the current `version` field (semantic version format: MAJOR.MINOR.PATCH)
3. Increment the version based on the argument:
   - `major`: Increment MAJOR, reset MINOR and PATCH to 0 (e.g., 1.2.3 → 2.0.0)
   - `minor`: Increment MINOR, reset PATCH to 0 (e.g., 1.2.3 → 1.3.0)
   - `patch` (default): Increment PATCH (e.g., 1.2.3 → 1.2.4)
4. Update the `version` field in `.claude-plugin/marketplace.json` using the Edit tool
5. Update the `version` field in `plugins/core/.claude-plugin/plugin.json` to match the new version
6. Update the `version` field in `plugins/tdd/.claude-plugin/plugin.json` to match the new version
7. Update the `core` plugin version in the `plugins` array within `.claude-plugin/marketplace.json` to match the new version
8. Update the `tdd` plugin version in the `plugins` array within `.claude-plugin/marketplace.json` to match the new version
9. Commit the change with message: `Release v{new_version}`
10. Push to remote

## Output

Report the old version, new version, and confirm the commit was pushed.
