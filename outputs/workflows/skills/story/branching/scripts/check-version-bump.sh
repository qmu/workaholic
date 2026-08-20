#!/bin/sh
# Check if a "Bump version" commit already exists in the current branch
# Usage: check-version-bump.sh [<base-ref>]
# Output: JSON — {ok, already_bumped, base, reason}
#
# THE BASE IS RESOLVED, NEVER DEFAULTED TO LOCAL `main` (2026-08-18). This asks
# "has THIS branch already bumped?", so the answer is only as good as the ref the
# range starts at. `git log main..HEAD` read the LOCAL `main`, which in a claim
# worktree is whatever the container's checkout happened to have — the claim branch
# is cut from origin/main and nothing on the drive path moves local `main`. The
# stale range then swept up every `Bump version to vX` that had landed on the base
# since, and the script answered `already_bumped: true` for a branch carrying no
# bump. Measured 2026-08-18 in worktree batch-20260818063646: local `main` at
# 6e0cb9e9 against origin/main at a871103d, hundreds of commits apart.
#
# The failure is one-directional and silent: a stale base can only ever produce the
# FALSE `true` — the answer that SKIPS the bump and ships plugin changes on a stale
# version. There is no symmetric case where it wrongly forces one. So the resolution
# is the single one every other base-reading script uses (gather/scripts/base-ref.sh,
# which prefers origin/<default> and fails loudly rather than falling back), and a
# base this script cannot resolve is reported by name — never answered as `true`.
#
# IT READS, IT DOES NOT FETCH (the ticket's Open Decision 1, resolved here). This is
# a predicate called from inside a worktree; a network call in a predicate is a new
# failure mode for each of its callers, and base-ref.sh is deliberately offline for
# the same reason. Freshness is the caller's act and already happens upstream —
# /drive's sync-main.sh fetches before surveying, and the claim's worktree is cut
# from a just-fetched origin/main. What this script guarantees is that it measures
# against the remote-tracking ref as last fetched and SAYS which ref that was, so a
# caller that skipped its fetch can see what the answer rests on.

set -eu

SCRIPT_DIR=$(dirname "$0")

emit() {
  cat <<EOF
{
  "ok": $1,
  "already_bumped": $2,
  "base": "$3",
  "reason": "$4"
}
EOF
}

if [ "$#" -ge 1 ] && [ -n "$1" ]; then
  BASE="$1"
else
  BASE=$("${SCRIPT_DIR}/../../gather/scripts//base-ref.sh" 2>/dev/null) || BASE_STATUS=$?
  if [ -z "${BASE:-}" ]; then
    # base-ref.sh's own exit vocabulary: 3 = origin configured but never fetched,
    # 4 = no origin and no local main/master. Degraded either way, and degraded
    # answers `false`: bumping when unsure is a no-op commit a human can drop,
    # while skipping one ships plugin changes on a stale version.
    case "${BASE_STATUS:-1}" in
      3) REASON="base_never_fetched" ;;
      4) REASON="no_base_ref" ;;
      *) REASON="base_unresolved" ;;
    esac
    emit false false "" "$REASON"
    exit 0
  fi
fi

if ! git rev-parse --verify --quiet "$BASE" >/dev/null 2>&1; then
  emit false false "" "base_not_found"
  exit 0
fi

# THE MATCH IS ON THE SUBJECT, NOT THE WHOLE MESSAGE. `--grep` searches the entire
# commit message, so any commit whose BODY happens to say "Bump version" answered the
# predicate `true` — measured on this script's own branch, where the archive commit's
# body describes the bug and the predicate then claimed the branch had bumped. The
# bump commit's subject is fixed by CLAUDE.md's Version Management section
# ("Bump version to v{new_version}"), so the subject is the whole signal; a body is
# prose about a commit, never the commit itself.
COUNT=$(git log "${BASE}..HEAD" --format=%s | grep -c '^Bump version' || true)

if [ "$COUNT" -gt 0 ]; then
  emit true true "$BASE" ""
else
  emit true false "$BASE" ""
fi
