---
created_at: 2026-07-22T20:00:01+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
---

# Fetch origin before resolving the mission-worktree base commit

## Overview

`create-mission-worktree.sh` resolves the base branch (default `main`) to a commit SHA by preferring the local ref. When the local `main` trails `origin/main`, the worktree is cut from the stale local base: a mission worktree created this way cannot see already-merged PRs or the rulings recorded in `origin/main`'s mission.md, producing duplicate work that later needs a unification merge. The script never fetches `origin` and never compares local freshness against the remote, so a desk whose local `main` is behind silently gets a stale base. The `/mission` replan path also does not surface open PRs touching the same mission, so a lane cannot notice a sibling already implementing the same acceptance.

## Policies

- operation — delivery starts from the merged base, not a stale local ref.
- implementation — fail loud when the remote base cannot be resolved rather than falling back silently.

## Implementation

1. In `create-mission-worktree.sh`, before resolving the base SHA, run `git fetch origin <base>`. Fail loud with a JSON error when `origin` is unreachable — never silently fall back to a stale local ref.
2. Resolve the base to `origin/<base>` as the source of truth; use the local ref only when no `origin/<base>` exists (fresh clone / offline, explicitly surfaced).
3. At `/mission` replan, surface open PRs whose branch or story touches the same mission slug, so a session sees a sibling implementation before duplicating it.

## Test Plan

- With a local `main` several commits behind `origin/main`, create a mission worktree and assert its base contains the origin-only commits.
- Simulate an unreachable `origin` and assert the script exits non-zero with a fetch-failure JSON, creating no worktree.
- Confirm an up-to-date checkout still creates the worktree unchanged.

## Quality Gate

- `create-mission-worktree.sh` never resolves a base older than `origin/<base>` without loudly reporting why.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: Distinguishing "origin unreachable" from "origin reachable but has no `<base>` ref" needs two probes, not one. A targeted `git fetch origin <base>` returns non-zero for *both* cases, so a bare fetch-failure test would wrongly hard-fail a legitimately local-only base branch. The fix: on fetch failure, probe reachability separately with `git ls-remote --exit-code origin` — unreachable → fail loud, reachable-but-missing-ref → surfaced local fallback.
  **Context**: The ticket's step 1 ("fail loud on unreachable") and step 2 ("local ref only when no origin/<base> exists") are only reconcilable by keeping these two axes separate; collapsing them regresses one or the other.

- **Insight**: Preferring `origin/<base>` first is the actual fix, not the fetch alone. The prior code fetched nothing *and* preferred the local ref first; even after adding a fetch, leaving the local-ref-first ordering would still cut from a stale base whenever a stale local ref existed. Both changes are load-bearing.
  **Context**: The regression test forces exactly this — local `main` pinned behind a fresh `origin/main` — and asserts the worktree parents off `origin/main`, so a future reordering back to local-first fails loudly.

- **Insight**: An unreachable *configured* origin now hard-blocks mission-worktree creation (no offline escape hatch). This is deliberate per the ticket (fail-loud over silent-stale) but is a real usability trade-off — a genuinely offline developer with a remote cannot cut a mission worktree until origin is reachable.
  **Context**: If this bites in practice, the sanctioned relaxation is a loud local fallback (stderr note + proceed) rather than silent stale reuse — which still satisfies the quality gate's "without loudly reporting why" clause. Left as fail-loud to honor the ticket's explicit Test Plan.
