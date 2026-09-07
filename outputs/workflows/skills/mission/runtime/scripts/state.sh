#!/bin/sh -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"

ACTION=${1:-}; [ -n "$ACTION" ] || runtime_usage "state action is required"; shift
SCOPE="" ID="" RECORD=meta EXPECTED="" INPUT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --scope) SCOPE=${2:-}; shift 2 ;;
        --id) ID=${2:-}; shift 2 ;;
        --record) RECORD=${2:-}; shift 2 ;;
        --expected-revision) EXPECTED=${2:-}; shift 2 ;;
        --input) INPUT=${2:-}; shift 2 ;;
        *) runtime_usage "unknown state argument: $1" ;;
    esac
done
case "$ACTION" in read|create|update|transition) ;; *) runtime_usage "unknown state action" ;; esac
case "$SCOPE" in binding|instance|publication|snapshot) ;; *) runtime_usage "invalid scope" ;; esac
case "$ID" in ''|*[!A-Za-z0-9._-]*|.|..) runtime_usage "invalid id" ;; esac
case "$RECORD" in
    meta) ;;
    inbox/*|outbox/*) [ "$SCOPE" = binding ] || runtime_usage "record is invalid for scope" ;;
    worker/*|delivery/*) [ "$SCOPE" = instance ] || runtime_usage "record is invalid for scope" ;;
    *) runtime_usage "invalid record" ;;
esac
record_id=${RECORD#*/}
case "$RECORD" in */*) case "$record_id" in ''|*[!A-Za-z0-9._-]*|.|..) runtime_usage "invalid record id" ;; esac ;; esac
case "$EXPECTED" in '') ;; *[!0-9]*) runtime_usage "expected revision must be an integer" ;; esac

COMMON=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || runtime_usage "not inside a git repository"
case "$SCOPE" in binding) PLURAL=bindings;; instance) PLURAL=instances;; publication) PLURAL=publications;; snapshot) PLURAL=snapshots;; esac
BASE="${COMMON}/workaholic/runtime/v1"
PATHNAME="${BASE}/${PLURAL}/${ID}/${RECORD}.json"
REQUEST="state-${ACTION}-${SCOPE}-${ID}"

if [ "$ACTION" = read ]; then
    if [ ! -f "$PATHNAME" ]; then runtime_json_result ok "" "$REQUEST" '{"found":false}'; exit 0; fi
    value=$(jq -c 'select(.schema_version == 1 and (.revision|type=="number") and (.generation|type=="number") and has("owner") and (.data|type=="object"))' "$PATHNAME" 2>/dev/null || true)
    if [ -z "$value" ]; then runtime_json_result error state_unreadable "$REQUEST" '{"found":true}'; exit 0; fi
    runtime_json_result ok "" "$REQUEST" "$(jq -cn --arg p "$PATHNAME" --argjson v "$value" '{found:true,path:$p,record:$v}')"
    exit 0
fi

runtime_require_json_file "$INPUT"
case "$ACTION" in update|transition) [ -n "$EXPECTED" ] || runtime_usage "--expected-revision is required" ;; esac

lock_name=$(printf '%s' "${PLURAL}.${ID}.${RECORD}" | tr '/' '.')
LOCK="${BASE}/locks/${lock_name}.lock"
mkdir -p "${BASE}/locks"
tries=0
while ! mkdir "$LOCK" 2>/dev/null; do
    tries=$((tries + 1)); [ "$tries" -lt 200 ] || { runtime_json_result deferred lock_busy "$REQUEST" '{}'; exit 0; }
    sleep 0.01
done
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT HUP INT TERM

defer_conflict() {
    actual=null
    [ ! -f "$PATHNAME" ] || actual=$(jq -r '.revision // "null"' "$PATHNAME" 2>/dev/null || printf null)
    runtime_json_result deferred revision_conflict "$REQUEST" "$(jq -cn --argjson expected "${EXPECTED:-null}" --argjson actual "$actual" '{expected_revision:$expected,actual_revision:$actual}')"
    exit 0
}

# Child records are writable only by the current scope lease. The check occurs
# under the child lock and the meta writer uses its own lock; a stale generation
# can never complete after release/reacquire or takeover.
if [ "$RECORD" != meta ]; then
    META="${BASE}/${PLURAL}/${ID}/meta.json"
    [ -f "$META" ] || { runtime_json_result deferred lease_missing "$REQUEST" '{}'; exit 0; }
    lease_owner=$(jq -c '.owner // null' "$META" 2>/dev/null || printf null)
    lease_generation=$(jq -r '.generation // 0' "$META" 2>/dev/null || printf 0)
    input_owner=$(jq -c '.owner // null' "$INPUT")
    input_generation=$(jq -r '.generation // 0' "$INPUT")
    [ "$lease_owner" != null ] && [ "$input_owner" = "$lease_owner" ] && [ "$input_generation" = "$lease_generation" ] \
        || { runtime_json_result deferred stale_generation "$REQUEST" '{}'; exit 0; }
fi

if [ "$ACTION" = create ]; then
    [ ! -e "$PATHNAME" ] || defer_conflict
    now=$(jq -r '.updated_at // .now // empty' "$INPUT"); [ -n "$now" ] || runtime_usage "create input requires updated_at"
    owner=$(jq -c '.owner // null' "$INPUT"); data=$(jq -c '.data // {}' "$INPUT")
    printf '%s' "$owner" | jq -e '. == null or (type=="object" and (.instance_id|type=="string" and length>0) and (.nonce|type=="string" and length>0) and (((.harness_receipt? // "")|type=="string" and length>0) or (has("process_id") and (.boot_id|type=="string" and length>0))))' >/dev/null 2>&1 || runtime_usage "owner requires instance_id, nonce, and process/boot or harness evidence"
    value=$(jq -cn --arg now "$now" --argjson owner "$owner" --argjson data "$data" '{schema_version:1,revision:1,owner:$owner,generation:1,updated_at:$now,data:$data}')
else
    [ -f "$PATHNAME" ] || defer_conflict
    old=$(jq -c 'select(.schema_version == 1 and (.revision|type=="number") and (.generation|type=="number") and has("owner") and (.data|type=="object"))' "$PATHNAME" 2>/dev/null || true)
    [ -n "$old" ] || { runtime_json_result error state_unreadable "$REQUEST" '{}'; exit 0; }
    actual=$(printf '%s' "$old" | jq -r .revision); [ "$actual" = "$EXPECTED" ] || defer_conflict
    now=$(jq -r '.updated_at // .now // empty' "$INPUT"); [ -n "$now" ] || runtime_usage "$ACTION input requires updated_at"
    if [ "$ACTION" = update ]; then
        jq -e '((has("owner") or has("generation")) | not) and (.data|type=="object")' "$INPUT" >/dev/null 2>&1 || runtime_usage "update cannot replace owner or generation"
        data=$(jq -c .data "$INPUT")
        value=$(printf '%s' "$old" | jq -c --arg now "$now" --argjson data "$data" '.revision += 1 | .updated_at=$now | .data=$data')
    else
        event=$(jq -r '.event // empty' "$INPUT"); requested_owner=$(jq -c '.owner // null' "$INPUT"); requested_generation=$(jq -r '.generation // 0' "$INPUT")
        old_owner=$(printf '%s' "$old" | jq -c .owner); old_generation=$(printf '%s' "$old" | jq -r .generation)
        case "$event" in
            acquire)
                [ "$old_owner" = null ] || { runtime_json_result deferred lease_held "$REQUEST" '{}'; exit 0; }
                printf '%s' "$requested_owner" | jq -e 'type=="object" and (.instance_id|type=="string" and length>0) and (.nonce|type=="string" and length>0) and (((.harness_receipt? // "")|type=="string" and length>0) or (has("process_id") and (.boot_id|type=="string" and length>0)))' >/dev/null 2>&1 || runtime_usage "acquire requires an evidenced owner"
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --argjson owner "$requested_owner" '.revision += 1 | .generation += 1 | .owner=$owner | .updated_at=$now | .data.lease_status="acquired"') ;;
            renew|release)
                [ "$requested_owner" = "$old_owner" ] && [ "$requested_generation" = "$old_generation" ] || { runtime_json_result deferred stale_generation "$REQUEST" '{}'; exit 0; }
                if [ "$event" = renew ]; then value=$(printf '%s' "$old" | jq -c --arg now "$now" '.revision += 1 | .updated_at=$now | .data.lease_status="acquired"');
                else value=$(printf '%s' "$old" | jq -c --arg now "$now" '.revision += 1 | .owner=null | .updated_at=$now | .data.lease_status="released"'); fi ;;
            takeover)
                jq -e '.expired == true and .old_owner_ended == true and (.old_owner_evidence|type=="object" and length>0) and (.owner|type=="object")' "$INPUT" >/dev/null 2>&1 || { runtime_json_result deferred takeover_unproved "$REQUEST" '{}'; exit 0; }
                printf '%s' "$requested_owner" | jq -e '(.instance_id|type=="string" and length>0) and (.nonce|type=="string" and length>0) and (((.harness_receipt? // "")|type=="string" and length>0) or (has("process_id") and (.boot_id|type=="string" and length>0)))' >/dev/null 2>&1 || runtime_usage "takeover requires an evidenced owner"
                evidence=$(jq -c .old_owner_evidence "$INPUT")
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --argjson owner "$requested_owner" --argjson evidence "$evidence" '.revision += 1 | .generation += 1 | .owner=$owner | .updated_at=$now | .data.lease_status="acquired" | .data.takeover_evidence=$evidence | if .data.external_effect == "sending" then .data.external_effect="unknown" else . end') ;;
            captured|accepted|completed)
                case "$RECORD:$event" in inbox/*:captured|inbox/*:accepted|inbox/*:completed) ;; *) runtime_usage "invalid inbox transition" ;; esac
                current=$(printf '%s' "$old" | jq -r '.data.state // ""'); case "$current:$event" in ':captured'|captured:accepted|accepted:completed) ;; *) runtime_json_result deferred invalid_transition "$REQUEST" '{}'; exit 0;; esac
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --arg e "$event" '.revision += 1 | .updated_at=$now | .data.state=$e') ;;
            planned|sending|confirmed|unknown|refused)
                case "$RECORD" in outbox/*) ;; *) runtime_usage "invalid outbox transition" ;; esac
                current=$(printf '%s' "$old" | jq -r '.data.state // ""'); case "$current:$event" in ':planned'|planned:sending|sending:confirmed|sending:unknown|planned:refused|sending:refused|unknown:confirmed|unknown:refused) ;; *) runtime_json_result deferred invalid_transition "$REQUEST" '{}'; exit 0;; esac
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --arg e "$event" '.revision += 1 | .updated_at=$now | .data.state=$e') ;;
            not_ready|waiting_checks|ready|merging|merged|unknown_delivery|refused_delivery)
                case "$RECORD" in delivery/*) ;; *) runtime_usage "invalid delivery transition" ;; esac
                mapped=$event; [ "$event" != unknown_delivery ] || mapped=unknown; [ "$event" != refused_delivery ] || mapped=refused
                current=$(printf '%s' "$old" | jq -r '.data.state // ""'); case "$current:$mapped" in ':not_ready'|not_ready:waiting_checks|waiting_checks:ready|ready:merging|merging:merged|merging:unknown|*:refused) ;; *) runtime_json_result deferred invalid_transition "$REQUEST" '{}'; exit 0;; esac
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --arg e "$mapped" '.revision += 1 | .updated_at=$now | .data.state=$e') ;;
            *) runtime_usage "unknown transition event" ;;
        esac
        # A transition may attach evidence produced by the effect it records
        # (for example the provider ts that confirms an outbox send). The state
        # machine still owns the finite state change above; callers can only
        # merge data, never replace revision/owner/generation through it.
        transition_data=$(jq -c '.data // {}' "$INPUT")
        value=$(printf '%s' "$value" | jq -c --argjson extra "$transition_data" '.data += $extra')
    fi
fi

printf '%s' "$value" | jq -e 'type=="object" and .schema_version==1 and (.revision|type=="number") and (.generation|type=="number") and (.data|type=="object")' >/dev/null 2>&1 || { runtime_json_result error state_invalid "$REQUEST" '{}'; exit 0; }
mkdir -p "$(dirname -- "$PATHNAME")"
TMP="${PATHNAME}.tmp.$$"
printf '%s\n' "$value" >"$TMP"
mv -f "$TMP" "$PATHNAME"
runtime_json_result ok "" "$REQUEST" "$(jq -cn --arg p "$PATHNAME" --argjson v "$value" '{path:$p,record:$v}')"
