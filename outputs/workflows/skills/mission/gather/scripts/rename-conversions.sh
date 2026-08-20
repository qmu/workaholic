#!/bin/sh -eu
# THE PROPOSAL HALF of the rename registry: find every surviving occurrence of a
# renamed name and PRINT the bulk conversion for it. It writes nothing, anywhere.
#
# WHY IT PROPOSES INSTEAD OF APPLYING. migrate-renamed-areas.sh moves a .workaholic/
# directory because that path is machine-owned and has exactly one correct
# destination. A NAME is different in kind: it lives in prose a human wrote, in a
# consuming repository's own documents, and in vocabulary that may deliberately
# differ from this plugin's. This repository's standing rule is that everything
# needing a judgment is reported with the decision it needs and never guessed
# (converge-layout.sh's header, and the `retired-area` class it names). `report` is
# also an ordinary English word — `/catch` reports, a step "reports" its status — so a
# blind sed is the failure mode this script exists to avoid rather than automate.
#
# It reports EVERY row, not just `name` rows: moving .workaholic/<old>/ does not move
# the dozens of scripts and sentences that name the old area, and those are prose and
# code, which is the proposed half by definition.
#
# WHAT IT DOES NOT SEARCH, and why each is deliberate:
#   .workaholic/   HISTORY. A story or an archived ticket described what was true when
#                  it was written; git-tracked history is grandfathered by every floor
#                  in this repository, and offering to rewrite it is offering to edit
#                  the record of what happened.
#   outputs/       GENERATED. Its conversion is `node scripts/build-plugins/build.mjs`,
#                  not sed; hand-editing it fails the `Outputs Freshness` CI.
#   .git/ .worktrees/ .publish/ .explain/   not the repository's content.
#   renames.tsv    THE TABLE ITSELF. Its whole job is to name the old name; converting
#                  it would delete the row that drives the conversion.
#
# Usage: rename-conversions.sh [repo-root]   (default: the git top level, else cwd)
# Output: {"repo": "<path>", "readable": true|false, "conversions": [
#            {"kind","old","new","since","why","count","files":[...],"command": "..."}]}
#   Rows with no surviving occurrence are omitted — a converged repository prints an
#   empty list, which is the signal that the rename is finished and the row can be
#   deleted from the table.
# Always exits 0. A read-only proposal that errors a session is a proposal nobody sees.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT="${1:-}"
if [ -z "$ROOT" ]; then
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

ROWS=$(sh "${SCRIPT_DIR}/list-renames.sh" --rows 2>/dev/null || true)

if [ -z "$ROWS" ]; then
    printf '{"repo": "%s", "readable": true, "conversions": []}\n' "$(esc "$ROOT")"
    exit 0
fi

# One exclusion list, used by the search and quoted verbatim into the suggested
# command, so what the operator would run matches what was counted.
EXCLUDES='--exclude-dir=.git --exclude-dir=.workaholic --exclude-dir=outputs --exclude-dir=.worktrees --exclude-dir=.publish --exclude-dir=.explain --exclude-dir=node_modules --exclude=renames.tsv'

items=""
sep=""

while IFS='	' read -r kind old new since why; do
    [ -n "${old:-}" ] || continue

    # -F: the old name may contain / and . (`/report`, `workaholic:report`); it is a
    # literal token, never a pattern.
    files=$(cd "$ROOT" && grep -rlF $EXCLUDES -- "$old" . 2>/dev/null | sed 's|^\./||' | sort || true)
    [ -n "$files" ] || continue

    n=$(printf '%s\n' "$files" | grep -c . || true)

    flist=""
    fsep=""
    for f in $files; do
        flist="${flist}${fsep}\"$(esc "$f")\""
        fsep=","
    done

    cmd="grep -rlF ${EXCLUDES} -- '${old}' . | xargs sed -i \"s|${old}|${new}|g\""

    items="${items}${sep}{\"kind\":\"$(esc "$kind")\",\"old\":\"$(esc "$old")\",\"new\":\"$(esc "$new")\",\"since\":\"$(esc "$since")\",\"why\":\"$(esc "$why")\",\"count\":${n},\"files\":[${flist}],\"command\":\"$(esc "$cmd")\"}"
    sep=","
done <<EOF
$ROWS
EOF

printf '{"repo": "%s", "readable": true, "conversions": [%s]}\n' "$(esc "$ROOT")" "$items"
