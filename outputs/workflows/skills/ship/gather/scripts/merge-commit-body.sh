#!/bin/sh -eu
# The squash TITLE and BODY every merge this loop makes carries, derived in ONE place.
#
#   merge-commit-body.sh <pull-request-number>
#   merge-commit-body.sh --branch <branch> [--number <n>] [--title <title>]
#
#     -> {"ok", "title", "body", "source", "reason"} on stdout, and nothing else.
#
# WHY IT EXISTS (2026-09-03, mission `compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk`).
# `merge-method.sh` settled that every merge is a SQUASH, and a squash whose API call carries no
# `commit_message` gets the forge's own default: the concatenation of every commit message on the
# branch. So the very bookkeeping the squash exists to keep off `main` -- the claim stamp, the
# heartbeats, the index refreshes -- lands on `main` anyway, inside the squash commit's body.
#
# MEASURED on this repository the day the mission was written: 48 commits on `main` whose body
# carries the text `Refresh heartbeat`, every one of them a squash body rather than a heartbeat
# commit, the longest 11,515 lines. All five REST merge call sites passed `merge_method` and
# nothing else.
#
# WHAT IT ANSWERS. The composed statement of what a unit did already exists -- the branch story --
# and until now nothing read it at the merge. So:
#
#   title   the pull request's own title with its ` (#<n>)` suffix, which is the shape a reader
#           already expects from a squash; the story's own heading when no number is in hand.
#   body    the story's `description:` line, then the branch's own commit subjects with the
#           HOUSEKEEPING ones dropped.
#
# HOUSEKEEPING IS DROPPED BY MARKER, NEVER BY TITLE (the mission's own ruling). A commit carrying a
# `Workaholic-Housekeeping: <kind>` trailer is the loop's memory rather than a change to the
# product, and `commit.sh` is its one writer. Matching on a subject such as `Refresh heartbeat`
# would key on one wording of one writer, and the next housekeeping commit would carry another.
# A commit with NO marker is treated as ordinary work, which is the safe direction: history
# already on the trunk carries no marker and is not rewritten, so this over-includes on old
# branches and under-includes on nothing.
#
# `source` IS THREE-VALUED AND EACH IS NAMED:
#
#   story            the branch story resolved and its description was read
#   fallback         no story resolved -- the body is one line naming the unit and its pull
#                    request. A publication (a proposal, a ruling draft, a `/ticket`) has no
#                    branch story by construction, so this is its ordinary answer, not a failure.
#   unreadable:<why> something this script needed could not be read. It STILL yields the fallback
#                    body: a composer that fails must never hand the forge its default back by
#                    omission, and a merge is never held on a body.
#
# IT WRITES NOTHING. No file, no ref, no commit, no Slack transport. Its one network read is the
# pull-request lookup that resolves a number to a head branch and a title, and `--branch` skips
# even that.
#
# THE BODY HAS A CEILING. The forge accepts a large body, but a body nobody reads is the noise
# this mission exists to remove, so the subject list is capped at WORKAHOLIC_MERGE_BODY_MAX_SUBJECTS
# (default 40) with the remainder COUNTED rather than cut silently, and the whole body at
# WORKAHOLIC_MERGE_BODY_MAX_BYTES (default 8000).

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/gh-rest.sh"

MAX_SUBJECTS=${WORKAHOLIC_MERGE_BODY_MAX_SUBJECTS:-40}
MAX_BYTES=${WORKAHOLIC_MERGE_BODY_MAX_BYTES:-8000}

NUMBER=""
BRANCH=""
TITLE=""

usage() {
  echo '{"ok": false, "title": "", "body": "", "source": "unreadable:bad_arguments", "reason": "usage: merge-commit-body.sh <pull-request-number> | --branch <branch> [--number <n>] [--title <title>]"}'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --branch) [ $# -ge 2 ] || usage; BRANCH="$2"; shift 2 ;;
    --number) [ $# -ge 2 ] || usage; NUMBER="$2"; shift 2 ;;
    --title)  [ $# -ge 2 ] || usage; TITLE="$2"; shift 2 ;;
    -*) usage ;;
    *) NUMBER="$1"; shift ;;
  esac
done

[ -n "$NUMBER" ] || [ -n "$BRANCH" ] || usage

json_escape() {
  # One reader of the JSON string escape, so the three emit paths cannot disagree.
  printf '%s' "$1" | python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null || {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' '\001' | sed -e 's/\001/\\n/g'
  }
}

emit() {
  # emit <ok> <title> <body> <source> <reason>
  printf '{"ok": %s, "title": "%s", "body": "%s", "source": "%s", "reason": "%s"}\n' \
    "$1" "$(json_escape "$2")" "$(json_escape "$3")" "$(json_escape "$4")" "$(json_escape "$5")"
  exit 0
}

# --- Resolve the branch and the pull-request title ------------------------------------------
lookup_reason=""
if [ -z "$BRANCH" ]; then
  if slug=$(sh "$GH_REST" slug 2>/dev/null) && [ -n "$slug" ]; then
    if pr_json=$(sh "$GH_REST" api "repos/${slug}/pulls/${NUMBER}" 2>/dev/null); then
      BRANCH=$(printf '%s' "$pr_json" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin); print(d.get("head",{}).get("ref","") or "")
except Exception: print("")' 2>/dev/null || true)
      [ -n "$TITLE" ] || TITLE=$(printf '%s' "$pr_json" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin); print(d.get("title","") or "")
except Exception: print("")' 2>/dev/null || true)
    else
      lookup_reason="pull_request_unreadable"
    fi
  else
    lookup_reason="no_slug"
  fi
fi

unit_name="${BRANCH:-#${NUMBER}}"

# The title keeps the shape a squash already has, so a reader's expectations do not move.
if [ -n "$TITLE" ]; then
  composed_title="$TITLE"
else
  composed_title="$unit_name"
fi
if [ -n "$NUMBER" ]; then
  composed_title="${composed_title} (#${NUMBER})"
fi

fallback_body() {
  if [ -n "$NUMBER" ]; then
    printf 'Merged %s as pull request #%s.\n' "$unit_name" "$NUMBER"
  else
    printf 'Merged %s.\n' "$unit_name"
  fi
}

# --- Read the branch story ------------------------------------------------------------------
story_file=""
description=""
if [ -n "$BRANCH" ]; then
  for candidate in \
    ".workaholic/stories/${BRANCH}.md" \
    "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.workaholic/stories/${BRANCH}.md"
  do
    if [ -f "$candidate" ]; then story_file="$candidate"; break; fi
  done
  if [ -z "$story_file" ]; then
    # The story may live only on the branch itself -- a unit's story is committed there before
    # the merge, and this script often runs from a checkout standing on the base.
    for ref in "origin/${BRANCH}" "$BRANCH"; do
      if blob=$(git show "${ref}:.workaholic/stories/${BRANCH}.md" 2>/dev/null); then
        story_file="ref:${ref}"
        description=$(printf '%s\n' "$blob" | sed -n 's/^description:[[:space:]]*//p' | head -1)
        break
      fi
    done
  else
    description=$(sed -n 's/^description:[[:space:]]*//p' "$story_file" | head -1)
  fi
fi

# --- Compose the subject list, housekeeping dropped by its marker ----------------------------
subjects=""
subject_reason=""
omitted=0
if [ -n "$BRANCH" ]; then
  base_ref=""
  for candidate in origin/main main; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then base_ref="$candidate"; break; fi
  done
  head_ref=""
  for candidate in "origin/${BRANCH}" "$BRANCH"; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then head_ref="$candidate"; break; fi
  done
  if [ -n "$base_ref" ] && [ -n "$head_ref" ]; then
    # TWO WALKS, NOT ONE RECORD FORMAT. A single `%s%x00%b` walk is the obvious shape and it
    # cannot work here: a command substitution drops NUL bytes, so the body ran into the next
    # subject and every commit read as one. The second walk asks git itself which commits carry
    # the marker (`--grep` matches the whole message, trailers included) and the first subtracts
    # them -- no separator to lose, and the marker test stays git's own.
    all=$(git log --no-merges --reverse --format='%H %s' "${base_ref}..${head_ref}" 2>/dev/null || true)
    housekeeping=$(git log --no-merges --format='%H' --grep='^Workaholic-Housekeeping:' \
      "${base_ref}..${head_ref}" 2>/dev/null || true)
    subjects=$(printf '%s\n' "$all" | HOUSEKEEPING="$housekeeping" python3 -c '
import os, sys
skip = set(os.environ.get("HOUSEKEEPING", "").split())
seen = set(); out = []
for line in sys.stdin.read().splitlines():
    line = line.strip()
    if not line:
        continue
    sha, _, subject = line.partition(" ")
    subject = subject.strip()
    if not subject or sha in skip or subject in seen:
        continue
    seen.add(subject); out.append(subject)
print("\n".join(out))
' 2>/dev/null || true)
  else
    subject_reason="no_commit_range"
  fi
fi

# --- Assemble ---------------------------------------------------------------------------------
source_word=""
reason=""
if [ -n "$description" ]; then
  source_word="story"
  body="$description"
elif [ -n "$lookup_reason" ]; then
  source_word="unreadable:${lookup_reason}"
  reason="$lookup_reason"
  body=$(fallback_body)
elif [ -n "$subject_reason" ]; then
  source_word="unreadable:${subject_reason}"
  reason="$subject_reason"
  body=$(fallback_body)
else
  source_word="fallback"
  body=$(fallback_body)
fi

if [ -n "$subjects" ]; then
  kept_count=$(printf '%s\n' "$subjects" | grep -c . || true)
  shown=$(printf '%s\n' "$subjects" | head -"$MAX_SUBJECTS")
  if [ "$kept_count" -gt "$MAX_SUBJECTS" ]; then
    omitted=$((kept_count - MAX_SUBJECTS))
  fi
  body="${body}

$(printf '%s\n' "$shown" | sed 's/^/* /')"
  if [ "$omitted" -gt 0 ]; then
    body="${body}
* ... and ${omitted} further commit(s)."
  fi
fi

# The ceiling is applied last, so a truncated body still says it was truncated.
byte_len=$(printf '%s' "$body" | wc -c | tr -d ' ')
if [ "$byte_len" -gt "$MAX_BYTES" ]; then
  body="$(printf '%s' "$body" | cut -c1-"$MAX_BYTES")
... (body truncated at ${MAX_BYTES} bytes)"
fi

emit true "$composed_title" "$body" "$source_word" "$reason"
