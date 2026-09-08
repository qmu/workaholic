---
created_at: 2026-09-08T09:55:13+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
mission: reduce-loop-cost-and-adapt-observation-cadence
merge_policy: review
depends_on: [20260908095512-reduce-first-tick-context-and-canonical-volume.md]
---

# Adapt inbound observation cadence

## Overview

After the volume reduction, make observation feel like a person keeping the inbound surfaces open:
recent Slack activity or a new assigned feedback issue earns short checks, while continued silence
gradually backs off to the declared maximum. Use inactivity rather than a hard-coded night schedule
so the same behavior follows each workspace's real rhythm.

## Key Files

- `plugins/workaholic/skills/runtime/scripts/{read-config,plan-poll}.sh`
- `plugins/workaholic/skills/work/scripts/codex-loop.sh`
- `plugins/workaholic/commands/infinite-development.md`
- `scripts/tests/agentic-loop/polling-cost.test.mjs`

## Implementation Steps

1. Observe Slack and assigned feedback issues, then derive the next interval from activity and consecutive quiet observations.
2. Persist only the evidence required to resume the cadence after restart; keep retry deadlines authoritative.
3. Let the Codex supervisor wake on the derived boundary and give Claude's native parent the same plan.
4. Prove rapid activity response, gradual idle backoff, restart continuity, and min/max bounds with a fake clock.

## Policies

- `design/policies/vendor-neutrality.md`: keep cadence in the shared runtime contract and adapters agent-specific.
- `implementation/policies/recover-from-the-edge.md`: persist enough state to resume without mistaking absence for silence.
- `operation/policies/runtime-behavior.md`: bound polling and preserve provider retry deadlines.

## Quality Gate

### Acceptance Criteria

- A new human Slack input or assigned feedback issue selects the configured conversation interval and makes its handling due.
- Successive quiet observations increase the interval gradually up to the configured maximum, and new activity resets it.
- Claude Code and Codex consume the same cadence fields and neither launches an LLM for a cached idle boundary.

### Verification Method

Use fixed-clock tests over activity, silence, restart, provider retry, and bounds. Run the complete
validation set after regeneration and report the final canonical LOC and prompt-byte deltas.

### Gate

Do not add a second clock, provider-specific scheduler, or time-zone rule when activity evidence
already expresses whether a human is present.

## Considerations

An unreadable inbound source remains unreadable and must not lengthen the interval as though every
source were quiet. Explicit fixed mode and an explicit interval continue to take priority.
