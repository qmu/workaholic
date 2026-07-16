---
type: bugfix
layer: [Domain]
created_at: 2026-07-16T02:10:00+09:00
author: a@qmu.jp
depends_on: []
---

# `gate.sh` can never resolve the ports of a mission living in its own worktree

## Motivation

`/mission` prescribes exactly one layout: a mission lives in its own persistent
`.worktrees/<slug>/` on its own `work-*` branch, and its quality gate is verified
by driving that worktree's server on the worktree's assigned port. For that
layout, `gate.sh` **always** returns empty ports. Both halves of the lookup fail,
in opposite directions, and there is no third place to run it from.

`gate.sh:47-48` resolves the env file like this:

```sh
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
env_file="${repo_root}/.worktrees/${slug}/.env"
```

**Run it inside the mission's worktree** — which is where the mission file is, and
where `/drive` auto-routes — and `git rev-parse --show-toplevel` returns *the
worktree itself*, not the main checkout. So the lookup becomes
`<worktree>/.worktrees/<slug>/.env`: a `.worktrees` directory nested inside a
worktree, which nothing ever creates. The ports come back `""`.

**Run it from the main checkout instead** and the ports would resolve — but the
mission is not there. It was created inside the worktree on the worktree's
branch, so the main checkout's `.workaholic/missions/active/` has no such
directory and `gate.sh` exits with `{"error": "not_found"}`.

Verified end to end on a mission created through the sanctioned flow
(`create-mission-worktree.sh` → `create.sh`). The worktree's `.env` is present and
correct:

```
WORKAHOLIC_PORT_BASE=4100
WORKAHOLIC_DEV_PORT=4100
WORKAHOLIC_DOCS_PORT=4101
```

and `gate.sh <slug>` from inside that worktree still returns
`"port_base": "", "dev_port": "", "docs_port": ""`. From the main checkout the same
command returns `not_found`.

**The impact is not cosmetic.** `SKILL.md` states the gate is verified by driving
the worktree's running server on `WORKAHOLIC_DEV_PORT`, and that the per-worktree
port base is what lets several missions' gates be checked at once. A `live-app`
gate has no target address without the port, so it cannot be driven at all — the
gate silently degrades to unverifiable while `gate.sh` still reports
`"valid": true`, because `valid` only checks that `gate_type` is one of the
allowed words. A mission can therefore declare a live gate, pass validation, and
be undriveable, with nothing in the output saying so.

This has been invisible because the two missions that predate the worktree flow
have no worktree at all, so their empty ports read as "no worktree yet" —
the correct answer for the wrong reason. Creating a mission properly, with a
worktree, produces the *same* empty ports. That is what makes this worth a
ticket rather than a note: the failure looks identical to the legitimate case.

## Scope

`gate.sh` returns the mission worktree's real ports when run from inside that
worktree — the only place the mission file exists and the place `/drive` routes to.

Two fixes are available and the choice is worth making deliberately:

- **Read the `.env` at the worktree root.** `create-mission-worktree.sh` places it
  at `<worktree>/.env`, which is exactly `${repo_root}/.env` when `gate.sh` runs
  inside the worktree. This is a one-line change and needs no knowledge of where
  the main checkout is.
- **Derive the main checkout from `git rev-parse --git-common-dir`**, which returns
  the main `.git` from inside any worktree; its parent is the main root, so the
  existing `${main_root}/.worktrees/${slug}/.env` path keeps working unchanged.

The first is simpler and reads the file the worktree owns. The second keeps the
current "ports belong to the main checkout's view of its worktrees" framing and
also fixes the case of running from the main checkout — though that case is
already unreachable for a live mission, since the mission file is not there.
Whichever is chosen, keep the "no worktree" case returning empty ports rather
than erroring.

Consider also whether `valid: true` should keep being reported for a `live-app`
gate whose port did not resolve. Right now the field answers only "is `gate_type`
a legal word", so a gate that cannot be driven still validates. That is a
separate judgement from this bug's mechanics, and the fix may make it moot — but
if a caller is meant to trust `valid`, an undriveable live gate arguably is not
valid.

## Key Files

- `plugins/workaholic/skills/mission/scripts/gate.sh:47-48` — the defect.
  `--show-toplevel` resolves to the worktree, so the `${repo_root}/.worktrees/`
  hop lands one level too deep.
- `plugins/workaholic/skills/mission/scripts/gate.sh:52-56` — the guarded read;
  correct in itself, simply never reached with a real path.
- `plugins/workaholic/skills/mission/scripts/gate.sh:41-44` — `valid` is computed
  purely from `gate_type` membership, independent of whether a port resolved.
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` — writes
  the `.env` and returns `port_base`/`dev_port`/`docs_port`; the values are right,
  only the later lookup is wrong.
- `plugins/workaholic/skills/mission/SKILL.md` (Quality gate section) — states the
  gate is driven against the worktree's port and that per-worktree ports let
  several gates run at once. That promise is what is currently unmet.
- `plugins/workaholic/commands/mission.md` (create path, step 3) — instructs the
  author to set `gate_target` to "a route served on the worktree's port", which is
  the contract this breaks.

## Considerations

- The mission-creation flow itself is fine: the worktree, the branch, and the
  `.env` are all created correctly. Only the read-back is wrong, so no existing
  mission's data needs migrating.
- A mission with no worktree must keep returning empty ports, not an error —
  missions created before the worktree flow are still active and are read by the
  same script.
- Worth checking whether any other script does the same
  `${repo_root}/.worktrees/...` hop while running inside a worktree; the mistake
  is natural enough to have been made twice, and `--show-toplevel` returning the
  worktree is the kind of thing that reads correct until it is run from the place
  the flow actually puts you.
