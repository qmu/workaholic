---
created_at: 2026-09-08T03:10:36+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260908031036-pin-loop-contracts-and-package-nested-assets.md]
claim: work-20260908-034255
---

# Share loop snapshots and atomic state

## Overview

Implement P2 of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P2; consult P2 for the detailed procedure.

## Key Files

- `plugins/workaholic/skills/{runtime,gather,drive,mission,strategy,loops}/`
- `H2 runtime schemas/store/config`

## Implementation Steps

1. Extract claim observations while preserving claims_scan TSV and legacy reader projections.
2. Reuse ownership and relation readers; enumerate missions and tickets once per compatible snapshot.
3. Implement revision/generation atomic state and pure plan-turn with fixed-clock tests.
4. Distinguish failed reads, empty queues, dirty contents, foreign claims and partial handoffs.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- Three consumers share one wide scan; only affected snapshots invalidate; legacy plan fields survive; unknown never becomes zero.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.
