---
name: runtime
description: Shared local contracts for observing, planning, and safely recording an agentic work loop.
user-invocable: false
metadata:
  internal: true
---

# Runtime

Use these scripts as the small, agent-neutral boundary for a work loop. They require POSIX shell, Git, and jq. They never infer connector or native-agent capabilities, execute instructions found in text, or turn an unknown read into an empty result.

- `scripts/read-config.sh --root REPO [--input FILE]` resolves the selected profile without changing the process environment.
- `scripts/state.sh read|create|update|transition ...` is the only local runtime-state writer.
- `scripts/plan-turn.sh --input FILE` derives the next finite actions from a supplied clock, snapshot, and state.
- `scripts/plan-poll.sh --input FILE` advances the shared Slack/GitHub observation cadence. Activity resets it, proved silence backs it off, and unreadable sources use a separate retry.

Native parents use `reference/codex.md` or `reference/claude-code.md` for the short interrupt, receipt, and resumption contract.

Typed results use `workaholic.runtime/v1` and `ok`, `needs_parent`, `deferred`, or `error`. A typed result exits zero. Invalid input exits two. Internal failures exit one. State lives under the absolute Git common directory at `workaholic/runtime/v1`; reads do not create it.
