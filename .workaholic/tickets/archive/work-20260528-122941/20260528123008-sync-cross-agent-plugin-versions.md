---
created_at: 2026-05-28T12:30:08+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: 665ee42
category: Changed
depends_on:
---

# Sync Cross-Agent Plugin Versions

## Overview

Eliminate version drift between the Claude marketplace metadata and the Codex-facing plugin manifests. The current repository advertises Workaholic `1.0.50` in `.claude-plugin/marketplace.json`, while the Codex manifests still report older versions (`workflows` at `1.0.0`, `standards` at `1.0.48`). Bring every public manifest back to one source of truth so installed plugin metadata reflects the same release across agents.

## Key Files

- `.claude-plugin/marketplace.json` - Current top-level version source used by the release workflow.
- `plugins/standards/.claude-plugin/plugin.json` - Claude-facing standards manifest with the current standards version.
- `plugins/standards/.codex-plugin/plugin.json` - Codex-facing standards manifest currently lagging behind the Claude version.
- `scripts/build-plugins/build.mjs` - Generates `dist/workflows/.codex-plugin/plugin.json` and currently hardcodes `version: "1.0.0"`.
- `dist/workflows/.codex-plugin/plugin.json` - Generated Codex-facing workflows manifest that should be regenerated, not hand-edited.
- `README.md` and `scripts/build-plugins/README.md` - Document the generated distribution and may need a note about version sourcing if the build behavior changes.

## Related History

Recent cross-agent packaging tickets established the current `plugins/` source and `dist/workflows/` generated-output model. This ticket is a metadata correctness follow-up, not a topology change.

Past tickets that touched similar areas:

- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - Identified manifest duplication as a maintenance cost and called out the need to keep per-agent manifest versions synchronized.
- [20260527012303-codex-plugin-manifests-and-exposure.md](.workaholic/tickets/archive/work-20260518-235327/20260527012303-codex-plugin-manifests-and-exposure.md) - Shipped Codex plugin manifests and exposure for the workflows plugin.
- [20260527142131-add-opencode-generated-target.md](.workaholic/tickets/archive/work-20260518-235327/20260527142131-add-opencode-generated-target.md) - Consolidated non-Claude distribution into `dist/workflows/` and noted that one generated plugin serves multiple agent installers.
- [20260527142133-update-docs-for-plugins-dist-topology.md](.workaholic/tickets/archive/work-20260518-235327/20260527142133-update-docs-for-plugins-dist-topology.md) - Updated docs around the committed generated distribution topology.

## Implementation Steps

1. Choose a single version source for generated and duplicated public manifests. Prefer reading from `.claude-plugin/marketplace.json` or a small shared helper rather than hardcoding the value in multiple files.
2. Update `scripts/build-plugins/build.mjs` so the generated `dist/workflows/.codex-plugin/plugin.json` receives the current workflows plugin version from the shared source.
3. Update `plugins/standards/.codex-plugin/plugin.json` so its version matches the current standards plugin version declared by Claude-facing metadata.
4. Regenerate `dist/workflows/` with the argument-less `node scripts/build-plugins/build.mjs`.
5. Run `node scripts/build-plugins/verify.mjs` and confirm the generated manifest version now matches `.claude-plugin/marketplace.json` for `workflows`.
6. Grep manifests for stale `1.0.0` or older Workaholic plugin versions and confirm no public manifest drift remains.

## Considerations

- Do not hand-edit `dist/workflows/.codex-plugin/plugin.json` as the final fix; change the generator and regenerate the artifact (`scripts/build-plugins/build.mjs`).
- Keep the fix release-friendly. The release workflow currently extracts the version from `.claude-plugin/marketplace.json`; avoid introducing a second authoritative version file unless release handling is updated at the same time (`.github/workflows/release.yml`).
- `standards` is not generated through `scripts/build-plugins/build.mjs`, so it needs either a direct manifest update or a separate sync mechanism (`plugins/standards/.codex-plugin/plugin.json`).

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: `.claude/commands/release.md` is stale and predates the current three-plugin layout. It still references a `tdd` plugin that no longer exists and does not mention `standards`, `work`, the four `plugins[].version` entries inside `marketplace.json`, the standards `.codex-plugin/plugin.json`, or the `dist/workflows/` regenerate step.
  **Context**: A future release run via `/release` would silently miss most of the version files this ticket just synced, recreating the same drift. The corrected list now lives in CLAUDE.md, but `release.md` itself should be brought into alignment in a follow-up ticket — otherwise human-and-AI release runs will diverge from the documented bump procedure.
