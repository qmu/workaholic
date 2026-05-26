# build-portable-skills

Generates self-contained, cross-agent-portable copies of the workflow skills from
the DRY `plugins/core` source.

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
node tools/build-portable-skills/build.mjs            # builds the default targets
node tools/build-portable-skills/build.mjs drive ship # builds specific targets
node tools/build-portable-skills/verify.mjs           # asserts every ref resolves
```

Default targets: `create-ticket`, `drive`, `report`, `ship`.
Output: `dist/skills/<target>/` (git-ignored; regenerate on demand / in CI).

## What it rewrites

| Location | From | To |
| -------- | ---- | -- |
| `SKILL.md` | `${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/` | `<x>/scripts/` |
| scripts | `${SCRIPT_DIR}/(../)+core/skills/<x>/scripts/` | `${SCRIPT_DIR}/../../<x>/scripts/` |

Each closure skill's whole `scripts/` dir is copied intact, so same-directory
sibling calls (e.g. `${SCRIPT_DIR}/update.sh`) keep working. The build fails
loudly if any `${CLAUDE_PLUGIN_ROOT}` token survives; `verify.mjs` additionally
checks that every emitted reference points at a real file.

The Codex / cross-agent manifests consume `dist/skills/` (see the Codex
manifest ticket). This tool only handles **script** portability — agent-neutral
orchestration prose and skill-preload dependencies are separate concerns.
