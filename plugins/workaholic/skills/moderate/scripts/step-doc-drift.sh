#!/bin/sh -eu
# Step 7 — documentation against the current concept, starting from README.md.
#
# IT REUSES THE EXISTING CHECKERS rather than writing a third one:
# `story/scripts/doc-drift.sh` for structural drift (a skill, command or hook
# appeared or vanished without the documents that enumerate them being touched)
# and `story/scripts/area-freshness.sh` for the two hand-maintained areas (a
# record naming something this repository retired is not "possibly stale", it is
# wrong).
#
# THE WINDOW IS A GIT QUESTION, NOT A CLOCK ONE. `doc-drift.sh` compares
# `<base>..HEAD`, and on `main` the natural base is "where the documentation was
# last looked at" — the previous tick that ran this step. That tick id converts to
# an ISO timestamp by string surgery, and `git rev-list -1 --before=<iso>` turns it
# into a commit without any `date -d`/`date -v` arithmetic. With no earlier tick
# the base is the day's first commit, and with no commit before that boundary the
# step says `no_baseline` rather than comparing against nothing.
#
# IT FILES, IT NEVER FIXES (the ticket's rule, and `area-freshness.sh`'s own). A
# drift finding becomes a **ticket**, because fixing documentation is work and work
# has a queue. A machine that rewrote `README.md` hourly would be recording what
# happened rather than what should happen — and an hourly unattended write to a
# document on `main` is the class this project has already refused twice.
#
# Usage: step-doc-drift.sh --tick <id> --root <repo-root> [--base <ref>]
# Output: one JSON line {"step","status","reason","summary","needs_agent":[...],"base":"<ref>"}

# ONE OBJECT PER LINE, VIA awk. `tr '}' '}\n'` looks like it splits the JSON and
# does not: tr maps one character to one character, so the replacement's second
# character is dropped and the whole payload stays on one line — after which a
# greedy `sed 's/.*"number": //'` reads the LAST pull request's number for every
# match. Measured 2026-08-17: two open pull requests, one conflicted, reported as
# "#13 conflicted" when #12 was the conflicted one.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPORT="${SCRIPT_DIR}/../../story/scripts"
LOG_READ="${SCRIPT_DIR}/log-read.sh"
ROOT='.'
TICK=''
BASE=''

while [ $# -gt 0 ]; do
    case "$1" in
        --base) BASE="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-}"; shift 2 ;;
        --tick) TICK="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit() {
    printf '{"step": "doc-drift", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "base": "%s"}\n' \
        "$1" "$2" "$(json_escape "$3")" "$4" "$(json_escape "$BASE")"
    exit 0
}

git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || emit skipped no_repo "not a git checkout — nothing to compare documentation against" ""

if [ -z "$BASE" ]; then
    prev=''
    if [ -f "$LOG_READ" ] && [ -n "$TICK" ]; then
        prev=$(sh "$LOG_READ" --root "$ROOT" --step doc-drift 2>/dev/null |
               tr ',' '\n' | grep '"tick"' | sed 's/.*"tick": "//; s/".*//' |
               grep -v "^${TICK}$" | sort | tail -n 1 || true)
    fi
    if [ -n "$prev" ]; then
        since=$(printf '%s' "$prev" | sed 's/^\(....\)\(..\)\(..\)-\(..\)\(..\)\(..\)$/\1-\2-\3T\4:\5:\6Z/')
    else
        since=$(printf '%s' "$TICK" | sed 's/^\(....\)\(..\)\(..\)-.*$/\1-\2-\3T00:00:00Z/')
    fi
    BASE=$(git -C "$ROOT" rev-list -1 --before="$since" HEAD 2>/dev/null || true)
    [ -n "$BASE" ] || emit skipped no_baseline "no commit before ${since} — nothing to compare this tick's documentation against" ""
fi

drift=$(sh "${REPORT}/doc-drift.sh" "$BASE" 2>/dev/null || true)
[ -n "$drift" ] || emit degraded drift_unreadable "doc-drift.sh returned nothing — the structural check did not run" ""

# `candidates` is doc-drift.sh's own vocabulary: a structural change that landed
# without its index document being touched. It emits facts; the judgement of
# whether the document actually needs a line is the agent's, and the outcome is a
# ticket rather than an edit.
cands=$(printf '%s' "$drift" | awk '{ gsub(/{/, "\n{"); print }' | grep '"signal":' || true)
cand_count=$(printf '%s' "$cands" | awk 'NF { n++ } END { print n + 0 }')

fresh=$(sh "${REPORT}/area-freshness.sh" 2>/dev/null || true)
wrong=$(printf '%s' "$fresh" | awk '{ gsub(/{/, "\n{"); print }' | grep '"retired_terms": \["' || true)
wrong_count=$(printf '%s' "$wrong" | awk 'NF { n++ } END { print n + 0 }')

# DEDUP, or this step re-files the same ticket every hour. `terms/retired-terms.md`
# is the standing example: a glossary OF retired terms names retired terms by
# construction, so `area-freshness.sh` reports it truthfully and forever. A finding
# an earlier tick already filed is counted and dropped, keyed on the document or
# record path in the `doc-drift-filed` line the agent wrote.
already_filed() {
    [ -f "$LOG_READ" ] || return 1
    seen=$(sh "$LOG_READ" --root "$ROOT" --step doc-drift-filed --contains "$1" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
    [ -n "$seen" ] && [ "$seen" != "0" ]
}

needs=''
fresh_cands=0
dropped=0
if [ "$cand_count" -gt 0 ]; then
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        doc=$(printf '%s' "$line" | sed 's/.*"doc":"\?//; s/[",].*//')
        reason=$(printf '%s' "$line" | sed 's/.*"reason":"\?//; s/"[},].*//')
        if already_filed "$doc"; then
            dropped=$((dropped + 1))
            continue
        fi
        fresh_cands=$((fresh_cands + 1))
        needs="${needs:+${needs}, }{\"action\": \"file_ticket\", \"drift\": \"structural\", \"doc\": \"$(json_escape "$doc")\", \"reason\": \"$(json_escape "$reason")\", \"since\": \"$(json_escape "$BASE")\", \"bound\": \"file a ticket; never edit the document from the tick\"}"
    done <<EOF
$cands
EOF
fi

fresh_wrong=0
if [ "$wrong_count" -gt 0 ]; then
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        path=$(printf '%s' "$line" | sed 's/.*"path": "//; s/".*//')
        if already_filed "$path"; then
            dropped=$((dropped + 1))
            continue
        fi
        fresh_wrong=$((fresh_wrong + 1))
        needs="${needs:+${needs}, }{\"action\": \"file_ticket\", \"drift\": \"retired_terms\", \"record\": \"$(json_escape "$path")\", \"bound\": \"file a ticket; the two hand-maintained areas are written by a human\"}"
    done <<EOF
$wrong
EOF
fi

if [ -z "$needs" ]; then
    emit ok "" "no new documentation drift since ${BASE} (${dropped} finding(s) already filed by an earlier tick)" ""
fi

emit ok "" \
    "${fresh_cands} structural drift candidate(s) since ${BASE}, ${fresh_wrong} record(s) naming something retired, ${dropped} already filed — each to be filed as a ticket, never edited here" \
    "$needs"
