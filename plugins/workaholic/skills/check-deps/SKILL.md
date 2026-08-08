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
{"ok": true, "version": "1.0.112", "checkout_version": "1.0.126", "version_drift": true, "registry_version": "1.0.129", "registry_unreadable": false, "loaded_version_behind_registry": true, "bootstrap_reload_pending": false, "bootstrap_reload_reason": "", "bootstrap_reload_at": "", "guards_present": true, "missing_guards": []}
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
- `bootstrap_reload_pending` / `bootstrap_reload_reason` / `bootstrap_reload_at` — whether
  the consuming repo's own `session-start.sh` performed a real install or update (`"install"`
  or `"update"`) at some point THIS session, per the marker it writes at
  `${TMPDIR:-/tmp}/workaholic-bootstrap-reload-pending`. `false`/empty when the marker is
  absent — either the bootstrap took its skip fast path, or this is not a bootstrapped
  session at all. See *Bootstrap reload-pending* below.
- `guards_present` / `missing_guards` — whether the expected PreToolUse Bash guards
  (`guard-ticket-structure.sh`, `guard-git-commit.sh`, `guard-git-branch.sh`) are registered in
  the loaded `hooks.json`. A non-empty list means a stale/partial install — a warning, `ok` stays
  `true`.

When the manifest/hooks cannot be located (the generated cross-agent bundle) or `jq` is absent,
the script degrades to `{"ok": true}` with no extra fields — the diagnostics are best-effort,
never a gate. Consumers surface `version` at the start of a flow and warn on `version_drift` or
non-empty `missing_guards`.

## Two drift axes: checkout drift warns, registry drift stops

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

## Bootstrap reload-pending: closes part of the gap, not all of it

Investigated 2026-08-08 (qmu/workaholic ticket 20260807131727), reproduced live inside an
`[Implement]` routine run: immediately after `session-start.sh` printed its old
"installed, run `/reload-plugins`" line, `Skill({skill: "workaholic:drive"})` returned
"Unknown skill" for the whole rest of that session — nothing from the plugin (commands,
skills, hooks) was registered at all. Checked against Claude Code's own docs
(`code.claude.com/docs/en/plugins.md` / `plugins-reference.md`): a mid-session plugin
change does not take effect for hooks, skills, or commands until a human types
`/reload-plugins`, and there is **no documented programmatic equivalent** — an unattended
session cannot trigger one.

**There is no fix inside the plugin for that totally-fresh case, and unlike the
registry-drift axis above, the gap cannot even be *detected* from inside the plugin**: any
script that would report the condition — `check.sh` included — is exactly as unregistered
as the skill whose absence it would explain. `bootstrap_reload_pending` only closes the
narrower, real case where *some* registration survives: an update that leaves the old
build's skills/commands bound rather than none at all (Claude Code's own doc: a
mid-session update "keeps using the previous version's path"), the update-only twin of
`loaded_version_behind_registry`. For that case `/drive`'s own preflight can still reach
this script and terminate `pending` on the field.

The totally-fresh case is instead handled by `session-start.sh`'s own trailing stdout
message, which lives in the *consuming repo's* hook config rather than in this plugin, so
it always runs and is always readable regardless of what the harness did or did not
register afterward — the one channel proven to survive. That message now states the
condition and the required response directly: treat the next `Unknown skill`/`Unknown
command` as this exact gap, report the run pending, and stop, rather than falling back to
guessing internal script paths.

**Known limit of the marker itself:** nothing observes whether a later `/reload-plugins`
actually ran, so once written it stays `true` for the rest of the session's `TMPDIR`
lifetime even if the gap was since resolved by hand. An occasional false "still pending"
is the accepted cost — the alternative, silently clearing it, risks the opposite: a real
gap read as healthy.

## Caveats

- **Known limit:** `checkout_version` reads the checkout as it is now, and `/drive` calls this
  **before** `sync-main.sh` fast-forwards — a clone behind the base can agree with a stale
  install on one tick; the drift surfaces on the next. The script must not mutate the checkout.
- **Activation probe:** `guards_present` proves registration, not firing (a PreToolUse hook runs
  only on the Bash tool call, so a script cannot test its own activation). To verify live, try
  `git branch zzz-activation-probe` through the Bash tool and expect the guard to block it; if it
  is not blocked, the guard is registered but not firing — check the loaded `version`.
