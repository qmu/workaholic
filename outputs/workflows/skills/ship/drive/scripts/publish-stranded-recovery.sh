#!/bin/sh -eu
# Publish a reviewed recovery as a draft, idempotently. Run IN the recovery tree
# after committing the reviewed diff. Review file must name tests and disposition.
# Usage: publish-stranded-recovery.sh <recovery-key> <review-markdown-file>
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../branching/scripts/lib/base-ref-gate.sh"
GH_REST="$SCRIPT_DIR/../../gather/scripts/gh-rest.sh"
key=${1:?recovery key required}; review=${2:?review file required}
fail() { jq -cn --arg reason "$1" '{published:false,reason:$reason}'; exit 1; }
case "$key" in *[!0-9a-f]*|'') fail invalid_key ;; esac
[ ${#key} -eq 40 ] || fail invalid_key
[ -s "$review" ] || fail review_required
[ -z "$(git status --porcelain)" ] || fail uncommitted_review_tree
branch=$(git branch --show-current)
claim_ref="refs/claims/recovery-$key"
git fetch --quiet origin "$claim_ref" || fail claim_unreadable
claim=$(git rev-parse FETCH_HEAD)
field() { git show -s --format="%(trailers:key=$1,valueonly)" "$claim" | tr -d '\n'; }
[ "$(field Recovery-Key)" = "$key" ] || fail recovery_key_mismatch
[ "$(field Recovery-Branch)" = "$branch" ] || fail recovery_branch_mismatch
git merge-base --is-ancestor "$claim" HEAD || fail recovery_claim_not_ancestor
slug=$(sh "$GH_REST" slug) || fail slug_unreadable
owner=${slug%%/*}
pulls=$(sh "$GH_REST" api "repos/$slug/pulls?state=all&head=$owner:$branch&per_page=50") || fail pulls_unreadable
printf '%s' "$pulls" | jq -e 'type=="array" and length<50' >/dev/null || fail pulls_unreadable
existing=$(printf '%s' "$pulls" | jq -c '.[0] // null')
if [ "$existing" != null ]; then
    printf '%s' "$existing" | jq -e '.state == "open" and .draft == true' >/dev/null || fail review_no_longer_open_draft
fi
# Scan exactly the reviewed head before any product content reaches the remote.
observed=$(git rev-parse HEAD)
scan=$(sh "$SCRIPT_DIR/../../release-scan/scripts/scan-branch-safety.sh" "$(field Recovery-Base)") || fail scan_unreadable
gate=$(printf '%s' "$scan" | sh "$SCRIPT_DIR/../../release-scan/scripts/gate-decision.sh") || fail scan_unreadable
printf '%s' "$gate" | jq -e '.decision == "pass" or (.decision == "block" and .override_only == true)' >/dev/null || fail safety_gate_refused
[ "$(git rev-parse HEAD)" = "$observed" ] || fail head_changed
[ -z "$(git status --porcelain)" ] || fail uncommitted_review_tree
base_ref_gate push "$branch" || fail base_ref_write
git push --quiet origin "$observed:refs/heads/$branch" || fail push_failed
if [ "$existing" != null ]; then
    printf '%s' "$existing" | jq -c '{published:true,reason:"existing_review",number,html_url,draft,state}'
    exit 0
fi
base_ref=${WORKAHOLIC_BASE_REF:-origin/main}; base_name=${base_ref#origin/}
body=$(printf 'Recovery key: `%s`\n\nOriginal branch: `%s`\n\nOriginal head: `%s`\n\nObserved base: `%s`\n\nSource unit: `%s`\n\nOriginal refs are preserved. Review only; no automatic merge or discard.\n\n' \
    "$key" "$(field Recovery-Source-Branch)" "$(field Recovery-Source-Head)" "$(field Recovery-Base)" "$(field Recovery-Unit)"; cat "$review")
request=$(mktemp); trap 'rm -f "$request"' EXIT HUP INT TERM
jq -n --arg head "$branch" --arg base "$base_name" --arg body "$body" \
    '{title:"Review stranded claim recovery",head:$head,base:$base,body:$body,draft:true}' > "$request"
result=$(sh "$GH_REST" api "repos/$slug/pulls" --method POST --input "$request") || fail draft_publication_failed
printf '%s' "$result" | jq -e '.draft == true and (.number | type == "number")' >/dev/null || fail draft_unconfirmed
printf '%s' "$result" | jq -c '{published:true,reason:"draft_review_created",number,html_url,draft}'
