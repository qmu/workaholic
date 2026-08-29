#!/bin/sh -eu
# Step 21 — is a proof the loop already made still holding?
#
# WHY THIS STEP EXISTS (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`).
# `Loop Drills` runs one matrix leg per hermetic drill on every push, so a merge that breaks a
# mechanism an earlier turn proved now fails a check. A red check reaches whoever happens to
# look at the merge; this tick is the one surface in this repository that addresses a NAMED
# PERSON, and a mechanism nobody is told about stays broken until the next time somebody needs
# it. The drill's own check run is named after the drill, so the finding can say WHICH proof
# stopped holding and WHICH earlier mission shipped it.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question       the SHIPPING MISSION'S ASSIGNEE — the person who built the mechanism
#                        and knows what it was for. It is a judgement and it is stated as one:
#                        a drill can outlive its author's involvement, which is why the
#                        question NAMES the mission so whoever reads it can redirect.
#   running identity     `undrivable-units`'. NEVER consulted. A failing drill is a fact about
#                        the repository, and an hourly question that answered differently per
#                        container is what that axis exists to prevent.
#   what it may read     `base-health`'s. `read-drill-verdicts.sh`, which composes
#                        `read-base-checks.sh` — the single reader of a commit's check runs in
#                        this plugin — and the drill register. `plan-units.sh` is REFUSED for
#                        the reason `closable-missions` records: that survey carries the living
#                        migrations and STAGES what they converge, and a step whose contract is
#                        *writes nothing* may not reach it through something that writes.
#
# THE KEY IS THE DRILL, NOT THE COMMIT AND NOT THE TICK. `drill-failing:<drill>` is what makes
# "exactly once per broken proof" mechanical: twenty-four ticks may see the same red leg and
# exactly one question goes out. Keying on the commit instead would re-ask the same question on
# every merge that followed the break, which is the hourly restatement two roots were retired
# for.
#
# A GREEN RUN PRODUCES NO QUESTION, NO EVENT AND NO ROOT LINE. That is the standing rule a
# status line addressed to nobody is noise; `base-health` holds it for the same reason and by
# the same mechanism — a step with no `event` renders no line.
#
# A DEGRADED READ ASKS NOTHING and is named (`drill_run_unreadable:<reason>`), and a repository
# that ships no `Loop Drills` workflow is `unavailable` and produces no question at all.
# Spending a person's attention on our own blindness is what `strategy-pace` already refuses.
#
# IT READS THE LAST COMPLETED RUN, never the current one — `read-base-checks.sh` answers
# `checks_pending` for a run still going, which lands here as a named degradation rather than as
# a question. A pending run is not a verdict, and asking about one is the over-eager question
# `ci-retirement-turn.sh`'s own reading already refuses.
#
# IT ASKS AND NOTHING ELSE. It never re-runs a leg, never reverts, never merges, never touches
# a claim, and writes nothing anywhere but its own tick-log line. Every reading it composes is a
# JUDGEMENT (`drive/reference/claims.md`, *Proofs and judgements*): a re-run can turn a red
# check green, so acting on it is forbidden and reporting it is the whole job.
#
# THE SUMMARY CARRIES NO TIMESTAMP AND NO BARE SHA, for the correctness reason
# `step-stalled-units.sh`'s header records: the root calls a step changed when its summary
# differs from the same step's an hour ago, so the summary names the DRILLS, which is what
# genuinely distinguishes one hour's answer from the last.
#
# Usage: step-drill-health.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"

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

emit() {
    printf '{"step": "drill-health", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

reader="${DRIVE_SCRIPTS}/read-drill-verdicts.sh"
[ -f "$reader" ] || emit degraded no_reader "read-drill-verdicts.sh is not present beside this skill"

tip=$( ( cd "$ROOT" && git rev-parse --verify "${WORKAHOLIC_BASE_REF:-origin/main}^{commit}" ) 2>/dev/null || true )
[ -n "$tip" ] || emit degraded no_base_ref "the base ref could not be resolved in this checkout"

out=$( ( cd "$ROOT" && sh "$reader" "$tip" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded drill_run_unreadable "the drill verdict reader produced no output"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded drill_run_unreadable "the drill verdict reader produced output this step could not parse"

state=$(printf '%s' "$out" | jq -r '.state // ""')
reason=$(printf '%s' "$out" | jq -r '.reason // ""')

case "$state" in
    unavailable)
        emit ok "no_workflow" "this repository runs no drill workflow, so there is no drill verdict to read"
        ;;
    no_failing_drill)
        emit ok "" "no drill is reported failing on the base"
        ;;
    unreadable)
        emit degraded "drill_run_unreadable:${reason}" \
            "the base's drill run could not be read (${reason}); a failing drill is indistinguishable from a passing one this tick"
        ;;
    failing) ;;
    *)
        emit degraded drill_run_unreadable "the drill verdict reader reported no state this step recognises"
        ;;
esac

count=$(printf '%s' "$out" | jq '.failing | length' 2>/dev/null || printf 0)
names=$(printf '%s' "$out" | jq -r '[.failing[].drill] | join(", ")' 2>/dev/null || printf '')
[ -n "$names" ] || names="drill names unavailable"

# THE ADDRESSEE IS THE MISSION'S ASSIGNEE, RESOLVED THROUGH THE ONE MAPPING READER — and an
# address the mapping does not name leaves the question addressed to nobody rather than
# stamping one nobody verified (`undrivable-units`' finding, not this step's to guess at). A
# drill the register could not attribute to a mission has no assignee to look up, and says so
# in the question rather than being dropped.
rows=""
i=0
while [ "$i" -lt "$count" ]; do
    drill=$(printf '%s' "$out" | jq -r ".failing[$i].drill")
    mission=$(printf '%s' "$out" | jq -r ".failing[$i].mission // \"\"")
    resolved=$(printf '%s' "$out" | jq -r ".failing[$i].mission_resolved // false")
    owner="unknown"
    if [ "$resolved" = "true" ] && [ -n "$mission" ]; then
        for area in active archive; do
            m="${ROOT}/.workaholic/missions/${area}/${mission}/mission.md"
            [ -f "$m" ] || continue
            who=$(sed -n 's/^assignees: *\[\(.*\)\].*/\1/p' "$m" | tr ',' '\n' \
                | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)
            [ -n "$who" ] || continue
            if [ -f "${GATHER_SCRIPTS}/identity.sh" ]; then
                ident=$( sh "${GATHER_SCRIPTS}/identity.sh" "$who" 2>/dev/null || true )
                if [ "$(printf '%s' "$ident" | jq -r '.resolved // false' 2>/dev/null || printf false)" = "true" ]; then
                    owner=$(printf '%s' "$ident" | jq -r '.canonical // ""' 2>/dev/null || printf '')
                    [ -n "$owner" ] || owner="unknown"
                fi
            fi
            break
        done
    fi
    row=$(jq -cn --arg d "$drill" --arg m "$mission" --arg o "$owner" --arg r "$resolved" \
        '{drill: $d,
          mission: (if $m == "" then "mission_unresolved" else $m end),
          mission_resolved: ($r == "true"),
          owner: $o,
          key: ("drill-failing:" + $d)}' 2>/dev/null || printf '')
    [ -n "$row" ] || row="{\"drill\": \"${drill}\", \"mission\": \"mission_unresolved\", \"mission_resolved\": false, \"owner\": \"unknown\", \"key\": \"drill-failing:${drill}\"}"
    if [ -z "$rows" ]; then rows="$row"; else rows="${rows}, ${row}"; fi
    i=$((i + 1))
done

summary="${count} drill(s) failing on the base: ${names}"

# THE ROOT LINE — supplied only when something is failing, so a green hour renders nothing at
# all. Every root line links its item, and the base URL is derived from the LOCAL remote (no
# network call, `step-direction-health.sh`'s precedent); an absent remote degrades to the bare
# drill names rather than to a broken link.
remote=$( ( cd "$ROOT" && git config --get remote.origin.url ) 2>/dev/null || true )
case "$remote" in
    git@*:*) repo_base="https://github.com/$(printf '%s' "$remote" | sed 's/^git@[^:]*://; s/\.git$//')" ;;
    https://*) repo_base=$(printf '%s' "$remote" | sed 's/\.git$//') ;;
    *) repo_base="" ;;
esac
if [ -n "$repo_base" ]; then
    event="${count} proof(s) the loop already made stopped holding: <${repo_base}/commit/${tip}|${names}>"
else
    event="${count} proof(s) the loop already made stopped holding: ${names}"
fi

needs=$(printf '[%s]' "$rows" | jq -c '{action: "tell_the_shipping_mission_s_assignee_a_drill_is_failing",
    bound: "one question per failing drill, addressed to `owner` (nobody when it is `unknown`), keyed on `key` so it is asked once however many ticks see the same drill; the tick asks and never re-runs a leg, reverts, merges or touches a claim",
    compose: "name the drill, that it is failing on the base, and the mission that shipped it -- so whoever reads it can redirect when the drill has outlived its author. Where `mission_resolved` is false say plainly that the register could not attribute the drill, and do not guess a mission. This is a reading of a check run, not a verdict: a re-run may clear it.",
    drills: .}' 2>/dev/null || echo '{}')

emit ok "" "$summary" "$needs" "$event"
