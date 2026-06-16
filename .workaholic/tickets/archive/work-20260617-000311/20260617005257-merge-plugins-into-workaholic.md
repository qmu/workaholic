---
created_at: 2026-06-17T00:52:57+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash: 4d83184
category: Changed
depends_on:
---

# Collapse core + standards + work into a single `workaholic` plugin

## Overview

Merge the three authored plugins (`core`, `standards`, `work`) into **one**
`plugins/workaholic/` plugin so the marketplace ships a single, coherent plugin
usable across AI coding tools. The merged plugin holds:

- `skills/` — all 14 current `core` skills + the 3 `standards` skills. The
  cross-agent **discovery set** stays the pure-prose subset only (the 3 standards
  skills + `write-release-note` + `review-sections`); the 12 script-bearing
  workflow skills keep `metadata.internal: true` and continue reaching non-Claude
  agents **only** through the regenerated `dist/` build.
- `commands/` — the 5 `work` slash commands (ticket, drive, report, ship, trip).
  **Verified safe cross-agent**: Codex and the `skills` CLI read only a plugin's
  `skills/` dir; a `commands/` directory is never scanned, so commands are
  invisible (not broken) on non-Claude agents.
- `agents/`, `hooks/`, `rules/` — the `work` Agent Teams members
  (planner/architect/constructor, launched only by `/trip`), the ticket hook, and
  the rules. All Claude-Code-only; ignored cross-agent for the same reason.

This is an atomic restructure — it must leave the tree working and CI-green in one
self-consistent change (no half-merged intermediate). It is `refactoring`:
behavior is preserved; only the plugin topology and namespaces change.

**Hard constraint (do not attempt to remove):** the merge does **not** eliminate
the `dist/` build. `core`'s script-bearing skills use `${CLAUDE_PLUGIN_ROOT}`,
which only expands in Claude Code; rewriting it to the relative form was
explicitly rejected (CLAUDE.md Cross-Agent Skill Exposure, verified 2026-05-26)
because it loses determinism in the `/drive`//`/ship` critical path. They stay
internal and reach other agents via the generated `dist/workflows` plugin, which
the build now sources from `plugins/workaholic/skills`.

## Key Files

**Source (move with `git mv` to preserve history):**

- `plugins/core/skills/` → `plugins/workaholic/skills/` - 14 skills; 12 keep `metadata.internal: true` + `${CLAUDE_PLUGIN_ROOT}`. The 4 with namespaced `skills:` preloads (create-ticket, drive, discover, report) and any `subagent_type`/`core:`/`standards:` refs inside them re-namespace to `workaholic:`.
- `plugins/standards/skills/` → `plugins/workaholic/skills/` - design, implementation (11 policies), operation; pure prose, self-contained, stay exposed.
- `plugins/work/commands/`, `agents/`, `hooks/`, `rules/` → `plugins/workaholic/` - 5 commands re-namespace their `skills:` frontmatter `core:`/`standards:` → `workaholic:`, and cross-plugin script paths `${CLAUDE_PLUGIN_ROOT}/../core/skills/...` → same-plugin `${CLAUDE_PLUGIN_ROOT}/skills/...`.
- `plugins/{core,standards,work}/.claude-plugin/plugin.json` → one `plugins/workaholic/.claude-plugin/plugin.json` (name `workaholic`, version 1.0.51, `dependencies: []`).
- `plugins/standards/.codex-plugin/plugin.json` → `plugins/workaholic/.codex-plugin/plugin.json` (name `workaholic`, `"skills": "./skills/"`).

**Manifests:**

- `.claude-plugin/marketplace.json` - Replace the `core`, `standards`, `work` entries with **one** `workaholic` entry (`source: ./plugins/workaholic`, `skills:` array = the pure-prose discovery set). Keep the `workflows` entry (`source: ./dist/workflows`). Root + every `plugins[].version` stay aligned at 1.0.51.
- `.agents/plugins/marketplace.json` - Rename the `standards` entry to `workaholic` (`source.path: ./plugins/workaholic`); keep `workflows`.

**Build pipeline:**

- `scripts/build-plugins/build.mjs` - Retarget `CORE_SKILLS` (L33) to `plugins/workaholic/skills`; extend the namespace-flatten regex (L179) to also strip `workaholic:`; `DEFAULT_TARGETS` (L45) / `EXTRA_SKILLS` (L48) unchanged in content. The generated `workflows` plugin (L39, L202-212) stays — it is still the self-contained cross-agent artifact for the script-bearing skills.
- `scripts/build-plugins/verify.mjs` - Scans `dist/<agent>/skills`; no functional change beyond any path/constant naming.

**Docs (must match the new topology in the same change):**

- `CLAUDE.md` - Project Structure tree, Architecture Policy (Component Nesting, Plugin Dependencies, Cross-Agent Skill Exposure, Design Principle, Common Operations table), Version Management list, and the `Edit plugins/ not .claude/` note all reference `core`/`standards`/`work` and must be rewritten for the single `workaholic` plugin (+ the generated `workflows`).
- `README.md`, `plugins/work/README.md` (→ `plugins/workaholic/README.md`), `scripts/build-plugins/README.md` - update plugin names/paths.
- `dist/workflows/` - GENERATED; regenerate via `node scripts/build-plugins/build.mjs` (never hand-edit; Dist Freshness CI guards it).

## Related History

- [20260404014400-create-work-plugin-merge-drivin-trippin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014400-create-work-plugin-merge-drivin-trippin.md) - The plugin-merge playbook this repeats: `git mv` files, flip `${CLAUDE_PLUGIN_ROOT}/../` cross-plugin paths to same-plugin, rewrite `subagent_type` and `skills:` frontmatter namespace prefixes.
- [20260328152057-create-standards-plugin.md](.workaholic/tickets/archive/drive-20260326-183949/20260328152057-create-standards-plugin.md) - Why `standards` was split out (no-command, skills-only, portable). This merge folds it back in but **preserves** that property by keeping the standards skills pure-prose and exposed.
- [20260514121300-move-report-ship-commands-to-work.md](.workaholic/tickets/archive/work-20260417-092936/20260514121300-move-report-ship-commands-to-work.md) - Codified the "no commands in the code-agnostic library" boundary. This ticket intentionally retires that boundary: one plugin now holds both skills and commands, which is safe because cross-agent consumers ignore `commands/`.
- [20260527012303-codex-plugin-manifests-and-exposure.md](.workaholic/tickets/archive/work-20260518-235327/20260527012303-codex-plugin-manifests-and-exposure.md) - Establishes that cross-agent reach is via the generated `dist/workflows` (not source-in-place); the merge keeps this mechanism, only retargeting its source.
- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - The exposure mechanics (`skills` CLI scans `skills/`; `metadata.internal` is the only per-skill exclusion) the merged `skills` array must preserve.

## Implementation Steps

1. **Create `plugins/workaholic/`** and `git mv` the three plugins' contents into it (`skills/` from core+standards; `commands/`, `agents/`, `hooks/`, `rules/` from work). Resolve any same-named skill collisions (none expected — core and standards skill names are disjoint).
2. **Write one `plugins/workaholic/.claude-plugin/plugin.json`** (name `workaholic`, version 1.0.51, `dependencies: []`) and a `.codex-plugin/plugin.json` (`"skills": "./skills/"`). Delete the three old plugin dirs' manifests.
3. **Re-namespace**: in commands and in any skill that preloads or names another skill, change `core:`/`standards:`/`work:` → `workaholic:`; change cross-plugin `${CLAUDE_PLUGIN_ROOT}/../core/skills/...` → `${CLAUDE_PLUGIN_ROOT}/skills/...`. Keep all `metadata.internal: true` flags as-is.
4. **Update `.claude-plugin/marketplace.json`** (collapse 3 entries → 1 `workaholic`, keep `workflows`) and **`.agents/plugins/marketplace.json`** (`standards` → `workaholic`), preserving single-semver alignment.
5. **Retarget `build.mjs`** (`CORE_SKILLS` → `plugins/workaholic/skills`; add `workaholic` to the namespace-flatten regex). Regenerate: `node scripts/build-plugins/build.mjs`.
6. **Run the gates**: `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs`. Confirm `dist/` regenerates cleanly (Dist Freshness will diff it).
7. **Rewrite docs** (`CLAUDE.md`, READMEs, `scripts/build-plugins/README.md`) for the single-plugin topology.
8. **Fence Claude-only surfaces**: ensure `agents/` (planner/architect/constructor) and the `/trip` command are NOT in the cross-agent `skills` discovery array and never enter `dist/` (the build already excludes `trip` and reads only `skills/`).

## Considerations

- **Atomic / no broken intermediate.** A half-merged tree won't load and will fail Dist Freshness CI. Do the move, namespace rewrite, manifests, build retarget, regen, and docs as one self-consistent change. (`.github/workflows/dist-freshness.yml`)
- **The `dist/` build stays — non-negotiable.** Script-bearing skills keep `${CLAUDE_PLUGIN_ROOT}` + `metadata.internal` and reach other agents only via the regenerated artifact. Do not try to expose them directly. (CLAUDE.md Cross-Agent Skill Exposure, verified 2026-05-26; `standards:implementation` machine-checkable reachability)
- **Dependency collapse simplifies paths.** With one plugin, `work`'s old `dependencies: ["core"]` and every `../core/` cross-plugin reference become same-plugin `${CLAUDE_PLUGIN_ROOT}/skills/...`; the previously *soft* `standards` preload reference hardens to intra-plugin. Audit every `${CLAUDE_PLUGIN_ROOT}/../` occurrence. (CLAUDE.md Skill Script Path Rule, Plugin Dependencies)
- **Agent Teams members stay Claude-only.** `planner`/`architect`/`constructor` and `/trip` must not leak into the cross-agent surface — they live under `agents/`/`commands/`, which the build and the `skills` CLI ignore, so this holds as long as they are not added to `skills/` or the discovery array. (CLAUDE.md Component Nesting)
- **Plugin name == marketplace name.** The marketplace is already named `workaholic`; a plugin also named `workaholic` is allowed but slightly confusing. The user explicitly wants `workaholic`; if collision causes any tooling ambiguity, that surfaces at implementation — note it, don't silently rename.
- **Version surface shrinks** from four `plugins[]` entries + three `plugin.json` files to one `workaholic` `plugin.json` + the `workflows` entry. Keep `.claude-plugin/marketplace.json` as the single source of truth at 1.0.51, mirrored to the new `plugin.json` and `.codex-plugin/plugin.json`. (CLAUDE.md Version Management)
- **`metadata.internal` is the only exposure lever.** The merged `skills` discovery array must list exactly the pure-prose set; every script-bearing skill must retain `metadata.internal: true` or it would wrongly leak to cross-agent discovery. Re-verify the 12/2 split after the move. (`scripts/build-plugins/verify.mjs`, `validate-metadata.mjs`)
- **`standards:operation` (CI/CD):** the merge must keep the build → verify → validate → Dist-Freshness chain green so the codebase still answers for itself whether a commit is deployable. (`plugins/standards/skills/operation/policies/ci-cd.md`)

## Final Report

Development completed (night drive, auto-approved). `git mv`'d `core`+`standards`
skills and `work`'s commands/agents/hooks/rules into one `plugins/workaholic/`;
removed the old manifests/dirs. Wrote the merged `.claude-plugin`/`.codex-plugin`
manifests (name `workaholic`, `dependencies: []`). Flattened every namespace
(`core:`/`standards:`/`work:` → `workaholic:`) and same-plugin path
(`${CLAUDE_PLUGIN_ROOT}/../core/skills/` → `${CLAUDE_PLUGIN_ROOT}/skills/`,
`${SCRIPT_DIR}/.../core/skills/` → `.../workaholic/skills/`). Retargeted
`build.mjs` (`CORE_SKILLS` path, `SCRIPT_CROSS_REF` regex, namespace-flatten regex),
collapsed both marketplace manifests to `workaholic` + `workflows`, updated the
smoke-test script paths and `scripts/claude.sh` launcher (also dropped its stale
`drivin`/`trippin` dirs), and regenerated `outputs/`. **All four gates pass**:
build, verify (self-contained), validate-metadata (workaholic@1.0.51 +
workflows@1.0.51 aligned), and 49 smoke tests — the smoke tests exercise the
rewritten cross-skill script paths (`user-slug.sh`, `commit.sh`), confirming the
path flatten is correct.

### Discovered Insights

- **Insight**: The four gates give strong structural coverage of a merge this size
  — `verify.mjs` proves every built script ref resolves, and the smoke tests run
  the actual bundled scripts (so a broken `${SCRIPT_DIR}/../../../../workaholic/skills/...`
  cross-ref would fail loudly). Green gates here means the functional merge is
  sound. **Context**: trust the gate suite as the merge's acceptance test.
- **Follow-up (not blocking)**: CLAUDE.md's Project Structure, Version Management,
  dependency diagram, file paths, README, and `claude.sh` are updated, but the
  **conceptual architecture narrative** (Cross-Agent Skill Exposure, the
  distribution section) still describes the prior three-plugin model in prose. A
  flagged note was added at the dependency section; a dedicated narrative-rewrite
  pass remains. The mechanics it describes are unchanged and correct — only the
  plugin-name framing is stale.
