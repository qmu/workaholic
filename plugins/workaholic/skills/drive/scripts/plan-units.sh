#!/bin/sh -eu
# The SURVEY half of the unified drive's partitioning: report everything that is
# claimable right now, with the in-flight claims already subtracted.
#
# Usage: plan-units.sh
# Output: JSON
#   {"fetched": bool, "base": "<ref>",
#    "claimed": [{"unit": "...", "branch": "...", "stale": bool}],
#    "missions": [{"slug", "title", "merge_policy", "checked", "total", "next", "path"}],
#    "backlog":  [{"path", "title", "type", "layer", "merge_policy", "depends_on"}],
#    "excluded": [{"kind": "mission"|"ticket", "id": "...", "reason": "..."}]}
#
# THE SPLIT IS THE POINT (docs/loop-engineering-workflow.md G2). Partitioning the
# work into PR-units is two different jobs, and only one of them is mechanical:
#
#   * WHAT IS AVAILABLE is derivable -- approved missions, this developer's todo
#     queue, minus whatever a claim already holds. That is this script, and it is
#     deterministic so two runners on two machines survey the same world.
#   * WHAT DESERVES ONE MERGE is judgment -- which backlog tickets are related
#     enough to share a PR. That stays with the executor (drive/SKILL.md, *Unified
#     Run* §2), which is why no grouping heuristic lives here. A script that
#     guessed at relatedness would make the conservative "when unsure, one ticket
#     per unit" bar unreachable, because nothing downstream could tell a confident
#     grouping from a coincidental one.
#
# CLAIMS ARE READ THROUGH THE SHARED SCAN (lib/claims.sh) -- the same
# implementation list-claims.sh renders and claim.sh verifies against. A surveyor
# with its own scan could offer a unit the writer would then refuse, so all three
# read one scan. Both subtractions matter: the UNIT id keeps a claimed mission out
# of the offer, and the ARTIFACT paths keep an already-batched ticket out of it.
#
# NOTHING IS EXCLUDED SILENTLY. Every mission and ticket the survey drops is
# reported in `excluded` with its reason (`claimed`, `not_approved`, `no_plan`,
# `mission_member`), because a queue item that vanishes from an unattended run's
# offer with no trace is indistinguishable from one that was never there
# (`workaholic:implementation` / observability).
#
# Pure read: it fetches (through the shared reader) and inspects, and writes nothing.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/claims.sh"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"error": "not inside a git repository"}' >&2
    exit 1
fi

MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"

# JSON-escape a value (backslash and double-quote only; titles are plain text --
# the same assumption list.sh makes about .workaholic/ artifacts).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read one frontmatter key from a file ("" when absent). First match inside the
# leading --- block wins, like every other frontmatter reader in the plugin.
fm_field() {
    awk -v key="$2" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$1" 2>/dev/null || true
}

# The document title: the first H1, falling back to the filename stem.
doc_title() {
    _dt=$(awk '/^# / { sub(/^# [ \t]*/, ""); print; exit }' "$1" 2>/dev/null || true)
    [ -n "$_dt" ] || _dt=$(basename "$1" .md)
    printf '%s' "$_dt"
}

# --- the claims in flight -----------------------------------------------------
FETCHED=$(claims_fetch)
BASE=$(claims_base)
ROWS=$(claims_scan "$BASE")

CLAIMED_UNITS=""
CLAIMED_ARTIFACTS=""
CLAIMED_JSON=""
if [ -n "$ROWS" ]; then
    sep=""
    while IFS='	' read -r c_unit c_branch _c_at c_stale c_arts; do
        [ -n "$c_unit" ] || continue
        CLAIMED_UNITS="${CLAIMED_UNITS}${c_unit}
"
        old_ifs="$IFS"
        IFS=','
        for art in $c_arts; do
            CLAIMED_ARTIFACTS="${CLAIMED_ARTIFACTS}${art}
"
        done
        IFS="$old_ifs"
        CLAIMED_JSON="${CLAIMED_JSON}${sep}{\"unit\": \"${c_unit}\", \"branch\": \"${c_branch}\", \"stale\": ${c_stale}}"
        sep=", "
    done <<EOF
$ROWS
EOF
fi

is_claimed_unit() {
    printf '%s' "$CLAIMED_UNITS" | grep -qx -- "$1" 2>/dev/null
}
is_claimed_artifact() {
    printf '%s' "$CLAIMED_ARTIFACTS" | grep -qx -- "$1" 2>/dev/null
}

EXCLUDED=""
exc_sep=""
exclude() {
    EXCLUDED="${EXCLUDED}${exc_sep}{\"kind\": \"${1}\", \"id\": \"$(json_escape "$2")\", \"reason\": \"${3}\"}"
    exc_sep=", "
}

# --- approved missions --------------------------------------------------------
# The status IS the authorization (docs/loop-engineering-workflow.md I2), and an
# approved mission with an empty ## Acceptance authorizes work against no bar at
# all -- the same floor drive-authorized.sh applies per ticket, applied here to
# the offer so a planless mission is never handed to an unattended run.
MISSIONS=""
m_sep=""
if [ -d ".workaholic/missions/active" ]; then
    for d in $(find .workaholic/missions/active -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort); do
        f="${d}/mission.md"
        [ -f "$f" ] || continue
        slug=$(basename "$d")
        status=$(fm_field "$f" status)
        if [ "$status" != "approved" ]; then
            exclude mission "$slug" "not_approved"
            continue
        fi
        if is_claimed_unit "$slug" || is_claimed_artifact "$f"; then
            exclude mission "$slug" "claimed"
            continue
        fi
        progress=$(sh "${MISSION_SCRIPTS}/progress.sh" "$f" 2>/dev/null || true)
        checked=$(printf '%s' "$progress" | sed -n 's/.*"checked": *\([0-9][0-9]*\).*/\1/p')
        total=$(printf '%s' "$progress" | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p')
        [ -n "$checked" ] || checked=0
        [ -n "$total" ] || total=0
        if [ "$total" -eq 0 ]; then
            exclude mission "$slug" "no_plan"
            continue
        fi
        title=$(json_escape "$(fm_field "$f" title)")
        policy=$(json_escape "$(fm_field "$f" merge_policy)")
        next=$(json_escape "$(sh "${MISSION_SCRIPTS}/next-acceptance.sh" "$f" 2>/dev/null || true)")
        MISSIONS="${MISSIONS}${m_sep}{\"slug\": \"${slug}\", \"title\": \"${title}\", \"merge_policy\": \"${policy}\", \"checked\": ${checked}, \"total\": ${total}, \"next\": \"${next}\", \"path\": \"$(json_escape "$f")\"}"
        m_sep=", "
    done
fi

# --- the unclaimed backlog ----------------------------------------------------
# The current developer's todo queue (list-todo.sh is already user-scoped), minus
# anything a claim holds, minus anything a mission already owns: a missioned
# ticket is driven as part of its mission's unit, in that mission's worktree, so
# offering it here would split one plan across two PRs.
BACKLOG=""
b_sep=""
for t in $(sh "${SCRIPT_DIR}/list-todo.sh" 2>/dev/null || true); do
    [ -f "$t" ] || continue
    if is_claimed_artifact "$t"; then
        exclude ticket "$t" "claimed"
        continue
    fi
    relation=$(sh "${MISSION_SCRIPTS}/read-relation.sh" "$t" 2>/dev/null || true)
    if [ -n "$relation" ]; then
        exclude ticket "$t" "mission_member"
        continue
    fi
    title=$(json_escape "$(doc_title "$t")")
    ttype=$(json_escape "$(fm_field "$t" type)")
    layer=$(json_escape "$(fm_field "$t" layer)")
    policy=$(json_escape "$(fm_field "$t" merge_policy)")
    depends=$(json_escape "$(fm_field "$t" depends_on)")
    BACKLOG="${BACKLOG}${b_sep}{\"path\": \"$(json_escape "$t")\", \"title\": \"${title}\", \"type\": \"${ttype}\", \"layer\": \"${layer}\", \"merge_policy\": \"${policy}\", \"depends_on\": \"${depends}\"}"
    b_sep=", "
done

printf '{"fetched": %s, "base": "%s", "claimed": [%s], "missions": [%s], "backlog": [%s], "excluded": [%s]}\n' \
    "$FETCHED" "$BASE" "$CLAIMED_JSON" "$MISSIONS" "$BACKLOG" "$EXCLUDED"
