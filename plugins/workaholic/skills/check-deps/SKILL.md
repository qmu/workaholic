---
name: check-deps
description: Verify required plugin dependencies are installed.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Check Dependencies

Workaholic is a single plugin (`dependencies: []`), so the dependency check is trivially
satisfied and kept for command-flow compatibility — `/ticket` and `/drive` call it as an early
pre-check. Its real value is **stale-install diagnostics**: the loaded plugin version, the two
drift axes below, and whether the PreToolUse Bash guards are registered.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

### Output contract

```json
{"ok": true, "version": "1.0.112", "checkout_version": "1.0.126", "version_drift": true, "registry_version": "1.0.129", "registry_unreadable": false, "loaded_version_behind_registry": true, "claude_session_detected": true, "registry_has_install": true, "unbound_in_claude_session": false, "guards_present": true, "missing_guards": []}
```

- `ok` — dependencies satisfied (always `true` for the single-plugin layout). Consumers stop with
  a message if it is ever `false`.
- `version` — the **loaded** plugin version, read from the manifest at `${CLAUDE_PLUGIN_ROOT}`
  when the harness set it (what this session actually bound), only otherwise from the manifest
  beside the script — the script's location answers "where is this file", not "what is running".
- `checkout_version` — what this checkout wants, from its `.claude-plugin/marketplace.json`.
  Empty when not determinable (a consuming repository carries no manifest — normal, not a fault).
- `version_drift` — `true` only when **both** versions are known and differ. One unknown side is
  silence, never an accusation.
- `registry_version` — what the harness registry (`~/.claude/plugins/installed_plugins.json`, or
  `CLAUDE_PLUGIN_REGISTRY`) records as installed; empty when `${CLAUDE_PLUGIN_ROOT}` is unset.
- `registry_unreadable` — a plugin root was bound but the registry could not be read or names no
  install. Consumers treat this exactly like being behind — an unanswerable question must not
  render as agreement.
- `loaded_version_behind_registry` — the loaded version sorts **strictly older** than the
  registry's. Ordered, not merely different: a loaded version *ahead* of the registry is a
  developer running a local build, which is deliberate.
- `claude_session_detected` — this IS a genuine Claude Code session (`CLAUDE_CODE_SESSION_ID` is
  set), independent of whether a plugin root was ever bound.
- `registry_has_install` — the harness registry lists ANY install for this plugin, independent of
  `loaded_root`/`registry_version` above (which only compute when a root was bound).
- `unbound_in_claude_session` — `true` when `loaded_root_source == "none"` **and**
  `claude_session_detected` **and** `registry_has_install`: a genuine Claude Code session where the
  plugin is installed per the harness's own registry, yet nothing was ever bound this session — the
  fresh-install/no-reload gap (see *Three drift axes* below). **Known limit**: a developer who
  invokes this script directly by its literal path in an otherwise-healthy, fully-bound session
  also shows `loaded_root_source == "none"` for that one call (the `${CLAUDE_PLUGIN_ROOT}`
  substitution happens in command-body text, never as a process env var), so this can
  false-positive there — accepted, since over-reporting costs a `pending` and under-reporting
  costs a run with zero plugin surface reading as healthy.
- `guards_present` / `missing_guards` — whether the expected PreToolUse Bash guards
  (`guard-ticket-structure.sh`, `guard-git-commit.sh`, `guard-git-branch.sh`) are registered in
  the loaded `hooks.json`. A non-empty list means a stale/partial install — a warning, `ok` stays
  `true`.

When the manifest/hooks cannot be located (the generated cross-agent bundle) or `jq` is absent,
the script degrades to `{"ok": true}` with no extra fields — the diagnostics are best-effort,
never a gate. Consumers surface `version` at the start of a flow and warn on `version_drift` or
non-empty `missing_guards`.

## Three drift axes: checkout drift and no-binding warn, registry drift stops

They have different causes and different fixes, so they are reported separately, and this script
decides neither — it is a diagnostic; the consumer enforces.

**Checkout drift (`version_drift`) is a warning.** A runner that refuses to work because its
plugin is old is as useless as one that works wrongly, and most releases touch nothing a given
run reaches. The hard stop already exists where drift bites: an obsolete always-on hook that
rewrites artifacts leaves a dirty tree, and `/drive`'s `sync-main.sh` terminates `pending` on it
before surveying — the fix was to make the mismatch legible, not to add a second gate (2026-08-04
outage: a baked-in stale build running a retired migration backwards).

**Registry drift (`loaded_version_behind_registry`) is a warning, and `plugin-src.sh` is what
answers it** (2026-08-12, the developer's ruling; it was a `/drive` §1 stop until then). `plugin
update` unpacks the new version beside the old and deletes nothing, so a session can bind a
**superseded** cache directory and keep it — the SessionStart bootstrap never refreshes a running
session, so nothing repairs *the binding*. What the old stop actually protected was the run's
**scripts**, not its binding: a superseded binding silently changed the survey's answer and the
run's next action on that answer is a push (measured 2026-08-04: a stale `claims.sh` offered five
already-driven tickets as backlog and the tick claimed one). So the answer is to stop reaching
through the binding — see *Resolving the source to run from* below — rather than to refuse to run.
Two properties keep the check itself trustworthy at any plugin age: **neither operand is plugin
content** (the harness's binding vs the harness's registry), and **the absence of the field counts
as the condition** — a build too old to emit it is by construction the stale build the field
exists to catch.

## Resolving the source to run from (`scripts/plugin-src.sh`)

```
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/plugin-src.sh [--clone] [--refresh]
```

Returns the **newest plugin tree present on this machine** and the run executes every script
from it: `{"ok": true, "src": …, "source": "checkout|registry|clone|bound", "version": …,
"src_immutable": …, "degraded": …, "bound_version": …, "candidates": [{…, "immutable": …}]}`.
The candidates are the **checkout** (`<project>/plugins/workaholic`), the newest **registry**
`installPath` (already downloaded — no network), a **clone** at `$WORKAHOLIC_SRC_HOME` (created
only with `--clone`), and the **bound** `${CLAUDE_PLUGIN_ROOT}`. Picking the newest can only move
a run forward on the staleness axis, which is what makes the demoted gate above safe.

**Two axes decide, in order: version, then stability.** Highest version wins outright — a
genuinely newer checkout still executes, which is what lets this repository develop its own
plugin and run the result. On an **equal** version the **immutable** candidate wins, because a
tie on version is not a tie on stability.

**`src_immutable` is the field to read, not a convention to remember.** A candidate is immutable
when its path is **version-addressed** — its own basename is the version it carries, the cache
layout `<cache>/workaholic/workaholic/<version>/` — so a different version unpacks to a different
directory and nothing can change the content behind a path already resolved. A checkout, a clone,
and a binding pointing at either are working trees, and are mutable by that same test.
`candidates[].immutable` reports it per candidate.

**Ordering rule for callers — the resolution must outlive every tree-moving step in the run.**
The source is resolved at the top of a run (`/drive` §1) and the freshen (`sync-main.sh`) runs
*after* it, so a mutable `src` can change — including backwards — while the run is already
executing from it. A caller therefore either resolves a source with `src_immutable: true`, or
**re-resolves after the tree-moving step**; preferring the immutable path on a tie makes the
first case the default and costs the caller nothing. Measured 2026-08-12T22:24Z: a cloud tick
resolved the checkout at a version tie, then reached a surveyable state by checking out the
container image's stale baked `main`, and the plugin source silently reverted 200 commits with
it — to a `sync-main.sh` that answered `diverged`, which the caller reads as terminate
`pending`. The tick would have been lost to the very failure the newer code prevents, while
reporting a version that was not the code it ran.

The harness binding is therefore an input, never a precondition: `unbound_in_claude_session` and
`loaded_version_behind_registry` both become source-selection facts to report. `ok: false`
(`no_plugin_source`) is the one genuine stop — nothing on the machine carries the workflow.
**It does not repair hooks**: PreToolUse guards and the policy lens belong to whatever the harness
bound, so a degraded run keeps the older guards (`guards_present` reports whether they are
registered at all) and must load `hooks/policy-index.md` from `src` explicitly.

**No binding at all (`unbound_in_claude_session`) is a warning for `/drive` (its §1), not a stop**
(2026-08-10, ticket `20260810090005`) — a different failure from either axis above, and lighter in
kind. `/drive`'s handling is one instance of the general rule stated once in
`plugins/workaholic/rules/general.md` ("An unbound skill surface is not, by itself, a reason to
stop"): any unattended entry point that finds the `Skill`/`Command` abstraction unreachable, with
the checkout present and current, reads the needed skill from the checkout path instead of
stopping outright. Registry drift is a *stale* binding whose scripts run and silently lie; this is *no* binding:
a genuine Claude Code session (`CLAUDE_CODE_SESSION_ID` present) where the registry confirms the
plugin is installed, yet `loaded_root_source` never resolved past `"none"` — every skill, command
and hook the plugin ships is invisible to the Skill/Command tool abstraction for the whole run. FB
`20260807104046` measured it live: a SessionStart hook installed the plugin and printed the
`/reload-plugins` reminder, and the session's very next `Skill(...)` call failed
`Unknown skill: workaholic:drive`. Investigated and confirmed there is no fix inside the plugin
(2026-08-09, https://code.claude.com/docs/en/plugins-reference.md#plugin-updates-and-caching):
Claude Code's own documentation states hooks, MCP servers and LSP servers keep the previous
binding until a human runs `/reload-plugins` — there is no environment variable, CLI flag, or
alternate hook event that makes a SessionStart-time install effective mid-session, and an
unattended routine never types the one command that does. Unlike registry drift, though, the
scripts themselves are not stale here — only the Skill/Command binding is missing — so the
developer's live correction (FB `20260810070110`) generalizes: the plugin's own scripts stay
directly runnable via `bash` from the checkout path, and the PreToolUse safety hooks stay
registered and active, independent of whether the Skill/Command binding resolved. `/drive` now
warns, records the condition in the run report, and continues by invoking every remaining script
on its checkout-relative path rather than `${CLAUDE_PLUGIN_ROOT}`.

## Caveats

- **Known limit:** `checkout_version` reads the checkout as it is now, and `/drive` calls this
  **before** `sync-main.sh` fast-forwards — a clone behind the base can agree with a stale
  install on one tick; the drift surfaces on the next. The script must not mutate the checkout.
- **Activation probe:** `guards_present` proves registration, not firing (a PreToolUse hook runs
  only on the Bash tool call, so a script cannot test its own activation). To verify live, try
  `git branch zzz-activation-probe` through the Bash tool and expect the guard to block it; if it
  is not blocked, the guard is registered but not firing — check the loaded `version`.
