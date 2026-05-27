---
created_at: 2026-05-27T14:21:32+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort:
commit_hash:
category:
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
