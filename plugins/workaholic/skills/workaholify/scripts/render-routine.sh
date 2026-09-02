#!/bin/sh -eu
# Render one routine template for a repository: the prompt with its substitutions applied,
# plus the fields a `RemoteTrigger` create/update body needs. Pure read, no API call.
#
#   render-routine.sh <template-id> <repo-url>
#
# Output (one JSON line):
#   {"id","name","scope","trigger","cron_expression","autofix_on_pr_create","model",
#    "allowed_tools","mcp","sources","notifications",
#    "allowed_tools_json","mcp_json","sources_json","repo","repo_name","repo_slug","prompt"}
#   {"error": "unknown_template"|"no_repo_url", ...}
#
# TWO SPELLINGS OF THE SAME THREE LISTS, AND BOTH ARE EMITTED. `allowed_tools`, `mcp` and
# `sources` come back as the frontmatter's own display string (`"[Bash, Read]"`) — what the
# setup sheet prints for a human to paste — AND as `*_json` twins, which is the shape the
# record actually stores. The twins are ADDED, never a mode: every pre-existing key keeps
# its bytes, so the sheet and every other caller are untouched, and `build-routine-body.sh`
# never has to parse a display string back apart.
#
# THREE SUBSTITUTIONS, AND ONLY THREE — each one demanded by the live routines:
#   {repo}       the full repository URL   — https://github.com/qmu/workaholic
#                (the `…/pull/123` links in the Slack formats). Accepts any of the
#                three remote spellings and renders the https one, so an SSH-form
#                checkout does not bake `git@github.com:owner/name/pull/123` into a
#                live routine. The reported `repo` field stays as the caller wrote it.
#   {repo_slug}  org/repo                  — qmu/workaholic
#                (how the Drive prompt names the repository in prose)
#   {repo_name}  the bare repository name  — workaholic
#                (the routine's own name, and the `dev-<name>` Slack channel)
# Anything else that differs between two repositories' routines is drift, not
# configuration — which is exactly what the comparison step is for.
#
# THE PROMPT IS EVERYTHING BELOW `## Prompt`. The heading itself is dropped; the rest is
# passed through byte-for-byte, because a template that reformats the prompt on the way out
# would make every existing routine read as drifted on its first comparison.
#
# THE CALLER BUILDS THE API BODY. This script deliberately does not emit a `job_config`:
# the environment id is an account-level fact this repository has no business hardcoding,
# and HOW MANY an account has is not this repository's claim to make either — the count is
# enumerated at run time, and the one account measured (twice: 2026-08-20 and 2026-09-02)
# had exactly one. The record's own shape is written down field by field in
# reference/routines.md, *The routine record, read back field by field*.
# A routine carries no environment variables either — it selects an environment and the
# variables live on that record, so no field for them is emitted or expected here. The rule
# and the measurement behind it: SKILL.md, *Where a routine's environment variables live*.

set -eu

ID="${1:-}"
REPO="${2:-}"

[ -n "$ID" ] || { echo '{"error": "no_template_id"}'; exit 1; }
[ -n "$REPO" ] || { echo '{"error": "no_repo_url"}'; exit 1; }

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
FILE="${SCRIPT_DIR}/../routines/${ID}.md"

if [ ! -f "$FILE" ]; then
  printf '{"error": "unknown_template", "id": "%s"}\n' "$ID"
  exit 1
fi

# Bare name from the URL, tolerating a trailing slash or .git.
REPO_CLEAN=$(printf '%s' "$REPO" | sed -e 's#/$##' -e 's#\.git$##')
REPO_NAME=$(printf '%s' "$REPO_CLEAN" | sed -e 's#.*/##')
# org/repo — the last two path segments, however the URL was written.
REPO_SLUG=$(printf '%s' "$REPO_CLEAN" | sed -e 's#^.*://[^/]*/##' -e 's#^git@[^:]*:##')
# `{repo}` becomes a LINK: the templates build `…/pull/123` out of it, and a created
# routine carries whatever is rendered here into a live standing process. An SSH remote
# names the same repository in a spelling no link can use, so the two SSH forms are
# canonicalized to https. A URL that already carries a scheme is left EXACTLY as given —
# a proxied `http://…` remote is not ours to rewrite, and forcing https would break it.
# For a clean https URL this is a no-op, so nothing that worked before changes.
REPO_URL=$(printf '%s' "$REPO_CLEAN" \
  | sed -e 's#^ssh://[^@/]*@#https://#' \
        -e 's#^ssh://#https://#' \
        -e 's#^\([^:/]*\)@\([^:/]*\):#https://\2/#')

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' | awk '{ printf "%s\\n", $0 }' | sed -e 's/\\n$//'
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

# `[Bash, Read]` -> `["Bash","Read"]`. The frontmatter's list spelling is what the setup
# sheet prints for a human to paste; the record stores a real array
# (reference/routines.md, *Template field -> record field*). Both are emitted, so no caller
# ever parses the display string back apart. An absent or empty field is `[]`, never null.
json_array() {
  printf '%s' "$1" | awk '
    {
      s = $0
      sub(/^[ \t]*\[/, "", s); sub(/\][ \t]*$/, "", s)
      gsub(/^[ \t]+|[ \t]+$/, "", s)
      if (s == "") { print "[]"; exit }
      n = split(s, parts, ",")
      out = ""
      for (i = 1; i <= n; i++) {
        v = parts[i]
        gsub(/^[ \t]+|[ \t]+$/, "", v)
        gsub(/^"|"$/, "", v)
        if (v == "") continue
        gsub(/\\/, "\\\\", v); gsub(/"/, "\\\"", v)
        out = out (out == "" ? "" : ", ") "\"" v "\""
      }
      print "[" out "]"
    }
    END { if (NR == 0) print "[]" }
  '
}

subst() {
  printf '%s' "$1" \
    | sed -e "s#{repo_name}#${REPO_NAME}#g" \
          -e "s#{repo_slug}#${REPO_SLUG}#g" \
          -e "s#{repo}#${REPO_URL}#g"
}

name=$(subst "$(fm_field "$FILE" name)")
scope=$(fm_field "$FILE" scope)
trigger=$(fm_field "$FILE" trigger)
cron=$(fm_field "$FILE" cron_expression)
autofix=$(fm_field "$FILE" autofix_on_pr_create)
model=$(fm_field "$FILE" model)
tools=$(fm_field "$FILE" allowed_tools)
mcp=$(fm_field "$FILE" mcp)
# `notifications` is the Claude-app channel on the record, NOT a Slack post. Only the
# account-level routine declares it (2026-08-19): its audience is its own operator, who is
# also the only person who can act on its refusal. Absent means off, which is every other
# template — a routine whose result already reaches a channel must not also push.
notifications=$(fm_field "$FILE" notifications)
# WHICH REPOSITORY THE ROUTINE CHECKS OUT, as data rather than prose (2026-09-02). It lands
# at `session_request.config.sources[].git_repository.url` on the record. Every template
# declares the repository being wired (`{repo}`); the field exists as a field, not a
# constant, because the one template that named a DIFFERENT repository — the retired
# `[Workaholic]` — stated it only in a paragraph, which is what made a caller read prose to
# build a body. A template declaring none renders `[]` and the body builder refuses.
sources=$(subst "$(fm_field "$FILE" sources)")

# Everything after the `## Prompt` heading, verbatim, with the substitutions applied.
prompt_raw=$(awk '
  found { print; next }
  /^## Prompt[ \t]*$/ { found = 1 }
' "$FILE" | sed -e '1{/^$/d}')
prompt=$(subst "$prompt_raw")

printf '{"id": "%s", "name": "%s", "scope": "%s", "trigger": "%s", "cron_expression": "%s", "autofix_on_pr_create": "%s", "model": "%s", "allowed_tools": "%s", "mcp": "%s", "sources": "%s", "notifications": "%s", "allowed_tools_json": %s, "mcp_json": %s, "sources_json": %s, "repo": "%s", "repo_name": "%s", "repo_slug": "%s", "prompt": "%s"}\n' \
  "$ID" "$name" "$scope" "$trigger" "$cron" "$autofix" "$model" "$tools" "$mcp" "$sources" "$notifications" \
  "$(json_array "$tools")" "$(json_array "$mcp")" "$(json_array "$sources")" \
  "$REPO" "$REPO_NAME" "$REPO_SLUG" "$(json_escape "$prompt")"
