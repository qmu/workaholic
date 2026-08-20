#!/bin/sh -eu
# Create or update GitHub PR from story file
# Outputs "PR created: <URL>" or "PR updated: <URL>"
#     or: {"pr": null, "reason": "gh_unavailable", ...} and exit 0 when the `gh` CLI is
#         absent -- the hourly cloud runner's condition (observed 2026-07-31, where this
#         script exited 127 at /drive step 5 *after* the branch was already pushed, the
#         worst place to fail).
#
# REPORT AND DEGRADE, rather than falling back to the GitHub API over curl. The work is
# pushed and safe either way, and `/drive`'s Unified Run already defines a PR-creation
# failure as "its own report item, affecting nothing else" -- so the caller has a place
# to put this. A second HTTP client inside the plugin would add an auth surface for a
# case the caller can already handle, and the agent that runs this script can reach
# GitHub through its MCP server, which no shell script can. (Rejected alternative,
# recorded so it is not re-proposed blind.)

set -eu

BRANCH="${1:-}"
TITLE="${2:-}"

if [ -z "$BRANCH" ] || [ -z "$TITLE" ]; then
    echo "Usage: create-or-update.sh <branch-name> \"<title>\""
    echo "Example: create-or-update.sh feat-20260115-auth \"Add user authentication\""
    exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

STORY_FILE="${ROOT}/.workaholic/stories/${BRANCH}.md"

if [ ! -f "$STORY_FILE" ]; then
    echo "Error: Story file not found: $STORY_FILE"
    exit 1
fi

# Strip YAML frontmatter using bundled script, write to a PRIVATE per-run temp
# file. A constant, process-global body path is a cross-run data hazard:
# two concurrent /story runs on different repos race between the write and the
# read-back, so one publishes the other's story. mktemp gives each run its own
# file; the EXIT trap removes ONLY what this run created (never a foreign path).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/workaholic-pr-body.XXXXXX")
trap 'rm -f "$BODY_FILE"' EXIT
"${SCRIPT_DIR}/strip-frontmatter.sh" "$STORY_FILE" > "$BODY_FILE"

# Drop the low-severity concern blocks from the BODY only. The committed story file
# keeps every severity and is the sole source the ship-time extractor parses, so this
# changes what the reviewer is asked to read and nothing about what gets recorded.
"${SCRIPT_DIR}/filter-low-concerns.sh" "$BODY_FILE" "$BRANCH" >/dev/null

# Bound the body under GitHub's 65,536-char PR-body limit (a large carried
# concern corpus used to hard-stop this script at gh time). Over the limit, the
# Concerns section is replaced with a link to the committed story file — the
# ship-time extractor reads the file, not the PR body, so extraction is unchanged.
"${SCRIPT_DIR}/shrink-pr-body.sh" "$BODY_FILE" "$BRANCH" >/dev/null

# The CLI must exist before anything is attempted against it. Checked here rather than
# at the top so the story-file and body preparation above still run and still fail loudly
# on their own terms -- only the GitHub half degrades.
if ! command -v gh >/dev/null 2>&1; then
    printf '{"pr": null, "reason": "gh_unavailable", "branch": "%s", "story": "%s", "detail": "the GitHub CLI is not installed here; the branch and its story are pushed -- open or update the pull request by hand"}\n' \
        "$BRANCH" "$STORY_FILE"
    exit 0
fi

# REST FOR ALL THREE CALLS (2026-08-12, FB 20260812172522). `gh pr list`, `gh pr create`
# and `gh repo view` are GraphQL-backed, and a Claude Code Web session may serve only
# "the pinned set of PR-review operations" — measured HTTP 403 in this repository's own
# tick. The update half already used `gh api`; the lookup and the create did not, so
# /story stopped in a restricted session at the exact moment the branch and story were
# already pushed. `head` needs the owner-qualified `owner:branch` form, and the slug now
# comes from the remote rather than from `gh repo view`.
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"
if ! REPO=$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1); then
    printf '{"pr": null, "reason": "no_remote", "branch": "%s", "story": "%s", "detail": "could not resolve owner/repo from the git remote, so the pull request could not be addressed; the branch and its story are pushed -- open or update it by hand"}\n' \
        "$BRANCH" "$STORY_FILE"
    exit 0
fi
OWNER=${REPO%%/*}

# `gh pr create` inferred the base from the repository's default branch; REST does not,
# so the base becomes an explicit step. It is asked of the ONE place that decides it
# (`gather/scripts/base-ref.sh`) rather than defaulted to `main` here — a silent
# `${1:-main}` fallback is the exact bug that script's header records. Its answer is a
# ref like `origin/main`; the API wants the bare branch name.
BASE_REF=$(sh "${GATHER_SCRIPTS}/base-ref.sh" 2>/dev/null || true)
BASE_BRANCH=${BASE_REF#origin/}
if [ -z "$BASE_BRANCH" ]; then
    printf '{"pr": null, "reason": "no_base_branch", "branch": "%s", "story": "%s", "detail": "could not resolve the base branch, so the pull request could not be addressed; the branch and its story are pushed -- open it by hand"}\n' \
        "$BRANCH" "$STORY_FILE"
    exit 0
fi

PR_INFO=$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
    "repos/${REPO}/pulls?head=${OWNER}:${BRANCH}&state=open&per_page=1" \
    --jq '.[0] | select(. != null) | {number, url: .html_url}' 2>/dev/null || echo "")

if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "null" ]; then
    # Create. The body goes in on STDIN, never through argv: it carries the whole story
    # and a single argv entry is capped at 128 KiB on Linux. The stderr is captured
    # rather than discarded — a swallowed 403 is what made the measured incident
    # undiagnosable.
    PAYLOAD=$(jq -n --arg t "$TITLE" --arg h "$BRANCH" --arg b "$BASE_BRANCH" \
        --rawfile body "$BODY_FILE" '{title: $t, head: $h, base: $b, body: $body}' 2>/dev/null || true)
    if [ -z "$PAYLOAD" ]; then
        printf '{"pr": null, "reason": "pr_failed", "branch": "%s", "story": "%s", "detail": "could not build the pull-request payload (is jq present?); the branch and its story are pushed -- open the pull request by hand"}\n' \
            "$BRANCH" "$STORY_FILE"
        exit 0
    fi
    if ! RESP=$(printf '%s' "$PAYLOAD" \
        | sh "${GATHER_SCRIPTS}/gh-rest.sh" api "repos/${REPO}/pulls" --method POST --input - 2>&1); then
        DETAIL=$(printf '%s' "$RESP" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)
        printf '{"pr": null, "reason": "pr_failed", "branch": "%s", "story": "%s", "detail": "the branch and its story ARE pushed; open the pull request by hand rather than re-reporting. Underlying error: %s"}\n' \
            "$BRANCH" "$STORY_FILE" "$DETAIL"
        exit 0
    fi
    URL=$(printf '%s' "$RESP" | jq -r '.html_url // empty' 2>/dev/null || true)
    if [ -z "$URL" ]; then
        DETAIL=$(printf '%s' "$RESP" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)
        printf '{"pr": null, "reason": "pr_failed", "branch": "%s", "story": "%s", "detail": "the branch and its story ARE pushed; open the pull request by hand. Underlying error: %s"}\n' \
            "$BRANCH" "$STORY_FILE" "$DETAIL"
        exit 0
    fi
    echo "PR created: $URL"
else
    NUMBER=$(echo "$PR_INFO" | jq -r '.number')
    URL=$(echo "$PR_INFO" | jq -r '.url')
    UPDATE=$(jq -n --arg t "$TITLE" --rawfile body "$BODY_FILE" '{title: $t, body: $body}' 2>/dev/null || true)
    printf '%s' "$UPDATE" \
        | sh "${GATHER_SCRIPTS}/gh-rest.sh" api "repos/${REPO}/pulls/${NUMBER}" \
            --method PATCH --input - > /dev/null
    echo "PR updated: $URL"
fi
