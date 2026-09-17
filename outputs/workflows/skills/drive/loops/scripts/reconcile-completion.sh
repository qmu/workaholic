#!/bin/sh -eu
# IS THE TICK'S COMPLETION CLAIM TRUE? Reconciled from the tree and the oracle, never relayed
# from a worker's own word.
#
# Usage: reconcile-completion.sh [--root PATH] [--claims FILE] [--plan-units FILE] [--unit ID]...
# Output: one JSON object, ALWAYS exit 0.
#   {"complete": true|false|null,
#    "merged": N|null, "standing_claims": N|null, "standing_claims_mine": N|null,
#    "queued": N|null,
#    "units": [{"unit": "...", "effect": "taken|refused:<word>|pending|unreadable", "source": "..."}],
#    "degraded": [{"source": "...", "reason": "..."}],
#    "readable": false}          # ABSENT on a reading in which every source answered
#
# WHY IT EXISTS (2026-09-09, mission `report-a-native-tick-from-reconciled-evidence-not-from-a-
# worker-s-word`). A native `/work` tick's report is assembled from each worker's own
# `executed` / `outcome` / `reason` (`work/scripts/worker-result.schema.json`), and NOTHING
# between the worker and the report asked the tree, the oracle or the queue whether that was
# true. **Measured 2026-09-08**: a session called implementation complete with **zero merges,
# six queued tickets and two unreconciled pull requests**, and misidentified its own runner's
# claims as another loop's. A closed inbound feedback issue was no help either — a *proposal*
# pull request closes one before any implementation exists.
#
# IT IS NOT A SECOND CLAIM ORACLE, and that bound is the shape of the script. It walks no ref,
# reads no `.workaholic/` artifact of its own and derives no verdict word. Every number it
# prints was printed by a reader this repository already owns:
#
#   merged            `drive/scripts/act-effect.sh delivery <unit> --claims <file>` — whose `taken` is the
#                     claim protocol's own proof that a merge landed (a merge RELEASES a claim,
#                     so a released claim is a merged unit) and whose refusal words are carried
#                     verbatim
#   standing claims   `drive/scripts/list-claims.sh` — the one claim oracle
#   queued            `drive/scripts/plan-units.sh` — `backlog_size`, the survey's own count
#
# AND IT IS BOUNDED TO THE TICK'S OWN UNITS. `--unit` is repeatable and names only what this
# tick claims to have delivered; with none given it reconciles the repository-level counts and
# nothing else. Both expensive readings can be HANDED IN (`--claims`, `--plan-units`) rather
# than re-made — the hand-back shape `direction-state.sh --emit-survey` already uses — so a
# tick that has surveyed once pays no second walk and no second fetch.
#
# WHOSE CLAIMS THEY ARE IS PART OF THE ANSWER, not a detail. `standing_claims` counts every row
# and `standing_claims_mine` counts this identity's, resolved on the claim protocol's own
# precedence (`WORKAHOLIC_CLAIM_IDENTITY` as an OVERRIDE, then `git config user.email`). The
# measured session read its own runner's claims as another loop's, which is a mistake only a
# reading that never names the owner can make.
#
# A DEGRADED SOURCE MAKES `complete` NULL, NEVER FALSE, AND ITS COUNT NULL, NEVER ZERO. This is
# `plan-units.sh`'s and `tick-progress.sh`'s standing convention rather than a third one: an
# unreadable oracle is not an empty one, and rendering *I could not look* as *nothing is
# outstanding* is the exact failure that lets a completion claim be wrong and confident. Each
# failure is named in `degraded[]` by its source and its reason, and `readable: false` rides
# beside it — ABSENT on a completed reading, so a consumer tests `readable == false` and never
# `readable // true`.
#
# `complete: true` NEEDS ALL FOUR TERMS: every named unit's delivery effect is `taken`, this
# identity holds no standing claim, the queue is empty, and no source was degraded. Anything
# less that was fully read is `false`. **A worker's own report and a closed feedback issue are
# evidence of nothing here** — neither is read, and there is no argument by which either could
# reach this script.
#
# NO STORE, NO CURSOR, NO FIELD ON ANY ARTIFACT, and no deployment reading: a merge is not a
# deployment, so `complete` says nothing about a target and the tick reports a pending or
# failed deployment as its own state (`commands/infinite-development.md`).

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ACT_EFFECT="${SCRIPT_DIR}/../../drive/scripts/act-effect.sh"
LIST_CLAIMS="${SCRIPT_DIR}/../../drive/scripts/list-claims.sh"
PLAN_UNITS="${SCRIPT_DIR}/../../drive/scripts/plan-units.sh"

ROOT=""
CLAIMS_FILE=""
PLAN_FILE=""
UNITS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --root)       ROOT=${2:-}; shift 2 ;;
        --claims)     CLAIMS_FILE=${2:-}; shift 2 ;;
        --plan-units) PLAN_FILE=${2:-}; shift 2 ;;
        --unit)       UNITS="${UNITS}${2:-}
"; shift 2 ;;
        *) shift ;;
    esac
done
[ -n "$ROOT" ] || ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
[ -d "$ROOT" ] && ROOT=$(CDPATH='' cd -- "$ROOT" && pwd)

degraded=""
note_degraded() {
    degraded="${degraded}$(jq -cn --arg source "$1" --arg reason "$2" '{source:$source,reason:$reason}')"
}

# --- the queue, from the survey's own count ---------------------------------------------------
queued=null
plan=""
if [ -n "$PLAN_FILE" ]; then
    plan=$(cat "$PLAN_FILE" 2>/dev/null || true)
    [ -n "$plan" ] || note_degraded plan-units handed_reading_unreadable
elif [ -f "$PLAN_UNITS" ]; then
    plan=$(cd "$ROOT" && sh "$PLAN_UNITS" 2>/dev/null || true)
    [ -n "$plan" ] || note_degraded plan-units reader_failed
else
    note_degraded plan-units reader_missing
fi
if [ -n "$plan" ]; then
    if printf '%s' "$plan" | jq -e 'has("backlog_size")' >/dev/null 2>&1; then
        # The survey's five `ok`-forbidding facts are its own; a survey that forbids `ok` has
        # not established an empty queue, so its count is not usable as one here either.
        if [ "$(printf '%s' "$plan" | jq -r '(.current != true) or (.shallow == true)
                or ((.backlog_error // "") != "") or (.owner_unresolved == true)
                or (.placeholder_identity == true)')" = true ]; then
            note_degraded plan-units survey_not_current
        else
            queued=$(printf '%s' "$plan" | jq -r '.backlog_size')
        fi
    else
        note_degraded plan-units reader_unparseable
    fi
fi

# --- the claims, from the one oracle ----------------------------------------------------------
standing=null
standing_mine=null
claims=""
if [ -n "$CLAIMS_FILE" ]; then
    claims=$(cat "$CLAIMS_FILE" 2>/dev/null || true)
    [ -n "$claims" ] || note_degraded list-claims handed_reading_unreadable
elif [ -f "$LIST_CLAIMS" ]; then
    claims=$(cd "$ROOT" && sh "$LIST_CLAIMS" 2>/dev/null || true)
    [ -n "$claims" ] || note_degraded list-claims reader_failed
else
    note_degraded list-claims reader_missing
fi
if [ -n "$claims" ]; then
    if ! printf '%s' "$claims" | jq -e 'has("claims")' >/dev/null 2>&1; then
        note_degraded list-claims reader_unparseable
    elif [ "$(printf '%s' "$claims" | jq -r '.fetched // false')" != true ]; then
        note_degraded list-claims origin_unreachable
    elif [ "$(printf '%s' "$claims" | jq -r '.shallow // false')" = true ]; then
        note_degraded list-claims shallow_history
    else
        me=${WORKAHOLIC_CLAIM_IDENTITY:-$(cd "$ROOT" && git config user.email 2>/dev/null || true)}
        standing=$(printf '%s' "$claims" | jq -r '[.claims[]?] | length')
        if [ -n "$me" ]; then
            standing_mine=$(printf '%s' "$claims" | jq -r --arg me "$me" \
                '[.claims[]? | select((.author // "") == $me)] | length')
        else
            note_degraded list-claims identity_unresolved
        fi
    fi
fi

# --- merged evidence, per unit this tick names ------------------------------------------------
rows=""
merged=0
merged_readable=true
if [ -n "$UNITS" ]; then
    if [ ! -f "$ACT_EFFECT" ]; then
        note_degraded act-effect reader_missing
        merged_readable=false
    else
        # The oracle reading above is HANDED ON rather than re-made. `act-effect.sh` composes
        # `list-claims.sh` for the row, so without this a tick naming N units paid N+1 scans and
        # N+1 fetches of one fact that cannot change between them — and the two readings could
        # disagree, which is the drift a single reading exists to prevent.
        handed=""
        if [ -n "$claims" ]; then
            handed="$(mktemp)"
            printf '%s' "$claims" >"$handed"
        fi
        for unit in $UNITS; do
            out=$(cd "$ROOT" && sh "$ACT_EFFECT" delivery "$unit" ${handed:+--claims "$handed"} 2>/dev/null || true)
            if printf '%s' "$out" | jq -e 'has("effect")' >/dev/null 2>&1; then
                effect=$(printf '%s' "$out" | jq -r '.effect')
                source=$(printf '%s' "$out" | jq -r '.source // ""')
            else
                effect=unreadable; source=act-effect.sh
            fi
            case "$effect" in
                taken) merged=$((merged + 1)) ;;
                unreadable) merged_readable=false; note_degraded act-effect "unit_unreadable:${unit}" ;;
            esac
            rows="${rows}$(jq -cn --arg unit "$unit" --arg effect "$effect" --arg source "$source" \
                '{unit:$unit,effect:$effect,source:$source}')"
        done
        [ -z "$handed" ] || rm -f "$handed"
    fi
fi
[ "$merged_readable" = true ] || merged=null

# --- the verdict ------------------------------------------------------------------------------
# `complete` is null on ANY degradation. A reading that could not be made is never a `false`
# either: `false` asserts outstanding work was seen, and this reader did not see it.
readable=true
[ -z "$degraded" ] || readable=false

complete=null
if [ "$readable" = true ]; then
    outstanding=$(printf '%s' "$rows" | jq -s '[.[] | select(.effect != "taken")] | length')
    if [ "$outstanding" -eq 0 ] && [ "$standing_mine" = 0 ] && [ "$queued" = 0 ]; then
        complete=true
    else
        complete=false
    fi
fi

printf '%s' "$rows" | jq -s \
    --argjson complete "$complete" \
    --argjson merged "$merged" \
    --argjson standing "$standing" \
    --argjson standing_mine "$standing_mine" \
    --argjson queued "$queued" \
    --argjson readable "$readable" \
    --argjson degraded "$(printf '%s' "$degraded" | jq -s '.')" \
    '{complete:$complete, merged:$merged, standing_claims:$standing,
      standing_claims_mine:$standing_mine, queued:$queued, units:., degraded:$degraded}
     + (if $readable then {} else {readable:false} end)'
