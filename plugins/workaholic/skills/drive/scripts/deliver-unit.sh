#!/bin/sh -eu
# Resume delivery for one reported unit without reimplementing its tickets.
# Usage: deliver-unit.sh UNIT

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
UNIT=${1:-}
[ -n "$UNIT" ] || { printf '{"ok":false,"reason":"unit_required"}\n'; exit 0; }

catchup=$(sh "$SCRIPT_DIR/catch-up-claim.sh" "$UNIT" 2>/dev/null || true)
outcome=$(printf '%s' "$catchup" | jq -r '.outcome // empty' 2>/dev/null || true)
case "$outcome" in
  catch_up_refused) jq -cn --arg unit "$UNIT" --argjson catchup "${catchup:-null}" '{ok:false,unit:$unit,catchup:$catchup,delivery:null,reason:"catch_up_refused"}'; exit 0;;
  caught_up) delivery=$(sh "$SCRIPT_DIR/retry-undelivered.sh" "$UNIT" --own-tip 2>/dev/null || true);;
  already_current) delivery=$(sh "$SCRIPT_DIR/retry-undelivered.sh" "$UNIT" 2>/dev/null || true);;
  *) jq -cn --arg unit "$UNIT" --arg raw "$catchup" '{ok:false,unit:$unit,catchup:null,delivery:null,reason:"catch_up_unreadable",detail:$raw}'; exit 0;;
esac
status=$(printf '%s' "$delivery" | jq -r '.outcome // empty' 2>/dev/null || true)
jq -cn --arg unit "$UNIT" --argjson catchup "$catchup" --argjson delivery "${delivery:-null}" --arg status "$status" \
  '{ok:($status=="merged"),unit:$unit,catchup:$catchup,delivery:$delivery,reason:(if $status=="merged" then "" elif $status=="merge_refused: checks_pending" then "waiting_checks" else ($delivery.reason // $status // "delivery_unreadable") end)}'
