#!/bin/sh -eu
# The CI-side CANDIDATE READER: which claim branches has the oracle proved may be deleted?
#
# Usage: list-retirable-claims.sh
# Output: {"ok": bool, "reason": "", "fetched": bool, "shallow": bool,
#          "candidates": [{"unit": "...", "branch": "work-...",
#                          "state": "present"|"already_gone"}]}
#         Always exit 0 — a degraded read is an answer, and its caller (a workflow step)
#         reports it rather than failing the job on it.
#
# WHY IT EXISTS (2026-08-28, mission `finish-a-proved-retirement-where-the-write-is-permitted`).
# Act 2 of the retirement — the remote branch delete — is refused in the container the loop runs
# in, by every available transport (`retire-claim.sh`, Act 2; `../reference/claims.md`, *When an
# act of the retirement is refused*). The act therefore moves to a different EXECUTOR, on
# `release-note-draft.yml`'s precedent, and before CI can take it something has to answer WHICH
# BRANCHES MAY BE DELETED. This is that answer, and nothing else: it deletes nothing, closes
# nothing and writes nothing anywhere.
#
# IT IS NOT A SECOND ORACLE, AND THAT IS THE WHOLE POINT. The obvious shortcut — a workflow
# shelling out to `git for-each-ref` and matching `work-*` — would delete branches nothing proved
# empty. `superseded` means the unit's content already reached the base, which is exactly why the
# branch can never land, so the derivation stays the claim oracle's: this composes
# `list-claims.sh` (one walk of the refs, not a second) and re-reads nothing itself. It adds no
# queue, no cursor, no stored state and no field on any artifact.
#
# THE LIVE-ROW RULE IS THE LIBRARY'S, NOT A COPY. A unit can be held by a `superseded` branch AND
# a live one — the shape a fresh claim over a superseded one creates — and first-match is the
# OLDEST, i.e. the dead one, so a caller that resolved by first-match would hand CI a branch a
# run is still driving. `claims_unit_resolution` is called here over a TSV PROJECTION of the
# reader's own rows: the same derivation `claim.sh`, `release-claim.sh` and `retire-claim.sh`
# read, evaluated once more rather than reimplemented. Only `superseded_only` is a candidate —
# a unit with any live row governs itself and the dead branch governs nothing.
#
# A DEGRADED READ YIELDS NO CANDIDATES AND ITS REASON, NEVER A BARE EMPTY SET. Unmerged remote
# branches are the only claim oracle, so a scan that could not reach the remote has not found
# "nothing to retire" — it has found nothing at all, and a proof that could not be read is not a
# proof. A shallow scan is the same shape one step over: a superseded claim is indistinguishable
# from a live one across a graft boundary, which is why CI defines its own full-history checkout.
# The words are `step-retire-claims.sh`'s own, deliberately — the CI side answers the same
# questions and must not invent a second vocabulary for them.
#
# `already_gone` IS A SUCCESS, not a degradation, and matches Act 2's own word. A branch absent
# from origin needs no delete, so a re-run over a set CI already took is a clean no-op rather
# than a run full of errors about work that is already done.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"
. "${SCRIPT_DIR}/lib/runner-identity.sh"

LISTER="${SCRIPT_DIR}/list-claims.sh"

FETCHED=false
SHALLOW=false

emit() {
    printf '{"ok": %s, "reason": "%s", "fetched": %s, "shallow": %s, "candidates": [%s]}\n' \
        "$1" "$2" "$FETCHED" "$SHALLOW" "${3:-}"
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

# WHERE THIS EXECUTOR HAS NO IDENTITY OF ITS OWN, RE-DERIVE PER MAPPED AUTHOR (2026-08-29,
# mission `make-the-two-executors-agree-about-a-proved-empty-claim`). `actions/checkout@v4`
# configures no `user.email`, so every row above reads `identity_unresolved` and `superseded`
# — the proof this reader exists to find — is never reached. The scan is re-run once per
# DISTINCT author the committed mapping names, and only that author's own rows are taken from
# each pass, so no claim is ever read under somebody else's identity.
#
# It is bounded three ways and each one is load-bearing: it is reachable ONLY with no configured
# identity (a container is byte-identical), it scans only as an author `identity.sh` resolves
# (an unmapped address stays `identity_unresolved` and is never impersonated), and it changes no
# gate — `claim_active` still outranks `superseded`, so a live claim reads live under every
# identity. The cost is one extra scan per distinct mapped author, and none at all otherwise.
if runner_identity_absent; then
    authors=$(printf '%s' "$out"         | jq -r '[.claims[]? | select(.resume_reason == "identity_unresolved") | .author // ""]
                 | map(select(. != "")) | unique | .[]' 2>/dev/null || true)
    for author in $authors; do
        [ -n "$author" ] || continue
        scan_as=$(runner_identity_for_author "$author")
        [ -n "$scan_as" ] || continue
        as_out=$(WORKAHOLIC_CLAIM_IDENTITY="$scan_as" sh "$LISTER" 2>/dev/null || true)
        [ -n "$as_out" ] || continue
        printf '%s' "$as_out" | jq -e . >/dev/null 2>&1 || continue
        out=$(printf '%s
%s' "$out" "$as_out" | jq -s --arg a "$author" '
            (.[1].claims // []) as $re
            | .[0]
            | .claims = [ .claims[]? as $c
                          | ( [ $re[] | select(.branch == $c.branch and (.author // "") == $a) ] | first )
                            // $c ]' 2>/dev/null || printf '%s' "$out")
    done
fi

# The TSV projection the library's resolver reads: field 1 the unit, field 2 the branch, field 7
# the verdict. The intervening columns are the scan's own and are not consulted by the resolver,
# so they are left empty rather than invented here.
rows=$(printf '%s' "$out" \
    | jq -r '.claims[]? | [.unit, .branch, "", "", "", "", .resume_reason] | @tsv' 2>/dev/null || true)

units=$(printf '%s' "$out" \
    | jq -r '[.claims[]? | select(.resume_reason == "superseded") | .unit] | unique | .[]' 2>/dev/null || true)

candidates=""
sep=""
for unit in $units; do
    [ -n "$unit" ] || continue
    # THE LIVE ROW WINS. A unit whose claims are not ALL superseded is governed by its live
    # claim, and the superseded branch beside it is reported by the oracle and acted on by
    # nothing — which is what "reported, never acted on" has always meant.
    [ "$(claims_unit_resolution "$rows" "$unit")" = "superseded_only" ] || continue
    row=$(claims_unit_row "$rows" "$unit")
    [ -n "$row" ] || continue
    branch=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
    [ -n "$branch" ] || continue
    if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
        state=present
    else
        state=already_gone
    fi
    candidates="${candidates}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"state\": \"${state}\"}"
    sep=", "
done

emit true "" "$candidates"
