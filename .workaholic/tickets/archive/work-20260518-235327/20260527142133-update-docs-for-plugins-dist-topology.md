---
created_at: 2026-05-27T14:21:33+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.5h
commit_hash: 944be19
category: Changed
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

## Final Report

Development completed as planned. Updated `CLAUDE.md` (distribution section + structure tree), `README.md` (install matrix + reach-other-agents section), and `tools/build-portable-skills/README.md` (usage/output/closing). Confirmed no `codex/workflows` or `dist/skills` references remain and that every documented command runs.

### Discovered Insights

- **Insight**: The CLAUDE.md "Known limitation: built skills retain Claude-namespaced `skills:` preloads" note was already stale before this work — `publicizeSkillMd` strips the `skills:` block, `metadata.internal`, and `user-invocable`, and flattens namespace prefixes. Removed the note rather than preserving a false caveat.
  **Context**: Docs describing generated output drift silently when the generator changes; the new `Dist Freshness` CI check guards the artifacts but not their prose description, so doc claims about the build still need manual review when `build.mjs` changes.
- **Insight**: `npx skills add . --list` reported exactly 10 skills (4 Standards + 6 Workflows) with no `core` group, i.e. the script-bearing `core` skills are not surfaced cross-agent. The documented `metadata.internal` rationale for keeping them hidden is therefore belt-and-suspenders relative to the observed behavior; left the existing (verified 2026-05-26) rationale intact rather than overturning it without dedicated verification.
  **Context**: A future ticket could confirm the precise `skills` CLI scan rule (every plugin's `skills/` vs only entries with a `skills` array) and tighten the exposure docs accordingly.
