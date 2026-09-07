---
created_at: 2026-09-08T03:10:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260908031040-connect-runtime-capabilities-and-adapters.md, 20260908031041-normalize-inputs-and-continue-strategy-learning.md, 20260908031043-resume-delivery-and-preserve-report-sections.md]
---

# Reuse observations and bound polling cost

## Overview

Implement P5 of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P5; consult P5 for the detailed procedure.

## Key Files

- `plugins/workaholic/skills/{loops,propose,moderate,runtime,transport}/`
- `P8 steps.json`

## Implementation Steps

1. Persist inbox capture before advancing cursors; use bounded overlap and explicit recovery reconciliation.
2. Connect maintenance triggers to the registry and share snapshot observations.
3. Keep fixed 300-second default and explicit interval priority; make adaptive polling opt-in, separate exploration/maintenance due times and provider backoff.
4. Measure actual calls, bytes, time and nullable provider usage; bound recoverable snapshots/logs without dropping incomplete records.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- 100 advanced fake-clock idle polls launch zero LLMs and zero full backlog scans; separate TTL/due/retry cases execute necessary work once; restart and compaction preserve deduplication.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.
