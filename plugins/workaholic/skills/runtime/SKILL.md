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
- `scripts/read-capabilities.sh --input FILE` selects `native`, `scheduler`, `supervisor`, or `once` from capabilities already observed by the parent.
- `scripts/state.sh read|create|update|transition ...` is the only local runtime-state writer.
- `scripts/plan-turn.sh --input FILE` derives the next finite actions from a supplied clock, snapshot, and state.
- `scripts/context-packet.sh --snapshot FILE --role ROLE [--unit ID]` emits only the evidence needed by one role.

Typed results use `workaholic.runtime/v1` and `ok`, `needs_parent`, `deferred`, or `error`. A typed result exits zero. Invalid input exits two. Internal failures exit one. State lives under the absolute Git common directory at `workaholic/runtime/v1`; reads do not create it.

