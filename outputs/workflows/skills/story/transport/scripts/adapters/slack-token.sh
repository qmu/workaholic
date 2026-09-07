#!/bin/sh -eu

. "$(dirname -- "$0")/../lib/result.sh"
transport_parse_request_arg "$@"
case "$TRANSPORT_OPERATION" in post_root|post_reply|add_reaction) ;; *) transport_result deferred token_operation_unavailable "$TRANSPORT_REQUEST_ID" '{}'; exit 0;; esac
[ -n "${SLACK_BOT_TOKEN:-}" ] || { transport_result deferred no_token "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
channel=$(jq -r '.input.binding.channel_id // .input.binding.channel // empty' "$TRANSPORT_REQUEST_FILE")
[ -n "$channel" ] || transport_usage "token transport requires a channel"
sender_expected=$(jq -r '.input.expected_sender_id // .input.binding.sender_id // empty' "$TRANSPORT_REQUEST_FILE")

case "$TRANSPORT_OPERATION" in
  post_root|post_reply)
    text=$(jq -r '.input.text // empty' "$TRANSPORT_REQUEST_FILE"); [ -n "$text" ] || transport_usage "post requires text"
    if jq -e '.input.legacy_payload==true' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1; then
      payload=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1])); p={"channel":sys.argv[2],"text":d["input"]["text"]}
if d["input"].get("thread_ts"): p["thread_ts"]=d["input"]["thread_ts"]
print(json.dumps(p))' "$TRANSPORT_REQUEST_FILE" "$channel")
    else
      payload=$(jq -cn --arg channel "$channel" --arg text "$text" --arg rid "$TRANSPORT_REQUEST_ID" --arg thread "$(jq -r '.input.thread_ts // empty' "$TRANSPORT_REQUEST_FILE")" \
        '{channel:$channel,text:$text,client_msg_id:$rid} + (if $thread=="" then {} else {thread_ts:$thread} end)')
    fi
    endpoint=${WORKAHOLIC_SLACK_API_URL:-https://slack.com/api/chat.postMessage}
    ;;
  add_reaction)
    ts=$(jq -r '.input.timestamp // empty' "$TRANSPORT_REQUEST_FILE"); emoji=$(jq -r '.input.emoji // empty' "$TRANSPORT_REQUEST_FILE")
    [ -n "$ts" ] && [ -n "$emoji" ] || transport_usage "reaction requires timestamp and emoji"
    payload=$(jq -cn --arg channel "$channel" --arg timestamp "$ts" --arg name "$emoji" '{channel:$channel,timestamp:$timestamp,name:$name}')
    endpoint=${WORKAHOLIC_SLACK_REACTION_API_URL:-https://slack.com/api/reactions.add}
    ;;
esac
body=$(mktemp); trap 'rm -f "$body"' EXIT HUP INT TERM
code=$(curl -sS -o "$body" -w '%{http_code}' -X POST -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" -H 'Content-Type: application/json; charset=utf-8' --data "$payload" "$endpoint" 2>/dev/null) || {
  transport_result deferred provider_timeout "$TRANSPORT_REQUEST_ID" '{"accepted":null}'; exit 0;
}
[ "$code" = 200 ] || { transport_result deferred "http_${code}" "$TRANSPORT_REQUEST_ID" '{"accepted":false}'; exit 0; }
parsed=$(jq -c --arg expected "$sender_expected" '
  if .ok!=true then {ok:false,reason:("slack_"+(.error//"unknown"))}
  elif $expected!="" and (.message.user//.user//"")!=$expected then {ok:false,reason:"sender_mismatch",sender_id:(.message.user//.user//null)}
  else {ok:true,data:{workspace:(.team//null),channel:(.channel//null),ts:(.ts//.message.ts//null),thread_ts:(.message.thread_ts//null),sender_id:(.message.user//.user//null),confirmed_by:"provider_response",delivered:true}} end
' "$body" 2>/dev/null) || { transport_result error slack_unparseable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
if [ "$(printf '%s' "$parsed" | jq -r .ok)" != true ]; then transport_result deferred "$(printf '%s' "$parsed" | jq -r .reason)" "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$parsed" | jq 'del(.ok,.reason)')"; exit 0; fi
transport_result ok "" "$TRANSPORT_REQUEST_ID" "$(printf '%s' "$parsed" | jq -c .data)"
