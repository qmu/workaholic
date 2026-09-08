#!/bin/sh -eu
# Describe the live QFS Slack routes a declared binding could actually use. Pure read.
#
#   describe-qfs.sh --workspace W --channel C [--mount /slack/…] [--account LABEL]
#                   [--sender-id U…]
#
# WHY THIS EXISTS. `observe-channel.sh` and `check-slack-channel.sh` each described the literal
# path `/slack` and read whatever came back as the route. That path is a guess: qfs mounts a
# Slack connection under its own name (`/slack/qmu`, `/slack/work`), so on any machine whose
# mount is named the describe returned nothing and the loop reported an unverified target while
# a perfectly good route sat one path segment away. A DECLARED mount is described directly and
# wins deterministically; only an undeclared one enumerates connections.
#
# WHAT IT WILL NOT DO. It never guesses a channel from a label. A mount whose channel list was
# read and does NOT carry the channel yields a `public_miss` observation — the resolver's own
# "cannot see it" evidence, never absence — and a mount whose channel list could not be read at
# all yields `channel_verified: false`, which is carried all the way onto the binding rather
# than being quietly rounded up to verified. An account or profile label is likewise never
# offered as a sender: `sender_id` is set only from a described identity.
#
# Output (one JSON line):
#   {"ok":true,"described":true,"observations":[…],"mounts":["…"],"reason":"", "unreadable":[…]}
#
# Typed refusals, each its own word and none of them a verdict about the channel:
#   `qfs_unavailable`      the binary is not on this machine
#   `connections_unreadable` the enumeration itself failed or did not parse
#   `no_connection`        qfs answered, and holds no Slack connection at all
#   `mount_not_described`  the DECLARED mount could not be described (wrong name, or removed)
#   `missing_scope`        qfs answered that the token may not see what was asked for
#   `no_route`             connections exist and none matches the declared workspace/account

WORKSPACE="" CHANNEL="" MOUNT="" ACCOUNT="" SENDER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --workspace) WORKSPACE=${2:-}; shift 2 ;;
    --channel) CHANNEL=${2:-}; shift 2 ;;
    --mount) MOUNT=${2:-}; shift 2 ;;
    --account) ACCOUNT=${2:-}; shift 2 ;;
    --sender-id) SENDER=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"described":false,"observations":[],"reason":"invalid_argument"}\n'; exit 2 ;;
  esac
done
[ -n "$CHANNEL" ] || { printf '{"ok":false,"described":false,"observations":[],"reason":"no_channel"}\n'; exit 2; }

QFS_BIN=${WORKAHOLIC_QFS_BIN:-qfs}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
# The counter lives in a file because every provider call is made inside a command
# substitution, and a shell variable incremented in a subshell is lost on the way out — the
# bounded-call claim would then be a number nobody counted.
printf '0' >"$tmp/calls"
qfs_calls() { cat "$tmp/calls"; }
qfs_call() { expr "$(cat "$tmp/calls")" + 1 >"$tmp/calls"; "$QFS_BIN" "$@" 2>&1 || printf ''; }
refuse() { jq -cn --arg reason "$1" --argjson unreadable "${2:-[]}" --argjson calls "$(qfs_calls)" \
  '{ok:false,described:false,observations:[],mounts:[],unreadable:$unreadable,calls:$calls,reason:$reason}'; exit 0; }
command -v "$QFS_BIN" >/dev/null 2>&1 || refuse qfs_unavailable

scoped() {
  # `missing_scope` is qfs saying the token may not look, which is never "it is not there".
  case "$1" in *missing_scope*|*not_authed*|*slack_auth*|*"not authorized"*) return 0 ;; esac
  return 1
}

# ---- 1. Which mounts are candidates -----------------------------------------------------
# A declared mount is described directly: the operator named it, so nothing may substitute
# another route for it. Only an undeclared binding enumerates.
if [ -n "$MOUNT" ]; then
  printf '%s\n' "$MOUNT" >"$tmp/mounts"
else
  mount_names() {
    printf '%s' "$1" | jq -r '
      [((.connections // .mounts // .data // .items // []) | if type == "array" then . else [] end)[]?
        | (.mount // .path // (if (.name // "") != "" then "/slack/" + (.name|tostring) else null end))
        | select(. != null)] | unique | .[]' 2>/dev/null || printf ''
  }
  listed=$(qfs_call connection list --json)
  printf '%s' "$listed" | jq -e . >/dev/null 2>&1 || { scoped "$listed" && refuse missing_scope; listed=''; }
  [ -n "$listed" ] && mount_names "$listed" >"$tmp/mounts" || : >"$tmp/mounts"
  if [ ! -s "$tmp/mounts" ]; then
    # Compatibility: a qfs without `connection list` still answers the aggregate describe.
    listed=$(qfs_call describe /slack --json)
    printf '%s' "$listed" | jq -e . >/dev/null 2>&1 || { scoped "$listed" && refuse missing_scope; refuse connections_unreadable; }
    mount_names "$listed" >"$tmp/mounts"
  fi
  [ -s "$tmp/mounts" ] || refuse no_connection
fi

# ---- 2. Describe each candidate ---------------------------------------------------------
: >"$tmp/observations"
: >"$tmp/unreadable"
while IFS= read -r mount; do
  [ -n "$mount" ] || continue
  case "$mount" in /slack/*) ;; *) printf '%s\n' "not_a_slack_mount:$mount" >>"$tmp/unreadable"; continue ;; esac
  described=$(qfs_call describe "$mount" --json)
  if ! printf '%s' "$described" | jq -e . >/dev/null 2>&1; then
    scoped "$described" && printf '%s\n' "missing_scope:$mount" >>"$tmp/unreadable" || printf '%s\n' "mount_not_described:$mount" >>"$tmp/unreadable"
    continue
  fi
  : >"$tmp/one"
  printf '%s' "$described" | jq -c \
    --arg mount "$mount" --arg workspace "$WORKSPACE" --arg channel "$CHANNEL" \
    --arg account "$ACCOUNT" --arg sender "$SENDER" '
    . as $d |
    # qfs versions differ in where they hang the mount body: some answer the mount itself,
    # older ones answer the whole `/slack` listing. Take this mount out of a listing by its
    # own PATH rather than by position — a listing read positionally is how a describe of one
    # mount silently returns another one'"'"'s identity.
    (if ($d.mounts | type) == "array" then $d.mounts
     elif ($d.connections | type) == "array" then $d.connections
     elif ($d.items | type) == "array" then $d.items
     elif ($d.data | type) == "array" then $d.data
     else null end) as $list |
    (if $list != null then
       (([$list[] | select(((.mount // .path // "") == $mount)
                           or (((.name // "") != "") and ("/slack/" + (.name|tostring)) == $mount))] | first)
        // (if ($list | length) == 1 then $list[0] else null end))
     elif ($d.mount | type) == "object" then $d.mount
     elif ($d.connection | type) == "object" then $d.connection
     elif ($d.data | type) == "object" then $d.data
     else $d end) as $m0 |
    # An empty body is NOT a described route. Reporting one would manufacture a route with
    # default operations and an unverified channel out of a describe that said nothing.
    (if ($m0 | type) == "object" and (($m0 | length) > 0) then $m0 else null end) as $m |
    if $m == null then empty else
    (($m.channels // $m.views // $m.conversations // null)) as $channels |
    (if $channels == null then null
     else [$channels[]? | {name:(.name // .channel // null), id:(.id // .channel_id // null),
                           is_private:(.is_private // .private // null)}] end) as $views |
    (if $views == null then null
     else ([$views[] | select((.name == $channel) or (.id == $channel))] | first) end) as $view |
    ($m.operations // $m.read_map // ["read_channel_delta"]) as $offered |
    {transport:"qfs",
     available:true,
     described:true,
     mount:$mount,
     account:($m.account // $m.name // (if $account == "" then null else $account end)),
     workspace:($m.workspace // $m.workspace_name // $m.team // (if $workspace == "" then null else $workspace end)),
     channel:$channel,
     channel_id:(if $view != null then ($view.id // null) else null end),
     channel_verified:($views != null and $view != null),
     sender_id:($m.sender_id // $m.bot_user_id // $m.user_id // null),
     operations:$offered,
     thread_map:($m.thread_map // {})}
    | if ($views != null and $view == null)
      then {transport:"qfs", available:false, described:true, mount:$mount, workspace:.workspace,
            channel:$channel, visibility:"public_miss", operations:[]}
      else . end
    end' >"$tmp/one" 2>/dev/null || printf '%s\n' "describe_unparseable:$mount" >>"$tmp/unreadable"
  if [ -s "$tmp/one" ]; then cat "$tmp/one" >>"$tmp/observations"
  else printf '%s\n' "mount_not_described:$mount" >>"$tmp/unreadable"; fi
done <"$tmp/mounts"

observations=$(jq -sc '.' "$tmp/observations" 2>/dev/null || printf '[]')
unreadable=$(jq -Rsc 'split("\n") | map(select(length > 0))' "$tmp/unreadable")

# A declared mount that could not be described is its own refusal: the operator named a route
# and it is not there, which is a different fact from having no connections at all.
if [ -n "$MOUNT" ] && [ "$(printf '%s' "$observations" | jq 'length')" -eq 0 ]; then
  case "$(printf '%s' "$unreadable" | jq -r '.[0] // ""')" in
    missing_scope:*) refuse missing_scope "$unreadable" ;;
    *) refuse mount_not_described "$unreadable" ;;
  esac
fi

[ "$(printf '%s' "$observations" | jq 'length')" -gt 0 ] || refuse no_route "$unreadable"

jq -cn --argjson observations "$observations" --argjson unreadable "$unreadable" --argjson calls "$(qfs_calls)" \
  '{ok:true, described:true, observations:$observations,
    mounts:([$observations[].mount] | unique),
    calls:$calls, unreadable:$unreadable, reason:""}'
