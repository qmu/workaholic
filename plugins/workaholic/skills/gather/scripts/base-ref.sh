#!/bin/sh -eu
# Resolve the base ref that "this branch" is measured against, for /report and
# release-scan. This is the SINGLE place the base is decided; every caller
# (git-context.sh, collect-commits.sh, scan-branch-safety.sh) asks here rather than
# re-deriving a `${1:-main}` default of its own.
#
# It prefers the remote-tracking ref `origin/<default-branch>`, for two reasons:
#   1. It equals what the PR is actually diffed against on GitHub.
#   2. It is IMMUNE to a local `main` that a primary checkout has pinned stale. On
#      the desk layout a worktree cannot move the `main` another worktree holds, so
#      local `main` is structurally behind `origin/main` — and diffing against it
#      narrates already-merged history and scans already-merged code (phantom commits,
#      phantom `secret` findings). Taking the base from the remote-tracking ref makes
#      that whole class unreachable.
#
# No network call — it resolves from refs already present (symbolic-ref / rev-parse),
# so it is safe to call inside the release-scan gate, whose verdict must not depend on
# connectivity. The caller is responsible for freshness (ship's catchup-main fetches);
# this script only decides which local ref to measure against.
#
# Output: the base ref on stdout (e.g. "origin/main"). Failure is LOUD, never a silent
# fallback to `main` (that silent fallback WAS the bug):
#   - origin configured but no remote-tracking ref yet (never fetched): exit 3 + stderr.
#   - no origin, no local main/master:                                   exit 4 + stderr.
#   - no origin but a local main/master exists: exit 0, stdout the local ref, and a
#     stderr NOTE — a visible fallback, so a local-only base is never taken silently.

set -eu

if git remote get-url origin >/dev/null 2>&1; then
    # Preferred: origin's default branch, resolved from the local remote-tracking refs.
    ref=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)
    if [ -z "$ref" ]; then
        # origin/HEAD may be unset (e.g. after a bare `git fetch`). Probe the usual names.
        for cand in origin/main origin/master; do
            if git rev-parse --verify --quiet "$cand" >/dev/null 2>&1; then
                ref="$cand"
                break
            fi
        done
    fi
    if [ -n "$ref" ] && git rev-parse --verify --quiet "$ref" >/dev/null 2>&1; then
        printf '%s\n' "$ref"
        exit 0
    fi
    echo "base-ref: origin is configured but has no remote-tracking ref to measure against (run: git fetch origin)" >&2
    exit 3
fi

# No 'origin' remote (a local-only repo, or a hermetic test). Fall back to a local
# default branch, but SAY SO — this is the visible fallback that replaces the old
# silent `BASE=main`.
for cand in main master; do
    if git rev-parse --verify --quiet "$cand" >/dev/null 2>&1; then
        echo "base-ref: no 'origin' remote; using local '$cand' as the base ref" >&2
        printf '%s\n' "$cand"
        exit 0
    fi
done

echo "base-ref: cannot resolve a base ref (no 'origin' remote, and no local main/master)" >&2
exit 4
