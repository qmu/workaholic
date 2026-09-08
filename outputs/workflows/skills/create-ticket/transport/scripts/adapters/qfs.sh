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
# QFS paths and `after` coordinates are syntax, not values. Keep every dynamic
# coordinate inside Slack's portable identifier/timestamp grammar so provider
# output cannot append a pipe-SQL operator on the next poll.
case "$mount" in /slack/*) ;; *) transport_result error qfs_binding_invalid "$TRANSPORT_REQUEST_ID" '{}'; exit 0;; esac
case "${mount#/slack/}" in ''|*[!A-Za-z0-9._/-]*|*..*|/*|*/|*//* ) transport_result error qfs_binding_invalid "$TRANSPORT_REQUEST_ID" '{}'; exit 0;; esac
case "$channel" in ''|*[!A-Za-z0-9._-]*) transport_usage "QFS channel coordinate is invalid";; esac
base="${mount%/}/${channel}"

case "$TRANSPORT_OPERATION" in
  read_channel_delta)
    cursor=$(jq -r '.input.cursor // empty' "$TRANSPORT_REQUEST_FILE")
    case "$cursor" in '') ;; *[!0-9.]*|*.*.*|.*|*.) transport_usage "QFS cursor is invalid";; *.*) ;; *) transport_usage "QFS cursor is invalid";; esac
    query="${base}/messages |> select id, ts, thread_ts, sender_id, text, edited_at |> limit 100"
    if [ -n "$cursor" ]; then
      overlap=$(jq -r '.input.overlap_seconds // 0' "$TRANSPORT_REQUEST_FILE")
      case "$overlap" in *[!0-9]*|'') transport_usage "QFS overlap_seconds must be a non-negative integer";; esac
      start=$(awk -v cursor="$cursor" -v overlap="$overlap" 'BEGIN { value=cursor-overlap; if (value<0) value=0; printf "%.6f", value }')
      query="${query} |> after ${start}"
    fi
    ;;
  list_thread_changes)
    # Slack channel history does not carry a reply under an older root, so a new reply is
    # invisible to `read_channel_delta` by construction. This asks the provider which THREADS
    # changed, by their own coordinates, inside the same bounded overlap window — never a scan
    # of every thread and never a full-channel read.
    cursor=$(jq -r '.input.cursor // empty' "$TRANSPORT_REQUEST_FILE")
    case "$cursor" in '') ;; *[!0-9.]*|*.*.*|.*|*.) transport_usage "QFS cursor is invalid";; *.*) ;; *) transport_usage "QFS cursor is invalid";; esac
    limit=$(jq -r '.input.limit // 20' "$TRANSPORT_REQUEST_FILE")
    case "$limit" in ''|*[!0-9]*) transport_usage "QFS limit must be a non-negative integer";; esac
    query="${base}/threads |> select thread_ts, last_reply_ts, reply_count |> limit ${limit}"
    if [ -n "$cursor" ]; then
      overlap=$(jq -r '.input.overlap_seconds // 0' "$TRANSPORT_REQUEST_FILE")
      case "$overlap" in *[!0-9]*|'') transport_usage "QFS overlap_seconds must be a non-negative integer";; esac
      start=$(awk -v cursor="$cursor" -v overlap="$overlap" 'BEGIN { value=cursor-overlap; if (value<0) value=0; printf "%.6f", value }')
      query="${query} |> after ${start}"
    fi
    ;;
  read_thread)
    thread=$(jq -r '.input.thread_ts // empty' "$TRANSPORT_REQUEST_FILE"); [ -n "$thread" ] || transport_usage "read_thread requires thread_ts"
    case "$thread" in *[!0-9.]*|*.*.*|.*|*.) transport_usage "QFS thread coordinate is invalid";; *.*) ;; *) transport_usage "QFS thread coordinate is invalid";; esac
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
    # `.ok // true` never fires for `{"ok": false}` — jq's `//` treats false as empty, so the
    # refusal this guard exists for read as an acceptance. `.ok != false` is the same
    # tolerance for an ABSENT field and an actual test of a present one.
    printf '%s' "$preview" | jq -e '.ok != false' >/dev/null 2>&1 || { transport_result deferred qfs_preview_refused "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    raw=$($QFS_BIN run "$query" --json --commit 2>&1) || {
      case "$?" in 124) transport_result deferred accepted_send_timeout "$TRANSPORT_REQUEST_ID" '{"accepted":true}';; *) transport_result deferred qfs_connector_failure "$TRANSPORT_REQUEST_ID" '{"accepted":null}';; esac
      exit 0
    }
else
    raw=$($QFS_BIN run "$query" --json 2>&1) || { transport_result deferred qfs_connector_failure "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
fi
data=$(printf '%s' "$raw" | jq -c --arg workspace "$workspace" --arg channel "$channel" --arg op "$TRANSPORT_OPERATION" '
  if $op=="list_thread_changes" then
    {workspace:$workspace,channel:$channel,
     threads:[((.threads // .rows // [])[]) | {thread_ts:(.thread_ts // .ts // null), last_reply_ts:(.last_reply_ts // .ts // null), reply_count:(.reply_count // null)} | select(.thread_ts != null)],
     next_cursor:(.next_cursor//null),has_more:(.has_more//false),observed_at:(.observed_at//null)}
  elif ($op|startswith("read_")) or $op=="search_exact" then
    {workspace:$workspace,channel:$channel,messages:(.messages // .rows // []),next_cursor:(.next_cursor//null),has_more:(.has_more//false),observed_at:(.observed_at//null)}
  else
    {workspace:$workspace,channel:$channel,ts:(.ts//.message.ts//null),thread_ts:(.thread_ts//.message.thread_ts//null),sender_id:(.sender_id//null),confirmed_by:(.confirmed_by//"qfs_response"),delivered:(.ok//true)}
  end' 2>/dev/null) || { transport_result error qfs_response_unparseable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
case "$TRANSPORT_OPERATION" in post_root|post_reply|add_reaction)
  [ "$(printf '%s' "$data" | jq -r .delivered)" = true ] || { transport_result deferred qfs_post_refused "$TRANSPORT_REQUEST_ID" "$data"; exit 0; };; esac
transport_result ok "" "$TRANSPORT_REQUEST_ID" "$data"
