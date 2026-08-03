#!/bin/sh -eu
# Flip the ## Acceptance checklist item that references <artifact-filename> from
# "- [ ]" to "- [x]". The item is matched by its "(#<artifact-filename>)" marker (the
# acceptance-to-artifact link defined by the mission schema, stamped at emission by
# link-acceptance.sh). Idempotent: an already-checked item, or no matching item, is a
# no-op. Scoped to the ## Acceptance section, so a bullet elsewhere is never flipped.
# Progress stays derived — this only changes checklist state; progress.sh computes
# checked/total. The mission file is git-staged so the calling seam's commit carries it.
#
# THE MATCH IS ITEM-SCOPED, NOT LINE-SCOPED. An acceptance criterion long enough to wrap
# carries its marker on a continuation line, and a line-scoped match would leave exactly
# that item unreachable — a formatting requirement wearing a link's clothes.
#
# THE RESULT SEPARATES "NOT SATISFIED" FROM "NOT ADDRESSABLE", which one reason used to
# conflate so a caller could not tell them apart:
#   already_checked    - an item this artifact links to is satisfied already
#   unlinked_items     - the board carries UNCHECKED items with no link at all, so no
#                        artifact could ever tick them (the stranded-board case)
#   no_unchecked_match - the open items are linked; this artifact does not satisfy one
# `unlinked` rides on every result, so a seam reports the stranded count without a
# second read. unlinked-acceptance.sh names the items. See reference/schema.md.
#
# Usage: tick-acceptance.sh <mission-slug-or-file> <artifact-filename>
# Output: JSON {ticked, path, unlinked[, reason]}

set -eu

ARG="${1:-}"
ARTIFACT="${2:-}"
if [ -z "$ARG" ] || [ -z "$ARTIFACT" ]; then
    echo '{"ticked": false, "reason": "missing_args"}' >&2
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"ticked": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

TMP="${FILE}.$$.tmp"

# One pass: collect the ## Acceptance items (a checklist line plus its indented
# continuation lines), flip every unchecked item carrying the marker, and report
# "<changed> <matched-checked> <unlinked>" for the shell to turn into a verdict.
# The boxes are written with alternation ("\[( |x|X)\]") rather than a nested character
# class so the source never contains a literal "[[" the POSIX lint would misread as a
# bash test.
RESULT=$(awk -v artifact="$ARTIFACT" -v tmp="$TMP" '
    BEGIN { in_acc = 0; n = 0; n_open = 0; changed = 0; hit_checked = 0; unlinked = 0; marker = "(#" artifact ")" }
    {
        line[NR] = $0
        if ($0 ~ /^## /) { n_open = 0; in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
        if (!in_acc) next
        if ($0 ~ /^[ \t]*-[ \t]+\[( |x|X)\]/) { n++; text[n] = $0; head[n] = NR; n_open = 1; next }
        if (n_open && $0 ~ /^[ \t]+[^ \t]/) { text[n] = text[n] " " $0; next }
        n_open = 0
    }
    END {
        for (i = 1; i <= n; i++) {
            checked = (text[i] ~ /^[ \t]*-[ \t]+\[(x|X)\]/)
            linked = (text[i] ~ /\(#[^)]+\)/)
            if (!checked && !linked) unlinked++
            if (index(text[i], marker) == 0) continue
            if (checked) { hit_checked = 1; continue }
            flip[head[i]] = 1
            changed = 1
        }
        for (i = 1; i <= NR; i++) {
            out = line[i]
            if (flip[i]) sub(/\[ \]/, "[x]", out)
            print out > tmp
        }
        printf "%d %d %d", changed, hit_checked, unlinked
    }
' "$FILE")

CHANGED=$(printf '%s' "$RESULT" | cut -d' ' -f1)
HIT_CHECKED=$(printf '%s' "$RESULT" | cut -d' ' -f2)
UNLINKED=$(printf '%s' "$RESULT" | cut -d' ' -f3)

if [ "$CHANGED" = "1" ]; then
    mv "$TMP" "$FILE"
    git add "$FILE" 2>/dev/null || true
    printf '{"ticked": true, "path": "%s", "unlinked": %d}\n' "$FILE" "$UNLINKED"
    exit 0
fi

rm -f "$TMP"
if [ "$HIT_CHECKED" = "1" ]; then
    REASON="already_checked"
elif [ "$UNLINKED" -gt 0 ]; then
    REASON="unlinked_items"
else
    REASON="no_unchecked_match"
fi
printf '{"ticked": false, "reason": "%s", "path": "%s", "unlinked": %d}\n' "$REASON" "$FILE" "$UNLINKED"
