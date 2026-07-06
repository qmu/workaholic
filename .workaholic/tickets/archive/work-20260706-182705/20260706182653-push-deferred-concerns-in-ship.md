---
created_at: 2026-07-06T18:26:53+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 0.5h
commit_hash: b724380
category: Changed
depends_on:
---

# Push Deferred-Concern Commits in the Ship Flow

## Overview

`extract-deferred-concerns.sh` (ship flow step 8) commits the extracted `.workaholic/concerns/*` files but never pushes. Because the step runs **post-merge** — `merge-pr.sh` has already `git checkout main` — the commit lands on **local `main`** and stays there, leaving local `main` one commit ahead of `origin/main` after every `/ship` whose story had active section-6 concerns. The concerns then never reach `origin/main` on their own (other developers don't see them; they survive only if the developer's next feature branch, cut from that local main, happens to carry them — fragile, lost on a fresh clone or `git reset --hard origin/main`). The sibling `commit-release-note.sh` already commits-and-pushes with a guarded `git push`; this ticket brings the extract script into line so `/ship` reliably ends on `main` level with `origin/main`.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — style/shell conventions; the push must stay POSIX `#!/bin/sh -eu` and non-blocking (`|| true`), matching the sibling script.
- `workaholic:operation` / delivery policies — the fix is a delivery-path defect: written knowledge (deferred concerns) was not reaching production `main`/the team. The change makes the ship path deliver what it records.

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - commits the concern files post-merge; add a guarded `git push` after the commit (line ~161).
- `plugins/workaholic/skills/ship/scripts/commit-release-note.sh` - sibling precedent: `git commit` immediately followed by `git push >/dev/null 2>&1 || true` (line ~33).
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` - establishes that step 8 runs while `main` is checked out (`git checkout main`), which is why the commit needs a push.
- `plugins/workaholic/skills/ship/SKILL.md` - §2-5 and Ship Flow step 8 prose must state the push and the "end level with origin/main" outcome.
- `scripts/test-workflow-scripts.mjs` - existing `extract-deferred-concerns` block (~line 778) to extend with the regression assertion.
- `outputs/workflows/skills/ship/...` - generated copies; regenerate via `build.mjs` (CI Outputs Freshness gate fails on drift).

## Related History

This complements the recent "Enforce ship catch-up and reconcile with main" change (`52c009f`), which made catching **up** with `origin/main` mandatory *before* deploy; this ticket fixes the symmetric *after*-merge gap where a post-merge commit was not propagated back to `origin/main`. The fix mirrors the established commit-and-push pattern already used by `commit-release-note.sh` in the same skill.

## Implementation Steps

1. Add a guarded push to `extract-deferred-concerns.sh` after the concern commit — `git push >/dev/null 2>&1 || true`, inside the existing `NO_COMMIT` guard so the test path that skips committing also skips pushing. (Done this session.)
2. Update `ship/SKILL.md` §2-5 and Ship Flow step 8 so the prose states the commit lands on local `main` post-merge and is pushed, keeping local `main` level with `origin/main`. (Done this session.)
3. Regenerate `outputs/` with `node scripts/build-plugins/build.mjs`. (Done this session.)
4. **Extend `scripts/test-workflow-scripts.mjs`**: add a hermetic assertion in the `extract-deferred-concerns` block that, after the script runs against a repo with a bare `origin` remote, `origin/main` equals local `main` (the concern commit was pushed). (Remaining — this is the drive work.)
5. Run `build.mjs`, `verify.mjs`, and `test-workflow-scripts.mjs`; confirm all green.

## Quality Gate

**Acceptance criteria:**
- After `extract-deferred-concerns.sh` runs against a repo with a bare `origin` remote and a story carrying ≥1 section-6 concern, `git rev-parse origin/main` equals `git rev-parse main` (the commit was pushed — local `main` is not ahead of origin).
- The push is non-fatal: with no reachable remote, the script still exits 0 and returns its normal `{"status":"ok",...}` JSON (guarded `|| true`).
- `ship/SKILL.md` §2-5 and step 8 describe the push and the "end level with origin/main" outcome; the committed `outputs/workflows` copies match source.

**Verification method:**
- New hermetic assertion in `scripts/test-workflow-scripts.mjs` (bare-remote scratch repo) covering both the push-happened and no-remote-still-ok criteria.
- `node scripts/build-plugins/build.mjs` regenerates `outputs/` with no unexpected diff; `node scripts/build-plugins/verify.mjs` clean; `node scripts/test-workflow-scripts.mjs` all green.

**Gate:**
- The full smoke suite is green (including the new assertion), `outputs/` is fresh (Outputs Freshness would pass), the script stays POSIX `#!/bin/sh -eu`, and the SKILL prose matches the script.

## Considerations

- Keep the push **inside** the `NO_COMMIT` guard so hermetic tests that set `NO_COMMIT` neither commit nor attempt a push (`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`).
- `|| true` is deliberate — a push failure (offline, no upstream) must not fail the ship after the merge already succeeded; the commit is still local and recoverable (matches `commit-release-note.sh`).
- Do not disturb the load-bearing merge-last ordering or the post-merge step sequence (`merge-pr.sh` → `publish-release.sh` → `extract-deferred-concerns.sh`).

## Final Report

Development completed as planned. Added the guarded `git push` after the concern commit (inside the `NO_COMMIT` guard), updated `ship/SKILL.md` §2-5 and Ship Flow step 8 to state the push and the "end level with origin/main" outcome, regenerated `outputs/`, and pinned the behavior with a new hermetic smoke test (bare-remote push scenario + no-remote graceful no-op). `build.mjs`, `verify.mjs`, and `test-workflow-scripts.mjs` (295 passed, +5 new assertions) all green.

### Discovered Insights

- **Insight**: The defect existed because a sibling script (`commit-release-note.sh`) carried the commit-and-push pattern while `extract-deferred-concerns.sh` had only the commit half, and no test pinned the push — the missing regression test is what let a commit-without-push ship silently.
  **Context**: The fix therefore isn't just the one-line push; it's the push plus a hermetic assertion (`origin/main == main` after extract) so the two sibling scripts can't drift apart again. The push had to stay inside the existing `NO_COMMIT` guard so the older dedup test (which sets `NO_COMMIT`) neither commits nor pushes.
