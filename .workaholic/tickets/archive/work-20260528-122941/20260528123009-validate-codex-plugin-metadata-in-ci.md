---
created_at: 2026-05-28T12:30:09+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 4d8bfba
category: Changed
depends_on: [20260528123008-sync-cross-agent-plugin-versions.md]
---

# Validate Codex Plugin Metadata In CI

## Overview

Extend plugin validation so CI checks the Codex-facing marketplace and `.codex-plugin/plugin.json` files, not only the Claude plugin metadata. The repository already caught a real drift case manually: Codex manifests can be valid JSON and still report stale versions or point to missing skill folders. Make that class of error fail in CI.

## Key Files

- `.github/workflows/validate-plugins.yml` - Existing plugin metadata validation workflow; currently validates Claude marketplace JSON and Claude plugin JSON.
- `.agents/plugins/marketplace.json` - Codex marketplace pointer that should be validated for JSON shape, plugin source paths, and installable plugin directories.
- `plugins/standards/.codex-plugin/plugin.json` - Codex-facing standards manifest that should be validated for required fields and version consistency.
- `dist/workflows/.codex-plugin/plugin.json` - Generated Codex-facing workflows manifest that should be validated after generation.
- `.claude-plugin/marketplace.json` - Expected source for public plugin versions or comparison baseline.
- `scripts/build-plugins/verify.mjs` - Existing self-contained artifact verifier; may be extended or complemented by a metadata verifier.

## Related History

The existing CI validates generated artifact freshness but does not fully validate public Codex plugin metadata. This ticket complements, rather than replaces, the dist freshness check.

Past tickets that touched similar areas:

- [20260527142132-add-dist-freshness-ci-check.md](.workaholic/tickets/archive/work-20260518-235327/20260527142132-add-dist-freshness-ci-check.md) - Added CI to regenerate and diff `dist/`, and fixed validation to resolve marketplace plugin sources instead of assuming `plugins/<name>`.
- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - Noted that duplicated manifests drift unless version sync is explicitly tracked.
- [20260527012303-codex-plugin-manifests-and-exposure.md](.workaholic/tickets/archive/work-20260518-235327/20260527012303-codex-plugin-manifests-and-exposure.md) - Added Codex-facing manifest exposure that should now be covered by CI.

## Implementation Steps

1. Update `.github/workflows/validate-plugins.yml` to validate `.agents/plugins/marketplace.json` with `jq`.
2. For each plugin entry in `.agents/plugins/marketplace.json`, resolve `source.path`, confirm the directory exists, and confirm it contains `.codex-plugin/plugin.json`.
3. Validate each `.codex-plugin/plugin.json` for required fields: `name`, `version`, `description`, `author`, and `skills`.
4. Confirm each Codex manifest's `skills` path exists and contains at least one skill directory with a `SKILL.md`.
5. Add version-alignment checks between `.claude-plugin/marketplace.json` and the Codex manifests for plugins that are exposed through both channels.
6. Run the updated workflow logic locally or reproduce the shell steps manually before committing.

## Considerations

- Keep validation source-path based. The workflows plugin intentionally lives under `dist/workflows`, so CI must not assume every plugin source is under `plugins/` (`.agents/plugins/marketplace.json`).
- Avoid duplicating complex validation logic inline if it becomes hard to read; a small `scripts/build-plugins/validate-metadata.mjs` helper may be cleaner than a long shell block (`.github/workflows/validate-plugins.yml`).
- This ticket depends on the version-sync ticket so CI does not start failing immediately because of the known existing drift.

## Final Report

Development completed as planned.
