---
created_at: 2026-09-08T03:10:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260908031040-connect-runtime-capabilities-and-adapters.md, 20260908031039-make-publication-and-claim-recovery-safe.md]
---

# Resume delivery and preserve report sections

## Overview

Implement P8 of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P8; consult P8 for the detailed procedure.

## Key Files

- `plugins/workaholic/skills/{drive,gather,ship,story,moderate}/`
- `H3 P8 delivery writer and steps.json`

## Implementation Steps

1. Bind release scan, checks and REST expected SHA to the pushed worktree head.
2. Persist waiting_checks and retry delivery even after already_current; defer unreadable checks while retaining explicit no_checks semantics.
3. Require merged evidence before cleanup; recover branch-independent unsent outbox.
4. Replace only bounded markdown sections; avoid identical PR PATCH and unknown-as-absent creation.
5. Register existing 33 maintenance steps in current order before P5 optimization; separate capture, acceptance, delivery and occurrence state.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- Catch-up/pending/next-tick-green merges without reimplementation; changed head refuses; report sections preserve each other; notifications remain recoverable after branch deletion.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.
