#!/bin/sh -eu
# CLEAR ONLY THE RESIDUE A PROOF COVERS, THEN LET THE FRESHEN RUN (2026-09-08, mission
# `clear-the-residue-the-base-already-holds-and-never-stop-silently`).
#
#   clear-proved-residue.sh [base-branch] [--allow-untracked]
#
# THE LAYER ABOVE `sync-main.sh`, WHICH IS LEFT BYTE-IDENTICAL. That script's refusal is correct
# by its own stated rationale — *a reset would discard a developer's local commits* — and the ask
# that produced this mission says so in those terms. Widening it would loosen the contract for
# every other caller of it, including the ones that run inside claim worktrees. So the judgement
# lives here, above it, and `sync-main.sh` is not touched.
#
# WHAT IT ACTS ON is `classify-residue.sh`'s reading and nothing else, and it RE-DERIVES each
# path's class through that same one reader in the moment before it touches that path
# (`--path`), never from the opening walk — the standing discipline for a bounded act on a proof
# (`drive/reference/claims.md`, *When a bounded act may read a judgement*): re-derive at the
# moment of the act, be idempotent, write nothing on a refusal, and refuse each bound by its own
# word. A second copy of the proof is what that discipline forbids, which is why the re-derivation
# is a call rather than an inlined comparison.
#
# PER CLASS:
#   on_base      `git restore --source=HEAD --staged --worktree -- <path>` — or, where HEAD does
#                not carry the path at all (a staged add of content the base already holds), the
#                index entry is dropped and the file removed. Both discard content BYTE-IDENTICAL
#                to what `<base>` holds, which the freshen that follows brings straight back.
#   regenerable  restored to HEAD the same way, then the repository's OWN generator re-run —
#                never a blind checkout of the base's copy, which would be a guess wearing a
#                proof's clothes. Which generator is derived from which paths were restored.
#   untracked    LEFT ALONE, ALWAYS. Deleting an untracked file is the one irreversible act
#                available at this seam and no proof covers it: an untracked file is by definition
#                on no ref. The measured tree had none, so the bound costs nothing that was
#                measured.
#   divergent    untouched, and the run refuses.
#   unanswerable untouched, and the run refuses. An absence of a reading is never a proof.
#
# EVERY REFUSAL THAT CAN BE CHECKED IS CHECKED BEFORE ANYTHING IS WRITTEN, so a refusal leaves
# the tree byte-identical rather than half-cleared. `untracked_present` is part of that: an
# untracked file keeps `check-workspace.sh` dirty however much else is cleared, so clearing the
# rest would be writes that buy the caller nothing. `--allow-untracked` is for a caller that does
# not need a clean tree; it clears the proved paths and names what it left in `untracked_left`.
#
# THE ONE REFUSAL THAT CANNOT PRECEDE ITS WRITES IS `generator_failed`, and that is stated rather
# than hidden: it is reachable only after the proved restores have been made, because running a
# generator is what a `regenerable` restore *is*. Those restores stand — each was individually
# re-derived and each discarded content the base holds — and the path the generator did not
# rewrite is left where the restore put it, never filled in from the base's copy. The freshen
# that follows will refuse if the tree is still dirty, which is the honest outcome.
#
# IT IS IDEMPOTENT: a second call on a tree it already cleared answers `already_clean` and writes
# nothing.
#
# Output (stdout, exit 0):
#   {"ok": true, "base": "origin/<base>", "cleared": [{"path": "...", "class": "..."}],
#    "regenerated": true|false, "generators": ["..."], "untracked_left": ["..."]}
#   {"ok": true, "already_clean": true, "base": "...", "cleared": [], "regenerated": false, ...}
#   {"ok": false, "reason": "divergent_residue"|"unanswerable_residue"|"untracked_present"
#                          |"classify_unreadable"|"not_on_main"|"no_origin"|"no_base_ref"
#                          |"status_unreadable"|"generator_failed",
#    "paths": [...], "detail": "...", "base": "..."}
#
# A reader refusal is passed through BY ITS OWN WORD (`not_on_main`, `no_origin`, `no_base_ref`,
# `status_unreadable`) rather than normalised into one: a normalised word sends a reader to a
# string no script printed. `classify_unreadable` is reserved for the reader not being runnable
# or answering nothing at all.
#
# Wired at `/drive` §1 ONCE, never in a loop: on `sync-main.sh` answering `dirty_workspace`, call
# this act once and, on `cleared`, re-run `sync-main.sh` once. A freshen that still refuses after
# a successful clear is reporting something the proof does not cover, and retrying would turn a
# report into a spin.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
CLASSIFY="${SCRIPT_DIR}/classify-residue.sh"
REFRESH_INDEX="${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh"

requested_base=""
allow_untracked=false
while [ $# -gt 0 ]; do
    case "$1" in
        --allow-untracked) allow_untracked=true; shift ;;
        *) [ -n "$requested_base" ] || requested_base="$1"; shift ;;
    esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"ok": false, "reason": "not_a_repository"}'
    exit 0
fi

refuse() {
    printf '{"ok": false, "reason": "%s", "base": "%s", "paths": [%s], "detail": "%s"}\n' \
        "$1" "${BASE:-}" "${2:-}" "${3:-}"
    exit 0
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g'
}

classify_all() {
    if [ -n "$requested_base" ]; then
        sh "$CLASSIFY" "$requested_base" 2>/dev/null
    else
        sh "$CLASSIFY" 2>/dev/null
    fi
}

classify_one() {
    if [ -n "$requested_base" ]; then
        sh "$CLASSIFY" "$requested_base" --path "$1" 2>/dev/null
    else
        sh "$CLASSIFY" --path "$1" 2>/dev/null
    fi
}

# --- The opening reading -------------------------------------------------------------------
BASE=""
[ -f "$CLASSIFY" ] || refuse classify_unreadable "" "reader not present"
reading=$(classify_all) || refuse classify_unreadable "" "reader exited non-zero"
[ -n "$reading" ] || refuse classify_unreadable "" "reader answered nothing"

BASE=$(printf '%s\n' "$reading" | sed -n 's/.*"base":[ ]*"\([^"]*\)".*/\1/p')
readable=$(printf '%s\n' "$reading" | sed -n 's/.*"readable":[ ]*\([a-z]*\).*/\1/p')
if [ "$readable" = "false" ]; then
    # The reader's own word, verbatim.
    reason=$(printf '%s\n' "$reading" | sed -n 's/.*"reason":[ ]*"\([^"]*\)".*/\1/p')
    [ -n "$reason" ] || reason="classify_unreadable"
    refuse "$reason" "" "the residue reading could not be completed"
fi

paths_of_class() {
    printf '%s' "$reading" | jq -r --arg c "$1" '[.paths[]? | select(.class == $c) | .path] | .[]' 2>/dev/null || true
}
json_array_of() {
    _jao=""
    for _jao_p in "$@"; do
        [ -n "$_jao_p" ] || continue
        [ -z "$_jao" ] || _jao="${_jao},"
        _jao="${_jao}\"$(json_escape "$_jao_p")\""
    done
    printf '%s' "$_jao"
}
# The class lists. Read with newline IFS so a path with spaces survives.
old_ifs=$IFS
IFS='
'
# shellcheck disable=SC2046
set -- $(paths_of_class divergent)
divergent_paths="$*"
divergent_json=$(json_array_of "$@")
# shellcheck disable=SC2046
set -- $(paths_of_class unanswerable)
unanswerable_json=$(json_array_of "$@")
unanswerable_paths="$*"
# shellcheck disable=SC2046
set -- $(paths_of_class untracked)
untracked_json=$(json_array_of "$@")
untracked_paths="$*"
# shellcheck disable=SC2046
set -- $(paths_of_class on_base)
on_base_list="$*"
# shellcheck disable=SC2046
set -- $(paths_of_class regenerable)
regenerable_list="$*"
IFS=$old_ifs

total=$(printf '%s' "$reading" | jq -r '.counts.total // 0' 2>/dev/null || printf '0')
case "$total" in ''|*[!0-9]*) total=0 ;; esac

if [ "$total" -eq 0 ]; then
    printf '{"ok": true, "already_clean": true, "base": "%s", "cleared": [], "regenerated": false, "generators": [], "untracked_left": []}\n' "$BASE"
    exit 0
fi

# --- Every refusal, BEFORE any write --------------------------------------------------------
[ -z "$divergent_paths" ] \
    || refuse divergent_residue "$divergent_json" "tracked work that is not on the base"
[ -z "$unanswerable_paths" ] \
    || refuse unanswerable_residue "$unanswerable_json" "no proof could be made about these paths"
if [ "$allow_untracked" != true ] && [ -n "$untracked_paths" ]; then
    refuse untracked_present "$untracked_json" "an untracked file is on no ref and is never removed here"
fi

# --- The act --------------------------------------------------------------------------------
cleared=""
add_cleared() {
    [ -z "$cleared" ] || cleared="${cleared},"
    cleared="${cleared}{\"path\": \"$(json_escape "$1")\", \"class\": \"$2\"}"
}

# Restore one path to HEAD. Where HEAD does not carry it — a staged ADD of content the base
# already holds, which is exactly the measured shape — `git restore` has nothing to restore
# from, so the index entry is dropped and the file removed. Both discard bytes the base holds.
restore_to_head() {
    if git cat-file -e "HEAD:$1" 2>/dev/null; then
        git restore --source=HEAD --staged --worktree -- "$1" >&2
    else
        git rm --cached --quiet -- "$1" >&2
        rm -f -- "$1"
    fi
}

# Act on ONE path only after re-deriving its class through the one reader, in the moment before
# touching it. A path whose class moved — or which is no longer dirty at all — is skipped
# silently: it is not this act's to touch any more.
act_on() {
    _ao_path="$1"
    _ao_want="$2"
    _ao_now=$(classify_one "$_ao_path") || return 0
    _ao_class=$(printf '%s' "$_ao_now" | jq -r --arg p "$_ao_path" '(.paths[]? | select(.path == $p) | .class) // ""' 2>/dev/null || printf '')
    [ "$_ao_class" = "$_ao_want" ] || return 0
    restore_to_head "$_ao_path"
    add_cleared "$_ao_path" "$_ao_want"
}

old_ifs=$IFS
IFS='
'
for p in $on_base_list; do
    [ -n "$p" ] || continue
    IFS=$old_ifs
    act_on "$p" on_base
    IFS='
'
done
regen_workaholic=false
regen_build=false
for p in $regenerable_list; do
    [ -n "$p" ] || continue
    IFS=$old_ifs
    act_on "$p" regenerable
    case "$p" in
        .workaholic/*) regen_workaholic=true ;;
        *) regen_build=true ;;
    esac
    IFS='
'
done
IFS=$old_ifs

# --- Regenerate what was restored -----------------------------------------------------------
# The generator is derived from the paths actually restored, so a tree with no regenerable
# residue runs nothing. A generator that fails is `generator_failed`: the path is left where the
# restore put it rather than falling back to the base's copy, which would be a guess.
generators=""
regenerated=false
add_generator() {
    [ -z "$generators" ] || generators="${generators},"
    generators="${generators}\"$1\""
}
if [ "$regen_workaholic" = true ] && [ -f "$REFRESH_INDEX" ]; then
    if sh "$REFRESH_INDEX" >/dev/null 2>&1; then
        regenerated=true
        add_generator "okf/scripts/refresh-index.sh"
    else
        refuse generator_failed "" "okf/scripts/refresh-index.sh"
    fi
fi
if [ "$regen_build" = true ] && [ -f "scripts/build-plugins/build.mjs" ] && command -v node >/dev/null 2>&1; then
    if node scripts/build-plugins/build.mjs >/dev/null 2>&1; then
        regenerated=true
        add_generator "scripts/build-plugins/build.mjs"
    else
        refuse generator_failed "" "scripts/build-plugins/build.mjs"
    fi
fi

printf '{"ok": true, "base": "%s", "cleared": [%s], "regenerated": %s, "generators": [%s], "untracked_left": [%s]}\n' \
    "$BASE" "$cleared" "$regenerated" "$generators" "$untracked_json"
