---
created_at: 2026-05-27T14:21:30+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Infrastructure]
effort: 0.5h
commit_hash: 83ec9a0
category: Changed
depends_on:
---

# Relocate cross-agent generated output into a committed `dist/`

## Overview

Generated cross-agent artifacts are currently split awkwardly across the repo root: `dist/skills/` is **gitignored build scratch**, while `codex/workflows/` is a **separate committed tree** at the root. This is the disorganization that prompted the redesign.

Adopt the agreed topology: **`plugins/` is the single authored source of truth; `dist/` is the committed, generated per-agent output root.** This ticket relocates the Codex output to `dist/codex/`, makes `dist/` a tracked (committed) directory, retargets the build tool, and repoints the Codex marketplace manifest — all in one self-consistent move so the repo is never left in a broken intermediate state.

Source duplication across agents is accepted by design (the cross-agent skill spec has no inter-skill sharing mechanism — verified against the `vercel-labs/skills` standard); the build tool keeps `plugins/` DRY and materializes self-contained per-agent copies under `dist/`.

## Key Files

- `tools/build-portable-skills/build.mjs` - emitter; constants `DIST` (line 27, `dist/skills`) and `CODEX_PLUGIN` (line 29, `codex/workflows`) must change to the `dist/<agent>/` layout
- `tools/build-portable-skills/verify.mjs` - reference verifier; update to the new output paths
- `.gitignore` - remove the `dist/` ignore line so generated outputs are tracked
- `codex/workflows/` - existing committed tree; regenerated under `dist/codex/` then deleted
- `.agents/plugins/marketplace.json` - the `workflows` plugin `source.path` currently points at `./codex/workflows`; repoint to `./dist/codex`

## Implementation Steps

1. Decide the committed output layout: each `dist/<agent>/` is a complete, installable plugin (its manifest + `skills/`). Assemble each agent plugin directly from the cross-skill closure rather than committing an intermediate `dist/skills/` scratch tree — the intermediate can be built in a temp dir or in memory.
2. In `build.mjs`, replace the `DIST`/`CODEX_PLUGIN` constants with a `dist/codex/` destination (and a per-agent base path the OpenCode ticket can extend). Keep the closure-computation, reference-rewrite, and `publicizeSkillMd` logic untouched — only the destination changes.
3. Run the build, verify `dist/codex/` matches the old `codex/workflows/` byte-for-byte (sanity check that only the location moved), then delete the old `codex/` tree.
4. Remove `dist/` from `.gitignore` and `git add` the generated `dist/codex/` tree.
5. Repoint `.agents/plugins/marketplace.json` `workflows.source.path` from `./codex/workflows` to `./dist/codex`.
6. Run `node tools/build-portable-skills/verify.mjs` against the new layout; confirm no `${CLAUDE_PLUGIN_ROOT}` token survives in `dist/`.

## Considerations

- Channels that install by reading the repo (Codex via `.agents/plugins/marketplace.json`; the `skills` CLI via `npx skills add owner/repo`) need the artifacts **present in the tree at install time** — this is the concrete reason `dist/` must be committed, not gitignored (`.gitignore`).
- Claude Code reads `plugins/` directly and consumes nothing from `dist/`; do **not** place any Claude-Code artifact under `dist/` (`plugins/`, `.claude-plugin/marketplace.json`).
- Keep this ticket's commit self-consistent: the manifest repoint (step 5) and the `codex/` deletion (step 3) must land together, or `.agents/plugins/marketplace.json` will reference a missing path.
- The build still only handles **script** portability; agent-neutral prose and skill-preload degradation are unchanged (`tools/build-portable-skills/README.md`).

## Final Report

Development completed as planned. Verified `dist/codex/` is byte-for-byte identical to the removed `codex/workflows/` (`git diff --no-index` clean), and `verify.mjs` resolves all 45 script references across the six shipped skills.

### Discovered Insights

- **Insight**: The build now assembles the committed `dist/` plugins **only on a full default build** (`node build.mjs` with no args); passing explicit targets builds into the throwaway scratch dir and skips assembly.
  **Context**: The T3 CI freshness check must invoke the **argument-less** `node build.mjs` (then `git diff --exit-code dist/`) — a partial build would never touch `dist/` and the check would pass vacuously.
- **Insight**: `verify.mjs` now scans the shipped `dist/<agent>/skills/` rather than an intermediate, so it also covers the pure-prose extra skills (`review-sections`, `write-release-note`); they correctly report 0 references, confirming the relative-ref regex produces no false positives on prose.
  **Context**: When T2 adds `dist/opencode/`, verification picks it up automatically with no verifier change.
