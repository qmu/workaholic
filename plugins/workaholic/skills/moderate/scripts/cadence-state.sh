#!/bin/sh -eu
# Is each declared cadence still being produced? — the one reader of a declared cadence.
#
# WHY IT EXISTS (2026-08-31, mission `notice-a-periodic-artifact-that-stopped-being-produced`).
# Every one of the tick's steps is driven by an object that EXISTS — an open pull request, a
# commit, a ticket, a record — so a producer that dies produces nothing and no step has
# anything to find. Measured: a daily record stopped for four days while hourly ticks ran
# throughout, and none of them reported it. The tick watches presence and cannot watch
# absence; this is the reading that watches absence.
#
# WHERE THE DECLARATION LIVES, AND WHAT IT SAYS: `workaholic:moderate`, *Where a cadence is
# declared, and what it says* — the one home, with the two rejected homes and their costs.
# It is NOT restated here. In one line: `WORKAHOLIC_CADENCES` carries `;`-separated entries of
# `<name>|<pattern>|<period>`, and an absent or empty variable means nothing is declared.
#
# ABSENT MEANS NOTHING IS DECLARED, AND THAT IS A REAL ANSWER. A repository declaring no
# cadence reads `count: 0` with a named `empty_reason` and exit 0 — the `no_log_source` split
# `step-workload-logs.sh` already draws between *this environment cannot see it* and *nobody
# asked for it*. It is never a degradation and never a finding.
#
# IT READS GIT, NOT MTIME, AND THAT IS A MEASUREMENT RATHER THAN A PREFERENCE. The obvious
# reading is the newest matching file's modification time, and it is USELESS in the
# environment this runs in: a routine's container is a fresh clone, and git stamps every
# checked-out file with the checkout's own time. Measured on this repository, 2026-08-31,
# inside a routine container: 1843 files carried the image's bake date and 481 the freshen's,
# and `.workaholic/moderations/2026-08-26.md` — five days old, the very artifact whose lapse
# measured this mission — showed an mtime of that morning. An mtime reading answers `current`
# for every cadence, always, in exactly the place it has to work. So the age is the newest
# COMMIT that touched the pattern, which survives a clone and is besides that the honest
# reading of *is it still being produced*: production here means committing.
#
# THE CAVEAT INVERTS, AND IS STATED RATHER THAN ASSUMED. Under an mtime read a file restored
# from history looks current though nothing produced it; under this read a restore is a new
# commit and therefore counts as production — which is correct for a tree whose producers
# commit, and wrong for a producer that writes outside git. A cadence whose artifacts never
# enter git cannot be measured here and must not be declared: it would read `unreadable`
# forever, which is the honest answer and not a lapse.
#
# A READ IT COULD NOT MAKE IS NEVER A LAPSE. That is the one way this reading can do harm: a
# wrong `lapsed` sends a person after a routine that is working, while a wrong `current` only
# delays a finding by an hour. So an unresolvable pattern, a malformed entry and a pattern
# with no commit in reachable history all answer `unreadable` with a NAMED reason and a NULL
# age — never a zero, which would read as *produced this second*, and never `lapsed`.
#
# `readable` IS ABSENT ON A COMPLETED READ, the convention `merge_policy` (absent means
# review) and a ticket's `status:` (absent means queued) already use — so every completed
# reading is byte-identical for a consumer not taught the term, and every test is
# `readable == false`, never `readable // true`.
#
# IT IS A PURE READ. No write, no stage, no network, no `gh`, no `plan-units.sh`. Exit 0 on
# every path, including a refusal.
#
# Usage: cadence-state.sh [--root <repo-root>]
# Env:   WORKAHOLIC_CADENCES — `<name>|<pattern>|<period>` entries, `;`-separated
# Output: one JSON line
#   {"count": <n>, "cadences": [ ... ]}                                  a completed read
#   {"count": 0, "cadences": [], "empty_reason": "no_cadence_declared"}  nothing declared
#   {"count": null, "cadences": [], "readable": false, "reason": "<why>"} could not read
#
# Each cadence:
#   {"name","pattern","period","period_hours","state","age_hours","last_produced","reason"}
#   state: "current" | "lapsed" | "unreadable"
#   age_hours / last_produced are null on "unreadable"

set -eu

ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

DECL="${WORKAHOLIC_CADENCES:-}"

if [ -z "$DECL" ]; then
    printf '{"count": 0, "cadences": [], "empty_reason": "no_cadence_declared"}\n'
    exit 0
fi

if ! ( cd "$ROOT" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1 ); then
    printf '{"count": null, "cadences": [], "readable": false, "reason": "no_git_history"}\n'
    exit 0
fi

NOW=$(date -u +%s)

entries=''
sep=''
count=0

# `;` separates entries and `|` separates an entry's three fields. Neither character occurs in
# a name, a path glob or a period, which is what makes the split unambiguous without a parser.
old_ifs=$IFS
IFS=';'
for raw in $DECL; do
    IFS=$old_ifs
    # Trim surrounding whitespace so a declaration may be written with spaces after the `;`.
    entry=$(printf '%s' "$raw" | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
    [ -n "$entry" ] || { IFS=';'; continue; }
    count=$((count + 1))

    name=$(printf '%s' "$entry" | cut -d'|' -f1)
    pattern=$(printf '%s' "$entry" | cut -d'|' -f2)
    period=$(printf '%s' "$entry" | cut -d'|' -f3)
    extra=$(printf '%s' "$entry" | cut -d'|' -f4)

    add() {
        # $1 name, $2 pattern, $3 period, $4 period_hours, $5 state, $6 age_hours,
        # $7 last_produced (ISO or empty), $8 reason
        _lp='null'
        [ -z "${7:-}" ] || _lp="\"$(json_escape "$7")\""
        entries="${entries}${sep}{\"name\": \"$(json_escape "$1")\", \"pattern\": \"$(json_escape "$2")\", \"period\": \"$(json_escape "$3")\", \"period_hours\": $4, \"state\": \"$5\", \"age_hours\": $6, \"last_produced\": ${_lp}, \"reason\": \"$(json_escape "${8:-}")\"}"
        sep=', '
    }

    if [ -z "$name" ] || [ -z "$pattern" ] || [ -z "$period" ] || [ -n "$extra" ]; then
        add "${name:-$entry}" "$pattern" "$period" null unreadable null '' malformed_entry
        IFS=';'
        continue
    fi

    # The name is the question's key, so it is held to a charset a key can carry.
    case "$name" in
        *[!A-Za-z0-9._-]*) add "$name" "$pattern" "$period" null unreadable null '' bad_name; IFS=';'; continue ;;
    esac

    number=$(printf '%s' "$period" | sed 's/[dh]$//')
    case "$period" in
        *d) case "$number" in ''|*[!0-9]*) period_hours='' ;; *) period_hours=$((number * 24)) ;; esac ;;
        *h) case "$number" in ''|*[!0-9]*) period_hours='' ;; *) period_hours=$number ;; esac ;;
        *)  period_hours='' ;;
    esac
    if [ -z "$period_hours" ] || [ "$period_hours" -le 0 ] 2>/dev/null; then
        add "$name" "$pattern" "$period" null unreadable null '' bad_period
        IFS=';'
        continue
    fi

    tracked=$( ( cd "$ROOT" && git ls-files -- "$pattern" 2>/dev/null | head -1 ) || true )
    if [ -z "$tracked" ]; then
        add "$name" "$pattern" "$period" "$period_hours" unreadable null '' no_matching_artifact
        IFS=';'
        continue
    fi

    newest=$( ( cd "$ROOT" && git log -1 --format='%ct %cI' -- "$pattern" 2>/dev/null ) || true )
    if [ -z "$newest" ]; then
        add "$name" "$pattern" "$period" "$period_hours" unreadable null '' no_commit_in_history
        IFS=';'
        continue
    fi

    ct=$(printf '%s' "$newest" | cut -d' ' -f1)
    iso=$(printf '%s' "$newest" | cut -d' ' -f2)
    case "$ct" in ''|*[!0-9]*)
        add "$name" "$pattern" "$period" "$period_hours" unreadable null '' unreadable_commit_time
        IFS=';'
        continue ;;
    esac

    age_hours=$(( (NOW - ct) / 3600 ))
    [ "$age_hours" -ge 0 ] || age_hours=0
    if [ "$age_hours" -gt "$period_hours" ]; then
        add "$name" "$pattern" "$period" "$period_hours" lapsed "$age_hours" "$iso" ''
    else
        add "$name" "$pattern" "$period" "$period_hours" current "$age_hours" "$iso" ''
    fi
    IFS=';'
done
IFS=$old_ifs

if [ "$count" -eq 0 ]; then
    printf '{"count": 0, "cadences": [], "empty_reason": "no_cadence_declared"}\n'
    exit 0
fi

printf '{"count": %s, "cadences": [%s]}\n' "$count" "$entries"
