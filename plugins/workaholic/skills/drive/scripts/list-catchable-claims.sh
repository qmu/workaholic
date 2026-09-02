#!/bin/sh -eu
# The CANDIDATE READER for the catch-up: which of this identity's reported claims can the loop
# still bring back onto the base by itself?
#
# Usage: list-catchable-claims.sh [base-branch]
# Output: {"ok": bool, "reason": "", "fetched": bool, "shallow": bool,
#          "count": <n>|null,
#          "candidates": [{"unit": "...", "branch": "work-...",
#                          "resume_reason": "report_undelivered"|"queue_drained",
#                          "mergeability": "mechanical"|"content"}]}
#         Always exit 0 — a degraded read is an answer, and its caller reports it rather than
#         failing the run on it.
#
# WHY IT EXISTS (2026-08-30, mission `catch-a-reported-claim-up-before-its-conflict-hardens`).
# One `mergeability` reading feeds two candidate sets that disagree. `/moderate`'s
# retired `catchup-blocked` step ASKED about a `content` conflict on a `report_undelivered` OR a
# `queue_drained` claim; `/implement` ACTS only on `report_undelivered`, because its one caller
# is the `undelivered[]` loop. So a `queue_drained` claim is asked about once its conflict has
# HARDENED and never acted on while it is still machine-settleable — the loop waiting for its
# own finished work to become a person's job. Measured live: one claim mechanical for four days,
# another content for twelve.
#
# `catch-up-claim.sh` never needed a delivery-verdict gate of its own; the only reason it never
# saw a `queue_drained` claim is which loop called it. This widens the CANDIDATE SET and touches
# the writer not at all.
#
# IT IS NOT A SECOND ORACLE. It composes `list-claims.sh` — one walk of the refs — and re-derives
# nothing: not `mergeability`, not the resume reason, not the refs walk. A reader that recomputed
# `mergeability` would be the second derivation the claim protocol refuses by name everywhere
# else, and the two answers would drift the first time either changed. It adds no queue, no
# cursor, no stored state and no field on any artifact.
#
# THE LIVE-ROW RULE IS THE LIBRARY'S, NOT A COPY. A unit can be held by a `superseded` branch and
# a live one — the shape a fresh claim over a superseded one creates — and first-match is the
# OLDEST, i.e. the dead one. `claims_unit_resolution` / `claims_unit_row` are called here over a
# TSV projection of the reader's own rows, the same derivation `claim.sh`, `release-claim.sh`,
# `retire-claim.sh` and `catch-up-claim.sh` read.
#
# WHY `clean` IS DELIBERATELY NOT A CANDIDATE. There is nothing to catch up, and
# `catch-up-claim.sh` would answer `already_current` after attaching a worktree. Filtering here
# keeps the steady state — every reported claim current with the base — costing the run nothing
# at all rather than a worktree per claim per tick. `content` is not a candidate either: it is a
# person's, refused by the writer and asked about by `/moderate`. `unanswerable` is the ABSENCE
# of a reading and is never actable (`../reference/claims.md`, *When a bounded act may read a
# judgement*).
#
# THE OPEN-PULL-REQUEST TERM IS READ OFF THE ROW, AND COSTS NO LOOKUP. Both admitted verdicts
# already MEAN "at an open pull request" in the oracle's own definitions — `report_undelivered`
# is "finished, pushed, at an open pull request" and `queue_drained` is "reported, pushed, at an
# open pull request, with no recorded merge refusal". Adding a REST call per candidate here would
# derive a second time what the verdict already carries, would duplicate the lookup
# `catch-up-claim.sh` makes for its own review bound, and would make this reader — a pure,
# offline read — need a credential. Measured against the alternative and recorded rather than
# left implicit.
#
# A DEGRADED READ YIELDS NO CANDIDATES, ITS REASON AND NULL COUNTS, never a bare empty set: a
# healthy quiet run and a scan that could not reach the remote are byte-identical otherwise, and
# the second has not found "nothing to catch up" — it has found nothing at all. A shallow scan is
# the same shape one step over, since a superseded claim is indistinguishable from a live one
# across a graft boundary.
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
    printf '{"ok": %s, "reason": "%s", "fetched": %s, "shallow": %s, "count": %s, "candidates": [%s]}\n' \
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

# A REPORTED claim of this identity whose branch the base may still accept without a person's
# judgement. The identity term is the oracle's own: `foreign_identity` and `identity_unresolved`
# are verdicts, so a claim that is not this runner's can never carry one of the two admitted
# words.
#
# `content` JOINED `mechanical` ON 2026-09-02 (mission
# `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`), and this reader had to move
# with the act or the widening would be unreachable: `catch-up-claim.sh` now attempts a
# `content`-classed branch — because `mergeability` is a PREDICTION computed with the
# repository's `.gitattributes` out of reach, and the writer merges in a real checkout where the
# union driver is in force — but `/implement` only ever calls it for what THIS reader offers.
# A reader left at `mechanical` would have made the change a no-op through the one caller that
# uses it.
#
# `unanswerable` IS STILL NOT OFFERED. It is the absence of a reading, the act refuses it by
# name, and offering a candidate the act must refuse spends a worktree to learn nothing.
units=$(printf '%s' "$out" \
    | jq -r '[.claims[]?
              | select((.resume_reason == "report_undelivered" or .resume_reason == "queue_drained")
                       and (.mergeability == "mechanical" or .mergeability == "content"))
              | .unit] | unique | .[]' 2>/dev/null || true)

candidates=""
sep=""
count=0
for unit in $units; do
    [ -n "$unit" ] || continue
    # THE LIVE ROW WINS. Resolve through the library, then read the resolved row's own verdict
    # and class — a unit whose live row is a different claim is governed by that row, and the
    # dead branch beside it governs nothing.
    case "$(claims_unit_resolution "$rows" "$unit")" in
        single | live ) ;;
        * ) continue ;;
    esac
    row=$(claims_unit_row "$rows" "$unit")
    [ -n "$row" ] || continue
    branch=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
    verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')
    [ -n "$branch" ] || continue
    case "$verdict" in
        report_undelivered | queue_drained ) ;;
        * ) continue ;;
    esac
    class=$(printf '%s' "$out" | jq -r --arg b "$branch" \
        '[.claims[]? | select(.branch == $b) | .mergeability] | first // ""' 2>/dev/null || printf '')
    # THE CLASS IS CARRIED THROUGH, NEVER FLATTENED. It used to be re-spelled as the literal
    # `mechanical` here, which was harmless while that was the only admitted word and became a
    # lie the moment `content` joined it. A caller reporting the candidate quotes this field.
    case "$class" in
        mechanical | content ) ;;
        * ) continue ;;
    esac
    candidates="${candidates}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"resume_reason\": \"${verdict}\", \"mergeability\": \"${class}\"}"
    sep=", "
    count=$((count + 1))
done

emit true "" "$candidates" "$count"
