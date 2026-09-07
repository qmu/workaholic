#!/bin/sh -eu

. "$(dirname -- "$0")/../lib/result.sh"
transport_parse_request_arg "$@"

route=$(jq -c --arg op "$TRANSPORT_OPERATION" '.input.binding.routes[]? | select(.transport=="qfs" and .described==true and (.operations|index($op)))' "$TRANSPORT_REQUEST_FILE" | head -1)
[ -n "$route" ] || { transport_result deferred qfs_operation_unavailable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
QFS_BIN=${WORKAHOLIC_QFS_BIN:-qfs}
command -v "$QFS_BIN" >/dev/null 2>&1 || { transport_result deferred qfs_unavailable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }

mount=$(printf '%s' "$route" | jq -r '.mount // empty')
[ -n "$mount" ] || { transport_result error qfs_binding_invalid "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
workspace=$(jq -r '.input.binding.workspace' "$TRANSPORT_REQUEST_FILE")
channel=$(jq -r '.input.binding.channel_id // .input.binding.channel' "$TRANSPORT_REQUEST_FILE")
case "$mount" in /slack/*) base="${mount%/}/${channel}" ;; *) transport_result error qfs_binding_invalid "$TRANSPORT_REQUEST_ID" '{}'; exit 0;; esac

case "$TRANSPORT_OPERATION" in
  read_channel_delta)
    cursor=$(jq -r '.input.cursor // empty' "$TRANSPORT_REQUEST_FILE")
    query="${base}/messages |> select id, ts, thread_ts, sender_id, text, edited_at |> limit 100"
    [ -z "$cursor" ] || query="${query} |> after ${cursor}"
    ;;
  read_thread)
    thread=$(jq -r '.input.thread_ts // empty' "$TRANSPORT_REQUEST_FILE"); [ -n "$thread" ] || transport_usage "read_thread requires thread_ts"
    query="${base}/threads/${thread}/messages |> select id, ts, thread_ts, sender_id, text, edited_at |> limit 100"
    ;;
  search_exact)
    exact=$(jq -r '.input.query // empty' "$TRANSPORT_REQUEST_FILE"); [ -n "$exact" ] || transport_usage "search_exact requires query"
    query="${base}/messages |> where text == $(printf '%s' "$exact" | jq -Rs .) |> select id, ts, thread_ts, sender_id, text |> limit 20"
    ;;
  post_root|post_reply|add_reaction|reconcile_send)
    # Writes and reconciliation use a request document so the QFS adapter owns
    # provider quoting in one place. `preview` is required before `commit`.
    query="CALL ${base}/${TRANSPORT_OPERATION}($(jq -c . "$TRANSPORT_REQUEST_FILE"))"
    ;;
  *) transport_result deferred qfs_operation_unavailable "$TRANSPORT_REQUEST_ID" '{}'; exit 0 ;;
esac

if case "$TRANSPORT_OPERATION" in post_root|post_reply|add_reaction) true;; *) false;; esac; then
    preview=$($QFS_BIN run "$query" --json --preview 2>&1) || { transport_result deferred qfs_preview_failed "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    printf '%s' "$preview" | jq -e '(.ok // true) != false' >/dev/null 2>&1 || { transport_result deferred qfs_preview_refused "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    raw=$($QFS_BIN run "$query" --json --commit 2>&1) || {
      case "$?" in 124) transport_result deferred accepted_send_timeout "$TRANSPORT_REQUEST_ID" '{"accepted":true}';; *) transport_result deferred qfs_connector_failure "$TRANSPORT_REQUEST_ID" '{}';; esac
      exit 0
    }
else
    raw=$($QFS_BIN run "$query" --json 2>&1) || { transport_result deferred qfs_connector_failure "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
fi
data=$(printf '%s' "$raw" | jq -c --arg workspace "$workspace" --arg channel "$channel" --arg op "$TRANSPORT_OPERATION" '
  if ($op|startswith("read_")) or $op=="search_exact" then
    {workspace:$workspace,channel:$channel,messages:(.messages // .rows // []),next_cursor:(.next_cursor//null),has_more:(.has_more//false),observed_at:(.observed_at//null)}
  else
    {workspace:$workspace,channel:$channel,ts:(.ts//.message.ts//null),thread_ts:(.thread_ts//.message.thread_ts//null),sender_id:(.sender_id//null),confirmed_by:(.confirmed_by//"qfs_response"),delivered:(.ok//true)}
  end' 2>/dev/null) || { transport_result error qfs_response_unparseable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
transport_result ok "" "$TRANSPORT_REQUEST_ID" "$data"
