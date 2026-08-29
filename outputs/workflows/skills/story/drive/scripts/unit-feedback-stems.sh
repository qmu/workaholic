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
# A TICKET'S REFS ARE REACHED THROUGH ITS MISSION (2026-08-29, ticket `20260829102500`).
# `/specificate` puts the carried-forward `feedback:` refs on the MISSION and its tickets carry
# `mission:` -- which is why `strategy/scripts/attributed-work.sh` has always needed its
# `via_mission:<slug>` hop. This resolver made no such hop, so a MISSION unit (whose artifact
# is `mission.md`) resolved its stems and a BATCH of that same mission's tickets resolved
# NOTHING. Measured 2026-08-29: unit `batch-20260829093639`, two tickets both naming a mission
# carrying two refs, answered `count: 0`; with no stem the notify lookup has nothing to search
# in case 2 and falls to case 4, so a follow-up unit's finish line starts a fresh thread beside
# the one its own item is already two replies deep in.
#
# THE HOP IS ARCHIVE-AWARE BECAUSE `mission_resolve` ALREADY IS -- active/ then archive/ then
# the legacy flat location. That matters most for exactly the shape that found this: the
# archive gate closes a mission the moment its last ticket is archived, so a follow-up driven
# after that resolves through an archived mission by construction. The ticket that provoked
# this named the archive as the CAUSE; the fixture refuted that -- a ticket naming an ACTIVE
# mission answered `count: 0` too -- so the repair is the missing hop, and archive-awareness
# is a property it inherits rather than the defect itself.
#
# THE RELATION STILL HAS ONE PARSER EACH. `mission:` is read through
# `mission/scripts/read-relation.sh` and `feedback:` through
# `specificate/scripts/read-feedback-relation.sh`; this composes them and parses neither.
# Direct refs come first and the mission's are appended, so a stem set that used to be
# non-empty is a PREFIX of the new one and the first-sorting-stem rule sees what it saw.
#
# AN EMPTY RESULT IS AN ANSWER, NOT A FAILURE: exit 0 with `count: 0`. The caller keys
# such a unit on `unit:<unit-id>` instead (drive SKILL, §5) -- never on nothing, and never
# as a keyless top-level line. A `mission:` slug that resolves to no mission.md leaves the
# hop empty for that artifact and is not an error either: the artifact may name a mission
# this checkout has never had.
#
# Never load-bearing: this resolves where a *notification* lands. Nothing about the
# survey, the claim, or the implementation reads it.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
READER="${SCRIPT_DIR}/../../specificate/scripts//read-feedback-relation.sh"
MISSION_READER="${SCRIPT_DIR}/../../mission/scripts//read-relation.sh"
MISSION_RESOLVE="${SCRIPT_DIR}/../../mission/scripts//lib/resolve.sh"

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

# THE MISSION HOP, appended after the direct refs (see the header). Only `mission_resolve` is
# used from the resolve library — never `missions_migrate_layout` or `missions_migrate_status`,
# which STAGE what they converge; this resolver is read-only and a caller that staged would
# dirty a checkout to decide where a Slack post goes.
if [ -f "$MISSION_READER" ] && [ -f "$MISSION_RESOLVE" ]; then
    # shellcheck source=/dev/null
    . "$MISSION_RESOLVE"
    for f in $present; do
        for slug in $(sh "$MISSION_READER" "$f" 2>/dev/null || true); do
            [ -n "$slug" ] || continue
            mpath=$(mission_resolve "$(missions_root_from_artifact "$f")" "$slug" 2>/dev/null || true)
            [ -n "$mpath" ] && [ -f "$mpath" ] || continue
            raw="${raw}
$(sh "$READER" "$mpath" 2>/dev/null || true)"
        done
    done
fi

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
