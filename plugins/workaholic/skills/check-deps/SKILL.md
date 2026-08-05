---
name: check-deps
description: Verify required plugin dependencies are installed.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Check Dependencies

Workaholic is a **single plugin** (`dependencies: []`), so there are no external
plugin dependencies to verify. The dependency check is trivially satisfied and
kept for command-flow compatibility — `/ticket` and `/drive` call it as an early
pre-check. It also surfaces **stale-install diagnostics**: the loaded plugin
version, the version this checkout wants, and whether the PreToolUse Bash guards
are registered, so an old or partial install is visible instead of being mistaken
for a broken hook.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

### Output Format

```json
{"ok": true, "version": "1.0.112", "checkout_version": "1.0.126", "version_drift": true, "registry_version": "1.0.129", "registry_unreadable": false, "loaded_version_behind_registry": true, "guards_present": true, "missing_guards": []}
```

**Two independent drift axes, with different consequences.** `version_drift` compares the
loaded plugin against the **checkout** and is a *warning*;
`loaded_version_behind_registry` compares it against the **harness registry** and is a
*stop* (below). They have different causes and different fixes — one means the repository
moved, the other means this session bound a superseded cache directory — so they are
reported separately rather than collapsed.

- `ok`: Boolean indicating dependencies are satisfied (always `true` for the
  single-plugin layout). Commands run this check early and stop with a message if
  `ok` is ever `false`.
- `version`: The **loaded** plugin version — read from the manifest at
  `${CLAUDE_PLUGIN_ROOT}` when the harness set it, which is what this session actually
  bound, and only otherwise from the manifest beside this script. The distinction is
  load-bearing: the script's own location answers "where is this file", not "what is
  running", and the two diverge in precisely the case worth catching.
- `registry_version`: What the harness registry
  (`~/.claude/plugins/installed_plugins.json`, or `CLAUDE_PLUGIN_REGISTRY`) records as
  installed for `workaholic@workaholic` — the newest entry when several exist. Empty when
  `${CLAUDE_PLUGIN_ROOT}` is unset, because then there is no binding to compare.
- `registry_unreadable`: `true` when a plugin root was bound but the registry could not be
  read or names no install. Consumers treat this exactly like drift — an unanswerable
  question must not render as agreement.
- `loaded_version_behind_registry`: `true` when the loaded version sorts **strictly
  older** than the registry's. Ordered, not merely different: a loaded version *ahead* of
  the registry is a developer running a local build, which is deliberate.
- `checkout_version`: The version **this checkout wants**, from its
  `.claude-plugin/marketplace.json`. Empty (`""`) when not determinable — a
  consuming repository carries no marketplace manifest, and that is the normal
  case there, not a fault.
- `version_drift`: `true` only when **both** versions are known and they differ.
  One unknown side is silence, never an accusation.
- `guards_present`: `true` when all three PreToolUse Bash guards
  (`guard-ticket-structure.sh`, `guard-git-commit.sh`, `guard-git-branch.sh`) are
  registered in the loaded `hooks.json`.
- `missing_guards`: Array of any expected guard **not** found in the loaded
  `hooks.json`. A non-empty list means a stale/partial install — a **warning**,
  not a hard failure (`ok` stays `true`).

When the script cannot locate the manifest/hooks (the generated cross-agent
bundle, where hooks do not exist) or `jq` is absent, it degrades to `{"ok": true}`
with no extra fields. The diagnostic fields are best-effort, never a gate.

Commands that consume this check **surface `version`** to the developer and
**warn when `missing_guards` is non-empty or `version_drift` is `true`** (a stale
or partial install), so the loaded build is visible at the start of a flow rather
than after an incident.

### Why CHECKOUT drift is a warning, not a stop

A runner that refuses to work because its plugin is old is as useless as one that
works wrongly, and most releases touch nothing a given run reaches. So `ok` stays
`true` and the caller reports the drift. The hard stop already exists exactly
where drift bites: an obsolete always-on hook that rewrites artifacts leaves a
dirty tree, and `/drive`'s `sync-main.sh` terminates `pending` on it before the
run can survey. That is the 2026-08-04 outage — a baked-in v1.0.112 running its
pre-K1 mission migration backwards against a K1-era repository — and the fix was
to make the mismatch **legible** (a bare `"1.0.112"` reads as healthy to anyone
who does not know what the repository is on), not to add a second gate.

### Why REGISTRY drift *is* a stop

The paragraph above holds for a checkout that moved, and it left a blind spot in exactly
the case it was designed for. `plugin update` unpacks the new version **beside** the old
one and deletes nothing, so a session can bind a superseded directory and keep it — the
SessionStart bootstrap cannot help, because it is decided that it never refreshes a
running session.

Measured on the 2026-08-04T22:58Z hourly tick: the registry recorded `1.0.129`, updated
~85 seconds before the session's first commit, and the session ran `1.0.112` anyway. That
version's `claims.sh` predates the rename-following resolution and the `queue_drained`
verdict, so the survey reported five already-driven tickets as fresh backlog and the tick
**claimed one of them** — a double-pick reaching a pushed ref, which is the precise
failure the claim protocol exists to prevent. It was caught only because the runner
cross-checked against the checkout by hand.

The difference from checkout drift is what the drift can *do*. A checkout that moved means
the run may be missing a fix; a superseded binding silently changes the **survey's
answer**, and the run's next action on that answer is a push. So `/drive` terminates
`pending` before surveying (its §1), and the repair is a fresh session rather than a
retry. `ok` stays `true` here regardless — this script is a diagnostic and does not decide
the run's fate.

**The reporter must not be the thing it reports on.** Neither operand is plugin content:
one is the harness's binding, the other the harness's registry. A verdict derived from
files shipped *inside* the plugin would go stale with the plugin, which is why `version`
now prefers `${CLAUDE_PLUGIN_ROOT}` over this script's own location. A consumer must also
treat **the absence** of `loaded_version_behind_registry` as the condition itself: a build
too old to emit the field is, by construction, the stale build the field exists to catch.

**Known limit.** `checkout_version` reads the checkout as it is *right now*, and
`/drive` calls this **before** `sync-main.sh` fast-forwards. A runner whose clone
is itself behind the base therefore compares against a stale wanted-version and
can agree with a stale install — which is exactly how a matching 1.0.112/1.0.112
pair arose while `origin/main` was on 1.0.126. This script is a diagnostic and
must not mutate the checkout (the same reason `plan-units.sh` reports `current`
rather than repairing it), so the drift surfaces on the following tick instead.

### Activation probe (hook presence vs. hook firing)

`guards_present` confirms the guards are **registered** in the loaded
`hooks.json`. It does **not** prove they **fire**: a PreToolUse hook only runs on
the Bash **tool** call, not on a nested `sh` invocation, so a script cannot test
its own activation. To verify activation live, attempt an off-policy branch
through the Bash tool and confirm it is blocked:

```bash
git branch zzz-activation-probe   # expect: PreToolUse guard blocks this (exit 2)
```

If that is **not** blocked, the guard is registered but not firing in this
session — check the loaded `version` (a pre-1.0.66 build predates the branch
guard entirely). See the archived `branch-guard-not-enforced-in-session` ticket
for the failure mode this guards against.
