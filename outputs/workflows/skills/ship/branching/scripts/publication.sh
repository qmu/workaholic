#!/bin/sh -eu
# Durable publication transaction. The model decides what to publish; this
# script preserves one worktree, commit, remote branch and PR across retries.

PUBLICATION_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${PUBLICATION_SCRIPT_DIR}/lib/publication-context.sh"

ACTION=${1:-}; [ -n "$ACTION" ] || publication_usage "action is required"; shift
TRANSACTION="" REQUEST="" BASE=main MODE=pr
while [ $# -gt 0 ]; do
  case "$1" in
    --transaction) TRANSACTION=${2:-}; shift 2;;
    --request) REQUEST=${2:-}; shift 2;;
    --base) BASE=${2:-}; shift 2;;
    --mode) MODE=${2:-}; shift 2;;
    *) publication_usage "unknown argument: $1";;
  esac
done
case "$ACTION" in open|status|commit|publish|close) ;; *) publication_usage "unknown action";; esac
case "$MODE" in pr|direct) ;; *) publication_usage "invalid publish mode";; esac
publication_context "$TRANSACTION"
now=${WORKAHOLIC_NOW:-$(date -Iseconds)}

read_state=$(publication_read)
found=$(printf '%s' "$read_state" | jq -r '.data.found')

if [ "$ACTION" = status ]; then
  [ "$found" = true ] || { publication_result true "" "$(jq -cn --arg id "$PUBLICATION_ID" '{transaction:$id,found:false}')"; exit 0; }
  record=$(publication_record "$read_state"); data=$(printf '%s' "$record" | jq -c .data)
  dirty=null; head=null
  if [ -d "$PUBLICATION_PATH" ]; then
    [ -z "$(git -C "$PUBLICATION_PATH" status --porcelain 2>/dev/null)" ] && dirty=false || dirty=true
    head=$(git -C "$PUBLICATION_PATH" rev-parse HEAD 2>/dev/null || printf null)
  fi
  publication_result true "" "$(jq -cn --arg id "$PUBLICATION_ID" --argjson record "$record" --argjson dirty "$dirty" --arg head "$head" '{transaction:$id,found:true,record:$record,dirty:$dirty,head:(if $head=="null" then null else $head end)}')"
  exit 0
fi

if [ "$ACTION" = open ]; then
  git config --get remote.origin.url >/dev/null 2>&1 || { publication_result false no_origin '{}'; exit 0; }
  git fetch --quiet origin "$BASE" || { publication_result false origin_unreachable '{}'; exit 0; }
  base_sha=$(git rev-parse --verify --quiet "origin/${BASE}^{commit}" || true); [ -n "$base_sha" ] || { publication_result false base_unresolved '{}'; exit 0; }
  . "${PUBLICATION_SCRIPT_DIR}/lib/ensure-git-excludes.sh"; ensure_git_excludes "$PUBLICATION_ROOT"
  git worktree prune >/dev/null 2>&1 || true
  resumed=true
  if [ "$found" != true ]; then
    resumed=false
    suffix=0
    while :; do
      stamp=$(date +%Y%m%d-%H%M%S)
      branch_id=$(printf '%s' "$PUBLICATION_ID" | sed 's/[^A-Za-z0-9._-]/-/g' | cut -c1-24)
      [ "$suffix" -eq 0 ] && branch="work-${stamp}-${branch_id}" || branch="work-${stamp}-${branch_id}-${suffix}"
      if git show-ref --verify --quiet "refs/heads/$branch" || git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        suffix=$((suffix+1)); continue
      fi
      break
    done
    data=$(jq -cn --arg id "$PUBLICATION_ID" --arg base "$BASE" --arg sha "$base_sha" --arg path "$PUBLICATION_PATH" --arg branch "$branch" \
      '{transaction:$id,phase:"preparing",base:$base,start_sha:$sha,path:$path,local_branch:$branch,remote_branch:$branch,committed_sha:null,pushed_sha:null,pr_number:null,pr_url:null,last_error:null}')
    input=$(mktemp); jq -cn --arg now "$now" --argjson owner "$PUBLICATION_OWNER" --argjson data "$data" '{updated_at:$now,owner:$owner,data:$data}' >"$input"
    created=$(publication_state create --scope publication --id "$PUBLICATION_ID" --input "$input"); rm -f "$input"
    [ "$(printf '%s' "$created" | jq -r .status)" = ok ] || { publication_result false transaction_conflict '{}'; exit 0; }
    record=$(printf '%s' "$created" | jq -c .data.record)
  else
    record=$(publication_record "$read_state"); data=$(printf '%s' "$record" | jq -c .data)
    branch=$(printf '%s' "$data" | jq -r .local_branch)
    [ "$(printf '%s' "$data" | jq -r .base)" = "$BASE" ] || { publication_result false base_mismatch '{}'; exit 0; }
  fi
  branch=$(printf '%s' "$data" | jq -r .local_branch)
  if git worktree list --porcelain | grep -Fqx "worktree $PUBLICATION_PATH"; then
    [ -z "$(git -C "$PUBLICATION_PATH" status --porcelain)" ] || { publication_result false dirty_publish_tree "$(jq -cn --arg path "$PUBLICATION_PATH" '{path:$path}')"; exit 0; }
    head=$(git -C "$PUBLICATION_PATH" rev-parse HEAD)
    committed=$(printf '%s' "$data" | jq -r '.committed_sha // empty')
    if [ -z "$committed" ] && [ "$head" != "$(printf '%s' "$data" | jq -r .start_sha)" ]; then
      data=$(printf '%s' "$data" | jq -c --arg sha "$head" '.phase="committed"|.committed_sha=$sha|.last_error=null')
      written=$(publication_write_data "$record" "$data" "$now"); record=$(printf '%s' "$written" | jq -c .data.record)
    fi
  elif [ -e "$PUBLICATION_PATH" ]; then publication_result false dirty_publish_tree '{}'; exit 0
  else
    start=$(printf '%s' "$data" | jq -r '.committed_sha // .start_sha')
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      branch_sha=$(git rev-parse "$branch")
      [ "$branch_sha" = "$start" ] || { publication_result false branch_changed "$(jq -cn --arg expected "$start" --arg actual "$branch_sha" '{expected_sha:$expected,actual_sha:$actual}')"; exit 0; }
      git worktree add "$PUBLICATION_PATH" "$branch" >/dev/null 2>&1 || { publication_result false worktree_creation_failed '{}'; exit 0; }
    else
      git worktree add -b "$branch" "$PUBLICATION_PATH" "$start" >/dev/null 2>&1 || { publication_result false worktree_creation_failed '{}'; exit 0; }
    fi
  fi
  data=$(printf '%s' "$record" | jq -c '.data|if .phase=="preparing" then .phase="open" else . end')
  written=$(publication_write_data "$record" "$data" "$now"); record=$(printf '%s' "$written" | jq -c .data.record)
  publication_result true "" "$(printf '%s' "$record" | jq -c --argjson resumed "$resumed" '{transaction:.data.transaction,path:.data.path,branch:.data.local_branch,base:("origin/"+.data.base),sha:(.data.committed_sha//.data.start_sha),phase:.data.phase,resumed:$resumed}')"
  exit 0
fi

[ "$found" = true ] || { publication_result false transaction_missing '{}'; exit 0; }
record=$(publication_record "$read_state"); data=$(printf '%s' "$record" | jq -c .data)
[ "$(printf '%s' "$record" | jq -c .owner)" = "$PUBLICATION_OWNER" ] || { publication_result false owner_mismatch '{}'; exit 0; }
[ -d "$PUBLICATION_PATH" ] || { publication_result false worktree_missing '{}'; exit 0; }
branch=$(printf '%s' "$data" | jq -r .local_branch)
[ "$(git -C "$PUBLICATION_PATH" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { publication_result false branch_mismatch '{}'; exit 0; }

if [ "$ACTION" = commit ]; then
  [ -s "$REQUEST" ] || publication_usage "commit requires --request FILE"
  jq -e '(.title|type=="string" and length>0) and (.why|type=="string") and (.changes|type=="string") and (.concerns|type=="string") and (.insights|type=="string") and (.verify|type=="string") and (.files|type=="array" and length>0) and all(.files[];type=="string" and length>0)' "$REQUEST" >/dev/null 2>&1 || publication_usage "invalid commit request"
  committed=$(printf '%s' "$data" | jq -r '.committed_sha // empty')
  if [ -n "$committed" ]; then publication_result true "" "$(jq -cn --arg sha "$committed" --arg branch "$branch" '{sha:$sha,branch:$branch,reused:true}')"; exit 0; fi
  set -- "$(jq -r .title "$REQUEST")" "$(jq -r .why "$REQUEST")" "$(jq -r .changes "$REQUEST")" "$(jq -r .concerns "$REQUEST")" "$(jq -r .insights "$REQUEST")" "$(jq -r .verify "$REQUEST")"
  while IFS= read -r file; do set -- "$@" "$file"; done <<EOF
$(jq -r '.files[]' "$REQUEST")
EOF
  before=$(git -C "$PUBLICATION_PATH" rev-parse HEAD)
  (cd "$PUBLICATION_PATH" && "${PUBLICATION_SCRIPT_DIR}/../../commit/scripts/commit.sh" "$@") >/dev/null || { publication_result false commit_failed '{}'; exit 0; }
  after=$(git -C "$PUBLICATION_PATH" rev-parse HEAD); [ "$before" != "$after" ] || { publication_result false nothing_to_commit '{}'; exit 0; }
  data=$(printf '%s' "$data" | jq -c --arg sha "$after" '.phase="committed"|.committed_sha=$sha|.last_error=null')
  written=$(publication_write_data "$record" "$data" "$now")
  publication_result true "" "$(printf '%s' "$written" | jq -c '{transaction:.data.record.data.transaction,sha:.data.record.data.committed_sha,branch:.data.record.data.local_branch,reused:false}')"
  exit 0
fi

if [ "$ACTION" = publish ]; then
  [ -s "$REQUEST" ] || publication_usage "publish requires --request FILE"
  jq -e '(.title|type=="string" and length>0) and (.body|type=="string")' "$REQUEST" >/dev/null 2>&1 || publication_usage "invalid publish request"
  sha=$(printf '%s' "$data" | jq -r '.committed_sha // empty'); [ -n "$sha" ] || { publication_result false nothing_committed '{}'; exit 0; }
  [ "$(git -C "$PUBLICATION_PATH" rev-parse HEAD)" = "$sha" ] || { publication_result false head_changed '{}'; exit 0; }
  remote=$(printf '%s' "$data" | jq -r .remote_branch); base=$(printf '%s' "$data" | jq -r .base)
  if [ "$MODE" = direct ]; then destination=$base; else destination=$remote; fi
  if [ "$(printf '%s' "$data" | jq -r '.pushed_sha // empty')" != "$sha" ]; then
    . "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/lib/base-ref-gate.sh"
    if ! base_ref_gate push "$sha:refs/heads/$destination"; then
      data=$(printf '%s' "$data" | jq -c '.last_error="base_ref_write"'); publication_write_data "$record" "$data" "$now" >/dev/null
      publication_result false base_ref_write "$(jq -cn --arg sha "$sha" --arg branch "$destination" --arg role "${WORKAHOLIC_ROLE:-}" '{sha:$sha,branch:$branch,role:$role}')"; exit 0
    fi
    git -C "$PUBLICATION_PATH" push --quiet origin "$sha:refs/heads/$destination" || {
      data=$(printf '%s' "$data" | jq -c '.last_error="push_failed"'); publication_write_data "$record" "$data" "$now" >/dev/null
      publication_result false push_failed "$(jq -cn --arg sha "$sha" --arg branch "$destination" '{sha:$sha,branch:$branch}')"; exit 0
    }
    git fetch --quiet origin "$destination" >/dev/null 2>&1 || true
    data=$(printf '%s' "$data" | jq -c --arg sha "$sha" '.phase="pushed"|.pushed_sha=$sha|.last_error=null')
    written=$(publication_write_data "$record" "$data" "$now"); record=$(printf '%s' "$written" | jq -c .data.record); data=$(printf '%s' "$record" | jq -c .data)
  fi
  if [ "$MODE" = direct ]; then publication_result true "" "$(jq -cn --arg sha "$sha" --arg base "$base" '{sha:$sha,base:$base,reused:true}')"; exit 0; fi
  command -v gh >/dev/null 2>&1 || { publication_result false no_gh "$(jq -cn --arg sha "$sha" --arg branch "$remote" '{sha:$sha,branch:$branch}')"; exit 0; }
  slug=$(git -C "$PUBLICATION_PATH" config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/)##;s#\.git$##')
  owner=${slug%%/*}
  if ! lookup=$(gh api --paginate "repos/$slug/pulls?head=$owner:$remote&base=$base&state=all&per_page=100" 2>/dev/null); then
    data=$(printf '%s' "$data" | jq -c '.phase="pr_unknown"|.last_error="pr_lookup_unknown"'); publication_write_data "$record" "$data" "$now" >/dev/null
    publication_result false pr_lookup_unknown "$(jq -cn --arg sha "$sha" --arg branch "$remote" '{sha:$sha,branch:$branch}')"; exit 0
  fi
  candidates=$(printf '%s\n' "$lookup" | jq -sc 'map(if type=="array" then .[] else . end)')
  existing=$(printf '%s' "$candidates" | jq -c --arg branch "$remote" --arg base "$base" '[.[]|select(.head.ref==$branch and .base.ref==$base)]|sort_by(.number)|last // null')
  if [ "$existing" != null ]; then
    state=$(printf '%s' "$existing" | jq -r .state); merged=$(printf '%s' "$existing" | jq -r '.merged_at!=null'); number=$(printf '%s' "$existing" | jq -r .number); url=$(printf '%s' "$existing" | jq -r .html_url)
    if [ "$state" = closed ] && [ "$merged" != true ]; then publication_result false closed_unmerged "$(jq -cn --argjson pr "$number" --arg url "$url" '{pr_number:$pr,pr_url:$url}')"; exit 0; fi
  else
    payload=$(jq -cn --arg title "$(jq -r .title "$REQUEST")" --arg body "$(jq -r .body "$REQUEST")" --arg head "$remote" --arg base "$base" '{title:$title,body:$body,head:$head,base:$base}')
    if ! existing=$(printf '%s' "$payload" | gh api "repos/$slug/pulls" --method POST --input - 2>/dev/null); then
      data=$(printf '%s' "$data" | jq -c '.phase="pr_unknown"|.last_error="pr_create_unknown"'); publication_write_data "$record" "$data" "$now" >/dev/null
      publication_result false pr_create_unknown "$(jq -cn --arg sha "$sha" --arg branch "$remote" '{sha:$sha,branch:$branch}')"; exit 0
    fi
    number=$(printf '%s' "$existing" | jq -r .number); url=$(printf '%s' "$existing" | jq -r .html_url); merged=false
  fi
  phase=published; [ "$merged" != true ] || phase=merged
  data=$(printf '%s' "$data" | jq -c --arg phase "$phase" --argjson number "$number" --arg url "$url" '.phase=$phase|.pr_number=$number|.pr_url=$url|.last_error=null')
  publication_write_data "$record" "$data" "$now" >/dev/null
  publication_result true "" "$(jq -cn --arg sha "$sha" --arg branch "$remote" --argjson pr "$number" --arg url "$url" --arg phase "$phase" '{sha:$sha,branch:$branch,pr_number:$pr,pr_url:$url,phase:$phase,reused:true}')"
  exit 0
fi

# close
[ -z "$(git -C "$PUBLICATION_PATH" status --porcelain)" ] || { publication_result false dirty_publish_tree '{}'; exit 0; }
sha=$(printf '%s' "$data" | jq -r '.committed_sha // empty')
if [ -n "$sha" ]; then
  git fetch --quiet origin >/dev/null 2>&1 || { publication_result false remote_unreadable '{}'; exit 0; }
  git branch --remotes --contains "$sha" --format='%(refname:short)' | grep -q '^origin/' || { publication_result false unpublished_commits "$(jq -cn --arg sha "$sha" '{sha:$sha}')"; exit 0; }
fi
git worktree remove "$PUBLICATION_PATH" >/dev/null
git branch -D "$branch" >/dev/null 2>&1 || true
data=$(printf '%s' "$data" | jq -c '.phase="closed"|.last_error=null')
publication_write_data "$record" "$data" "$now" >/dev/null
publication_result true "" "$(jq -cn --arg path "$PUBLICATION_PATH" --arg branch "$branch" '{removed:true,branch_deleted:true,path:$path,branch:$branch}')"
