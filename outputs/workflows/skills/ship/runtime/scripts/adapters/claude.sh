#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../lib/result.sh"
[ "${1:-}" = --request ] || runtime_usage "usage: claude.sh --request FILE"; REQUEST=${2:-}
runtime_require_json_file "$REQUEST"
jq -e '.protocol=="workaholic.runtime/v1" and .operation=="run_worker" and (.request_id|type=="string" and length>0) and (.repo_root|type=="string" and length>0) and (.input.prompt|type=="string" and length>0) and ((.input.output_schema//null)==null or (.input.output_schema|type=="string"))' "$REQUEST" >/dev/null 2>&1 || runtime_usage "invalid Claude adapter request"
id=$(jq -r .request_id "$REQUEST"); root=$(jq -r .repo_root "$REQUEST"); prompt=$(jq -r .input.prompt "$REQUEST"); schema=$(jq -r '.input.output_schema // empty' "$REQUEST")
command -v claude >/dev/null 2>&1 || { runtime_json_result error cli_unavailable "$id" '{}'; exit 0; }
out=$(mktemp); log=$(mktemp); trap 'rm -f "$out" "$log"' EXIT HUP INT TERM
set -- --print --output-format json
[ -z "$schema" ] || set -- "$@" --json-schema "$(cat "$schema")"
if (cd "$root" && claude "$@" "$prompt") >"$out" 2>"$log"; then code=0; else code=$?; fi
[ "$code" -eq 0 ] || { runtime_json_result error "cli_exit_${code}" "$id" "$(jq -cn --arg log "$(tail -c 2000 "$log")" '{diagnostic:$log}')"; exit 0; }
# Claude may wrap structured output in `structured_output`; normalize only that
# documented transport wrapper and preserve the four-field worker result itself.
normalized=$(jq -c '.structured_output // .' "$out" 2>/dev/null || printf '')
printf '%s' "$normalized" | jq -e 'type=="object" and (keys|sort==["executed","outcome","reason","report"]) and (.executed|type=="boolean") and (.outcome=="ok" or .outcome=="pending" or .outcome=="blocked" or .outcome=="failed") and (.reason|type=="string") and (.report|type=="string")' >/dev/null 2>&1 || { runtime_json_result error invalid_worker_result "$id" '{}'; exit 0; }
runtime_json_result ok "" "$id" "$(printf '%s' "$normalized" | jq -c '{result:.,cli:"claude"}')"
