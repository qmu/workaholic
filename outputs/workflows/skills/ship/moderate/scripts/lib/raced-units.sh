#!/bin/sh
# WHICH UNITS ARE HELD BY TWO OR MORE LIVE CLAIMS — the one way a step filters a raced unit out
# of its own candidates (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`).
#
#   . "${SCRIPT_DIR}/lib/raced-units.sh"
#   raced=$(raced_units "$claims_json")   # newline-separated unit ids, possibly empty
#   is_raced "$unit" "$raced" && continue
#
# WHY IT IS A SHARED HELPER AND NOT THREE COPIES. `raced-units` owns the question and
# `stalled-units`, `undelivered-units` and `catchup-blocked` each filter and count — the
# `handoff-units`/`stalled-units` precedent, where one step asks and the others filter. Three
# copies of the same test is how two of them start disagreeing about which unit is raced, and a
# step that filtered a unit the asking step did not ask about would drop the finding entirely.
#
# IT DERIVES NOTHING. The resolution is `claims_unit_resolution`, the library's own single
# derivation — the same one `claim.sh`, `release-claim.sh`, `retire-claim.sh`,
# `catch-up-claim.sh`, `list-catchable-claims.sh` and `list-raced-units.sh` read. A second
# implementation of "two live claims" is exactly the drift the claim protocol refuses by name.
#
# IT COSTS NO EXTRA WALK OF THE REFS. Each calling step has already read `list-claims.sh`; this
# takes that JSON and projects it, rather than composing `list-raced-units.sh`, which would make
# every filtering step pay for a second scan of the remote.
#
# A CALLER THAT CANNOT READ ITS CLAIMS FILTERS NOTHING, which is the safe direction: an
# over-eager question beats a silently dropped one, and a step that filtered on an unreadable
# reading would hide a finding on exactly the ticks it could see least.

# $1 = the JSON `list-claims.sh` produced. Prints one unit id per line.
raced_units() {
    _ru_json="${1:-}"
    [ -n "$_ru_json" ] || return 0
    printf '%s' "$_ru_json" | jq -e . >/dev/null 2>&1 || return 0

    # Field 1 the unit, field 2 the branch, field 7 the verdict — the projection the library's
    # resolver reads. The intervening columns are the scan's own and are not consulted.
    _ru_rows=$(printf '%s' "$_ru_json" \
        | jq -r '.claims[]? | [.unit, .branch, "", "", "", "", .resume_reason] | @tsv' 2>/dev/null || true)
    [ -n "$_ru_rows" ] || return 0

    for _ru_unit in $(printf '%s' "$_ru_json" | jq -r '[.claims[]?.unit] | unique | .[]' 2>/dev/null || true); do
        [ -n "$_ru_unit" ] || continue
        [ "$(claims_unit_resolution "$_ru_rows" "$_ru_unit")" = "ambiguous" ] || continue
        printf '%s\n' "$_ru_unit"
    done
}

# $1 = unit id, $2 = the newline-separated set `raced_units` produced.
is_raced() {
    [ -n "${2:-}" ] || return 1
    printf '%s\n' "$2" | grep -Fxq -- "$1"
}
