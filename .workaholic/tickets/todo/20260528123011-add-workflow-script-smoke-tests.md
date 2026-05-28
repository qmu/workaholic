---
created_at: 2026-05-28T12:30:11+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Add Workflow Script Smoke Tests

## Overview

Add deterministic smoke tests for high-risk Workaholic workflow scripts. The current `verify.mjs` proves generated script references resolve, but it does not prove scripts behave correctly in realistic repositories. Add a small temp-repo test harness that exercises core script behavior without requiring real GitHub or production credentials.

## Key Files

- `scripts/build-plugins/verify.mjs` - Existing static reference verifier; can remain focused or call a new smoke-test helper.
- `scripts/build-plugins/README.md` - Should document the new verification command if one is added.
- `.github/workflows/dist-freshness.yml` - Candidate workflow for running generated-artifact verification and script smoke tests.
- `.github/workflows/validate-plugins.yml` - Candidate workflow if smoke tests are treated as plugin validation.
- `plugins/core/skills/drive/scripts/archive.sh` - High-risk script that mutates ticket state and commit metadata.
- `plugins/core/skills/branching/scripts/detect-context.sh` and `plugins/core/skills/branching/scripts/check-workspace.sh` - Branch and workspace routing scripts that affect every workflow.
- `plugins/core/skills/ship/scripts/extract-carryover.sh`, `pre-check.sh`, and `merge-pr.sh` - Shipping scripts that need mocked `gh` coverage rather than live GitHub calls.

## Related History

The repo already has a strong static generated-artifact check. This ticket adds behavior coverage for the scripts that static reference validation cannot cover.

Past tickets that touched similar areas:

- [20260527012301-build-step-for-self-contained-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260527012301-build-step-for-self-contained-portable-skills.md) - Added the build pipeline that makes scripts portable.
- [20260527142132-add-dist-freshness-ci-check.md](.workaholic/tickets/archive/work-20260518-235327/20260527142132-add-dist-freshness-ci-check.md) - Added CI checks for generated artifact freshness and static self-containment.
- [20260528091259-ship-deploy-doc-from-claude-md.md](.workaholic/tickets/archive/work-20260528-091259/20260528091259-ship-deploy-doc-from-claude-md.md) - Recently touched ship scripts and regenerated `dist/workflows`, showing how script changes propagate into generated artifacts.

## Implementation Steps

1. Add a small smoke-test runner, for example `scripts/build-plugins/smoke.mjs` or `scripts/test-workflow-scripts.mjs`, that creates temporary git repositories under `/tmp`.
2. Test branch/context scripts against representative states: `main`, `work-*`, legacy `drive-*`, and unknown branches.
3. Test `archive.sh` with a synthetic ticket and commit metadata. Assert the ticket moves to the expected archive path and frontmatter receives the expected commit fields.
4. Test `extract-carryover.sh` with a synthetic story file containing concerns. Use a mocked `gh` or avoid code paths that need live GitHub access; assert generated concern files and commit behavior.
5. Test shipping scripts that call `gh` with a controlled fake executable earlier in `PATH`, so CI does not require network or GitHub credentials.
6. Wire the smoke tests into CI after the existing build/verify steps.
7. Document how contributors run the smoke tests locally.

## Considerations

- Keep the smoke tests hermetic. They should not need network, real remotes, production deploy credentials, or a real GitHub token.
- Avoid making tests brittle against exact commit hashes or wall-clock timestamps unless the scripts explicitly promise those values.
- Test source scripts under `plugins/core/skills/**/scripts` first. If generated copies need separate coverage, run the same smoke helper after `node scripts/build-plugins/build.mjs` against `dist/workflows/skills/**`.
- The tests should create and clean their own temp repos. They must not mutate the developer's current `.workaholic/` state.
