#!/bin/sh -eu
# QFS pipe-SQL adapter: discovered paths, INSERT maps, default preview, no CALL guesses.
. "$(dirname -- "$0")/../lib/result.sh"
transport_parse_request_arg "$@"
route=$(jq -c --arg op "$TRANSPORT_OPERATION" '.input.binding.routes[]? |
  select(.transport=="qfs" and .described==true and .dialect=="pipe-sql" and (.operations|index($op)))' "$TRANSPORT_REQUEST_FILE" | head -1)
[ -n "$route" ] || { transport_result deferred qfs_operation_unavailable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
QFS_BIN=${WORKAHOLIC_QFS_BIN:-qfs}
mount=$(printf '%s' "$route" | jq -r .mount)
workspace=$(jq -r .input.binding.workspace "$TRANSPORT_REQUEST_FILE")
channel=$(jq -r .input.binding.channel_id "$TRANSPORT_REQUEST_FILE")
case "$mount/$workspace/$channel" in *[!A-Za-z0-9_/-]*|*..*) transport_usage "invalid QFS coordinate";; esac
base="$mount/$workspace/$channel"
thread=$(jq -r '.input.thread_ts // empty' "$TRANSPORT_REQUEST_FILE")
case "$thread" in '') ;; *[!0-9.]*|*.*.*|.*|*.) transport_usage "invalid thread coordinate";; esac
path="$base/messages"
case "$TRANSPORT_OPERATION" in read_thread|post_reply) [ -n "$thread" ] || transport_usage "thread required"; path="$path/$thread/replies";; esac
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
qfs_call() { timeout 20 "$QFS_BIN" "$@"; }
error_data() {
  # Only preserve machine error codes; provider prose can contain secrets or request text.
  jq -c '{provider_code:(.error.code // .kind // "unreadable_provider_error")}' "$tmp/error" 2>/dev/null || printf '{}'
}
case "$TRANSPORT_OPERATION" in
  read_channel_delta|read_thread|search_exact)
    query="$path"
    cursor=$(jq -r '.input.cursor // empty' "$TRANSPORT_REQUEST_FILE")
    if [ -n "$cursor" ]; then
      case "$cursor" in *[!0-9.]*|*.*.*|.*|*.) transport_usage "invalid cursor";; esac
      overlap=$(jq -r '.input.overlap_seconds // 0' "$TRANSPORT_REQUEST_FILE")
      case "$overlap" in ''|*[!0-9]*) transport_usage "invalid overlap";; esac
      since=$(awk -v c="$cursor" -v o="$overlap" 'BEGIN {v=c-o; if(v<0)v=0; printf "%.6f",v}')
      query="$query |> where ts >= '$since'"
    fi
    query="$query |> select ts, user, text, thread_ts, subtype |> limit 100"
    if ! qfs_call run "$query" --json > "$tmp/raw" 2> "$tmp/error"; then
      transport_result deferred qfs_connector_failure "$TRANSPORT_REQUEST_ID" "$(error_data)"; exit 0
    fi
    data=$(jq -c --arg workspace "$workspace" --arg channel "$channel" '
      if (.rows|type) != "array" then error("missing rows") else
      {workspace:$workspace,channel:$channel,messages:[.rows[]|. + {id:.ts,sender_id:.user}],
       next_cursor:([.rows[].ts]|max // null),has_more:((.meta.truncated == true) or (.rows|length)>=100)} end' "$tmp/raw") \
      || { transport_result deferred qfs_response_unreadable "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    if [ "$TRANSPORT_OPERATION" = search_exact ]; then
      # A bounded message table is not a search index. Return exact-token matches
      # as partial evidence; zero rows cannot certify that a historical root is absent.
      exact=$(jq -r '.input.query // empty' "$TRANSPORT_REQUEST_FILE")
      [ -n "$exact" ] || transport_usage "query required"
      data=$(printf '%s' "$data" | jq -c --arg query "$exact" \
        '.messages |= map(select(.text|contains($query))) | .has_more=true | .complete=false')
    fi
    transport_result ok "" "$TRANSPORT_REQUEST_ID" "$data";;
  post_root|post_reply)
    jq -e '.input.text|type=="string" and length>0' "$TRANSPORT_REQUEST_FILE" >/dev/null 2>&1 || transport_usage "text required"
    flag=map_verified; [ "$TRANSPORT_OPERATION" != post_reply ] || flag=thread_map_verified
    [ "$(printf '%s' "$route" | jq -r --arg flag "$flag" '.[$flag]')" = true ] || {
      transport_result deferred qfs_map_unverified "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    text=$(jq -r -L "$(dirname -- "$0")/../lib" 'include "qfs-string"; .input.text | qfs_string' "$TRANSPORT_REQUEST_FILE")
    query="insert into $path values ($text)"
    if ! qfs_call run "$query" --json > "$tmp/preview" 2> "$tmp/error"; then
      transport_result deferred qfs_preview_failed "$TRANSPORT_REQUEST_ID" "$(error_data)"; exit 0
    fi
    # READ THE COUNT WHERE THE PROVIDER ANSWERS IT. QFS answers the affected count nested at
    # `.preview.total_affected` as `{"exact": N}`; the top-level `.total_affected` this guard
    # used to read is `null` there, and `null > 0` is `false` in jq — so a CORRECT preview
    # refused every post and the commit below was unreachable. Both nestings and a bare number
    # are tolerated rather than one guess being swapped for another; the first reading that
    # yields a number wins, and a shape NO reading can find stays `qfs_preview_refused`, the
    # honest word for "the preview did not say what was affected". The `committed` and
    # `preview.rows` terms are unchanged: only a preview that positively states an affected
    # row may commit.
    jq -e '.committed == false and (.preview.rows|type)=="array"
           and ([ (.preview.total_affected.exact? // empty),
                  (.preview.total_affected? // empty),
                  (.total_affected.exact? // empty),
                  (.total_affected? // empty) ]
                | map(select(type == "number")) | first // 0) > 0' "$tmp/preview" >/dev/null 2>&1 || {
      transport_result deferred qfs_preview_refused "$TRANSPORT_REQUEST_ID" '{}'; exit 0; }
    if ! qfs_call run "$query" --json --commit > "$tmp/raw" 2> "$tmp/error"; then
      transport_result deferred qfs_connector_failure "$TRANSPORT_REQUEST_ID" "$(error_data)"; exit 0
    fi
    # A committed effect without a Slack coordinate is accepted, not confirmed delivery.
    # Leave the existing outbox unknown; do not retry over a different account.
    transport_result deferred qfs_receipt_unavailable "$TRANSPORT_REQUEST_ID" '{"accepted":true}' ;;
  *) transport_result deferred qfs_operation_unavailable "$TRANSPORT_REQUEST_ID" '{}';;
esac
