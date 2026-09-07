#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../runtime/scripts/lib/result.sh"
REQUEST="" SNAPSHOT=""
while [ $# -gt 0 ]; do case "$1" in --request) REQUEST=${2:-}; shift 2;; --snapshot) SNAPSHOT=${2:-}; shift 2;; *) runtime_usage "invalid discover-input argument";; esac; done
runtime_require_json_file "$REQUEST"
normalized=$(sh "${SCRIPT_DIR}/normalize-input.sh" --request "$REQUEST")
[ "$(printf '%s' "$normalized" | jq -r .status)" = ok ] || { printf '%s\n' "$normalized"; exit 0; }
id=$(jq -r .request_id "$REQUEST"); root=$(jq -r .repo_root "$REQUEST")
if [ -n "$SNAPSHOT" ]; then
  runtime_require_json_file "$SNAPSHOT"; snapshot=$(cat "$SNAPSHOT")
else
  input=$(mktemp); trap 'rm -f "$input"' EXIT HUP INT TERM
  now=$(jq -r '.input.observed_at // empty' "$REQUEST"); [ -n "$now" ] || now=$(date -Iseconds)
  email=$(git -C "$root" config user.email 2>/dev/null || printf '')
  jq -cn --arg root "$root" --arg now "$now" --arg email "$email" --arg input_id "$id" '{repo_root:$root,now:$now,config:{},identity:{email:$email},communication:{new_input_ids:[$input_id],known_thread_changes:[],has_more:null,unreadable:[]}}' >"$input"
  observed=$(sh "${SCRIPT_DIR}/../../gather/scripts/read-snapshot.sh" --input "$input")
  [ "$(printf '%s' "$observed" | jq -r .status)" = ok ] || { runtime_json_result deferred discovery_unreadable "$id" "$(jq -cn --argjson observed "$observed" '{observation:$observed}')"; exit 0; }
  snapshot=$(printf '%s' "$observed" | jq -c .data)
fi
runtime_json_result ok "" "$id" "$(jq -cn --argjson normalized "$(printf '%s' "$normalized" | jq -c .data)" --argjson snapshot "$snapshot" '{normalized:$normalized,snapshot:$snapshot}')"
