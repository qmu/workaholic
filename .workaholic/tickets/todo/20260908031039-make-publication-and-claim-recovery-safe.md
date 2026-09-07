---
created_at: 2026-09-08T03:10:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260908031037-share-loop-snapshots-and-atomic-state.md]
---

# Make publication and claim recovery safe

## Overview

Implement P7a of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P7a; consult P7 for the detailed procedure.

## Key Files

- `plugins/workaholic/skills/branching/scripts/{open-publish-tree,publish-tree-pr,publish-tree-commit,close-publish-tree}.sh`
- `plugins/workaholic/skills/drive/scripts/{claim,claim-arbitrate}.sh`

## Implementation Steps

1. Implement the P7 publication transaction before enabling concurrent runtime publication.
2. Preserve clean unpublished commits and resume the same transaction/SHA/branch after push failure.
3. Keep PR lookup unknown separate from successful absence.
4. Acquire stable-order arbiters, re-fetch overlap while held, and release only receipt-owned SHAs using compare-and-delete.
5. Retain degraded arbitration and initialize claim liveness with recoverable post-push failure.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- Throwaway repos prove concurrent publication, failed-push resumption, unknown lookup and arbiter races; stale cleanup cannot delete a new owner lock.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.
