#!/bin/sh -eu
# Bring THIS checkout's base branch up to date with origin's, FAST-FORWARD ONLY.
#
#   sync-main.sh [base-branch]      # base defaults to the branch check.sh calls main
#
# Output (stdout, always exit 0 for a reported outcome):
#   {"ok": true,  "base": "origin/<base>", "sha": "<sha>", "advanced": true|false}
#   {"ok": false, "reason": "not_on_main"|"dirty_workspace"|"no_origin"
#                          |"origin_unreachable"|"diverged", ...}
#
# NEVER merges, rebases, stashes, or resets. A fast-forward is the only mutation
# it will perform, and every state in which it cannot fast-forward is REPORTED
# rather than resolved: staleness is reported and never auto-broken, and a reset
# would discard a developer's local commits on the base.
#
# The reasons ride stdout with exit 0 on purpose. Every one of them is a
# legitimate state of a developer's checkout — on a branch, mid-edit — not a
# failure of this script, and the callers (`/propose` step 1, `/drive`'s
# freshness step) are command markdown that cannot branch: they hand the JSON to
# an orchestrator that reads one uniform contract. A genuine misuse (not a git
# repository) still exits non-zero with an "error" key.
#
# Composed from the existing readers (check.sh, check-workspace.sh) rather than
# re-deriving "am I on main" and "is the tree clean" — those questions have one
# implementation each.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
requested_base="${1:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

# --- 1. On the base branch? -------------------------------------------------
# check.sh answers for main OR master, so a master-default repository works with
# no argument. An explicitly requested base must match exactly.
check_out=$(sh "${SCRIPT_DIR}/check.sh")
branch=$(printf '%s\n' "$check_out" | sed -n 's/.*"branch":[ ]*"\([^"]*\)".*/\1/p')
on_main=$(printf '%s\n' "$check_out" | sed -n 's/.*"on_main":[ ]*\([a-z]*\).*/\1/p')

if [ -n "$requested_base" ]; then
  base="$requested_base"
  if [ "$branch" != "$base" ]; then
    printf '{"ok": false, "reason": "not_on_main", "branch": "%s", "base": "%s"}\n' "$branch" "$base"
    exit 0
  fi
else
  if [ "$on_main" != "true" ]; then
    printf '{"ok": false, "reason": "not_on_main", "branch": "%s"}\n' "$branch"
    exit 0
  fi
  base="$branch"
fi

# --- 2. Clean tree? ---------------------------------------------------------
# A fast-forward moves tracked files under the caller's feet; refuse rather than
# risk a conflicted checkout over uncommitted work.
ws_out=$(sh "${SCRIPT_DIR}/check-workspace.sh")
clean=$(printf '%s\n' "$ws_out" | sed -n 's/.*"clean":[ ]*\([a-z]*\).*/\1/p')
if [ "$clean" != "true" ]; then
  summary=$(printf '%s\n' "$ws_out" | sed -n 's/.*"summary":[ ]*"\([^"]*\)".*/\1/p')
  printf '{"ok": false, "reason": "dirty_workspace", "branch": "%s", "summary": "%s"}\n' "$branch" "$summary"
  exit 0
fi

# --- 3. Origin ---------------------------------------------------------------
if ! git config --get remote.origin.url >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_origin", "base": "%s"}\n' "$base"
  exit 0
fi

# An unreachable origin is its own reason. Reporting `ok: true` off a stale
# remote-tracking ref would be the silent yesterday's-queue survey this script
# exists to prevent.
if ! git fetch --quiet origin "$base" >&2; then
  printf '{"ok": false, "reason": "origin_unreachable", "base": "%s"}\n' "$base"
  exit 0
fi

local_sha=$(git rev-parse --verify --quiet "refs/heads/${base}^{commit}" || true)
remote_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/${base}^{commit}" || true)

if [ -z "$remote_sha" ]; then
  printf '{"ok": false, "reason": "origin_unreachable", "base": "%s", "detail": "origin has no %s ref after a successful fetch"}\n' "$base" "$base"
  exit 0
fi

if [ "$local_sha" = "$remote_sha" ]; then
  printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": false}\n' "$base" "$remote_sha"
  exit 0
fi

# --- 4. Fast-forward, or report why not --------------------------------------
# Local strictly behind: fast-forward. Anything else — local ahead, or genuine
# divergence — is a human's decision, reported with a `detail` that says which.
if git merge-base --is-ancestor "$local_sha" "$remote_sha"; then
  git merge --ff-only --quiet "origin/${base}" >&2
  printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": true}\n' "$base" "$remote_sha"
  exit 0
fi

if git merge-base --is-ancestor "$remote_sha" "$local_sha"; then
  detail="local_ahead"
else
  detail="both_diverged"
fi
printf '{"ok": false, "reason": "diverged", "base": "%s", "local_sha": "%s", "remote_sha": "%s", "detail": "%s"}\n' \
  "$base" "$local_sha" "$remote_sha" "$detail"
exit 0
