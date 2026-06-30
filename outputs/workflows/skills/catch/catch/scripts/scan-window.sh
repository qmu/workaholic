#!/bin/sh -eu
# scan-window.sh — Enumerate the developers active in a recent time window and the
# evidence trail (commits, tickets, stories) for a by-developer catch-up report (/catch).
#
# Usage: scan-window.sh [window]
#   window: any `git log --since` expression; defaults to "2 weeks ago".
#
# Output (JSON):
#   {
#     "window": "2 weeks ago",
#     "developers": [ { name, email, commit_count, commits: [ {hash, subject, timestamp, body} ] } ],
#     "tickets":    [ { path, author, title, scope } ],   scope in todo|archive|icebox
#     "stories":    [ "<path>", ... ]
#   }
#
# developers[] is grouped from `git log --since` (HEAD-reachable history, so it reflects
# the integrated development line rather than unmerged side branches) by author email.
# tickets[] carries each ticket's frontmatter author so collectors can group tickets on
# the same developer axis as commits. Records are delimited with ASCII unit (0x1f) and
# record (0x1e) separators so multi-line bodies and titles survive; jq splits on the
#  /  escapes and does all JSON escaping. The developer email is the join
# key; the by-developer report is assembled from these facts downstream, not here.

set -eu

WINDOW="${1:-2 weeks ago}"

# --- Time-bucket boundaries (epoch seconds) ---------------------------------
# Each commit is tagged into a bucket so collectors can summarize a developer's
# yesterday+today / this-week / last-week focus without doing date math in the LLM.
# Boundaries are UTC-day based (today midnight = epoch - epoch % 86400), precise
# enough for a focus narrative and avoiding non-POSIX `date -d` arithmetic.
NOW=$(date +%s)
DOW=$(date +%u)                              # 1=Mon .. 7=Sun
TODAY0=$(( NOW - NOW % 86400 ))              # today 00:00 UTC
RECENT_START=$(( TODAY0 - 86400 ))           # yesterday 00:00 (yesterday+today)
WEEK_START=$(( TODAY0 - (DOW - 1) * 86400 )) # Monday 00:00 of the current week
LAST_WEEK_START=$(( WEEK_START - 604800 ))   # Monday 00:00 of the previous week

# --- Developers + their commits in the window -------------------------------
# git emits %x1f/%x1e as literal 0x1f/0x1e bytes; jq splits on the same code points.
# --branches --source widens the scan beyond HEAD-reachable history so unmerged
# topic branches are visible, and each commit carries the branch (%S) it was reached
# from; %ct (committer epoch) drives the bucket assignment. The window (--since)
# still bounds it, so only branches with recent commits appear.
DEVELOPERS=$(
  git log --since="$WINDOW" --reverse --no-merges --branches --source \
    --format='%h%x1f%an%x1f%ae%x1f%s%x1f%cI%x1f%ct%x1f%S%x1f%b%x1e' 2>/dev/null \
  | jq -Rs \
      --argjson recent_start "$RECENT_START" \
      --argjson week_start "$WEEK_START" \
      --argjson last_week_start "$LAST_WEEK_START" '
      split("")
      | map(select((gsub("\\s"; "") | length) > 0))
      | map(ltrimstr("\n") | split(""))
      | map({
          hash: .[0], name: .[1], email: .[2],
          subject: .[3], timestamp: .[4],
          epoch: (.[5] | tonumber),
          branch: ((.[6] // "") | sub("^refs/heads/"; "")),
          body: ((.[7] // "") | sub("\n+$"; "")),
          bucket: ((.[5] | tonumber) as $e
            | if   $e >= $recent_start    then "recent"
              elif $e >= $week_start      then "this_week"
              elif $e >= $last_week_start then "last_week"
              else "older" end)
        })
      | group_by(.email)
      | map({
          name: .[0].name,
          email: .[0].email,
          commit_count: length,
          commits: map({hash, subject, timestamp, epoch, bucket, branch}),
          branches: (group_by(.branch)
            | map({name: .[0].branch, commit_count: length})
            | sort_by(.commit_count) | reverse)
        })'
)
[ -n "$DEVELOPERS" ] || DEVELOPERS='[]'

# --- Tickets across todo / archive / icebox ---------------------------------
TDIRS=""
for d in todo archive icebox; do
  if [ -d ".workaholic/tickets/$d" ]; then
    TDIRS="$TDIRS .workaholic/tickets/$d"
  fi
done

emit_tickets() {
  [ -n "$TDIRS" ] || return 0
  # word-splitting of $TDIRS is intended: it is a space-separated dir list we build.
  # shellcheck disable=SC2086
  find $TDIRS -name '*.md' -type f 2>/dev/null | sort | while IFS= read -r f; do
    author=$(sed -n 's/^author:[[:space:]]*//p' "$f" | head -n1)
    title=$(sed -n 's/^#[[:space:]]\{1,\}\(.*\)/\1/p' "$f" | head -n1)
    case "$f" in
      *.workaholic/tickets/todo/*) scope=todo ;;
      *.workaholic/tickets/archive/*) scope=archive ;;
      *.workaholic/tickets/icebox/*) scope=icebox ;;
      *) scope=unknown ;;
    esac
    printf '%s\037%s\037%s\037%s\036' "$f" "$author" "$title" "$scope"
  done
}

TICKETS=$(
  emit_tickets | jq -Rs '
    split("")
    | map(select((gsub("\\s"; "") | length) > 0))
    | map(split(""))
    | map({path: .[0], author: .[1], title: .[2], scope: .[3]})'
)
[ -n "$TICKETS" ] || TICKETS='[]'

# --- Branch stories ---------------------------------------------------------
STORIES='[]'
if [ -d ".workaholic/stories" ]; then
  STORIES=$(
    find .workaholic/stories -maxdepth 1 -name '*.md' -type f 2>/dev/null \
      | grep -v '/README\.md$' \
      | sort \
      | jq -Rs 'split("\n") | map(select(length > 0))'
  )
  [ -n "$STORIES" ] || STORIES='[]'
fi

WINDOW_JSON=$(printf '%s' "$WINDOW" | jq -Rs .)

cat <<EOF
{
  "window": ${WINDOW_JSON},
  "buckets": {
    "recent_start": ${RECENT_START},
    "week_start": ${WEEK_START},
    "last_week_start": ${LAST_WEEK_START}
  },
  "developers": ${DEVELOPERS},
  "tickets": ${TICKETS},
  "stories": ${STORIES}
}
EOF
