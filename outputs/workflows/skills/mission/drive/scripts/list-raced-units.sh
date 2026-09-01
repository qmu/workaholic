#!/bin/sh -eu
# WHICH UNITS ARE BEING DRIVEN TWICE RIGHT NOW? The candidate reader for the one surface that
# names a claim race to a person.
#
# Usage: list-raced-units.sh
# Output: {"ok": bool, "reason": "", "fetched": bool, "shallow": bool,
#          "count": <n>|null,
#          "raced": [{"unit": "...", "branches": ["work-...", "work-..."],
#                     "owners": ["a@b"], "verdicts": ["claim_active", "report_undelivered"]}]}
#         Always exit 0 — a degraded read is an answer, and its caller reports it rather than
#         failing the tick on it.
#
# WHY IT EXISTS (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`).
# No run report, no `/moderate` step and no claim verdict named *this unit was driven twice*.
# Measured 2026-08-30: `work-20260830-055314` and `work-20260830-055318` were both claimed for
# one unit four seconds apart and each drove the same four tickets for over an hour. The run
# that lost reported an ordinary undelivered unit, and the duplicated hour is recorded nowhere.
#
# THE CANDIDATE SET IS `ambiguous` AND NOTHING ELSE — TWO OR MORE LIVE CLAIMS FOR ONE UNIT.
# That is the race itself, readable with no threshold, no clock comparison and no stored field,
# straight off `claims_unit_resolution`, which already answers it for every other consumer.
#
# WHY THE AFTERMATH IS DELIBERATELY NOT A CANDIDATE, and this is the ticket's hardest judgement
# rather than an omission. A race that has already resolved leaves one live claim beside one
# `superseded` one — and that shape is BYTE-IDENTICAL to the sanctioned recovery the protocol
# performs on purpose: a `superseded` claim's work is resurveyed and taken on a FRESH claim,
# because the old branch cannot land (`../reference/claims.md`, and `plan-units.sh`'s
# `resurveyed[]`). Separating a race from that recovery would need either a clock threshold
# between the two claims' creation times or a field stored on an artifact, and this repository
# refuses both by name. So the aftermath is left where it is already handled — the loser reads
# `superseded`, `retire-claims` retires it, and `stalled-units` counts it as a fact rather than
# asking about it — and this reader answers only the state in which a person can still act:
# two runs driving one unit at the same time.
#
# IT IS NOT A SECOND ORACLE. It composes `list-claims.sh` — one walk of the refs — and re-derives
# nothing: not the resolution, not a verdict, not the refs walk. `claims_unit_resolution` is the
# library's own, the same derivation `claim.sh`, `release-claim.sh`, `retire-claim.sh`,
# `catch-up-claim.sh` and `list-catchable-claims.sh` read. It adds no queue, no cursor, no stored
# state and no field on any artifact, and `lib/claims.sh` emits no new word for it.
#
# EVERY VALUE HERE IS A JUDGEMENT (`../reference/claims.md`, *Whether a unit is being driven
# twice*): a claim set is re-read every tick and can change between two reads — a race resolves
# the moment one of the two branches merges — which is the one property a proof must not have.
# So no consumer may release a claim, pick between two branches, delete a branch, close a pull
# request, revert, merge, gate or hold work on it. Reporting and asking is the whole licence.
#
# BOTH BRANCHES ARE NAMED, NEVER PICKED BETWEEN. That is `ambiguous_claim`'s standing everywhere
# else in the protocol, and it is what a person needs: which two branches drove the unit, and
# who holds each.
#
# A DEGRADED READ YIELDS NO CANDIDATES, ITS REASON AND NULL COUNTS, never a bare empty set: a
# healthy quiet run and a scan that could not reach the remote are byte-identical otherwise, and
# the second has not found "no unit is being driven twice" — it has found nothing at all. A
# shallow scan is the same shape one step over, since across a graft boundary a superseded claim
# is indistinguishable from a live one, which is exactly the term this reading is built on.
#
# PURE READ. No branch, no worktree, no claim touched, no ref written, no file written, no
# network call the scan does not already make; exit 0 on every path.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

LISTER="${SCRIPT_DIR}/list-claims.sh"

FETCHED=false
SHALLOW=false

# `count` is null on every degraded path and a real number on every complete one. A zeroed count
# on a read we could not make is the collapse this whole shape exists to close.
emit() {
    printf '{"ok": %s, "reason": "%s", "fetched": %s, "shallow": %s, "count": %s, "raced": [%s]}\n' \
        "$1" "$2" "$FETCHED" "$SHALLOW" "${4:-null}" "${3:-}"
    exit 0
}

[ -f "$LISTER" ] || emit false no_claim_reader

out=$(sh "$LISTER" 2>/dev/null || true)
[ -n "$out" ] || emit false claims_unreadable
printf '%s' "$out" | jq -e . >/dev/null 2>&1 || emit false claims_unparseable

FETCHED=$(printf '%s' "$out" | jq -r '.fetched // false')
SHALLOW=$(printf '%s' "$out" | jq -r '.shallow // false')

[ "$FETCHED" = "true" ] || emit false origin_unreachable
[ "$SHALLOW" = "true" ] && emit false shallow_history

# The TSV projection the library's resolver reads: field 1 the unit, field 2 the branch, field 7
# the verdict. The intervening columns are the scan's own and are not consulted by the resolver,
# so they are left empty rather than invented here.
rows=$(printf '%s' "$out" \
    | jq -r '.claims[]? | [.unit, .branch, "", "", "", "", .resume_reason] | @tsv' 2>/dev/null || true)

units=$(printf '%s' "$out" | jq -r '[.claims[]?.unit] | unique | .[]' 2>/dev/null || true)

raced=""
sep=""
count=0
for unit in $units; do
    [ -n "$unit" ] || continue
    [ "$(claims_unit_resolution "$rows" "$unit")" = "ambiguous" ] || continue
    # The live branches, comma-joined, from the library's own helper — the same string an
    # `ambiguous_claim` refusal reports, so the question and the refusal cannot name different
    # pairs. A superseded branch beside them is not part of the race and is left out.
    live=$(claims_unit_live_branches "$rows" "$unit")
    [ -n "$live" ] || continue
    row=$(printf '%s' "$out" | jq -c --arg u "$unit" --arg live "$live" '
        ($live | split(",")) as $bs
        | {unit: $u,
           branches: $bs,
           owners: [.claims[]? | select(.branch as $b | $bs | index($b)) | .author // "unknown"] | unique,
           verdicts: [$bs[] as $b | (.claims[]? | select(.branch == $b) | .resume_reason)]}
    ' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    raced="${raced}${sep}${row}"
    sep=", "
    count=$((count + 1))
done

emit true "" "$raced" "$count"
