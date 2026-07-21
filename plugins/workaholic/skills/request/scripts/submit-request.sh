#!/bin/sh -eu
# Submit a confirmed, masked request as a ticket to ANOTHER repository.
#
# Usage: submit-request.sh <target-repo-root> <ticket-filename> <body-file>
#
# This is the ONLY sanctioned writer of a cross-repository artifact. Everything else is
# refused by hooks/guard-repo-confinement.sh. That guard watches the Write/Edit tools and
# does not see a script like this one — which is the point: the casual path is closed and
# the deliberate path runs here, where the caller has already shown the developer exactly
# what will be submitted and had them confirm it.
#
# This script does NOT mask and does NOT judge. By the time it runs, the body is already
# masked and confirmed. It refuses only the mechanical mistakes: a target that is not a
# repo, a body that is empty, a filename that is not ticket-shaped, and — as a last
# backstop, not a substitute for the confirmation — a body still carrying this repo's own
# name or path.
#
# Emits JSON: { ok, path } or { ok: false, error }.

set -eu

emit_err() {
    printf '{"ok": false, "error": "%s"}\n' "$1"
    exit 0
}

target="${1:-}"
filename="${2:-}"
body_file="${3:-}"

[ -n "$target" ]    || emit_err "no target repo given"
[ -n "$filename" ]  || emit_err "no filename given"
[ -n "$body_file" ] || emit_err "no body file given"
[ -f "$body_file" ] || emit_err "body file not found: ${body_file}"
[ -s "$body_file" ] || emit_err "body is empty — nothing to submit"

printf '%s' "$filename" | grep -qE '^[0-9]{14}-[a-z0-9-]+\.md$' \
    || emit_err "filename must be YYYYMMDDHHmmss-kebab-slug.md, got: ${filename}"

git -C "$target" rev-parse --show-toplevel >/dev/null 2>&1 || emit_err "not a git repository: ${target}"
target_root="$(git -C "$target" rev-parse --show-toplevel)"

SOURCE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ "$target_root" != "$SOURCE_ROOT" ] || emit_err "target is this repository — use /ticket, not /request"

# Last backstop. Deterministic, and deliberately narrow: it knows only this repo's own
# name and path, which are the two things always mechanically knowable. It cannot know a
# customer's vocabulary — that is what the confirmation is for, and a pass here means
# nothing beyond "our own name is absent".
source_name="$(basename -- "$SOURCE_ROOT")"
if grep -qiF -- "$source_name" "$body_file" 2>/dev/null; then
    emit_err "body still names this repository ('${source_name}') — mask it and re-confirm"
fi
if grep -qF -- "$SOURCE_ROOT" "$body_file" 2>/dev/null; then
    emit_err "body still contains this repository's path — mask it and re-confirm"
fi

user_slug="$(git -C "$target_root" config user.email 2>/dev/null | tr '@.' '--' || echo "")"
[ -n "$user_slug" ] || user_slug="$(git config user.email 2>/dev/null | tr '@.' '--' || echo unknown)"

dest_dir="${target_root}/.workaholic/tickets/todo/${user_slug}"
dest="${dest_dir}/${filename}"
[ -e "$dest" ] && emit_err "already exists: ${dest}"

mkdir -p "$dest_dir"
cp -- "$body_file" "$dest"

printf '{"ok": true, "path": "%s"}\n' "$dest"
