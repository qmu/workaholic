---
type: bugfix
layer: [Domain]
effort: 1h
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

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the resolution stays in `mission/scripts/gate.sh`; a worktree's location is derived, never guessed by a caller.
- `workaholic:implementation` / `policies/coding-standards.md` — the reader keeps its contract: `gate.sh` answers "where does this mission's server run", and must not report `valid: true` for a gate it cannot address.
- `workaholic:implementation` / `policies/domain-layer-separation.md` — "where is the main checkout from here" is domain logic with one answer; `git rev-parse --show-toplevel` is the wrong primitive inside a worktree and the right one must live in a single place.
- `workaholic:implementation` / `policies/objective-documentation.md` — `SKILL.md` states the gate is driven on `WORKAHOLIC_DEV_PORT`; code and documented contract are reconciled in the same change.
- `workaholic:implementation` / `policies/test.md` — the boundary condition to target deliberately: a mission **inside its own worktree** (the prescribed layout), which is the exact case with no coverage today.
- `workaholic:implementation` / `policies/observability.md` — a gate that cannot be driven must say so, rather than degrading silently to unverifiable while reporting success.

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

## Quality Gate

**Acceptance criteria** (hermetic assertions in `scripts/test-workflow-scripts.mjs`, real worktrees in temp repos, no network):

| case | must hold |
| --- | --- |
| `gate.sh <slug>` run **inside** the mission's own worktree (the prescribed layout) | resolves `port_base` / `dev_port` / `docs_port` from that worktree's `.env` — non-empty. This is today's bug and the case with no coverage. |
| `gate.sh <slug>` run from the **main checkout** for a mission created in a worktree | resolves the mission and its ports rather than returning `not_found` — or, if that is judged out of scope, returns an error that **names** the reason, never a silent empty. Decide and record which. |
| A mission with **no** worktree (the legacy case) | still reports empty ports without error — the correct answer for the right reason. No regression. |
| A `live-app` gate whose ports cannot be resolved | does **not** report `valid: true` with empty ports. Either it reports the gate as undriveable, or `valid` stops meaning "the word is spelled right". State which. |
| `gate.sh` on a mission with empty `gate_*` | unchanged — an absent gate is not an error (`20260716102950` makes empty the normal case). |

**Verification method:** create a real worktree in a temp repo (`create-mission-worktree.sh` → `create.sh`), then drive the real `gate.sh` from both inside the worktree and from the main checkout, asserting on the JSON. The bug reproduces only with a genuine worktree, so a fixture that fakes the directory proves nothing.

**The gate:** every row; the `valid`-semantics decision recorded either way; full suite green, 0 failed; `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; rebuild clean (the mission skill is bundled **six times**).

**Watch it fail first:** back up `gate.sh`, revert it alone (never `git stash`, and never revert uncommitted work — there is no HEAD to return to), confirm the inside-the-worktree assertion goes RED, restore from the backup.

## Final Report

Development completed as planned. Every gate row holds.

**The fix is a primitive swap.** `git rev-parse --show-toplevel` answers "where am I", which inside a worktree is *the worktree*. The question this code actually asks is "where is the **main** checkout", and `--git-common-dir` is the primitive for it: inside a linked worktree it points at the main `.git` (while `--git-dir` points at `.git/worktrees/<name>`), so its dirname is the main root. Verified empirically from all three locations — inside a worktree, at the main root, and from a main-checkout subdir — before writing a line of the fix, because git returns that path **relative to CWD** when convenient (`.git` at the toplevel, `../../.git` from a subdir). That is why it is resolved through `cd`+`pwd` rather than string surgery, and why a subdir case is asserted.

**The `valid`-semantics decision, recorded as the gate required.** `valid` keeps its existing meaning — *the declaration is well-formed* — because that is testable and callers already depend on it. The missing answer got its own field: **`driveable`**, with a `reason` (`no_gate` / `no_worktree`). This is why it matters: a mission could declare a `live-app` gate, pass validation with `valid: true`, and be **impossible to address** because the ports were empty. The gate degraded to unverifiable while reporting success. Overloading `valid` would have fixed the symptom by breaking a contract; adding `driveable` says the second thing without disturbing the first.

**The main-checkout half is deliberately not fixed**, and this is the scope call the gate asked me to state. Running `gate.sh <slug>` from the main checkout for a mission created in a worktree still returns `not_found` — correctly: the mission genuinely is not there, since it lives on the worktree's branch. `not_found` already names the reason, satisfying the gate row's second clause. Resolving it would mean scanning every worktree for the mission, which is a different feature (cross-worktree mission discovery) and would change what `mission_resolve` means for every mission script, not just this one.

### Discovered Insights

- **Insight**: This bug was invisible because **the failure looked identical to the legitimate case**. A mission with no worktree correctly reports empty ports; a mission *in* its worktree reported empty ports too — the right answer for the wrong reason. Both read as "no worktree yet".
  **Context**: The ticket called this out and it is the generalizable part: when a failure mode is indistinguishable from a valid state, no amount of looking at output finds it, and the only defence is a test that constructs the state where they must differ. That is why the test builds a **real** `git worktree` — a fixture that merely creates the directory resolves through `--show-toplevel` by accident and asserts nothing. `driveable`/`reason` also exist so the two cases stop looking alike at the API boundary.

- **Insight**: My subdir assertion initially failed, and the cause was **not** this bug: `mission_resolve` looks under a **CWD-relative** `.workaholic/`, so a bare slug cannot resolve from any subdirectory — a pre-existing property of every mission script, unrelated to port resolution.
  **Context**: I had conflated two lookups in one assertion, and the fix was to address the mission by absolute path so the test measures only what it names. Worth recording as a latent constraint: every mission script must be run from a checkout root. It is not a bug today because the workflows always run there, but it is a real edge for anyone invoking these scripts by hand, and it is invisible until you try.

- **Insight**: The relationship to `54e5ec65` (which demoted the mission gate to optional) is worth stating plainly, because the two look contradictory: that ticket found this script's brokenness was *evidence the gate was inert*, and this ticket fixes the script anyway.
  **Context**: They are consistent. Demoting the gate means a mission is not *required* to declare one — it does not mean a declared gate may silently fail. The `no_gate` reason encodes exactly that: an absent gate is the normal case and not an error, while a declared-but-unaddressable gate now says so. If the fields stay universally empty over the next few missions, the honest follow-up is to delete `gate_*` and this script outright rather than maintain a working reader nobody calls.

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
