# build-plugins

Generates self-contained, cross-agent-portable copies of the workflow skills from
the DRY `plugins/workaholic` source.

## Why

Claude Code uses the `core` skills directly and resolves `${CLAUDE_PLUGIN_ROOT}`
to the installed plugin dir, so skills can share scripts across the plugin. Other
agents (Codex, Cursor, OpenCode, Pi) do not expand that token and install each
skill as an **isolated folder** — so a skill that references another skill's
`scripts/` breaks there.

This tool keeps the source DRY (one canonical `branching`, `commit`, etc.) and
**generates** self-contained skill folders for distribution: each target skill's
`SKILL.md` plus the full `scripts/` of every skill in its cross-skill dependency
closure, with all references rewritten to skill-root-relative paths.

## Usage

```bash
node scripts/build-plugins/build.mjs              # full build: assembles the committed outputs/workflows plugin
node scripts/build-plugins/build.mjs drive ship   # dev only: builds named skills into a throwaway scratch dir
node scripts/build-plugins/verify.mjs             # asserts every ref in outputs/<agent>/skills resolves
node scripts/build-plugins/validate-metadata.mjs  # asserts Codex marketplace + .codex-plugin manifests are well-formed and version-aligned with the Claude marketplace
```

Default targets: `create-ticket`, `drive`, `report`, `ship` (plus the prose `review-sections` and `write-release-note`). Only the **argument-less** full build writes `outputs/`; passing explicit targets builds into a temp scratch dir for inspection and does not touch the committed output.
Output: `outputs/workflows/` — a committed, self-contained plugin (`.codex-plugin/plugin.json` + `skills/`) consumed by Codex (`.agents/plugins/marketplace.json`) and the `skills` CLI (`.claude-plugin/marketplace.json`).

## What it rewrites

| Location | From | To |
| -------- | ---- | -- |
| `SKILL.md` | `${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/` | `<x>/scripts/` |
| scripts | `${SCRIPT_DIR}/(../)+core/skills/<x>/scripts/` | `${SCRIPT_DIR}/../../<x>/scripts/` |

Each closure skill's whole `scripts/` dir is copied intact, so same-directory
sibling calls (e.g. `${SCRIPT_DIR}/update.sh`) keep working. The build fails
loudly if any `${CLAUDE_PLUGIN_ROOT}` token survives; `verify.mjs` additionally
checks that every emitted reference points at a real file.

The committed `outputs/workflows/` output is consumed by both the Codex manifest
(`.agents/plugins/marketplace.json`) and the `skills` CLI manifest
(`.claude-plugin/marketplace.json`), and is kept in sync with source by the
`Outputs Freshness` CI check (`.github/workflows/outputs-freshness.yml`). This tool only
handles **script** portability — agent-neutral orchestration prose and skill-preload
dependencies are separate concerns.
