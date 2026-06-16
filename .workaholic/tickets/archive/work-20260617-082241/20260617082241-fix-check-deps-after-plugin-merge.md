---
created_at: 2026-06-17T08:22:41+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: 4dd4d21
category: Changed
depends_on:
---

# Fix check-deps regression after the plugin merge

## Overview

The plugin merge (collapsing `core`+`standards`+`work` into one `workaholic`
plugin) broke `check-deps`. Its `check.sh` looks for a **sibling `core` plugin**
(`${plugin_root}/../core/.claude-plugin/plugin.json`) that no longer exists, so it
now returns `{"ok": false, "missing": ["core"], ...}` unconditionally.

This is a **command-blocking regression**: `/ticket` and `/drive` run check-deps as
a pre-check and stop when `ok` is `false`. The static gates (build/verify/validate/
smoke) don't exercise check-deps, so they didn't catch it.

With a single plugin (`dependencies: []`), there are no external plugin
dependencies to verify. `check.sh` should simply return `{"ok": true}`.

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/check.sh` - Replace the sibling-`core`-plugin existence check with an unconditional `{"ok": true}` (one plugin, no external deps).
- `plugins/workaholic/skills/check-deps/SKILL.md` - Update the prose ("Verify that required plugin dependencies (core) are installed") to reflect that the single `workaholic` plugin has no external dependencies; the check is now a trivially-satisfied guard kept for command-flow compatibility.
- `plugins/workaholic/commands/ticket.md`, `drive.md` - They call check-deps as a pre-check; no change needed once `check.sh` returns `ok: true`, but verify the pre-check text still reads correctly.

## Related History

This regression was introduced by the merge on the same branch as this fix's parent work; it is the concrete instance of the "runtime skill resolution benefits from interactive verification" caveat noted in the merge ticket's Final Report (the static gates passed but a runtime pre-check broke).

## Implementation Steps

1. Edit `check.sh` to drop the `core_path` logic and always `echo '{"ok": true}'`.
2. Update `check-deps/SKILL.md` prose to the single-plugin reality.
3. Verify by running `bash plugins/workaholic/skills/check-deps/scripts/check.sh` → `{"ok": true}`.
4. Run the gate suite (`build`, `verify`, `validate-metadata`, `test-workflow-scripts`) — no `dist/`/`outputs/` change expected, but confirm green.

## Considerations

- **Keep the script, not just delete it.** `/ticket` and `/drive` reference
  `check-deps` as a pre-check; making it a trivially-passing no-op is lower-risk
  than editing both commands to remove the call. (`plugins/workaholic/commands/`)
- **No new conditional shell.** The fixed script is a one-line echo — no branching.
  (CLAUDE.md Shell Script Principle)
- This is the kind of cross-plugin-dependency assumption the merge had to unwind;
  audit for any other script that assumes a sibling `core`/`standards`/`work`
  plugin directory exists. (`grep -rn '\.\./core\|\.\./standards\|\.\./work' plugins/workaholic/skills/*/scripts/`)

## Final Report

Development completed as planned. Replaced `check.sh`'s sibling-`core`-plugin
existence check with an unconditional `{"ok": true}`, and rewrote
`check-deps/SKILL.md` to the single-plugin reality. Audited all skill scripts for
other `../core` / `../standards` / `../work` sibling-plugin assumptions — **none
remain**. `check-deps` now returns `{"ok": true}`, unblocking the `/ticket` and
`/drive` pre-checks. Regenerated `outputs/`; build/verify/validate and 49 smoke
tests pass.

### Discovered Insights

- **Insight**: This regression slipped past the merge's four gates because
  `check-deps` is a runtime *command pre-check*, not exercised by
  build/verify/validate/smoke. **Context**: after a structural change, also
  smoke-run the command pre-checks (`check-deps`, `check-workspace`,
  `detect-context`) — the build gates prove artifacts are well-formed, not that
  the live command path still passes.
