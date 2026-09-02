#!/bin/sh
# Check whether this branch has bumped the version, AND whether the number it bumped to is
# still ahead of the base.
# Usage: check-version-bump.sh [<base-ref>]
# Output: JSON — {ok, already_bumped, version_ahead, branch_version, base_version, base, reason}
#
# ═══ TWO QUESTIONS, BECAUSE ONE OF THEM WAS NEVER ASKED ══════════════════════════════
# `already_bumped` answers *did this branch make a bump commit*. That is true of the branch and
# says nothing about **which number it landed on** — and when several branches are cut from one
# base, each bumps `N -> N+1` and each is individually right. The first to merge takes `N+1`;
# every later squash then contains its own bump commit whose CONTENT is already the value the
# base holds, so it produces **no version diff at all** and nothing anywhere reports it.
#
# MEASURED on this repository's `main`, 2026-09-02 — five consecutive merges, two versions:
#
#   #896 Resolve a conflicted pull request in the tick -> 1.0.285
#   #897 Settle a claim race at the remote            -> 1.0.285
#   #898 Take the moderation tick's log off main      -> 1.0.285
#   #894 Read the base's colour past a bookkeeping tip-> 1.0.284
#   #895 Refuse an ask the loop wrote to itself       -> 1.0.284
#
# `.claude-plugin/marketplace.json` is what a consumer installs from and CI publishes a Release
# per version, so a published `1.0.285` and a `main` carrying two further merges are different
# trees under one number. Nothing is broken; what is lost is the ability to say which code a
# version is. Since 2026-09-02 (`/spawn-loops`, three loops plus the developer's own sessions)
# concurrent branches are the normal state, so this is what the rule produces rather than a slip.
#
# `version_ahead` IS THREE-VALUED and its unknown is a real third answer: an unreadable manifest
# on either side answers `null` with a reason, never `false`. The caller's rule is the same
# direction the base resolution already takes — **bump when unsure**, because a redundant bump is
# a no-op commit a human drops while a skipped one ships changes on a spent number.
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

# THE MANIFEST IS THE SOURCE OF TRUTH, and it is read at exactly one path here — the same one
# CLAUDE.md's *Version Management* names first. The three files that follow it are checked by
# `validate-metadata.mjs`, so a second reader of a second file would be a second answer.
MANIFEST=".claude-plugin/marketplace.json"

_version_at() { # $1 = a git revision, or "" for the working tree
  if [ -z "${1:-}" ]; then
    [ -f "$MANIFEST" ] || { printf ''; return 0; }
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST" | sed -n '1p'
  else
    git show "$1:$MANIFEST" 2>/dev/null \
      | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed -n '1p'
  fi
}

# GREATER, NOT MERELY DIFFERENT. A branch cut from a base that has since moved PAST it must bump
# again; one whose number equals the base's must too. Compared field-wise as integers so
# `1.0.9` < `1.0.10`, which a string compare gets wrong.
_version_gt() { # $1 > $2 ?
  printf '%s\n%s\n' "$1" "$2" | awk -F. '
    NR == 1 { split($0, a, ".") ; next }
    { split($0, b, ".") }
    END {
      for (i = 1; i <= 3; i++) {
        x = a[i] + 0; y = b[i] + 0
        if (x > y) { print "true"; exit }
        if (x < y) { print "false"; exit }
      }
      print "false"
    }'
}

emit() {
  cat <<EOF
{
  "ok": $1,
  "already_bumped": $2,
  "version_ahead": ${5:-null},
  "branch_version": "${6:-}",
  "base_version": "${7:-}",
  "base": "$3",
  "reason": "$4"
}
EOF
}

if [ "$#" -ge 1 ] && [ -n "$1" ]; then
  BASE="$1"
else
  BASE=$("${SCRIPT_DIR}/../../gather/scripts/base-ref.sh" 2>/dev/null) || BASE_STATUS=$?
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

BRANCH_V=$(_version_at "")
BASE_V=$(_version_at "$BASE")
if [ -z "$BRANCH_V" ] || [ -z "$BASE_V" ]; then
  # UNREADABLE IS NOT `false`, and it is not `true` either. The caller bumps when unsure.
  AHEAD=null
  AHEAD_REASON="manifest_unreadable"
else
  AHEAD=$(_version_gt "$BRANCH_V" "$BASE_V")
  AHEAD_REASON=""
fi

if [ "$COUNT" -gt 0 ]; then
  emit true true "$BASE" "$AHEAD_REASON" "$AHEAD" "$BRANCH_V" "$BASE_V"
else
  emit true false "$BASE" "$AHEAD_REASON" "$AHEAD" "$BRANCH_V" "$BASE_V"
fi
