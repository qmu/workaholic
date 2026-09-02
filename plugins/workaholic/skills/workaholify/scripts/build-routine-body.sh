#!/bin/sh -eu
# Build ONE routine's create/update request body, in one place. Pure read, no API call.
#
#   build-routine-body.sh <template-id> <repo-url> <environment-id>
#
# Output (one JSON line):
#   {"id","name","environment_id","body_shape","body_shape_verified","fields":{…},"body":{…}}
#   {"error": "no_environment_id"|"no_sources"|"unknown_template"|"no_repo_url", …}
#
# WHY A SIBLING AND NOT A MODE ON `render-routine.sh` (Open Decision 1 of ticket
# `20260821150359-build-the-routine-api-body-in-one-place`, resolved 2026-09-02 by the
# driving session). The ask offered a sibling *or* a JSON-typed mode, and named the cost of
# each: a sibling adds a SECOND reader of the same frontmatter — the exact drift `scope:`
# was centralised to avoid — while a mode changes a script four callers and the setup sheets
# already depend on. Neither cost is paid here, because this sibling reads NO frontmatter:
# it composes `render-routine.sh`, which stays the one reader, and that script grew ADDITIVE
# `*_json` twins rather than a mode, so every pre-existing key keeps its bytes and no caller
# it already has can tell the difference. What is left of the sibling shape is only its
# advantage — the body's assembly lives in a file whose whole subject is the body.
#
# THE ENVELOPE IS OBSERVED; THE CREATE BODY'S OWN NESTING IS NOT. A live record reads back
# as `session_request.{environment_id, config{sources,model,allowed_tools,
# autofix_on_pr_create}, events}`, and the older recovery-by-400s account names
# `job_config.ccr.{environment_id, session_context, events}`. This script emits the observed
# nesting under `body`, says which one it used (`body_shape`) and says it is unproven
# (`body_shape_verified: false`) — because the API silently drops unknown fields, so only a
# write followed by a read-back settles it and a 200 proves nothing. `fields` carries the
# same values flat, for a transport whose own envelope differs (the meta-MCP create takes
# name/prompt/cron_expression/environment_id/connectors at the top level). Full record:
# reference/routines.md, *The routine record, read back field by field*.
#
# THE ENVIRONMENT ID IS AN ARGUMENT, NEVER A DEFAULT. Which environment a routine is created
# in is enumerated at run time by the caller and refused by name when it cannot be
# (SKILL.md §5, *Which environment a routine is created in*); a script that guessed one
# would be the aspirational configuration this skill refuses everywhere else.

set -eu

ID="${1:-}"
REPO="${2:-}"
ENV_ID="${3:-}"

[ -n "$ID" ] || { echo '{"error": "no_template_id"}'; exit 1; }
[ -n "$REPO" ] || { echo '{"error": "no_repo_url"}'; exit 1; }
[ -n "$ENV_ID" ] || { echo '{"error": "no_environment_id"}'; exit 1; }

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

rendered=$("${SCRIPT_DIR}/render-routine.sh" "$ID" "$REPO") || {
  printf '%s\n' "$rendered"
  exit 1
}

field() { printf '%s' "$rendered" | jq -r --arg k "$1" '.[$k] // ""'; }
raw()   { printf '%s' "$rendered" | jq -c --arg k "$1" '.[$k] // []'; }

name=$(field name)
cron=$(field cron_expression)
model=$(field model)
notifications=$(field notifications)
autofix=$(field autofix_on_pr_create)
tools=$(raw allowed_tools_json)
mcp=$(raw mcp_json)
sources=$(raw sources_json)

# A template that declares no repository to check out cannot produce a body: a routine with
# no source clones nothing and every command it names fails at its first read. Refused by
# name rather than emitted empty, on the rule that a body which reads as configured over a
# routine that is not is the most expensive kind of broken.
[ "$sources" != "[]" ] || { printf '{"error": "no_sources", "id": "%s"}\n' "$ID"; exit 1; }

# `autofix_on_pr_create` is a real boolean on the record; the template spells it as text.
case "$autofix" in true) autofix_json=true ;; *) autofix_json=false ;; esac

printf '%s' "$rendered" | jq -c \
  --arg env "$ENV_ID" \
  --arg name "$name" \
  --arg cron "$cron" \
  --arg model "$model" \
  --arg notifications "$notifications" \
  --argjson tools "$tools" \
  --argjson mcp "$mcp" \
  --argjson sources "$sources" \
  --argjson autofix "$autofix_json" '
  {
    id: .id,
    name: $name,
    environment_id: $env,
    body_shape: "session_request",
    body_shape_verified: false,
    fields: {
      name: $name,
      cron_expression: $cron,
      model: $model,
      allowed_tools: $tools,
      mcp: $mcp,
      sources: $sources,
      autofix_on_pr_create: $autofix,
      notifications: $notifications,
      prompt: .prompt
    },
    body: {
      name: $name,
      cron_expression: $cron,
      session_request: {
        environment_id: $env,
        config: {
          sources: [$sources[] | {git_repository: {url: .}}],
          model: $model,
          allowed_tools: $tools,
          autofix_on_pr_create: $autofix
        },
        events: [
          {
            payload: {
              type: "user",
              internal_anthropic_catchall: {
                message: { role: "user", content: .prompt }
              }
            }
          }
        ]
      }
    }
  }'
