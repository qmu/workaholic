#!/bin/sh -eu
# claim-mission-state.sh — IS THE WORK BEHIND THIS CLAIM STILL WANTED? One reader, keyed on a
# unit id, answering exactly that and nothing else.
#
#   claim-mission-state.sh <unit-id>
#
# Output: {"ok": true, "unit": "<id>", "kind": "mission", "state": "active"}
#         {"ok": true, "unit": "<id>", "kind": "mission", "state": "not_active",
#          "status": "achieved"|"abandoned"|"carried"|""}
#         {"ok": true, "unit": "<id>", "kind": "batch"}          — no `state` key at all
#         {"ok": false, "unit": "<id>", "reason": "..."}          — no `state` key at all
#   Exit 0 in every case. PURE READ of the local tree: no network, no ref, no worktree, no
#   index, no field on any artifact.
#
# ═══ WHY IT EXISTS (2026-09-02, mission ══════════════════════════════════════════════
# `retire-a-claim-whose-work-is-finished-or-abandoned`). Retirement is keyed on the branch's
# own pull request (`branch-pull-request-state.sh`), so nothing in the protocol could answer
# *is the work behind this claim still wanted*. Measured: the operator closed a pull request
# and abandoned its mission, and the tick went on reporting that branch as stuck work hourly
# until a person deleted it — the claim kept every reading it had, because a mission's end
# state is read by no claim-side script at all.
#
# ═══ IT IS A READER AND NEVER A VERDICT ══════════════════════════════════════════════
# It names no candidate, fires no act, moves no claim verdict, and writes nothing anywhere.
# Whether this answer is strong enough to license a branch delete is the CANDIDATE's question
# and is settled where the candidate is derived — the shape `branch-pull-request-state.sh`'s
# own header states for the same reason, and the one `retire-claim.sh` refuses to collapse.
#
# ═══ THE AREA DECIDES, AND `status` RIDES ALONG ══════════════════════════════════════
# `missions/active/` is `active`; `missions/archive/` is `not_active`. The area is the place
# `close.sh` moves a mission to and is the term every other reader already keys on
# (`list.sh`'s own `ready_reason: not_active`, `summary.sh`'s business set). `status:` is
# carried BESIDE the answer rather than being it: `achieved`, `abandoned` and `carried` are
# three different reasons the work stopped and a consumer that must tell them apart has them,
# while a consumer that only needs *is it still wanted* reads one word. An archived mission
# whose `status:` is somehow empty still answers `not_active` with an empty `status` — the
# place is the record, and inventing a status here would be a second writer of one.
#
# ═══ A BATCH UNIT ANSWERS `kind: batch`, WHICH IS A REAL ANSWER ══════════════════════
# `batch-<ts>` names no mission, so *is its mission still active* has no subject. Answering
# `not_active` would be a lie in the one direction that costs — every batch claim in the
# repository would read as retired-by-definition — and answering `ok: false` would call our
# own correct reading a degradation. It emits no `state` key at all, so a consumer keying on
# `state` cannot mistake the absence for a value.
#
# ═══ AN UNREADABLE MISSION IS `ok: false`, NEVER `not_active` ════════════════════════
# The asymmetry that decides every reading in this protocol: a wrong `not_active` deletes a
# live branch, a wrong `ok: false` only makes a caller wait. So every degradation emits no
# `state` key and a named reason — `mission_list_unreadable`, `mission_not_found`, `no_unit`.
#
# ═══ IT COMPOSES `mission/scripts/lib/resolve.sh`, THE ONE RESOLVER ══════════════════
# `mission_resolve` is what every mission script already uses to turn a slug into a file, and
# it searches `active/` then `archive/` — so the AREA, which is this reader's whole answer,
# falls out of the path it returns. No walk over `missions/*/` of its own, and the worktree
# question (`missions_root_default` resolves through git, so a worktree resolves to its OWN
# tree) is answered by the resolver rather than re-decided here.
#
# `summary.sh` is deliberately NOT the composition point: it reports only the ACTIVE missions
# that are the caller's business, so an archived mission — the whole subject here — is
# invisible to it, and an ownership gate has no place in a question about whether work is
# wanted. `list.sh` was the first choice and was measured too expensive: it enumerates every
# mission and computes each one's progress, and `list-retirable-claims.sh` calls this reader
# ONCE PER UNIT, so composing it made the candidate scan O(units × missions) in a path that
# runs every tick.
#
# `status:` is read with the four-line `fm_field` idiom this repository already carries in five
# scripts, off the one file the resolver named — a bounded read of one field, not a second walk.
#
# The vocabulary and its proof/judgement classification: `../reference/claims.md`.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MISSION_RESOLVE="${SCRIPT_DIR}/../../mission/scripts/lib/resolve.sh"

UNIT="${1:-}"

json_escape() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r//g'
}

emit_err() {
    printf '{"ok": false, "unit": "%s", "reason": "%s"}\n' "$(json_escape "$UNIT")" "$1"
    exit 0
}

[ -n "$UNIT" ] || emit_err "no_unit"

# A `batch-<ts>` unit names no mission. Answered, never degraded.
case "$UNIT" in
    batch-*)
        printf '{"ok": true, "unit": "%s", "kind": "batch"}\n' "$(json_escape "$UNIT")"
        exit 0
        ;;
esac

[ -f "$MISSION_RESOLVE" ] || emit_err "mission_list_unreadable"
. "$MISSION_RESOLVE"

path="$(mission_resolve "$(missions_root_default)" "$UNIT" 2>/dev/null || printf '')"
[ -n "$path" ] || emit_err "mission_not_found"
[ -f "$path" ] || emit_err "mission_not_found"

# The frontmatter idiom this repository already carries in five scripts: the first `key:` line
# inside the leading `---` block, whitespace trimmed. One field, one file, no walk.
fm_field() {
    sed -n '/^---$/,/^---$/p' "$1" 2>/dev/null \
        | sed -n "s/^$2:[[:space:]]*//p" \
        | head -n 1 \
        | sed -e 's/[[:space:]]*$//'
}
status="$(fm_field "$path" status)"

case "$path" in
    *"/missions/active/"*)
        printf '{"ok": true, "unit": "%s", "kind": "mission", "state": "active"}\n' \
            "$(json_escape "$UNIT")"
        ;;
    *"/missions/archive/"*)
        printf '{"ok": true, "unit": "%s", "kind": "mission", "state": "not_active", "status": "%s"}\n' \
            "$(json_escape "$UNIT")" "$(json_escape "$status")"
        ;;
    *)
        # A mission directly under `missions/` is the pre-area legacy layout the resolver still
        # tolerates. It is neither area, so neither answer is established: named, never guessed.
        emit_err "mission_area_unresolved"
        ;;
esac
