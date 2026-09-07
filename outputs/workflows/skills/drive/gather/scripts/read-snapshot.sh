#!/bin/sh -eu
# Build one evidence snapshot. The claims fetch/ref walk is materialized once and
# projected through legacy readers so their public JSON remains authoritative.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
RUNTIME_SCRIPTS="${SCRIPT_DIR}/../../runtime/scripts"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"
LOOPS_SCRIPTS="${SCRIPT_DIR}/../../loops/scripts"
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts"
BRANCHING_SCRIPTS="${SCRIPT_DIR}/../../branching/scripts"
. "${RUNTIME_SCRIPTS}/lib/result.sh"

INPUT="" PREVIOUS=""
while [ $# -gt 0 ]; do
    case "$1" in --input) INPUT=${2:-}; shift 2;; --previous) PREVIOUS=${2:-}; shift 2;; *) runtime_usage "invalid read-snapshot argument";; esac
done
runtime_require_json_file "$INPUT"
jq -e '(.repo_root|type=="string") and (.now|type=="string") and (.config|type=="object") and has("identity")
  and ([.config | .. | objects | keys[]] | all(test("token|secret|password|credential";"i")|not))' "$INPUT" >/dev/null 2>&1 || runtime_usage "snapshot input requires safe repo_root, now, config, and identity"
if [ -n "$PREVIOUS" ]; then runtime_require_json_file "$PREVIOUS"; fi

ROOT=$(jq -r .repo_root "$INPUT"); [ -d "$ROOT" ] || runtime_usage "repo_root is not a directory"
ROOT=$(CDPATH='' cd -- "$ROOT" && pwd)
cd "$ROOT"
COMMON=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || runtime_usage "repo_root is not a git repository"
NOW=$(jq -r .now "$INPUT")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM

sh "${DRIVE_SCRIPTS}/observe-claims.sh" >"$tmp/claims-observation.json" || { runtime_json_result error claims_unreadable read-snapshot '{}'; exit 0; }
sh "${SCRIPT_DIR}/../../mission/scripts/read-corpus.sh" "$ROOT/.workaholic" >"$tmp/corpus.json" || { runtime_json_result error corpus_unreadable read-snapshot '{}'; exit 0; }
sh "${DRIVE_SCRIPTS}/list-claims.sh" --observation "$tmp/claims-observation.json" >"$tmp/claims.json" || { runtime_json_result error claims_unreadable read-snapshot '{}'; exit 0; }
sh "${DRIVE_SCRIPTS}/plan-units.sh" --claims-observation "$tmp/claims-observation.json" --corpus "$tmp/corpus.json" >"$tmp/survey.json" || { runtime_json_result error survey_unreadable read-snapshot '{}'; exit 0; }

# Recovery is a projection of the claims already observed. Publication recovery is
# read once and remains unknown if that independent reader is unavailable.
jq '[.claims[]? | select((.resume_reason=="report_undelivered" or .resume_reason=="queue_drained" or .resume_reason=="awaiting_verification") and (.mergeability=="mechanical" or .mergeability=="content")) | .unit] | unique' "$tmp/claims.json" >"$tmp/recovery-units.json"
stranded=null
if [ -x "$BRANCHING_SCRIPTS/list-stranded-publications.sh" ]; then
    if sh "$BRANCHING_SCRIPTS/list-stranded-publications.sh" >"$tmp/stranded.json" 2>/dev/null && jq -e '.ok==true' "$tmp/stranded.json" >/dev/null 2>&1; then
        stranded=$(jq '[.publications[]? | select(.mergeability=="clean" or .mergeability=="mechanical" or .mergeability=="content")] | length' "$tmp/stranded.json")
    fi
fi
if [ "$stranded" = null ]; then
    recovery_readable=false
    printf '{"units":[],"stranded":0}\n' >"$tmp/recovery.json"
else
    recovery_readable=true
    jq -cn --slurpfile units "$tmp/recovery-units.json" --argjson stranded "$stranded" '{units:$units[0],stranded:$stranded}' >"$tmp/recovery.json"
fi
sh "$LOOPS_SCRIPTS/claimable-units.sh" --survey "$tmp/survey.json" --recovery "$tmp/recovery.json" >"$tmp/claimable.json" || true

if [ -x "$STRATEGY_SCRIPTS/list.sh" ]; then sh "$STRATEGY_SCRIPTS/list.sh" "$ROOT/.workaholic" >"$tmp/strategies-legacy.json" 2>/dev/null || printf '{"count":null,"strategies":[],"readable":false,"reason":"strategy_unreadable"}\n' >"$tmp/strategies-legacy.json";
else printf '{"count":null,"strategies":[],"readable":false,"reason":"strategy_unreadable"}\n' >"$tmp/strategies-legacy.json"; fi
sh "$STRATEGY_SCRIPTS/normalize.sh" --input "$tmp/strategies-legacy.json" >"$tmp/strategies.json" || { runtime_json_result error strategy_unreadable read-snapshot '{}'; exit 0; }

HEAD_SHA=$(git rev-parse HEAD)
BASE_SHA=$(jq -r .base_sha "$tmp/claims-observation.json")
# Hash object ids and status records, never raw content. Credential-shaped paths
# are excluded from content hashing; runtime configuration is hashed separately
# after its allowlist check above.
{
    printf 'HEAD %s\n' "$HEAD_SHA"
    git status --porcelain=v1 -z --untracked-files=all | od -An -tx1
    { git diff --name-only; git diff --cached --name-only; } | LC_ALL=C sort -u \
      | grep -Eiv '(^|/)(\.env([^/]*)?|[^/]*(secret|credential|password|token)[^/]*)$' \
      | while IFS= read -r f; do [ -f "$f" ] && { printf '%s\t' "$f"; git hash-object -- "$f"; }; done
    git ls-files --others --exclude-standard -- .workaholic plugins scripts docs '*.md' \
      | grep -Eiv '(^|/)(\.env([^/]*)?|[^/]*(secret|credential|password|token)[^/]*)$' \
      | while IFS= read -r f; do [ -f "$f" ] && { printf '%s\t' "$f"; git hash-object -- "$f"; }; done
} >"$tmp/local-material"
LOCAL_FP=$(git hash-object "$tmp/local-material")
jq -Sc .config "$INPUT" | git hash-object --stdin >"$tmp/config-fp"; CONFIG_FP=$(cat "$tmp/config-fp")
find plugins/workaholic/skills -path '*/policies/*.md' -type f -print0 2>/dev/null | sort -z | xargs -0 git hash-object 2>/dev/null | git hash-object --stdin >"$tmp/policy-fp" || printf unknown >"$tmp/policy-fp"
POLICY_FP=$(cat "$tmp/policy-fp")
SNAPSHOT_ID=$(printf '%s\n%s\n%s\n%s\n' "$NOW" "$HEAD_SHA" "$LOCAL_FP" "$CONFIG_FP" | git hash-object --stdin)

REMOTE=$(jq -c --arg now "$NOW" --slurpfile o "$tmp/claims-observation.json" '{observed_at:$now,ok:$o[0].fetched,reason:(if $o[0].fetched then "" else "origin_unreachable" end)}' "$INPUT")
COMMUNICATION=$(jq -c '.communication // {new_input_ids:[],known_thread_changes:[],has_more:null,unreadable:[]}' "$INPUT")
IDENTITY=$(jq -c .identity "$INPUT"); CONFIG=$(jq -c .config "$INPUT")
PREVIOUS_JSON=null; [ -z "$PREVIOUS" ] || PREVIOUS_JSON=$(cat "$PREVIOUS")

jq -cn --arg sid "$SNAPSHOT_ID" --arg now "$NOW" --arg root "$ROOT" --arg common "$COMMON" --arg head "$HEAD_SHA" --arg base "$BASE_SHA" \
  --arg local "$LOCAL_FP" --arg config_fp "$CONFIG_FP" --arg policy_fp "$POLICY_FP" --argjson identity "$IDENTITY" --argjson config "$CONFIG" \
  --slurpfile observation "$tmp/claims-observation.json" --slurpfile claims "$tmp/claims.json" --slurpfile survey "$tmp/survey.json" --slurpfile strategies "$tmp/strategies.json" --slurpfile claimable "$tmp/claimable.json" \
  --argjson remote "$REMOTE" --argjson communication "$COMMUNICATION" --argjson recovery_readable "$recovery_readable" --argjson previous "$PREVIOUS_JSON" '
  {schema_version:1,snapshot_id:$sid,observed_at:$now,
   repo:{root:$root,git_common_dir:$common,head_sha:$head,base_sha:$base},identity:$identity,config:$config,config_fingerprint:$config_fp,policy_fingerprint:$policy_fp,
   freshness:{local_fingerprint:$local,remote:$remote,recovery_readable:$recovery_readable,previous_snapshot_id:($previous.snapshot_id // null),
     invalidated:(if $previous==null then ["initial"] else
       ([if $previous.freshness.local_fingerprint != $local then "local" else empty end,
         if $previous.config_fingerprint != $config_fp then "config" else empty end,
         if $previous.policy_fingerprint != $policy_fp then "policy" else empty end,
         if $previous.freshness.remote.ok != $remote.ok or $previous.repo.base_sha != $base then "remote" else empty end]) end)},
   work:{raw_claim_observation:$observation[0],claims:$claims[0].claims,missions:$survey[0].missions,tickets:$survey[0].backlog,strategies:$strategies[0].strategies,
     survey:$survey[0],claimable:$claimable[0],claimable_units:(([ $survey[0].missions[]?.slug ] + [ $survey[0].backlog[]?.path ] + [ $survey[0].resumable[]?.unit ]) | unique)},
   communication:$communication,
   evidence:[{kind:"git",version:$head},{kind:"claims",version:$observation[0].surveyed_sha},{kind:"local",version:$local}]}' >"$tmp/snapshot.json"

runtime_json_result ok "" read-snapshot "$(cat "$tmp/snapshot.json")"
