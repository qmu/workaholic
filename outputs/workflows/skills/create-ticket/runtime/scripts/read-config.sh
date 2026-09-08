#!/bin/sh -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"

ROOT="" INPUT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT=${2:-}; shift 2 ;;
        --input) INPUT=${2:-}; shift 2 ;;
        *) runtime_usage "usage: read-config.sh --root REPO [--input FILE]" ;;
    esac
done
[ -n "$ROOT" ] && [ -d "$ROOT" ] || runtime_usage "--root must be a directory"
ROOT=$(CDPATH='' cd -- "$ROOT" && pwd)
if [ -n "$INPUT" ]; then runtime_require_json_file "$INPUT"; else INPUT=/dev/null; fi

PROFILE=${WORKAHOLIC_PROFILE:-default}
CONFIG="${ROOT}/workaholic.config.json"
LEGACY="${ROOT}/.claude/settings.json"
[ ! -f "$CONFIG" ] || jq -e '.schema_version == 1 and (.profiles | type == "object")' "$CONFIG" >/dev/null 2>&1 \
    || runtime_usage "workaholic.config.json is invalid"
[ ! -f "$LEGACY" ] || jq -e 'type == "object"' "$LEGACY" >/dev/null 2>&1 \
    || runtime_usage ".claude/settings.json is invalid"

cfg='{}'; [ ! -f "$CONFIG" ] || cfg=$(cat "$CONFIG")
old='{}'; [ ! -f "$LEGACY" ] || old=$(cat "$LEGACY")
explicit='{}'; [ "$INPUT" = /dev/null ] || explicit=$(cat "$INPUT")

# Only these non-secret settings cross the legacy/environment boundary.
env_interval=${WORKAHOLIC_POLL_INTERVAL_SECONDS-}
env_mode=${WORKAHOLIC_POLL_MODE-}
env_max=${WORKAHOLIC_PROPOSE_MAX-}

jq -cn \
    --arg request read-config --arg root "$ROOT" --arg profile "$PROFILE" \
    --arg input "$INPUT" --argjson cfg "$cfg" --argjson old "$old" --argjson explicit "$explicit" \
    --arg env_interval "$env_interval" --arg env_mode "$env_mode" --arg env_max "$env_max" '
  def allowed:
    (type=="object") and all(keys[]; .=="polling" or .=="target" or .=="limits")
    and ((.polling? // {}) | type=="object" and all(keys[]; .=="mode" or .=="interval_seconds" or .=="conversation_seconds" or .=="idle_seconds" or .=="max_seconds"))
    and ((.limits? // {}) | type=="object" and all(keys[]; .=="propose_max"))
    and ((.target? // {}) | type=="object" and all(keys[]; .=="workspace_id" or .=="channel_id" or .=="qfs" or .=="allowed_sender_ids" or .=="identity_policy"));
  ($cfg.profiles[$profile] // {}) as $selected
  | ($old.env // {}) as $legacy_env
  | {polling:{mode:"adaptive",interval_seconds:300,conversation_seconds:30,idle_seconds:300,max_seconds:900},target:null,limits:{propose_max:null}} as $defaults
  | if (($selected|allowed) and ($explicit|allowed)) then . else error("unknown configuration key") end
  | ($defaults
      | if ($legacy_env.WORKAHOLIC_POLL_MODE? != null) then .polling.mode=$legacy_env.WORKAHOLIC_POLL_MODE else . end
      | if ($legacy_env.WORKAHOLIC_POLL_INTERVAL_SECONDS? != null) then .polling.interval_seconds=($legacy_env.WORKAHOLIC_POLL_INTERVAL_SECONDS|tonumber) else . end
      | if ($legacy_env.WORKAHOLIC_POLL_INTERVAL_SECONDS? != null and $legacy_env.WORKAHOLIC_POLL_MODE? == null) then .polling.mode="fixed" else . end
      | if ($legacy_env.WORKAHOLIC_PROPOSE_MAX? != null) then .limits.propose_max=($legacy_env.WORKAHOLIC_PROPOSE_MAX|tonumber) else . end
      | . * $selected
      | if ($selected.polling.interval_seconds? != null and $selected.polling.mode? == null) then .polling.mode="fixed" else . end
      | if $env_mode != "" then .polling.mode=$env_mode else . end
      | if $env_interval != "" then .polling.interval_seconds=($env_interval|tonumber) else . end
      | if ($env_interval != "" and $env_mode == "") then .polling.mode="fixed" else . end
      | if $env_max != "" then .limits.propose_max=($env_max|tonumber) else . end
      | . * $explicit
      | if ($explicit.polling.interval_seconds? != null and $explicit.polling.mode? == null) then .polling.mode="fixed" else . end) as $resolved
  | {protocol:"workaholic.runtime/v1",request_id:$request,status:"ok",reason:"",
     data:{schema_version:1,repo_root:$root,profile:$profile,config:$resolved,
       sources:{explicit:($input != "/dev/null"),environment:{polling_mode:($env_mode != ""),polling_interval_seconds:($env_interval != ""),propose_max:($env_max != "")},profile:($selected != {}),legacy:($legacy_env != {})}}}' \
    2>/dev/null || runtime_usage "configuration values have invalid types"
