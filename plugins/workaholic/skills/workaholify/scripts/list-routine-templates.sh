#!/bin/sh -eu
# List the routine TEMPLATES this plugin ships. Pure read.
#
#   list-routine-templates.sh
#
# Output (one JSON line):
#   {"count": N, "templates": [{"id","name_pattern","trigger","cron_expression","model"}]}
#
# ONE SET OF TEMPLATES, MANY REPOSITORIES. The templates live in the PLUGIN
# (`skills/workaholify/routines/*.md`), not in any repository's `.workaholic/`. That is
# the whole shape of the thing: `[FB]`, `Merged PR`, `[Drive]` and `[Propose]` are the
# routines every workaholic repository should have, and what differs between repositories is only which
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
  trigger=$(fm_field "$f" trigger)
  cron=$(fm_field "$f" cron_expression)
  model=$(fm_field "$f" model)

  entries="${entries}${sep}{\"id\": \"$(json_escape "$id")\", \"name_pattern\": \"$(json_escape "$name")\", \"trigger\": \"$(json_escape "$trigger")\", \"cron_expression\": \"$(json_escape "$cron")\", \"model\": \"$(json_escape "$model")\", \"path\": \"$(json_escape "$f")\"}"
  sep=", "
  count=$((count + 1))
done

printf '{"count": %s, "templates": [%s]}\n' "$count" "$entries"
