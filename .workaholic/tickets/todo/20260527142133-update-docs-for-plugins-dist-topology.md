---
created_at: 2026-05-27T14:21:33+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260527142130-relocate-cross-agent-output-into-dist.md, 20260527142131-add-opencode-generated-target.md, 20260527142132-add-dist-freshness-ci-check.md]
---

# Update documentation for the `plugins/` (source) + `dist/` (generated) topology

## Overview

Realign all prose with the new structure so the next contributor (and the next agent integration) sees one coherent model: **`plugins/` is authored source; `dist/<agent>/` is committed, generated, CI-guarded output; per-agent marketplace manifests stay at the repo root as thin pointers.** Several docs currently describe the old `codex/` + gitignored-`dist/` arrangement and have already started to drift.

## Key Files

- `CLAUDE.md` - the "Codex distribution" / "Cross-Agent Skill Exposure" sections name `codex/` as the shipped distribution and `dist/` as gitignored scratch (both now wrong); the "source-vs-artifact rule" and regenerate instructions point at `codex/`
- `tools/build-portable-skills/README.md` - already stale: says output goes to gitignored `dist/skills/` and that the Codex manifest consumes `dist/skills/`; must describe `dist/<agent>/` committed outputs and the CI freshness check
- `README.md` - repo-level structure/overview references to the plugin layout
- `.claude/rules/` and `plugins/work/rules/` - check for any path references to `codex/` or the old layout

## Implementation Steps

1. Rewrite the CLAUDE.md cross-agent sections to the final model: `plugins/` source → build → committed `dist/codex/`, `dist/opencode/`; root manifests (`.claude-plugin/marketplace.json` → `plugins/`, `.agents/plugins/marketplace.json` → `dist/*`) are thin pointers; Claude consumes `plugins/` directly.
2. Replace every `codex/workflows/` path reference with `dist/codex/`; remove the "`dist/` is gitignored dev scratch; `codex/` ships" framing.
3. Update `tools/build-portable-skills/README.md` to match `build.mjs`: committed `dist/<agent>/` targets, OpenCode included, and the now-existing CI freshness check (remove the "sensible follow-up" caveat).
4. Update `README.md` structure section and any rule files that mention the old paths.
5. Grep the repo for stale `codex/` references and reconcile them.

## Considerations

- This ticket depends on the prior three so the docs describe the end state (Codex relocated, OpenCode added, CI check live), not an intermediate one.
- Keep the documented "why script-bearing skills stay internal / `${CLAUDE_PLUGIN_ROOT}` determinism" rationale — it is still valid and explains why `plugins/` source keeps the token while `dist/` rewrites it (`CLAUDE.md`).
- Verify documented commands actually run (`node tools/build-portable-skills/build.mjs`, the `npx skills add . --list` preview) rather than copying old invocations.
