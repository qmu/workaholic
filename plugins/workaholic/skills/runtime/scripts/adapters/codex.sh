#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
[ "${1:-}" = --request ] || runtime_usage "usage: codex.sh --request FILE"; REQUEST=${2:-}
runtime_require_json_file "$REQUEST"
jq -e '.protocol=="workaholic.runtime/v1" and .operation=="run_worker" and (.request_id|type=="string" and length>0) and (.repo_root|type=="string" and length>0) and (.input.prompt|type=="string" and length>0) and ((.input.output_schema//null)==null or (.input.output_schema|type=="string"))' "$REQUEST" >/dev/null 2>&1 || runtime_usage "invalid Codex adapter request"
id=$(jq -r .request_id "$REQUEST"); root=$(jq -r .repo_root "$REQUEST"); prompt=$(jq -r .input.prompt "$REQUEST"); schema=$(jq -r '.input.output_schema // empty' "$REQUEST")
command -v codex >/dev/null 2>&1 || { runtime_json_result error cli_unavailable "$id" '{}'; exit 0; }
out=$(mktemp); log=$(mktemp); trap 'rm -f "$out" "$log"' EXIT HUP INT TERM
set -- exec -C "$root" --json --output-last-message "$out"
[ -z "$schema" ] || set -- "$@" --output-schema "$schema"
if codex "$@" "$prompt" >"$log" 2>&1; then code=0; else code=$?; fi
[ "$code" -eq 0 ] || { runtime_json_result error "cli_exit_${code}" "$id" "$(jq -cn --arg log "$(tail -c 2000 "$log")" '{diagnostic:$log}')"; exit 0; }
jq -e 'type=="object" and (keys|sort==["executed","outcome","reason","report"]) and (.executed|type=="boolean") and (.outcome=="ok" or .outcome=="pending" or .outcome=="blocked" or .outcome=="failed") and (.reason|type=="string") and (.report|type=="string")' "$out" >/dev/null 2>&1 || { runtime_json_result error invalid_worker_result "$id" '{}'; exit 0; }
runtime_json_result ok "" "$id" "$(jq -c '{result:.,cli:"codex"}' "$out")"
