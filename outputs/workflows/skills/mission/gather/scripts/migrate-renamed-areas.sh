#!/bin/sh -eu
# Living migration: move every .workaholic/ area the rename registry says has been
# renamed, and fix the machine-read links that name it.
#
# Sibling to migrate-todo-owners.sh and migrate-ticket-states.sh, run at the same
# seams, with the same contract: idempotent, best-effort, git-staged, and a clean
# no-op in a repository that never had the old shape. It differs from those two in
# one way that matters: they encode ONE change each, this one encodes whatever the
# registry declares (renames.tsv, read through list-renames.sh). That is the point —
# a rename costs a row, not a script.
#
# WHAT IT DOES, per `area` row (kind `name` is not its business — see below):
#   .workaholic/<old>/  ->  .workaholic/<old renamed to new>/     (git mv, staged)
#   .workaholic/index.md link `](<old>/` / `[<old>/`  ->  the new name
#
# THE LINK REWRITE IS DELIBERATELY NARROW. Only the BUNDLE-ROOT index is touched,
# because that file is generated (okf/scripts/refresh-index.sh) and its links are
# machine-read. Every other file under .workaholic/ — a story, an archived ticket, a
# feedback record — is HISTORY: it described what was true when it was written, and
# this repository's floors grandfather git-tracked history rather than rewrite it. A
# migration that swept those would be editing the record of what happened.
#
# WHAT IT REFUSES: a destination that already exists. Two areas holding files is a
# merge, and which file wins is an owner's decision, not a script's. Reported in
# `blocked` and left untouched, on the same reasoning that makes migrate-todo-owners
# refuse a filename collision.
#
# KIND `name` IS NOT APPLIED HERE, ever. A name lives in prose a human wrote and in a
# consuming repository's own documents; rename-conversions.sh finds those and PRINTS a
# conversion for the operator to run or decline (renames.tsv's header carries the
# reasoning). Keeping the two halves in two scripts is what stops the mechanical one
# from quietly growing a prose rewriter.
#
# Usage: migrate-renamed-areas.sh [workaholic-root]   (default .workaholic)
# Output: {"migrated": N, "moves": [{"from","to","since"}...],
#          "blocked": [{"path","reason"}...], "links_updated": N}
# Always exits 0 — a convergent step that stops a session is a step nobody runs.

set -eu

SCRIPT_DIR=$(dirname "$0")
WH_ROOT="${1:-.workaholic}"

moves=""
blocked=""
count=0
links=0
msep=""
bsep=""

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# `--rows` rather than the JSON face: this is POSIX sh, and a second JSON parser here
# is the drift list-renames.sh exists to prevent.
ROWS=$(sh "${SCRIPT_DIR}/list-renames.sh" --rows --kind area 2>/dev/null || true)

if [ -n "$ROWS" ] && [ -d "$WH_ROOT" ]; then
    while IFS='	' read -r kind old new since why; do
        [ -n "${old:-}" ] || continue
        src="${WH_ROOT}/${old}"
        dest="${WH_ROOT}/${new}"

        [ -d "$src" ] || continue

        if [ -e "$dest" ]; then
            blocked="${blocked}${bsep}{\"path\":\"$(esc "$src")\",\"reason\":\"destination_exists\"}"
            bsep=","
            echo "migrate-renamed-areas: ${dest} already exists; left ${src} in place" >&2
            continue
        fi

        if git mv "$src" "$dest" 2>/dev/null; then
            :
        else
            mv "$src" "$dest"
            git add -A "$dest" 2>/dev/null || true
            git add -A "$src" 2>/dev/null || true
        fi

        moves="${moves}${msep}{\"from\":\"$(esc "$src")\",\"to\":\"$(esc "$dest")\",\"since\":\"$(esc "$since")\"}"
        msep=","
        count=$((count + 1))

        # The generated bundle-root index, and nothing else. `refresh-index.sh` would
        # regenerate it anyway in a repository that runs the OKF seam, but a consuming
        # repository converging its layout may never reach that seam, and a root index
        # pointing at a directory that no longer exists is a broken bundle.
        index="${WH_ROOT}/index.md"
        if [ -f "$index" ] && grep -q "${old}/" "$index" 2>/dev/null; then
            tmp="${index}.rename.$$"
            sed -e "s|](${old}/|](${new}/|g" -e "s|\[${old}/|[${new}/|g" "$index" > "$tmp"
            mv "$tmp" "$index"
            git add "$index" 2>/dev/null || true
            links=$((links + 1))
        fi
    done <<EOF
$ROWS
EOF
fi

printf '{"migrated": %s, "moves": [%s], "blocked": [%s], "links_updated": %s}\n' \
    "$count" "$moves" "$blocked" "$links"
