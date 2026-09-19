---
created_at: 2026-09-19T11:55:10+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-the-codex-clock-dying-silently-and-writing-the-locks-it-reads
merge_policy:
verification_handoff: 
---

# Recover or record a retired plugin tree at startup

## Overview

The reported failure — a supervisor pinned to a plugin version that then vanished, ticking into
the same wall forever with no path back — does not reproduce against this tree's running loop.
`ensure_plugin_tree()` is called at the head of **every** iteration and re-resolves the tree
through `check-deps/scripts/plugin-src.sh`, re-deriving `TICK_PROMPT`, `SCRIPT_DIR` and
`COMMAND_BODY`, so the composed tick prompt and dispatch line carry the current path rather than a
baked-in one. It landed 2026-09-07 in #1069 — the same day the reported loop died, which is why
that process could never have picked it up.

What does not reproduce is the loop; what does is the **startup**. The guards that refuse a
missing `skills/work/SKILL.md` or `commands/infinite-development.md` run before `REPO_ROOT`,
`LOG_DIR` and `SUPERVISOR_FILE` are resolved and before `ensure_plugin_tree` is reachable, so such
a launch exits 2 with no recovery attempted and **no record written anywhere**. `--status` then
answers `absent`, which is the reading *never started* — indistinguishable from a repository that
never ran the Codex path, and exactly the confusion `supervisor.json` was added to end.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/failure-handling.md` — a refusal that leaves no evidence is a silent failure

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the startup guards
  (`plugin_skill_missing` / `plugin_command_missing`), the `REPO_ROOT` / `LOG_DIR` resolution below
  them, `ensure_plugin_tree()` and `plugin_tree_complete()`, and `write_supervisor()`.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the sanctioned resolver, two axes
  (`src`, `call_src`); the startup path must read it exactly as the loop does and gain no third axis.
- `scripts/codex-loop.sh` — the shim, which refuses `clock_wrapper_missing` before any of this.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the startup-refusal vocabulary and
  the supervisor-liveness contract both live here.
- `scripts/e2e/drills/verify-codex-clock.sh` — already has a `clock_wrapper_missing` breaker row.

## Implementation Steps

1. Reproduce: launch the supervisor against a copy of the plugin tree with
   `skills/work/SKILL.md` removed, and record that it exits 2 with no state directory written and
   that a subsequent `--status` answers `absent`.
2. Move the `REPO_ROOT` / `LOG_DIR` / `SUPERVISOR_FILE` resolution above the two plugin-tree
   guards, so a refusal has somewhere to record itself. Nothing else about the order may move —
   the interval validation and the argument parse stay where they are.
3. Make the startup path attempt the same recovery the loop already performs, through
   `ensure_plugin_tree()` rather than a second copy of it: one resolution, one
   `plugin_tree_complete()` test, the resolver's `call_src // src` preference unchanged.
4. When the recovery succeeds, report it the way the loop does
   (`recovered retired plugin tree <old> -> <new>`) and start normally.
5. When it cannot, write `stopped` with the precise word already in use
   (`clock_wrapper_missing`, `plugin_skill_missing`, `plugin_command_missing`) and the retired root
   beside it, then exit 2 as before. The exit status and the stderr lines do not change.
6. Leave `repository_missing` refusing before any record — there is no repository to record into,
   and inventing a location for the state directory would be worse than the absence.
7. Add a drill row proving a startup against a retired tree leaves a readable `stopped` record
   naming the reason, with a breaker that restores the early exit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A supervisor started against a plugin tree missing its work skill recovers it when a complete
  tree exists on the machine, and says which tree it moved to.
- When no complete tree exists, the state directory carries `state: stopped` with the reason word,
  and `--status` reports that rather than `absent`.
- A launch outside a git repository still refuses `repository_missing` and writes nothing.

**Verification method** — the commands/tests/probes that prove them:

- The step 1 reproduction, re-run after the change, in both the recoverable and unrecoverable cases.
- `sh scripts/e2e/loop-drill.sh verify-codex-clock`.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Both new drill rows pass and their breakers fail the drill.

## Considerations

- Keep one resolution seam. A second copy of the recovery inside the startup guard is how the two
  paths start disagreeing about which tree is current.
- The resolver's two axes are load-bearing and must not be flattened here: `src` says which code
  runs, `call_src` keeps the call inside the workspace.
