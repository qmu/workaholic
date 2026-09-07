# build-plugins

Generates self-contained, cross-agent-portable copies of the workflow skills from
the DRY `plugins/workaholic` source.

## Why

Claude Code uses the `workaholic` skills directly and resolves `${CLAUDE_PLUGIN_ROOT}`
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
node --test scripts/tests/agentic-loop/packaging.test.mjs # isolated distribution regressions
node scripts/build-plugins/verify.mjs             # asserts every ref in outputs/<agent>/skills resolves
node scripts/build-plugins/validate-metadata.mjs  # asserts Codex marketplace + .codex-plugin manifests are well-formed and version-aligned with the Claude marketplace
```

Default targets: `create-ticket`, `drive`, `story`, `ship`, `catch`, `mission` (plus the prose `review-sections` and `write-release-note`). Only the **argument-less** full build writes `outputs/`; passing explicit targets builds into a temp scratch dir for inspection and does not touch the committed output.
Target-only scratch skills resolve their script and companion paths but retain source
namespace and mechanism wording. Full assembly additionally publicizes that prose.

Output: `outputs/workflows/` — a committed, self-contained plugin (`.codex-plugin/plugin.json` + `skills/`) consumed by Codex (`.agents/plugins/marketplace.json`) and the `skills` CLI (`.claude-plugin/marketplace.json`).

## What it rewrites

| Location | From | To |
| -------- | ---- | -- |
| `SKILL.md` | `${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/` | `<x>/scripts/` |
| `reference/**/*.md` | `${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/` | a path relative to that file (e.g. `../../<x>/scripts/`) |
| scripts | `${SCRIPT_DIR}/../../<x>/scripts/` | unchanged |

Each closure skill's whole `scripts/` dir is copied intact, so same-directory
sibling calls (e.g. `${SCRIPT_DIR}/list-todo.sh`) keep working. The build fails
loudly if any unresolved `${CLAUDE_PLUGIN_ROOT}/` path survives; bare variable reads remain allowed; `verify.mjs` additionally
checks that every emitted reference points at a real file.

The committed `outputs/workflows/` output is consumed by both the Codex manifest
(`.agents/plugins/marketplace.json`) and the `skills` CLI manifest
(`.claude-plugin/marketplace.json`), and is kept in sync with source by the
`Outputs Freshness` CI check (`.github/workflows/outputs-freshness.yml`). This tool only
handles **script** portability — agent-neutral orchestration prose and skill-preload
dependencies are separate concerns.

## Dependency and asset contract

Closure discovery recursively scans each skill's `scripts/` and `reference/` trees.
`skill-dependencies.json` is an object mapping skill names to arrays of additional
skill names. It starts empty: existing detected references remain authoritative,
and explicit entries only add dependencies that cannot be expressed by those
references. Build and verify use the union, follow transitive edges, tolerate
cycles, and reject missing source or target skills even in unrelated entries.
Do not copy every existing dependency into the catalog.

Nested helpers and schemas ship inside their owning `scripts/` directory.
Cross-skill shell references retain `${SCRIPT_DIR}/../../<x>/scripts/`.
Root wrappers resolve these paths and pass them into nested libraries; a library
must not calculate that two-level path from its own deeper directory.
Companion Markdown is rewritten and publicized recursively. Its executable
relative references and links back to `SKILL.md` are verified at their actual
depth; bare script names in prose are identifiers, not executable relative paths.

The full build deletes and regenerates its outputs to remove orphan assets.
The packaging tests execute source, generated workflows, and a standalone skill
with the source removed, then check orphan removal and deliberate reference
breakage. They use throwaway fixtures and reject service CLI calls. The full
`work` loop remains available through the source plugin, outside portable defaults.
