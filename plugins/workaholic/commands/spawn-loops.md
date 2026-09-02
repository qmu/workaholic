---
name: spawn-loops
description: Start the local development loops — one tmux session per loop (propose every 5 minutes, implement every 5 minutes, moderate every 30), each a Claude Code session running /loop in its own clone of this repository. Idempotent; reports what it spawned, what was already running, and every refusal by name.
skills:
  - workaholic:loops
---

# Spawn Loops

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/spawn-loops.sh` from this checkout and
report its output: per loop the tmux session, the clone path, the interval, the prompt `/loop`
repeats, and the state — `spawned`, `already_running`, or a refusal by name (`no_tmux`,
`no_claude`, `no_repo_url`, `clone_failed`, `fetch_failed`, `tmux_failed`). `no_tmux` names the
fallback: the Claude Code Web routines through `/setup-dev-routines` and
`/setup-repo-routines`.

Then run `bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/loop-status.sh` once and show each
session's last pane lines, so the person can see the first turn start.

**Say once**: if a Claude Code Web routine for this repository is still enabled on the account,
the two premises are running against one inbox — the dedups hold but every fire is waste — and
that routine should be disabled (`workaholic:loops`, *The fallback*). This command cannot see
another account's routines and does not try.

It asks nothing, writes nothing into the repository, and opens no pull request. Stopping is
`bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/stop-loops.sh`, a script a person runs.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
