---
created_at: 2026-05-27T01:23:01+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash: d370d93
depends_on: [20260527012300-decouple-core-ship-from-trip.md]
category: Added
---

# Build step: generate self-contained skill artifacts from DRY core source

## Overview

To run the workflow skills (`create-ticket`, `drive`, `report`, `ship`) on Codex and other agents, each must be a **self-contained** skill folder: its `SKILL.md` may only reference files inside its own directory (Agent Skills spec: "relative paths from the skill root, one level deep"). workaholic instead shares scripts across skills — measured **81** `${CLAUDE_PLUGIN_ROOT}` references, of which ~24 are cross-skill jumps into another skill's `scripts/` (e.g. `drive` → `branching`/`check-deps`/`commit`; `report`/`ship`/`create-ticket` → `branching`, fan-in 5). `${CLAUDE_PLUGIN_ROOT}` is a Claude-Code plugin token no other agent expands.

The chosen resolution (developer decision) is a **build step**, not per-skill duplication: keep the source DRY (shared `core` scripts as today, used directly by Claude Code), and **generate** self-contained skill folders for cross-agent distribution — inlining each cross-skill script into the consuming skill and rewriting `${CLAUDE_PLUGIN_ROOT}/.../scripts/X.sh` to a spec-relative `scripts/X.sh`. This avoids forking `branching` into 3+ hand-maintained copies (drift), which the audit/reorg work flagged as the core risk.

## Key Files

- `plugins/core/skills/*/SKILL.md` + their `scripts/` - The DRY source. Inputs to the build. Unchanged for Claude Code use.
- **New** `tools/build-portable-skills/` (or `scripts/`) - The packaging tool (Node or POSIX shell). Reads the dependency closure of each target workflow skill, copies the closure's scripts into a generated self-contained folder, and rewrites script references to relative paths. Emits to a `dist/`-style output consumed by the cross-agent manifests (next tickets).
- `plugins/core/skills/drive/scripts/archive.sh` - Contains the one script-to-script cross reference (`../../../../core/skills/commit/scripts/commit.sh`, line ~58). The build must inline `commit.sh` (or its needed entry) into the generated `drive` artifact. (Note: ticket 20260527012300 already moves ship's worktree helpers to the trip side, so they are out of the portable closure.)
- `CLAUDE.md` - "Skill Script Path Rule" mandates `${CLAUDE_PLUGIN_ROOT}` for skill scripts. Source keeps using it; the build output uses relative paths. Document this source-vs-artifact distinction (also touched in the manifest ticket).

## Dependency closures to bundle (from measured data)

- `create-ticket` → `gather`, `branching`
- `drive` → `branching`, `check-deps`, `commit`
- `report` → `branching`, `review-sections` (+ `write-release-note`, already self-contained)
- `ship` (post-decouple) → `branching` (+ `cloud.md` is user-provided, not bundled)

## Related History

- [20260527000801-reorganize-skill-dependencies-for-self-containment.md](.workaholic/tickets/archive/work-20260518-235327/20260527000801-reorganize-skill-dependencies-for-self-containment.md) - Reorg design. Its "build/packaging step" option (kept-DRY source + inlined artifacts) is the approach this ticket implements; note this **supersedes** that ticket's recommendation (B) of keeping `branching` shared/Claude-only, because the portability goal now requires `branching` to ride along with each workflow skill.
- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - The `skills` CLI behavior and `metadata.internal` mechanism the generated artifacts must play nicely with.

## Implementation Steps

1. **Define the build tool** under `tools/` (or a `core` skill's `scripts/`). Given a target skill name, compute its cross-skill/script dependency closure, materialize a self-contained folder (`SKILL.md` + a flat `scripts/` containing every needed script), and rewrite all `${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/Y` and intra-script `../core/.../Y` references to local `scripts/Y`.
2. **Handle name collisions** when two source skills contribute a script of the same basename into one artifact (namespace by source skill, e.g. `scripts/branching__check.sh`, and rewrite references accordingly).
3. **Emit artifacts** to a deterministic output dir (e.g. `dist/skills/<name>/`) suitable for the cross-agent manifests. Decide whether artifacts are committed or generated on demand (recommend: generated + git-ignored, regenerated in CI/release).
4. **Verify byte-for-byte logic parity**: a generated artifact's script run from its own folder must produce the same result as the DRY source run under Claude Code. Add a smoke test that runs each generated skill's primary script.
5. **Keep Claude Code on the DRY source** — the build output is for other agents only; nothing about Claude Code's plugin loading changes.

## Considerations

- **Drift is the whole reason for the build step.** Do NOT hand-copy shared scripts into skills; the generator is the single source of truth so `branching` stays one canonical file.
- **`cloud.md` is user-provided** and not part of any skill folder; ship's deploy step references the user's repo `cloud.md`, which is correct on any agent — do not try to bundle it.
- **Agent-neutral prose is a separate concern** (next ticket). This ticket only fixes script *resolution*; it does not rewrite orchestration language (AskUserQuestion / subagent fan-out).
- **review-sections currently lacks frontmatter** (Codex requires `name`+`description`); that fix lives in the prose ticket but the build must not choke on it — sequence accordingly.
- **`Config`/tooling change**; engages `standards:leading-availability` (build/release reproducibility) and `standards:leading-validity` (the closure computation should be explicit and total — every reference resolved or the build fails loudly).

## Final Report

Development completed. Added `tools/build-portable-skills/` with `build.mjs` (generator), `verify.mjs` (self-containment assertion), and a `README.md`. `dist/` is git-ignored. Verified: the 4 targets build with correct closures (create-ticket=[branching,gather], drive=[branching,check-deps,commit], report=[branching], ship=[branching]); 43 emitted script references resolve; zero `${CLAUDE_PLUGIN_ROOT}` tokens survive. Claude Code keeps using the DRY source unchanged.

### Deviations from the ticket

- **Layout: per-skill subdirectory, not flattened+namespaced.** Step 2 anticipated basename collisions (e.g. `branching/check.sh` vs `check-deps/check.sh`, both in drive's closure) and suggested namespacing as `scripts/branching__check.sh`. Instead the generator copies each closure skill's whole `scripts/` into its own subdir (`dist/skills/<target>/<x>/scripts/<f>`). This sidesteps collisions structurally AND preserves intra-skill same-dir sibling calls (`${SCRIPT_DIR}/update.sh`, `${SCRIPT_DIR}/strip-frontmatter.sh`) without rewriting them — cleaner than namespacing. SKILL.md refs become `<x>/scripts/<f>` (skill-root-relative, spec-compliant).
- **Parity verified statically, not by execution.** Step 4 suggested running each generated skill's primary script. Most are destructive (`archive.sh` commits, `merge-pr.sh` merges), so executing them in a smoke test is unsafe. Instead: scripts are copied byte-for-byte (only path *references* are rewritten), so logic parity is guaranteed by construction; `verify.mjs` confirms every rewritten reference resolves to a real file from the script's own location.
- **review-sections is not in any script closure** — it is pure prose with no scripts, referenced by `report` as a skill preload, not a script. So the build neither chokes on its missing frontmatter nor needs it; that fix stays in the prose ticket (T3) and the manifest ticket ships it as its own skill.

### Discovered Insights

- **Insight**: workaholic's cross-skill coupling is almost entirely declarative SKILL.md references (`${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/`), not script-to-script calls. The only script-internal cross-skill call in all of `core` is `archive.sh` → `commit.sh`; everything else a script invokes is a same-directory sibling. This is why a simple two-rule rewrite (one for SKILL.md, one for the `${SCRIPT_DIR}/../core/...` climb) fully self-contains the workflow skills.
  **Context**: Future scripts should keep this property — invoke siblings via `${SCRIPT_DIR}/name.sh` and cross-skill helpers only via the documented `${CLAUDE_PLUGIN_ROOT}` form — so the generator's two rules remain sufficient.
