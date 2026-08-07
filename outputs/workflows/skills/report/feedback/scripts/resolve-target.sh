#!/bin/sh -eu
# Resolve a target repository for a cross-boundary ask, and report what sending there
# would mean.
#
# Usage: resolve-target.sh <path-or-name-or-slug-or-url>
#
# Emits JSON: { ok, path, name, slug, remote, visibility, user_slug, todo_dir, source_repo }
# `visibility` is public|private|unknown — the caller MUST show it in the confirmation,
# because "this becomes world-readable" is a different decision from "this stays internal".
# On any failure emits { ok: false, error } and exits 0, so the caller can present the
# error rather than crash mid-flow.
#
# THE TARGET NEED NOT BE ON THIS DISK. The crossing artifact is a GitHub issue, so the
# only thing the sender strictly needs is the target's `owner/name` — and requiring a
# local checkout would mean a developer can only raise an ask against repositories they
# happen to have cloned, which is not the boundary the rule is about. Four forms resolve:
#
#   /abs/path, ./rel/path, sibling-name   a checkout on this disk (`path` is set)
#   owner/name                            a slug alone      (`path` is empty)
#   https://github.com/owner/name[.git]   a browser URL     (`path` is empty)
#   git@github.com:owner/name[.git]       a clone URL       (`path` is empty)
#
# A DIRECTORY ALWAYS WINS. The path forms are tried first, so a sibling checkout named
# `owner/name` — or any relative two-segment path that exists — resolves to the checkout
# rather than to a GitHub slug that may not be the same repository. Guessing across that
# ambiguity is exactly the "never guess a target" failure, so the more concrete answer
# takes precedence and the caller sees `path` telling it which branch resolved.

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

# `owner/name` from a GitHub URL in either spelling, or empty when the argument is not
# one. Kept narrow on purpose: a host that is not github.com is not something `gh issue
# create` can address, so reporting it as resolved would be a lie the caller acts on.
url_slug() {
    printf '%s' "$1" | sed -n \
        -e 's#^https\{0,1\}://github\.com/\([^/][^/]*\)/\([^/][^/]*\)/\{0,1\}$#\1/\2#p' \
        -e 's#^git@github\.com:\([^/][^/]*\)/\([^/][^/]*\)$#\1/\2#p' \
        | sed -e 's#\.git$##' | head -1
}

# Emit the remote-only answer for a resolved `owner/name`: no checkout, so no `path`,
# no `todo_dir`. `user_slug` still answers "who is asking", which is this repository's
# identity either way.
emit_remote_target() {
    _rt_slug="$1"
    if [ "$_rt_slug" = "$(source_slug)" ]; then
        emit_err "target is this repository — use /ticket, not a cross-repository ask"
    fi
    _rt_name="${_rt_slug#*/}"
    _rt_remote="https://github.com/${_rt_slug}"
    _rt_user="$(git config user.email 2>/dev/null | tr '@.' '--' || echo unknown)"
    [ -n "$_rt_user" ] || _rt_user=unknown
    printf '{"ok": true, "path": "", "name": "%s", "slug": "%s", "remote": "%s", "visibility": "%s", "user_slug": "%s", "todo_dir": "", "source_repo": "%s"}\n' \
        "$_rt_name" "$_rt_slug" "$_rt_remote" "$(lookup_visibility "$_rt_remote")" "$_rt_user" \
        "$(basename -- "$SOURCE_ROOT")"
    exit 0
}

# This repository's own `owner/name`, or empty when it has no origin. Read from the
# CONFIGURED url first for the reason spelled out below: a local insteadOf rewrite can
# name this repository as something no slug lookup would recognise.
source_slug() {
    _ss="$(git -C "$SOURCE_ROOT" config --get remote.origin.url 2>/dev/null || true)"
    [ -n "$_ss" ] || _ss="$(git -C "$SOURCE_ROOT" remote get-url origin 2>/dev/null || true)"
    url_slug "$_ss"
}

# public|private|unknown. `unknown` is a real ANSWER, not a failure: it means the lookup
# could not be made — no `gh`, no network, no access, or a remote that is not on GitHub —
# and the caller shows it as such rather than implying the repository is private.
# Deliberately github-only: `gh api repos/<slug>` asks github.com whatever the remote's
# host is, so deriving a slug from an arbitrary URL would answer a question about some
# other repository that happens to share the two trailing path segments.
lookup_visibility() {
    _lv_slug="$(url_slug "$1")"
    case "$_lv_slug" in
        */*) ;;
        *) printf 'unknown'; return 0 ;;
    esac
    command -v gh >/dev/null 2>&1 || { printf 'unknown'; return 0; }
    # THE ANSWER IS AN ENUM, AND ANYTHING ELSE IS `unknown`. `gh api` prints its error
    # body to STDOUT, not stderr, so a 404 or an unauthenticated call yields a JSON blob
    # AND a non-zero status: the `2>/dev/null || echo unknown` form this replaces emitted
    # `{"message":"Not Found",...}unknown` into the `visibility` field, which made the
    # whole envelope unparseable — a resolution failure reported as a crash, on the one
    # field the confirmation shows a human. Whitelisting the three values GitHub can
    # return is the only shape that cannot leak a payload into the envelope.
    _lv_out="$(gh api "repos/${_lv_slug}" --jq '.visibility' 2>/dev/null || true)"
    case "$_lv_out" in
        public|private|internal) printf '%s' "$_lv_out" ;;
        *) printf 'unknown' ;;
    esac
}

# Accept an absolute path, a path relative to cwd, or a bare repo name resolved as a
# sibling of this repo's parent directory — then, only if none of those is a directory,
# an `owner/name` slug or a GitHub URL naming a repository that need not be on this disk.
if [ -d "$arg" ]; then
    target="$arg"
elif [ -d "$(dirname -- "$SOURCE_ROOT")/$arg" ]; then
    target="$(dirname -- "$SOURCE_ROOT")/$arg"
else
    remote_slug="$(url_slug "$arg")"
    if [ -z "$remote_slug" ]; then
        case "$arg" in
            */*/*|/*) ;;
            */*) if printf '%s' "$arg" | grep -qE '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$'; then remote_slug="$arg"; fi ;;
        esac
    fi
    [ -n "$remote_slug" ] || emit_err "no such directory: ${arg}"
    emit_remote_target "$remote_slug"
fi

target="$(cd -- "$target" 2>/dev/null && pwd -P || true)"
[ -n "$target" ] || emit_err "cannot resolve target directory"

git -C "$target" rev-parse --git-dir >/dev/null 2>&1 || emit_err "not a git repository: ${target}"

target_root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$target_root" ] || emit_err "cannot resolve target repository root"

# Sending an ask to our own repo is not a crossing — it is a ticket. Say so plainly.
if [ "$target_root" = "$SOURCE_ROOT" ]; then
    emit_err "target is this repository — use /ticket, not a cross-repository ask"
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

# `todo_dir` is the target's FLAT queue since P2 (2026-08-06). It used to carry a
# per-user segment derived here by a SECOND, divergent slug rule (`tr '@.' '--'`,
# not gather/scripts/user-slug.sh) — a duplicate that could disagree with the
# canonical one on any character outside [a-z0-9.@]. The flatten removes the
# segment and the duplicate rule with it; `user_slug` stays as the reporting-only
# field it was, computed through the one rule.
user_slug="$(git -C "$target_root" config user.email 2>/dev/null || echo "")"
[ -n "$user_slug" ] || user_slug="$(git config user.email 2>/dev/null || echo "")"
if [ -n "$user_slug" ]; then
    user_slug="$(sh "$(dirname "$0")/../../gather/scripts/user-slug.sh" "$user_slug" 2>/dev/null || echo unknown)"
else
    user_slug="unknown"
fi

printf '{"ok": true, "path": "%s", "name": "%s", "slug": "%s", "remote": "%s", "visibility": "%s", "user_slug": "%s", "todo_dir": "%s", "source_repo": "%s"}\n' \
    "$target_root" "$name" "$(url_slug "$remote")" "$remote" "$(lookup_visibility "$remote")" "$user_slug" \
    "${target_root}/.workaholic/tickets/todo" \
    "$(basename -- "$SOURCE_ROOT")"
