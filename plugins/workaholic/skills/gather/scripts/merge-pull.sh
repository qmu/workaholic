#!/bin/sh -eu
# Merge exactly the reviewed pull-request head and reconcile an uncertain response.
# Usage: merge-pull.sh --request FILE

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REQUEST=""
[ "${1:-}" = --request ] && REQUEST=${2:-}
[ -s "$REQUEST" ] || { printf '{"status":"refused","reason":"invalid_request"}\n'; exit 0; }
jq -e '(.pr|type=="number") and (.expected_sha|type=="string" and length>0) and (.method|type=="string") and (.title|type=="string") and (.body|type=="string")' "$REQUEST" >/dev/null 2>&1 || {
  printf '{"status":"refused","reason":"invalid_request"}\n'; exit 0;
}
repo=$(jq -r '.repo // empty' "$REQUEST")
[ -n "$repo" ] || repo=$(sh "$SCRIPT_DIR/gh-rest.sh" slug 2>/dev/null || true)
case "$repo" in */*) ;; *) printf '{"status":"deferred","reason":"repo_unresolved"}\n'; exit 0;; esac
pr=$(jq -r .pr "$REQUEST"); expected=$(jq -r .expected_sha "$REQUEST")

read_pr() { sh "$SCRIPT_DIR/gh-rest.sh" api "repos/${repo}/pulls/${pr}" 2>/dev/null; }
before=$(read_pr || true)
head=$(printf '%s' "$before" | jq -r '.head.sha // empty' 2>/dev/null || true)
state=$(printf '%s' "$before" | jq -r '.state // empty' 2>/dev/null || true)
merged=$(printf '%s' "$before" | jq -r '.merged // false' 2>/dev/null || true)
if [ "$merged" = true ]; then
  sha=$(printf '%s' "$before" | jq -r '.merge_commit_sha // empty')
  jq -cn --arg sha "$sha" --arg expected "$expected" '{status:"merged",merge_sha:$sha,expected_sha:$expected,reconciled:true}'
  exit 0
fi
[ -n "$head" ] || { printf '{"status":"deferred","reason":"pr_unreadable"}\n'; exit 0; }
[ "$state" = open ] || { printf '{"status":"refused","reason":"pull_not_open"}\n'; exit 0; }
[ "$head" = "$expected" ] || { jq -cn --arg expected "$expected" --arg actual "$head" '{status:"refused",reason:"head_changed",expected_sha:$expected,actual_sha:$actual}'; exit 0; }

method=$(jq -r .method "$REQUEST"); title=$(jq -r .title "$REQUEST"); body=$(jq -r .body "$REQUEST")
if response=$(sh "$SCRIPT_DIR/gh-rest.sh" api "repos/${repo}/pulls/${pr}/merge" --method PUT \
    -f "sha=${expected}" -f "merge_method=${method}" -f "commit_title=${title}" -f "commit_message=${body}" 2>&1); then
  ok=$(printf '%s' "$response" | jq -r '.merged // false' 2>/dev/null || true)
  sha=$(printf '%s' "$response" | jq -r '.sha // empty' 2>/dev/null || true)
  if [ "$ok" = true ] && [ -n "$sha" ]; then
    jq -cn --arg sha "$sha" --arg expected "$expected" '{status:"merged",merge_sha:$sha,expected_sha:$expected,reconciled:false}'
    exit 0
  fi
fi

# A failed/partial write is an unknown effect until the pull request itself answers.
after=$(read_pr || true)
if [ "$(printf '%s' "$after" | jq -r '.merged // false' 2>/dev/null || true)" = true ]; then
  sha=$(printf '%s' "$after" | jq -r '.merge_commit_sha // empty' 2>/dev/null || true)
  [ -n "$sha" ] && { jq -cn --arg sha "$sha" --arg expected "$expected" '{status:"merged",merge_sha:$sha,expected_sha:$expected,reconciled:true}'; exit 0; }
fi
jq -cn --arg expected "$expected" '{status:"unknown",reason:"merge_effect_unconfirmed",expected_sha:$expected}'
