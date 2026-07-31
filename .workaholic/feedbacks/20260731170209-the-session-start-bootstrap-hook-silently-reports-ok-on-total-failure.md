---
type: Feedback
title: The session-start bootstrap hook silently reports OK on total failure
kind: insight
source: discussion
created_at: 2026-07-31T17:02:09+00:00
author: noreply@anthropic.com
supersedes: 
---

# The session-start bootstrap hook silently reports OK on total failure

# The session-start bootstrap hook silently reports OK on total failure

Registered from [qmu/workaholic#126](https://github.com/qmu/workaholic/issues/126) — a review of a
draft `session-start.sh` for Claude Code on the web. Recorded in the reviewer's own words.

## The review

The overall shape is right — gate on `CLAUDE_CODE_REMOTE`, fail open so the hook never blocks session
start, and redirect output to a log file instead of polluting the session context. But the current
draft has one bug that silently defeats its own verification step, plus a few robustness issues.

**1. The failure path never fires (blocking).**

```
{ ... } >>"$LOG" 2>&1 || echo "FAILED"
```

Because the `{ }` group is the left side of a `||` list, `set -e` is suppressed *inside* the group —
errexit is ignored for any command in an `&&`/`||` list except the last, and that context propagates
into the compound command. Consequences: if `marketplace add` fails the script does not stop, it
proceeds to `install`; the final `echo "OK"` succeeds, so the group exits 0; `|| echo "FAILED"`
therefore never runs, and the log says `OK` even on total failure. The intent ("if this isn't green
here, the session will break too") is fully defeated. Each step needs an explicit status check.

**2. `marketplace add --scope user` is probably invalid.** `--scope` is documented for
`plugin install`, not for `marketplace add`, which takes only the marketplace. And `plugin install`
already defaults to user scope, so the flag is redundant there as well. An "unknown option" error
would be swallowed by issue 1.

**3. Not idempotent across re-runs.** `SessionStart` fires on `resume`, `clear`, and `compact` too,
not just `startup` — restrict the matcher. `marketplace add` on an already-registered marketplace
errors out. And a known CLI limitation: the marketplace is a local git clone and `plugin install`
does *not* refresh it before resolving the plugin name, so a stale clone fails with a misleading
"not found" error — run `marketplace update` first when it is already registered.

**4. Smaller issues.** `export HOME=/root` is hardcoded and breaks immediately if the hook runs as
non-root (`~/.claude` unwritable) — use `: "${HOME:=/root}"` and respect an existing value.
`LOG=/var/log/...` is not writable as non-root and grows unbounded across sessions — use
`${TMPDIR:-/tmp}` or `$HOME/.cache`. A network clone plus install can exceed the default hook
timeout — set `"timeout": 120` in `settings.json`. The hook runs on every session start — exit early
if the plugin is already installed. And a plugin installed during `SessionStart` is not picked up
until `/reload-plugins` — emit a one-line note on stdout, which lands in the session context.

**5. To verify on the platform.** If `qmu/workaholic` is private, sandbox git goes through a proxy
using a credential scoped to the session's repository, so cloning a *different* private repo may be
blocked — test this before relying on it. Run `env | grep -i claude` and
`claude plugin install --help` once inside a web session to confirm the variable value and the actual
flag set.

## The revised script

```bash
#!/bin/bash
# Fail-open: this hook must never block session start, so no `set -e`.
set -uo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

: "${HOME:=/root}"; export HOME
LOG="${TMPDIR:-/tmp}/bootstrap-workaholic.log"
MP=workaholic
PLUGIN="workaholic@${MP}"

log() { printf '%s %s\n' "$(date -Is)" "$*" >>"$LOG"; }
run() { log "\$ $*"; "$@" >>"$LOG" 2>&1 || { log "FAILED: $*"; return 1; }; }
die() { echo "workaholic bootstrap: $1 (see $LOG)"; exit 0; }  # exit 0 = fail open

log "=== bootstrap (claude $(claude --version 2>/dev/null || echo unknown)) ==="

# Already installed: skip the network round-trip entirely.
if claude plugin list 2>/dev/null | grep -q "$PLUGIN"; then
  log "already installed; skip"
  exit 0
fi

# 1) Register the marketplace (refresh it if already registered).
if claude plugin marketplace list 2>/dev/null | grep -q "$MP"; then
  run claude plugin marketplace update "$MP" || true   # try install anyway
else
  run claude plugin marketplace add qmu/workaholic || die "marketplace add failed"
fi

# 2) Install (user scope is the default).
run claude plugin install "$PLUGIN" || die "install failed"

# 3) Verify.
run claude plugin list || true
echo "workaholic installed. Run /reload-plugins if its commands aren't available yet."
exit 0
```

With `settings.json` registering it under a `startup` matcher with `"timeout": 120`.

## What was measured (2026-07-31)

The reviewed script is **not in this repository**: `grep -rn "session-start"` over the tree matches
one prose line in an unrelated 2026-07-06 story and nothing else, `.claude/settings.json` carries
only `env` and `permissions` (no `hooks` key), and the plugin's `hooks/hooks.json` registers no
`SessionStart` event at all. So this is inbound review of a draft held outside the checkout — the
same gap `20260731160517-routine-configuration-has-no-source-of-truth-in-the-repository.md` measured
for the scheduled routines, now reaching the bootstrap hook that would install the plugin in the
first place.
