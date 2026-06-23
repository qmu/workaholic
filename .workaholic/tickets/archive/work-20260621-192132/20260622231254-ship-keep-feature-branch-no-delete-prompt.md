---
created_at: 2026-06-22T23:12:54+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: d1730ac
category: Changed
depends_on:
---

# `/ship`: keep the feature branch on merge — stop prompting to delete the remote branch

## Overview

When `/ship` merges a PR, `merge-pr.sh` runs `gh pr merge "$pr_number" --merge` with **no** branch-deletion flag. Because neither `--delete-branch` nor `--no-delete-branch` is specified, `gh` falls back to its interactive **"Delete the branch?"** prompt after a successful merge — so every successful ship nags the developer about removing the remote feature branch. We never delete feature branches on merge, so this prompt is pure friction (and one wrong keystroke deletes a branch we wanted to keep).

**Fix:** pass `--no-delete-branch` explicitly. That makes the intent unambiguous — `gh` keeps both the remote and local branch and **does not prompt**. One-line change in `merge-pr.sh`.

## Key Files

- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` - PRIMARY. Line 15: change `gh pr merge "$pr_number" --merge` to `gh pr merge "$pr_number" --merge --no-delete-branch`. Nothing else in the script changes (it still checks out and pulls `main` and returns the merge JSON).
- `outputs/workflows/skills/ship/ship/scripts/merge-pr.sh` - GENERATED. `ship` is in the cross-agent build, so regenerate `outputs/` and commit it.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - OUT OF SCOPE / reference. The Trip Ship flow's `cleanup-worktree.sh` (step 3) deliberately removes the *worktree and its branch* after a trip merge — that is the intended trip lifecycle, not the regular-ship prompt being fixed here. Do not change it.
- `scripts/test-workflow-scripts.mjs` - Reference only. `merge-pr.sh` calls `gh` (network), so it is not in the hermetic suite; no test change. Confirm the suite still passes.

## Related History

- The ship reorder work (`work-20260617-231848`, deploy-confirm-before-merge) established `merge-pr.sh` as the merge-last step; this only adjusts the `gh` flags it passes, not the ordering.

## Implementation Steps

1. **Add `--no-delete-branch`** to the `gh pr merge` invocation in `merge-pr.sh` (line 15): `gh pr merge "$pr_number" --merge --no-delete-branch`. Leave the failure handling, `git checkout main` / `git pull origin main`, and the JSON output untouched.
2. **Regenerate and verify**: `node scripts/build-plugins/build.mjs` (regenerates `outputs/workflows/skills/ship/ship/scripts/merge-pr.sh`; commit it), then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs` (all green; merge-pr.sh is not hermetically tested).
3. **Confirm** the generated `outputs/` copy carries the new flag, and `git status outputs/` shows only the expected `merge-pr.sh` regeneration.

## Considerations

- **Implementation is the binding lens** (`workaholic:implementation`): Config/script work — `directory-structure` (edit `plugins/`, regenerate `outputs/`), `coding-standards`/shell (keep the script POSIX-clean; this is a single-flag addition, no new logic).
- **`--no-delete-branch` is the right lever, not script logic.** It both prevents deletion AND suppresses the prompt in one flag — no conditional, no inline branching. Do not try to detect/answer the prompt; just declare the intent.
- **Regenerate `outputs/`.** `merge-pr.sh` ships cross-agent inside the built `ship` skill, so the generated copy must be rebuilt and committed or the Outputs Freshness CI fails.
- **Trip worktree cleanup stays as-is.** `cleanup-worktree.sh` removing a trip's worktree+branch after merge is intentional trip lifecycle and is a different concern from the regular-ship prompt; this ticket does not touch it.
- **No version bump implied**; a patch bump happens at `/report`/release time.

## Final Report

Development completed as planned — a single flag (`--no-delete-branch`) on the `gh pr merge` call, plus the `outputs/` regeneration. No other change.

### Discovered Insights

- **Insight**: The nagging prompt was never workaholic's own `AskUserQuestion` — it was `gh pr merge` falling back to its interactive "Delete the branch?" prompt because `merge-pr.sh` specified a merge method (`--merge`) but no branch-deletion flag. Declaring the intent with `--no-delete-branch` is the fix; there is nothing in the skill prose to change.
  **Context**: When a bundled script wraps an external CLI (`gh`, `git`), unspecified flags can surface that tool's own interactive prompts inside the workflow. The defensive habit is to pin every decision flag the wrapped command exposes (merge method AND branch disposition), so the script is fully non-interactive regardless of the caller's TTY.
- **Insight**: This is the regular-ship path only. The Trip Ship flow intentionally removes a trip's worktree+branch via `cleanup-worktree.sh` after merge — a separate, deliberate lifecycle that this change leaves alone. "We don't remove feature branches" applies to the normal merge, not to ephemeral trip worktrees.
  **Context**: Anyone later trying to make ship "stop deleting branches" globally should not touch the trip worktree cleanup — conflating the two would break the trip lifecycle.
