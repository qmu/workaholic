#!/bin/sh -eu
# Post a proposal announcement to Slack AS THE BOT (docs/
# loop-engineering-workflow.md E2: AI proposals appear as the bot, distinct from
# human speech). Environment-driven and NEVER load-bearing:
#
#   SLACK_BOT_TOKEN            xoxb token with chat:write (read at call time,
#                              never persisted, logged, or echoed)
#   WORKAHOLIC_SLACK_CHANNEL   channel id or name to post into. OPTIONAL since 2026-09-01:
#                              absent, this falls back to WORKAHOLIC_INBOUND_SLACK_CHANNEL and
#                              then to the repository's own name -- the resolution
#                              `workaholic:notify` already states, read here rather than
#                              re-authored.
#   WORKAHOLIC_SLACK_API_URL   override for tests (default Slack's
#                              chat.postMessage endpoint); the hermetic suite
#                              points this at a local stub - the suite never
#                              calls Slack
#
# A missing token/channel is a graceful, recorded no-op (exit 0): the loop must
# run identically on machines with no Slack wiring, and a notification failure
# must never fail a proposal that already pushed (see propose/SKILL.md,
# Notifier contract). Non-zero exit is reserved for malformed invocation.
#
# Usage: notify-slack.sh [--thread-ts <ts>] "<text>"
# Output: JSON {notified, reason}
#   reason: "" | no_token | no_channel | http_<code> | slack_<error> | curl_failed
#
# --thread-ts posts the message as a REPLY into an existing thread instead of as
# a new keyed root. Slack's chat.postMessage takes thread_ts as an ordinary
# argument of the same method under the same chat:write scope this script has
# always required -- there is no second scope and no account-level provisioning
# change (measured 2026-08-31 against Slack's own chat.postMessage reference;
# the search half of the thread lookup stays on the connector, which is what
# needs search:read). The SEARCH is still not this script's: a caller passes a
# coordinate the connector already resolved. With no flag the payload is
# byte-identical to what this script has always sent.

set -eu

THREAD_TS=""
THREAD_TS_GIVEN=0
while [ $# -gt 0 ]; do
    case "$1" in
        --thread-ts)
            [ $# -ge 2 ] || { echo '{"notified": false, "reason": "bad_thread_ts"}'; exit 1; }
            THREAD_TS="$2"
            THREAD_TS_GIVEN=1
            shift 2
            ;;
        --thread-ts=*)
            THREAD_TS="${1#--thread-ts=}"
            THREAD_TS_GIVEN=1
            shift
            ;;
        *) break ;;
    esac
done

# A malformed coordinate is refused by its own name rather than dropped: silently
# posting a ROOT where a reply was asked for is the failure this flag exists to
# remove, and it is invisible from the caller's side. A Slack ts is
# <seconds>.<microseconds> -- digits, exactly one dot, neither leading nor
# trailing. An explicitly empty value is malformed too, not "no flag".
if [ "$THREAD_TS_GIVEN" = "1" ]; then
    case "$THREAD_TS" in
        "" | *[!0-9.]* | *.*.* | .* | *.) echo '{"notified": false, "reason": "bad_thread_ts"}'; exit 1 ;;
        *.*) : ;;
        *) echo '{"notified": false, "reason": "bad_thread_ts"}'; exit 1 ;;
    esac
fi

TEXT="${1:-}"
[ -n "$TEXT" ] || { echo '{"notified": false, "reason": "no_text"}'; exit 1; }

TOKEN="${SLACK_BOT_TOKEN:-}"
# ONE CHANNEL, ONE RESOLUTION (2026-09-01, issue #806). This read `WORKAHOLIC_SLACK_CHANNEL`
# and nothing else, with no default -- so a repository that had already declared its channel the
# way `workaholic:notify` states it (*the repository's channel: `WORKAHOLIC_INBOUND_SLACK_CHANNEL`
# when set, else the repository's own name*) still got `no_channel` from this transport. Two
# variables for one channel is the second derivation this repository forbids everywhere else, and
# its cost was concrete: the machine fallback needed a token AND a second variable nobody had a
# reason to set, so the one transport designated to survive a connector outage could not run
# during one.
#
# THE ORDER IS THE STATED ONE, and this script is a reader of it rather than a second author:
# an explicit `WORKAHOLIC_SLACK_CHANNEL` still wins (a caller that wants a different channel for
# the tokened post keeps saying so), then the repository's declared channel, then the repository's
# own name -- the last derived from the git remote, which is where `<repo_name>` comes from
# everywhere else in this plugin.
CHANNEL="${WORKAHOLIC_SLACK_CHANNEL:-${WORKAHOLIC_INBOUND_SLACK_CHANNEL:-}}"
if [ -z "$CHANNEL" ]; then
    CHANNEL=$(git config --get remote.origin.url 2>/dev/null \
        | sed -e 's#\.git$##' -e 's#.*/##' 2>/dev/null || printf '')
fi
API_URL="${WORKAHOLIC_SLACK_API_URL:-https://slack.com/api/chat.postMessage}"

if [ -z "$TOKEN" ]; then
    echo '{"notified": false, "reason": "no_token"}'
    exit 0
fi
if [ -z "$CHANNEL" ]; then
    echo '{"notified": false, "reason": "no_channel"}'
    exit 0
fi

# Keep this legacy entry point's two-field response while delegating the effect
# and its durable evidence to transport/v1. Callers may supply a stable ID for
# retries; otherwise this compatibility wrapper mints one for this occurrence.
TRANSPORT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/../../transport/scripts" && pwd)
REQUEST=$(mktemp); trap 'rm -f "$REQUEST"' EXIT HUP INT TERM
request_id=${WORKAHOLIC_TRANSPORT_REQUEST_ID:-notify-$(date +%s)-$$}
workspace=${WORKAHOLIC_SLACK_WORKSPACE:-legacy-token}
operation=post_root; [ "$THREAD_TS_GIVEN" = 0 ] || operation=post_reply
binding_id=$(printf '%s' "slack-token:$workspace:$CHANNEL" | sha256sum | cut -c1-32)
jq -cn --arg rid "$request_id" --arg op "$operation" --arg root "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" \
  --arg instance "notify-$binding_id" --arg binding "$binding_id" --arg workspace "$workspace" --arg channel "$CHANNEL" \
  --arg text "$TEXT" --arg thread "$THREAD_TS" '
  {protocol:"workaholic.transport/v1",request_id:$rid,operation:$op,repo_root:$root,instance_id:$instance,binding_id:$binding,
   input:({binding:{workspace:$workspace,channel:$channel,channel_id:null,sender_id:null,operations:["post_root","post_reply"],
          routes:[{transport:"slack_token",mount:null,account:null,operations:["post_root","post_reply"],sender_id:null,described:true}],thread_map:{}},
          text:$text,legacy_payload:true} + (if $thread=="" then {} else {thread_ts:$thread} end))}' >"$REQUEST"
result=$(SLACK_BOT_TOKEN="$TOKEN" WORKAHOLIC_SLACK_API_URL="$API_URL" "$TRANSPORT_DIR/perform.sh" --request "$REQUEST") || {
  echo '{"notified": false, "reason": "curl_failed"}'; exit 0;
}
if [ "$(printf '%s' "$result" | jq -r .status 2>/dev/null)" = ok ]; then
  echo '{"notified": true, "reason": ""}'
  exit 0
fi
reason=$(printf '%s' "$result" | jq -r '.reason // "transport_failed"' 2>/dev/null || printf transport_failed)
case "$reason" in provider_timeout|accepted_send_timeout|state_writer_missing|outbox_conflict|binding_busy|binding_owned) reason=curl_failed;; esac
jq -cn --arg reason "$reason" '{notified:false,reason:$reason}'
