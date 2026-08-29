#!/bin/sh -eu
# finding-suppression.sh — WHICH STEPS' FINDINGS AN OPEN FINDING ISSUE ALREADY CARRIES, so the
# hourly question about exactly those findings is held while the loop is driving the repair.
#
#   finding-suppression.sh
#
# Output: {"ok": true, "readable": true|false, "reason": "",
#          "any_open": true|false,
#          "open": [{"number": N, "url": "..."}],
#          "held": {"steps": ["<step id>", ...]}}
#   Exit 0 always. PURE READ: it writes nothing and creates nothing.
#
# ═══ WHY IT EXISTS ═══════════════════════════════════════════════════════════════════
# Once a finding has become work, asking a person about it is asking them — the same person, in
# the same hour — about the thing the loop is already driving. Hold exactly that question.
#
# ═══ A SIBLING READER, NOT AN EXTENSION OF `ruling-suppression.sh` ═══════════════════
# Reported rather than assumed. What the two share is the SHAPE and all four of its rules; what
# they do not share is the SOURCE — a ruling is an open pull request, a finding is an open
# issue. Extending `ruling-suppression.sh`'s `held` map would put two unrelated network reads
# behind one call, so a step consulting it about rulings would pay for a finding read it never
# wanted, and the script's own one-reader-per-fact rule would still need a second reader inside
# it. So: same shape, one reader per fact, and neither reads the other's ledger.
#
# ═══ ONE READER, SO THE CONSULTING STEPS CANNOT DISAGREE ═════════════════════════════
# Every step that consults this reads it here, and none reads `list-finding-issues.sh` itself:
# two readings of one fact drift, which is the rule `ruling-suppression.sh`'s header states.
#
# ═══ IT IS KEYED ON THE SUBJECT, NEVER ON THE EXISTENCE OF A FILING ══════════════════
# That bound is the whole safety property: a filing about ONE step's finding must not silence
# the questions of a different step. `any_open` is reported beside `held` for a different job —
# a question that IS still asked while a filing is open can say so.
#
# ═══ AN UNREADABLE READ SUPPRESSES NOTHING ═══════════════════════════════════════════
# `ci-retirement-turn.sh`'s discipline: an over-eager question is better than a silently dropped
# one, so a read that failed leaves every question exactly where it was. `held` is then empty
# and `readable` is false with the reason named.
#
# ═══ THE SUPPRESSION IS DERIVED, NEVER STORED ════════════════════════════════════════
# `held` is projected from the OPEN finding issues only. The moment the repair merges — which
# auto-closes its issue — or somebody closes it, the step stops being named here and its
# question is reachable again, with no state anywhere. (The dedup keeps using the CLOSED issues
# too, which is a different question: *has this been filed* outlives *is it in flight*.)
#
# ═══ THE ORDERING, STATED RATHER THAN ENGINEERED AROUND ══════════════════════════════
# `file-findings` runs near the end of the tick and the agent files AFTER `run.sh` returns, so a
# finding filed this tick holds its question from the NEXT tick, not this one. Reordering the
# run to close that window would put the filing before the steps whose reports are its
# candidates.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LEDGER="${SCRIPT_DIR}/list-finding-issues.sh"

emit_blind() {
  printf '{"ok": true, "readable": false, "reason": "%s", "any_open": false, "open": [], "held": {"steps": []}}\n' \
    "$(printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200)"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_blind "jq_unavailable"
[ -f "$LEDGER" ] || emit_blind "no_finding_issues_reader"

OUT="$(sh "$LEDGER" 2>/dev/null || true)"
[ -n "$OUT" ] && printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 || emit_blind "finding_issues_unreadable"
[ "$(printf '%s' "$OUT" | jq -r '.ok // false')" = "true" ] \
  || emit_blind "$(printf '%s' "$OUT" | jq -r '.reason // "finding_issues_unreadable"')"

printf '%s' "$OUT" | jq -c '
  {ok: true, readable: true, reason: "",
   any_open: (((.open // []) | length) > 0),
   open: ((.open // []) | map({number: .number, url: .url})),
   held: {steps: ((.open // []) | map(.step) | map(select(. != "")) | unique)}}'
