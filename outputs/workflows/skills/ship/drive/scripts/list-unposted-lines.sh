#!/bin/sh -eu
# The CANDIDATE READER for the finish-line re-send: which of this identity's standing claims is
# carrying a line the transport would not take?
#
# Usage: list-unposted-lines.sh
# Output: {"ok": bool, "reason": "", "fetched": bool, "shallow": bool, "count": <n>|null,
#          "candidates": [{"unit": "...", "branch": "work-...", "shape": "...",
#                          "reason": "post_refused", "text": "..."}],
#          "unreadable": [{"unit": "...", "branch": "...", "reason": "..."}]}
#         Always exit 0 — a degraded read is an answer, and its caller reports it rather than
#         failing the run on it.
#
# WHY IT EXISTS (2026-09-03, mission `deliver-a-post-the-transport-refused-or-say-it-reached-nobody`).
# `record-unposted-line.sh` leaves the fact on the unit's own story; nothing read it back, so the
# record would have been a store nobody consulted. The loop turns every five minutes and the
# re-send rides that tick — no timer, no queue, no cursor and no second liveness authority beside
# the branch tip.
#
# WHAT IT COVERS, AND THE LIMIT IS STATED RATHER THAN WORKED AROUND. The record lives on the
# unit's branch, so this reaches every unit whose CLAIM STILL STANDS — a `🟡 Handoff`, a unit at
# an open pull request, a unit whose merge was refused. That is the measured case: three
# `🟡 Handoff` lines lost on 2026-09-02, every one of them a unit whose claim stands by design.
# A unit that MERGED is deliberately not covered: the merge releases the claim and deletes the
# branch, so there is no branch to record onto and no branch to read back from, and carrying it
# would mean writing to the base outside a merge — which no run may do. Such a line is reported
# unposted by the run that lost it and carried by nobody.
#
# IT IS NOT A SECOND ORACLE. It composes `list-claims.sh` — one walk of the refs — and reads each
# candidate's story blob straight off the branch with `read-unposted-line.sh`, the one reader of
# that section's format. No second walk, no re-derived verdict, no field on any artifact.
#
# THE IDENTITY TERM IS THE ORACLE'S OWN. `foreign_identity` and `identity_unresolved` are
# verdicts, so a claim that is not this runner's cannot reach the candidate list — a colleague's
# unposted line is theirs to send, and posting it as us would put a line in the channel under the
# wrong account.
#
# AN UNREADABLE STORY IS NAMED, NEVER DROPPED. `unreadable[]` carries the reason
# `read-unposted-line.sh` gave, because *this unit is carrying nothing* and *I could not look at
# this unit* send a reader to different places — the same rule the base-health and residue reads
# already carry.
#
# PURE READ. No branch, no worktree, no claim touched, no ref written, no file written, no
# network call the scan does not already make; exit 0 on every path.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

LISTER="${SCRIPT_DIR}/list-claims.sh"
READER="${SCRIPT_DIR}/../../story/scripts//read-unposted-line.sh"

FETCHED=false
SHALLOW=false

emit() {
    printf '{"ok": %s, "reason": "%s", "fetched": %s, "shallow": %s, "count": %s, "candidates": [%s], "unreadable": [%s]}\n' \
        "$1" "$2" "$FETCHED" "$SHALLOW" "${4:-null}" "${3:-}" "${5:-}"
    exit 0
}

[ -f "$LISTER" ] || emit false no_claim_reader
[ -f "$READER" ] || emit false no_line_reader

out=$(sh "$LISTER" 2>/dev/null || true)
[ -n "$out" ] || emit false claims_unreadable
printf '%s' "$out" | jq -e . >/dev/null 2>&1 || emit false claims_unparseable

FETCHED=$(printf '%s' "$out" | jq -r '.fetched // false')
SHALLOW=$(printf '%s' "$out" | jq -r '.shallow // false')

[ "$FETCHED" = "true" ] || emit false origin_unreachable
[ "$SHALLOW" = "true" ] && emit false shallow_history

# Every row whose verdict is one of this identity's own. A claim that reported at all is the only
# one that can carry a line — a unit posts its finish once it has finished — but the verdict is
# not narrowed further than that here: which verdicts a standing claim can hold is the oracle's
# business, and re-listing them would be a second copy to keep in step.
rows=$(printf '%s' "$out" \
    | jq -r '.claims[]? | select(.resume_reason != "foreign_identity" and .resume_reason != "identity_unresolved")
             | [.unit, .branch] | @tsv' 2>/dev/null || true)

candidates=""
csep=""
unreadable=""
usep=""
count=0

# The rows go through a temp file rather than a pipe: the loop below accumulates into shell
# variables, and a `while` on the right of a pipe runs in a subshell whose assignments are lost.
scratch=$(mktemp 2>/dev/null || printf '')
[ -n "$scratch" ] || emit false no_tmpfile
trap 'rm -f "$scratch"' EXIT INT TERM
printf '%s\n' "$rows" > "$scratch"

while IFS="$(printf '\t')" read -r unit branch; do
    [ -n "${branch:-}" ] || continue
    line=$(sh "$READER" --ref "origin/${branch}" --branch "$branch" 2>/dev/null || true)
    [ -n "$line" ] || continue
    found=$(printf '%s' "$line" | jq -r '.found // false' 2>/dev/null || printf 'false')
    readable=$(printf '%s' "$line" | jq -r '.readable // false' 2>/dev/null || printf 'false')
    if [ "$readable" != "true" ]; then
        why=$(printf '%s' "$line" | jq -r '.unreadable_reason // ""' 2>/dev/null || printf '')
        # `story_unreadable` on a branch with no story at all is the ordinary state of a claim
        # that has not reported yet, not a degradation — it is skipped rather than named, so the
        # list says what could not be read and not what was never written.
        [ "$why" = "story_unreadable" ] && continue
        unreadable="${unreadable}${usep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"reason\": \"${why}\"}"
        usep=", "
        continue
    fi
    [ "$found" = "true" ] || continue
    entry=$(printf '%s' "$line" | jq -c --arg u "$unit" --arg b "$branch" \
        '{unit: $u, branch: $b, shape: .shape, reason: .reason, text: .text}' 2>/dev/null || printf '')
    [ -n "$entry" ] || continue
    candidates="${candidates}${csep}${entry}"
    csep=", "
    count=$((count + 1))
done < "$scratch"

emit true "" "$candidates" "$count" "$unreadable"
