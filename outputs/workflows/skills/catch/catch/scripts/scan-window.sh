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

# --- Developers + their commits in the window -------------------------------
# git emits %x1f/%x1e as literal 0x1f/0x1e bytes; jq splits on the same code points.
DEVELOPERS=$(
  git log --since="$WINDOW" --reverse --no-merges \
    --format='%h%x1f%an%x1f%ae%x1f%s%x1f%cI%x1f%b%x1e' 2>/dev/null \
  | jq -Rs '
      split("")
      | map(select((gsub("\\s"; "") | length) > 0))
      | map(ltrimstr("\n") | split(""))
      | map({
          hash: .[0], name: .[1], email: .[2],
          subject: .[3], timestamp: .[4],
          body: ((.[5] // "") | sub("\n+$"; ""))
        })
      | group_by(.email)
      | map({
          name: .[0].name,
          email: .[0].email,
          commit_count: length,
          commits: map({hash, subject, timestamp, body})
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
  "developers": ${DEVELOPERS},
  "tickets": ${TICKETS},
  "stories": ${STORIES}
}
EOF
