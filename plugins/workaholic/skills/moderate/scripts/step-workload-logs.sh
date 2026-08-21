#!/bin/sh -eu
# Step 3 — the workload logs of environments this session can actually read.
#
# IT READS THE RECORDS; IT RUNS NOTHING (decided 2026-08-17). A deployment record
# already carries executable prose, and `/ship` runs it **only on the developer's
# instruction** (§5-D). An hourly unattended tick that executed a repository-declared
# command would move that boundary quietly — arbitrary code out of a file, every
# hour, with nobody watching. So this step resolves *which* targets declare a
# readable log source and *whether* this environment carries what each needs, and
# hands them to the agent, which reads them with the tools the session actually has.
#
# "MISSING CREDENTIALS" IS A CHECKED CLAIM, NEVER A FORECAST (the failure
# contract's rule, applied here). A target is reported `no_credentials` only after
# the named environment variable was looked for and found absent, and the report
# names the variable. A target that declares no locator at all is `no_log_source` —
# a different fact, and the one a human fixes by writing the record.
#
# THE LOCATOR IS NON-SECRET BY CONSTRUCTION. `log_locator:` is an optional
# deployments frontmatter field alongside `url` / `endpoint` / `command`, and
# `log_credential_env:` names an environment VARIABLE, never its value — the same
# rule the whole area is under: credentials are supplied transiently, never
# committed.
#
# Usage: workload-logs.sh --tick <id> --root <repo-root>
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"targets":[...]}

set -eu

ROOT='.'

while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --tick) shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

fm_field() {
    # $1 file, $2 key -> the frontmatter value, or ""
    awk -v key="$2" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        substr($0, 1, length(key) + 1) == key ":" {
            val = substr($0, length(key) + 2)
            gsub(/^[ \t]+|[ \t]+$/, "", val)
            print val
            exit
        }
    ' "$1" 2>/dev/null || true
}

emit() {
    printf '{"step": "workload-logs", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "targets": [%s]}\n' \
        "$1" "$2" "$(json_escape "$3")" "$4" "$5"
    exit 0
}

DIR="$ROOT/.workaholic/deployments"
if [ ! -d "$DIR" ]; then
    emit skipped no_targets "no deployments/ records here — nothing declares a workload log" "" ""
fi

needs=''
targets=''
total=0
readable=0
no_source=0
no_creds=0

for f in "$DIR"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    [ "$name" != "index" ] || continue
    total=$((total + 1))

    locator=$(fm_field "$f" log_locator)
    cred_env=$(fm_field "$f" log_credential_env)

    if [ -z "$locator" ]; then
        no_source=$((no_source + 1))
        targets="${targets:+${targets}, }{\"target\": \"$(json_escape "$name")\", \"state\": \"no_log_source\"}"
        continue
    fi

    if [ -n "$cred_env" ]; then
        # Presence only — the value is never read, printed, or logged.
        if ! env | grep -q "^${cred_env}="; then
            no_creds=$((no_creds + 1))
            targets="${targets:+${targets}, }{\"target\": \"$(json_escape "$name")\", \"state\": \"no_credentials\", \"credential_env\": \"$(json_escape "$cred_env")\"}"
            continue
        fi
    fi

    readable=$((readable + 1))
    targets="${targets:+${targets}, }{\"target\": \"$(json_escape "$name")\", \"state\": \"readable\", \"locator\": \"$(json_escape "$locator")\"}"
    needs="${needs:+${needs}, }{\"surface\": \"workload-log\", \"action\": \"read_and_judge\", \"target\": \"$(json_escape "$name")\", \"locator\": \"$(json_escape "$locator")\", \"bound\": \"pointer and the failing signal only — never a log body, and never a credential\"}"
done

if [ "$total" -eq 0 ]; then
    emit skipped no_targets "no deployment records here — nothing declares a workload log" "" ""
fi

if [ "$readable" -eq 0 ]; then
    emit skipped no_log_source \
        "${total} target(s): ${no_source} declare no log_locator, ${no_creds} declare one this environment has no credential for" \
        "" "$targets"
fi

emit ok "" \
    "${total} target(s): ${readable} readable, ${no_source} without a log_locator, ${no_creds} without credentials here" \
    "$needs" "$targets"
