#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
[ "${1:-}" = --request ] || runtime_usage "usage: dispatch.sh --request FILE"; REQUEST=${2:-}
runtime_require_json_file "$REQUEST"
jq -e '.protocol=="workaholic.runtime/v1" and .operation=="dispatch" and (.request_id|type=="string" and length>0) and (.repo_root|type=="string" and length>0) and (.instance_id|type=="string" and length>0) and (.input.role|type=="string" and length>0) and ((.input.unit//null)==null or (.input.unit|type=="string")) and (.input.adapter=="codex" or .input.adapter=="claude" or .input.adapter=="native") and (.input.prompt|type=="string" and length>0) and ((.input.dry_run//false)|type=="boolean")' "$REQUEST" >/dev/null 2>&1 || runtime_usage "invalid dispatch request"
id=$(jq -r .request_id "$REQUEST"); root=$(jq -r .repo_root "$REQUEST"); instance=$(jq -r .instance_id "$REQUEST"); role=$(jq -r .input.role "$REQUEST"); unit=$(jq -r '.input.unit // empty' "$REQUEST"); adapter=$(jq -r .input.adapter "$REQUEST"); dry=$(jq -r '.input.dry_run // false' "$REQUEST")
case "$id" in ''|*[!A-Za-z0-9._-]*) runtime_usage "request_id must be path safe";; esac
case "$instance" in ''|*[!A-Za-z0-9._-]*) runtime_usage "instance_id must be path safe";; esac
case "$role" in ''|*[!A-Za-z0-9._-]*) runtime_usage "role must be path safe";; esac
case "$unit" in *[!A-Za-z0-9._-]*) runtime_usage "unit must be path safe";; esac
receipt=$(jq -cn --arg id "$id" --arg role "$role" --arg unit "$unit" '{request_id:$id,role:$role,unit:(if $unit=="" then null else $unit end),reserved:false,child_id:null,executed:false,result:null}')
if [ "$dry" = true ]; then runtime_json_result ok "" "$id" "$(jq -cn --arg adapter "$adapter" --argjson receipt "$receipt" '{planned:true,adapter:$adapter,receipt:$receipt}')"; exit 0; fi
git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || runtime_usage "repo_root is not a git repository"
common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir); lock="${common}/workaholic/runtime/v1/locks/dispatch-${role}-${unit:-none}.lock"
mkdir -p "$(dirname -- "$lock")"
mkdir "$lock" 2>/dev/null || { runtime_json_result deferred already_running "$id" "$(jq -cn --arg role "$role" --arg unit "$unit" '{role:$role,unit:(if $unit=="" then null else $unit end)}')"; exit 0; }
trap 'rmdir "$lock" 2>/dev/null || true' EXIT HUP INT TERM
state="${SCRIPT_DIR}/state.sh"; now=${WORKAHOLIC_NOW:-$(date -Iseconds)}; instance_nonce=$(printf '%s' "$instance" | sha256sum | cut -c1-24); owner=$(jq -cn --arg i "$instance" --arg n "$instance_nonce" '{instance_id:$i,nonce:$n,harness_receipt:("instance:"+$i)}')
meta=$(cd "$root" && sh "$state" read --scope instance --id "$instance")
if [ "$(printf '%s' "$meta" | jq -r .data.found)" != true ]; then
  input=$(mktemp); jq -cn --arg now "$now" --argjson owner "$owner" '{updated_at:$now,owner:$owner,data:{lease_status:"acquired"}}' >"$input"
  meta=$(cd "$root" && sh "$state" create --scope instance --id "$instance" --input "$input"); rm -f "$input"
fi
[ "$(printf '%s' "$meta" | jq -r .status)" = ok ] || { runtime_json_result deferred instance_unavailable "$id" '{}'; exit 0; }
record=$(printf '%s' "$meta" | jq -c '.data.record'); generation=$(printf '%s' "$record" | jq -r .generation); actual_owner=$(printf '%s' "$record" | jq -c .owner)
[ "$actual_owner" = "$owner" ] || { runtime_json_result deferred owner_mismatch "$id" '{}'; exit 0; }
receipt=$(printf '%s' "$receipt" | jq -c '.reserved=true')
input=$(mktemp); jq -cn --arg now "$now" --argjson owner "$owner" --argjson generation "$generation" --argjson data "$receipt" '{updated_at:$now,owner:$owner,generation:$generation,data:$data}' >"$input"
reserved=$(cd "$root" && sh "$state" create --scope instance --id "$instance" --record "worker/$id" --input "$input"); rm -f "$input"
if [ "$(printf '%s' "$reserved" | jq -r .status)" != ok ]; then
  existing=$(cd "$root" && sh "$state" read --scope instance --id "$instance" --record "worker/$id")
  runtime_json_result deferred already_reserved "$id" "$(printf '%s' "$existing" | jq -c '{receipt:(.data.record.data//null)}')"; exit 0
fi
if [ "$adapter" = native ]; then
  runtime_json_result needs_parent native_spawn "$id" "$(jq -cn --argjson receipt "$receipt" '{receipt:$receipt}')"; exit 0
fi
worker_request=$(mktemp); jq -c '.operation="run_worker"|.input={prompt:.input.prompt,output_schema:(.input.output_schema//null)}' "$REQUEST" >"$worker_request"
result=$(sh "${SCRIPT_DIR}/adapters/${adapter}.sh" --request "$worker_request"); rm -f "$worker_request"
revision=$(printf '%s' "$reserved" | jq -r .data.record.revision)
final=$(printf '%s' "$receipt" | jq -c --argjson result "$result" '.executed=($result.status=="ok" and $result.data.result.executed==true)|.result=($result.data.result//null)')
input=$(mktemp); jq -cn --arg now "$now" --argjson owner "$owner" --argjson generation "$generation" --argjson data "$final" '{updated_at:$now,owner:$owner,generation:$generation,data:$data}' >"$input"
(cd "$root" && sh "$state" update --scope instance --id "$instance" --record "worker/$id" --expected-revision "$revision" --input "$input") >/dev/null; rm -f "$input"
runtime_json_result ok "" "$id" "$(jq -cn --argjson receipt "$final" --argjson adapter_result "$result" '{receipt:$receipt,adapter_result:$adapter_result}')"
