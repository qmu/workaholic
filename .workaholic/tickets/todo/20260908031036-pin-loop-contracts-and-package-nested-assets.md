---
created_at: 2026-09-08T03:10:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: []
---

# Pin loop contracts and package nested assets

## Overview

Implement P1 of `docs/agentic-loop-redesign.md`, H3. The operator requested starting this redesign on 2026-09-08. Its H1 decisions and H2 boundaries are authoritative; the earlier foreground mission is complete. This ticket covers only P1; consult P1 for the detailed procedure.

## Key Files

- `scripts/build-plugins/{build,verify,script-ref-patterns}.mjs`
- `scripts/build-plugins/skill-dependencies.json`
- `docs/agentic-loop-contracts.md`
- `scripts/tests/agentic-loop/*.test.mjs`

## Implementation Steps

1. Capture H4 legacy CLI, JSON keys, stderr, exit codes and claims TSV separately from intentional B01–B20 repairs.
2. Reproduce B01 with nested helper, reference and schema consumers before changing the walker.
3. Compute recursive detected dependencies union explicit dependencies; validate targets and preserve both reference forms.
4. Build source, generated and standalone consumers; preserve full regeneration and orphan removal.

## Policies

- `development/policies/commit-change-history.md`: keep rationale, verification and handoff in the ticket and story.
- `implementation/policies/test.md`: regress observable failures, not implementation wording; retain meaningful existing coverage.
- `design/policies/vendor-neutrality.md`: preserve portable entry contracts and isolate provider dependencies.
- `development/policies/qa-engineering.md`: implementer owns the evidence and states unverified boundaries.

## Quality Gate

### Acceptance Criteria

- Nested helper/reference/schema consumers execute successfully; missing declared dependencies fail verification; baseline JSON keys and failure contracts remain pinned.
- H4 unchanged contracts remain compatible; intentional behavior repairs have named B-number regression evidence.

### Verification Method

Decided: use the H5 Node-standard hermetic fixtures with fake transports and fixed clocks; no new test framework or real credentials. Run relevant smoke labels and confirm positive executed counts. On unit completion run H5 full build, verify, metadata, smoke, layout, hermetic drills, docs build and diff checks. Record commands, counts and tested HEAD.

### Gate

Do not declare completion with failing relevant regressions. Record H5 real-environment checks separately; fake delivery and past PR #993 evidence do not discharge them.

## Considerations

- Dependencies are the actual H3 prerequisites, not numeric ordering. P1 is first.
- Merge policy remains unset (the existing reader defaults to review); no merge, deployment, Slack send or standing process is authorized by this plan publication.
- Preserve legacy wrappers and recoverable state. Record conversion, rollback reader, unfinished transaction locations and next unit under H6.

## Baseline Reproduction

On source HEAD `a41522ab3`, a throwaway build tree contained a target with only
`reference/nested/details.md` referencing a second skill through the supported
plugin-root script form. The dependency's source script exited 0 and printed
`nested-dependency-ok`. Running `node scripts/build-plugins/build.mjs fixture-target`
exited 1, reported `closure=[fixture-target]`, and rejected the unresolved
plugin-root path in `reference/nested/details.md`. The dependency script was absent
from the built target. Expected rewritten reference:
`../../fixture-dependency/scripts/value.sh`.

This reproduces B01 before implementation. Preserve it as an executable isolated
consumer regression in P1; the temporary local fixture is not a shipped test.
