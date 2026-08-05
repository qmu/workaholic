#!/bin/sh -eu
# Resolve a target repository for /request and report what filing there would mean.
#
# Usage: resolve-target.sh <path-or-name>
#
# Emits JSON: { ok, path, name, remote, visibility, user_slug, todo_dir, source_repo }
# `visibility` is public|private|unknown — the command MUST show it in the confirmation,
# because "this becomes world-readable" is a different decision from "this stays internal.
# On any failure emits { ok: false, error } and exits 0, so the caller can present the
# error rather than crash mid-flow.

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"
. "${SCRIPT_DIR}/lib/remote-url.sh"

emit_err() {
    printf '{"ok": false, "error": "%s"}\n' "$1"
    exit 0
}

arg="${1:-}"
[ -n "$arg" ] || emit_err "no target given"

SOURCE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Accept an absolute path, a path relative to cwd, or a bare repo name resolved as a
# sibling of this repo's parent directory.
if [ -d "$arg" ]; then
    target="$arg"
elif [ -d "$(dirname -- "$SOURCE_ROOT")/$arg" ]; then
    target="$(dirname -- "$SOURCE_ROOT")/$arg"
else
    emit_err "no such directory: ${arg}"
fi

target="$(cd -- "$target" 2>/dev/null && pwd -P || true)"
[ -n "$target" ] || emit_err "cannot resolve target directory"

git -C "$target" rev-parse --git-dir >/dev/null 2>&1 || emit_err "not a git repository: ${target}"

target_root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$target_root" ] || emit_err "cannot resolve target repository root"

# Filing into our own repo is not a request — it is a ticket. Say so plainly.
if [ "$target_root" = "$SOURCE_ROOT" ]; then
    emit_err "target is this repository — use /ticket, not /request"
fi

name="$(basename -- "$target_root")"

# THE CONFIGURED URL, NOT THE REWRITTEN ONE. This value is shown to the developer as the
# destination they confirm, so it must be the URL a colleague would clone -- not whatever
# an insteadOf rule rewrites it to locally. Under the rewrite the Claude Code on the web
# container carried on 2026-08-04, `git remote get-url` answered
# `http://local_proxy@127.0.0.1:.../git/qmu/qfs`, which is a destination nobody outside
# that container can reach and which also defeats the `visibility` lookup below (its sed
# strips only the github.com forms, so the slug stayed a full URL and `gh api` failed to
# `unknown`). See lib/remote-url.sh for why the two forms exist.
remote="$(remote_url_configured "$target_root")"
[ -n "$remote" ] || remote="$(remote_url_effective "$target_root")"

visibility=unknown
if [ -n "$remote" ] && command -v gh >/dev/null 2>&1; then
    slug="$(printf '%s' "$remote" | sed -e 's#^git@github.com:##' -e 's#^https://github.com/##' -e 's#\.git$##')"
    case "$slug" in
        */*) visibility="$(gh api "repos/${slug}" --jq '.visibility' 2>/dev/null || echo unknown)" ;;
    esac
fi

user_slug="$(git -C "$target_root" config user.email 2>/dev/null | tr '@.' '--' || echo "")"
[ -n "$user_slug" ] || user_slug="$(git config user.email 2>/dev/null | tr '@.' '--' || echo unknown)"

printf '{"ok": true, "path": "%s", "name": "%s", "remote": "%s", "visibility": "%s", "user_slug": "%s", "todo_dir": "%s", "source_repo": "%s"}\n' \
    "$target_root" "$name" "$remote" "$visibility" "$user_slug" \
    "${target_root}/.workaholic/tickets/todo/${user_slug}" \
    "$(basename -- "$SOURCE_ROOT")"
