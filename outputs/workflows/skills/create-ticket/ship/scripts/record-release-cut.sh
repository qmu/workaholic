#!/bin/sh -eu
# Write the durable ship record for a freshly cut release/* branch (decision L3).
#
# THE QUESTION THIS ANSWERS: "what did this deploy carry, and when" — from the filesystem,
# with grep and git log, without opening GitHub. It is a NEW, SEPARATE artifact:
# .workaholic/release-notes/<branch>.md (one note per shipped unit, written pre-merge) and
# the story's `## Deployment Evidence` block are untouched and keep exactly their shape.
#
# Everything here is DERIVED FROM GIT at cut time rather than accumulated per unit. The
# question is about the release, and re-deriving it from per-unit notes would make it a
# view rather than a record — a view is only as durable as the things it reads.
#
# It runs on the BASE, because a promotion is a batch-level act over the base and the
# record belongs there: a record on the release branch would be invisible to everyone
# until (and unless) that branch merged somewhere. Post-merge direct-to-base commits are
# the sanctioned shape for a seam already downstream of a merge (the same reasoning
# extract-deferred-concerns.sh applies).
#
# Usage: record-release-cut.sh <release-branch> [since-ref] [base]
#   <release-branch>  e.g. release/20260803-213000 (as cut-release-branch.sh minted it)
#   [since-ref]       the previous release boundary; resolved automatically when omitted
#   [base]            default main
# Output: JSON {ok, path, release_branch, cut_sha, since_ref, since_reason, carried_count,
#               committed, pushed, push_error} or {ok:false, reason}
#   reason: usage | unknown_release_branch | not_on_base | dirty_workspace
#         | already_recorded | commit_failed

set -eu

BRANCH="${1:-}"
SINCE_ARG="${2:-}"
BASE="${3:-main}"

fail() {
  printf '{"ok": false, "reason": "%s"}\n' "$1"
  exit 0
}

[ -n "$BRANCH" ] || { echo '{"ok": false, "reason": "usage"}' >&2; exit 1; }

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo '{"ok": false, "reason": "not_a_git_repo"}' >&2
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# The release branch must exist as a ref. Prefer the remote: the record describes a
# published window, and a local-only branch is not one.
CUT_SHA=$(git rev-parse --verify --quiet "refs/remotes/origin/${BRANCH}" || true)
[ -n "$CUT_SHA" ] || CUT_SHA=$(git rev-parse --verify --quiet "refs/heads/${BRANCH}" || true)
[ -n "$CUT_SHA" ] || fail unknown_release_branch

CURRENT=$(git branch --show-current 2>/dev/null || true)
[ "$CURRENT" = "$BASE" ] || fail not_on_base
[ -z "$(git status --porcelain 2>/dev/null)" ] || fail dirty_workspace

DIR="${ROOT}/.workaholic/releases"
SLUG=$(printf '%s' "$BRANCH" | tr '/' '-')
FILE="${DIR}/${SLUG}.md"
# One record per release branch, and it is never rewritten: a second cut is a second
# release with its own identity.
if [ -e "$FILE" ]; then
  fail already_recorded
fi

# --- Resolve the previous release boundary -----------------------------------------
# Four sources, most specific first. The reason is RECORDED alongside the ref, because a
# range is only trustworthy if the reader can see how it was chosen.
SINCE=""
SINCE_REASON=""
if [ -n "$SINCE_ARG" ]; then
  SINCE=$(git rev-parse --verify --quiet "${SINCE_ARG}^{commit}" || true)
  [ -n "$SINCE" ] && SINCE_REASON=given
fi

if [ -z "$SINCE" ] && [ -d "$DIR" ]; then
  # The newest prior record whose cut_sha still resolves. Filenames carry the cut
  # timestamp, so a reverse sort is chronological.
  for prior in $(find "$DIR" -maxdepth 1 -name 'release-*.md' -type f 2>/dev/null | LC_ALL=C sort -r); do
    prior_sha=$(sed -n 's/^cut_sha:[[:space:]]*//p' "$prior" | head -n 1)
    [ -n "$prior_sha" ] || continue
    prior_sha=$(git rev-parse --verify --quiet "${prior_sha}^{commit}" || true)
    [ -n "$prior_sha" ] || continue
    SINCE="$prior_sha"
    SINCE_REASON=prior_release
    break
  done
fi

if [ -z "$SINCE" ]; then
  tag=$(git describe --tags --abbrev=0 "$CUT_SHA" 2>/dev/null || true)
  if [ -n "$tag" ]; then
    SINCE=$(git rev-parse --verify --quiet "${tag}^{commit}" || true)
    [ -n "$SINCE" ] && SINCE_REASON="latest_tag:${tag}"
  fi
fi

# No prior release and no tag: this release genuinely carries the whole history, and
# saying so is more honest than inventing a boundary.
[ -n "$SINCE" ] || SINCE_REASON=full_history

if [ -n "$SINCE" ]; then
  RANGE="${SINCE}..${CUT_SHA}"
else
  RANGE="$CUT_SHA"
fi

# The range is LITERAL: every base commit between the two boundaries, this pipeline's own
# record and confirmation commits included. That is deliberate — the recorded count is
# exactly what `git log <since_ref>..<cut_sha>` replays, so any reader can re-derive it. A
# filter that hid bookkeeping would have to recognise it by subject, and the first time it
# guessed wrong the record would stop being verifiable, which is the one property it has.
CARRIED=$(git rev-list --count "$RANGE" 2>/dev/null || echo 0)

# The body lists the commits, bounded. carried_count stays exact; a record that pastes
# five thousand subjects is not readable, and readability is the whole point.
LIST_MAX=200

CREATED_AT=$(date -Iseconds)
AUTHOR=$(git config user.email 2>/dev/null || true)
SINCE_DISPLAY="$SINCE"
[ -n "$SINCE_DISPLAY" ] || SINCE_DISPLAY="(none — first recorded release)"

mkdir -p "$DIR"
{
  printf -- '---\n'
  printf -- 'type: Release\n'
  printf -- 'title: %s\n' "$BRANCH"
  printf -- 'description: Release cut from %s at %s, carrying %s commit(s)\n' \
    "$BASE" "$(printf '%s' "$CUT_SHA" | cut -c1-8)" "$CARRIED"
  printf -- 'release_branch: %s\n' "$BRANCH"
  printf -- 'status: staging\n'
  printf -- 'base: %s\n' "$BASE"
  printf -- 'cut_at: %s\n' "$CREATED_AT"
  printf -- 'cut_sha: %s\n' "$CUT_SHA"
  printf -- 'since_ref: %s\n' "$SINCE"
  printf -- 'since_reason: %s\n' "$SINCE_REASON"
  printf -- 'carried_count: %s\n' "$CARRIED"
  printf -- 'confirmed_at:\n'
  printf -- 'confirmation_method:\n'
  printf -- 'confirmation_status:\n'
  printf -- 'tag:\n'
  printf -- 'author: %s\n' "$AUTHOR"
  printf -- 'created_at: %s\n' "$CREATED_AT"
  printf -- 'modified_at: %s\n' "$CREATED_AT"
  printf -- '---\n\n'
  printf -- '# %s\n\n' "$BRANCH"
  printf -- 'Cut from `%s` at `%s` on %s. The staging window is **open**: this release is\n' \
    "$BASE" "$CUT_SHA" "$CREATED_AT"
  printf -- 'not in production until a confirmation is recorded below.\n\n'
  printf -- '## Carried commits\n\n'
  printf -- 'Range `%s` — **%s** commit(s), measured from the previous boundary\n' "$RANGE" "$CARRIED"
  printf -- '(`since_reason: %s`).\n\n' "$SINCE_REASON"
  printf -- 'Previous boundary: `%s`\n\n' "$SINCE_DISPLAY"
  git log --no-merges --format='* `%h` %s' --max-count="$LIST_MAX" "$RANGE" 2>/dev/null || true
  if [ "$CARRIED" -gt "$LIST_MAX" ]; then
    printf -- '\n* … and %s more (the count above is exact; the list is bounded at %s).\n' \
      "$((CARRIED - LIST_MAX))" "$LIST_MAX"
  fi
  printf -- '\n## Confirmation\n\n'
  printf -- 'Pending — no confirmation has been executed against this release branch yet.\n'
} > "$FILE"

# Keep the OKF bundle indexes in step, exactly like every other knowledge write.
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" >/dev/null 2>&1 || true
git add "${ROOT}/.workaholic/index.md" "${DIR}/index.md" >/dev/null 2>&1 || true

if ! sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" --skip-staging \
  "Record release cut" \
  "A production release needs a durable record of what it carried and when, answerable from the filesystem." \
  "Adds ${SLUG}.md: the base commits this release branch carries, its cut time, and a pending confirmation." \
  "" "" "Derived from git at cut time; carried_count is exact." >/dev/null 2>&1; then
  fail commit_failed
fi

. "${SCRIPT_DIR}/lib/push-outcome.sh"
push_and_report

printf '{"ok": true, "path": ".workaholic/releases/%s.md", "release_branch": "%s", "cut_sha": "%s", "since_ref": "%s", "since_reason": "%s", "carried_count": %s, "committed": true, "pushed": %s, "push_error": "%s"}\n' \
  "$SLUG" "$BRANCH" "$CUT_SHA" "$SINCE" "$SINCE_REASON" "$CARRIED" "$PUSH_OK" "$PUSH_ERROR"
