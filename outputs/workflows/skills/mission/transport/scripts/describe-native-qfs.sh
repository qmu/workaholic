#!/bin/sh -eu
# Adapter for QFS connect --list + describe's path/children/verbs contract.
# Usage: describe-native-qfs.sh MOUNT WORKSPACE CHANNEL ACCOUNT
# No configuration changes and no effects. Account labels never become sender IDs.
mount=$1 workspace=$2 channel=$3 account=$4
QFS_BIN=${WORKAHOLIC_QFS_BIN:-qfs}
case "$mount/$workspace/$channel" in *[!A-Za-z0-9_/#-]*|*..*) printf '{"ok":false,"reason":"invalid_coordinate","observations":[]}\n'; exit 0;; esac
case "$mount" in /slack|/slack-*|/slack/*) ;; *) printf '{"ok":false,"reason":"invalid_mount","observations":[]}\n'; exit 0;; esac
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
run_qfs() { timeout 20 "$QFS_BIN" "$@"; }
run_qfs describe "$mount/$workspace" --json > "$tmp/workspace" 2>/dev/null || {
  printf '{"ok":false,"reason":"mount_not_described","observations":[]}\n'; exit 0; }
cid=''
lookup_failed=false
case "$channel" in C[A-Z0-9]*|G[A-Z0-9]*) cid=$channel;; esac
if [ -z "$cid" ]; then
  jq -r '.children[]? | select(.segment == "channels" or .segment == "private-channels") | .path' "$tmp/workspace" > "$tmp/collections"
  : > "$tmp/matches"
  while IFS= read -r collection; do
    case "$collection" in "$mount/$workspace/channels"|"$mount/$workspace/private-channels") ;; *) continue;; esac
    run_qfs describe "$collection" --json > "$tmp/schema" 2>/dev/null || { lookup_failed=true; continue; }
    name=$(printf '%s' "${channel#\#}" | jq -Rrs -L "$(dirname -- "$0")/lib" 'include "qfs-string"; qfs_string')
    run_qfs run "$collection |> where name == $name |> select id, name |> limit 100" --json > "$tmp/channels" 2>/dev/null || { lookup_failed=true; continue; }
    jq -e '(.rows|type)=="array"' "$tmp/channels" >/dev/null 2>&1 || { lookup_failed=true; continue; }
    jq -r --arg name "${channel#\#}" '.rows[]? | select(.name == $name) | .id' "$tmp/channels" >> "$tmp/matches"
  done < "$tmp/collections"
  ids=$(sort -u "$tmp/matches" | jq -Rsc 'split("\n")|map(select(length>0))')
  [ "$(printf '%s' "$ids" | jq length)" -eq 1 ] && cid=$(printf '%s' "$ids" | jq -r '.[0]')
fi
if [ -z "$cid" ]; then
  reason=channel_unreadable
  [ "$lookup_failed" != true ] || reason=channel_lookup_failed
  jq -cn --arg reason "$reason" '{ok:false,reason:$reason,observations:[]}'
  exit 0
fi
base="$mount/$workspace/$cid"
run_qfs describe "$base/messages" --json > "$tmp/messages" 2>/dev/null || {
  printf '{"ok":false,"reason":"messages_not_described","observations":[]}\n'; exit 0; }
run_qfs run "$base/messages |> select ts, user |> limit 1" --json > "$tmp/probe" 2>/dev/null || {
  printf '{"ok":false,"reason":"channel_unreadable","observations":[]}\n'; exit 0; }
jq -e '(.rows|type)=="array"' "$tmp/probe" >/dev/null 2>&1 || {
  printf '{"ok":false,"reason":"channel_response_unreadable","observations":[]}\n'; exit 0; }
# Inspect map bodies, not INSERT in describe: procedures can expose several maps with
# the same target, which is not proof that a text INSERT selects chat.postMessage.
run_qfs describe /sys/drivers --json >/dev/null 2>&1 || true
run_qfs run "/sys/drivers |> where kind == 'map' AND name LIKE '/slack/%' |> select name, body" --json > "$tmp/maps" 2>/dev/null || printf '{"rows":[]}' > "$tmp/maps"
jq -cn --arg mount "$mount" --arg workspace "$workspace" --arg channel "$channel" --arg cid "$cid" --arg account "$account" \
  --slurpfile maps "$tmp/maps" --slurpfile schema "$tmp/messages" '
  def maps_for($path): [$maps[0].rows[]? | select(.name == $path)];
  maps_for("/slack/{ws}/{channel}/messages") as $root |
  maps_for("/slack/{ws}/{channel}/messages/{ts}/replies") as $reply |
  (($root|length)==1 and ($root[0].body|contains("chat.postMessage"))) as $post |
  (($reply|length)==1 and ($reply[0].body|contains("chat.postMessage")) and ($reply[0].body|contains("thread_ts"))) as $thread |
  {ok:true,observations:[{available:true,transport:"qfs",dialect:"pipe-sql",described:true,
    mount:$mount,workspace:$workspace,channel:$channel,channel_id:$cid,account:$account,
    sender_id:null,sender_verified:false,channel_verified:true,map_verified:$post,
    thread_map_verified:$thread,operations:(["read_channel_delta","read_thread","search_exact"]+
      (if $post then ["post_root"] else [] end)+(if $thread then ["post_reply"] else [] end)),
    limitations:(["sender_unverified","thread_discovery_unavailable","reaction_map_unverified"]+
      (if $post then [] else ["root_map_unverified_or_ambiguous"] end))}]}'
