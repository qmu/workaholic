#!/bin/sh -eu
# Did the act this loop took actually take effect? ONE reader, for both acts.
#
# Usage: act-effect.sh retirement <unit>
#        act-effect.sh delivery   <unit>
# Output: {"ok": bool, "act": "...", "unit": "...", "effect": "...", "source": "...", "reason": ""}
#         `effect` is one of `taken` | `refused:<word>` | `pending` | `unavailable` | `unreadable`.
#         Always exit 0.
#
# WHY IT EXISTS (2026-08-29, mission `read-back-whether-the-loop-s-own-act-took-effect`).
# This loop performs exactly two acts on a PROOF (`../reference/claims.md`, *Proofs and
# judgements*): the retirement's Act 2 — `retire-claim.sh` in the container,
# `delete-retired-claim-branch.sh` in CI — and the delivery retry, `retry-undelivered.sh`. The
# retry already answered *did my act take effect*: it records the merge outcome back onto the
# branch story through `record-merge-outcome.sh`, so the next survey and `/moderate`'s question
# read a current answer. The retirement did not, and answered from a run's EXISTENCE instead.
# With that repaired, the same question was answered in two places in two shapes — which is how
# two readings of one fact start to disagree. This is the one place.
#
# IT OWNS THE ASSEMBLY AND NO ACT'S VOCABULARY. Each answer comes from that act's OWN existing
# outcome source, composed and never re-derived:
#
#   retirement   `ci-retirement-turn.sh <unit>`, which reads the turn's recorded verdict
#   delivery     the claim row's `merge_outcome`, which `lib/claims.sh` reads off the branch
#                story blob the scan already fetched — NO network call and no second derivation
#
# **Each act's word is carried verbatim.** The two acts have different refusal vocabularies and
# they are deliberately NOT merged into a third: a normalised word would send a reader to a
# string no script ever printed. What is shared is only the SHAPE — `taken` / `refused:<word>` /
# `pending` / `unavailable` / `unreadable` — which is a frame around each act's answer, not a
# translation of it.
#
# NO FIELD, NO STORE, NO SECOND ORACLE. It creates no file, no cursor and no ledger, and it adds
# nothing to any artifact. It is visibly unable to answer on its own: every value it returns was
# printed by a script it composed, and `source` names which one, so a reader can go and ask the
# same question of the same script and get the same word.
#
# `retry-undelivered.sh` IS UNTOUCHED BY THIS. Its behaviour, its refusals and the number of
# network calls it makes are exactly what they were; this composes the answer it already
# records rather than changing how it records it.
#
# EVERY VALUE IS A JUDGEMENT, NOT A PROOF (`../reference/claims.md`, *Whether an act the loop
# took had its effect*). A workflow run is re-runnable and a branch can be deleted or restored
# between two reads, so nothing here may revert, re-run, gate, hold work or merge. The licence
# is to report, to ask, and — for the retirement — to hold a question on `taken` or `pending`.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
TURN="${SCRIPT_DIR}/ci-retirement-turn.sh"
LISTER="${SCRIPT_DIR}/list-claims.sh"

ACT="${1:-}"
UNIT="${2:-}"

emit() {
    printf '{"ok": %s, "act": "%s", "unit": "%s", "effect": "%s", "source": "%s", "reason": "%s"}\n' \
        "$1" "$ACT" "$UNIT" "$2" "${3:-}" "${4:-}"
    exit 0
}

case "$ACT" in
    retirement|delivery) ;;
    *) ACT="${ACT}"; emit false unreadable "" usage ;;
esac
[ -n "$UNIT" ] || emit false unreadable "" no_unit

if [ "$ACT" = "retirement" ]; then
    [ -f "$TURN" ] || emit false unreadable ci-retirement-turn.sh no_reader
    out=$(sh "$TURN" "$UNIT" 2>/dev/null || true)
    printf '%s' "$out" | jq -e . >/dev/null 2>&1 || emit false unreadable ci-retirement-turn.sh reader_unparseable
    word=$(printf '%s' "$out" | jq -r --arg u "$UNIT" \
        '[.units[]? | select(.unit == $u) | .ci_turn] | first // ""' 2>/dev/null || printf '')
    [ -n "$word" ] || emit true unreadable ci-retirement-turn.sh unit_unanswered
    reason=$(printf '%s' "$out" | jq -r '.reason // ""')
    emit true "$word" ci-retirement-turn.sh "$reason"
fi

# --- delivery -------------------------------------------------------------------------------
# The retry's answer, exactly where the retry puts it. `list-claims.sh` already carries it on the
# row as `merge_outcome`, read by `lib/claims.sh` off the branch story blob the scan fetched, so
# composing the row costs no call this reader would not otherwise make and cannot disagree with
# the run that made the attempt.
[ -f "$LISTER" ] || emit false unreadable list-claims.sh no_reader
claims=$(sh "$LISTER" 2>/dev/null || true)
printf '%s' "$claims" | jq -e . >/dev/null 2>&1 || emit false unreadable list-claims.sh claims_unparseable
[ "$(printf '%s' "$claims" | jq -r '.fetched // false')" = "true" ] \
    || emit false unreadable list-claims.sh origin_unreachable

row=$(printf '%s' "$claims" | jq -c --arg u "$UNIT" \
    '[.claims[]? | select(.unit == $u)] | first // empty' 2>/dev/null || printf '')

# NO CLAIM ROW IS `taken`, AND THAT IS THE RETRY'S OWN LOGIC RATHER THAN AN INFERENCE ABOUT IT:
# a merge RELEASES a claim by definition (`../reference/claims.md`, *The model*), so a unit whose
# claim has left the table is one whose merge landed. `retry-undelivered.sh` records nothing on
# success for exactly this reason.
[ -n "$row" ] || emit true taken list-claims.sh claim_released

outcome=$(printf '%s' "$row" | jq -r '.merge_outcome // ""')
case "$outcome" in
    # The word the run that made the attempt wrote, carried through with no translation.
    merge_refused:*) emit true "refused:${outcome#merge_refused:}" list-claims.sh "" ;;
    merge_refused) emit true "refused:unstated" list-claims.sh "" ;;
    "") emit true pending list-claims.sh no_attempt_recorded ;;
    *) emit true unreadable list-claims.sh "unrecognised_outcome" ;;
esac
