#!/bin/sh -eu
# Read one provider-side Slack delta through a live QFS description and persist
# the returned messages before exposing observation evidence to the planner.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "${1:-}" = --root ] && [ -n "${2:-}" ] || runtime_usage "usage: observe-channel.sh --root REPO [--now ISO]"
ROOT=$2; shift 2; NOW=""
while [ $# -gt 0 ]; do case "$1" in --now) NOW=${2:-}; shift 2;; *) runtime_usage "invalid observe-channel argument";; esac; done
[ -n "$NOW" ] || NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
CHANNEL=${WORKAHOLIC_INBOUND_SLACK_CHANNEL:-$(basename "$ROOT")}; WORKSPACE=${WORKAHOLIC_SLACK_WORKSPACE:-qmu}
empty() { runtime_json_result ok "$1" observe-channel "$(jq -cn --arg reason "$1" '{observation_proved:false,new_input_ids:[],known_thread_changes:[],has_more:null,unreadable:[$reason]}')"; }
command -v qfs >/dev/null 2>&1 || { empty qfs_unavailable; exit 0; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
described=$(qfs describe /slack --json 2>/dev/null || printf '')
printf '%s' "$described" | jq -e . >/dev/null 2>&1 || { empty qfs_describe_unavailable; exit 0; }
BOT=${WORKAHOLIC_SLACK_BOT_USER_ID:-}
observations=$(printf '%s' "$described" | jq -c --arg workspace "$WORKSPACE" --arg channel "$CHANNEL" '[((.mounts // .connections // .data // .items // [])[]) | {transport:"qfs",available:true,described:true,mount:(.mount // .path // null),account:(.account // .name // null),workspace:(.workspace // .workspace_name // .name // null),channel:$channel,channel_id:(.channel_id//null),sender_id:(.sender_id // .bot_user_id // .user_id // null),operations:(.operations // .read_map // ["read_channel_delta"])} | select(.mount!=null) | select($workspace=="" or .workspace==$workspace)]')
jq -cn --arg root "$ROOT" --arg workspace "$WORKSPACE" --arg channel "$CHANNEL" --arg sender "$BOT" --argjson observations "$observations" '{protocol:"workaholic.transport/v1",request_id:"loop-observe-resolve",operation:"discover",repo_root:$root,instance_id:"loop-observer",input:{target:({workspace:$workspace,channel:$channel} + (if $sender=="" then {} else {sender_id:$sender} end)),observations:$observations}}' >"$tmp/resolve.json"
resolved=$("$SCRIPT_DIR/resolve-target.sh" --request "$tmp/resolve.json")
[ "$(printf '%s' "$resolved" | jq -r .status)" = ok ] || { empty "$(printf '%s' "$resolved" | jq -r .reason)"; exit 0; }
binding=$(printf '%s' "$resolved" | jq -c .data.binding); binding_id=$(printf '%s' "$resolved" | jq -r .data.binding_id)
STATE="$SCRIPT_DIR/../../runtime/scripts/state.sh"; call() { (cd "$ROOT" && "$STATE" "$@"); }
meta=$(call read --scope binding --id "$binding_id")
if [ "$(printf '%s' "$meta" | jq -r .data.found)" != true ]; then
  jq -cn --arg now "$NOW" --argjson target "$binding" '{updated_at:$now,owner:null,data:{lease_status:"released",target:$target,cursor:null}}' >"$tmp/meta.json"
  call create --scope binding --id "$binding_id" --input "$tmp/meta.json" >/dev/null
  meta=$(call read --scope binding --id "$binding_id")
fi
cursor=$(printf '%s' "$meta" | jq -c '.data.record.data.cursor // null')
jq -cn --arg root "$ROOT" --arg bid "$binding_id" --argjson binding "$binding" --argjson cursor "$cursor" '{protocol:"workaholic.transport/v1",request_id:"loop-observe-read",operation:"read_channel_delta",repo_root:$root,instance_id:"loop-observer",binding_id:$bid,input:{binding:$binding,cursor:$cursor,overlap_seconds:300}}' >"$tmp/read.json"
read_result=$("$SCRIPT_DIR/perform.sh" --request "$tmp/read.json")
[ "$(printf '%s' "$read_result" | jq -r .status)" = ok ] || { empty "$(printf '%s' "$read_result" | jq -r .reason)"; exit 0; }
next=$(printf '%s' "$read_result" | jq -c --argjson old "$cursor" '.data.next_cursor // ([.data.messages[]?.ts] | max) // $old')
jq -cn --arg root "$ROOT" --arg bid "$binding_id" --arg now "$NOW" --argjson messages "$(printf '%s' "$read_result" | jq -c .data.messages)" --argjson next "$next" '{repo_root:$root,binding_id:$bid,now:$now,messages:$messages,next_cursor:$next}' >"$tmp/capture.json"
captured=$("$SCRIPT_DIR/capture-inbox.sh" --request "$tmp/capture.json")
[ "$(printf '%s' "$captured" | jq -r .status)" = ok ] || { empty "$(printf '%s' "$captured" | jq -r .reason)"; exit 0; }
new_ids=$(printf '%s' "$captured" | jq -c '.data.new_input_ids // []')
data=$(printf '%s' "$read_result" | jq -c --arg bot "$BOT" --argjson new "$new_ids" '
  [.data.messages[]? | . as $m | (.id // .ts) as $id | select($id != null and ($new|index($id))) |
    select($bot=="" or (($m.sender_id // $m.author_id // $m.user // $m.user_id // "") != $bot))] as $fresh |
  {observation_proved:true,
   new_input_ids:[$fresh[]|(.id // .ts)]|unique,
   known_thread_changes:[$fresh[]|select((.thread_ts//"")!="")|{id:(.id//.ts),thread_ts,ts:(.ts//.id),sender_id:(.sender_id//null)}]|unique_by(.id),
   mentions:[$fresh[]|select($bot!="" and ((.text//"")|contains("<@"+$bot+">")))|{id:(.id//.ts),thread_ts:(.thread_ts//null),ts:(.ts//.id)}]|unique_by(.id),
   coverage:{top_level:{status:"covered",source:"read_channel_delta"},threads:{status:"covered_when_returned_by_channel_delta",source:"thread_ts"},mentions:(if $bot=="" then {status:"unreadable",reason:"sender_identity_unverified"} else {status:"covered_in_channel_delta",source:"message_text"} end)},
   calls:{describe:1,read_channel_delta:1,capture:1,total:3},
   has_more:(.data.has_more//false),unreadable:(if $bot=="" then ["sender_identity_unverified"] else [] end),next_cursor:.data.next_cursor}')
runtime_json_result ok "" observe-channel "$data"
