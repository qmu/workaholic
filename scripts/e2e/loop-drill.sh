#!/bin/sh -eu
# Exercise the propose-implement loop on demand, end to end.
#
#   loop-drill.sh seed      # mint a fresh drill pair (GitHub issue + Slack root)
#   loop-drill.sh status    # report the drill's residue: issues, claims, tickets
#   loop-drill.sh reset     # recover an ABORTED run: close/delete drill-owned residue
#
# Every outcome is ONE JSON line on stdout. A non-zero exit names the blocker in
# `reason`; exit 0 means the subcommand did what it was asked.
#
# Exit codes:
#   0  the subcommand completed (read `ok`/`reason` for the detail)
#   2  usage
#   3  a dirty precondition refused the drill (`inbox_dirty`, `claim_dirty`)
#   4  the environment could not answer (`gh_unavailable`, `identity_unresolved`,
#      `list_failed`, `issue_failed`, `not_a_repo`)
#
# WHY THIS EXISTS (2026-08-12, mission
# make-the-propose-implement-loop-drillable-on-demand). The loop is otherwise tested
# only by waiting for its hourly ticks and reading what broke -- a discovery
# regression cost a full day of ticks before a human read the logs. Seeding an ask by
# hand is a GitHub issue, a Slack post, and afterwards an audit of stray branches;
# that friction is why nobody drills the loop before changing it.
#
# WHY IT LIVES IN `scripts/`, NOT IN THE PLUGIN. This is operator tooling: it assumes
# the server's full `gh` and `qfs`, which a plugin skill must never do (a skill ships
# to 40+ agents through `outputs/`, and half of them have neither). It is invoked by a
# human at a terminal, ships to no other agent, and is exempt from nothing else.
#
# WHAT IT NEVER DOES. It writes nothing under `.workaholic/`: feedback records,
# tickets and stories are immutable history, and a drill that edited them would be
# rewriting the evidence it exists to produce. Re-runnability comes from minting a
# FRESH issue per run -- never from deleting the last run's history.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/../.." && pwd)
GH_REST="${REPO_ROOT}/plugins/workaholic/skills/gather/scripts/gh-rest.sh"
LIST_CLAIMS="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"

# The Slack surface is named ONCE so a rebind is a one-line change (measured
# 2026-08-12: the `/slack-me` mount reaches the private `dev-workaholic` channel, the
# team-bot mount cannot see it).
DRILL_SLACK_MOUNT="${DRILL_SLACK_MOUNT:-/slack-me/qmu/dev-workaholic/messages}"

# The marker every drill-minted artifact carries in its BODY. `reset` refuses to touch
# anything that does not carry it, which is what keeps the drill from eating a
# colleague's issue or branch.
DRILL_MARKER_PREFIX="drill:"

ISSUE_PAGE_SIZE="${DRILL_ISSUE_PAGE_SIZE:-50}"
BASE_BRANCH="${DRILL_BASE_BRANCH:-main}"
TAB="$(printf '\t')"

# ---------------------------------------------------------------- emit helpers

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

one_line() {
    printf '%s' "$1" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400
}

# One JSON line naming the blocker, then the exit code the caller reads.
#
# NEVER CALLED FROM INSIDE A COMMAND SUBSTITUTION. `x="$(helper)"` would swallow this
# printf into `x` and exit only the subshell, so the caller would die with a bare
# status and no reason on stdout -- the silent-failure shape this whole script exists
# to make impossible. Every fallible call below is therefore an `if ! x="$(...)"`
# in the current shell.
emit_err() {
    printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$(one_line "${3:-}")"
    exit "$2"
}

# Join accumulated JSON rows into an array body.
append_row() {
    if [ -z "$1" ]; then printf '%s' "$2"; else printf '%s, %s' "$1" "$2"; fi
}

# ---------------------------------------------------------------- environment

require_repo() {
    git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
        || emit_err "not_a_repo" 4 "$REPO_ROOT is not a git work tree"
}

# REST ONLY, through the one transport (`rules/shell.md`). `gh issue`, `gh pr` and
# `gh repo` are GraphQL-backed and a Claude Code Web session may 403 them mid-run, so
# the drill -- whose whole job is to tell a broken loop from a working one -- must not
# be the thing that fails for the reason it is testing for.
gh_api() {
    sh "$GH_REST" api "$@"
}

require_gh() {
    command -v gh >/dev/null 2>&1 || emit_err "gh_unavailable" 4 "gh is not on PATH"
}

# Sets: LOGIN
resolve_login() {
    if ! LOGIN="$(gh_api user --jq .login 2>&1)"; then
        emit_err "identity_unresolved" 4 "$LOGIN"
    fi
    [ -n "$LOGIN" ] || emit_err "identity_unresolved" 4 "gh api user returned an empty login"
}

# Sets: SLUG
resolve_slug() {
    if ! SLUG="$(sh "$GH_REST" slug 2>&1)"; then
        emit_err "list_failed" 4 "$SLUG"
    fi
}

# ---------------------------------------------------------------- oracles

# Sets: ASSIGNED_ROWS -- "<number>\t<url>\t<title>" per open issue assigned to LOGIN.
# Pull requests share the issue numbering space on this endpoint and are dropped, so
# the preflight sees exactly the inbox discovery sees.
read_assigned_open() {
    if ! ASSIGNED_ROWS="$(gh_api "repos/${SLUG}/issues?state=open&assignee=${LOGIN}&per_page=${ISSUE_PAGE_SIZE}" \
        --jq 'map(select(.pull_request | not)) | sort_by(.number) | .[]
              | [(.number|tostring), .html_url, .title] | @tsv' 2>&1)"; then
        emit_err "list_failed" 4 "$ASSIGNED_ROWS"
    fi
}

# Sets: DRILL_ROWS -- "<number>\t<state>\t<url>\t<run_id>" per drill-minted issue,
# any state. The marker lives in the BODY, which is the only honest key: a title
# convention is prose, and prose is not an identifier.
read_drill_issues() {
    if ! DRILL_ROWS="$(gh_api "repos/${SLUG}/issues?state=all&per_page=${ISSUE_PAGE_SIZE}" \
        --jq "map(select(.pull_request | not))
              | map(select((.body // \"\") | contains(\"${DRILL_MARKER_PREFIX}\")))
              | sort_by(.number) | .[]
              | [(.number|tostring), .state, .html_url,
                 ((.body // \"\") | [scan(\"${DRILL_MARKER_PREFIX}[0-9]{8}-[0-9]{6}\")] | (.[0] // \"\") | sub(\"${DRILL_MARKER_PREFIX}\"; \"\"))]
              | @tsv" 2>&1)"; then
        emit_err "list_failed" 4 "$DRILL_ROWS"
    fi
}

# Unmerged remote work-* branches -- the git-native claim oracle. Read through
# list-claims.sh so this and `/drive`'s survey cannot disagree about what is in
# flight; a claim this missed would be a double-pick waiting to happen.
claim_branches() {
    _out="$(sh "$LIST_CLAIMS" 2>/dev/null || printf '')"
    printf '%s' "$_out" \
        | tr ',' '\n' \
        | sed -n 's/.*"branch": *"\(work-[^"]*\)".*/\1/p' \
        | sort -u
}

# The artifact chain a drill issue leaves behind:
#   issue #N -> feedback record naming /issues/N -> ticket naming that record's stem.
# Both hops are grep over the checkout, because both relations are written into the
# files themselves; nothing is inferred from a session transcript.
feedback_records_for_issue() {
    _dir="${REPO_ROOT}/.workaholic/feedbacks"
    [ -d "$_dir" ] || return 0
    grep -rlE "/issues/${1}([^0-9]|\$)" "$_dir" 2>/dev/null || true
}

tickets_for_issue() {
    _n="$1"
    _root="${REPO_ROOT}/.workaholic/tickets/${2}"
    [ -d "$_root" ] || return 0
    for _rec in $(feedback_records_for_issue "$_n"); do
        _stem="$(basename "$_rec" .md)"
        grep -rl "$_stem" "$_root" 2>/dev/null || true
    done
}

# ---------------------------------------------------------------- seed

# The ask itself. Trivial, uniquely worded, instruction-shaped, and about THIS
# repository only -- never client context, which the release scan's `leak` family
# would (correctly) stop at the drill's own pull request.
drill_issue_title() {
    printf 'Record loop-drill run %s in the drill log' "$1"
}

drill_issue_body() {
    cat <<EOF
Add one line to the drill log in \`docs/loop-drill-runbook.md\` recording that
loop-drill run \`${1}\` exercised the propose-implement loop end to end.

This issue was minted by \`scripts/e2e/loop-drill.sh seed\` to drill the loop. It
carries the drill marker below so \`loop-drill.sh reset\` can recognise its own
residue and refuse everything else.

${DRILL_MARKER_PREFIX}${1}
EOF
}

# Post the thread root the drill's finish lines reply into. The issue URL goes into
# Slack verbatim on its own line; a Slack permalink never goes into the issue (the
# notification surface points at the repository, never the other way round).
post_slack_root() {
    if ! command -v qfs >/dev/null 2>&1; then
        printf 'no_qfs'
        return 0
    fi
    _text="Loop drill seeded: ${1}
${2}"
    # Single quotes delimit the SQL string, so a quote inside the text is doubled. The
    # text is ours and quote-free today; the escape is here so a future wording change
    # cannot turn into a broken statement.
    _sql="$(printf '%s' "$_text" | sed "s/'/''/g")"
    if _out="$(qfs run --commit "insert into ${DRILL_SLACK_MOUNT} values ('${_sql}')" 2>&1)"; then
        printf 'posted'
    else
        printf 'qfs_failed: %s' "$(one_line "$_out")"
    fi
}

cmd_seed() {
    require_repo
    require_gh
    resolve_login
    resolve_slug

    # --- preflight 1: the inbox must be empty ---------------------------------
    # Discovery has NO title filter (`propose/scripts/list-inbound-issues.sh`), so any
    # stray assigned issue is taken as an ask and the drill would verify the wrong
    # artifact chain. Refuse loudly rather than seed into noise.
    read_assigned_open
    dirty=""
    while IFS="$TAB" read -r number url title; do
        [ -n "$number" ] || continue
        dirty="$(append_row "$dirty" "{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\"}")"
    done <<EOF
$ASSIGNED_ROWS
EOF
    if [ -n "$dirty" ]; then
        printf '{"ok": false, "reason": "inbox_dirty", "detail": "an open assigned issue would be taken as the drill ask", "issues": [%s]}\n' "$dirty"
        exit 3
    fi

    # --- preflight 2: no claim in flight ---------------------------------------
    # An unmerged work-* branch is BOTH a live claim and a dedup ref: the drill's
    # `[Implement]` fire would take the other unit, and `[Propose]`'s dedup would see
    # a branch it must not collide with.
    branches="$(claim_branches)"
    if [ -n "$branches" ]; then
        rows_b=""
        for b in $branches; do
            rows_b="$(append_row "$rows_b" "\"$(json_escape "$b")\"")"
        done
        printf '{"ok": false, "reason": "claim_dirty", "detail": "an unmerged work-* branch is a live claim and a dedup ref", "branches": [%s]}\n' "$rows_b"
        exit 3
    fi

    # --- mint the pair ----------------------------------------------------------
    run_id="$(date -u +%Y%m%d-%H%M%S)"
    title="$(drill_issue_title "$run_id")"
    body="$(drill_issue_body "$run_id")"

    if ! created="$(gh_api "repos/${SLUG}/issues" --method POST \
        -f "title=${title}" -f "body=${body}" -f "assignees[]=${LOGIN}" \
        --jq '[(.number|tostring), .html_url] | @tsv' 2>&1)"; then
        emit_err "issue_failed" 4 "$created"
    fi

    issue_number="$(printf '%s' "$created" | cut -f1)"
    issue_url="$(printf '%s' "$created" | cut -f2)"
    [ -n "$issue_number" ] || emit_err "issue_failed" 4 "the create call returned no issue number"

    # A Slack failure AFTER the issue is minted is advisory and never a blocker: the
    # issue is the load-bearing artifact (discovery reads GitHub, not Slack), and
    # deleting a minted issue to keep two surfaces in step would destroy the drill's
    # own evidence. Report `slack_posted: false` with the reason and carry on.
    slack_result="$(post_slack_root "$title" "$issue_url")"
    case "$slack_result" in
        posted) slack_posted="true"; slack_reason="" ;;
        *) slack_posted="false"; slack_reason="$slack_result" ;;
    esac

    printf '{"ok": true, "run_id": "%s", "issue_number": %s, "issue_url": "%s", "assignee": "%s", "slack_posted": %s, "slack_reason": "%s", "slack_mount": "%s"}\n' \
        "$run_id" "$issue_number" "$(json_escape "$issue_url")" "$(json_escape "$LOGIN")" \
        "$slack_posted" "$(json_escape "$slack_reason")" "$(json_escape "$DRILL_SLACK_MOUNT")"
}

# ---------------------------------------------------------------- status

cmd_status() {
    require_repo
    require_gh
    resolve_slug
    read_drill_issues

    issues=""
    open_count=0
    todo=""
    archive=""
    while IFS="$TAB" read -r number state url run_id; do
        [ -n "$number" ] || continue
        if [ "$state" = "open" ]; then
            open_count=$((open_count + 1))
        fi
        issues="$(append_row "$issues" "{\"number\": ${number}, \"state\": \"$(json_escape "$state")\", \"url\": \"$(json_escape "$url")\", \"run_id\": \"$(json_escape "$run_id")\"}")"
        for p in $(tickets_for_issue "$number" todo); do
            todo="$(append_row "$todo" "\"$(json_escape "${p#"${REPO_ROOT}/"}")\"")"
        done
        for p in $(tickets_for_issue "$number" archive); do
            archive="$(append_row "$archive" "\"$(json_escape "${p#"${REPO_ROOT}/"}")\"")"
        done
    done <<EOF
$DRILL_ROWS
EOF

    claims=""
    for b in $(claim_branches); do
        claims="$(append_row "$claims" "\"$(json_escape "$b")\"")"
    done

    printf '{"ok": true, "open_drill_issues": %s, "issues": [%s], "claim_branches": [%s], "tickets": {"todo": [%s], "archive": [%s]}}\n' \
        "$open_count" "$issues" "$claims" "$todo" "$archive"
}

# ---------------------------------------------------------------- reset

# Is this unmerged work-* branch the drill's own? The proof is the branch's diff
# against the base: a drill-owned branch publishes a feedback record (or a ticket)
# naming one of the drill issues. Anything else is somebody's work and is SKIPPED --
# a drill that could delete a colleague's claim would be worse than no drill.
branch_is_drill_owned() {
    _branch="$1"
    _numbers="$2"
    [ -n "$_numbers" ] || return 1
    _diff="$(git -C "$REPO_ROOT" diff "origin/${BASE_BRANCH}...origin/${_branch}" 2>/dev/null || printf '')"
    [ -n "$_diff" ] || return 1
    for _n in $_numbers; do
        if printf '%s' "$_diff" | grep -qE "/issues/${_n}([^0-9]|\$)"; then
            return 0
        fi
    done
    return 1
}

cmd_reset() {
    require_repo
    require_gh
    resolve_login
    resolve_slug

    git -C "$REPO_ROOT" fetch --quiet origin >/dev/null 2>&1 || true

    read_drill_issues
    numbers=""
    open_numbers=""
    while IFS="$TAB" read -r number state url run_id; do
        [ -n "$number" ] || continue
        numbers="${numbers} ${number}"
        if [ "$state" = "open" ]; then
            open_numbers="${open_numbers} ${number}"
        fi
    done <<EOF
$DRILL_ROWS
EOF

    closed=""
    close_failed=""
    for n in $open_numbers; do
        if out="$(gh_api "repos/${SLUG}/issues/${n}" --method PATCH -f "state=closed" --jq .number 2>&1)"; then
            closed="$(append_row "$closed" "$n")"
        else
            detail="$(json_escape "$(one_line "$out")")"
            close_failed="$(append_row "$close_failed" "{\"number\": ${n}, \"detail\": \"${detail}\"}")"
        fi
    done

    deleted=""
    skipped=""
    for b in $(claim_branches); do
        if branch_is_drill_owned "$b" "$numbers"; then
            if git -C "$REPO_ROOT" push --quiet origin --delete "$b" >/dev/null 2>&1; then
                deleted="$(append_row "$deleted" "\"$(json_escape "$b")\"")"
            else
                skipped="$(append_row "$skipped" "{\"branch\": \"$(json_escape "$b")\", \"reason\": \"delete_failed\"}")"
            fi
        else
            # NOT OURS. Named, never touched -- the operator needs to see what the
            # drill left alone as much as what it removed.
            skipped="$(append_row "$skipped" "{\"branch\": \"$(json_escape "$b")\", \"reason\": \"not_drill_owned\"}")"
        fi
    done

    # Re-run the preflight so the operator learns in ONE invocation whether the base is
    # drillable again, rather than discovering it at the next refused `seed`.
    read_assigned_open
    inbox_dirty="false"
    if [ -n "$(printf '%s' "$ASSIGNED_ROWS" | tr -d '[:space:]')" ]; then
        inbox_dirty="true"
    fi
    claim_dirty="false"
    if [ -n "$(claim_branches)" ]; then
        claim_dirty="true"
    fi

    printf '{"ok": true, "closed_issues": [%s], "close_failed": [%s], "deleted_branches": [%s], "skipped": [%s], "preflight": {"inbox_dirty": %s, "claim_dirty": %s}}\n' \
        "$closed" "$close_failed" "$deleted" "$skipped" "$inbox_dirty" "$claim_dirty"
}

# ---------------------------------------------------------------- dispatch

CMD="${1:-}"
[ -n "$CMD" ] || {
    echo '{"ok": false, "reason": "usage", "detail": "loop-drill.sh seed|status|reset"}' >&2
    exit 2
}
shift

case "$CMD" in
    seed) cmd_seed "$@" ;;
    status) cmd_status "$@" ;;
    reset) cmd_reset "$@" ;;
    *)
        echo '{"ok": false, "reason": "usage", "detail": "loop-drill.sh seed|status|reset"}' >&2
        exit 2
        ;;
esac
