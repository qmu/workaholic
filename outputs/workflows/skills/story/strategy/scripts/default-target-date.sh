#!/bin/sh -eu
# THE ONE DERIVATION OF THE DEFAULT TARGET DATE.
#
# Usage: default-target-date.sh [<ask-date>]
# Output: {"ok": true,  "reason": "",             "target_date": "YYYY-MM-DD",
#          "basis": "YYYY-MM-DD", "basis_source": "ask"|"today", "days": 7}
#         {"ok": false, "reason": "bad_ask_date", "target_date": null,
#          "basis": null, "basis_source": "", "days": 7}
#         Exit 0 on the success path; a refusal exits 0 too, so a caller reads the
#         FIELD rather than the status (`gh-rest.sh available`'s convention).
#
# WHY IT EXISTS (2026-08-30, mission
# `draft-a-dateless-direction-with-the-operator-s-one-week-default`). An ask carrying an aim
# and an owner but no date was refused `no_target_date`, and the refusal reached nobody —
# three announced directions died there. **The operator ruled the default on 2026-08-30: one
# week from the ask.** The number 7 below IS that ruling, and it lives here and nowhere else,
# so a later reader finds the ruling rather than a bare constant.
#
# ONE PLACE, BEFORE ANY CALLER. Every other date term in the strategy layer —
# `days_to_target`, `overdue`, `expiring` — is derived in exactly one place and read by
# everything else. This one is derived before its first caller exists, deliberately: two
# sessions each computing "a week" from two different clocks is precisely how a repository
# ends up with two answers to one question, and the layer has refused that shape by name
# everywhere else.
#
# IT OWNS THE ARITHMETIC AND NOTHING ELSE. It decides no policy, reads no strategy, writes
# nothing, and never says whether a default SHOULD be taken — that judgment belongs to the
# caller, which knows whether the ask stated a date of its own. A date the ask states is
# never overwritten, and this script cannot overwrite one because it is never shown one.
#
# THE BASIS IS THE ASK'S OWN DATE WHEN THERE IS ONE. A tick that ingests an issue filed days
# ago must not date the direction from its own clock — the ask is what the week is counted
# from, so the triggering issue's `created_at` is passed in and reported back as `basis`,
# with `basis_source` saying which of the two answers a caller is looking at.
#
# THE ARGUMENT IS A CALENDAR DATE, NOT A TIMESTAMP. A caller holding an issue's RFC3339
# `created_at` passes its DATE part (`${created_at%%T*}`) — one substring, no arithmetic, so
# no second derivation is created by the split. Anything else is refused rather than
# interpreted.
#
# A MALFORMED ARGUMENT IS REFUSED WITH NO DATE AT ALL, never silently fallen back to today:
# a plausible answer computed from an input nobody could read is the failure this whole
# reading exists to avoid, and it would be invisible — the caller would draft a direction
# dated a week from the wrong day and nothing would say so. Two ways to be malformed and
# both answer `bad_ask_date`: the shape (`not-a-date`, an RFC3339 timestamp, `2026-13-45`)
# and the calendar (`2026-02-30`, which jq's own parser NORMALIZES to 2026-03-02 rather than
# rejecting — so the parse is round-tripped and a date that does not survive it is refused).
#
# THE ARITHMETIC IS jq's, NOT `date`'s. `date -d` is GNU-only and `date -v` is BSD-only, so a
# script written with either works on the runner and not on a developer's machine.
# `survey-strategies.sh` already does its day arithmetic in jq over epoch seconds; this
# matches that shape exactly. `date -u +%Y-%m-%d` is used only to ask what today is, which is
# portable and is what that survey does too.

set -eu

DAYS=7

ASK_DATE="${1:-}"

refuse() {
    printf '{"ok": false, "reason": "%s", "target_date": null, "basis": null, "basis_source": "", "days": %s}\n' \
        "$1" "$DAYS"
    exit 0
}

if [ -n "$ASK_DATE" ]; then
    BASIS="$ASK_DATE"
    BASIS_SOURCE=ask
else
    BASIS="$(date -u +%Y-%m-%d)"
    BASIS_SOURCE=today
fi

case "$BASIS" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) refuse bad_ask_date ;;
esac

# The parse is ROUND-TRIPPED, because jq's `fromdateiso8601` normalizes an out-of-range day
# (2026-02-30 -> 2026-03-02) instead of failing. A basis that does not come back as itself was
# never a calendar date, and computing a week from it would answer plausibly about a day the
# ask never named.
out=$(jq -nc --arg basis "$BASIS" --arg source "$BASIS_SOURCE" --argjson days "$DAYS" '
    ($basis + "T00:00:00Z") as $iso
    | ($iso | fromdateiso8601) as $epoch
    | if ($epoch | strftime("%Y-%m-%d")) != $basis
      then {ok: false, reason: "bad_ask_date", target_date: null, basis: null,
            basis_source: "", days: $days}
      else {ok: true, reason: "",
            target_date: (($epoch + ($days * 86400)) | strftime("%Y-%m-%d")),
            basis: $basis, basis_source: $source, days: $days}
      end' 2>/dev/null || true)

[ -n "$out" ] || refuse bad_ask_date

printf '%s\n' "$out"
