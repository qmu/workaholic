---
created_at: 2026-05-27T14:21:32+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 0.5h
commit_hash: 0fddd5b
category: Added
depends_on: [20260527142130-relocate-cross-agent-output-into-dist.md]
---

# Add a CI freshness check so `dist/` cannot drift from `plugins/`

## Overview

Now that `dist/` is committed and generated from `plugins/`, the committed artifacts can silently rot whenever a `core` skill or its script closure changes without a rebuild — exactly the failure mode the redesign set out to eliminate. Add a CI check that regenerates `dist/` and fails if the working tree differs from the committed output, guaranteeing source and artifact stay in lockstep.

## Key Files

- `.github/workflows/` - add (or extend) a workflow that runs the build and asserts a clean diff
- `tools/build-portable-skills/build.mjs` - invoked by CI (full default build)
- `tools/build-portable-skills/verify.mjs` - invoked by CI (reference resolution)

## Implementation Steps

1. Add a CI job that runs `node tools/build-portable-skills/build.mjs` followed by `node tools/build-portable-skills/verify.mjs`.
2. After the build, assert no uncommitted changes with `git diff --exit-code dist/` (and any other generated path, e.g. `.agents/plugins/marketplace.json` if the build writes it). A non-empty diff fails the job with a message telling the contributor to rebuild and commit `dist/`.
3. Trigger the workflow on pull requests and pushes that touch `plugins/`, `tools/build-portable-skills/`, or `dist/`.
4. Document the one-line local equivalent (`node tools/build-portable-skills/build.mjs && git diff --exit-code dist/`) so contributors can self-check before pushing.

## Considerations

- This is the guard CLAUDE.md already flagged as "a sensible follow-up"; once it exists, update that note in the docs ticket.
- Keep the build deterministic (stable file ordering, no timestamps in output) so the diff check is not flaky (`tools/build-portable-skills/build.mjs`).
- The check must run on the same Node version contributors use locally to avoid spurious diffs.

## Final Report

Development completed as planned, plus a fix outside the original scope. Verified locally: the freshness check passes when in sync, and a negative test (edit a source skill → rebuild → `git diff` shows `dist/` diverging → restore → clean) confirms drift is actually caught.

### Discovered Insights

- **Insight**: T2's `workflows` marketplace entry (`source: ./dist/workflows`) silently invalidated an existing `validate-plugins.yml` step that asserted `plugins/<name>` exists for every marketplace plugin. Fixed it to resolve each plugin's declared `source` instead.
  **Context**: Any future plugin whose source is generated (under `dist/`) rather than authored (under `plugins/`) now passes validation; assuming `plugins/<name>` is no longer safe anywhere in CI.
- **Insight**: The freshness check must call `node build.mjs` with **no arguments** — a targeted build only writes the throwaway scratch dir and never touches `dist/`, so `git diff --exit-code dist/` would pass vacuously. This requirement is encoded as a comment in the workflow.
  **Context**: Carries forward the T1 insight about argument-less vs targeted builds into the CI definition.
