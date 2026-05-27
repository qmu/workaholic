---
created_at: 2026-05-27T14:21:31+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on: [20260527142130-relocate-cross-agent-output-into-dist.md]
---

# Add OpenCode as a generated target under `dist/opencode`

## Overview

OpenCode is the third supported coding agent (alongside Claude Code and Codex). With the `dist/` output root in place, add OpenCode as a second generated target so the same DRY `plugins/core` source produces an OpenCode-installable plugin at `dist/opencode/`, with its discovery manifest wired into the root marketplace.

## Key Files

- `tools/build-portable-skills/build.mjs` - extend the per-agent assembly to emit `dist/opencode/` in addition to `dist/codex/`
- `.agents/plugins/marketplace.json` - add (or confirm) the OpenCode plugin entry pointing at `./dist/opencode` if OpenCode consumes this manifest; otherwise add the manifest OpenCode expects
- `dist/opencode/` - new generated tree (output of this ticket)

## Implementation Steps

1. **Verify OpenCode's plugin/skill discovery format first** (do not assume). Determine: does OpenCode consume the `vercel-labs/skills` canonical `.agents/skills/` install path, the shared `.agents/plugins/marketplace.json`, or its own manifest (analogous to Codex's `.codex-plugin/plugin.json`)? Confirm how it expects bundled scripts to be referenced (relative-to-skill-root is the spec norm). Record the findings in this ticket's commit message or a short note.
2. Based on step 1, add an OpenCode target to `build.mjs` that reuses the existing closure/rewrite/`publicizeSkillMd` pipeline and writes the OpenCode-shaped plugin to `dist/opencode/`.
3. Wire OpenCode discovery: add the manifest/entry OpenCode requires (root-level pointer into `dist/opencode/`, mirroring how Codex points into `dist/codex/`).
4. Build and verify: `node tools/build-portable-skills/build.mjs` then `verify.mjs`; confirm the OpenCode tree is self-contained (no `${CLAUDE_PLUGIN_ROOT}`, no cross-skill path escapes).

## Considerations

- The same accepted trade-off applies: OpenCode skills are self-contained copies generated from `plugins/`; there is no cross-skill sharing in the spec (`tools/build-portable-skills/build.mjs`).
- If OpenCode uses the same `vercel-labs/skills` canonical-dir + symlink install model as the other 40+ agents, it may need no bespoke manifest beyond what the `skills` CLI already discovers from `.claude-plugin/marketplace.json` — verify before adding redundant manifests (avoid a third half-overlapping manifest).
- Known limitation carried from Codex: built skills retain Claude-namespaced `skills:` frontmatter preloads which non-Claude agents ignore; equivalent guidance is restated in skill bodies, so it degrades gracefully.
