---
created_at: 2026-05-28T09:12:59+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 0.5h
commit_hash: 65d9734
category: Changed
depends_on:
---

# Read /ship Deploy/Verify from CLAUDE.md instead of cloud.md

## Overview

`/ship` currently reads its `## Deploy` and `## Verify` instructions from a dedicated, user-authored `cloud.md` file. Replace that convention outright: the ship workflow reads those sections from the project's `CLAUDE.md`, and `cloud.md` is removed entirely. This is a hard cutover — no `cloud.md` fallback, no backward compatibility. The finder script is renamed `find-cloud-md.sh` → `find-claude-md.sh`, the "Cloud.md Convention" prose is reworked, the user-facing docs are updated, and the committed `dist/workflows` artifacts are regenerated so the convention is consistent across Claude Code and the cross-agent distribution.

The convention is owned entirely by `core:ship`; the `/ship` command in `plugins/work` delegates and contains no `cloud.md` text, so no command change is needed.

## Key Files

- `plugins/core/skills/ship/scripts/find-cloud-md.sh` — Resolves the deploy-doc path. Today it loops over `./cloud.md` then `./.workaholic/cloud.md` and returns `{found, path}` (it does NOT parse sections — that is model-side). **Rename to `find-claude-md.sh`** and make it resolve `./CLAUDE.md` only.
- `plugins/core/skills/ship/SKILL.md` — Authoritative ship knowledge. Edit: frontmatter `description` (line 3, "deploy via cloud.md"), §1 "Cloud.md Convention" heading + 1-1 Search Order, 1-4 Fallback message, §2-3 script reference (rename to `find-claude-md.sh`), and §5 Ship Flow steps 4 (Deploy) and 5 (Verify) which name `cloud.md`. Every `cloud.md` mention must be gone.
- `plugins/core/README.md` — Skills table row for `ship` ("cloud.md deploy"). Reword to `CLAUDE.md`.
- `README.md` (repo root) — Line ~108 describes `/ship` deploying "following your project's cloud.md instructions". Reword to `CLAUDE.md`.
- `scripts/build-plugins/build.mjs` — Build pipeline; `DEFAULT_TARGETS` already includes `ship`. No edit needed — the closure is computed automatically and picks up the renamed script. The regeneration mechanism.
- `dist/workflows/skills/ship/SKILL.md` and `dist/workflows/skills/ship/ship/scripts/find-cloud-md.sh` — GENERATED, committed copies (the script copy will be renamed by the rebuild). Do NOT hand-edit; regenerate via the argument-less build and commit the diff.
- `.github/workflows/dist-freshness.yml` — CI guard that fails on any `dist/` diff after a fresh build. The change is only complete once committed `dist/` matches a fresh build.

## Related History

The `cloud.md` convention is well-traveled but has never been redesigned: it was defined once and carried verbatim through five relocations, a confirmation gate, the thin-command refactor, and the recent trip decoupling. No prior ticket proposed sourcing deploy/verify from `CLAUDE.md`, so this is a novel change to an established contract — and a deliberate removal of the original `cloud.md` design.

Past tickets that touched this area:

- [20260311105613-add-ship-drive-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105613-add-ship-drive-command.md) — Origin of the entire `cloud.md` convention: the `## Deploy`/`## Verify` sections, the `./cloud.md` + `./.workaholic/cloud.md` search order, the skip-if-missing fallback, and the original `find-cloud-md.sh`. This is the spec being removed.
- [20260527012300-decouple-core-ship-from-trip.md](.workaholic/tickets/archive/work-20260518-235327/20260527012300-decouple-core-ship-from-trip.md) — Established `core:ship` as the trip-independent, cross-agent merge→deploy(cloud.md)→verify essence. Confirms the deploy step is the cross-agent-portable path and the artifact must stay agent-neutral.
- [20260514154749-thin-ship-and-discover-umbrellas.md](.workaholic/tickets/archive/work-20260417-092936/20260514154749-thin-ship-and-discover-umbrellas.md) — Defines the current `SKILL.md` section structure (§1 Cloud.md Convention, §2 Shell Scripts, §5 Ship Flow) that the prose edits must target.
- [20260329213021-move-ship-scripts-from-trippin-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260329213021-move-ship-scripts-from-trippin-to-core.md) — Established the current home of `find-cloud-md.sh` and its same-plugin `${CLAUDE_PLUGIN_ROOT}/skills/ship/` reference form; confirms renaming/retargeting the finder is a localized edit.
- [20260311121500-add-deployment-confirmation-to-ship-commands.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121500-add-deployment-confirmation-to-ship-commands.md) — Added the AskUserQuestion confirm-before-deploy gate. This behavior MUST be preserved when the Deploy section is sourced from `CLAUDE.md`.

## Implementation Steps

1. **Rename and rewrite the finder script.** Rename `plugins/core/skills/ship/scripts/find-cloud-md.sh` → `find-claude-md.sh`. Make it resolve `./CLAUDE.md` only and return `{found, path}` (keep the candidate-list loop structure even with a single entry, so the no-inline-shell rule is honored and adding locations later stays trivial). No `cloud.md` / `.workaholic/cloud.md` candidates remain.
2. **Update the script reference in SKILL.md.** Change the `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh` references in §2-3 and §5 step 4 to `find-claude-md.sh`.
3. **Rework SKILL.md prose.** Rename §1 heading "Cloud.md Convention" → "CLAUDE.md Convention", update §1-1 Search Order (just `./CLAUDE.md`), the §1-4 Fallback message ("No `## Deploy` section found in CLAUDE.md. Deployment skipped."), the frontmatter `description` (drop "via cloud.md"), and §5 steps 4–5 so they reference `CLAUDE.md` and its `## Deploy`/`## Verify` sections. Preserve the confirm-before-deploy gate verbatim. No `cloud.md` string may remain in the file.
4. **Adjust the "not found" semantics.** Because `CLAUDE.md` almost always exists (unlike a bespoke `cloud.md`), "skip deploy" must trigger when `CLAUDE.md` is present but has no `## Deploy`/`## Verify` sections — not only when the file is absent. Document this in §1-4 so the model checks for the sections after the script resolves the path (section detection stays model-side, consistent with today's design).
5. **Update documentation.** Reword the `ship` row in `plugins/core/README.md` and the `/ship` description in the root `README.md` to name `CLAUDE.md`. Sweep the repo for any remaining `cloud.md` mentions in `plugins/` source and remove them.
6. **Regenerate dist/.** Run the argument-less `node scripts/build-plugins/build.mjs` to regenerate `dist/workflows/skills/ship/**` (the old `dist/.../find-cloud-md.sh` should disappear and `find-claude-md.sh` appear). Do NOT hand-edit the artifacts. Commit the `dist/` diff in the same change.
7. **Verify freshness.** Confirm `git diff -- dist/` is empty after a fresh build (what `dist-freshness.yml` checks in CI), that no stale `find-cloud-md.sh` remains under `dist/`, and that `verify.mjs` still passes (no leftover `${CLAUDE_PLUGIN_ROOT}` in the generated skill).

## Considerations

- **Source-vs-artifact rule.** Never hand-edit `dist/`; edit `plugins/core` then regenerate. A file rename in source must be reflected by a rebuild (the old generated script must be removed, not left orphaned). The change is incomplete (and CI-failing) until committed `dist/workflows/skills/ship/**` matches a fresh build (`.github/workflows/dist-freshness.yml`).
- **No inline shell.** Keep all path-resolution logic inside the renamed bundled script; do not inline conditionals/loops into `SKILL.md` (CLAUDE.md Shell Script Principle). Keep the `${CLAUDE_PLUGIN_ROOT}` token in source references.
- **Preserve the confirm-before-deploy gate.** The AskUserQuestion confirmation before executing the Deploy section must remain (`plugins/core/skills/ship/SKILL.md` §1-3, §5 step 4).
- **Accepted: cross-agent coupling.** `core:ship` is the agent-neutral ship essence also shipped to Codex/OpenCode via `dist/workflows`, and `CLAUDE.md` is a Claude-specific filename — so on agents without a `CLAUDE.md` the deploy step simply skips. This coupling is an accepted, intentional consequence of the `CLAUDE.md`-only convention (and the `find-claude-md.sh` name); it is noted only for the record, not as something to re-litigate.

## Patches

> **Note**: These patches are speculative — verify before applying. The script edit assumes the file is renamed to `find-claude-md.sh` (e.g. `git mv` then edit).

### `plugins/core/skills/ship/scripts/find-claude-md.sh` (renamed from `find-cloud-md.sh`)

```diff
--- a/plugins/core/skills/ship/scripts/find-cloud-md.sh
+++ b/plugins/core/skills/ship/scripts/find-claude-md.sh
@@
-for candidate in "./cloud.md" "./.workaholic/cloud.md"; do
+for candidate in "./CLAUDE.md"; do
   if [ -f "$candidate" ]; then
     echo '{"found": true, "path": "'"$candidate"'"}'
     exit 0
   fi
 done
 
 echo '{"found": false}'
```

### `plugins/core/skills/ship/SKILL.md`

```diff
--- a/plugins/core/skills/ship/SKILL.md
+++ b/plugins/core/skills/ship/SKILL.md
@@
-4. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
-5. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
+4. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-claude-md.sh`. If `found` is `false`, or `CLAUDE.md` has no `## Deploy` section: inform user "No deploy instructions found in CLAUDE.md. Deployment skipped." and skip to summary. Otherwise: read `CLAUDE.md`, find the `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
+5. **Verify**: If a `## Deploy` section was found, read the `## Verify` section of `CLAUDE.md` and execute. Report results.
```

## Final Report

Development completed as planned. Implemented as a hard cutover: `git mv` renamed `find-cloud-md.sh` → `find-claude-md.sh` (now resolving `./CLAUDE.md` only), the ship `SKILL.md` §1 became "CLAUDE.md Convention" with the frontmatter description, §2-3 reference, Ship Flow steps 4–5, and not-found semantics all rewritten, and both READMEs were updated. `dist/workflows` was regenerated argument-less; `grep` confirms zero `cloud.md` references remain in `plugins/` or `dist/`, and `verify.mjs` passes.

### Discovered Insights

- **Insight**: Renaming a bundled skill script needs no `build.mjs` change, but the rebuild does not delete the previous artifact on its own — the orphaned `dist/.../find-cloud-md.sh` showed up as a git deletion that must be staged, otherwise `dist-freshness` CI would diff.
  **Context**: `build.mjs` computes each skill's script closure dynamically and copies whatever is present in source, so a rename is picked up automatically; but confirm the stale generated file's deletion is staged when committing a script rename.
- **Insight**: `find-claude-md.sh` only resolves the file path (`{found, path}`); detecting the `## Deploy`/`## Verify` sections is model-side. Because `CLAUDE.md` nearly always exists, the "skip deploy" trigger had to move from "file absent" to "file present but no `## Deploy` section."
  **Context**: This split (script = path resolution, model = section parsing) is the existing design; preserving it kept the change to a single-candidate loop plus prose, rather than adding section-parsing shell.
