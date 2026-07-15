#!/bin/sh -eu
# scan-window.sh — Enumerate the developers active in a recent time window and the
# evidence trail (commits, tickets, stories, deployments) for a by-developer
# catch-up report (/catch).
#
# Usage: scan-window.sh [window]
#   window: any `git log --since` expression; defaults to "2 weeks ago".
#
# Output (JSON): { window, fetch_ok, buckets, developers[], tickets[], stories[], deployments[] }.
# fetch_ok reports whether the best-effort `git fetch` at startup succeeded; false
# means the remote view could not be refreshed and the scan may be stale.
# Records are delimited with ASCII unit (0x1f) and record (0x1e) separators so
# multi-line bodies/titles survive: git emits them via %x1f/%x1e, the shell via
# octal \037/\036, and jq splits on the matching  /  escapes and does
# all JSON escaping. The developer email is the by-developer join key; the report
# is assembled from these facts downstream, not here.

set -eu

WINDOW="${1:-2 weeks ago}"
SCRIPT_DIR=$(dirname "$0")

# --- Refresh remote-tracking refs (best-effort, non-fatal) ------------------
# /catch answers "what has everyone pushed", so refresh refs/remotes/* before
# scanning. This is the one write /catch performs, and it touches only
# remote-tracking refs -- never the working tree, the index, or any project file.
# It is best-effort: on failure (offline, no remote, auth) we proceed from
# whatever refs are already local and report the staleness via fetch_ok downstream
# rather than aborting the report. set -eu is active, so the `if` neutralizes a
# non-zero fetch exit instead of letting it terminate the script.
FETCH_OK=false
if git fetch --quiet --all --prune 2>/dev/null; then
  FETCH_OK=true
fi

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
# --branches --remotes --source widens the scan beyond HEAD-reachable history so
# unmerged local topic branches AND branches that live only on a remote (other
# developers' pushed-but-unpulled work, now refreshed by the fetch above) are
# visible. Each commit carries the branch (%S) it was reached from; --source emits
# each commit exactly once, so a commit present on both a local head and a remote
# ref is not double-counted. --exclude drops the symbolic refs/remotes/*/HEAD so a
# commit is never mis-attributed to a branch named "HEAD". %ct (committer epoch)
# drives the bucket assignment; the window (--since) still bounds it.
#
# %S emits the branch shortened: a local head as `feature`, a remote-only ref as
# `origin/feature` (and, on some git versions, the full `refs/heads/…`/`refs/remotes/…`).
# REMOTES carries the configured remote names so strip_branch (in the jq below) can
# normalize every form to the bare branch name, collapsing `origin/feature` and a
# local `feature` into one entry.
REMOTES=$(git remote 2>/dev/null | jq -Rs 'split("\n") | map(select(length > 0))')
[ -n "$REMOTES" ] || REMOTES='[]'

DEVELOPERS=$(
  git log --since="$WINDOW" --reverse --no-merges \
    --exclude='refs/remotes/*/HEAD' --branches --remotes --source \
    --format='%h%x1f%an%x1f%ae%x1f%s%x1f%cI%x1f%ct%x1f%S%x1f%b%x1e' 2>/dev/null \
  | jq -Rs \
      --argjson recent_start "$RECENT_START" \
      --argjson week_start "$WEEK_START" \
      --argjson last_week_start "$LAST_WEEK_START" \
      --argjson remotes "$REMOTES" '
      def strip_branch:
        sub("^refs/heads/"; "")
        | sub("^refs/remotes/"; "")
        | . as $b
        | ([$remotes[] | . + "/" | select($b | startswith(.))] | first) as $pfx
        | if $pfx then $b[($pfx | length):] else $b end;
      split("")
      | map(select((gsub("\\s"; "") | length) > 0))
      | map(ltrimstr("\n") | split(""))
      | map({
          hash: .[0], name: .[1], email: .[2],
          subject: .[3], timestamp: .[4],
          epoch: (.[5] | tonumber),
          branch: ((.[6] // "") | strip_branch),
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
    # `mission:` is optional ticket frontmatter (empty until set) and MANY-valued — the
    # join key(s) to missions. Read through the mission skill's single reader, which
    # accepts both `mission: [a, b]` and a bare `mission: a`, then carried through this
    # record comma-joined and split back into an array by the jq below. Absent fields emit
    # "" and never fail the scan.
    mission=$(sh "${SCRIPT_DIR}/../../mission/scripts//read-relation.sh" "$f" 2>/dev/null | paste -sd, - || true)
    case "$f" in
      *.workaholic/tickets/todo/*) scope=todo ;;
      *.workaholic/tickets/archive/*) scope=archive ;;
      *.workaholic/tickets/icebox/*) scope=icebox ;;
      *) scope=unknown ;;
    esac
    # commit_hash ties an archived ticket to the commit that implemented it. Derive it
    # from git — the commit that ADDED the archived ticket — never from frontmatter: a
    # commit cannot carry its own hash, so the value archive.sh used to stamp named a
    # pre-amend commit that is orphaned and never pushed (see report/scripts/ticket-commits.sh,
    # the single source of truth for this derivation). Only archived tickets have one.
    commit_hash=""
    if [ "$scope" = archive ]; then
      commit_hash=$(git log --diff-filter=A --format=%h -- "$f" 2>/dev/null | head -n1 || true)
    fi
    printf '%s\037%s\037%s\037%s\037%s\037%s\036' \
      "$f" "$author" "$title" "$scope" "$mission" "$commit_hash"
  done
}

TICKETS=$(
  emit_tickets | jq -Rs '
    split("")
    | map(select((gsub("\\s"; "") | length) > 0))
    | map(split(""))
    | map({path: .[0], author: .[1], title: .[2], scope: .[3],
           mission: (.[4] | if . == "" then [] else split(",") end),
           commit_hash: .[5]})'
)
[ -n "$TICKETS" ] || TICKETS='[]'

# --- Missions: active list + progress + this-window activity -----------------
# The mission axis for /catch. Reuse the mission skill's OWN readers as the domain
# interface (list.sh -> {slug,title,status,checked,total}; progress stays derived,
# never stored), then attach two window-scoped views per mission without writing
# anything:
#   - window_events: the mission's append-only ## Changelog lines dated within the
#     window (MERGED activity: ticket archived / story reported / concern events).
#   - in_flight: UNMERGED tickets carrying `mission: <slug>` that are not yet
#     archived (no commit_hash) -- progress toward the mission from work still on a
#     branch, which the merge-time changelog cannot yet show.
# Read-only: a /catch scan mutates no mission file content (no changelog append,
# no tick). The one tree change it can trigger is the mission scripts' living
# layout migration (flat -> active|archive), which the list.sh call below runs.

# Emit each mission's changelog entries as a slug-tagged record stream so jq can
# window-filter them by date. Missions are walked across both areas (active/ and
# archive/) plus any legacy flat dir the migration could not move. A changelog
# line is `- <YYYY-MM-DD> — <event> — <artifact>` inside the `## Changelog`
# section; events carry no " — " so a split on " — " yields exactly
# [date, event, artifact].
emit_changelog_events() {
  [ -d ".workaholic/missions" ] || return 0
  for d in $(
    {
      find .workaholic/missions/active .workaholic/missions/archive -maxdepth 1 -mindepth 1 -type d 2>/dev/null
      find .workaholic/missions -maxdepth 1 -mindepth 1 -type d ! -name active ! -name archive 2>/dev/null
    } | awk -F/ '{print $NF "\t" $0}' | LC_ALL=C sort | cut -f2-
  ); do
    f="$d/mission.md"
    [ -f "$f" ] || continue
    slug=$(basename "$d")
    awk -v slug="$slug" '
      /^## / { in_cl = ($0 ~ /^##[ \t]+Changelog[ \t]*$/); next }
      in_cl && /^[ \t]*-[ \t]+[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][ \t]/ {
        line = $0
        sub(/^[ \t]*-[ \t]+/, "", line)
        n = split(line, p, / — /)
        gsub(/[ \t]+$/, "", p[1])
        printf "%s\037%s\037%s\037%s\036", slug, p[1], p[2], p[n]
      }
    ' "$f"
  done
}

MISSIONS='[]'
if [ -d ".workaholic/missions" ]; then
  # Window start as a YYYY-MM-DD string, resolved by git's own date engine (the
  # same --since the scan uses) so "this window" is defined consistently and we
  # avoid non-POSIX `date -d` arithmetic. Empty when no commit falls in the window.
  WINDOW_START_DATE=$(git log --since="$WINDOW" --branches --remotes \
    --format=%cd --date=format:'%Y-%m-%d' --reverse 2>/dev/null | head -n1 || true)

  MLIST=$(sh "${SCRIPT_DIR}/../../mission/scripts//list.sh" 2>/dev/null || echo '[]')
  [ -n "$MLIST" ] || MLIST='[]'

  MISSIONS=$(
    emit_changelog_events | jq -Rs \
      --argjson list "$MLIST" \
      --argjson tickets "$TICKETS" \
      --arg cutoff "$WINDOW_START_DATE" '
      ( split("")
        | map(select((gsub("\\s"; "") | length) > 0))
        | map(split("") | {slug: .[0], date: .[1], event: .[2], artifact: .[3]})
      ) as $events
      | $list
      | map(
          .slug as $s
          | . + {
              window_events: ( $events
                | map(select(.slug == $s and ($cutoff == "" or .date >= $cutoff)))
                | map({date, event, artifact}) ),
              in_flight: ( $tickets
                | map(select((.mission | index($s)) and .scope != "archive"))
                | map({path, title, author, scope}) )
            }
        )'
  )
  [ -n "$MISSIONS" ] || MISSIONS='[]'
fi

# --- Branch stories ---------------------------------------------------------
STORIES='[]'
if [ -d ".workaholic/stories" ]; then
  STORIES=$(
    find .workaholic/stories -maxdepth 1 -name '*.md' -type f 2>/dev/null \
      | grep -vE '/(README|index)\.md$' \
      | sort \
      | jq -Rs 'split("\n") | map(select(length > 0))'
  )
  [ -n "$STORIES" ] || STORIES='[]'
fi

# --- Deployments / releases this week ---------------------------------------
# Read the ship-produced `## Deployment Evidence` block from each branch story
# (record-evidence.sh writes When/Status/Observed) and join the release title from
# the matching release-notes/<branch>.md (its H1). Stories and release-notes carry
# no author, so a deployment is attributed to the git author of the commit that last
# touched the story (the ship commit), keyed by branch. Filtered to this calendar
# week (ship-commit epoch >= WEEK_START). The confirmation comment is the `Observed:`
# value; an empty one signals the /ship-can-capture-it fallback downstream.
emit_deployments() {
  [ -d ".workaholic/stories" ] || return 0
  find .workaholic/stories -maxdepth 1 -name '*.md' -type f 2>/dev/null \
    | grep -vE '/(README|index)\.md$' | sort | while IFS= read -r f; do
      grep -q '^## Deployment Evidence' "$f" || continue
      epoch=$(git log -1 --format=%ct -- "$f" 2>/dev/null)
      [ -n "$epoch" ] || continue
      [ "$epoch" -ge "$WEEK_START" ] || continue
      branch=$(basename "$f" .md)
      author=$(git log -1 --format=%ae -- "$f" 2>/dev/null)
      when=$(sed -n 's/^- \*\*When:\*\*[[:space:]]*//p' "$f" | head -n1)
      status=$(sed -n 's/^- \*\*Status:\*\*[[:space:]]*//p' "$f" | head -n1)
      observed=$(sed -n 's/^- \*\*Observed:\*\*[[:space:]]*//p' "$f" | head -n1)
      rel=".workaholic/release-notes/${branch}.md"
      if [ -f "$rel" ]; then
        title=$(sed -n 's/^#[[:space:]]\{1,\}\(.*\)/\1/p' "$rel" | head -n1)
      else
        title=$(sed -n 's/^#[[:space:]]\{1,\}\(.*\)/\1/p' "$f" | head -n1)
      fi
      printf '%s\037%s\037%s\037%s\037%s\037%s\036' \
        "$branch" "$author" "$when" "$title" "$status" "$observed"
    done
}

DEPLOYMENTS=$(
  emit_deployments | jq -Rs '
    split("")
    | map(select((gsub("\\s"; "") | length) > 0))
    | map(split(""))
    | map({
        branch: .[0], author: .[1], timestamp: .[2],
        release_title: .[3], status: .[4], confirmation: .[5]
      })'
)
[ -n "$DEPLOYMENTS" ] || DEPLOYMENTS='[]'

WINDOW_JSON=$(printf '%s' "$WINDOW" | jq -Rs .)

cat <<EOF
{
  "window": ${WINDOW_JSON},
  "fetch_ok": ${FETCH_OK},
  "buckets": {
    "recent_start": ${RECENT_START},
    "week_start": ${WEEK_START},
    "last_week_start": ${LAST_WEEK_START}
  },
  "developers": ${DEVELOPERS},
  "tickets": ${TICKETS},
  "stories": ${STORIES},
  "deployments": ${DEPLOYMENTS},
  "missions": ${MISSIONS}
}
EOF
