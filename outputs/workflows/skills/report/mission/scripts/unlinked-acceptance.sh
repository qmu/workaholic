#!/bin/sh -eu
# Name the acceptance items no artifact can ever tick: the UNCHECKED items carrying no
# (#<filename>) link. This is the audit half of the link contract — progress.sh counts
# them so a stranded board cannot hide, and this says WHICH items they are, which is what
# makes the repair a scripted per-item link rather than a hand-edited checkbox.
#
# Pure read; writes nothing. With a mission argument it reports that mission; with none it
# sweeps every mission under .workaholic/missions/active/ (the repo-wide measurement —
# 2026-08-03 it was 37 items across six missions, every one proposal-scaffolded).
# Missions with nothing unlinked are omitted, so empty output means a clean tree.
#
# Usage: unlinked-acceptance.sh [<mission-slug-or-file>]
# Output: JSON [{slug, path, items: [{index, text}]}] — index is the item's 1-based
#         position in ## Acceptance, which is exactly link-acceptance.sh's selector.

set -eu

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"

ARG="${1:-}"

if [ -n "$ARG" ]; then
    ROOT=$(missions_root_for_arg "$ARG")
    missions_migrate_layout "$ROOT"
    FILE=$(mission_resolve "$ROOT" "$ARG")
    [ -f "$FILE" ] || { printf '{"error": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }
    FILES="$FILE"
else
    ROOT=$(missions_root_default)
    missions_migrate_layout "$ROOT"
    FILES=$(find "${ROOT}/missions/active" -name mission.md -type f 2>/dev/null | sort || true)
fi

# Emit one item per line as "<index>\t<text>" for the mission in $1. The item is its
# checklist line plus indented continuations, so a wrapped criterion is judged whole and
# its display text reads as one line. The boxes use alternation ("\[( |x|X)\]") rather
# than a nested character class so the source carries no literal "[[" for the POSIX lint.
scan() {
    awk '
        BEGIN { in_acc = 0; n = 0; n_open = 0 }
        /^## / { n_open = 0; in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
        !in_acc { next }
        /^[ \t]*-[ \t]+\[( |x|X)\]/ { n++; text[n] = $0; n_open = 1; next }
        n_open && /^[ \t]+[^ \t]/ { text[n] = text[n] " " $0; next }
        { n_open = 0 }
        END {
            for (i = 1; i <= n; i++) {
                if (text[i] ~ /^[ \t]*-[ \t]+\[(x|X)\]/) continue
                if (text[i] ~ /\(#[^)]+\)/) continue
                display = text[i]
                sub(/^[ \t]*-[ \t]+\[[^]]*\][ \t]*/, "", display)
                gsub(/[ \t]+/, " ", display)
                printf "%d\t%s\n", i, display
            }
        }
    ' "$1"
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

OUT="["
FIRST=1
for f in $FILES; do
    [ -f "$f" ] || continue
    ITEMS=$(scan "$f")
    [ -n "$ITEMS" ] || continue
    slug=$(basename "$(dirname "$f")")
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"$(json_escape "$slug")\",\"path\":\"$(json_escape "$f")\",\"items\":["
    IFIRST=1
    # Read the scan's tab-separated lines; the text is the remainder of the line, so a
    # criterion containing a tab still reads back whole.
    while IFS= read -r row; do
        idx=${row%%	*}
        text=${row#*	}
        [ "$IFIRST" -eq 1 ] || OUT="${OUT},"
        IFIRST=0
        OUT="${OUT}{\"index\":${idx},\"text\":\"$(json_escape "$text")\"}"
    done <<EOF
$ITEMS
EOF
    OUT="${OUT}]}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
