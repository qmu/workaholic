#!/bin/sh -eu
# List the routine TEMPLATES this plugin ships. Pure read.
#
#   list-routine-templates.sh [<scope>]
#
# Output (one JSON line):
#   {"count": N, "scope": "<filter or empty>",
#    "templates": [{"id","name_pattern","scope","trigger","cron_expression","model","notifications","sources","path"}]}
#
# THE SCOPE IS THE TEMPLATE'S OWN FIELD, NOT THE COMMAND'S (2026-08-14, issue #451).
# `/setup-dev-routines` and `/setup-repo-routines` differ only in which templates they
# converge, so the split has to live where both of them — and both setup sheets — read
# one source. Enumerating ids inside two commands would be the same list written twice,
# and the drift between them would be invisible exactly the way template drift was.
#   developer   every developer needs their own copy, per repository ([Specificate],
#               [Implement]) — configured by /setup-dev-routines
#   repository  the repository needs exactly ONE copy, configured by one account
#               ([Standup], [Moderate]) — /setup-repo-routines
# An optional positional filters the set; absent, every template is listed. A template
# declaring no scope is reported with an empty one and is never silently folded into
# any bucket — a missing scope is a defect in the template, not a default.
#
# THE `user` SCOPE IS RETIRED (2026-08-22, issue #557). It existed for exactly one
# template, `[Workaholic]`, an hourly routine that converged the account's other routines
# — and it could not: no `RemoteTrigger`-family tool is exposed to a clock-fired container,
# measured on the day it shipped and again from one of its own ticks. It converged zero
# routines on every tick of its life. Deleting the template emptied the scope, so the scope
# and its command went with it rather than surviving as a value nothing declares.
#
# The counting distinction it recorded was real and is kept in git history rather than in a
# dead branch here: `developer` multiplies by developers AND by repositories, `user` by
# neither. If a template ever needs that shape again, this is the commit to read; a scope
# with no template is not a place to put one, it is dead code.

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
  notifications=$(fm_field "$f" notifications)
  # Read here as well as in render-routine.sh: a template field only one of the two readers
  # knows about is the drift `scope:` was centralised to avoid (2026-09-02).
  sources=$(fm_field "$f" sources)

  [ -z "$WANT_SCOPE" ] || [ "$scope" = "$WANT_SCOPE" ] || continue

  entries="${entries}${sep}{\"id\": \"$(json_escape "$id")\", \"name_pattern\": \"$(json_escape "$name")\", \"scope\": \"$(json_escape "$scope")\", \"trigger\": \"$(json_escape "$trigger")\", \"cron_expression\": \"$(json_escape "$cron")\", \"model\": \"$(json_escape "$model")\", \"notifications\": \"$(json_escape "$notifications")\", \"sources\": \"$(json_escape "$sources")\", \"path\": \"$(json_escape "$f")\"}"
  sep=", "
  count=$((count + 1))
done

printf '{"count": %s, "scope": "%s", "templates": [%s]}\n' "$count" "$(json_escape "$WANT_SCOPE")" "$entries"
