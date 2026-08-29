#!/bin/sh -eu
# What did the base's own drill run say — per drill? The ONE composition of a commit's check
# state and the drill register, read by the `/moderate` tick's `drill-health` step and by the
# archive gate, so those two never derive the same fact twice.
#
# WHY IT EXISTS (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`).
# `Loop Drills` runs one matrix leg per hermetic drill, and a check run is named after its
# job — so the failing check's NAME is the drill's name, with no log to parse, no extra call
# and no permission beyond the read `read-base-checks.sh` already makes. This script is the
# place that fact is turned into a per-drill reading; every consumer composes it.
#
# IT DERIVES NO CHECK STATE OF ITS OWN. `read-base-checks.sh` is the single reader of a
# commit's check runs in this plugin and stays so: this composes it and does nothing else
# with the network.
#
# FOUR STATES, AND TWO OF THEM ARE ABOUT US:
#
#   failing           at least one failing check names a drill the register knows
#   no_failing_drill  the reading was made and named no drill — NOT a claim that every drill
#                     passed, only that none of them is reported failing at this commit
#   unreadable        `read-base-checks.sh` could not answer (its reason is carried verbatim)
#   unavailable       this repository ships no `Loop Drills` workflow, so there is nothing to
#                     read; a consuming repository with no drill set at all lands here
#
# A `--drill` call has one more: `no_drill`, for a name the register does not carry. That is
# a FACT (the mission it came from ships no drill), never a degradation, which is why it is
# reported `ok: true` and is not folded into `unavailable`.
#
# `no_failing_drill` IS DELIBERATELY NOT CALLED `green`. A pending leg is invisible behind a
# sibling check that already failed, and a check that never ran is not a check that passed —
# so the word says what was observed rather than what a reader would like it to mean.
#
# NOTHING MAY ACT ON WHAT THIS ANSWERS. Every value is a JUDGEMENT: a check run is designed
# to be re-runnable, so each reading can become false by looking again — the one property a
# proof must not have (`drive/reference/claims.md`, *Proofs and judgements*). Report it, ask
# about it; never revert, re-run, gate, hold or merge on it. The archive gate names it beside
# a close and the close is byte-identical either way.
#
# IT EXITS 0 IN EVERY CASE, INCLUDING EVERY DEGRADATION.
#
# Usage:
#   read-drill-verdicts.sh <commit>                # every failing drill
#   read-drill-verdicts.sh <commit> --drill <name> # one drill's reading
#
# Output: one JSON line
#   {"ok", "commit", "state", "reason", "failing": [{"drill","mission","mission_resolved"}]}
#   with --drill: {"ok", "commit", "drill", "verdict", "reason", "mission", "mission_resolved"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CHECKS="${SCRIPT_DIR}/read-base-checks.sh"
REGISTER="${SCRIPT_DIR}/drill-register.sh"

COMMIT="${1:-}"
shift 2>/dev/null || true
WANT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --drill) shift; WANT="${1:-}" ;;
        *) ;;
    esac
    shift 2>/dev/null || break
done

emit() {
    if [ -n "$WANT" ]; then
        _ok=true
        case "$1" in unreadable|unavailable) _ok=false ;; esac
        printf '{"ok": %s, "commit": "%s", "drill": "%s", "verdict": "%s", "reason": "%s", "mission": "%s", "mission_resolved": %s}\n' \
            "$_ok" "$COMMIT" "$WANT" "$1" "${2:-}" "${3:-}" "${4:-false}"
    else
        _ok=true
        case "$1" in unreadable|unavailable) _ok=false ;; esac
        printf '{"ok": %s, "commit": "%s", "state": "%s", "reason": "%s", "failing": %s}\n' \
            "$_ok" "$COMMIT" "$1" "${2:-}" "${3:-[]}"
    fi
    exit 0
}

[ -n "$COMMIT" ] || emit unreadable no_commit
[ -f "$CHECKS" ] || emit unreadable no_checks_reader
[ -f "$REGISTER" ] || emit unavailable no_register_reader

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
# NO WORKFLOW, NO READING. A repository that never adopted `Loop Drills` has no per-drill
# check to find, and reporting that as "nothing failing" would read exactly like a repository
# whose drills all passed.
if [ -n "$ROOT" ] && [ ! -f "${ROOT}/.github/workflows/loop-drills.yml" ]; then
    emit unavailable no_workflow
fi

reg=$(sh "$REGISTER" list 2>/dev/null || true)
case "$reg" in
    *'"ok": true'*) ;;
    *) emit unavailable no_register ;;
esac

# The register's own answer for the one drill a `--drill` call asks about. An unknown name is
# `no_drill`: the mission it was resolved from ships no drill, which is a fact rather than a
# degradation.
mission=""
mres="false"
if [ -n "$WANT" ]; then
    row=$(printf '%s' "$reg" | tr '{' '\n' | grep "\"drill\": \"${WANT}\"," || true)
    [ -n "$row" ] || emit no_drill unregistered
    mission=$(printf '%s' "$row" | sed -n 's/.*"mission": "\([a-z0-9-]*\)".*/\1/p')
    case "$row" in *'"mission_resolved": true'*) mres="true" ;; esac
fi

state=$(sh "$CHECKS" "$COMMIT" 2>/dev/null || true)
case "$state" in
    *'"state": "unanswerable"'*)
        why=$(printf '%s' "$state" | sed -n 's/.*"reason": "\([a-z_]*\)".*/\1/p' | head -n 1)
        emit unreadable "${why:-unanswerable}" "$mission" "$mres"
        ;;
    *'"state": "green"'*)
        if [ -n "$WANT" ]; then emit no_failing_drill "" "$mission" "$mres"; fi
        emit no_failing_drill "" "[]"
        ;;
    *'"state": "red"'*) ;;
    *) emit unreadable unparseable_check_read "$mission" "$mres" ;;
esac

# `red` — intersect the failing check names with the register. A failing check that is not a
# drill (the manifest job, the outputs freshness job) belongs to `base-health`'s question, not
# to this one.
# `read-base-checks.sh` builds `failing` with `jq -c`, which emits `"name":"x"` with no space
# after the colon, while its own printf-built fields carry one. The match tolerates both rather
# than assuming the shape of whichever half it happens to be reading.
names=$(printf '%s' "$state" | tr '{' '\n' | sed -n 's/.*"name":[ ]*"\([^"]*\)".*/\1/p')

if [ -n "$WANT" ]; then
    if printf '%s\n' "$names" | grep -qx -- "$WANT"; then
        emit failing check_failed "$mission" "$mres"
    fi
    emit no_failing_drill "" "$mission" "$mres"
fi

out=""
for n in $names; do
    row=$(printf '%s' "$reg" | tr '{' '\n' | grep "\"drill\": \"${n}\"," || true)
    [ -n "$row" ] || continue
    m=$(printf '%s' "$row" | sed -n 's/.*"mission": "\([a-z0-9-]*\)".*/\1/p')
    r=false
    case "$row" in *'"mission_resolved": true'*) r=true ;; esac
    entry="{\"drill\": \"${n}\", \"mission\": \"${m}\", \"mission_resolved\": ${r}}"
    if [ -z "$out" ]; then out="$entry"; else out="${out}, ${entry}"; fi
done

[ -n "$out" ] || emit no_failing_drill "" "[]"
emit failing "" "[${out}]"
