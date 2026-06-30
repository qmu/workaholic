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
version and whether the PreToolUse Bash guards are registered, so an old or
partial install is visible instead of being mistaken for a broken hook.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

### Output Format

```json
{"ok": true, "version": "1.0.68", "guards_present": true, "missing_guards": []}
```

- `ok`: Boolean indicating dependencies are satisfied (always `true` for the
  single-plugin layout). Commands run this check early and stop with a message if
  `ok` is ever `false`.
- `version`: The **loaded** plugin version (read from the plugin's own
  `.claude-plugin/plugin.json`). Surfacing it makes a stale install detectable.
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
**warn when `missing_guards` is non-empty** (a stale or partial install), so the
loaded build is visible at the start of a flow rather than after an incident.

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
