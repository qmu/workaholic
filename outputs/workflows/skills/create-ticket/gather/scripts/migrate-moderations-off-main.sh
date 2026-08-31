#!/bin/sh -eu
# Move the /moderate tick log off the base branch and onto its own (issue #782).
#
#   migrate-moderations-off-main.sh [repo-root] [--seed]
#
# Output (one JSON line):
#   {"ok", "state": "converged|migrated|skipped|degraded", "reason",
#    "tracked": <n>, "untracked": <n>, "seeded": <n>, "ref", "seed_state"}
#
# WHY (measured 2026-09-01 on a consuming repository's `main`, one calendar day): 275 commits,
# 138 of them touching only `.workaholic/`, 5 touching only the product. The single largest
# author was this log -- three commits an hour, ~50 a day, none of them a change to the
# development target. Its content is load-bearing and stays; its HOME moves
# (`gather/scripts/log-ref.sh`).
#
# TWO HALVES, AND THE ORDER MATTERS. Seeding comes first and untracking second, because the
# other order has a window in which the only readable copy of the log is neither on `main` nor
# on the branch. A fresh container clones `main`; the moment `moderations/` leaves it, every day
# file the branch does not already carry is invisible to `hydrate-log.sh` -- recoverable from
# git history by a person, but not by the loop, and `condition-age.sh` and every dedup would
# read the gap as *nothing ever happened*.
#
#   1. SEED (only with `--seed`, because it PUSHES). Every tracked day file is written onto the
#      log branch in one commit, built against a scratch index -- no checkout, no local branch,
#      the caller's tree byte-identical. A day the branch already carries is left as the branch
#      has it: the log is append-only in substance and the branch is authoritative once seeded.
#   2. UNTRACK. `git rm --cached` stages the removal and leaves every file on disk, which is
#      `converge-layout.sh`'s contract -- it stages and never commits, so the operator's commit
#      is what actually takes the path off `main`. `.gitignore` already carries the directory,
#      so nothing re-adds it.
#
# THE HISTORY ON `main` IS LEFT ALONE, deliberately. Rewriting it would mean a force-push over
# every collaborator's clone to tidy a log, which is not a trade this command gets to make for
# somebody's repository. What changes is what `main` carries FROM NOW ON; `git log` keeps every
# commit it already had, and that is the honest cost of the move rather than a defect in it.
#
# IDEMPOTENT: a repository with nothing tracked under `moderations/` reports `converged` with
# every count zero and touches nothing at all.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOG_REF_SH="${SCRIPT_DIR}/log-ref.sh"

ROOT=''
SEED=0
for arg in "$@"; do
    case "$arg" in
        --seed) SEED=1 ;;
        *)      [ -n "$ROOT" ] || ROOT="$arg" ;;
    esac
done
[ -n "$ROOT" ] || ROOT='.'

REF=''
[ ! -f "$LOG_REF_SH" ] || REF=$(sh "$LOG_REF_SH")
[ -n "$REF" ] || REF=workaholic-log

TRACKED=0
UNTRACKED=0
SEEDED=0
SEED_STATE='not_attempted'

emit() {
    printf '{"ok": %s, "state": "%s", "reason": "%s", "tracked": %s, "untracked": %s, "seeded": %s, "ref": "%s", "seed_state": "%s"}\n' \
        "$1" "$2" "${3:-}" "$TRACKED" "$UNTRACKED" "$SEEDED" "$REF" "$SEED_STATE"
    exit 0
}

repo_root=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || printf '')
[ -n "$repo_root" ] || emit false skipped not_a_repo

files=$(git -C "$repo_root" ls-files -- .workaholic/moderations 2>/dev/null || true)
TRACKED=$(printf '%s\n' "$files" | grep -c '[^[:space:]]' || true)
case "$TRACKED" in ''|*[!0-9]*) TRACKED=0 ;; esac
[ "$TRACKED" -gt 0 ] || emit true converged nothing_tracked

# --- 1. seed ---------------------------------------------------------------------------------
if [ "$SEED" -eq 1 ]; then
    if ! git -C "$repo_root" config --get remote.origin.url >/dev/null 2>&1; then
        SEED_STATE=no_origin
    else
        ensure="${SCRIPT_DIR}/ensure-log-ref.sh"
        ens=$([ -f "$ensure" ] && sh "$ensure" --root "$repo_root" 2>/dev/null || printf '')
        case "$ens" in
            *'"ok": true'*)
                idx=$(mktemp)
                rm -f "$idx"
                tip=$(git -C "$repo_root" ls-remote --heads origin "$REF" 2>/dev/null | cut -f1 || printf '')
                # Start from what the branch already has, so a re-run adds only what is missing
                # and never rewrites a day the branch already carries.
                if [ -n "$tip" ]; then
                    git -C "$repo_root" fetch --quiet --no-tags origin \
                        "+refs/heads/${REF}:refs/remotes/origin/${REF}" >/dev/null 2>&1 || true
                    GIT_INDEX_FILE="$idx" git -C "$repo_root" read-tree "refs/remotes/origin/${REF}" >/dev/null 2>&1 || true
                fi
                for f in $files; do
                    if GIT_INDEX_FILE="$idx" git -C "$repo_root" ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
                        continue
                    fi
                    blob=$(git -C "$repo_root" rev-parse "HEAD:${f}" 2>/dev/null || printf '')
                    [ -n "$blob" ] || continue
                    GIT_INDEX_FILE="$idx" git -C "$repo_root" update-index --add --cacheinfo "100644,${blob},${f}" >/dev/null 2>&1 || continue
                    SEEDED=$((SEEDED + 1))
                done
                if [ "$SEEDED" -eq 0 ]; then
                    SEED_STATE=already_seeded
                else
                    tree=$(GIT_INDEX_FILE="$idx" git -C "$repo_root" write-tree 2>/dev/null || printf '')
                    if [ -z "$tree" ]; then
                        SEED_STATE=tree_failed; SEEDED=0
                    else
                        if [ -n "$tip" ]; then
                            sha=$(printf '%s' "seed the tick log from main" | git -C "$repo_root" commit-tree "$tree" -p "$tip" 2>/dev/null || printf '')
                        else
                            sha=$(printf '%s' "seed the tick log from main" | git -C "$repo_root" commit-tree "$tree" 2>/dev/null || printf '')
                        fi
                        if [ -z "$sha" ]; then
                            SEED_STATE=commit_failed; SEEDED=0
                        elif git -C "$repo_root" push --quiet origin "${sha}:refs/heads/${REF}" >/dev/null 2>&1; then
                            SEED_STATE=seeded
                        else
                            SEED_STATE=push_failed; SEEDED=0
                        fi
                    fi
                fi
                rm -f "$idx"
                ;;
            *) SEED_STATE=log_ref_unavailable ;;
        esac
    fi
    # THE UNTRACKING IS GATED ON THE SEED, and this is the whole reason the order is written
    # down: untracking after a failed seed is the one outcome that loses the log.
    case "$SEED_STATE" in
        seeded|already_seeded) ;;
        *) emit false degraded "seed_${SEED_STATE}" ;;
    esac
fi

# --- 2. untrack ------------------------------------------------------------------------------
# Without `--seed` this refuses rather than running: the caller has not proved the log survives.
if [ "$SEED" -eq 0 ]; then
    emit false skipped seed_required
fi

if git -C "$repo_root" rm --cached -r --quiet -- .workaholic/moderations >/dev/null 2>&1; then
    UNTRACKED="$TRACKED"
    emit true migrated ''
fi
emit false degraded untrack_failed
