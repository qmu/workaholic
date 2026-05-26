---
created_at: 2026-05-27T01:23:01+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
depends_on: [20260527012300-decouple-core-ship-from-trip.md]
category:
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
