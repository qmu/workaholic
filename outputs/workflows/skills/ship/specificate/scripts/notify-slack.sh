#!/bin/sh -eu
# Post a proposal announcement to Slack AS THE BOT (docs/
# loop-engineering-workflow.md E2: AI proposals appear as the bot, distinct from
# human speech). Environment-driven and NEVER load-bearing:
#
#   SLACK_BOT_TOKEN            xoxb token with chat:write (read at call time,
#                              never persisted, logged, or echoed)
#   WORKAHOLIC_SLACK_CHANNEL   channel id to post into
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
CHANNEL="${WORKAHOLIC_SLACK_CHANNEL:-}"
API_URL="${WORKAHOLIC_SLACK_API_URL:-https://slack.com/api/chat.postMessage}"

if [ -z "$TOKEN" ]; then
    echo '{"notified": false, "reason": "no_token"}'
    exit 0
fi
if [ -z "$CHANNEL" ]; then
    echo '{"notified": false, "reason": "no_channel"}'
    exit 0
fi

# JSON-encode the payload safely (text is arbitrary prose). The thread_ts key
# rides ONLY when the flag was given, so a caller that passes no flag sends the
# byte-identical payload this script has always sent.
PAYLOAD=$(printf '%s' "$TEXT" | python3 -c 'import json,sys,os
p = {"channel": os.environ["WORKAHOLIC_SLACK_CHANNEL"], "text": sys.stdin.read()}
if sys.argv[1]:
    p["thread_ts"] = sys.argv[1]
print(json.dumps(p))' "$THREAD_TS")

# The token rides only in the Authorization header of this one call; stderr is
# discarded so a curl verbose/error path can never echo headers.
HTTP_BODY=$(mktemp)
trap 'rm -f "$HTTP_BODY"' EXIT
HTTP_CODE=$(curl -sS -o "$HTTP_BODY" -w '%{http_code}' -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'Content-Type: application/json; charset=utf-8' \
    --data "$PAYLOAD" \
    "$API_URL" 2>/dev/null) || { echo '{"notified": false, "reason": "curl_failed"}'; exit 0; }

if [ "$HTTP_CODE" != "200" ]; then
    printf '{"notified": false, "reason": "http_%s"}\n' "$HTTP_CODE"
    exit 0
fi

python3 - "$HTTP_BODY" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print('{"notified": false, "reason": "slack_unparseable"}')
    raise SystemExit(0)
if d.get("ok"):
    print('{"notified": true, "reason": ""}')
else:
    err = str(d.get("error", "unknown"))[:64].replace('"', '')
    print(json.dumps({"notified": False, "reason": f"slack_{err}"}))
PY
