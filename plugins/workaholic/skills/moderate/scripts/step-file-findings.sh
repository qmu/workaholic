#!/bin/sh -eu
# Step — turn a REPAIRABLE finding of this tick into one `[FB]` issue the loop can drive.
#
# WHY THIS STEP EXISTS (2026-08-29, mission `let-the-tick-s-own-findings-become-the-loop-s-work`).
# `/moderate` had two destinations for a finding: a QUESTION to a person, or a FEEDBACK RECORD.
# Neither becomes work, because `[Specificate]`'s unattended entrance reads GitHub ISSUES — so
# the tick's own debt accumulated hour after hour where nothing could drive it, while the only
# in-tick caller of the one filer acted on a PERSON'S answer and never on a finding of its own.
# The third destination is an issue, and this step is what supplies it.
#
# ONLY A `repairable` FINDING, AND THE CLASSIFICATION HAS ONE HOME. The table lives in
# `reference/workflow.md`, keyed on the step id `run.sh`'s own `STEPS` already fixes, and is READ
# here rather than restated — a second copy is exactly the drift the table exists to prevent, and
# the suite fails on a step id classified inside any script. An unclassified step is
# `needs_ruling`, which falls out of this for free: a step the table does not name is not in the
# repairable set, so it is never a candidate.
#
# ITS CANDIDATES ARE THE RUN'S OWN STEP REPORTS. `run.sh` names the accumulated rows in
# `WORKAHOLIC_TICK_REPORTS`, so this step reads what the steps before it reported — including each
# step's `event`, the honest "a repository event happened here" signal, which the tick log
# deliberately does not carry. A step reports a FINDING when it supplied an event, or when it was
# `degraded` or `blocked` — our own machinery failing is the loop's debt as surely as a stuck
# pull request is.
#
# IT WRITES NOTHING — not even its own tick-log line, which `run.sh` writes. The filing is a
# NETWORK WRITE and a composition, so it goes back in `needs_agent` and the agent takes it after
# `run.sh` returns, exactly as `step-inbound-sweep.sh` and `step-standing-rulings.sh` split their
# acts. The issue lives on GitHub, outside the tree, which is the ground `/propose`'s inbound
# sweep already stands on, so the tick's *writes nothing but its own log line* contract is intact.
#
# ITS `event` IS ALWAYS EMPTY, `standing-rulings`' rule for `standing-rulings`' reason: at the
# moment `run.sh` reads this line NOTHING HAS BEEN FILED, because the agent acts afterwards. An
# event here would announce an act this step has not taken, and a tick that filed nothing would
# render a root line saying so.
#
# IT NEVER REACHES `plan-units.sh` — `undrivable-units`' rule, first recorded by
# `closable-missions`: that survey runs the living migrations and STAGES what they converge, and
# a step whose contract is *writes nothing* may not reach it through something that writes.
#
# Usage: step-file-findings.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TABLE="${SCRIPT_DIR}/../reference/workflow.md"
LEDGER="${SCRIPT_DIR}/list-finding-issues.sh"
. "${SCRIPT_DIR}/lib/question-id.sh"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit() {
    # $1 status  $2 reason  $3 summary  $4 needs_agent body
    printf '{"step": "file-findings", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": ""}\n' \
        "$1" "$2" "$(json_escape "$3")" "${4:-}"
    exit 0
}

command -v jq >/dev/null 2>&1 || emit degraded jq_unavailable "jq is not on PATH, so no finding could be classified"
[ -f "$TABLE" ] || emit degraded no_classification_table "the finding classification is not at reference/workflow.md"

# --- 1. The repairable set, read out of the table's own rows --------------------------
# One derivation, in the table's home. A step id absent here is `needs_ruling` by the table's
# stated default and therefore never a candidate.
repairable=$(sed -n 's#^| *`\([a-z-]\{1,\}\)` *| *\**`repairable`.*#\1#p' "$TABLE" | sort -u)
[ -n "$repairable" ] || emit degraded classification_unreadable \
    "no repairable step could be read out of the classification table"

# --- 2. This tick's own step reports --------------------------------------------------
reports="${WORKAHOLIC_TICK_REPORTS:-}"
[ -n "$reports" ] && [ -f "$reports" ] || emit degraded reports_unavailable \
    "the run did not name its own step reports, so no finding could be read"
printf '%s' "$(cat "$reports")" | jq -e . >/dev/null 2>&1 || emit degraded reports_unreadable \
    "the run's step reports could not be parsed, so no finding could be read"

repairable_json=$(printf '%s\n' "$repairable" | jq -R . | jq -sc .)

# A step reports a FINDING when it supplied an `event`, or when it was `degraded`/`blocked`.
# The first is the step's own statement that a repository event happened; the second is our own
# machinery failing, which is the loop's debt too.
found=$(jq -c --argjson repairable "$repairable_json" '
  [ (.steps // [])[]
    | select(.step as $s | $repairable | index($s))
    | select(((.event // "") != "") or (.status == "degraded") or (.status == "blocked"))
    | {step: .step, status: .status, reason: (.reason // ""),
       summary: (.summary // ""), event: (.event // "")} ]' < "$reports" 2>/dev/null || printf '[]')
[ -n "$found" ] || found='[]'

# Everything else this tick found is LEFT to a person — it reaches them through its own
# question, and re-listing it here would be the report addressed to nobody this repository has
# twice retired posts for. It is a count.
left=$(jq -r --argjson repairable "$repairable_json" '
  [ (.steps // [])[]
    | select(.step as $s | $repairable | index($s) | not)
    | select(((.event // "") != "") or (.status == "degraded") or (.status == "blocked")) ]
  | length' < "$reports" 2>/dev/null || printf '0')
case "$left" in ''|*[!0-9]*) left=0 ;; esac

n=$(printf '%s' "$found" | jq -r 'length')
case "$n" in ''|*[!0-9]*) n=0 ;; esac

if [ "$n" -eq 0 ]; then
    emit ok no_candidates "no repairable finding this tick; ${left} left to a person"
fi

# --- 3. The finding id, derived where every other question id is derived --------------
# `lib/question-id.sh` is the one derivation, so the filing and the asking cannot disagree about
# what "the same finding" is — which is what lets ticket 6's suppression hold exactly the
# question a filing answers. The key is the STEP ID and nothing else: a finding's summary moves
# as the world moves, and keying on it would re-file the same finding whenever its wording
# changed.
ids=""
i=0
while [ "$i" -lt "$n" ]; do
    step=$(printf '%s' "$found" | jq -r ".[$i].step")
    ids="${ids:+${ids} }$(question_slug "finding:${step}")"
    i=$((i + 1))
done
ids_json=$(printf '%s' "$ids" | tr ' ' '\n' | sed '/^$/d' | jq -R . | jq -sc .)

candidates=$(printf '%s' "$found" | jq -c --argjson ids "$ids_json" \
    '[ range(0; length) as $i | .[$i] + {finding_id: $ids[$i], subject: ("finding:" + .[$i].step)} ]')

# --- 4. The ledger: the brake, then the dedup -----------------------------------------
# One read of one ledger answers both — `any_open` for the brake, `filed_ids` for the dedup —
# because two readers of one ledger drift. An unreadable ledger files NOTHING and is named
# distinctly from a held one: *one is already in flight* and *I could not look* are different
# facts about the loop, and collapsing them is how a broken gate reads as a working one.
[ -f "$LEDGER" ] || emit degraded no_ledger_reader \
    "list-finding-issues.sh is not present beside this step"
ledger=$( ( cd "$ROOT" && sh "$LEDGER" ) 2>/dev/null || true )
if [ -z "$ledger" ] || ! printf '%s' "$ledger" | jq -e . >/dev/null 2>&1; then
    emit degraded brake_unreadable \
        "the finding issues could not be read, so nothing is filed (${n} repairable, ${left} left to a person)"
fi
if [ "$(printf '%s' "$ledger" | jq -r '.ok // false')" != "true" ]; then
    emit degraded "brake_$(printf '%s' "$ledger" | jq -r '.reason // "unreadable"' | tr -d '"')" \
        "the finding issues could not be read, so nothing is filed (${n} repairable, ${left} left to a person)"
fi

# THE BRAKE: at most one open finding issue in flight. No cursor and no stored state — the two
# states hand off with no window, because a merged repair closes its own issue and the finding
# leaves the candidate set with it. A per-day cap is refused by name: the ask is for an HOURLY
# loop, and a daily bound on the only path from the tick's debt to the work queue would cap
# that path at one turn a day. One in flight is deliberately strict; if it measurably starves
# the queue that is a finding for a later ask, not a number to raise here.
if [ "$(printf '%s' "$ledger" | jq -r '.any_open // false')" = "true" ]; then
    held=$(printf '%s' "$ledger" | jq -r '[.open[].number | tostring] | join(", #")')
    emit ok brake_held \
        "a finding issue is already open (#${held}); ${n} repairable finding(s) held, ${left} left to a person"
fi

# THE DEDUP, structural and keyed on the same step id the already-asked gate uses: a candidate
# whose id is already on an issue is dropped and COUNTED, never silently. Nothing is stored —
# the issues themselves are the memory, so a tick log that died with its container changes
# nothing here (`filed-records.sh`'s rule: a `-filed` line is never itself the proof).
filed_ids=$(printf '%s' "$ledger" | jq -c '.filed_ids // []')
remaining=$(printf '%s' "$candidates" | jq -c --argjson filed "$filed_ids" \
    '[ .[] | select(.finding_id as $id | $filed | index($id) | not) ]')
kept=$(printf '%s' "$remaining" | jq -r 'length')
case "$kept" in ''|*[!0-9]*) kept=0 ;; esac
already=$((n - kept))

if [ "$kept" -eq 0 ]; then
    emit ok all_already_filed \
        "all ${n} repairable finding(s) are already filed; ${left} left to a person"
fi
candidates="$remaining"

needs=$(jq -nc --argjson candidates "$candidates" --arg tick "$TICK" '
    {action: "file_each_repairable_finding_as_one_fb_issue",
     surface: "github",
     tick: $tick,
     bound: "one issue per candidate through propose/scripts/file-inbound-ask.sh, which stays the ONE filer and the ONE writer of the marker; assign it to the running identity so the next [Specificate] ingests it, and carry the direction through feedback/scripts/ask-feedback-line.sh, still the one writer of that line. Nothing else opens an issue.",
     marker: "pass --finding <step>:<finding_id> exactly as this candidate carries them. That visible line is what the next tick reads back as the dedup, so an issue filed without it will be filed again every hour.",
     body: "write the issue for the person and for the [Specificate] run that will read it: what the tick found, which step found it, and the repair the finding names. A step summary is written for a maintainer diagnosing the tick and reads badly as an issue body — compose, never paste.",
     direction: "judge it as the inbound sweep judges it: an explicit strategy slug wins, else the active set, else no line at all. unattributed is an ordinary answer and is never forced.",
     report: "per candidate, either the issue number it was filed as, or a named not-filed reason — a candidate handed back with no outcome is non-conformant on its face",
     candidates: $candidates}' 2>/dev/null || printf '{}')

emit ok "" \
  "${kept} repairable finding(s) to file, ${already} already filed; ${left} left to a person" \
  "$needs"
