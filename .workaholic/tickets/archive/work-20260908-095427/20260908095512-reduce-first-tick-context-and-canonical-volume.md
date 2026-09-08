---
created_at: 2026-09-08T09:55:12+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
mission: reduce-loop-cost-and-adapt-observation-cadence
merge_policy: review
depends_on: []
---

# Reduce first-tick context and canonical volume

## Overview

Issue #1084 records that the first Codex tick consumed about 25% of its context window and that
the redesign grew canonical code despite reduction being an explicit axis. Remove duplicated
operative instructions, unused runtime surfaces, and implementation-shaped tests before adding
new cadence behavior.

## Key Files

- `plugins/workaholic/skills/work/`
- `plugins/workaholic/commands/infinite-development.md`
- `plugins/workaholic/skills/{runtime,loops}/`
- `scripts/tests/agentic-loop/` and `scripts/test-workflow-scripts.mjs`

## Implementation Steps

1. Measure the files and prompt paths loaded by the first Claude Code and Codex tick.
2. Give each operative rule one short owner and delete duplicated history or unreachable runtime APIs.
3. Replace prose-shape assertions with the smallest behavioral coverage required at surviving boundaries.
4. Report byte, line, and selected-path context deltas against current main.

## Policies

- `implementation/policies/test.md`: retain behavioral evidence and remove tests that mirror prose or implementation shape.
- `design/policies/progressive-disclosure.md`: load only the instructions required for the current tick.
- `development/policies/qa-engineering.md`: measure the reduction and keep unresolved live behavior explicit.

## Quality Gate

### Acceptance Criteria

- Canonical source has a negative net line delta and the first-tick instruction path has a negative byte delta.
- Claude Code and Codex still answer the channel, dispatch due work once, and report a typed outcome.

### Verification Method

Measure with `wc`, run focused loop tests, then run plugin build, generated-output verification,
metadata validation, workflow smoke tests, agentic-loop tests, and hermetic drills.

### Gate

Do not trade a smaller prompt for duplicated state ownership or an unknown-as-success fallback.

## Considerations

The target is deletion of work, not compression of the same work into opaque syntax. Generated
workflow copies are reported separately from canonical source.
