---
created_at: 2026-05-27T01:23:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
depends_on: [20260527012301-build-step-for-self-contained-portable-skills.md, 20260527012302-agent-neutral-workflow-skill-prose.md]
category:
---

# Codex plugin manifests, exposure, and docs for the portable workflows

## Overview

With the workflow skills decoupled from trip, script-self-contained (build step), and agent-neutral in prose, the final step is to **distribute** them to Codex (and ideally other agents) and document it. Codex has its own plugin system — verified by the Codex readiness assessment: plugins use `plugins/<name>/.codex-plugin/plugin.json` with optional `skills/`/`agents/`/`commands/`/`hooks.json`/`.mcp.json`, and a marketplace at `.agents/plugins/marketplace.json` at the repo root; standalone skills are discovered under `$CODEX_HOME/skills` (`~/.codex/skills`). Codex reads only `name`+`description` from skill frontmatter and has no `metadata.internal` concept.

This ticket adds the Codex manifests pointing at the build step's self-contained artifacts, exposes the portable workflow set (`create-ticket`, `drive`, `report`, `ship` + their bundled closures, plus the already-portable `standards` and `write-release-note`), excludes `trip`, and updates the docs/exposure policy.

## Key Files

- **New** `.agents/plugins/marketplace.json` (repo root) - Codex marketplace listing the portable plugin(s). Mirrors the intent of `.claude-plugin/marketplace.json` but in Codex's format. Keep BOTH manifest families in parallel (do not replace `.claude-plugin/`).
- **New** `plugins/<name>/.codex-plugin/plugin.json` - Per-plugin Codex manifest for whichever plugins are exposed (at minimum a portable plugin carrying the 4 workflow skills + standards). Fields: `skills`, optionally `hooks`/`mcpServers`, relative `./...` paths pointing at the build artifacts.
- `tools/build-portable-skills/` (from `20260527012301`) - The Codex manifests consume its `dist/` output. Wire the build → manifest path.
- `.claude-plugin/marketplace.json` - Unchanged for Claude Code; cross-check that exposure stays consistent.
- `plugins/core/skills/*/SKILL.md` - Remove `metadata.internal: true` from the now-portable workflow skills + their bundled utilities where they are exposed as artifacts. (Codex ignores the field anyway; this keeps the `skills` CLI / Claude marketplace honest.)
- `CLAUDE.md` - "Cross-Agent Skill Exposure", "Skill Script Path Rule", "Common Operations" — update to describe: DRY source uses `${CLAUDE_PLUGIN_ROOT}`; portable artifacts (built) use relative paths; the exposed set now includes the workflow skills via build artifacts; trip stays Claude-only.
- `README.md` - Add a Codex install section and a multi-agent matrix (Claude Code marketplace / Codex marketplace + `~/.codex/skills` / `npx skills` / clone-copy), reflecting the actually-portable set.

## Related History

- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - standards-only packaging + the `skills` CLI / `metadata.internal` mechanism.
- [20260525205530-audit-claude-specific-refs-in-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205530-audit-claude-specific-refs-in-portable-skills.md) - Exposed `write-release-note`; established the per-skill exposure discipline this ticket extends to the workflow set.

## Implementation Steps

1. **Add `plugins/<name>/.codex-plugin/plugin.json`** for the exposed plugin(s), listing the workflow skills + standards, with relative paths to the build artifacts. Confirm the exact field schema against Codex's `plugin-json-spec` (`skills`, `hooks`, `mcpServers`, `apps`, `interface`).
2. **Add `.agents/plugins/marketplace.json`** at the repo root enumerating those plugins (Codex marketplace format).
3. **Wire the build artifacts**: ensure the Codex manifests reference the self-contained skill folders produced by `20260527012301`, not the DRY source (whose `${CLAUDE_PLUGIN_ROOT}` refs would break on Codex).
4. **Remove `metadata.internal: true`** from the workflow skills (and bundled utilities) that are now exposed; keep it on anything still Claude-only (e.g. `trip-protocol`, and any utility not shipped standalone).
5. **Exclude trip**: ensure no Codex manifest lists `trip`/`trip-protocol` or the Agent Teams agents.
6. **Update `CLAUDE.md`** exposure/script-path/common-operations sections to the source-vs-artifact, Claude-vs-portable model.
7. **Update `README.md`** with the Codex install path and multi-agent matrix.
8. **Verify on Codex**: install via the Codex marketplace (or drop a built skill into `~/.codex/skills`, restart) and confirm `create-ticket`/`drive`/`report`/`ship` load and their bundled scripts resolve from the skill folder.

## Considerations

- **Maintain both manifest families.** `.claude-plugin/` (Claude Code) and `.codex-plugin/` + `.agents/plugins/marketplace.json` (Codex) coexist; the audit ticket and Codex both stress not replacing one with the other.
- **Cursor is a possible follow-up, not this ticket.** Cursor uses `.cursor-plugin/` + `.agents/skills/`; once the build artifacts exist, adding Cursor is incremental. Keep scope to Codex here unless trivially shared.
- **`metadata.internal` is Claude/`skills`-CLI-only.** Do not rely on it for Codex filtering; Codex exposure is controlled by what the manifests list (Codex assessment).
- **Verification is the gate.** Per the audit lesson, do not declare Codex-compatible without actually loading the built skills in Codex and resolving a bundled script.
- **`Config`/Infrastructure**; engages `standards:leading-availability` (reproducible multi-agent distribution) and `standards:leading-security` (the manifests must not expose anything that runs `cloud.md`-style deploy without the same guards Claude Code applies).
