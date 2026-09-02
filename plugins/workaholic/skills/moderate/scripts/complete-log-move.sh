#!/bin/sh -eu
# Finish the tick log's move off the base -- from the tick, not from a person (2026-09-02,
# ticket `20260902042038`).
#
#   complete-log-move.sh [--root <repo-root>]
#
# Output (one JSON line, always exit 0):
#   {"state": "already_off_base|moved|refused", "reason": "<word>", "tracked": <n>,
#    "untracked": <n>, "seeded": <n>, "sha": "<base commit or empty>"}
#
# WHY THE TICK AND NOT `/workaholify`. The off-main design reached a repository only through
# `converge-layout.sh`, which runs from a command a PERSON invokes -- so between the plugin
# shipping the design and a human running it, every tick kept writing day files to the base.
# MEASURED on a consuming repository: twelve days of silent hourly accumulation, ended only when
# the operator ran `/workaholify` by hand on 2026-09-02, and even then they had to commit and
# merge the staged removals themselves. Twelve days of accumulation is the defect; the leftover
# files are only its residue. The tick that owns the log already reaches the network
# (`ensure-log-ref.sh` creates the branch), so it is the one that can notice and finish this.
#
# MOVING IS THE DESIGN, REPORTING IS THE FALLBACK. A step that only reported would leave the
# accumulation running while naming it once an hour, which is the shape the measurement
# indicts. So this completes the move by default and refuses BY NAME when it cannot -- and a
# refusal makes its calling step `degraded`, which is what carries the condition to a person
# through the tick's existing finding seam, every tick, until it is repaired. No new store, no
# cursor, no field.
#
# IT IS NOT A SECOND MOVER. `gather/scripts/migrate-moderations-off-main.sh` performs both
# halves in the one order that is safe (seed, then untrack); this script composes it inside the
# publish tree the tick already uses and lands the staged removal on the base with
# `publish-tree-commit.sh`. The caller's own checkout is never touched -- which matters here
# because the day files on disk are this tick's working log.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BRANCHING="${SCRIPT_DIR}/../../branching/scripts"
MIGRATE="${SCRIPT_DIR}/../../gather/scripts/migrate-moderations-off-main.sh"

ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

TRACKED=0
UNTRACKED=0
SEEDED=0

emit() {
    printf '{"state": "%s", "reason": "%s", "tracked": %s, "untracked": %s, "seeded": %s, "sha": "%s"}\n' \
        "$1" "${2:-}" "$TRACKED" "$UNTRACKED" "$SEEDED" "${3:-}"
    exit 0
}

repo_root=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || printf '')
[ -n "$repo_root" ] || emit refused not_a_repo

# THE READING FIRST, AND ITS FAILURE IS NOT "CLEAN". `git ls-files` answering nothing because it
# could not run is indistinguishable from answering nothing because there is nothing tracked, so
# the command's own exit status is what separates them.
if files=$(git -C "$repo_root" ls-files -- .workaholic/moderations 2>/dev/null); then
    TRACKED=$(printf '%s\n' "$files" | grep -c '[^[:space:]]' || true)
    case "$TRACKED" in ''|*[!0-9]*) TRACKED=0 ;; esac
else
    emit refused tracking_unreadable
fi
[ "$TRACKED" -gt 0 ] || emit already_off_base ''

git -C "$repo_root" config --get remote.origin.url >/dev/null 2>&1 || emit refused no_origin
[ -f "$MIGRATE" ] || emit refused migration_missing
[ -f "${BRANCHING}/open-publish-tree.sh" ] || emit refused publish_seam_missing

open_out=$(cd "$repo_root" && sh "${BRANCHING}/open-publish-tree.sh" 2>/dev/null || printf '')
case "$open_out" in *'"ok": true'*) ;; *) emit refused publish_tree_unavailable ;; esac
pub=$(printf '%s' "$open_out" | sed -n 's/.*"path": "\([^"]*\)".*/\1/p')
[ -n "$pub" ] && [ -d "$pub" ] || emit refused publish_tree_unavailable

close_tree() { (cd "$repo_root" && sh "${BRANCHING}/close-publish-tree.sh" >/dev/null 2>&1) || true; }

# `--seed` PUSHES the day files to the log branch before anything is untracked. That order is the
# migration's own safety property and is not re-decided here.
mig=$(cd "$repo_root" && sh "$MIGRATE" "$pub" --seed 2>/dev/null || printf '')
mig_state=$(printf '%s' "$mig" | sed -n 's/.*"state": "\([^"]*\)".*/\1/p')
mig_reason=$(printf '%s' "$mig" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
UNTRACKED=$(printf '%s' "$mig" | sed -n 's/.*"untracked": \([0-9]*\).*/\1/p')
SEEDED=$(printf '%s' "$mig" | sed -n 's/.*"seeded": \([0-9]*\).*/\1/p')
[ -n "$UNTRACKED" ] || UNTRACKED=0
[ -n "$SEEDED" ] || SEEDED=0

case "$mig_state" in
    migrated) ;;
    converged) close_tree; emit already_off_base '' ;;
    *) close_tree; emit refused "migration_${mig_reason:-refused}" ;;
esac

commit_out=$(cd "$repo_root" && sh "${BRANCHING}/publish-tree-commit.sh" \
    "Take the tick log off the base" \
    "The tick log's home is its own branch; day files still tracked on the base are the residue of a repository that had not converged, and every tick was adding to them." \
    "The day files were seeded onto the log branch and their tracking removed from the base. The files stay on disk in every checkout -- .gitignore already carries the directory." \
    "None -- the log's content is on the log branch before anything here is untracked." \
    "The move used to reach a repository only when a person ran /workaholify; the tick that owns the log now finishes it." \
    "migrate-moderations-off-main.sh reported migrated; the base no longer tracks .workaholic/moderations/." \
    2>/dev/null || printf '')
close_tree
case "$commit_out" in
    *'"ok": true'*)
        sha=$(printf '%s' "$commit_out" | sed -n 's/.*"sha": "\([^"]*\)".*/\1/p')
        emit moved '' "$sha"
        ;;
    *'"reason": "nothing_to_commit"'*) emit already_off_base '' ;;
    *)
        creason=$(printf '%s' "$commit_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
        emit refused "publish_${creason:-commit_failed}"
        ;;
esac
