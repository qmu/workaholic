#!/bin/sh -eu
# Claim one immutable stranded observation and prepare an isolated review tree.
# Usage: recover-stranded-claim.sh <unit> <branch> <expected-head>
# Never changes the original branch/worktree, merges, deletes or discards work.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../branching/scripts/lib/base-ref-gate.sh"
resume=false
if [ "${1:-}" = --resume ]; then resume=true; shift; fi
unit=${1:?unit required}; source_branch=${2:?branch required}; expected=${3:?head required}
fail() { jq -cn --arg reason "$1" '{claimed:false,reason:$reason}'; exit 1; }
case "$source_branch" in work-????????-??????) ;; *) fail invalid_branch ;; esac
case "$expected" in *[!0-9a-f]*|'') fail invalid_head ;; esac
[ ${#expected} -eq 40 ] || fail invalid_head
observation=$(sh "$SCRIPT_DIR/list-claims.sh")
printf '%s' "$observation" | jq -e '.fetched == true and .shallow == false' >/dev/null || fail claims_unreadable
row=$(printf '%s' "$observation" | jq -c --arg u "$unit" --arg b "$source_branch" '[.claims[] | select(.unit==$u and .branch==$b)] | if length==1 then .[0] else null end')
printf '%s' "$row" | jq -e '.resume_reason == "stranded"' >/dev/null || fail claim_not_stranded_or_not_owned
head=$(git rev-parse "refs/remotes/origin/$source_branch")
[ "$head" = "$expected" ] || fail source_head_changed
remote_head=$(git ls-remote origin "refs/heads/$source_branch" | cut -f1)
[ "$remote_head" = "$expected" ] || fail source_head_changed
# The oracle checks identity/liveness before offering stranded. Re-read its source
# ref after observation and lock precisely this immutable branch/head, not the unit.
key=$(printf '%s\n%s\n' "$source_branch" "$head" | git hash-object --stdin)
claim_ref="refs/claims/recovery-$key"
existing=$(git ls-remote origin "$claim_ref") || fail origin_unreachable
old_claim=''; branch=''; pinned_base="${WORKAHOLIC_BASE_REF:-origin/main}"
if [ -n "$existing" ]; then
    if [ "$resume" != true ]; then
        jq -cn --arg key "$key" --arg ref "$claim_ref" '{claimed:false,reason:"recovery_already_claimed",key:$key,claim_ref:$ref}'
        exit 0
    fi
    git fetch --quiet origin "$claim_ref" || fail claim_unreadable
    old_claim=$(git rev-parse FETCH_HEAD)
    claim_field() { git show -s --format="%(trailers:key=$1,valueonly)" "$old_claim" | tr -d '\n'; }
    identity=${WORKAHOLIC_CLAIM_IDENTITY:-$(git config user.email)}
    [ "$(git show -s --format=%ae "$old_claim")" = "$identity" ] || fail recovery_foreign_identity
    [ "$(claim_field Recovery-Key)" = "$key" ] || fail recovery_key_mismatch
    claimed_at=$(claim_field Recovery-Claimed-At)
    stale_minutes=${WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES:-30}
    case "$claimed_at:$stale_minutes" in *[!0-9:]*) fail claim_time_unreadable ;; esac
    [ -n "$claimed_at" ] && [ -n "$stale_minutes" ] || fail claim_time_unreadable
    [ "$(( $(date +%s) - claimed_at ))" -ge "$((stale_minutes * 60))" ] || fail recovery_active
    branch=$(claim_field Recovery-Branch)
    pinned_base=$(claim_field Recovery-Base)
fi
assessment=$(sh "$SCRIPT_DIR/assess-claim-residue.sh" "$source_branch" "$pinned_base" "$head")
state=$(printf '%s' "$assessment" | jq -r .state)
if [ "$state" = unknown ]; then
    jq -cn --argjson evidence "$assessment" '{claimed:false,reason:"assessment_unanswerable",evidence:$evidence}'
    exit 1
fi
base=$(printf '%s' "$assessment" | jq -r .base)
root=$(git rev-parse --show-toplevel)
worktree="$root/.worktrees/recovery-$key"
mkdir -p "$root/.worktrees"
if [ -n "$old_claim" ]; then
    if [ -e "$worktree" ]; then
        [ "$(git -C "$worktree" branch --show-current)" = "$branch" ] || fail recovery_worktree_mismatch
        [ -z "$(git -C "$worktree" status --porcelain)" ] || fail recovery_worktree_dirty
        git -C "$worktree" merge-base --is-ancestor "$old_claim" HEAD || fail recovery_worktree_stale
    else
        start=$old_claim
        # A prior publication may contain reviewed commits after coordination.
        if git fetch --quiet origin "refs/heads/$branch" 2>/dev/null; then
            published=$(git rev-parse FETCH_HEAD)
            if git merge-base --is-ancestor "$old_claim" "$published"; then start=$published; fi
        fi
        git worktree add -b "$branch" "$worktree" "$start" >&2 || fail worktree_creation_failed
    fi
    cd "$worktree"
else
    [ ! -e "$worktree" ] || fail recovery_worktree_exists
    git worktree add --detach "$worktree" "$base" >&2 || fail worktree_creation_failed
    cd "$worktree"
    branch=$(sh "$SCRIPT_DIR/../../branching/scripts/create.sh" | jq -r .branch)
fi
# Preserve reviewed commits on resume. A crash immediately after coordination has
# no product diff and must reconstruct the pinned residual tree in a fresh clone.
replay=true
if [ -n "$old_claim" ] && ! git diff --quiet "$base" HEAD -- . ':(exclude).workaholic'; then replay=false; fi
# Empty coordination commit has a unique branch trailer. Competing writers use
# an absent-ref lease; the loser keeps its isolated tree and never applies work.
attempt=$(mktemp); nonce=$(basename "$attempt"); rm -f "$attempt"
sh "$SCRIPT_DIR/../../commit/scripts/commit.sh" --allow-empty --housekeeping claim \
    --trailer "Recovery-Attempt: $nonce" --trailer "Recovery-Claimed-At: $(date +%s)" \
    --trailer "Recovery-Key: $key" --trailer "Recovery-Branch: $branch" \
    --trailer "Recovery-Source-Branch: $source_branch" --trailer "Recovery-Source-Head: $head" \
    --trailer "Recovery-Base: $base" --trailer "Recovery-Unit: $unit" \
    'Claim stranded branch recovery' 'Review undelivered effects without touching the original claim.' \
    'None' 'Original branch remains protected.' 'None' 'Source ownership and immutable head checked.' >&2
# A resume may retain locally reviewed product commits. Coordination refs are
# public too: run the same gate before uploading any such ancestry.
observed=$(git rev-parse HEAD)
scan=$(sh "$SCRIPT_DIR/../../release-scan/scripts/scan-branch-safety.sh" "$base") || fail scan_unreadable
gate=$(printf '%s' "$scan" | sh "$SCRIPT_DIR/../../release-scan/scripts/gate-decision.sh") || fail scan_unreadable
printf '%s' "$gate" | jq -e '.decision == "pass" or (.decision == "block" and .override_only == true)' >/dev/null || fail safety_gate_refused
[ "$(git rev-parse HEAD)" = "$observed" ] || fail head_changed
base_ref_gate push "$claim_ref" || fail base_ref_write
if ! git push --force-with-lease="$claim_ref:$old_claim" origin "$observed:$claim_ref" >&2; then fail recovery_claim_raced; fi
# Exclude bookkeeping from replay: ticket archives on the base are authoritative.
# The resulting tree is a three-way merge, so independent newer base edits survive.
if [ "$state" = pending ] && [ "$replay" = true ]; then
    tree=$(printf '%s' "$assessment" | jq -r .tree)
    git diff --binary "$base" "$tree" -- . ':(exclude).workaholic' | git apply --index --binary || fail residual_apply_failed
fi
jq -cn --arg key "$key" --arg ref "$claim_ref" --arg branch "$branch" \
    --arg worktree "$worktree" --argjson source "$row" --argjson evidence "$assessment" \
    '{claimed:true,reason:"review_tree_prepared",key:$key,claim_ref:$ref,branch:$branch,
      worktree:$worktree,source:$source,evidence:$evidence,
      next:"Inspect staged effects; verify; commit and publish a draft PR. Never auto-merge or delete the source."}'
