#!/bin/sh -eu
# ruling-suppression.sh — WHICH SUBJECTS AN OPEN RULING ALREADY ASKS FOR, so the hourly
# question about exactly those subjects is held while the diff carries the ask.
#
#   ruling-suppression.sh
#
# Output: {"ok": true, "readable": true|false, "reason": "",
#          "any_open": true|false,
#          "open": [{"number": N, "url": "..."}],
#          "held": {"attribution": ["<mission slug>"], "identity_mapping": ["<address>"]}}
#   Exit 0 always. PURE READ: it writes nothing and creates nothing.
#
# ═══ WHY IT EXISTS ═══════════════════════════════════════════════════════════════════
# Once a ruling diff names a subject, the hourly question about that subject is asking the
# operator to do BY HAND on `main` what the pull request already proposes — and it is the
# same person, in the same hour, about the same thing. Hold exactly that question.
#
# ═══ ONE READER, SO THE TWO STEPS CANNOT DISAGREE ════════════════════════════════════
# `undrivable-units` and `direction-health` both consult this, and neither reads
# `list-open-rulings.sh` itself: two readings of one fact drift, which is the rule
# `direction-health` already holds to for the residue it carries rather than re-reads.
#
# ═══ IT IS KEYED ON THE SUBJECT, NEVER ON THE EXISTENCE OF A RULING ══════════════════
# That bound is the whole safety property: a ruling naming ONE mission must not silence the
# question about a DIFFERENT one. `any_open` is reported beside `held` for a different job —
# a question that IS still asked while a ruling is open can say so, which is how a subject the
# run left `undecided` names why the loop could not judge it.
#
# ═══ AN UNREADABLE READ SUPPRESSES NOTHING ═══════════════════════════════════════════
# `ci-retirement-turn.sh`'s discipline: an over-eager question is better than a silently
# dropped one, so a read that failed leaves every question exactly where it was. `held` is
# then empty and `readable` is false with the reason named.
#
# ═══ THE HOLD IS CORRECT ONLY WHILE SOMEBODY IS TOLD ABOUT THE RULING ════════════════
# (2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`.) Holding a
# subject's hourly question is right while the ruling is moving and WRONG once the ruling
# itself has gone unanswered: the loop is then silent about the ruling AND about what that
# ruling holds, at the same time. Measured 2026-08-29: #694 open 18 hours, with
# `plan-units.sh` offering nothing over a backlog of 10.
#
# THE REPAIR IS THE RULING'S OWN QUESTION, NOT A RELEASE OF THE HOLD. `step-operator-pulls.sh`
# asks the operator, once, about the un-acted pull request and names what merging it would
# unblock — read from THIS script, so the two readings share one derivation and cannot diverge
# about which subjects a ruling holds. Releasing the hold as well would ask one person twice,
# in two vocabularies, about one pull request: the doubling `handoff-units` and `stalled-units`
# were split to avoid. **Nothing in this script moved for it** — the hold stays keyed on the
# subject, an unreadable read still suppresses nothing, `overdue` and `dormant` are never held,
# and `ask-question.sh` gained nothing.
#
# RELEASING ON A TIMER IS REFUSED BY NAME: it would introduce a threshold this layer has
# refused elsewhere, and the un-acted reading is already available without one.
#
# ═══ THE SUPPRESSION IS DERIVED, NEVER STORED ════════════════════════════════════════
# The moment the operator merges or closes the ruling, the pull request is no longer open, the
# subject stops being named here, and the question is reachable again — with no state anywhere.
# (After a MERGE the subject usually leaves the candidate set on its own, because it is no
# longer unattributed or uncovered; after a CLOSE it comes straight back, which is what makes
# closing a real refusal rather than a way to silence the loop.)

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OPEN="${SCRIPT_DIR}/list-open-rulings.sh"

emit_blind() {
  printf '{"ok": true, "readable": false, "reason": "%s", "any_open": false, "open": [], "held": {"attribution": [], "identity_mapping": []}}\n' \
    "$(printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200)"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_blind "jq_unavailable"
[ -f "$OPEN" ] || emit_blind "no_open_rulings_reader"

OUT="$(sh "$OPEN" 2>/dev/null || true)"
[ -n "$OUT" ] && printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 || emit_blind "open_rulings_unreadable"
[ "$(printf '%s' "$OUT" | jq -r '.ok // false')" = "true" ] \
  || emit_blind "$(printf '%s' "$OUT" | jq -r '.reason // "open_rulings_unreadable"')"

printf '%s' "$OUT" | jq -c '
  ((.rulings // []) | map(.subjects // []) | add // []) as $subjects
  | {ok: true, readable: true, reason: "",
     any_open: (((.rulings // []) | length) > 0),
     open: ((.rulings // []) | map({number: .number, url: .url})),
     held: {attribution: ($subjects | map(select(.kind == "attribution") | .subject) | unique),
            identity_mapping: ($subjects | map(select(.kind == "identity_mapping") | .subject) | unique)}}'
