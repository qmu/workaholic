#!/bin/sh -eu
# Resume delivery as a durable state machine, independently of implementation.
# Usage: deliver-unit.sh UNIT

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
STATE="${SCRIPT_DIR}/../../runtime/scripts/state.sh"
MERGE_PULL="${SCRIPT_DIR}/../../gather/scripts/merge-pull.sh"
UNIT=${1:-}
[ -n "$UNIT" ] || { printf '{"ok":false,"reason":"unit_required"}\n'; exit 0; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf '{"ok":false,"reason":"not_a_repository"}\n'; exit 0; }

key=$(printf '%s' "$UNIT" | sha256sum | cut -c1-24)
INSTANCE="delivery-${key}"; RECORD="delivery/${key}"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BOOT=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown)
START=$(awk '{print $22}' "/proc/$$/stat" 2>/dev/null || printf unknown)
NONCE=$(printf '%s' "$$:$NOW:$UNIT" | sha256sum | cut -c1-24)
OWNER=$(jq -cn --arg i "$INSTANCE" --arg n "$NONCE" --argjson p "$$" --arg b "$BOOT" --arg s "$START" '{instance_id:$i,nonce:$n,process_id:$p,boot_id:$b,process_start:$s}')
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT HUP INT TERM

state() { "$STATE" "$@"; }
read_meta() { state read --scope instance --id "$INSTANCE"; }
meta=$(read_meta)
if [ "$(printf '%s' "$meta" | jq -r '.data.found')" != true ]; then
  jq -cn --arg now "$NOW" --argjson owner "$OWNER" --arg unit "$UNIT" '{updated_at:$now,owner:$owner,data:{lease_status:"acquired",unit:$unit}}' >"$TMP/meta.json"
  made=$(state create --scope instance --id "$INSTANCE" --input "$TMP/meta.json")
  [ "$(printf '%s' "$made" | jq -r .status)" = ok ] && meta=$(printf '%s' "$made" | jq -c '{data:{found:true,record:.data.record}}') || meta=$(read_meta)
fi

meta_record=$(printf '%s' "$meta" | jq -c '.data.record // null')
[ "$meta_record" != null ] || { printf '{"ok":false,"reason":"delivery_state_unreadable"}\n'; exit 0; }
held_owner=$(printf '%s' "$meta_record" | jq -c '.owner')
if [ "$held_owner" = null ]; then
  rev=$(printf '%s' "$meta_record" | jq -r .revision)
  jq -cn --arg now "$NOW" --argjson owner "$OWNER" '{updated_at:$now,event:"acquire",owner:$owner}' >"$TMP/lease.json"
  changed=$(state transition --scope instance --id "$INSTANCE" --expected-revision "$rev" --input "$TMP/lease.json")
  [ "$(printf '%s' "$changed" | jq -r .status)" = ok ] || { printf '{"ok":false,"reason":"delivery_busy"}\n'; exit 0; }
  meta_record=$(printf '%s' "$changed" | jq -c .data.record)
elif [ "$held_owner" != "$OWNER" ]; then
  old_pid=$(printf '%s' "$held_owner" | jq -r '.process_id // empty'); old_boot=$(printf '%s' "$held_owner" | jq -r '.boot_id // empty'); old_start=$(printf '%s' "$held_owner" | jq -r '.process_start // empty')
  ended=false
  if [ -n "$old_pid" ] && [ -n "$old_boot" ] && [ -n "$old_start" ] && [ "$BOOT" != unknown ]; then
    if [ "$old_boot" != "$BOOT" ]; then ended=true
    elif [ ! -r "/proc/${old_pid}/stat" ]; then ended=true
    elif [ "$(awk '{print $22}' "/proc/${old_pid}/stat" 2>/dev/null || printf '')" != "$old_start" ]; then ended=true
    fi
  fi
  [ "$ended" = true ] || { printf '{"ok":false,"reason":"delivery_busy"}\n'; exit 0; }
  rev=$(printf '%s' "$meta_record" | jq -r .revision)
  jq -cn --arg now "$NOW" --argjson owner "$OWNER" --argjson old "$held_owner" '{updated_at:$now,event:"takeover",expired:true,old_owner_ended:true,old_owner_evidence:{recorded_owner:$old},owner:$owner}' >"$TMP/lease.json"
  changed=$(state transition --scope instance --id "$INSTANCE" --expected-revision "$rev" --input "$TMP/lease.json")
  [ "$(printf '%s' "$changed" | jq -r .status)" = ok ] || { printf '{"ok":false,"reason":"delivery_busy"}\n'; exit 0; }
  meta_record=$(printf '%s' "$changed" | jq -c .data.record)
fi
GEN=$(printf '%s' "$meta_record" | jq -r .generation)

release_lease() {
  current=$(read_meta); rec=$(printf '%s' "$current" | jq -c '.data.record // null')
  [ "$rec" != null ] || return 0
  [ "$(printf '%s' "$rec" | jq -c .owner)" = "$OWNER" ] || return 0
  rev=$(printf '%s' "$rec" | jq -r .revision)
  jq -cn --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson owner "$OWNER" --argjson generation "$GEN" '{updated_at:$now,event:"release",owner:$owner,generation:$generation}' >"$TMP/release.json"
  state transition --scope instance --id "$INSTANCE" --expected-revision "$rev" --input "$TMP/release.json" >/dev/null 2>&1 || true
}

delivery=$(state read --scope instance --id "$INSTANCE" --record "$RECORD")
if [ "$(printf '%s' "$delivery" | jq -r '.data.found')" != true ]; then
  jq -cn --arg now "$NOW" --argjson owner "$OWNER" --argjson generation "$GEN" --arg unit "$UNIT" '{updated_at:$now,owner:$owner,generation:$generation,data:{state:"not_ready",unit:$unit,merge_request:null,last_result:null}}' >"$TMP/delivery.json"
  delivery=$(state create --scope instance --id "$INSTANCE" --record "$RECORD" --input "$TMP/delivery.json")
fi
[ "$(printf '%s' "$delivery" | jq -r .status)" = ok ] || { release_lease; printf '{"ok":false,"reason":"delivery_state_conflict"}\n'; exit 0; }

transition() {
  event=$1; extra=${2:-'{}'}
  current=$(state read --scope instance --id "$INSTANCE" --record "$RECORD")
  rev=$(printf '%s' "$current" | jq -r '.data.record.revision')
  jq -cn --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg event "$event" --argjson owner "$OWNER" --argjson generation "$GEN" --argjson extra "$extra" '{updated_at:$now,event:$event,owner:$owner,generation:$generation,data:$extra}' >"$TMP/transition.json"
  state transition --scope instance --id "$INSTANCE" --record "$RECORD" --expected-revision "$rev" --input "$TMP/transition.json"
}

current=$(state read --scope instance --id "$INSTANCE" --record "$RECORD")
phase=$(printf '%s' "$current" | jq -r '.data.record.data.state')
catchup=null

case "$phase" in
  merged) release_lease; jq -cn --arg unit "$UNIT" '{ok:true,unit:$unit,catchup:null,delivery:{status:"merged",reconciled:true},reason:""}'; exit 0;;
  refused)
    reset=$(transition not_ready '{}')
    [ "$(printf '%s' "$reset" | jq -r .status)" = ok ] || { release_lease; printf '{"ok":false,"reason":"delivery_state_conflict"}\n'; exit 0; }
    current=$(state read --scope instance --id "$INSTANCE" --record "$RECORD"); phase=not_ready;;
esac

if [ "$phase" = unknown ] || [ "$phase" = merging ]; then
  printf '%s' "$current" | jq '.data.record.data.merge_request + {reconcile_only:true}' >"$TMP/merge.json"
  reconciled=$(sh "$MERGE_PULL" --request "$TMP/merge.json" 2>/dev/null || printf '{"status":"unknown","reason":"merge_effect_unconfirmed"}')
  case "$(printf '%s' "$reconciled" | jq -r '.status // "unknown"')" in
    merged)
      recorded=$(transition merged "$(jq -cn --argjson r "$reconciled" '{last_result:$r}')")
      [ "$(printf '%s' "$recorded" | jq -r .status)" = ok ] || { release_lease; printf '{"ok":false,"reason":"delivery_state_conflict"}\n'; exit 0; }
      release_lease; jq -cn --arg unit "$UNIT" --argjson delivery "$reconciled" '{ok:true,unit:$unit,catchup:null,delivery:$delivery,reason:""}'; exit 0;;
    refused)
      recorded=$(transition refused_delivery "$(jq -cn --argjson r "$reconciled" '{last_result:$r}')")
      [ "$(printf '%s' "$recorded" | jq -r .status)" = ok ] || { release_lease; printf '{"ok":false,"reason":"delivery_state_conflict"}\n'; exit 0; }
      release_lease; jq -cn --arg unit "$UNIT" --argjson delivery "$reconciled" '{ok:false,unit:$unit,catchup:null,delivery:$delivery,reason:($delivery.reason//"delivery_refused")}'; exit 0;;
    *) release_lease; jq -cn --arg unit "$UNIT" --argjson delivery "$reconciled" '{ok:false,unit:$unit,catchup:null,delivery:$delivery,reason:"merge_unknown"}'; exit 0;;
  esac
fi

if [ "$phase" = not_ready ]; then
  catchup=$(sh "$SCRIPT_DIR/catch-up-claim.sh" "$UNIT" 2>/dev/null || true)
  outcome=$(printf '%s' "$catchup" | jq -r '.outcome // empty' 2>/dev/null || true)
  case "$outcome" in
    catch_up_refused) transition refused_delivery "$(jq -cn --argjson r "${catchup:-null}" '{last_result:$r}')" >/dev/null; release_lease; jq -cn --arg unit "$UNIT" --argjson catchup "${catchup:-null}" '{ok:false,unit:$unit,catchup:$catchup,delivery:null,reason:"catch_up_refused"}'; exit 0;;
    caught_up) own_tip=--own-tip ;;
    already_current) own_tip='' ;;
    *) release_lease; jq -cn --arg unit "$UNIT" --arg raw "$catchup" '{ok:false,unit:$unit,catchup:null,delivery:null,reason:"catch_up_unreadable",detail:$raw}'; exit 0;;
  esac
  moved=$(transition waiting_checks "$(jq -cn --argjson c "$catchup" --argjson own "$( [ "$own_tip" = --own-tip ] && printf true || printf false )" '{catchup:$c,own_tip:$own}')")
  [ "$(printf '%s' "$moved" | jq -r .status)" = ok ] || { release_lease; jq -cn --arg unit "$UNIT" '{ok:false,unit:$unit,catchup:null,delivery:null,reason:"delivery_state_conflict"}'; exit 0; }
else
  own_tip=$(printf '%s' "$current" | jq -r 'if .data.record.data.own_tip==true then "--own-tip" else "" end')
fi

prepared=$(sh "$SCRIPT_DIR/retry-undelivered.sh" "$UNIT" ${own_tip:+$own_tip} --prepare-only 2>/dev/null || true)
prepared_outcome=$(printf '%s' "$prepared" | jq -r '.outcome // empty' 2>/dev/null || true)
if [ "$prepared_outcome" != ready ]; then
  reason=$(printf '%s' "$prepared" | jq -r '.merge_reason // empty')
  [ -n "$reason" ] || reason=$(printf '%s' "$prepared" | jq -r '.reason // "delivery_unreadable"')
  if [ "$reason" != checks_pending ]; then transition refused_delivery "$(jq -cn --argjson r "${prepared:-null}" '{last_result:$r}')" >/dev/null; fi
  release_lease
  shown_reason=$( [ "$reason" = checks_pending ] && printf waiting_checks || printf '%s' "$reason" )
  jq -cn --arg unit "$UNIT" --argjson catchup "$catchup" --argjson delivery "${prepared:-null}" --arg reason "$shown_reason" '{ok:false,unit:$unit,catchup:$catchup,delivery:$delivery,reason:$reason}'
  exit 0
fi

merge_request=$(printf '%s' "$prepared" | jq -c .merge_request)
if [ "$phase" != ready ]; then
  moved=$(transition ready "$(jq -cn --argjson m "$merge_request" '{merge_request:$m}')")
  [ "$(printf '%s' "$moved" | jq -r .status)" = ok ] || { release_lease; jq -cn --arg unit "$UNIT" '{ok:false,unit:$unit,catchup:null,delivery:null,reason:"delivery_state_conflict"}'; exit 0; }
fi
moved=$(transition merging '{}')
[ "$(printf '%s' "$moved" | jq -r .status)" = ok ] || { release_lease; jq -cn --arg unit "$UNIT" '{ok:false,unit:$unit,catchup:null,delivery:null,reason:"delivery_state_conflict"}'; exit 0; }
printf '%s\n' "$merge_request" >"$TMP/merge.json"
merged=$(sh "$MERGE_PULL" --request "$TMP/merge.json" 2>/dev/null || printf '{"status":"unknown","reason":"merge_effect_unconfirmed"}')
case "$(printf '%s' "$merged" | jq -r '.status // "unknown"')" in
  merged) event=merged; ok=true; reason='' ;;
  refused) event=refused_delivery; ok=false; reason=$(printf '%s' "$merged" | jq -r '.reason // "merge_refused"') ;;
  *) event=unknown_delivery; ok=false; reason=merge_unknown ;;
esac
recorded=$(transition "$event" "$(jq -cn --argjson r "$merged" '{last_result:$r}')")
state_written=$( [ "$(printf '%s' "$recorded" | jq -r .status)" = ok ] && printf true || printf false )
release_lease
jq -cn --argjson ok "$ok" --argjson state_written "$state_written" --arg unit "$UNIT" --argjson catchup "$catchup" --argjson delivery "$merged" --arg reason "$reason" '{ok:$ok,unit:$unit,catchup:$catchup,delivery:$delivery,state_written:$state_written,reason:$reason}'
