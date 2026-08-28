#!/bin/sh -eu
# list-standing-rulings.sh — WHAT IS STANDING FOR THE OPERATOR TO RULE ON, in one place.
#
#   list-standing-rulings.sh [--root <.workaholic>] [--judgement <subject>=<answer>]...
#
# Output: {"ok", "readable", "reason",
#          "rulings": [{"kind", "subject", "decision", "evidence": {...}, "repair"}],
#          "sources": {"unattributed": {...}, "identity": {...}},
#          "count", "exhaustive": false}
#   Plus, ONLY when at least one `--judgement` was passed:
#          "judgement": {"supplied": N, "refused": [{"subject", "reason"}]}
#   Exit 0 always. PURE READ: it writes nothing and creates nothing.
#
# ═══ WHY IT EXISTS ═══════════════════════════════════════════════════════════════════
# The loop already reads both standing rulings and surfaces each as its own hourly question:
#
#   `strategy/scripts/unattributed-work.sh`        -> which active missions no direction claims
#   `workaholify/scripts/audit-identity-coverage.sh` -> which addresses no mapping entry names
#
# Two readings, two vocabularies, two questions, and each asks the operator to perform a
# repair BY HAND on `main` — the attribution by editing a mission's `feedback:` line, the
# mapping by uncommenting a line in `.claude/git-identities`. Composed into ONE set, a later
# caller can draft the whole set as one diff and the operator rules by MERGING instead.
#
# ═══ IT COMPOSES; IT WALKS NOTHING ═══════════════════════════════════════════════════
# `closing-residue.sh`'s rule, one layer across: the only thing this owns is the ASSEMBLY.
# There is NO second walk of `missions/`, `tickets/` or the `feedback:` relation here, no
# relation of its own and NO FIELD ON ANY ARTIFACT. Each composed reader stays the single
# reader of its own fact, and each entry's evidence is what that reader already said.
#
# ═══ IT JUDGES NOTHING; THE RUN DOES ════════════════════════════════════════════════
# WHICH direction a mission answers and WHICH account an address belongs to are readings only
# a person or a run can make — a script that guessed either would be AUTHORING the operator's
# ruling, which is exactly what `carry-attribution.sh`'s header forbids and what the whole
# ruling path rests on. So this reader COMPOSES readings and STORES an answer it was handed,
# and DERIVES none. The seam is `survey-strategies.sh --aim-kind`'s, one value per candidate:
#
#   --judgement <mission-slug>=<strategy-slug>     (an `attribution`)
#   --judgement <address>=<github-login>           (an `identity_mapping`)
#
# A candidate with no answer reads `decision: "undecided"` and is **never written** by any
# later caller. Absent the flag entirely the output is BYTE-IDENTICAL to the reader's first
# shipped shape — which is why `judgement` is emitted only when at least one was passed: with
# no judgement in hand there is nothing to refuse and no count to state.
#
# A judgement naming a subject this reader did not surface is REFUSED
# (`subject_not_surfaced`), never accepted: the reader's own candidate set is the domain, and
# an answer outside it means the run and the tree disagree about what is standing.
#
# The `repair` string carries a PLACEHOLDER for the half only a judgement supplies
# (`<strategy>`, `<login>`) — the same shape `audit-identity-coverage.sh` already proposes —
# and a judged entry resolves it, so a caller never re-composes the string.
#
# ═══ A DEGRADED SOURCE IS NOT AN EMPTY ONE ═══════════════════════════════════════════
# Each source carries its OWN `readable` and `reason`, and a degraded one reports **null**
# counts rather than zeroed ones — `unattributed-work.sh`'s own rule, inherited rather than
# re-decided. The top-level `readable` names WHICH source failed
# (`unattributed_unreadable:<reason>` / `identity_unreadable:<reason>`), because a half-read
# set rendered as a whole one is the collapse this layer exists to remove. A degraded source
# contributes NO entries: a ruling that could not be read is not a ruling.
#
# An EMPTY read is not a degradation. No unattributed mission and no uncovered address is a
# real answer about a real tree and keeps honest zeros. So is `map.present: false` — a mapping
# file that does not exist is a finding (`identity_map_missing`), not a failure to read one.
#
# ═══ WHAT IT DOES NOT ANSWER ═════════════════════════════════════════════════════════
# `exhaustive` is `false`, ALWAYS and by construction, inherited from what it composes: the
# attribution walk is transitive and lossy at both hops and over-reports at the mission grain,
# and the coverage audit sees only the addresses this tree happens to carry. So this is the
# set of rulings VISIBLY standing, never a claim that no others are.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
UNATTRIBUTED="${SCRIPT_DIR}/../../strategy/scripts/unattributed-work.sh"
IDENTITY_AUDIT="${SCRIPT_DIR}/../../workaholify/scripts/audit-identity-coverage.sh"

ROOT=".workaholic"
JUDGED=""      # newline-separated `<subject>\t<answer>` pairs, in the order supplied
JUDGED_N=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --judgement)
      pair="${2:-}"; shift 2
      # An argument with no `=`, or one with an empty answer, is kept rather than dropped: it
      # is a judgement the run believes it supplied, and silently losing one is how a run and
      # this reader would disagree about what was decided.
      case "$pair" in
        *=*) JUDGED="${JUDGED}${pair%%=*}	${pair#*=}
" ;;
        *)   JUDGED="${JUDGED}${pair}
" ;;
      esac
      JUDGED_N=$((JUDGED_N + 1)) ;;
    --) shift; break ;;
    -*) printf '{"ok": false, "readable": false, "reason": "usage", "rulings": [], "sources": {}, "count": 0, "exhaustive": false}\n' >&2; exit 0 ;;
    *) break ;;
  esac
done

json_str() { printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200; }

emit_unreadable() {
  printf '{"ok": true, "readable": false, "reason": "%s", "rulings": [], "sources": {"unattributed": {"readable": false, "reason": "%s", "mission_count": null, "ticket_count": null}, "identity": {"readable": false, "reason": "%s", "map_present": null, "addresses": null, "covered": null, "uncovered_count": null}}, "count": null, "exhaustive": false}\n' \
    "$(json_str "$1")" "$(json_str "$1")" "$(json_str "$1")"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_unreadable "jq_unavailable"

# The coverage audit is addressed at the REPOSITORY root, not at the bundle root: it reads
# `.claude/git-identities` beside `.workaholic/`. Deriving it here keeps one `--root` on the
# command line rather than two the caller must keep in step.
REPO_ROOT="$(dirname -- "$ROOT")"
[ -n "$REPO_ROOT" ] || REPO_ROOT="."

# --- 1. What no direction claims, from that fact's own single reader ---------------------
U_BLOCK='{"readable": false, "reason": "no_unattributed_work_script", "mission_count": null, "ticket_count": null}'
U_ENTRIES='[]'
if [ -f "$UNATTRIBUTED" ]; then
  U_OUT="$(sh "$UNATTRIBUTED" --root "$ROOT" 2>/dev/null || true)"
  if [ -n "$U_OUT" ] && printf '%s' "$U_OUT" | jq -e . >/dev/null 2>&1; then
    if [ "$(printf '%s' "$U_OUT" | jq -r '.readable // false')" = "true" ]; then
      U_BLOCK="$(printf '%s' "$U_OUT" | jq -c '{readable: true, reason: "",
                                                mission_count: (.mission_count // 0),
                                                ticket_count: (.ticket_count // 0)}')"
      # A LOOSE QUEUED TICKET IS NOT A CANDIDATE. `unattributed-work.sh` answers at the
      # mission grain and says so, so a ticket appearing in its residue may well cite a live
      # direction through its own refs; drafting an attribution for one would be ruling on a
      # reading its own source refuses to make. The count is carried; the entries are not.
      U_ENTRIES="$(printf '%s' "$U_OUT" | jq -c '[.missions[]? | {
        kind: "attribution",
        subject: .slug,
        decision: "undecided",
        evidence: {path: (.path // ""), queued: (.queued // 0)},
        repair: ("carry-attribution.sh <strategy> " + .slug)}]')"
    else
      U_BLOCK="$(printf '%s' "$U_OUT" | jq -c '{readable: false, reason: (.reason // "residue_unreadable"),
                                                mission_count: null, ticket_count: null}')"
    fi
  else
    U_BLOCK='{"readable": false, "reason": "unattributed_work_unreadable", "mission_count": null, "ticket_count": null}'
  fi
fi

# --- 2. What no mapping entry names, from that fact's own single reader ------------------
I_BLOCK='{"readable": false, "reason": "no_identity_audit_script", "map_present": null, "addresses": null, "covered": null, "uncovered_count": null}'
I_ENTRIES='[]'
if [ -f "$IDENTITY_AUDIT" ]; then
  I_OUT="$(sh "$IDENTITY_AUDIT" "$REPO_ROOT" 2>/dev/null || true)"
  if [ -n "$I_OUT" ] && printf '%s' "$I_OUT" | jq -e . >/dev/null 2>&1; then
    I_BLOCK="$(printf '%s' "$I_OUT" | jq -c '{readable: true, reason: "",
                                              map_present: (.map.present // false),
                                              addresses: (.addresses // 0),
                                              covered: (.covered // 0),
                                              uncovered_count: ((.uncovered // []) | length)}')"
    # The audit's own proposed line, carried verbatim: its `<login>` placeholder is the half
    # only a judgement supplies, and re-composing the string here would be a second format.
    I_ENTRIES="$(printf '%s' "$I_OUT" | jq -c '[.uncovered[]? | {
      kind: "identity_mapping",
      subject: .address,
      decision: "undecided",
      evidence: {artifacts: (.artifacts // 0)},
      repair: (.line // "")}]')"
  else
    I_BLOCK='{"readable": false, "reason": "identity_audit_unreadable", "map_present": null, "addresses": null, "covered": null, "uncovered_count": null}'
  fi
fi

TMP_J=$(mktemp)
trap 'rm -f "$TMP_J"' EXIT INT TERM
printf '%s' "$JUDGED" > "$TMP_J"

jq -nc \
  --argjson u "$U_BLOCK" \
  --argjson i "$I_BLOCK" \
  --argjson ue "$U_ENTRIES" \
  --argjson ie "$I_ENTRIES" \
  --argjson jn "$JUDGED_N" \
  --rawfile judged "$TMP_J" '
  # The judgements the run handed in, in the order it handed them: `<subject>\t<answer>`.
  ($judged | split("\n") | map(select(length > 0))
   | map(split("\t") | {subject: .[0], answer: (.[1] // "")})) as $j
  | [ (if ($u.readable | not) then "unattributed_unreadable:" + ($u.reason // "") else empty end),
      (if ($i.readable | not) then "identity_unreadable:"     + ($i.reason // "") else empty end)
    ] as $bad
  | ($ue + $ie) as $candidates
  | ($candidates | map(.subject)) as $domain
  | ($candidates | map(
      . as $c
      # An entry takes the FIRST answer naming it. A second judgement of the same subject is a
      # run contradicting itself within one call; taking the first keeps the reading stable.
      | (($j | map(select(.subject == $c.subject and (.answer | length) > 0)) | first) // null) as $a
      | if $a == null then .
        else .decision = $a.answer
             # The repair resolves the half only the judgement supplies, so no caller ever
             # re-composes the string in a second format.
             | .repair = (if $c.kind == "attribution"
                          then "carry-attribution.sh " + $a.answer + " " + $c.subject
                          else $a.answer + "=" + $c.subject end)
        end)) as $rulings
  | ($j | map(select((.answer | length) == 0)
              | {subject: .subject, reason: "malformed_judgement"})
       + map(. as $x
              | select(($x.answer | length) > 0 and (($domain | index($x.subject)) == null))
              | {subject: $x.subject, reason: "subject_not_surfaced"})) as $refused
  | {ok: true,
     readable: (($bad | length) == 0),
     reason: ($bad | join("; ")),
     rulings: $rulings,
     sources: {unattributed: $u, identity: $i},
     count: ($rulings | length),
     # ALWAYS false: both composed readers are lossy and say so.
     exhaustive: false}
  # Emitted ONLY when a judgement was supplied, so the no-flag output stays byte-identical to
  # the shape this reader first shipped.
  | if $jn > 0 then . + {judgement: {supplied: $jn, refused: $refused}} else . end'
