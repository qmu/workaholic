#!/bin/sh -eu
# The SURVEY half of the unified drive's partitioning: report everything that is
# claimable right now, with the in-flight claims already subtracted.
#
# Usage: plan-units.sh
# Output: JSON
#   {"fetched": bool, "base": "<ref>",
#    "surveyed_sha": "<sha of the checkout's HEAD>", "base_sha": "<sha of <base>>",
#    "current": bool,
#    "user_slug": "<the surveyed developer's queue slug, "" when unresolvable>",
#    "backlog_error": "<reason, "" when the queue was read>",
#    "claimed": [{"unit": "...", "branch": "...", "stale": bool}],
#    "missions": [{"slug", "title", "merge_policy", "checked", "total", "next", "path"}],
#    "backlog":  [{"path", "title", "type", "layer", "merge_policy", "depends_on"}],
#    "excluded": [{"kind": "mission"|"ticket", "id": "...", "reason": "..."}]}
#
# IT STATES ITS OWN FRESHNESS, AND STILL DOES NOT FIX IT (decision J3). Claims come
# from git refs, but the ARTIFACTS come from the working tree this runs in -- so a
# checkout behind <base> surveys a stale queue and reports it confidently. That
# defect is closed by the CALLER (commands/drive.md runs branching/sync-main.sh
# before surveying), not here: a script named "plan units" that mutated the checkout
# would surprise every other caller, and this one is deliberately callable where
# reading must be side-effect-free (including inside a claim worktree).
#
# What it owes the caller instead is the FACT: `surveyed_sha` is what the working
# tree actually holds, `base_sha` is where <base> points, and `current` is whether
# the survey is KNOWN current -- the shas agree AND the fetch succeeded, since an
# offline runner matching its own last-known ref has established nothing about the
# base. `current: false` means this survey could not see everything on the base, and
# the run's terminal token may not be `ok` on the strength of it. There is
# no `excluded` reason for staleness because a stale checkout does not drop a NAMED
# item -- it never learns the item exists, which is exactly why the condition has to
# be reported as a property of the survey rather than of an artifact.
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
# reported in `excluded` with its reason (`claimed`, `not_approved`, `owned_by_other`,
# `no_plan`, `no_tickets`, `mission_member`), because a queue item that vanishes from
# an unattended run's offer with no trace is indistinguishable from one that was never
# there (`workaholic:implementation` / observability).
#
# `no_plan` and `no_tickets` are DELIBERATELY DISTINCT, because they call for
# different developer actions: `no_plan` means write the acceptance criteria,
# `no_tickets` means emit the ticket set (`/mission <instruction>` replans it). The
# reason vocabulary is read straight out of cron logs, so collapsing them would make
# the log less actionable.
#
# AN UNREADABLE QUEUE IS NOT AN EMPTY ONE. The backlog half is scoped to the current
# developer, so it has a failure mode the mission half does not: with no
# `git config user.email` there is no queue directory to name, and a survey that
# discarded that status would emit `backlog: []` and let the run terminate `ok` over
# a full queue. So the read's status is captured, not swallowed: `backlog_error` names
# the reason (`identity_unresolved`, `unreadable`) and is `""` when the queue was
# genuinely read, and `user_slug` reports WHOSE queue was surveyed. A non-empty
# `backlog_error` forbids `ok` exactly as `current: false` does (drive/SKILL.md §7).
# It is a top-level key rather than an `excluded[]` entry for the same reason `current`
# is: `excluded[]` names artifacts the survey SAW and dropped, and this condition is
# that it never learned any artifact exists.
#
# MISSIONS ARE FILTERED BY OWNERSHIP, through the one oracle every other consumer
# already reads (mission/scripts/mission-owners.sh -- plural `assignees`, legacy
# fallback to the singular `assignee`). The gate is the mission lens's, verbatim: a
# mission is offerable when the runner's identity is AMONG its owners, or it has no
# owners at all (team-owned = claimable); only a mission owned solely by others is
# dropped, as `owned_by_other`. Without this the executor was the single ownership
# consumer answering differently from the roadmap the developer is shown -- and an
# unattended runner would claim a colleague's approved mission and, under
# `merge_policy: auto`, drive it to `main`.
#
# Pure read: it fetches (through the shared reader) and inspects, and writes nothing.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/claims.sh"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"error": "not inside a git repository"}' >&2
    exit 1
fi

MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts/"

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

# --- freshness, reported never repaired (see the header) -----------------------
# `claims_fetch` above updated the remote-tracking refs, so BASE reflects the remote
# when it succeeded. Comparing the two shas is most of the check --
#
# -- but `current` requires FETCHED too, and that conjunction is the honest part.
# Offline, BASE is only the last-known ref, so "my HEAD equals origin/main" means
# "I match what I remember", not "I match the base". Reporting `current: true` there
# would let a runner that cannot reach the remote at all emit `ok`, which is the
# confident-stale-survey this field exists to make impossible.
SURVEYED_SHA=$(git rev-parse HEAD 2>/dev/null || printf '')
BASE_SHA=$(git rev-parse --verify --quiet "${BASE}^{commit}" 2>/dev/null || printf '')
if [ "$FETCHED" = "true" ] && [ -n "$SURVEYED_SHA" ] && [ "$SURVEYED_SHA" = "$BASE_SHA" ]; then
    CURRENT=true
else
    CURRENT=false
fi

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
# all, so the offer applies that floor too -- a planless mission is never handed to
# an unattended run.
#
# BUT ACCEPTANCE ITEMS ARE NOT A QUEUE, and the offer needs both floors. `/propose`
# writes a provisional acceptance SKETCH, which satisfies an item count with zero
# tickets: on 2026-07-30 an approved mission with `merge_policy: auto`, `tickets: []`
# and an acceptance block reading "PROPOSED sketch -- not a plan" was offered here as
# claimable. So drivability is also checked against the ticket queue itself
# (`mission/scripts/queue-size.sh`, the single reader both floors call), and a mission
# with nothing left in todo/ is excluded `no_tickets`.
#
# Ownership is applied FIRST among the approved-mission checks, because "not my work"
# is the cheapest true answer and the one an operator reading a cron log wants: a
# colleague's mission that is also claimed is `owned_by_other` to this runner either
# way, and no action of theirs follows from the claim.
MISSIONS=""
m_sep=""
# The runner's identity, resolved once. Empty means unresolvable — the same condition
# `backlog_error` reports below — and every OWNED mission is then someone else's,
# which is the conservative reading: a runner that cannot say who it is must not
# claim work on anyone's behalf. Unowned missions stay offerable, as everywhere else.
ME=$(git config user.email 2>/dev/null || true)
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
        # Mine, or unclaimed. Someone else's is not this runner's to take.
        owners=$(sh "${MISSION_SCRIPTS}/mission-owners.sh" "$f" 2>/dev/null || true)
        if [ -n "$owners" ] && { [ -z "$ME" ] || ! printf '%s\n' "$owners" | grep -Fxq "$ME"; }; then
            exclude mission "$slug" "owned_by_other"
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
        # Nothing left to drive: the acceptance list may be full, but no ticket in
        # todo/ names this mission, so a claim would create a branch and a worktree
        # for an empty queue.
        qs=$(sh "${MISSION_SCRIPTS}/queue-size.sh" "$slug" 2>/dev/null || true)
        queued=$(printf '%s' "$qs" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
        [ -n "$queued" ] || queued=0
        if [ "$queued" -eq 0 ]; then
            exclude mission "$slug" "no_tickets"
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
#
# The read's STATUS is captured rather than discarded (see the header): list-todo.sh
# exits 3 when the developer's identity — and therefore the queue directory — cannot
# be resolved at all, which is a different fact from an empty queue and must not
# render identically.
BACKLOG=""
b_sep=""
USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts//user-slug.sh" 2>/dev/null || true)
BACKLOG_ERROR=""
todo_status=0
TODO_LIST=$(sh "${SCRIPT_DIR}/list-todo.sh" 2>/dev/null) || todo_status=$?
case "$todo_status" in
    0) ;;
    3) BACKLOG_ERROR="identity_unresolved" ;;
    *) BACKLOG_ERROR="unreadable" ;;
esac
for t in $TODO_LIST; do
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

printf '{"fetched": %s, "base": "%s", "surveyed_sha": "%s", "base_sha": "%s", "current": %s, "user_slug": "%s", "backlog_error": "%s", "claimed": [%s], "missions": [%s], "backlog": [%s], "excluded": [%s]}\n' \
    "$FETCHED" "$BASE" "$SURVEYED_SHA" "$BASE_SHA" "$CURRENT" "$(json_escape "$USER_SLUG")" "$BACKLOG_ERROR" \
    "$CLAIMED_JSON" "$MISSIONS" "$BACKLOG" "$EXCLUDED"
