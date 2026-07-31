---
type: Feedback
title: Review of the draft session-start bootstrap hook
kind: insight
source: discussion
created_at: 2026-07-31T17:01:44+00:00
author: noreply@anthropic.com
supersedes: 
---

# Review of the draft session-start bootstrap hook

A review of a draft `session-start.sh` bootstrap hook for Claude Code on the web (the hook that would install the workaholic plugin into a web session). The shape is judged right — gate on `CLAUDE_CODE_REMOTE`, fail open so the hook never blocks session start, redirect output to a log rather than the session context — with one blocking bug and several robustness issues:

1. **The failure path never fires.** In `{ ... } >>"$LOG" 2>&1 || echo "FAILED"`, `set -e` is suppressed inside the group because it is the left side of a `||` list, so a failed `marketplace add` does not stop the script, the final `echo "OK"` makes the group exit 0, and the log reports `OK` on total failure. Each step needs an explicit status check.
2. **`marketplace add --scope user` is probably invalid** — `--scope` is documented for `plugin install`, not `marketplace add`, and `plugin install` already defaults to user scope. The "unknown option" error would be swallowed by issue 1.
3. **Not idempotent** — `SessionStart` also fires on `resume`, `clear` and `compact` (restrict the matcher); `marketplace add` errors on an already-registered marketplace; and `plugin install` does not refresh the local marketplace clone before resolving, so a stale clone fails with a misleading "not found" — run `marketplace update` first.
4. **Smaller items** — `export HOME=/root` is hardcoded (use `: "${HOME:=/root}"`); `/var/log/...` is not writable as non-root and grows unbounded (use `${TMPDIR:-/tmp}`); set `"timeout": 120` in `settings.json`; exit early when the plugin is already installed; and note that a plugin installed during `SessionStart` is not active until `/reload-plugins`.
5. **To verify on the platform** — whether sandbox git can clone a *different* private repo than the session's own, and the actual flag set via `claude plugin install --help`.

The issue body carries a corrected script and the matching `settings.json` block.

Measured (2026-07-31): the reviewed artifact is not in this repository — there is no `scripts/session-start.sh`, and `.claude/settings.json` contains only `env` and `permissions`, no `SessionStart` hook. So this reviews a draft that was never committed, and no artifact here records a decision that this repository should ship a bootstrap hook at all. The nearest prior art is `20260730111600-a-stale-installed-plugin-now-offers.md`, which asks for a `SessionStart` version-mismatch check — a related but different job.

Registered from issue #126.
