#!/bin/sh -eu
# Whose work is this unit? — the disclosure `/implement`'s run report and finish
# line carry when a claimed unit's tickets were written by somebody else.
#
# WHY IT EXISTS (2026-08-14, issue #454). A developer who enabled `[Implement]`
# under their own identity expected it to take their own and genuinely team-owned
# work. It took colleagues' work and, on the immediate-merge route, merged it —
# through no human gate, with nothing in the run report or the Slack finish line
# saying whose work it was. The sibling tickets close the *legacy-layout* case
# (`owners.sh`'s path tier, `archive.sh`'s convergence). This covers what stays
# true afterwards: a genuinely unowned ticket (empty `assignees:`) is claimable by
# anyone BY DESIGN, and when a runner takes one, the fact that someone else wrote
# it belongs where a human reads the outcome.
#
# THIS IS DISCLOSURE, NOT OWNERSHIP. `author:` is immutable history and is
# deliberately not an ownership tier (`gather/scripts/owners.sh` header) — reading
# it for a report line is fine, reading it for a claim decision would re-create the
# defect P2 removed. Nothing here is consulted by the survey, the claim, or the
# route; the run's behaviour is identical with and without it.
#
# ONE IDENTITY COMPARISON, NOT A SECOND ONE. Comparison is by slug through
# `gather/scripts/user-slug.sh`, exactly as `owns.sh` compares owners — so
# `A@Qmu.jp`, `a@qmu.jp` and a migration-stamped `a-qmu-jp` are one person here for
# the same reason they are one person there.
#
# `unresolved` IS ITS OWN VERDICT, for the same reason `owns.sh` keeps it: a runner
# with no identity to compare against does not know the tickets are its own, and
# rendering that as "authored by me" is the silence this whole change removes.
#
# Usage: unit-authors.sh <artifact-file>...
# Output: one JSON line
#   {"verdict": "mine"|"foreign"|"unresolved", "runner": "<slug>",
#    "authors": [...], "foreign_authors": [...]}
#
#   mine        every readable author is the runner (or none names one)
#   foreign     at least one artifact was authored by another identity
#   unresolved  this runner has no identity to compare against
#
# Only `foreign` and `unresolved` earn a line: a unit whose tickets are all the
# runner's own adds nothing anywhere.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts/"

json_list() {
    # $1: newline-delimited values -> a JSON array body
    printf '%s' "$1" | awk 'NF { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "%s\"%s\"", (n++ ? ", " : ""), $0 }'
}

authors=''
for f in "$@"; do
    [ -f "$f" ] || continue
    a=$(awk '
    NR == 1 { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    /^author:[ \t]*/ { sub(/^author:[ \t]*/, ""); sub(/[ \t]+$/, ""); if (length($0) > 0) print; exit }
    ' "$f" 2>/dev/null || true)
    [ -n "$a" ] || continue
    case "
${authors}" in
        *"
${a}"*) ;;
        *) authors="${authors}${authors:+
}${a}" ;;
    esac
done

me=$(git config user.email 2>/dev/null || true)
my_slug=''
[ -n "$me" ] && my_slug=$(sh "${GATHER}/user-slug.sh" "$me" 2>/dev/null || true)

if [ -z "$my_slug" ]; then
    printf '{"verdict": "unresolved", "runner": "", "authors": [%s], "foreign_authors": []}\n' "$(json_list "$authors")"
    exit 0
fi

foreign=''
for a in $authors; do
    a_slug=$(sh "${GATHER}/user-slug.sh" "$a" 2>/dev/null || true)
    [ "$a_slug" = "$my_slug" ] && continue
    foreign="${foreign}${foreign:+
}${a}"
done

verdict=mine
[ -n "$foreign" ] && verdict=foreign

printf '{"verdict": "%s", "runner": "%s", "authors": [%s], "foreign_authors": [%s]}\n' \
    "$verdict" "$my_slug" "$(json_list "$authors")" "$(json_list "$foreign")"
