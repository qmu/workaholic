#!/bin/sh -eu
# Resolve a PR-unit's ARTIFACTS to the feedback record STEMS whose Slack threads its
# start and finish posts belong in (workaholify SKILL, *One thread per feedback item*).
#
# Usage: unit-feedback-stems.sh <artifact-file>...
#   mission unit -> the mission's mission.md
#   batch unit   -> the unit's ticket files
# Output: {"count": N, "stems": ["<stem>", ...]}
#
# A *stem* is the feedback record's filename without `.md` -- exactly the token a thread
# root carries as `fb:<stem>`. The `feedback:` field stores the filename, so stripping the
# extension here is the whole translation, and it happens in one place so no caller
# invents a second spelling of the key.
#
# THE RELATION IS READ THROUGH ITS ONE READER (specificate/scripts/read-feedback-relation.sh),
# never re-parsed. Two parsers of the same frontmatter field eventually disagree, and the
# side that under-reads posts into a thread nobody is watching.
#
# ORDER IS PRESERVED AND DUPLICATES ARE DROPPED. A batch's tickets routinely trace to the
# same record, and a unit must not post the same line twice into one thread; two tickets
# tracing to two records is the case that legitimately yields two stems, and both are
# reported because each item's thread is supposed to carry that item's whole life.
#
# AN EMPTY RESULT IS AN ANSWER, NOT A FAILURE: exit 0 with `count: 0`. The caller keys
# such a unit on `unit:<unit-id>` instead (drive SKILL, §5) -- never on nothing, and never
# as a keyless top-level line.
#
# Never load-bearing: this resolves where a *notification* lands. Nothing about the
# survey, the claim, or the implementation reads it.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
READER="${SCRIPT_DIR}/../../specificate/scripts//read-feedback-relation.sh"

emit() {
    printf '{"count": %s, "stems": [' "$1"
    shift
    sep=""
    for s in "$@"; do
        printf '%s"%s"' "$sep" "$s"
        sep=", "
    done
    printf ']}\n'
}

if [ "$#" -eq 0 ] || [ ! -f "$READER" ]; then
    emit 0
    exit 0
fi

# Existing files only: a caller passes a claim's artifact list, and a ticket archived by a
# previous pass of the same run is no longer at the path the claim stamped.
present=""
for f in "$@"; do
    [ -f "$f" ] || continue
    present="${present} ${f}"
done

if [ -z "$present" ]; then
    emit 0
    exit 0
fi

# shellcheck disable=SC2086
raw=$(sh "$READER" $present 2>/dev/null || true)

stems=""
count=0
for ref in $raw; do
    stem=${ref%.md}
    [ -n "$stem" ] || continue
    case " ${stems} " in
        *" ${stem} "*) continue ;;
    esac
    stems="${stems} ${stem}"
    count=$((count + 1))
done

# shellcheck disable=SC2086
emit "$count" $stems
