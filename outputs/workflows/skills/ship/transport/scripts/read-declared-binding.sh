#!/bin/sh -eu
# Read the repository's own declared Slack binding. Pure read; writes nothing.
#
#   read-declared-binding.sh --root REPO [--scope RELDIR]...
#
# The declaration is a fenced block in the repository's instruction file, so every agent
# reads it from the surface it already loads and no agent has to read CLAUDE.md:
#
#   ```workaholic-slack-binding
#   workspace: qmu
#   channel: dev-workaholic
#   mount: /slack/qmu
#   sender_id: U0123
#   operations: read_channel_delta, read_thread, post_root, post_reply
#   fallback: connector
#   ```
#
# Sources, in ascending precedence: `CLAUDE.md`, `AGENTS.md`, then the same two under each
# `--scope` directory (deeper wins), then `WORKAHOLIC_SLACK_BINDING_FILE`. A deeper scope
# OVERRIDES a shallower one — that is what nesting is for. Two sources at the SAME depth
# giving one key two different values is a CONFLICT: it is reported, and no value is picked,
# because guessing which instruction file the operator meant is the failure this reader exists
# to prevent.
#
# `declared: false` is an ordinary answer, never an error — a repository that declares nothing
# behaves exactly as it did before this existed, on its environment variables.
#
# Output (one JSON line):
#   {"ok":true,"declared":true,"sources":[…],"binding":{…},"declared_digest":"…",
#    "missing":[],"conflicts":[],"unknown_keys":[],"invalid":[],"complete":true,"reason":""}
#
# `missing[]` is the REQUIRED keys (workspace, channel) that are absent. `complete` says
# whether the binding also carries what a route can actually be VERIFIED against
# (mount/account and sender_id); a complete: false binding is usable and is reported as
# partial, never refused here — refusing is the caller's ruling, not the reader's.

ROOT="" ; SCOPES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=${2:-}; shift 2 ;;
    --scope) SCOPES="${SCOPES}${SCOPES:+ }${2:-}"; shift 2 ;;
    *) printf '{"ok":false,"declared":false,"reason":"invalid_argument"}\n'; exit 2 ;;
  esac
done
[ -n "$ROOT" ] && [ -d "$ROOT" ] || { printf '{"ok":false,"declared":false,"reason":"no_root"}\n'; exit 2; }

REQUIRED='workspace channel'
KNOWN='workspace channel channel_id mount account sender_id operations fallback'
OPERATIONS='discover read_channel_delta read_thread list_thread_changes search_exact post_root post_reply add_reaction reconcile_send'
TRANSPORTS='connector slack_token'

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
: >"$tmp/entries"
: >"$tmp/errors"

# depth 0 = repository root, 1..n = each --scope in the order given, 99 = explicit override.
extract() {
  _file=$1 _depth=$2 _label=$3
  [ -f "$_file" ] || return 0
  [ -r "$_file" ] || { printf 'unreadable\t%s\n' "$_label" >>"$tmp/errors"; return 0; }
  awk -v depth="$_depth" -v label="$_label" '
    /^[ \t]*```[ \t]*workaholic-slack-binding[ \t]*$/ { if (inblock) { print "unterminated\t" label > "/dev/stderr"; } inblock=1; next }
    /^[ \t]*```/ { if (inblock) inblock=0; next }
    inblock {
      line=$0
      sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      pos=index(line, ":")
      if (pos == 0) { print "malformed\t" label "\t" line > "/dev/stderr"; next }
      key=substr(line, 1, pos-1); value=substr(line, pos+1)
      sub(/[ \t]+$/, "", key); sub(/^[ \t]+/, "", value); sub(/[ \t]+$/, "", value)
      if (key == "" || value == "") { print "malformed\t" label "\t" line > "/dev/stderr"; next }
      print depth "\t" label "\t" key "\t" value
    }
    END { if (inblock) print "unterminated\t" label > "/dev/stderr" }
  ' "$_file" 2>>"$tmp/errors" >>"$tmp/entries"
}

extract "$ROOT/CLAUDE.md" 0 CLAUDE.md
extract "$ROOT/AGENTS.md" 0 AGENTS.md
_n=0
for scope in $SCOPES; do
  _n=$((_n + 1))
  extract "$ROOT/$scope/CLAUDE.md" "$_n" "$scope/CLAUDE.md"
  extract "$ROOT/$scope/AGENTS.md" "$_n" "$scope/AGENTS.md"
done
if [ -n "${WORKAHOLIC_SLACK_BINDING_FILE:-}" ]; then
  case "$WORKAHOLIC_SLACK_BINDING_FILE" in
    /*) extract "$WORKAHOLIC_SLACK_BINDING_FILE" 99 "$WORKAHOLIC_SLACK_BINDING_FILE" ;;
    *) extract "$ROOT/$WORKAHOLIC_SLACK_BINDING_FILE" 99 "$WORKAHOLIC_SLACK_BINDING_FILE" ;;
  esac
fi

entries=$(jq -Rsc 'split("\n") | map(select(length > 0) | split("\t") | {depth:(.[0]|tonumber), source:.[1], key:.[2], value:.[3]})' "$tmp/entries")
errors=$(jq -Rsc 'split("\n") | map(select(length > 0) | split("\t") | {kind:.[0], source:.[1], detail:(.[2] // null)})' "$tmp/errors")

result=$(printf '%s' "$entries" | jq -c \
  --argjson errors "$errors" \
  --arg required "$REQUIRED" --arg known "$KNOWN" --arg operations "$OPERATIONS" --arg transports "$TRANSPORTS" '
  ($required|split(" ")) as $required |
  ($known|split(" ")) as $known |
  ($operations|split(" ")) as $ops |
  ($transports|split(" ")) as $transports |
  . as $entries |
  ([$entries[].source] | unique) as $sources |
  # A key resolves at its DEEPEST declaring scope; two sources at that same depth
  # disagreeing is a conflict and yields no value at all.
  ([$entries[].key] | unique) as $keys |
  ([$keys[] as $k |
     ([$entries[] | select(.key == $k)]) as $rows |
     ([$rows[].depth] | max) as $deep |
     ([$rows[] | select(.depth == $deep)]) as $winners |
     ([$winners[].value] | unique) as $values |
     {key:$k, values:$values, sources:[$winners[].source]}]) as $resolved |
  ([$resolved[] | select(.values|length > 1) | {key, values, sources}]) as $conflicts |
  ([$resolved[] | select((.key|IN($known[])) | not) | .key] | unique) as $unknown |
  ([$resolved[] | select(.values|length == 1) | select(.key|IN($known[]))]) as $settled |
  (reduce $settled[] as $r ({};
     .[$r.key] =
       (if $r.key == "operations" or $r.key == "fallback"
        then ($r.values[0] | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(length > 0)))
        else $r.values[0] end))) as $binding |
  ([($binding.operations // [])[] | select((. | IN($ops[])) | not) | {field:"operations", value:.}] +
   [($binding.fallback // [])[] | select((. | IN($transports[])) | not) | {field:"fallback", value:.}]) as $invalid |
  ([$required[] | select(($binding[.] // "") == "")]) as $missing |
  {ok:(($errors|length) == 0),
   declared:(($settled|length) > 0 or ($conflicts|length) > 0),
   sources:$sources,
   binding:$binding,
   missing:$missing,
   conflicts:$conflicts,
   unknown_keys:$unknown,
   invalid:$invalid,
   errors:$errors,
   complete:(($missing|length) == 0 and ($conflicts|length) == 0 and ($invalid|length) == 0
             and (($binding.sender_id // "") != "")
             and ((($binding.mount // "") != "") or (($binding.account // "") != ""))),
   reason:(if ($errors|length) > 0 then ($errors[0].kind + ":" + $errors[0].source)
           elif ($conflicts|length) > 0 then "contradictory_declaration"
           elif ($settled|length) == 0 then "no_declaration"
           elif ($missing|length) > 0 then "incomplete_declaration"
           elif ($invalid|length) > 0 then "invalid_declaration"
           else "" end)}')

digest=$(printf '%s' "$result" | jq -Sc .binding | sha256sum | cut -c1-32)
printf '%s' "$result" | jq -c --arg digest "$digest" '. + {declared_digest:(if .declared then $digest else null end)}'
