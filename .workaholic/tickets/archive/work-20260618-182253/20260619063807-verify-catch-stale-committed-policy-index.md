---
created_at: 2026-06-19T06:38:07+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 0.5h
commit_hash: 00287ab
category: Changed
depends_on:
---

# Make `verify.mjs` catch a stale *committed* `hooks/policy-index.md`, not just a freshly-rebuilt one

## Overview

The always-loaded four-pillar policy index (`plugins/workaholic/hooks/policy-index.md`, injected on every workflow turn by `hooks/policy-lens.sh`) is generated from the four pillar `SKILL.md` `## Policies` sections by `scripts/build-plugins/policy-index.mjs`. The `workaholic-standards-sync` controller now regenerates this digest inside each sync PR (re-running this repo's own generator against its fresh clone, so its output is byte-identical to `node scripts/build-plugins/build.mjs`), which closes the drift for the automated path.

But the **CI freshness guard has a blind spot for the committed file**. In `.github/workflows/outputs-freshness.yml` the job runs `build.mjs` (which *rewrites* `policy-index.md` on disk) and then `verify.mjs`. `verify.mjs`'s policy-index check reads the file **on disk** and compares it to `generatePolicyIndex(REPO_ROOT)` — but `build.mjs` just freshened that file, so the check always passes regardless of what was committed. The subsequent "Assert outputs/ matches committed output" step only diffs `outputs/`, and `policy-index.md` lives under `plugins/`, not `outputs/`. Net: a PR that edits a `## Policies` bullet by hand (or any non-controller path) but forgets to regenerate the committed `policy-index.md` would **pass CI green while shipping a stale always-loaded index** — exactly the silent drift the index was meant to avoid.

This is the residual half of `workaholic-standards-sync`'s ticket `20260619011105-always-loaded-policy-index-digest` (controller-side regeneration), filed here because the fix lives in this repo's CI/verify layer.

## Key Files

- `scripts/build-plugins/verify.mjs` - The policy-index freshness check (near the end) compares the on-disk file to a fresh regeneration. Because `build.mjs` runs first in CI, "on-disk" is already fresh. The check needs to compare against the **git-committed** content (e.g. `git show HEAD:plugins/workaholic/hooks/policy-index.md`, or run before `build.mjs`), not the working-tree file.
- `.github/workflows/outputs-freshness.yml` - Orders `build.mjs` then `verify.mjs`; the `git diff --exit-code -- outputs/` assertion covers only `outputs/`. Either widen that diff to include `plugins/workaholic/hooks/policy-index.md`, or have `verify.mjs` itself fail on a stale committed index.
- `scripts/build-plugins/policy-index.mjs` - `generatePolicyIndex(repoRoot)` / `POLICY_INDEX_REL`; the single canonical generator both `build.mjs` and `verify.mjs` (and the sync controller) import. Do not add a second generator.

## Related History

- `workaholic-standards-sync` ticket `20260619011105-always-loaded-policy-index-digest.md` - The controller-side regeneration that this ticket complements. The controller keeps the *automated* sync PR fresh; this ticket keeps *every* PR honest.
- `hooks/policy-lens.sh` (this repo) - Injects `policy-index.md` as the bounded "embed the index, refer for bodies" exception. A stale index silently weakens that lens.

## Implementation Steps

1. **Decide the guard surface.** Either (a) make the `outputs-freshness.yml` "assert no drift" step also diff `plugins/workaholic/hooks/policy-index.md` (simplest, mirrors the `outputs/` assertion), or (b) make `verify.mjs` compare the **committed** index (`git show HEAD:<POLICY_INDEX_REL>`) to `generatePolicyIndex(REPO_ROOT)` so it fails independent of `build.mjs` run order. Prefer (a) if you want one consistent "regenerate and commit" message; prefer (b) if `verify.mjs` should be self-contained.
2. **Implement** the chosen guard. Keep using the single canonical generator — no second copy of the digest logic.
3. **Verify** by committing a deliberately stale `policy-index.md` (e.g. delete one bullet) on a scratch branch and confirming CI now fails with an actionable "run `node scripts/build-plugins/build.mjs` and commit" message; then regenerate and confirm green.

## Considerations

- **Don't double-regenerate-and-pass.** The core bug is that regenerating before checking masks staleness. Whichever approach is chosen, the check must reflect the *committed* bytes.
- **Keep one generator.** `build.mjs`, `verify.mjs`, and the `workaholic-standards-sync` controller all import `generatePolicyIndex` from `policy-index.mjs`. The fix must not introduce a parallel implementation.
- **Scope.** Small CI/verify hardening; no runtime or plugin-behavior change. The always-loaded injection, the generator, and the `/drive` policy-lens marker are already in place — this only closes the freshness blind spot.

## Final Report

Development completed as planned. Chose option (a) from Implementation Step 1: the authoritative committed-bytes guard is the `git diff` in `outputs-freshness.yml`, now extended to cover `plugins/workaholic/hooks/policy-index.md` alongside `outputs/`. `verify.mjs`'s working-tree check was kept (it catches a `## Policies` edit that forgot to rebuild when verify runs before build) with an honest comment; the inaccurate CLAUDE.md claim ("`verify.mjs` fails if the committed index is stale") was corrected to point at the CI guard.

### Discovered Insights

- **Insight**: The root cause is build-before-check ordering. `outputs-freshness.yml` runs `build.mjs` (which rewrites the on-disk `policy-index.md`) before `verify.mjs` reads it, so any check that reads the working-tree file passes vacuously. The only reliable committed-bytes guard in this pipeline is the post-build `git diff`, because `git diff` compares the rebuilt working tree against the committed index. This is exactly why `outputs/` is guarded by `git diff`, not by a `verify.mjs` internal check — the same pattern had to be extended to the index rather than reinvented.
  **Context**: Any future "freshness" check for a generated-and-committed artifact must be a post-build `git diff` over that path, not an in-process file read, or it will be masked by the regenerate step. Reading committed bytes via `git show HEAD:<path>` inside `verify.mjs` was the alternative (option b) but has poor local ergonomics — it would fail on the normal "regenerated but not yet committed" pre-commit state.
- **Insight**: `policy-index.md` is the first generated-and-committed artifact that lives **outside** `outputs/`, so it had to be named explicitly in the diff assertion — the existing `git diff -- outputs/` silently excluded it. Anything else build.mjs ever emits outside `outputs/` will have the same blind spot until added to that diff list.
  **Context**: Verified the guard end to end locally: a dropped bullet in the committed index yields `git diff --exit-code` = 1 (CI red); a rebuild yields 0 (green).
