---
created_at: 2026-09-08T03:10:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260908031038-unify-loop-transports-and-durable-outbox.md, 20260908031039-make-publication-and-claim-recovery-safe.md]
claim: work-20260908-043332
claim_unit: batch-20260908043329
---

# Connect runtime capabilities and adapters

## Overview

Implement P4 of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P4; consult P4 for the detailed procedure.

## Key Files

- `plugins/workaholic/skills/{work,loops,runtime,workaholify}/`
- `plugins/workaholic/commands/{work,infinite-development}.md`
- `scripts/codex-loop.sh`

## Implementation Steps

1. Implement H2 capability selection and native/CLI adapters without model or permission overrides.
2. Connect supervisor planning to plan-turn; share atomic fork-before-dispatch ownership including no-flock systems.
3. Preserve original worker outcomes and typed retry counters; validate intervals before effects; keep dry-run pure.
4. Preserve legacy status/relay contracts and explicit state migration; retain anchored interruptible native cadence.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- Contract fixtures cover both adapters, long workers, restart, PID reuse, duplicate dispatch and stop; real native interruption and automatic reports require separate H5 evidence.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.
