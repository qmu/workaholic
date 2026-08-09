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

## Three drift axes: checkout drift warns, the other two stop

They have different causes and different fixes, so they are reported separately, and this script
decides neither — it is a diagnostic; the consumer enforces.

**Checkout drift (`version_drift`) is a warning.** A runner that refuses to work because its
plugin is old is as useless as one that works wrongly, and most releases touch nothing a given
run reaches. The hard stop already exists where drift bites: an obsolete always-on hook that
rewrites artifacts leaves a dirty tree, and `/drive`'s `sync-main.sh` terminates `pending` on it
before surveying — the fix was to make the mismatch legible, not to add a second gate (2026-08-04
outage: a baked-in stale build running a retired migration backwards).

**Registry drift (`loaded_version_behind_registry`) is a stop for `/drive` (its §1).** `plugin
update` unpacks the new version beside the old and deletes nothing, so a session can bind a
**superseded** cache directory and keep it — the SessionStart bootstrap never refreshes a running
session, so nothing repairs it. A superseded binding silently changes the **survey's answer**,
and the run's next action on that answer is a push (measured 2026-08-04: a stale `claims.sh`
offered five already-driven tickets as backlog and the tick claimed one). The repair is a fresh
session, never a retry. Two properties keep the check trustworthy at any plugin age: **neither
operand is plugin content** (the harness's binding vs the harness's registry), and **the absence
of the field counts as the condition** — a build too old to emit it is by construction the stale
build the field exists to catch.

**No binding at all (`unbound_in_claude_session`) is also a stop for `/drive` (its §1) — a
different failure from either axis above.** Registry drift is a *stale* binding; this is *no*
binding: a genuine Claude Code session (`CLAUDE_CODE_SESSION_ID` present) where the registry
confirms the plugin is installed, yet `loaded_root_source` never resolved past `"none"` — every
skill, command and hook the plugin ships is invisible for the whole run. FB `20260807104046`
measured it live: a SessionStart hook installed the plugin and printed the `/reload-plugins`
reminder, and the session's very next `Skill(...)` call failed `Unknown skill: workaholic:drive`.
Investigated and confirmed there is no fix inside the plugin (2026-08-09,
https://code.claude.com/docs/en/plugins-reference.md#plugin-updates-and-caching): Claude Code's
own documentation states hooks, MCP servers and LSP servers keep the previous binding until a
human runs `/reload-plugins` — there is no environment variable, CLI flag, or alternate hook event
that makes a SessionStart-time install effective mid-session, and an unattended routine never
types the one command that does. The repair is the same as registry drift's: a fresh session, not
a retry.

## Caveats

- **Known limit:** `checkout_version` reads the checkout as it is now, and `/drive` calls this
  **before** `sync-main.sh` fast-forwards — a clone behind the base can agree with a stale
  install on one tick; the drift surfaces on the next. The script must not mutate the checkout.
- **Activation probe:** `guards_present` proves registration, not firing (a PreToolUse hook runs
  only on the Bash tool call, so a script cannot test its own activation). To verify live, try
  `git branch zzz-activation-probe` through the Bash tool and expect the guard to block it; if it
  is not blocked, the guard is registered but not firing — check the loaded `version`.
