#!/bin/sh -eu
# Render a COPY-PASTE SETUP SHEET for one routine template: everything a developer needs
# to create that routine by hand at https://claude.ai/code/routines, and nothing else.
#
#   render-setup-sheet.sh <template-id> <repo-url> [<scope>]
#   render-setup-sheet.sh --all <repo-url> [<scope>]
#
# The optional third argument is the routine SCOPE (`developer` | `repository`), the
# template's own frontmatter field. `--all` with a scope renders only that scope's
# sheets, so `/setup-dev-routines` and `/setup-repo-routines` each keep a usable
# copy-paste recovery path for its own refusal instead of sharing one sheet that
# tells a developer to create the repository's single routine as well. An explicit
# template id whose scope does not match is refused by name (`scope_mismatch`)
# rather than rendered anyway.
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
# THE SAME RULING HELD FOR A SCHEDULE TRIGGER IN EVERY SESSION CHECKED THROUGH 2026-08-10
# (ticket `20260810085351` -- FB `20260810085032`/issue #336 asked to revive a management
# command for `cron_expression` specifically, since it is a genuine data field on a
# routine record, unlike the GitHub event). `ToolSearch` over those sessions' full tool
# surface found no `RemoteTrigger`-family tool at all -- only `CronCreate`/`CronList`/
# `CronDelete`, session-only in-memory cron unrelated to account-level routines. THAT
# FINDING WAS SCOPED TO THE UNATTENDED, ROUTINE-FIRED SESSION CLASS, and a later
# interactive-session check (FB `20260810214929`, ticket `20260810130703`) found a
# `RemoteTrigger`-family tool present there -- so `/setup-routines` now detects this
# per-session and applies directly when the tool is exposed (`workaholic:workaholify`
# SKILL.md, "Direct-apply when RemoteTrigger is exposed"). This script remains the
# whole surface for the class that genuinely has no such tool, and the direct-apply
# path's own source of the target state either way -- nothing below reads or writes
# an account.
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
    echo 'usage: render-setup-sheet.sh <template-id|--all> <repo-url> [developer|repository]' >&2
    exit 2
}

[ "$#" -eq 2 ] || [ "$#" -eq 3 ] || usage
TARGET="$1"
REPO_URL="$2"
WANT_SCOPE="${3:-}"

case "$WANT_SCOPE" in
    ''|developer|repository) ;;
    *) echo "unknown scope: ${WANT_SCOPE}" >&2; exit 2 ;;
esac

sheet() {
    _id="$1"
    _file="${ROUTINES_DIR}/${_id}.md"
    [ -f "$_file" ] || { echo "unknown template: ${_id}" >&2; return 1; }
    _scope=$(fm_field "$_file" scope)
    if [ -n "$WANT_SCOPE" ] && [ "$_scope" != "$WANT_SCOPE" ]; then
        echo "scope_mismatch: ${_id} is scope '${_scope:-none}', not '${WANT_SCOPE}'" >&2
        return 1
    fi

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
    _autofix=$(fm_field "$_file" autofix_on_pr_create)
    _mcp=$(fm_field "$_file" mcp)
    # A rename is the one thing the convergence CANNOT do for the operator: it matches an
    # account's routines by NAME, so a renamed template creates a second routine beside the
    # old one rather than renaming it — and a routine is an account-level record no other
    # account can list or delete. `renamed_from:` is therefore carried into the sheet as an
    # instruction to a human, derived from the template like every other step here rather
    # than written into prose somebody has to remember to delete. The field is deleted from
    # the template once the fleet has cut over, and the note disappears with it.
    _renamed_from_raw=$(fm_field "$_file" renamed_from | sed -e 's/^"//' -e 's/"$//')
    _renamed_from=$(printf '%s' "$_renamed_from_raw" | sed -e "s#{repo_name}#${_repo_name}#g")
    # A SWAP IS NOT TWO INDEPENDENT RENAMES (2026-08-19, issue #526). When the name this
    # template was renamed OUT of is the name another template now claims, the two cutovers
    # are ORDERED: an account that creates the new holder of the old name before renaming
    # its live routine ends up with two routines carrying one rendered name, which
    # convergence matches by name and therefore cannot tell apart — and no other account can
    # list or delete the duplicate. Derived from the template set, like every other step on
    # this sheet, so the ordering disappears with the fields rather than outliving them in
    # prose. Empty for an ordinary rename, where the freed name goes nowhere.
    _name_raw=$(fm_field "$_file" name | sed -e 's/^"//' -e 's/"$//')
    _takes_over=""   # another template CLAIMS the name this one is vacating
    _held_by=""      # another routine still HOLDS the name this one is taking
    for _o in "$ROUTINES_DIR"/*.md; do
        [ -f "$_o" ] || continue
        [ "$_o" != "$_file" ] || continue
        _oname=$(fm_field "$_o" name | sed -e 's/^"//' -e 's/"$//')
        _ofrom=$(fm_field "$_o" renamed_from | sed -e 's/^"//' -e 's/"$//')
        if [ -n "$_renamed_from_raw" ] && [ "$_oname" = "$_renamed_from_raw" ]; then
            _takes_over=$(printf '%s' "$_oname" | sed -e "s#{repo_name}#${_repo_name}#g")
        fi
        if [ -n "$_ofrom" ] && [ "$_ofrom" = "$_name_raw" ]; then
            _held_by=$(printf '%s' "$_oname" | sed -e "s#{repo_name}#${_repo_name}#g")
        fi
    done

    printf '## %s\n\n' "$_name"
    case "$_scope" in
        repository) printf 'Scope: **repository** — exactly one account creates this one.\n\n' ;;
        developer)  printf 'Scope: **developer** — each developer creates their own copy.\n\n' ;;
        *)          printf 'Scope: **undeclared** — the template declares no `scope:`; treat that as a defect.\n\n' ;;
    esac
    if [ -n "$_renamed_from" ]; then
        printf '> **Already running `%s`? Rename that routine — do not create a second.**\n' "$_renamed_from"
        printf '> This routine was renamed, and convergence matches an account'\''s routines by name,\n'
        printf '> so creating a new one leaves the old one firing on its own schedule beside it.\n'
        printf '> A routine is an account-level record: nothing in this plugin — and no other\n'
        printf '> account — can detect or delete your duplicate. Open the old routine, change its\n'
        printf '> name to `%s`, and apply the fields below to it.\n\n' "$_name"
        if [ -n "$_takes_over" ]; then
            printf '> **Do this one FIRST.** `%s` is not going away — another routine takes\n' "$_takes_over"
            printf '> that name in this same change. Until you have renamed this one, creating\n'
            printf '> the other leaves your account with two routines called `%s`,\n' "$_takes_over"
            printf '> firing different commands on different schedules, and convergence matches\n'
            printf '> by name and cannot tell them apart.\n\n'
        fi
    fi
    if [ -n "$_held_by" ]; then
        printf '> **Rename `%s` to `%s` BEFORE creating this one.**\n' "$_name" "$_held_by"
        printf '> The name below is the one that routine holds until you rename it. Create this\n'
        printf '> routine first and your account holds two called `%s`, firing\n' "$_name"
        printf '> different commands on different schedules; convergence matches by name and\n'
        printf '> cannot tell them apart, and no other account can list or delete the duplicate.\n\n'
    fi
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

    if [ "$_autofix" = "true" ]; then
        printf '%s. **Auto-fix pull requests**: turn the option on (stored as `autofix_on_pr_create` on the routine).\n' "$_n"
        _n=$((_n + 1))
    fi
    printf '%s. **Connectors**: keep `%s`; remove the rest.\n' "$_n" "${_mcp:-none}"
    _n=$((_n + 1))
    # THE CHANNEL LINE IS DERIVED FROM `mcp:`, NEVER PRINTED UNCONDITIONALLY. A routine
    # granted no connector posts nothing at all, so telling its operator to have a Slack
    # channel ready describes a routine they are not creating -- and two templates are in
    # that state now ([Workaholic], [Propose]), each because its audience is exactly one
    # person who is already reached another way. A template declaring `notifications:` gets
    # that step instead, from the same field the setup commands diff.
    _notif=$(fm_field "$_file" notifications)
    # `mcp: []` renders as the two-character list, not as an empty field: an explicitly
    # empty connector list and a missing one mean the same thing here and must not diverge.
    case "$_mcp" in ''|'[]'|none) _has_mcp="" ;; *) _has_mcp=1 ;; esac
    if [ -n "$_has_mcp" ]; then
        # "posts and reads" since 2026-08-23: [Propose]'s inbound sweep READS the channel
        # and posts nothing, so the old "every post goes there" claimed a post the routine
        # never makes. The line's job is unchanged — the channel must exist.
        # The bare repository name since 2026-08-28: the `dev-` prefix convention is retired.
        printf '%s. Have the Slack channel `%s` ready — the routine'"'"'s posts and reads happen there and nowhere else.\n' "$_n" "$_repo_name"
        # A connector routine may ALSO declare a notification ([Propose] since 2026-08-23:
        # the connector is for the sweep's read, the result still reaches its reader by
        # push) — the two lines are not alternatives when the template declares both.
        if [ -n "$_notif" ]; then
            _n=$((_n + 1))
            printf '%s. **Notifications**: set them to `%s` — the routine posts nothing; its result reaches you here.\n' "$_n" "$_notif"
        fi
    elif [ -n "$_notif" ]; then
        printf '%s. **Notifications**: set them to `%s`. This routine posts to no channel; its result reaches you here.\n' "$_n" "$_notif"
    else
        printf '%s. **No channel to prepare** — this routine holds no connector and posts nothing.\n' "$_n"
    fi
    printf '\nPrompt to paste:\n\n````text\n'
    # The prompt, verbatim, from the same renderer -- read back out of the JSON string.
    printf '%s' "$_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["prompt"])'
    printf '````\n\n'
}

case "$WANT_SCOPE" in
    developer)
        printf '# Developer-scoped routine setup for %s\n\n' "$REPO_URL"
        printf '**Every developer on this repository creates their own copy of these.**\n\n'
        ;;
    repository)
        # The COUNT is stated, not left to be discovered by scrolling: this scope grew from
        # one routine to two on 2026-08-17, and the whole point of the scope is that one
        # account carries them all. A reader who creates the first and stops has left the
        # repository half-configured with nothing to tell them so.
        _repo_count=0
        for _f in "$ROUTINES_DIR"/*.md; do
            [ -f "$_f" ] || continue
            [ "$(fm_field "$_f" scope)" = "repository" ] || continue
            _repo_count=$((_repo_count + 1))
        done
        printf '# Repository-scoped routine setup for %s\n\n' "$REPO_URL"
        printf '**One account creates these for the whole repository — not every team member.**\n'
        printf 'N copies of a repository routine all firing on their schedule is the failure the\n'
        printf 'scope exists to prevent; nothing in the product can detect or refuse the duplicates.\n\n'
        printf 'There %s **%s** routine%s in this scope, and the same account creates every one of\n' \
            "$([ "$_repo_count" -eq 1 ] && echo is || echo are)" "$_repo_count" \
            "$([ "$_repo_count" -eq 1 ] && echo '' || echo s)"
        printf 'them. The per-developer setup burden is unchanged at two either way.\n\n'
        ;;
    *)
        printf '# Routine setup for %s\n\n' "$REPO_URL"
        ;;
esac
printf 'Create these by hand in the web UI. **This command cannot do it**: a GitHub-event\n'
printf 'trigger is configurable in the UI only with no API-readable field, and no\n'
printf '`RemoteTrigger`-family tool was exposed to an unattended, routine-fired session for\n'
printf 'either kind — verified empty for a schedule trigger too (ticket `20260810085351`),\n'
printf 'not only assumed from the earlier GitHub-trigger finding. A separate attended session\n'
printf 'found the opposite on its own tool surface (workaholify reference/routines.md); this\n'
printf 'command makes no such call either way. Nothing here can read, set, or verify the\n'
printf 'wiring for any trigger kind — only state what it should be. Confirm what\n'
printf 'actually runs at <%s>.\n\n' "$ROUTINES_URL"
printf '> **On a public repository, set Issue and Pull request permissions to `Collaborators\n'
printf '> only` before creating these.** A GitHub-triggered routine feeds an Issue or a pull\n'
printf '> request body to an unattended agent holding Bash, Write and a Slack connector, so\n'
printf '> an open issue tracker is an open input to that agent; a schedule-triggered routine\n'
printf '> reads the same content once it starts driving, so the precondition still applies.\n'
printf '> Note also that a Slack thread URL placed in a public Issue or pull request body is\n'
printf '> world-readable and permanently archived — it is not a credential and grants no\n'
printf '> access, but it cannot be unpublished.\n\n'
printf '> **Each developer whose tickets a routine should drive needs an entry in the\n'
printf '> committed `.claude/git-identities` mapping** (`<login>=<canonical>[,<alias>...]`;\n'
printf '> the first field is canonical, the rest are that person'\''s other addresses; the web bootstrap\n'
printf '> hook reads it). Without one, the cloud session keeps the container'\''s default git\n'
printf '> identity and that developer'\''s own [Implement] routine cannot claim tickets\n'
printf '> assigned to them.\n\n'

if [ "$TARGET" = "--all" ]; then
    rendered=0
    for _f in "$ROUTINES_DIR"/*.md; do
        [ -f "$_f" ] || continue
        # Filtered here rather than inside sheet() so a scope that simply does not
        # apply to a template is a skip, not the refusal an explicit id earns.
        [ -z "$WANT_SCOPE" ] || [ "$(fm_field "$_f" scope)" = "$WANT_SCOPE" ] || continue
        sheet "$(basename "$_f" .md)"
        rendered=$((rendered + 1))
    done
    # Silence here would read as "nothing to do"; the truth is "this plugin version
    # ships no template of that scope".
    [ "$rendered" -gt 0 ] || printf 'This plugin version ships no `%s`-scoped routine template.\n\n' "$WANT_SCOPE"
else
    sheet "$TARGET"
fi
