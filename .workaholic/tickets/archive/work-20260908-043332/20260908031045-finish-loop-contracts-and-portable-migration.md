---
status: done
created_at: 2026-09-08T03:10:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260908031036-pin-loop-contracts-and-package-nested-assets.md, 20260908031037-share-loop-snapshots-and-atomic-state.md, 20260908031038-unify-loop-transports-and-durable-outbox.md, 20260908031039-make-publication-and-claim-recovery-safe.md, 20260908031040-connect-runtime-capabilities-and-adapters.md, 20260908031041-normalize-inputs-and-continue-strategy-learning.md, 20260908031042-share-discovery-across-manual-entrypoints.md, 20260908031043-resume-delivery-and-preserve-report-sections.md, 20260908031044-reuse-observations-and-bound-polling-cost.md]
claim: work-20260908-043332
claim_unit: batch-20260908043329
---

# Finish loop contracts and portable migration

## Overview

Implement P9 of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P9; consult P9 for the detailed procedure.

## Key Files

- `CLAUDE.md`
- `README.md`
- `plugins/workaholic/{README.md,rules,commands,hooks,skills}/`
- `scripts/build-plugins/`
- `.github/workflows/`
- `docs/`

## Implementation Steps

1. Assign each execution decision one owner and replace H4 contradictions in current instructions.
2. Generate shared command fragments and make hooks adapters over writer-owned validators.
3. Replace obsolete prose pins with behavioral regressions while accounting for every moved test.
4. Verify all distribution forms, synchronized version sources and regenerated outputs.
5. Measure actual selected-path context and document migration, rollback and unverified live boundaries.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- Compatibility fixtures, full smoke, hermetic drills, metadata/build/freshness and docs build pass; retired behavior is absent from current instructions; live gaps remain explicit.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.
