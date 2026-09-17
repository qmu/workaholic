#!/bin/sh -eu
# Commit what the caller wrote into the publish tree and LAND IT ON THE BASE.
#
#   publish-tree-commit.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
#
# The positional arguments are commit.sh's, forwarded verbatim: this script owns
# the push, not the message. The base branch is `main` unless
# WORKAHOLIC_PUBLISH_BASE names another.
#
# Output (stdout, exit 0 for a reported outcome):
#   {"ok": true,  "sha": "<pushed sha>", "retried": true|false, "base": "<base>"}
#   {"ok": false, "reason": "no_publish_tree"|"nothing_to_commit"|"commit_failed"
#                          |"diverged"|"push_failed", ...}
#
# THE COMMIT GOES THROUGH commit.sh, inside the publish tree, via a
# `( cd … && … )` subshell — the form the working-directory guard tolerates. The
# subject gate, the staging semantics, and the Co-Authored-By trailer are
# inherited unchanged; there is no hand-rolled `git commit` here.
#
# THE BRANCH NAME NEVER LEAVES THE MACHINE. `git push origin publish-main:<base>`
# lands the COMMIT on the base; no `publish-main` ref is ever created on origin,
# so the claim scan (which enumerates unmerged origin branches) never sees it.
#
# NO UNATTENDED PATH CALLS THIS SEAM (2026-09-11, issue #1151). Its two remaining
# callers -- `moderate/scripts/persist-log.sh --record` and
# `ship/scripts/extract-deferred-concerns.sh` -- moved onto `publish-tree-pr.sh`, so a
# feedback record and a deferred concern now reach the base through a merged pull
# request with the normal checks, never as a direct commit. What may still use it: an
# ATTENDED developer's own publication (no `WORKAHOLIC_ROLE` set) and the hermetic suite's
# fixtures, which need a one-commit road onto a throwaway base. It is kept rather than
# deleted because the suite's publish-tree contracts are written against it; the
# base-ref gate (`branching/scripts/lib/base-ref-gate.sh`) refuses its push under every
# unattended role, so keeping it opens no road back to `main` for a routine.
#
# NON-FAST-FORWARD IS EXPECTED, NOT EXCEPTIONAL. Another session or a cron tick
# may push between the open and this call, so a rejection is re-fetched, rebased,
# and retried ONCE. The bound is deliberate: an unbounded retry loop would hide
# sustained divergence that a human should see. A surviving rejection reports
# `diverged` and LEAVES THE COMMIT INTACT in the publish tree, so nothing is lost.

set -eu

base="${WORKAHOLIC_PUBLISH_BASE:-main}"
PUBLISH_BRANCH="publish-main"

if [ "$#" -lt 6 ]; then
  echo 'Usage: publish-tree-commit.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]' >&2
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

if [ -n "${WORKAHOLIC_PUBLICATION_ID:-}" ]; then
  title=$1 why=$2 changes=$3 concerns=$4 insights=$5 verify=$6; shift 6
  commit_request=$(mktemp); publish_request=$(mktemp); trap 'rm -f "$commit_request" "$publish_request"' EXIT
  jq -cn --arg title "$title" --arg why "$why" --arg changes "$changes" --arg concerns "$concerns" --arg insights "$insights" --arg verify "$verify" --args \
    '{title:$title,why:$why,changes:$changes,concerns:$concerns,insights:$insights,verify:$verify,files:$ARGS.positional}' "$@" >"$commit_request"
  committed=$(sh "${SCRIPT_DIR}/publication.sh" commit --transaction "$WORKAHOLIC_PUBLICATION_ID" --request "$commit_request")
  [ "$(printf '%s' "$committed" | jq -r .ok)" = true ] || { printf '%s\n' "$committed"; exit 0; }
  jq -cn --arg title "$title" --arg body "$why" '{title:$title,body:$body}' >"$publish_request"
  published=$(sh "${SCRIPT_DIR}/publication.sh" publish --transaction "$WORKAHOLIC_PUBLICATION_ID" --request "$publish_request" --mode direct)
  if [ "$(printf '%s' "$published" | jq -r .ok)" = true ]; then
    printf '%s' "$published" | jq -c '{ok:true,sha:.sha,retried:false,base:.base}'
  else printf '%s\n' "$published"; fi
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
publish_path="${repo_root}/.publish"

if ! git worktree list --porcelain | grep -q "^worktree ${publish_path}$"; then
  printf '{"ok": false, "reason": "no_publish_tree", "path": "%s", "detail": "run open-publish-tree.sh first"}\n' "$publish_path"
  exit 0
fi

before_sha="$(git -C "$publish_path" rev-parse HEAD)"

# --- 1. Commit through the shared wrapper ------------------------------------
if ( cd "$publish_path" && sh "${SCRIPT_DIR}/../../commit/scripts/commit.sh" "$@" ) >&2; then
  :
else
  printf '{"ok": false, "reason": "commit_failed", "path": "%s"}\n' "$publish_path"
  exit 0
fi

after_sha="$(git -C "$publish_path" rev-parse HEAD)"
if [ "$before_sha" = "$after_sha" ]; then
  # commit.sh exits 0 on "nothing staged". Reporting ok:true here would hand back
  # a sha that predates the caller's write — a publication that never happened,
  # reported as one that did.
  printf '{"ok": false, "reason": "nothing_to_commit", "path": "%s", "detail": "commit.sh staged nothing; the artifact is NOT on %s"}\n' "$publish_path" "$base"
  exit 0
fi

# --- 2. Push the commit onto the base, with one rebase-and-retry -------------
# THE BASE-REF GATE (2026-09-11, issue #1151): this seam's destination IS the base, so under
# any unattended role it is refused by name with the commit left intact in the publish tree.
. "${SCRIPT_DIR}/lib/base-ref-gate.sh"
if ! base_ref_gate push "${PUBLISH_BRANCH}:${base}"; then
  printf '{"ok": false, "reason": "base_ref_write", "role": "%s", "path": "%s", "detail": "a direct write to %s is refused under an unattended role; publish through publish-tree-pr.sh. The commit is intact in the publish tree"}\n' \
    "${WORKAHOLIC_ROLE:-}" "$publish_path" "$base"
  exit 0
fi
retried=false
if git -C "$publish_path" push --quiet origin "${PUBLISH_BRANCH}:${base}" >&2; then
  :
else
  retried=true
  if ! git -C "$publish_path" fetch --quiet origin "$base" >&2; then
    printf '{"ok": false, "reason": "push_failed", "retried": true, "detail": "origin became unreachable; the commit is intact in %s"}\n' "$publish_path"
    exit 0
  fi
  if git -C "$publish_path" rebase --quiet "origin/${base}" >&2; then
    :
  else
    git -C "$publish_path" rebase --abort >&2 2>/dev/null || true
    printf '{"ok": false, "reason": "diverged", "retried": true, "path": "%s", "detail": "the publish commit does not rebase cleanly onto origin/%s; it is intact and recoverable in the publish tree"}\n' "$publish_path" "$base"
    exit 0
  fi
  if git -C "$publish_path" push --quiet origin "${PUBLISH_BRANCH}:${base}" >&2; then
    :
  else
    printf '{"ok": false, "reason": "diverged", "retried": true, "path": "%s", "detail": "origin/%s advanced again after the rebase; the commit is intact and recoverable in the publish tree"}\n' "$publish_path" "$base"
    exit 0
  fi
fi

pushed_sha="$(git -C "$publish_path" rev-parse HEAD)"
printf '{"ok": true, "sha": "%s", "retried": %s, "base": "%s"}\n' "$pushed_sha" "$retried" "$base"
