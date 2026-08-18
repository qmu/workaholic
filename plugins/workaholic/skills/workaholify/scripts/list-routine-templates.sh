#!/bin/sh -eu
# List the routine TEMPLATES this plugin ships. Pure read.
#
#   list-routine-templates.sh [<scope>]
#
# Output (one JSON line):
#   {"count": N, "scope": "<filter or empty>",
#    "templates": [{"id","name_pattern","scope","trigger","cron_expression","model",
#                   "notifications","path"}]}
#
# THE SCOPE IS THE TEMPLATE'S OWN FIELD, NOT THE COMMAND'S (2026-08-14, issue #451).
# `/setup-dev-routines` and `/setup-repo-routines` differ only in which templates they
# converge, so the split has to live where both of them — and both setup sheets — read
# one source. Enumerating ids inside two commands would be the same list written twice,
# and the drift between them would be invisible exactly the way template drift was.
#   developer   every developer needs their own copy ([Propose], [Implement])
#   repository  the repository needs exactly ONE copy, configured by one account
# An optional positional filters the set; absent, every template is listed. A template
# declaring no scope is reported with an empty one and is never silently folded into
# either bucket — a missing scope is a defect in the template, not a default.
#
# ONE SET OF TEMPLATES, MANY REPOSITORIES. The templates live in the PLUGIN
# (`skills/workaholify/routines/*.md`), not in any repository's `.workaholic/`. That is
# the whole shape of the thing: `[Propose]` and `[Implement]` are the two routines
# every workaholic repository should have, and what differs between repositories is only which
# repository they point at. A per-repository declaration would be one copy per repo of a
# file that is identical in every repo except its own URL — and each copy free to drift.
#
# THE PROMPT BODY IS THE TEMPLATE. Everything below the `## Prompt` heading of a template
# file is the routine's prompt, verbatim, with `{repo}` (full URL) and `{repo_name}` (bare
# name, used for the `dev-<name>` Slack channel) as the only substitutions. Keeping it as
# readable markdown rather than an embedded JSON string is deliberate: the prompt IS the
# routine — the issue that asked for this called template freshness the point — and a
# prompt nobody can read in a diff is a prompt nobody will keep current.
#
# THIS SCRIPT NEVER TALKS TO THE API. Fetching and writing routines is the `RemoteTrigger`
# tool's job, which only the command (main-agent) can call; a shell script cannot. So the
# split is: scripts own the template reading and the comparison, the command owns the API
# calls and the confirmation.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
DIR="${SCRIPT_DIR}/../routines"
WANT_SCOPE="${1:-}"

case "$WANT_SCOPE" in
  ''|developer|repository) ;;
  *) printf '{"error": "unknown_scope", "scope": "%s"}\n' "$WANT_SCOPE" >&2; exit 2 ;;
esac

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

fm_field() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm {
      idx = index($0, ":")
      if (idx > 0 && substr($0, 1, idx - 1) == key) {
        v = substr($0, idx + 1)
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        if (v ~ /^".*"$/) { v = substr(v, 2, length(v) - 2) }
        print v; exit
      }
    }
  ' "$1"
}

entries=""
sep=""
count=0

for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  id=$(fm_field "$f" id)
  [ -n "$id" ] || id=$(basename "$f" .md)
  name=$(fm_field "$f" name)
  scope=$(fm_field "$f" scope)
  trigger=$(fm_field "$f" trigger)
  cron=$(fm_field "$f" cron_expression)
  model=$(fm_field "$f" model)
  # The app's completion notification, reported per template so a template that declares
  # nothing is visible as a defect rather than folded into the server's default.
  notifications=$(fm_field "$f" notifications)

  [ -z "$WANT_SCOPE" ] || [ "$scope" = "$WANT_SCOPE" ] || continue

  entries="${entries}${sep}{\"id\": \"$(json_escape "$id")\", \"name_pattern\": \"$(json_escape "$name")\", \"scope\": \"$(json_escape "$scope")\", \"trigger\": \"$(json_escape "$trigger")\", \"cron_expression\": \"$(json_escape "$cron")\", \"model\": \"$(json_escape "$model")\", \"notifications\": \"$(json_escape "$notifications")\", \"path\": \"$(json_escape "$f")\"}"
  sep=", "
  count=$((count + 1))
done

printf '{"count": %s, "scope": "%s", "templates": [%s]}\n' "$count" "$(json_escape "$WANT_SCOPE")" "$entries"
