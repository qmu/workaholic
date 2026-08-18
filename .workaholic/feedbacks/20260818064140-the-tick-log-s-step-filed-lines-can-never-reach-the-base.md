---
type: Feedback
title: The tick log's step-filed lines can never reach the base
kind: concern
source: discussion
subject: observer_ai:[Housekeep] routine
created_at: 2026-08-18T06:41:40+00:00
author: a@qmu.jp
supersedes: 
---

# The tick log's step-filed lines can never reach the base

The `/housekeep` contract requires the agent to record what it filed under a second,
distinct step id — `<step>-filed` — and states that `log-read.sh` is how a later tick
answers *"did an earlier tick already file this?"*. Measured on tick `20260818-063819`:
those lines can never reach the base, so that dedup memory is permanently empty.

**The mechanism.** `run.sh` runs `persist-log.sh` as its closing act, after the ninth
step. The agent only acts on `needs_agent` *after* `run.sh` returns, so every
`<step>-filed` line is appended to the checkout **after** the persist has already run.
Re-running `persist-log.sh` by hand does not carry them either: the union is **by
section**, and it appends only the `## <tick-id>` sections the base is missing. The
section already landed with its nine probe lines, so the second call returned
`already_current` / `sections: 0` / `changed: false` — correct by its own rule, and
structurally unable to update a section that is already there.

**The consequence, in a routine container.** A hand-run never sees this: the checkout
survives, so the next `log-read.sh` finds the lines. A routine-fired tick is cloned
fresh from the base every hour, so it reads a log containing only probe lines. Every
dedup the design builds on that memory is inert:

- `doc-drift` re-reports `.workaholic/terms/retired-terms.md` every hour forever — the
  exact case its own section says dedup exists for ("counted and dropped").
- `inbound-sweep` cannot skip an item an earlier tick already filed.
- `human-checkin`'s `already_asked` gate and its held-question carry-forward
  (`human-checkin-held-<slug>`) are written by the agent after the persist too.

**Three forks, none obviously right, which is why this is a record first.**

1. **Persist twice** — once as the closing act, once after the agent's filing. Needs
   the union to update an existing section, not only add missing ones, which is a real
   change to the concurrency rule two containers depend on.
2. **Make the union merge lines within a section** — union by `(tick, step)` rather
   than by `(tick)`. Strictly more correct and strictly more code; conflicts stay
   append-only, so it does not reintroduce the rebase the design refused.
3. **Move the filing before the persist** — the agent files, then a separate closing
   call persists. Restructures the run contract and means `run.sh` no longer owns its
   own closing act.

The record names the fork rather than picking one, because the concurrency rule is
load-bearing and the choice is the operator's.

**A second, smaller finding from the same tick.** `feedback/scripts/create.sh`'s own
usage header lists `development` as a valid `source`, and the validator accepts only
`meeting|slack|discussion` — this record had to be filed as `discussion`. The header
and the `case` are one file apart and disagree.
