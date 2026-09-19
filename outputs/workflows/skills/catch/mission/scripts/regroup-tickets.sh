#!/bin/sh -eu
# regroup-tickets.sh — CARRY AN OPERATOR'S GRANULARITY CORRECTION onto queued tickets: write
# the `mission:` relation naming one active mission onto an explicitly named set of queued
# loose tickets, and append one changelog line to that mission. It writes nothing else.
#
#   regroup-tickets.sh <mission-slug> <ticket-filename>... [--root <workaholic-root>]
#                      [--date YYYY-MM-DD]
#
# `<ticket-filename>` is the bare filename under `tickets/todo/` — the same spelling a
# mission's acceptance link uses (`(#<filename>)`) and the same one the operator's ask names.
#
# Output: one JSON object
#   {"regrouped": true,  "mission": …, "path": …, "added": […], "already": […],
#    "changelog": true|false}
#   {"regrouped": true,  "mission": …, "path": …, "added": [], "already": […],
#    "reason": "already_in_mission", "changelog": false}
#   {"regrouped": false, "reason": "<word>", "refusals": [{"ticket": …, "reason": "<word>"}]}
#
# ═══ ITS PRECEDENT IS `carry-attribution.sh`, AND THE FOUR BOUNDS IT INHERITS ═════════
# `strategy/scripts/carry-attribution.sh` is the shape this copies, property for property,
# because the two acts are the same act on a different relation: a machine CARRIES a ruling
# the operator ANNOUNCED, by explicit slug, onto a pull request only they can merge. The four
# bounds are `drive/reference/claims.md`, *When a bounded act may read a judgement*, cited
# rather than restated:
#
#   * it RE-DERIVES every precondition at the moment of the act — mission liveness, each
#     ticket's queued-ness, each ticket's existing relation and the claim oracle's own answer
#     are read here, never passed in and never inherited from a caller's earlier reading;
#   * it is IDEMPOTENT — a ticket that already names the mission reports `already_in_mission`
#     and is left BYTE-IDENTICAL, and a re-run over a fully regrouped set writes nothing at
#     all (the shape `carry-attribution.sh`'s `already` uses);
#   * it is REVERSIBLE — one frontmatter line and one appended changelog line, both on a pull
#     request a person merges;
#   * it REFUSES EVERY BOUND BY ITS OWN WORD, writing nothing.
#
# ═══ IT FIRES ON AN EXPLICIT ANNOUNCEMENT AND ON NOTHING ELSE ════════════════════════
# Both the mission and EVERY ticket are named by the operator's ask. A run never regroups on
# its own reading that tickets look related: that reading is the executor's grouping judgement
# and it changes a UNIT, never an artifact (`workaholic:drive` §2, where a shared `feedback:`
# ref is grounds for one batch unit). `CLAUDE.md`'s planning job states plainly that the loop
# may not merge two missions and may not retire a ticket it judges mooted, so a regroup that
# fired on the loop's own reading would be exactly the act that is forbidden.
#
# ═══ ALL-OR-NOTHING OVER THE NAMED SET ═══════════════════════════════════════════════
# Every member is validated before ANY member is written, and a refusal on one leaves every
# member byte-identical. A half-regrouped batch is the one outcome that cannot be argued with
# afterwards: `plan-units.sh` would offer some of the set loose and drive the rest inside the
# mission, which is the fragmentation this act exists to end, with the operator's ruling half
# applied and no record of which half.
#
# ═══ WHAT IT DOES NOT WRITE ══════════════════════════════════════════════════════════
# No acceptance item (promoting a ticket into the definition of done is the developer's call),
# no ticket body edit, no reordering, no ticket creation, no deletion, and nothing at all on a
# feedback record or a strategy. The rest of the ticket's frontmatter and the whole of its body
# are asserted byte-identical over the candidate before the file is touched — not a restatement
# of the interface, but what the file says, `carry-attribution.sh`'s discipline verbatim.
#
# ═══ `claimed` IS THE NEXT SAFE BOUNDARY, AND IT IS READ FROM THE ONE ORACLE ═════════
# The ask asks for new claims to stop at the next safe boundary. That is satisfied by the
# EXISTING claim protocol and no new mechanism: a ticket inside a live claim is another run's
# work, so it is refused `claimed` and that run is never interrupted. No hold, no flag, no
# second control path. The reading comes from `drive/scripts/list-claims.sh` — the unmerged
# remote branches, the only claim oracle — and a scan this act could not read refuses
# `claim_unreadable` with nothing written: an absence of a reading is never a proof that
# nothing is claimed.
#
# ═══ ITS PUBLICATION DOES NOT AUTO-MERGE, AND THE SEAM CANNOT DERIVE THAT ════════════
# It carries an operator's ruling, so the operator's merge is the authorship. Said plainly
# rather than implied: `publish-tree-pr.sh`'s `ruling_touching` derivation does **not** catch
# this shape. That test fires on a mission that already existed on the base whose diff moves
# its `feedback:` line (`branching/scripts/lib/publication-refusal.sh`), and a regroup moves a
# TICKET's `mission:` line and appends a mission CHANGELOG line — neither term. So this is the
# caller's rule, stated at `/specificate`'s step 9f and pinned by a test over that step's own
# text: a weaker guarantee than the strategy form's, recorded as such.
#
# IT STAGES THE PATHS AND NEVER COMMITS, exactly as `carry-attribution.sh` and `amend.sh` do.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
READ_RELATION="${SCRIPT_DIR}/read-relation.sh"
APPEND_CHANGELOG="${SCRIPT_DIR}/append-changelog.sh"
LIST_CLAIMS="${SCRIPT_DIR}/../../drive/scripts/list-claims.sh"

MISSION=""
ROOT=".workaholic"
DATE=""
TICKETS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --date) DATE="${2:-}"; shift 2 ;;
        --) shift ;;
        -*) echo '{"regrouped": false, "reason": "usage"}' >&2; exit 1 ;;
        *)
            if [ -z "$MISSION" ]; then MISSION="$1"; else TICKETS="${TICKETS}$1
"; fi
            shift ;;
    esac
done

refuse() {
    printf '{"regrouped": false, "reason": "%s", "refusals": [%s]}\n' "$1" "${2:-}"
    exit 1
}

[ -n "$MISSION" ] || refuse no_slug
[ -n "$TICKETS" ] || refuse no_tickets

# MATCHING IS BY EXPLICIT SLUG ONLY, the recognition rule every lifecycle route holds.
MISSION_FILE="${ROOT}/missions/active/${MISSION}/mission.md"
if [ ! -f "$MISSION_FILE" ]; then
    if [ -f "${ROOT}/missions/archive/${MISSION}/mission.md" ]; then
        # A CLOSED MISSION ACQUIRES NO WORK — `carry-attribution.sh`'s `not_active`, for its
        # reason: an ended container gaining new tickets is the one thing that word exists to
        # prevent everywhere else in this artifact's model.
        refuse not_active
    fi
    refuse mission_not_found
fi

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

# --- The claim oracle, read once for the whole set --------------------------------------
# One scan for N tickets: the reading is about the repository, not about any one ticket.
CLAIMED_ARTIFACTS="${WORK}/claimed"
: > "$CLAIMED_ARTIFACTS"
claims_json=$(sh "$LIST_CLAIMS" 2>/dev/null || true)
if [ -z "$claims_json" ] || ! printf '%s' "$claims_json" | jq -e '.claims | type == "array"' >/dev/null 2>&1; then
    refuse claim_unreadable
fi
printf '%s' "$claims_json" | jq -r '.claims[]?.artifacts[]?' 2>/dev/null > "$CLAIMED_ARTIFACTS" || : > "$CLAIMED_ARTIFACTS"

# --- Pass 1: validate every member, writing nothing -------------------------------------
REFUSALS=""
ADD_LIST="${WORK}/add"
ALREADY_LIST="${WORK}/already"
: > "$ADD_LIST"
: > "$ALREADY_LIST"

add_refusal() {
    REFUSALS="${REFUSALS}${REFUSALS:+, }{\"ticket\": \"$(esc "$1")\", \"reason\": \"$2\"}"
}

while IFS= read -r name; do
    [ -n "$name" ] || continue
    # The ask names a filename; a path is accepted only when it is the queued one, so an
    # archived or iceboxed copy can never be reached by spelling its path.
    base=${name##*/}
    path="${ROOT}/tickets/todo/${base}"
    if [ ! -f "$path" ]; then
        # NOT FOUND and NOT QUEUED are different facts and get different words: one says the
        # operator named something that is not here, the other says it is here and has moved
        # past the point where regrouping means anything.
        if [ -n "$(find "${ROOT}/tickets" -name "$base" -print -quit 2>/dev/null || true)" ]; then
            add_refusal "$base" not_queued
        else
            add_refusal "$base" ticket_not_found
        fi
        continue
    fi
    if grep -qxF "$path" "$CLAIMED_ARTIFACTS" 2>/dev/null; then
        add_refusal "$base" claimed
        continue
    fi
    rel=$(sh "$READ_RELATION" "$path" 2>/dev/null || true)
    if printf '%s\n' "$rel" | grep -qxF "$MISSION" 2>/dev/null; then
        printf '%s\n' "$base" >> "$ALREADY_LIST"
        continue
    fi
    other=$(printf '%s\n' "$rel" | grep -v '^$' || true)
    if [ -n "$other" ]; then
        # A ticket already inside another mission is not a LOOSE ticket, and the ask is about
        # regrouping loose ones. Making the relation carry both would leave the ticket driven
        # by whichever unit is claimed first, which is an ambiguity the operator did not ask
        # for. Its own word, so the refusal names what is actually in the way.
        add_refusal "$base" in_other_mission
        continue
    fi
    printf '%s\n' "$base" >> "$ADD_LIST"
done <<TICKETS
${TICKETS}
TICKETS

[ -z "$REFUSALS" ] || refuse member_refused "$REFUSALS"

json_list() {
    [ -s "$1" ] || { printf ''; return 0; }
    sed -e 's/.*/"&"/' "$1" | paste -sd, - | sed 's/,/, /g'
}

if [ ! -s "$ADD_LIST" ]; then
    printf '{"regrouped": true, "mission": "%s", "path": "%s", "added": [], "already": [%s], "reason": "already_in_mission", "changelog": false}\n' \
        "$(esc "$MISSION")" "$(esc "$MISSION_FILE")" "$(json_list "$ALREADY_LIST")"
    exit 0
fi

# --- Pass 2: write, one ticket at a time, each asserted before it is touched -------------
fm_block() {
    awk 'NR==1 { if ($0 != "---") exit; next } /^---[ \t]*$/ { exit } { print }' "$1" 2>/dev/null || true
}
body_block() {
    awk 'BEGIN { n = 0 } /^---[ \t]*$/ { n++; if (n <= 2) next } n >= 2 { print }' "$1" 2>/dev/null || true
}

while IFS= read -r base; do
    [ -n "$base" ] || continue
    path="${ROOT}/tickets/todo/${base}"
    cand="${WORK}/cand"
    awk -v line="mission: ${MISSION}" '
        NR == 1 { print; if ($0 != "---") { bad = 1; exit } ; infm = 1; next }
        infm && /^---[ \t]*$/ { if (!written) { print line; written = 1 } ; infm = 0; print; next }
        infm && /^mission:/ { print line; written = 1; next }
        { print }
        END { if (bad) exit 1 }
    ' "$path" > "$cand" || refuse immutable_field
    fm_block "$path" | grep -v '^mission:' > "${WORK}/fm-before" || true
    fm_block "$cand" | grep -v '^mission:' > "${WORK}/fm-after" || true
    cmp -s "${WORK}/fm-before" "${WORK}/fm-after" || refuse immutable_field
    body_block "$path" > "${WORK}/body-before"
    body_block "$cand" > "${WORK}/body-after"
    cmp -s "${WORK}/body-before" "${WORK}/body-after" || refuse immutable_field
    mv "$cand" "$path"
    git add "$path" 2>/dev/null || true
done < "$ADD_LIST"

# --- One changelog line, through the idempotent mutator ---------------------------------
# Composed, never reimplemented: `append-changelog.sh` is the single writer of that section
# and owns the format and the (event, artifact) idempotency key.
first=$(head -n 1 "$ADD_LIST")
count=$(wc -l < "$ADD_LIST" | tr -d ' ')
if [ -n "$DATE" ]; then
    cl=$(sh "$APPEND_CHANGELOG" "$MISSION_FILE" "regrouped ${count} queued ticket(s) on an operator granularity correction" "$first" "$DATE" 2>/dev/null || true)
else
    cl=$(sh "$APPEND_CHANGELOG" "$MISSION_FILE" "regrouped ${count} queued ticket(s) on an operator granularity correction" "$first" 2>/dev/null || true)
fi
CHANGELOG=false
printf '%s' "$cl" | grep -q '"appended": *true' 2>/dev/null && CHANGELOG=true

printf '{"regrouped": true, "mission": "%s", "path": "%s", "added": [%s], "already": [%s], "changelog": %s}\n' \
    "$(esc "$MISSION")" "$(esc "$MISSION_FILE")" \
    "$(json_list "$ADD_LIST")" "$(json_list "$ALREADY_LIST")" "$CHANGELOG"
