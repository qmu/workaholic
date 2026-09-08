#!/bin/sh -eu
# Deliver an ordinary publication only after its shared preparation gate succeeds.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER="$SCRIPT_DIR/../../gather/scripts"
NUMBER=${1:-}
BASE_BRANCH=${2:-main}
[ "$#" -le 2 ] || exit 2
prepared=$(sh "$SCRIPT_DIR/prepare-publication.sh" "$NUMBER" "$BASE_BRANCH")
case "$(printf '%s' "$prepared" | jq -r .outcome)" in settled) ;; *) printf '%s\n' "$prepared"; exit 0;; esac
BRANCH=$(printf '%s' "$prepared" | jq -r .branch)
DELIVERY=not_attempted
MERGE_BODY_SOURCE=""
emit() {
  printf '%s' "$prepared" | jq -c --arg reason "${1:-}" --arg delivery "$DELIVERY" --arg source "$MERGE_BODY_SOURCE" ' .reason=$reason | .delivery=$delivery | .body_source=$source'
  exit 0
}
# ── DELIVER: one merge attempt, through the seam every other caller uses ─────────────
# The merge vocabulary is `merge-reason.sh`'s own and is never a second set; the method is
# read from `merge-method.sh` and never spelled here (`CLAUDE.md`, *Enforcement gates*).
# A delivery this environment could not attempt is `not_attempted` with its reason, never a
# refusal of the settlement: the branch IS caught up and pushed, and the next tick's retry
# finds it mergeable.
sh "${GATHER}/gh-rest.sh" available >/dev/null 2>&1 || emit gh_unavailable
slug="$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || printf '')"
[ -n "$slug" ] || emit slug_unresolved

# Bind the check observation and merge request to this worktree's pushed head.
expected_head=$(git rev-parse "refs/remotes/origin/$BRANCH" 2>/dev/null || printf '')
check_gate=$(sh "${SCRIPT_DIR}/../../drive/scripts/branch-checks.sh" "$NUMBER" "$expected_head" 2>/dev/null || printf '')
gate_word=$(printf '%s' "$check_gate" | jq -r '.gate // "defer"' 2>/dev/null || printf defer)
if [ "$gate_word" != pass ]; then
    DELIVERY="merge_refused: $(printf '%s' "$check_gate" | jq -r '.reason // "checks_unreadable"' 2>/dev/null || printf checks_unreadable)"
    emit ""
fi

method=$(sh "${GATHER}/merge-method.sh" 2>/dev/null || printf '')
body_json=$(sh "${GATHER}/merge-commit-body.sh" "$NUMBER" 2>/dev/null || printf '')
merge_title=$(printf '%s' "$body_json" | jq -r '.title // ""' 2>/dev/null || printf '')
merge_body=$(printf '%s' "$body_json" | jq -r '.body // ""' 2>/dev/null || printf '')
MERGE_BODY_SOURCE=$(printf '%s' "$body_json" | jq -r '.source // "unreadable:no_composer"' 2>/dev/null || printf 'unreadable:no_composer')
request=$(mktemp); trap 'rm -f "$request"' EXIT HUP INT TERM
jq -cn --arg repo "$slug" --argjson pr "$NUMBER" --arg sha "$expected_head" --arg method "$method" \
  --arg title "$merge_title" --arg body "$merge_body" '{repo:$repo,pr:$pr,expected_sha:$sha,method:$method,title:$title,body:$body}' > "$request"
merge_resp=$(sh "${GATHER}/merge-pull.sh" --request "$request" 2>/dev/null || printf '')
case "$(printf '%s' "$merge_resp" | jq -r '.status // "unknown"' 2>/dev/null || printf unknown)" in
  merged) DELIVERY=merged ;;
  refused) DELIVERY="merge_refused: $(printf '%s' "$merge_resp" | jq -r '.reason // "merge_failed"')" ;;
  *) DELIVERY="merge_refused: merge_effect_unknown" ;;
esac

emit ""
