#!/bin/sh -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
. "${SCRIPT_DIR}/lib/lock.sh"

# EVERY UNBOUNDED VALUE TRAVELS BY FILE, NEVER BY `argv` (2026-09-19, ticket
# `20260919120809`). The record is rewritten in full on every event, so `state.sh`
# composes the new value from the old one -- and Linux caps ONE argument at
# MAX_ARG_STRLEN (32 x PAGE_SIZE: 131072 bytes on a 4 KiB page, NOT the far larger
# ARG_MAX). Past that cap every `--arg`/`--argjson` carrying a record or a data block
# answered `E2BIG`, and each of the three sites failed differently and silently:
# the composition left the value empty and the shape assertion answered `state_invalid`
# (the wrong word, nothing written); the success render failed AFTER the record had
# landed on disk, exiting 2 with EMPTY stdout while the revision had advanced -- so a
# caller retried a write that had succeeded and got `revision_conflict` against itself;
# and the READ render failed the same way, so `coordinator.sh` read an empty file and
# every coordinator event answered with total silence carrying no reason word.
#
# The ceiling below is a DECLARED POLICY bound, not a platform one, and it gates
# WRITES ONLY: a record already on disk is always read back, which is what lets an
# oversized legacy record be rescued rather than bricked.
RECORD_MAX_BYTES=1048576

SCRATCH=""
scratch_dir() {
    [ -n "$SCRATCH" ] || SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/workaholic-state.$$.XXXXXX") || return 1
    printf '%s' "$SCRATCH"
}
scratch_clean() { [ -z "$SCRATCH" ] || rm -rf "$SCRATCH" 2>/dev/null || true; }
# Registered before anything can write into it, and carried into every later trap so a
# payload file never escapes the cleanup (the lock traps below re-declare it).
trap 'scratch_clean' EXIT HUP INT TERM
scratch_path() { _sp_dir=$(scratch_dir) || return 1; printf '%s/%s.json' "$_sp_dir" "$1"; }
# `>|` rather than `>`: under `noclobber` a bare redirect onto an existing path writes
# NOTHING and the caller reads a stale file (`rules/shell.md`).
scratch_write() {
    _sw_path=$(scratch_path "$1") || return 1
    printf '%s' "$2" >| "$_sw_path" || return 1
    [ -s "$_sw_path" ] || return 1
    printf '%s' "$_sw_path"
}

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

# A composition or a write that could not run answers by its own name. `state_invalid`
# is retained for exactly what it says -- a composed value that failed the shape
# assertion -- and is not widened; `state_unreadable` already meant *this record could
# not be read* and now covers the render that could not be made either.
read_unreadable() {
    runtime_json_result error state_unreadable "$REQUEST" "$(jq -cn --arg d "${1:-}" '{found:true,detail:$d}')"
    exit 0
}
write_failed() {
    runtime_json_result error state_write_failed "$REQUEST" "$(jq -cn --arg s "${1:-}" '{step:$s}')"
    exit 0
}

if [ "$ACTION" = read ]; then
    if [ ! -f "$PATHNAME" ]; then runtime_json_result ok "" "$REQUEST" '{"found":false}'; exit 0; fi
    value=$(jq -c 'select(.schema_version == 1 and (.revision|type=="number") and (.generation|type=="number") and has("owner") and (.data|type=="object"))' "$PATHNAME" 2>/dev/null || true)
    if [ -z "$value" ]; then runtime_json_result error state_unreadable "$REQUEST" '{"found":true}'; exit 0; fi
    # The file on disk IS the value the select above validated, so it is slurped
    # straight into the program: no size of record can reach `argv` from here.
    read_data=$(scratch_path read-data) || read_unreadable scratch_unavailable
    jq -cn --arg p "$PATHNAME" --slurpfile v "$PATHNAME" \
        '($v[0] // null) as $r
         | if ($r|type) != "object" then error("record unreadable") else {found:true,path:$p,record:$r} end' \
        >| "$read_data" 2>/dev/null || read_unreadable render_failed
    runtime_json_result_file ok "" "$REQUEST" "$read_data" || read_unreadable render_failed
    exit 0
fi

runtime_require_json_file "$INPUT"
case "$ACTION" in update|transition) [ -n "$EXPECTED" ] || runtime_usage "--expected-revision is required" ;; esac

# One scope lock fences the lease metadata and every child record together. A child
# therefore cannot pass a generation check while a concurrent release/takeover moves
# the scope to another generation.
lock_name=$(printf '%s' "${PLURAL}.${ID}" | tr '/' '.')
LOCK="${BASE}/locks/${lock_name}.lock"
mkdir -p "${BASE}/locks"
LOCK_GUARD="${LOCK}.guard"
# The stable advisory-lock inode serializes both stale-owner reclamation and the
# protected write. Without this outer guard, two reclaimers can both validate the
# same dead JSON lock: one removes it and installs a live replacement, then the
# other removes that replacement using its stale check. flock releases on process
# death, while the JSON owner record retains the evidence needed after a crash.
runtime_lock_acquire "$LOCK_GUARD" 9 true || { runtime_json_result deferred lock_busy "$REQUEST" '{}'; exit 0; }
boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || printf unknown)
process_start=$(awk '{print $22}' "/proc/$$/stat" 2>/dev/null || printf unknown)
lock_candidate="${BASE}/locks/.${lock_name}.$$.$process_start"
jq -cn --argjson pid "$$" --arg boot "$boot_id" --arg start "$process_start" \
  '{pid:$pid,boot_id:$boot,process_start:$start}' >"$lock_candidate"
trap 'rm -f "$lock_candidate"; runtime_lock_release; scratch_clean' EXIT HUP INT TERM
if ! ln "$lock_candidate" "$LOCK" 2>/dev/null; then
    # Reclaim only with process evidence. On another boot the recorded process is
    # necessarily gone; on this boot both PID and /proc start time must still match.
    observed=$(cat "$LOCK" 2>/dev/null || printf '')
    old_pid=$(printf '%s' "$observed" | jq -r '.pid // empty' 2>/dev/null || printf '')
    old_boot=$(printf '%s' "$observed" | jq -r '.boot_id // empty' 2>/dev/null || printf '')
    old_start=$(printf '%s' "$observed" | jq -r '.process_start // empty' 2>/dev/null || printf '')
    owner_alive=unknown
    if [ -n "$old_pid" ] && [ -n "$old_boot" ] && [ -n "$old_start" ] && [ "$boot_id" != unknown ]; then
        if [ "$old_boot" != "$boot_id" ]; then owner_alive=false
        elif [ -r "/proc/${old_pid}/stat" ]; then
            live_start=$(awk '{print $22}' "/proc/${old_pid}/stat" 2>/dev/null || printf '')
            if [ "$live_start" = "$old_start" ]; then owner_alive=true; else owner_alive=false; fi
        else owner_alive=false
        fi
    fi
    if [ "$owner_alive" = false ] && [ "$(cat "$LOCK" 2>/dev/null || printf '')" = "$observed" ]; then
        rm -f "$LOCK" 2>/dev/null || true
        ln "$lock_candidate" "$LOCK" 2>/dev/null || { runtime_json_result deferred lock_busy "$REQUEST" '{}'; exit 0; }
    else
        runtime_json_result deferred lock_busy "$REQUEST" '{}'
        exit 0
    fi
fi
trap 'rm -f "$LOCK" "$lock_candidate" 2>/dev/null || true; runtime_lock_release; scratch_clean' EXIT HUP INT TERM

defer_conflict() {
    actual=null
    [ ! -f "$PATHNAME" ] || actual=$(jq -r '.revision // "null"' "$PATHNAME" 2>/dev/null || printf null)
    runtime_json_result deferred revision_conflict "$REQUEST" "$(jq -cn --argjson expected "${EXPECTED:-null}" --argjson actual "$actual" '{expected_revision:$expected,actual_revision:$actual}')"
    exit 0
}

# Child records are writable only by the current scope lease. The check occurs
# under the shared scope lock, so a stale generation cannot complete after
# release/reacquire or takeover.
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

# The composed record lives in a FILE from here to the write, so no size of record
# reaches `argv` on the way to disk or on the way back to the caller.
VALUE_FILE=$(scratch_path value) || write_failed scratch_unavailable

if [ "$ACTION" = create ]; then
    [ ! -e "$PATHNAME" ] || defer_conflict
    now=$(jq -r '.updated_at // .now // empty' "$INPUT"); [ -n "$now" ] || runtime_usage "create input requires updated_at"
    owner=$(jq -c '.owner // null' "$INPUT"); data=$(jq -c '.data // {}' "$INPUT")
    printf '%s' "$owner" | jq -e '. == null or (type=="object" and (.instance_id|type=="string" and length>0) and (.nonce|type=="string" and length>0) and (((.harness_receipt? // "")|type=="string" and length>0) or (has("process_id") and (.boot_id|type=="string" and length>0))))' >/dev/null 2>&1 || runtime_usage "owner requires instance_id, nonce, and process/boot or harness evidence"
    data_file=$(scratch_write create-data "$data") || write_failed stage_data
    owner_file=$(scratch_write create-owner "$owner") || write_failed stage_owner
    # `--slurpfile` slurps a STREAM into an array, so the program indexes `[0]` and
    # refuses a file that came back EMPTY -- which would otherwise compose a null
    # `.data` silently. A payload that is present and not an object is the CALLER'S
    # malformed input and is carried through verbatim, so the shape assertion below
    # still answers `state_invalid` for it exactly as it always did.
    jq -cn --arg now "$now" --slurpfile owner "$owner_file" --slurpfile data "$data_file" \
      'if ($data|length) == 0 or ($owner|length) == 0 then error("payload did not survive staging")
       else {schema_version:1,revision:1,owner:$owner[0],generation:1,updated_at:$now,data:$data[0]} end' \
      >| "$VALUE_FILE" 2>/dev/null || write_failed compose_create
else
    [ -f "$PATHNAME" ] || defer_conflict
    old=$(jq -c 'select(.schema_version == 1 and (.revision|type=="number") and (.generation|type=="number") and has("owner") and (.data|type=="object"))' "$PATHNAME" 2>/dev/null || true)
    [ -n "$old" ] || { runtime_json_result error state_unreadable "$REQUEST" '{}'; exit 0; }
    actual=$(printf '%s' "$old" | jq -r .revision); [ "$actual" = "$EXPECTED" ] || defer_conflict
    now=$(jq -r '.updated_at // .now // empty' "$INPUT"); [ -n "$now" ] || runtime_usage "$ACTION input requires updated_at"
    if [ "$ACTION" = update ]; then
        if [ "$RECORD" = meta ]; then
            jq -e '((has("owner") or has("generation")) | not) and (.data|type=="object")' "$INPUT" >/dev/null 2>&1 || runtime_usage "update cannot replace owner or generation"
        else
            jq -e '(.data|type=="object")' "$INPUT" >/dev/null 2>&1 || runtime_usage "child update requires data"
        fi
        data=$(jq -c .data "$INPUT")
        data_file=$(scratch_write update-data "$data") || write_failed stage_data
        printf '%s' "$old" | jq -c --arg now "$now" --slurpfile data "$data_file" \
          'if ($data|length) == 0 then error("data payload did not survive staging")
           else (.revision += 1 | .updated_at=$now | .data=$data[0]) end' \
          >| "$VALUE_FILE" 2>/dev/null || write_failed compose_update
    else
        event=$(jq -r '.event // empty' "$INPUT"); requested_owner=$(jq -c '.owner // null' "$INPUT"); requested_generation=$(jq -r '.generation // 0' "$INPUT")
        old_owner=$(printf '%s' "$old" | jq -c .owner); old_generation=$(printf '%s' "$old" | jq -r .generation)
        case "$event" in
            acquire)
                [ "$old_owner" = null ] || { runtime_json_result deferred lease_held "$REQUEST" '{}'; exit 0; }
                printf '%s' "$requested_owner" | jq -e 'type=="object" and (.instance_id|type=="string" and length>0) and (.nonce|type=="string" and length>0) and (((.harness_receipt? // "")|type=="string" and length>0) or (has("process_id") and (.boot_id|type=="string" and length>0)))' >/dev/null 2>&1 || runtime_usage "acquire requires an evidenced owner"
                owner_file=$(scratch_write acquire-owner "$requested_owner") || write_failed stage_owner
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --slurpfile owner "$owner_file" '.revision += 1 | .generation += 1 | .owner=$owner[0] | .updated_at=$now | .data.lease_status="acquired"') || write_failed compose_acquire ;;
            renew|release)
                [ "$requested_owner" = "$old_owner" ] && [ "$requested_generation" = "$old_generation" ] || { runtime_json_result deferred stale_generation "$REQUEST" '{}'; exit 0; }
                if [ "$event" = renew ]; then value=$(printf '%s' "$old" | jq -c --arg now "$now" '.revision += 1 | .updated_at=$now | .data.lease_status="acquired"') || write_failed compose_renew;
                else value=$(printf '%s' "$old" | jq -c --arg now "$now" '.revision += 1 | .owner=null | .updated_at=$now | .data.lease_status="released"') || write_failed compose_release; fi ;;
            takeover)
                jq -e '.expired == true and .old_owner_ended == true and (.old_owner_evidence|type=="object" and length>0) and (.owner|type=="object")' "$INPUT" >/dev/null 2>&1 || { runtime_json_result deferred takeover_unproved "$REQUEST" '{}'; exit 0; }
                printf '%s' "$requested_owner" | jq -e '(.instance_id|type=="string" and length>0) and (.nonce|type=="string" and length>0) and (((.harness_receipt? // "")|type=="string" and length>0) or (has("process_id") and (.boot_id|type=="string" and length>0)))' >/dev/null 2>&1 || runtime_usage "takeover requires an evidenced owner"
                evidence=$(jq -c .old_owner_evidence "$INPUT")
                owner_file=$(scratch_write takeover-owner "$requested_owner") || write_failed stage_owner
                evidence_file=$(scratch_write takeover-evidence "$evidence") || write_failed stage_evidence
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --slurpfile owner "$owner_file" --slurpfile evidence "$evidence_file" '.revision += 1 | .generation += 1 | .owner=$owner[0] | .updated_at=$now | .data.lease_status="acquired" | .data.takeover_evidence=$evidence[0] | if .data.external_effect == "sending" then .data.external_effect="unknown" else . end') || write_failed compose_takeover ;;
            captured|accepted|completed)
                case "$RECORD:$event" in inbox/*:captured|inbox/*:accepted|inbox/*:completed) ;; *) runtime_usage "invalid inbox transition" ;; esac
                current=$(printf '%s' "$old" | jq -r '.data.state // ""'); case "$current:$event" in ':captured'|captured:accepted|accepted:completed) ;; *) runtime_json_result deferred invalid_transition "$REQUEST" '{}'; exit 0;; esac
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --arg e "$event" '.revision += 1 | .updated_at=$now | .data.state=$e') || write_failed compose_inbox ;;
            planned|sending|confirmed|unknown|refused)
                case "$RECORD" in outbox/*) ;; *) runtime_usage "invalid outbox transition" ;; esac
                current=$(printf '%s' "$old" | jq -r '.data.state // ""'); case "$current:$event" in ':planned'|planned:sending|sending:confirmed|sending:unknown|planned:refused|sending:refused|unknown:confirmed|unknown:refused) ;; *) runtime_json_result deferred invalid_transition "$REQUEST" '{}'; exit 0;; esac
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --arg e "$event" '.revision += 1 | .updated_at=$now | .data.state=$e') || write_failed compose_outbox ;;
            not_ready|waiting_checks|ready|merging|merged|unknown_delivery|refused_delivery)
                case "$RECORD" in delivery/*) ;; *) runtime_usage "invalid delivery transition" ;; esac
                mapped=$event; [ "$event" != unknown_delivery ] || mapped=unknown; [ "$event" != refused_delivery ] || mapped=refused
                current=$(printf '%s' "$old" | jq -r '.data.state // ""'); case "$current:$mapped" in ':not_ready'|refused:not_ready|not_ready:waiting_checks|waiting_checks:ready|ready:merging|merging:merged|merging:unknown|unknown:merged|*:refused) ;; *) runtime_json_result deferred invalid_transition "$REQUEST" '{}'; exit 0;; esac
                value=$(printf '%s' "$old" | jq -c --arg now "$now" --arg e "$mapped" '.revision += 1 | .updated_at=$now | .data.state=$e') || write_failed compose_delivery ;;
            *) runtime_usage "unknown transition event" ;;
        esac
        # A transition may attach evidence produced by the effect it records
        # (for example the provider ts that confirms an outbox send). The state
        # machine still owns the finite state change above; callers can only
        # merge data, never replace revision/owner/generation through it.
        transition_data=$(jq -c '.data // {}' "$INPUT")
        extra_file=$(scratch_write transition-data "$transition_data") || write_failed stage_transition_data
        # The arms above compose from STDIN, which has no argument cap; what they hand
        # back is staged here so the last merge and everything after it reads a file.
        base_file=$(scratch_write transition-base "$value") || write_failed stage_value
        jq -c --slurpfile extra "$extra_file" '.data += ($extra[0] // {})' "$base_file" \
          >| "$VALUE_FILE" 2>/dev/null || write_failed compose_transition
    fi
fi

[ -s "$VALUE_FILE" ] || write_failed value_absent
# The shape assertion, unchanged in meaning and deliberately NOT widened: it answers
# `state_invalid` for a composed value that is genuinely malformed, and for nothing else.
jq -e 'type=="object" and .schema_version==1 and (.revision|type=="number") and (.generation|type=="number") and (.data|type=="object")' "$VALUE_FILE" >/dev/null 2>&1 \
    || { runtime_json_result error state_invalid "$REQUEST" '{}'; exit 0; }

observed_bytes=$(wc -c < "$VALUE_FILE" 2>/dev/null | tr -d ' ') || observed_bytes=""
[ -n "$observed_bytes" ] || write_failed size_unreadable
if [ "$observed_bytes" -gt "$RECORD_MAX_BYTES" ]; then
    runtime_json_result error state_too_large "$REQUEST" \
        "$(jq -cn --argjson o "$observed_bytes" --argjson m "$RECORD_MAX_BYTES" '{observed_bytes:$o,ceiling_bytes:$m}')"
    exit 0
fi

# THE SUCCESS RESULT IS RENDERED BEFORE THE RECORD LANDS. The old order wrote first and
# rendered second, so a render that could not run left the write committed and the
# caller holding empty stdout -- it then retried and collided with its own revision.
# Rendering first means every refusal reachable here leaves the record byte-identical.
result_data=$(scratch_path result-data) || write_failed scratch_unavailable
jq -cn --arg p "$PATHNAME" --slurpfile v "$VALUE_FILE" '{path:$p,record:$v[0]}' \
    >| "$result_data" 2>/dev/null || write_failed render_result
[ -s "$result_data" ] || write_failed render_result

mkdir -p "$(dirname -- "$PATHNAME")"
TMP="${PATHNAME}.tmp.$$"
cp "$VALUE_FILE" "$TMP" || write_failed stage_record
mv -f "$TMP" "$PATHNAME" || write_failed commit_record
runtime_json_result_file ok "" "$REQUEST" "$result_data" || write_failed emit_result
