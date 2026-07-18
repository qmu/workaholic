#!/bin/sh
# Shared exclude guard for the two worktree creators (ensure-worktree.sh and
# create-mission-worktree.sh). Source this file and call `ensure_git_excludes
# <repo_root>` BEFORE `git worktree add`.
#
# Why: git does NOT auto-ignore a linked worktree directory, so a stray
# `git add -A` in the main tree would embed .worktrees/<name> as a gitlink. And
# the per-worktree .env (credentials + assigned ports) must not register as a
# "dirty" file that blocks worktree reset/cleanup. Both are excluded via the
# shared, untracked .git/info/exclude (applies to every worktree of this repo,
# needs no commit). Idempotent: existing lines are never duplicated.
#
# Extracted from create-mission-worktree.sh so the guard cannot drift between
# the creators — ensure-worktree.sh (trip/drive worktrees) used to lack it
# entirely, leaving the gitlink risk latent for non-mission worktrees.

# Reads: $1 = repo root. Writes: <git-common-dir>/info/exclude.
ensure_git_excludes() {
    _ege_root="$1"
    _ege_common="$(git rev-parse --git-common-dir 2>/dev/null || echo "${_ege_root}/.git")"
    case "$_ege_common" in /*) : ;; *) _ege_common="${_ege_root}/${_ege_common}" ;; esac
    _ege_exclude="${_ege_common}/info/exclude"
    mkdir -p "${_ege_common}/info"
    for _ege_pat in '.worktrees/' '.env'; do
        if [ ! -f "$_ege_exclude" ] || ! grep -qxF "$_ege_pat" "$_ege_exclude"; then
            printf '%s\n' "$_ege_pat" >> "$_ege_exclude"
        fi
    done
}
