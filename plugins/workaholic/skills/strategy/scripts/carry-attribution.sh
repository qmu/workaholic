#!/bin/sh -eu
# carry-attribution.sh — CARRY AN OPERATOR'S ATTRIBUTION RULING onto one mission: append the
# refs a named `active` strategy already cites to the `feedback:` list of a named mission, so
# the citation walk can see work the operator says answers that direction.
#
#   carry-attribution.sh <strategy-slug> <mission-slug> [<workaholic-root>]
#
# Output: one JSON object
#   {"carried": true,  "path": …, "strategy": …, "mission": …, "added": ["…"]}
#   {"carried": true,  "path": …, "strategy": …, "mission": …, "added": [], "reason": "already"}
#   {"carried": false, "reason": "no_slug"|"no_mission"|"strategy_not_found"|"not_active"
#                               |"mission_not_found"|"no_revision"|"immutable_field"}
#
# ═══ WHY THIS WRITER IS ADMISSIBLE ═══════════════════════════════════════════════════
# `unattributed-work.sh` names the active missions no direction claims. Some of them genuinely
# belong to no direction; some answer one and were published without the carry-forward link.
# For the second kind the repair was A HAND EDIT OF `main` — the one act this repository still
# left to a person editing the base directly, which is exactly what `amend.sh` was admitted to
# remove for the strategy artifact.
#
# IT COPIES `amend.sh`'s PREMISE LITERALLY, and that premise is the whole justification: a
# machine only ever CARRIES a ruling the operator ANNOUNCED, by explicit slug, onto a pull
# request only they can merge. It never decides that a mission looks like it belongs
# somewhere. `/specificate`'s announcement route is the one caller, and a run that reached this
# on its own reading would be authoring the operator's attribution rather than carrying it.
#
# IT ADDS NO FIELD AND REVIVES NO RELATION. The refs it appends are the ones
# `attributed-work.sh` already walks — `strategy.feedback[] ∩ artifact.feedback[]` — so the
# citation still runs strategy → feedback one way and the retired `strategy:` mission relation
# stays retired. Nothing is ever written back onto the strategy or onto a feedback record.
#
# ═══ THE BOUND IS THE SAFETY PROPERTY ════════════════════════════════════════════════
#   * it appends refs that ALREADY EXIST on the named strategy — it never authors one;
#   * it never REMOVES a ref, so a mission answering two directions keeps both;
#   * it touches the `feedback:` line and nothing else, asserted over the candidate before
#     writing rather than trusted;
#   * it never touches the strategy file at all — that artifact keeps its three writers
#     (`create.sh`, `amend.sh`, `close.sh`) and this is none of them.
#
# NOTHING IS WRITTEN ON A REFUSAL, `amend.sh`'s discipline verbatim: the candidate is composed
# under a temporary directory and validated there, and the artifact is touched only by the
# final `mv`. No partial write, no staged half, and no write-then-revert — a revert is a second
# write, and what this needs is the guarantee that a refusal never wrote.
#
# IDEMPOTENT: a mission that already carries every ref is left BYTE-IDENTICAL and reports
# `already`, the shape `amend.sh` and `close.sh` both use on a re-run.
#
# ═══ ITS PULL REQUEST DOES NOT AUTO-MERGE, AND THE SEAM ENFORCES THAT ════════════════
# The publication carries an operator's ruling, so the operator's merge is the authorship —
# the same reason a strategy-touching proposal never auto-merges.
#
# This header read *the seam cannot enforce that* until 2026-08-28, on the ground that an
# attribution carry is byte-indistinguishable from any other mission write. It is NOT
# indistinguishable: an ordinary proposal ADDS a mission, while this MODIFIES one already on
# the base and moves its `feedback:` line — which is exactly and only what this script writes.
# `publish-tree-pr.sh` derives **`ruling_touching`** from that shape and leaves the pull
# request open whatever `WORKAHOLIC_AUTO_MERGE` says. `/specificate`'s step 9e still leaves the
# variable unset and that assertion still stands, now as a second guard rather than the only
# one — a caller leaving a variable unset is a judgement a future caller can forget.
#
# IT STAGES THE ONE PATH AND NEVER COMMITS, exactly as `amend.sh` and `create.sh` do. It does
# not refresh the OKF indexes: `feedback:` is not an index-visible field, so a refresh could
# only add an unrelated diff to a call whose contract is that it touched one file.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
READ_FEEDBACK="${SCRIPT_DIR}/../../specificate/scripts/read-feedback-relation.sh"

refuse() {
    printf '{"carried": false, "reason": "%s"}\n' "$1"
    exit 1
}

STRATEGY="${1:-}"
MISSION="${2:-}"
ROOT="${3:-.workaholic}"

[ -n "$STRATEGY" ] || refuse no_slug
[ -n "$MISSION" ] || refuse no_mission

# MATCHING IS BY EXPLICIT SLUG ONLY, the recognition rule every lifecycle route already holds:
# a title or a paraphrase never resolves to an artifact here.
STRATEGY_FILE="${ROOT}/strategies/${STRATEGY}.md"
[ -f "$STRATEGY_FILE" ] || refuse strategy_not_found
MISSION_FILE="${ROOT}/missions/active/${MISSION}/mission.md"
[ -f "$MISSION_FILE" ] || refuse mission_not_found

fm_value() {
    awk -v key="$2" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$1" 2>/dev/null || true
}

# A CLOSED DIRECTION IS HISTORY. Carrying its refs onto a live mission would make a finished
# direction acquire new work, which is the one thing `not_active` exists to prevent everywhere
# else in this artifact's model.
[ "$(fm_value "$STRATEGY_FILE" status)" = "active" ] || refuse not_active

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

sh "$READ_FEEDBACK" "$STRATEGY_FILE" > "${WORK}/srefs" 2>/dev/null || : > "${WORK}/srefs"
sh "$READ_FEEDBACK" "$MISSION_FILE" > "${WORK}/mrefs" 2>/dev/null || : > "${WORK}/mrefs"

# A strategy citing nothing has nothing to carry. `no_revision` is `amend.sh`'s own name for
# "the ask named the slugs but nothing to write", so one model never gains two names for it.
[ -s "${WORK}/srefs" ] || refuse no_revision

: > "${WORK}/added"
while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    grep -qxF "$ref" "${WORK}/mrefs" 2>/dev/null && continue
    grep -qxF "$ref" "${WORK}/added" 2>/dev/null && continue
    printf '%s\n' "$ref" >> "${WORK}/added"
done < "${WORK}/srefs"

if [ ! -s "${WORK}/added" ]; then
    printf '{"carried": true, "path": "%s", "strategy": "%s", "mission": "%s", "added": [], "reason": "already"}\n' \
        "$MISSION_FILE" "$STRATEGY" "$MISSION"
    exit 0
fi

# The union, in the mission's own order first: an existing ref is never reordered, so a reader
# scanning the line sees what the mission has always cited before what the operator added.
cat "${WORK}/mrefs" "${WORK}/added" | grep -v '^$' > "${WORK}/union"
NEWLINE="feedback: [$(paste -sd, - < "${WORK}/union" | sed 's/,/, /g')]"

CAND="${WORK}/cand"
awk -v line="$NEWLINE" '
    NR == 1 { print; if ($0 != "---") { bad = 1; exit } ; infm = 1; next }
    infm && /^---[ \t]*$/ { if (!written) { print line; written = 1 } ; infm = 0; print; next }
    infm && /^feedback:/ { print line; written = 1; next }
    { print }
    END { if (bad) exit 1 }
' "$MISSION_FILE" > "$CAND" || refuse immutable_field

# --- Assert that only the `feedback:` line moved, over the candidate ----------------
# Not a restatement of the interface: the interface is what a caller passes, this is what the
# file says. The two disagreeing is exactly the failure worth naming.
fm_block() {
    awk 'NR==1 { if ($0 != "---") exit; next } /^---[ \t]*$/ { exit } { print }' "$1" 2>/dev/null || true
}
fm_block "$MISSION_FILE" | grep -v '^feedback:' > "${WORK}/fm-before" || true
fm_block "$CAND" | grep -v '^feedback:' > "${WORK}/fm-after" || true
cmp -s "${WORK}/fm-before" "${WORK}/fm-after" || refuse immutable_field

# The body is untouched too — this route writes one frontmatter line and nothing else.
awk 'BEGIN { n = 0 } /^---[ \t]*$/ { n++; if (n <= 2) next } n >= 2 { print }' "$MISSION_FILE" > "${WORK}/body-before"
awk 'BEGIN { n = 0 } /^---[ \t]*$/ { n++; if (n <= 2) next } n >= 2 { print }' "$CAND" > "${WORK}/body-after"
cmp -s "${WORK}/body-before" "${WORK}/body-after" || refuse immutable_field

mv "$CAND" "$MISSION_FILE"
git add "$MISSION_FILE" 2>/dev/null || true

ADDED=$(sed -e 's/.*/"&"/' "${WORK}/added" | paste -sd, - | sed 's/,/, /g')
printf '{"carried": true, "path": "%s", "strategy": "%s", "mission": "%s", "added": [%s]}\n' \
    "$MISSION_FILE" "$STRATEGY" "$MISSION" "$ADDED"
