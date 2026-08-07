#!/bin/sh -eu
# Render a COPY-PASTE SETUP SHEET for one routine template: everything a developer needs
# to create that routine by hand at https://claude.ai/code/routines, and nothing else.
#
#   render-setup-sheet.sh <template-id> <repo-url>
#   render-setup-sheet.sh --all <repo-url>
#
# Output: the sheet on stdout, as markdown. No JSON, because the consumer is a person
# reading it beside a browser form, not a program.
#
# WHY A SHEET AND NOT A MANAGEMENT COMMAND (the developer's ruling, 2026-08-06, recorded
# in `.workaholic/feedbacks/20260806143907-routine-setup-is-a-human-act-the-plugin-makes-
# cheap.md`). A routine's GitHub trigger is configured in the web UI ONLY -- the product
# documentation says so, and the API record carries no event field, so the wiring can be
# neither read, written, nor drift-checked from a session. A tool that manages the
# readable half while blind to the half that decides whether the routine runs at all
# misleads more than it helps: on 2026-08-06 a paginated `list` (20 rows, unread
# `has_more`) was surveyed as the whole account, six duplicate records were carefully
# refreshed through a digest gate, and the real wired routine ran a stale prompt beyond
# page one. So the plugin's one job here is to make the human's UI setup cheap.
#
# THE UI STEPS ARE DERIVED, NEVER HAND-WRITTEN. They come from the template's own
# `trigger_kind` / `trigger_event` / `trigger_filters` declaration, so a template whose
# trigger changes cannot leave a stale procedure behind in prose somebody forgot.
#
# It reads templates and renders text. It reaches no account, opens no network
# connection, and mutates nothing.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROUTINES_DIR="${SCRIPT_DIR}/../routines"
RENDER="${SCRIPT_DIR}/render-routine.sh"
LIST="${SCRIPT_DIR}/list-routine-templates.sh"
ROUTINES_URL="https://claude.ai/code/routines"

fm_field() { sed -n "2,/^---[ \t]*\$/p" "$1" | sed -n "s/^$2:[ \t]*//p" | head -n 1; }

usage() {
    echo 'usage: render-setup-sheet.sh <template-id|--all> <repo-url>' >&2
    exit 2
}

[ "$#" -eq 2 ] || usage
TARGET="$1"
REPO_URL="$2"

sheet() {
    _id="$1"
    _file="${ROUTINES_DIR}/${_id}.md"
    [ -f "$_file" ] || { echo "unknown template: ${_id}" >&2; return 1; }

    # The rendered fields (name, model, prompt) come from the same renderer the templates
    # have always used, so a sheet can never disagree with what the template says.
    _json=$(sh "$RENDER" "$_id" "$REPO_URL")
    _name=$(printf '%s' "$_json" | sed -n 's/.*"name": "\([^"]*\)".*/\1/p')
    _model=$(printf '%s' "$_json" | sed -n 's/.*"model": "\([^"]*\)".*/\1/p')
    _repo_name=$(printf '%s' "$_json" | sed -n 's/.*"repo_name": "\([^"]*\)".*/\1/p')

    _kind=$(fm_field "$_file" trigger_kind)
    _event=$(fm_field "$_file" trigger_event)
    _filters=$(fm_field "$_file" trigger_filters)
    _cron=$(fm_field "$_file" cron_expression)
    _mcp=$(fm_field "$_file" mcp)

    printf '## %s\n\n' "$_name"
    printf 'Open <%s> and click **New routine**, then:\n\n' "$ROUTINES_URL"
    printf '1. **Name**: `%s`\n' "$_name"
    printf '2. **Model**: `%s`\n' "$_model"
    printf '3. **Repository**: `%s`\n' "$REPO_URL"
    printf '4. **Instructions**: paste the prompt block below, verbatim\n'

    _n=5
    if [ -n "$_kind" ] && [ "$_kind" = "github" ]; then
        printf '%s. **Trigger** — *Select a trigger* → **Add another trigger** → **GitHub event**:\n' "$_n"
        printf '   - Repository: `%s`\n' "$REPO_URL"
        printf '   - Event: `%s`\n' "$_event"
        [ -n "$_filters" ] && printf '   - Filters (all must match): `%s`\n' "$_filters"
        printf '   - Requires the Claude GitHub App on that repository; the form prompts to install it.\n'
        _n=$((_n + 1))
    elif [ -n "$_cron" ]; then
        printf '%s. **Trigger** — *Select a trigger* → **Schedule**, cron `%s`\n' "$_n" "$_cron"
        _n=$((_n + 1))
    fi

    printf '%s. **Connectors**: keep `%s`; remove the rest.\n' "$_n" "${_mcp:-none}"
    _n=$((_n + 1))
    printf '%s. Have the Slack channel `dev-%s` ready — every post goes there and nowhere else.\n' "$_n" "$_repo_name"
    printf '\nPrompt to paste:\n\n````text\n'
    # The prompt, verbatim, from the same renderer -- read back out of the JSON string.
    printf '%s' "$_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["prompt"])'
    printf '````\n\n'
}

printf '# Routine setup for %s\n\n' "$REPO_URL"
printf 'Create these by hand in the web UI. **The plugin cannot do it**: a routine'\''s GitHub\n'
printf 'trigger is configurable in the UI only, and the API exposes no trigger field, so\n'
printf 'nothing here can read, set, or verify the wiring — only state what it should be.\n'
printf 'Confirm what actually runs at <%s>.\n\n' "$ROUTINES_URL"
printf '> **On a public repository, set Issue and Pull request permissions to `Collaborators\n'
printf '> only` before creating these.** Each routine fires on an Issue or a pull request and\n'
printf '> feeds its body to an unattended agent holding Bash, Write and a Slack connector, so\n'
printf '> an open issue tracker is an open input to that agent. Note also that a Slack thread\n'
printf '> URL placed in a public Issue or pull request body is world-readable and permanently\n'
printf '> archived — it is not a credential and grants no access, but it cannot be unpublished.\n\n'
printf '> **Each developer whose tickets a routine should drive needs an entry in the\n'
printf '> committed `.claude/git-identities` mapping** (`<login>=<email>`; the web bootstrap\n'
printf '> hook reads it). Without one, the cloud session keeps the container'\''s default git\n'
printf '> identity and that developer'\''s own [Implement] routine cannot claim tickets\n'
printf '> assigned to them.\n\n'

if [ "$TARGET" = "--all" ]; then
    for _f in "$ROUTINES_DIR"/*.md; do
        [ -f "$_f" ] || continue
        _b=$(basename "$_f" .md)
        sheet "$_b"
    done
else
    sheet "$TARGET"
fi
