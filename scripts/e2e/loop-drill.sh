#!/bin/sh -eu
# Exercise the propose-implement loop on demand, end to end.
#
#   loop-drill.sh seed                        # mint a fresh drill pair (issue + Slack root)
#   loop-drill.sh status                      # report the drill's residue
#   loop-drill.sh reset                       # recover an ABORTED run
#   loop-drill.sh verify-specificate  <issue> [--json]   # did the [Specificate] fire land?
#   loop-drill.sh verify-implement <issue> [--json]  # did the [Implement] fire land?
#                                             (a drill ticket carrying
#                                             `verification_handoff:` inverts the
#                                             stage: open + handed off, not merged)
#   loop-drill.sh verify-plan [--json]        # is the deployment-plan refresh sound?
#   loop-drill.sh verify-status [--json]      # is the [Prepare Release] read sound and silent?
#   loop-drill.sh verify-cadence [--json]     # is the daily note generation idempotent and clock-free?
#   loop-drill.sh verify-planner [--json]     # is the release-plan chain gated, honest and write-free?
#   loop-drill.sh verify-moderate [--json]  # is the /moderate tick (the [Moderate]
#                                             routine since 2026-08-19) sound and
#                                             write-free? The stage names the COMMAND,
#                                             which did not move in that rename; the
#                                             routine that fires it did.
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
#      `verify-plan` additionally uses 4 for `plan_unreadable`, and `verify-status`
#      for `status_unreadable`.
#   5  a verify stage HAS NOT RUN YET (no artifacts, the ask still open) -- distinct
#      from 1 so a poller can tell "wait" from "broken"
#   1  a verify stage RAN AND FAILED: at least one load-bearing row is false
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
    # Discovery has NO title filter (`specificate/scripts/list-inbound-issues.sh`), so any
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
    # `[Implement]` fire would take the other unit, and `[Specificate]`'s dedup would see
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

# ---------------------------------------------------------------- verify

# THE ARTIFACTS ARE THE VERDICT. Every load-bearing row below reads `origin/main`, an
# unmerged-branch scan, or a REST issue/pull-request state -- the same oracles the loop
# itself reads. A session transcript is diagnosis material, never a verdict: it says
# what a run believed, and a stage that believed it succeeded is exactly the stage
# worth checking.
#
# THREE VALUES, NOT TWO. `pass: true` / `pass: false` / `pass: null`. Null is either
# advisory (a Slack row, which can never decide a stage) or unread (`qfs` failed).
# "Stage not yet run" is a property of the WHOLE stage, not of a row -- reported as
# `verdict: "pending"` with exit 5, because a stage nobody fired has not failed.

ROWS=""
ACTIONABLE=""
LOAD_FAILED=0
LOAD_PASSED=0
ADVISORY=0
SHOW_ALL_ROWS="false"

# add_row <check> <pass:true|false|null> <detail> <bearing:load|advisory>
#
# Both accumulators are built here rather than filtered at print time: a row's JSON
# carries operator-written detail, and re-parsing that back out with sed to decide what
# to print is the kind of cleverness that breaks on the first detail containing a brace.
add_row() {
    _row="{\"check\": \"$(json_escape "$1")\", \"pass\": $2, \"detail\": \"$(json_escape "$3")\", \"bearing\": \"$4\"}"
    ROWS="$(append_row "$ROWS" "$_row")"
    if [ "$2" != "true" ]; then
        ACTIONABLE="$(append_row "$ACTIONABLE" "$_row")"
    fi
    if [ "$4" = "load" ]; then
        if [ "$2" = "true" ]; then
            LOAD_PASSED=$((LOAD_PASSED + 1))
        else
            LOAD_FAILED=$((LOAD_FAILED + 1))
        fi
    else
        ADVISORY=$((ADVISORY + 1))
    fi
}

# Files on the base whose CONTENT matches an ERE. Reading the base rather than the
# working tree is the point: a drill verifies what the loop published, not what this
# checkout happens to hold.
main_grep() {
    git -C "$REPO_ROOT" ls-tree -r --name-only "origin/${BASE_BRANCH}" -- "$1" 2>/dev/null \
        | while read -r _f; do
            if git -C "$REPO_ROOT" show "origin/${BASE_BRANCH}:${_f}" 2>/dev/null | grep -qE "$2"; then
                printf '%s\n' "$_f"
            fi
        done
}

main_show() {
    git -C "$REPO_ROOT" show "origin/${BASE_BRANCH}:${1}" 2>/dev/null || true
}

# Sets: PR_ROWS -- "<number>\t<head_ref>\t<merged_at>\t<title>\t<body>" per pull
# request. Read through the REST pulls endpoint; `gh pr list` is GraphQL-backed and a
# restricted session would report "the stage failed" when it only failed to look.
# `@tsv` escapes the body's newlines and tabs, so the five fields stay unambiguous.
#
# `-` IS THE EMPTY SENTINEL, and it is a correctness requirement rather than a style
# choice. A TAB is an IFS *whitespace* character, so `read` collapses a run of them into
# ONE delimiter and strips leading ones: a genuinely empty middle field (an UNMERGED
# pull request's `merged_at` -- exactly the row this drill has to recognise) shifts
# every later field left by one, and the body arrives holding the title. Measured while
# writing this: `verify-specificate` reported "no pull request carries Closes #N" about a
# pull request that carried it.
PR_EMPTY="-"
read_pulls() {
    if ! PR_ROWS="$(gh_api "repos/${SLUG}/pulls?state=all&per_page=${ISSUE_PAGE_SIZE}" \
        --jq '.[] | [(.number|tostring), (.head.ref // "-"), (.merged_at // "-"), (.title // "-"), (.body // "-")] | @tsv' 2>&1)"; then
        emit_err "list_failed" 4 "$PR_ROWS"
    fi
}

# Read the seed thread. ADVISORY ALWAYS: the notification surface must never decide a
# stage the artifacts already decided, so every outcome here is `pass: null` on failure
# and never touches the exit code.
slack_rows() {
    _needle="$1"
    _name="$2"
    if ! command -v qfs >/dev/null 2>&1; then
        add_row "$_name" null "qfs is not installed; the Slack surface was not read" advisory
        return 0
    fi
    if ! _out="$(qfs run "${DRILL_SLACK_MOUNT} |> select text |> limit 50" --json 2>&1)"; then
        add_row "$_name" null "qfs read failed: $(one_line "$_out")" advisory
        return 0
    fi
    if printf '%s' "$_out" | grep -qF "$_needle"; then
        add_row "$_name" true "found in the seed thread" advisory
    else
        add_row "$_name" false "not found in ${DRILL_SLACK_MOUNT}" advisory
    fi
}

emit_verdict() {
    _stage="$1"
    _issue="$2"
    _verdict="$3"
    _code="$4"
    _ok="false"
    if [ "$_verdict" = "pass" ]; then
        _ok="true"
    fi
    # The terse default carries the ACTIONABLE rows -- everything not passing, which is
    # what an operator has to act on. `--json` carries the full set, which is what a
    # runbook pastes and what a regression test pins.
    if [ "$SHOW_ALL_ROWS" = "true" ]; then
        _rows="$ROWS"
    else
        _rows="$ACTIONABLE"
    fi
    printf '{"ok": %s, "stage": "%s", "issue": %s, "verdict": "%s", "load_bearing": {"passed": %s, "failed": %s}, "advisory": %s, "rows": [%s]}\n' \
        "$_ok" "$_stage" "$_issue" "$_verdict" "$LOAD_PASSED" "$LOAD_FAILED" "$ADVISORY" "$_rows"
    exit "$_code"
}

# Sets: ISSUE_STATE, ISSUE_ASSIGNEE
read_issue() {
    if ! _row="$(gh_api "repos/${SLUG}/issues/${1}" \
        --jq '[.state, ((.assignees // []) | map(.login) | join(","))] | @tsv' 2>&1)"; then
        emit_err "list_failed" 4 "$_row"
    fi
    ISSUE_STATE="$(printf '%s' "$_row" | cut -f1)"
    ISSUE_ASSIGNEE="$(printf '%s' "$_row" | cut -f2)"
}

verify_prelude() {
    require_repo
    require_gh
    resolve_slug
    git -C "$REPO_ROOT" fetch --quiet origin "$BASE_BRANCH" >/dev/null 2>&1 || true
    git -C "$REPO_ROOT" fetch --quiet origin >/dev/null 2>&1 || true
}

cmd_verify_specificate() {
    ISSUE="${1:-}"
    case "$ISSUE" in
        '' | *[!0-9]*) emit_err "usage" 2 "verify-specificate needs an issue number" ;;
    esac
    verify_prelude
    read_issue "$ISSUE"
    read_pulls

    record="$(main_grep ".workaholic/feedbacks" "/issues/${ISSUE}([^0-9]|\$)" | head -1)"

    # STAGE NOT YET RUN vs STAGE FAILED. No record on the base AND the ask still open is
    # a routine that has not fired -- `pending`, not `fail`. Calling that a failure would
    # train the operator to ignore red, which is worse than reporting nothing.
    if [ -z "$record" ] && [ "$ISSUE_STATE" = "open" ]; then
        add_row "feedback_record" null "no record on origin/${BASE_BRANCH} names /issues/${ISSUE} and the issue is still open" load
        LOAD_FAILED=0
        emit_verdict "specificate" "$ISSUE" "pending" 5
    fi

    if [ -n "$record" ]; then
        add_row "feedback_record" true "$record" load
    else
        add_row "feedback_record" false "expected a file under .workaholic/feedbacks/ on origin/${BASE_BRANCH} naming /issues/${ISSUE}" load
    fi

    if [ "$ISSUE_STATE" = "closed" ]; then
        add_row "issue_closed" true "the merged proposal's Closes #${ISSUE} closed it" load
    else
        add_row "issue_closed" false "issue #${ISSUE} is still ${ISSUE_STATE}" load
    fi

    # The proposal pull request: found by its NATIVE CLOSING KEYWORD, which is the
    # relation the propose seam actually writes into the body -- not by its title, which
    # is prose and would match a hand-opened pull request that closes nothing.
    pr_number=""
    pr_merged=""
    while IFS="$TAB" read -r number head merged title body; do
        [ -n "$number" ] || continue
        printf '%s' "$body" | grep -qE "Closes #${ISSUE}([^0-9]|\$)" || continue
        pr_number="$number"
        pr_merged="$merged"
    done <<EOF
$PR_ROWS
EOF
    if [ -z "$pr_number" ]; then
        add_row "proposal_pr_merged" false "no pull request on ${SLUG} carries Closes #${ISSUE}" load
    elif [ "$pr_merged" != "$PR_EMPTY" ]; then
        add_row "proposal_pr_merged" true "pull request #${pr_number} merged at ${pr_merged}" load
    else
        add_row "proposal_pr_merged" false "pull request #${pr_number} exists but is not merged" load
    fi

    # The artifacts the proposal emitted, in WHICHEVER of the three sanctioned shapes it
    # chose (`workaholic:specificate`, *The form follows the work's shape*): a loose ticket
    # naming the record, a mission naming the record whose tickets carry `mission: <slug>`,
    # or the record alone. Until 2026-08-12 only the first was looked for, so the
    # mission-shaped proposal (PR #407, measured 20:47 UTC) was reported as a missing
    # ticket on a stage that had in fact passed -- a red verdict on a green run, which
    # trains the operator to ignore red exactly as the `pending`-vs-`fail` rule above
    # argues against.
    #
    # The mission hops are anchored to the FRONTMATTER relation -- `feedback:` and
    # `mission:` are line-leading keys -- so a mission merely discussed in a ticket's prose
    # is not mistaken for the relation. The loose lookup is deliberately left as it was
    # (any occurrence of the stem under tickets/), so the shape the rows were written for
    # cannot regress. Both hops read the base through main_grep like every other row: a
    # drill that consulted the working tree would disagree with itself per operator.
    form="record_alone"
    ticket=""
    mission=""
    slug=""
    stem=""
    if [ -n "$record" ]; then
        stem="$(basename "$record" .md)"
        ticket="$(main_grep ".workaholic/tickets" "$stem" | head -1)"
        if [ -n "$ticket" ]; then
            form="loose_ticket"
        else
            mission="$(main_grep ".workaholic/missions" "^feedback:.*${stem}" | head -1)"
            if [ -n "$mission" ]; then
                slug="$(basename "$(dirname "$mission")")"
                ticket="$(main_grep ".workaholic/tickets" "^mission:.*${slug}" | head -1)"
                if [ -n "$ticket" ]; then
                    form="mission"
                else
                    form="mission_without_tickets"
                fi
            fi
        fi
    fi

    # ADVISORY BY DECISION, not by oversight: the drill knows which form was emitted, it
    # cannot know which form the ask WARRANTED -- that judgment is the propose skill's and
    # a human's. A row that graded the choice would fail every correctly-record-alone
    # proposal, so this one states the shape and decides nothing.
    case "$form" in
        loose_ticket) add_row "proposal_form" null "loose ticket (${ticket})" advisory ;;
        mission) add_row "proposal_form" null "mission ${slug} (${mission})" advisory ;;
        mission_without_tickets) add_row "proposal_form" null "mission ${slug} with no ticket carrying its relation" advisory ;;
        *) add_row "proposal_form" null "record alone -- no ticket and no mission names ${stem:-the record}" advisory ;;
    esac

    if [ -n "$ticket" ]; then
        if [ "$form" = "mission" ]; then
            add_row "ticket_feedback_ref" true "${ticket} via mission ${slug}" load
        else
            add_row "ticket_feedback_ref" true "$ticket" load
        fi
        # THE TWO SPELLINGS OF ONE PERSON. An issue's assignee is a GitHub login; a ticket
        # carries a git email, because the propose seam writes the identity the repository's
        # own committed map resolves (`.claude/git-identities`, `<login>=<email>` — the same
        # file the web bootstrap reads). Comparing the raw login against the ticket failed a
        # correctly-assigned one: measured 2026-08-12 on issue #406, where the ticket carried
        # `a@qmu.jp` and the row demanded `tamurayoshiya`. Either spelling satisfies it, and
        # the map is read off the base like every other row — an absent or unmapped login
        # simply leaves the login as the only accepted token, never an error.
        assignee_email=""
        if [ -n "$ISSUE_ASSIGNEE" ]; then
            assignee_email="$(main_show ".claude/git-identities" | grep -E "^${ISSUE_ASSIGNEE}=" | head -1 | cut -d= -f2)"
        fi
        if [ -n "$ISSUE_ASSIGNEE" ] && main_show "$ticket" | grep -qF "$ISSUE_ASSIGNEE"; then
            add_row "ticket_assignee" true "carries the issue's assignee (${ISSUE_ASSIGNEE})" load
        elif [ -n "$assignee_email" ] && main_show "$ticket" | grep -qF "$assignee_email"; then
            add_row "ticket_assignee" true "carries the issue's assignee as ${assignee_email} (git-identities maps ${ISSUE_ASSIGNEE})" load
        else
            add_row "ticket_assignee" false "expected the issue's assignee (${ISSUE_ASSIGNEE:-none}${assignee_email:+ or ${assignee_email}}) on ${ticket}" load
        fi
    elif [ "$form" = "mission_without_tickets" ]; then
        # A mission is not a mission under two tickets (`mission/scripts/check-floor.sh`),
        # so a published mission with none is a real defect of the run -- load-bearing.
        add_row "ticket_feedback_ref" false "mission ${slug} names ${stem} but no ticket carries mission: ${slug}" load
        add_row "ticket_assignee" false "no ticket to carry the assignee" load
    else
        add_row "ticket_feedback_ref" null "record-alone proposal: no ticket or mission names ${stem:-the feedback record}, which the judgment bar permits" advisory
        add_row "ticket_assignee" null "no ticket to carry the assignee (record alone)" advisory
    fi

    slack_rows "/issues/${ISSUE}" "slack_seed_root"

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "specificate" "$ISSUE" "fail" 1
    fi
    emit_verdict "specificate" "$ISSUE" "pass" 0
}

cmd_verify_implement() {
    ISSUE="${1:-}"
    case "$ISSUE" in
        '' | *[!0-9]*) emit_err "usage" 2 "verify-implement needs an issue number" ;;
    esac
    verify_prelude
    read_pulls

    record="$(main_grep ".workaholic/feedbacks" "/issues/${ISSUE}([^0-9]|\$)" | head -1)"
    if [ -z "$record" ]; then
        add_row "feedback_record" null "the propose stage has not landed; run verify-specificate first" load
        LOAD_FAILED=0
        emit_verdict "implement" "$ISSUE" "pending" 5
    fi
    stem="$(basename "$record" .md)"

    todo="$(main_grep ".workaholic/tickets/todo" "$stem" | head -1)"
    archived="$(main_grep ".workaholic/tickets/archive" "$stem" | head -1)"

    if [ -z "$archived" ] && [ -n "$todo" ]; then
        add_row "ticket_archived" null "the drill ticket is still queued at ${todo}; the [Implement] fire has not landed" load
        LOAD_FAILED=0
        emit_verdict "implement" "$ISSUE" "pending" 5
    fi

    if [ -n "$archived" ]; then
        add_row "ticket_archived" true "$archived" load
    else
        add_row "ticket_archived" false "expected the drill ticket under .workaholic/tickets/archive/ on origin/${BASE_BRANCH}" load
    fi

    # The archive directory IS the unit's branch (`tickets/archive/<branch>/<file>`), so
    # the ticket's landing place names the pull request to check. Nothing is carried
    # between stages: every relation is read back out of the artifacts.
    unit_branch=""
    if [ -n "$archived" ]; then
        unit_branch="$(printf '%s' "$archived" | sed -n 's#^.workaholic/tickets/archive/\([^/]*\)/.*#\1#p')"
    fi

    story="$(main_grep ".workaholic/stories" "${unit_branch:-$stem}" | head -1)"
    if [ -n "$story" ]; then
        add_row "story_exists" true "$story" load
    else
        add_row "story_exists" false "expected a story under .workaholic/stories/ naming ${unit_branch:-$stem}" load
    fi

    # THE UNVERIFIABLE-UNIT FIXTURE INVERTS THE EXPECTATIONS, and it is read off the
    # artifact rather than passed as a flag: a ticket declaring `verification_handoff:`
    # is one the loop must NOT merge (`workaholic:drive` §6), so for that seed a merged
    # pull request is the failure and an open one carrying `## Handoff` is the pass. The
    # declaration is read from the ARCHIVED ticket -- the same file the run routed on --
    # so the drill and the run cannot disagree about which fixture this was.
    declared=""
    if [ -n "$archived" ]; then
        declared="$(main_show "$archived" | awk '
            NR == 1 { if ($0 != "---") exit; next }
            /^---[ \t]*$/ { exit }
            index($0, "verification_handoff:") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
        ')"
    fi

    if [ -n "$unit_branch" ]; then
        pr_state=""
        pr_number=""
        pr_body=""
        while IFS="$TAB" read -r number head merged title body; do
            [ -n "$number" ] || continue
            [ "$head" = "$unit_branch" ] || continue
            pr_number="$number"
            pr_state="$merged"
            pr_body="$body"
        done <<EOF
$PR_ROWS
EOF
        if [ -n "$declared" ]; then
            if [ -z "$pr_number" ]; then
                add_row "unit_pr_handed_off" false "no pull request found for head ${unit_branch}" load
            elif [ "$pr_state" != "$PR_EMPTY" ]; then
                add_row "unit_pr_handed_off" false "pull request #${pr_number} MERGED at ${pr_state}; a unit declaring verification_handoff must stay open" load
            elif ! printf '%s' "$pr_body" | grep -qF '## Handoff'; then
                add_row "unit_pr_handed_off" false "pull request #${pr_number} is open but its body carries no ## Handoff section" load
            elif ! printf '%s' "$pr_body" | grep -qF "$declared"; then
                add_row "unit_pr_handed_off" false "pull request #${pr_number} hands off without naming the declared verification (${declared})" load
            else
                add_row "unit_pr_handed_off" true "pull request #${pr_number} is open and hands off: ${declared}" load
            fi

            # The claim is the other half of the handoff: the unit is still owned while
            # it waits for a person, so the branch staying unmerged is the pass here --
            # the exact inverse of the merged case below, and for the same reason.
            if claim_branches | grep -qx "$unit_branch"; then
                add_row "claim_held" true "${unit_branch} is still claimed, as a handoff unit should be" load
            else
                add_row "claim_held" false "${unit_branch} is no longer an unmerged work-* branch; the handoff released its claim" load
            fi
        else
            if [ -z "$pr_number" ]; then
                add_row "unit_pr_merged" false "no pull request found for head ${unit_branch}" load
            elif [ "$pr_state" != "$PR_EMPTY" ]; then
                add_row "unit_pr_merged" true "pull request #${pr_number} merged at ${pr_state}" load
            else
                add_row "unit_pr_merged" false "pull request #${pr_number} for ${unit_branch} is not merged" load
            fi

            # CLAIM RELEASE, READ NARROWLY AND DELIBERATELY. The merge releases the claim by
            # definition, so what is checked is that THIS unit's branch is gone from the
            # unmerged set -- not that the repository holds no claims at all. A colleague's
            # live claim is not this drill's failure, and a check that reported it as one
            # would be red for reasons the operator cannot act on.
            if claim_branches | grep -qx "$unit_branch"; then
                add_row "claim_released" false "${unit_branch} is still an unmerged work-* branch" load
            else
                others="$(claim_branches | tr '\n' ' ')"
                add_row "claim_released" true "${unit_branch} is merged${others:+; other live claims: ${others}}" load
            fi
        fi
    elif [ -n "$declared" ]; then
        add_row "unit_pr_handed_off" false "no archived ticket, so no unit branch to check" load
        add_row "claim_held" false "no unit branch to check" load
    else
        add_row "unit_pr_merged" false "no archived ticket, so no unit branch to check" load
        add_row "claim_released" false "no unit branch to check" load
    fi

    if [ -n "$declared" ]; then
        slack_rows "/issues/${ISSUE}" "slack_handoff_line"
    else
        slack_rows "/issues/${ISSUE}" "slack_finish_line"
    fi

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "implement" "$ISSUE" "fail" 1
    fi
    emit_verdict "implement" "$ISSUE" "pass" 0
}

# ---------------------------------------------------------------- verify-plan
#
# The deployment-plan refresh is carried by `[Implement]`'s existing hourly tick
# (through `/ship`'s drafting phase), which means it is otherwise only observable by
# waiting an hour and reading a note. This stage proves the three properties the
# carrier depends on, in seconds and without waiting for a tick:
#
#   plan_drafted    the consolidation reads this repository and a plan is produced
#   plan_idempotent a second run against an unchanged base is byte-identical
#   plan_degraded   an unreadable base is reported and writes NOTHING
#
# It writes nothing under `.workaholic/`: the plan is drafted into a scratch note in
# the temp directory, using this repository's real deployment targets and real commit
# range. A drill that edited the knowledge tree would be rewriting its own evidence.
cmd_verify_plan() {
    _draft="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/draft-deploy-plan.sh"
    if [ ! -f "$_draft" ]; then
        emit_err "plan_unreadable" 4 "draft-deploy-plan.sh is not present in this checkout"
    fi

    _tmp="${TMPDIR:-/tmp}/workaholic-plan-drill.$$"
    _note="${_tmp}/scratch-note.md"
    mkdir -p "$_tmp"
    # shellcheck disable=SC2064 -- expand _tmp now, at trap definition time.
    trap "rm -rf '$_tmp'" EXIT INT TERM
    printf -- '---\ntype: Release Note\nbranch: drill-scratch\n---\n\n# Drill scratch\n\n## Summary\n\nNot a real note.\n' > "$_note"

    _out=$(cd "$REPO_ROOT" && sh "$_draft" "$_note" "$BASE_BRANCH" 2>&1) || true
    case "$_out" in
        *'"ok": true'*)
            _targets=$(printf '%s' "$_out" | sed -n 's/.*"targets": \([0-9]*\).*/\1/p')
            add_row "plan_drafted" true "the plan covers ${_targets} target(s)" load
            ;;
        *)
            add_row "plan_drafted" false "$(one_line "$_out")" load
            emit_verdict "plan" 0 "fail" 1
            ;;
    esac

    cp "$_note" "${_note}.first"
    _out2=$(cd "$REPO_ROOT" && sh "$_draft" "$_note" "$BASE_BRANCH" 2>&1) || true
    if printf '%s' "$_out2" | grep -q '"changed": false' && cmp -s "$_note" "${_note}.first"; then
        add_row "plan_idempotent" true "a second run left the note byte-identical" load
    else
        add_row "plan_idempotent" false "a second run changed the note: $(one_line "$_out2")" load
    fi

    cp "$_note" "${_note}.before"
    _out3=$(cd "$REPO_ROOT" && sh "$_draft" "$_note" "no-such-base-for-the-drill" 2>&1) || true
    if printf '%s' "$_out3" | grep -q '"ok": false' && cmp -s "$_note" "${_note}.before"; then
        add_row "plan_degraded" true "an unreadable base was reported and skipped" load
    else
        add_row "plan_degraded" false "a degraded read did not skip cleanly: $(one_line "$_out3")" load
    fi

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "plan" 0 "fail" 1
    fi
    emit_verdict "plan" 0 "pass" 0
}

# ---------------------------------------------------------------- verify-status
#
# The repository-scoped `[Prepare Release]` routine (`/prepare-release`) is otherwise
# only observable by waiting an hour and watching a Slack channel for a message that,
# on a healthy quiet repository, correctly never arrives. This stage proves the three
# properties the routine depends on, in seconds:
#
#   status_read       the consolidation reads this repository and reports its targets
#   status_stable     a second run against an unchanged base returns the SAME digest
#                     (the digest excludes the base sha, so an advanced base is not
#                     news; an unstable digest would make every tick post)
#   status_degraded   an unreadable base is reported by reason and yields no digest
#   status_refs       the freshness of the refs the count came from is REPORTED, and a
#                     read that could not freshen them names its doubt instead of
#                     printing a bare number (2026-08-18 — a container with no tags and
#                     a five-day-stale base reported 2721, then 2950, then the true 4
#                     for one unchanged repository, with the digest moving each time)
#   status_rate       the post is bounded to one ask per Asia/Tokyo day: the day token
#                     is well-formed and holds across two reads (2026-08-18 — nine posts
#                     in nine consecutive hours for one request, because the count is in
#                     the digest's input and a commit lands on the base every hour)
#
# It writes nothing anywhere — which is the routine's whole contract, so the drill
# asserting it by construction is the point rather than a convenience.
cmd_verify_status() {
    _rep="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/report-deploy-status.sh"
    if [ ! -f "$_rep" ]; then
        emit_err "status_unreadable" 4 "report-deploy-status.sh is not present in this checkout"
    fi

    _out=$(cd "$REPO_ROOT" && sh "$_rep" "$BASE_BRANCH" 2>&1) || true
    case "$_out" in
        *'"ok": true'*)
            _count=$(printf '%s' "$_out" | sed -n 's/.*"count": \([0-9]*\).*/\1/p')
            _digest=$(printf '%s' "$_out" | sed -n 's/.*"digest": "\([0-9a-f]*\)".*/\1/p')
            add_row "status_read" true "the status covers ${_count} target(s), digest ${_digest}" load
            ;;
        *)
            add_row "status_read" false "$(one_line "$_out")" load
            emit_verdict "status" 0 "fail" 1
            ;;
    esac

    _out2=$(cd "$REPO_ROOT" && sh "$_rep" "$BASE_BRANCH" 2>&1) || true
    _digest2=$(printf '%s' "$_out2" | sed -n 's/.*"digest": "\([0-9a-f]*\)".*/\1/p')
    if [ -n "$_digest" ] && [ "$_digest" = "$_digest2" ]; then
        add_row "status_stable" true "a second run returned the same digest, so an idle tick posts nothing" load
    else
        add_row "status_stable" false "the digest moved between two reads: ${_digest} -> ${_digest2}" load
    fi

    _out3=$(cd "$REPO_ROOT" && sh "$_rep" "no-such-base-for-the-drill" 2>&1) || true
    if printf '%s' "$_out3" | grep -q '"ok": false' && printf '%s' "$_out3" | grep -q '"digest": ""'; then
        add_row "status_degraded" true "an unreadable base was reported with no digest" load
    else
        add_row "status_degraded" false "a degraded read did not refuse cleanly: $(one_line "$_out3")" load
    fi

    # The freshness field must be PRESENT and, when the refs could not be freshened, the
    # read must say so rather than let a collapsed boundary pass as an ordinary one. Run
    # with the fetch opted out so the degraded path is exercised on demand rather than
    # only when the server happens to be offline.
    _refs=$(printf '%s' "$_out" | sed -n 's/.*"refs": "\([a-z_]*\)".*/\1/p')
    if [ -n "$_refs" ]; then
        _why=$(printf '%s' "$_out" | sed -n 's/.*"refs_reason": "\([a-z_]*\)".*/\1/p')
        _doubt=$(printf '%s' "$_out" | sed -n 's/.*"doubtful": \([a-z]*\).*/\1/p')
        add_row "status_refs" true "the read names its refs: ${_refs} (${_why}), doubtful ${_doubt}" load
    else
        add_row "status_refs" false "the read reported no refs field: $(one_line "$_out")" load
    fi

    _out4=$(cd "$REPO_ROOT" && WORKAHOLIC_DEPLOY_FETCH_TIMEOUT=0 sh "$_rep" "$BASE_BRANCH" 2>&1) || true
    _refs4=$(printf '%s' "$_out4" | sed -n 's/.*"refs": "\([a-z_]*\)".*/\1/p')
    if [ "$_refs4" = "skipped" ]; then
        add_row "status_refs_optout" true "the offline opt-out is honoured and named skipped" load
    else
        add_row "status_refs_optout" false "the opt-out did not report skipped: $(one_line "$_out4")" load
    fi

    # The rate bound. The digest is ALLOWED to move between reads of an advancing base --
    # its derivation was deliberately left alone -- so what is checked here is that the
    # day token is well-formed and that two reads of one state key identically. A token
    # that moved every read would restore the hourly restatement the bound removed.
    _day=$(printf '%s' "$_out" | sed -n 's/.*"day_token": "\([0-9a-f:-]*\)".*/\1/p')
    _day2=$(printf '%s' "$_out2" | sed -n 's/.*"day_token": "\([0-9a-f:-]*\)".*/\1/p')
    if printf '%s' "$_day" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}:[0-9a-f]{8}$' \
        && [ "$_day" = "$_day2" ]; then
        _tz=$(printf '%s' "$_out" | sed -n 's/.*"tz": "\([A-Za-z/_+-]*\)".*/\1/p')
        add_row "status_rate" true "the ask keys to ${_day} (${_tz}), so it is said once a day" load
    else
        add_row "status_rate" false "the day token is malformed or unstable: '${_day}' -> '${_day2}'" load
    fi

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "status" 0 "fail" 1
    fi
    emit_verdict "status" 0 "pass" 0
}

# --------------------------------------------------------------- verify-cadence
#
# The daily per-target note generation that rides the same repository tick. Like
# `verify-status` it exists so the behaviour is checkable in seconds rather than by
# waiting a day and reading a GitHub draft release. It proves four properties:
#
#   cadence_renders    every declared target renders a draft body
#   cadence_idempotent two renders of an unchanged base are byte-identical, which is
#                      what keeps a periodic generator from being a write treadmill
#   cadence_clockfree  two renders taken a second apart still match, so no clock
#                      leaked into the body
#   cadence_stage      the release stage is derived from git and the release record
#
# It never calls `gh` and never writes: the render is pure, and the only writing step
# (the sync) is deliberately out of scope here so the drill stays hermetic.
cmd_verify_cadence() {
    _drafter="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/draft-release-note.sh"
    _cadence="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/run-note-cadence.sh"
    if [ ! -f "$_drafter" ] || [ ! -f "$_cadence" ]; then
        emit_err "cadence_unreadable" 4 "the note cadence scripts are not present in this checkout"
    fi

    _a=$(cd "$REPO_ROOT" && sh "$_drafter" "$BASE_BRANCH" 2>&1) || true
    case "$_a" in
        *'"ok": true'*)
            _n=$(printf '%s' "$_a" | sed -n 's/.*"count": \([0-9]*\).*/\1/p')
            add_row "cadence_renders" true "a draft rendered for ${_n} target(s)" load
            ;;
        *)
            add_row "cadence_renders" false "$(one_line "$_a")" load
            emit_verdict "cadence" 0 "fail" 1
            ;;
    esac

    _b=$(cd "$REPO_ROOT" && sh "$_drafter" "$BASE_BRANCH" 2>&1) || true
    if [ "$_a" = "$_b" ]; then
        add_row "cadence_idempotent" true "two renders of an unchanged base are byte-identical" load
    else
        add_row "cadence_idempotent" false "two renders of an unchanged base differ, so a periodic tick would write every time" load
    fi

    sleep 1
    _c=$(cd "$REPO_ROOT" && sh "$_drafter" "$BASE_BRANCH" 2>&1) || true
    if [ "$_a" = "$_c" ]; then
        add_row "cadence_clockfree" true "a render a second later still matches, so no clock reached the body" load
    else
        add_row "cadence_clockfree" false "a render a second later differs: a clock leaked into the note body" load
    fi

    _s=$(cd "$REPO_ROOT" && sh "$_cadence" --dry-run "$BASE_BRANCH" 2>&1) || true
    case "$_s" in
        *'"stage": "draft"'*|*'"stage": "staging"'*|*'"stage": "confirmed"'*)
            _st=$(printf '%s' "$_s" | sed -n 's/.*"stage": "\([a-z]*\)".*/\1/p' | head -n 1)
            add_row "cadence_stage" true "the release stage derived as ${_st}" load
            ;;
        *'"reason": "gh_unavailable"'*)
            add_row "cadence_stage" true "no gh in this environment; the cadence refused by reason and wrote nothing" load
            ;;
        *)
            add_row "cadence_stage" false "the stage was not derived: $(one_line "$_s")" load
            ;;
    esac

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "cadence" 0 "fail" 1
    fi
    emit_verdict "cadence" 0 "pass" 0
}

# --------------------------------------------------------------- verify-planner
#
# The RELEASE PLAN chain (2026-08-18, issue #512): the judgment half that CI runs
# beside the writer. It proves what can be proved against this checkout without a
# credential and without the network, and it NAMES what it could not exercise
# rather than reporting it as passed:
#
#   planner_scripts    the planner and the plan renderer are present
#   planner_gated      with no planner command reachable, the planner refuses BY
#                      NAME (`no_planner`) and writes no plan -- which is what makes
#                      an unset CI secret a visible degradation, not a broken job
#   planner_authors    with a stub planner on PATH, a plan is authored and stamped
#                      with this base sha
#   planner_arranges   the rendered note reflects that plan's arrangement
#   planner_visible    a plan that was EXPECTED and did not apply says so on the
#                      note's face, so a broken planner is not mistaken for a list
#   planner_clean      nothing in the checkout moved: the chain writes no file the
#                      caller did not ask for
#
# A base with nothing unreleased cannot exercise the middle rows; they are then
# reported `empty_range` as non-load-bearing rather than counted as passes.
cmd_verify_planner() {
    _planner="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/plan-release.sh"
    _drafter="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/draft-release-note.sh"
    _renderer="${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/render-release-plan.sh"
    if [ ! -f "$_planner" ] || [ ! -f "$_renderer" ] || [ ! -f "$_drafter" ]; then
        emit_err "planner_unreadable" 4 "the release-plan scripts are not present in this checkout"
    fi
    add_row "planner_scripts" true "plan-release.sh and render-release-plan.sh are present" load

    _slug=$(cd "$REPO_ROOT" && sh plugins/workaholic/skills/ship/scripts/read-deployments.sh --slugs 2>/dev/null | head -n 1)
    if [ -z "$_slug" ]; then
        add_row "planner_gated" false "no deployment target is declared, so nothing can be planned" load
        emit_verdict "planner" 0 "fail" 1
    fi

    _dirty_before=$(cd "$REPO_ROOT" && git status --porcelain | wc -l | tr -d " ")
    _work="${TMPDIR:-/tmp}/wh-drill-planner.$$"
    mkdir -p "$_work/out" "$_work/bin"

    # (1) THE GATE. A planner command that does not exist is the shape a CI run with
    # no ANTHROPIC_API_KEY takes, and it must refuse by name rather than crash.
    _g=$(cd "$REPO_ROOT" && WORKAHOLIC_PLANNER_CMD=wh-no-such-planner sh "$_planner" --target "$_slug" --out "$_work/out" "$BASE_BRANCH" 2>&1) || true
    case "$_g" in
        *'"reason": "no_planner"'*)
            add_row "planner_gated" true "no planner reachable: refused as no_planner, no plan written" load ;;
        *'"reason": "empty_range"'*)
            add_row "planner_gated" true "nothing is unreleased for ${_slug}, so the planner correctly planned nothing" load ;;
        *)
            add_row "planner_gated" false "$(one_line "$_g")" load ;;
    esac

    if printf '%s' "$_g" | grep -q '"reason": "empty_range"'; then
        add_row "planner_authors" true "unexercised: nothing is unreleased for ${_slug} on this base" info
        add_row "planner_arranges" true "unexercised: nothing is unreleased for ${_slug} on this base" info
        add_row "planner_visible" true "unexercised: nothing is unreleased for ${_slug} on this base" info
    else
        # (2) THE STUB. The planner command is pluggable precisely so the chain can be
        # driven with no key and no network; the stub answers with one group holding
        # every merge it was shown, in the order it was shown them.
        printf '#!/bin/sh\nsed -n "s/^- #\\([0-9]*\\) .*/\\1/p" | awk "BEGIN{printf \"{\\"groups\\":[{\\"title\\":\\"Drill group\\",\\"items\\":[\"} {printf \"%%s{\\"pr\\":%%s}\", (n++?\",\":\"\"), \$1} END{print \"]}]}\"}"\n' > "$_work/bin/wh-drill-planner"
        chmod +x "$_work/bin/wh-drill-planner"
        _a=$(cd "$REPO_ROOT" && PATH="$_work/bin:$PATH" WORKAHOLIC_PLANNER_CMD=wh-drill-planner sh "$_planner" --target "$_slug" --out "$_work/out" "$BASE_BRANCH" 2>&1) || true
        if printf '%s' "$_a" | grep -q '"planned": true'; then
            add_row "planner_authors" true "a plan was authored for ${_slug} and stamped with this base" load
        else
            add_row "planner_authors" false "$(one_line "$_a")" load
        fi

        _r=$(cd "$REPO_ROOT" && sh "$_drafter" --target "$_slug" --plan "$_work/out/${_slug}.json" "$BASE_BRANCH" 2>&1) || true
        if printf '%s' "$_r" | grep -q '"present": true'; then
            add_row "planner_arranges" true "the note rendered that plan's arrangement" load
        else
            add_row "planner_arranges" false "$(one_line "$_r")" load
        fi

        # (3) THE VISIBLE FALLBACK. A plan EXPECTED and absent must be said out loud.
        _f=$(cd "$REPO_ROOT" && sh "$_drafter" --target "$_slug" --plan "$_work/out/absent.json" "$BASE_BRANCH" 2>&1) || true
        if printf '%s' "$_f" | grep -q "No release plan was applied"; then
            add_row "planner_visible" true "an expected-but-absent plan is named on the note's face" load
        else
            add_row "planner_visible" false "the note fell back silently, so a broken planner reads as a deliberate list" load
        fi
    fi

    rm -rf "$_work"
    _dirty_after=$(cd "$REPO_ROOT" && git status --porcelain | wc -l | tr -d " ")
    if [ "$_dirty_before" = "$_dirty_after" ]; then
        add_row "planner_clean" true "the checkout is exactly as the drill found it" load
    else
        add_row "planner_clean" false "the chain left ${_dirty_after} changed path(s) where it found ${_dirty_before}" load
    fi

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "planner" 0 "fail" 1
    fi
    emit_verdict "planner" 0 "pass" 0
}

cmd_verify_standup() {
    # The [Standup] read. Like verify-status it needs no seed, no fire and no issue number,
    # and it writes nothing anywhere -- which is the routine's whole contract, so asserting
    # it by construction is the point. On a healthy repository with no strategy authored the
    # correct output is NO Slack message at all, so "did it work?" is unanswerable by
    # watching the channel; these rows answer it instead.
    _dig="${REPO_ROOT}/plugins/workaholic/skills/standup/scripts/digest.sh"
    if [ ! -f "$_dig" ]; then
        emit_err "standup_unreadable" 4 "digest.sh is not present in this checkout"
    fi

    # digest.sh emits COMPACT json (jq -c), so every match below tolerates the absent space
    # after a colon rather than assuming the spaced form the shell-printf scripts emit.
    _out=$(cd "$REPO_ROOT" && sh "$_dig" "1 day ago" 2>&1) || true
    if printf '%s' "$_out" | grep -q '"token":[ ]*"standup:'; then
        _n=$(printf '%s' "$_out" | sed -n 's/.*"strategy_count":[ ]*\([0-9]*\).*/\1/p')
        _reason=$(printf '%s' "$_out" | sed -n 's/.*"noop_reason":[ ]*"\([a-z_]*\)".*/\1/p')
        add_row "standup_read" true "the digest covers ${_n} strategy(ies), noop_reason '${_reason}'" load
    else
        add_row "standup_read" false "$(one_line "$_out")" load
        emit_verdict "standup" 0 "fail" 1
    fi

    # A repository with no strategy authored must be a NAMED no-op, never an empty digest:
    # the silence is what allows a daily post to exist at all, and a nameless empty one is
    # indistinguishable from a read that failed.
    if printf '%s' "$_out" | grep -q '"noop":[ ]*true'; then
        if printf '%s' "$_out" | grep -qE '"noop_reason":[ ]*"(no_strategies|no_activity|strategy_list_unreadable)"'; then
            add_row "standup_noop_named" true "a quiet morning names its reason and posts nothing" load
        else
            add_row "standup_noop_named" false "noop with no reason: $(one_line "$_out")" load
        fi
    else
        add_row "standup_noop_named" true "the digest is news today, so the no-op path is not exercised" info
    fi

    # THE PURE READ, demonstrated rather than asserted: the tree is unchanged after the run.
    _dirty=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    _out2=$(cd "$REPO_ROOT" && sh "$_dig" "1 day ago" 2>&1) || true
    _dirty2=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$_dirty" = "$_dirty2" ]; then
        add_row "standup_writes_nothing" true "two runs left the working tree exactly as it was" load
    else
        add_row "standup_writes_nothing" false "the working tree changed across a read: ${_dirty} -> ${_dirty2}" load
    fi

    # An unreadable knowledge root must degrade to a named no-op, not a crash: the routine
    # runs unattended every morning and a non-zero exit is a silent morning nobody explains.
    _out3=$(cd "$REPO_ROOT" && sh "$_dig" "1 day ago" ".workaholic-no-such-root-for-the-drill" 2>&1) || true
    if printf '%s' "$_out3" | grep -q '"noop_reason":[ ]*"no_strategies"'; then
        add_row "standup_degraded" true "an absent knowledge root reads as no strategies and posts nothing" load
    else
        add_row "standup_degraded" false "a degraded read did not answer cleanly: $(one_line "$_out3")" load
    fi

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "standup" 0 "fail" 1
    fi
    emit_verdict "standup" 0 "pass" 0
}
# --------------------------------------------------------------- verify-moderate
# RENAMED FROM `verify-propose` on 2026-08-21 (issue #555): the maintenance tick kept the
# verb from the name it held before the 2026-08-19 rename, and `/propose` is now a real,
# different command with its own drill below. A drill verb that names the wrong command is
# worse than an ugly one.
# Is the maintenance tick sound — every step reported, one log entry, nothing written
# outside the log? The drill runs the tick against a THROWAWAY root so the operator's
# own `.workaholic/moderations/` is never appended to by a drill.
cmd_verify_moderate() {
    _run="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/run.sh"
    if [ ! -f "$_run" ]; then
        emit_err "moderate_unreadable" 4 "moderate/scripts/run.sh is not present in this checkout"
    fi

    # A DELTA, NOT AN ABSOLUTE. The drill runs in whatever checkout the operator has,
    # which may legitimately be mid-edit; reporting their own uncommitted work as the
    # tick's doing is the kind of false red that teaches people to ignore a drill.
    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    mkdir -p "${_root}/.workaholic"
    _tick=$(sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/tick-id.sh" | sed 's/.*"tick": "//; s/".*//')
    _out=$(cd "$REPO_ROOT" && sh "$_run" --tick "$_tick" --root "$_root" 2>&1) || true

    # TEN since the release-status and note-cadence steps merged in (2026-08-19); the count
    # was left at nine and the drill has failed on every run since. Corrected 2026-08-21.
    _steps=$(printf '%s' "$_out" | awk '{ n = gsub(/"step":/, "&"); print n + 0 }')
    if [ "${_steps:-0}" -eq 10 ]; then
        add_row "moderate_steps" true "all ten steps reported" load
    else
        add_row "moderate_steps" false "expected ten reported steps, got ${_steps:-0}: $(one_line "$_out")" load
        rm -rf "$_root"
        emit_verdict "moderate" 0 "fail" 1
    fi

    # A step that cannot run says so BY NAME. `not_implemented` means the mission is
    # half-landed in this checkout, which is a real finding rather than a pass.
    if printf '%s' "$_out" | grep -q '"reason": "not_implemented"'; then
        add_row "moderate_built" false "a step still reports not_implemented in this checkout" load
    else
        add_row "moderate_built" true "no step is left unimplemented" load
    fi

    _day=$(printf '%s' "$_tick" | sed 's/^\(....\)\(..\)\(..\)-.*$/\1-\2-\3/')
    _log="${_root}/.workaholic/moderations/${_day}.md"
    if [ -f "$_log" ]; then
        _sections=$(grep -c '^## ' "$_log" || true)
        # Ten step lines plus the closing act's own `persist-log` line.
        _lines=$(grep -c '^- `' "$_log" || true)
        if [ "$_sections" = "1" ] && [ "$_lines" = "11" ]; then
            add_row "moderate_log" true "one tick section carrying ten step lines and the persist" load
        else
            add_row "moderate_log" false "expected 1 section and 11 lines, got ${_sections} and ${_lines}" load
        fi
    else
        add_row "moderate_log" false "the tick wrote no log at ${_log}" load
    fi

    # THE DRILL MUST NOT PUBLISH. The tick's closing act puts the log on the base, and
    # the drill runs against a throwaway root from inside the operator's own checkout —
    # so the one thing worth pinning here is that a root outside a repository is skipped
    # BY NAME rather than committed into whatever repository the cwd happens to be.
    if printf '%s' "$_out" | grep -q '"reason": "not_a_repo"'; then
        add_row "moderate_persist" true "the drill's throwaway root is skipped by name, never published" load
    else
        add_row "moderate_persist" false "the persist did not report not_a_repo for a throwaway root: $(one_line "$_out")" load
    fi

    # Nothing outside the log: a maintenance tick that dirtied the checkout would be
    # writing to `main` on an hourly schedule, which is the thing it must never do.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _dirty=$(printf '%s\n' "$_before" "$_after" | sort | uniq -u | head -5)
    if [ -z "$_dirty" ]; then
        add_row "moderate_clean" true "the tick added nothing to the checkout's own state" load
    else
        add_row "moderate_clean" false "the tick changed the checkout: $(one_line "$_dirty")" load
    fi

    rm -rf "$_root"

    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "moderate" 0 "fail" 1
    fi
    emit_verdict "moderate" 0 "pass" 0
}

# ----------------------------------------------------------------- verify-propose
# Is the BRAKE sound? `/propose` is the one routine here that drops the standing
# conservative bar on purpose, so what is worth drilling is not that it can propose but
# that it REFUSES when it must. The drill builds a throwaway strategy tree, hands the
# survey a synthetic open-proposal list (`--open-proposals`, so no network is touched),
# and checks each gate by name — including the two that would turn the dropped bar into an
# unbounded routine if they ever stopped holding: the in-flight gate and the unreadable
# inbox.
cmd_verify_propose() {
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _open_sh="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/open-proposal.sh"
    if [ ! -f "$_survey" ] || [ ! -f "$_open_sh" ]; then
        emit_err "propose_unreadable" 4 "propose/scripts is not present in this checkout"
    fi

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    mkdir -p "${_root}/strategies" "${_root}/feedbacks"
    printf -- '---\ntype: Feedback\n---\n\nx\n' > "${_root}/feedbacks/20260101000000-a.md"
    _far=$(date -u -d "+30 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _near=$(date -u -d "+3 days" +%Y-%m-%d 2>/dev/null || echo 2098-01-01)
    _gone=$(date -u -d "-2 days" +%Y-%m-%d 2>/dev/null || echo 2000-01-01)
    _mk() { # slug status target assignee refs
        cat > "${_root}/strategies/$1.md" <<EOF
---
type: Strategy
title: $1
slug: $1
status: $2
target_date: $3
assignees: [$4]
feedback: [$5]
---

# $1

## Aim

a

## Schedule

s
EOF
    }
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _mk live   active   "$_far"  "$_me"             20260101000000-a.md
    _mk urgent active   "$_near" "$_me"             20260101000000-a.md
    _mk closed achieved "$_far"  "$_me"             20260101000000-a.md
    _mk theirs active   "$_far"  "somebody@else.tld" 20260101000000-a.md
    _mk late   active   "$_gone" "$_me"             20260101000000-a.md
    _mk blind  active   "$_far"  "$_me"             ""

    _open="${_root}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    _out=$(cd "$REPO_ROOT" && sh "$_survey" --open-proposals "$_open" "30 days ago" "$_root" 2>&1) || true

    _reason() { printf '%s' "$_out" | sed -n "s/.*{\"slug\": *\"$1\", *\"reason\": *\"\([a-z_]*\)\".*/\1/p" | head -1; }
    _sel=$(printf '%s' "$_out" | sed -n 's/.*"selected": *\[\([^]]*\)\].*/\1/p')

    if printf '%s' "$_sel" | grep -q '"urgent"'; then
        add_row "propose_nearest_first" true "the tick takes the direction whose date is nearest" load
    else
        add_row "propose_nearest_first" false "expected urgent to be selected, got: $(one_line "$_sel")" load
    fi

    for _pair in "closed:not_active" "theirs:not_mine" "late:past_target_date" "blind:no_feedback_refs"; do
        _slug=${_pair%%:*}; _want=${_pair#*:}
        _got=$(_reason "$_slug")
        if [ "$_got" = "$_want" ]; then
            add_row "propose_gate_${_slug}" true "${_slug} refused as ${_want}" load
        else
            add_row "propose_gate_${_slug}" false "expected ${_want} for ${_slug}, got '${_got:-nothing}'" load
        fi
    done

    # THE IN-FLIGHT GATE. One proposal per strategy at a time is what bounds a routine
    # whose judgment bar was deliberately dropped; if this stops holding, nothing else does.
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": [{"number": 1, "url": "u", "strategy": "urgent", "move": "depth", "title": "t"}]}\n' > "$_open"
    _out=$(cd "$REPO_ROOT" && sh "$_survey" --open-proposals "$_open" "30 days ago" "$_root" 2>&1) || true
    if [ "$(_reason urgent)" = "open_proposal" ]; then
        add_row "propose_in_flight" true "a strategy with a proposal still open is refused" load
    else
        add_row "propose_in_flight" false "the in-flight gate did not hold: $(one_line "$_out")" load
    fi

    # THE MISSION GRAIN (2026-08-26). The brake asks whether a MISSION is in flight, and the
    # case that matters is the one the change-grain gate left open: a mission whose queue is
    # DRAINED — its last ticket claimed and archived — while its work is still at a pull
    # request. Under the old arithmetic that strategy was eligible and a second mission
    # would have been proposed against it.
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    mkdir -p "${_root}/missions/active/drained" "${_root}/tickets/archive/work-x"
    printf -- '---\ntype: Mission\ntitle: Drained\nslug: drained\nstatus: active\nfeedback: [20260101000000-a.md]\n---\n\n# Drained\n' \
        > "${_root}/missions/active/drained/mission.md"
    printf -- '---\ncreated_at: 2026-08-26T00:00:00+00:00\nstatus: done\nmission: drained\n---\n\n# Done\n' \
        > "${_root}/tickets/archive/work-x/20260826000001-done.md"
    _out=$(cd "$REPO_ROOT" && sh "$_survey" --open-proposals "$_open" "30 days ago" "$_root" 2>&1) || true
    if [ "$(_reason live)" = "work_waiting" ]; then
        add_row "propose_mission_in_flight" true "a strategy whose mission is active with a drained queue is still gated" load
    else
        add_row "propose_mission_in_flight" false "the mission-grain gate did not hold: $(one_line "$_out")" load
    fi

    # And it LIFTS when the mission is closed — the whole point of "one mission per strategy
    # at a time" is that the next turn begins, so a gate that never released would be a stall
    # rather than a brake.
    mkdir -p "${_root}/missions/archive/drained"
    mv "${_root}/missions/active/drained/mission.md" "${_root}/missions/archive/drained/mission.md"
    sed -i.bak 's/^status: active$/status: achieved/' "${_root}/missions/archive/drained/mission.md" 2>/dev/null \
        || sed -i '' 's/^status: active$/status: achieved/' "${_root}/missions/archive/drained/mission.md"
    rm -rf "${_root}/missions/active/drained" "${_root}/missions/archive/drained/mission.md.bak"
    _out=$(cd "$REPO_ROOT" && sh "$_survey" --open-proposals "$_open" "30 days ago" "$_root" 2>&1) || true
    if [ -z "$(_reason live)" ]; then
        add_row "propose_mission_released" true "a closed mission frees the strategy for its next turn" load
    else
        add_row "propose_mission_released" false "the gate did not release: $(one_line "$_out")" load
    fi
    rm -rf "${_root}/tickets"

    # A GATE THAT CANNOT BE READ IS NOT A GATE: the whole tick refuses rather than
    # falling through to a permissive default.
    printf '{"ok": false, "reason": "list_failed"}\n' > "$_open"
    _out=$(cd "$REPO_ROOT" && sh "$_survey" --open-proposals "$_open" "30 days ago" "$_root" 2>&1) || true
    if printf '%s' "$_out" | grep -q '"reason": "inbox_unreadable"'; then
        add_row "propose_unreadable_inbox" true "an unreadable open-proposal list refuses the whole tick" load
    else
        add_row "propose_unreadable_inbox" false "the tick did not refuse an unreadable inbox: $(one_line "$_out")" load
    fi

    # The write floor, on the paths that run before any network call.
    _body="${_root}/body.md"
    printf '%s\n' "## What to change" "" "x" "" "## Why this commits to the strategy" "" "y" "" > "$_body"
    _r=$(cd "$REPO_ROOT" && sh "$_open_sh" --strategy live --move depth --title t --workaholic-root "$_root" "$_body" 2>&1) || true
    if printf '%s' "$_r" | grep -q '"reason": "missing_section"'; then
        add_row "propose_floor_sections" true "a body that names no fork it is chosen against is refused" load
    else
        add_row "propose_floor_sections" false "the section floor did not hold: $(one_line "$_r")" load
    fi
    printf '%s\n' "## What this is chosen against" "" "z" "" >> "$_body"
    _r=$(cd "$REPO_ROOT" && sh "$_open_sh" --strategy live --title t --workaholic-root "$_root" "$_body" 2>&1) || true
    if printf '%s' "$_r" | grep -q '"reason": "no_move"'; then
        add_row "propose_floor_move" true "a proposal declaring no evolutionary move is refused" load
    else
        add_row "propose_floor_move" false "the move floor did not hold: $(one_line "$_r")" load
    fi

    # THE MISSION FLOOR (2026-08-26). The unit a proposal declares its move over is a whole
    # mission, so the body must name the experience and the ordered ticket set, and a set of
    # fewer than two tickets is not a mission. Both refusals run BEFORE any network call,
    # which is what makes them drillable here.
    _mbody="${_root}/mission-body.md"
    printf '%s\n' "## What to change" "" "x" "" "## Why this commits to the strategy" "" "y" "" \
        "## What this is chosen against" "" "z" "" > "$_mbody"
    _r=$(cd "$REPO_ROOT" && sh "$_open_sh" --strategy live --move depth --title t --workaholic-root "$_root" "$_mbody" 2>&1) || true
    if printf '%s' "$_r" | grep -q '"reason": "missing_section"'; then
        add_row "propose_floor_mission_shape" true "a body naming no experience and no ticket set is refused" load
    else
        add_row "propose_floor_mission_shape" false "the mission-shape floor did not hold: $(one_line "$_r")" load
    fi

    printf '%s\n' "## Experience" "" "e" "" "## Tickets" "" "1. only one" "" >> "$_mbody"
    _r=$(cd "$REPO_ROOT" && sh "$_open_sh" --strategy live --move depth --title t --workaholic-root "$_root" "$_mbody" 2>&1) || true
    if printf '%s' "$_r" | grep -q '"reason": "under_planned"'; then
        add_row "propose_floor_two_tickets" true "a proposal naming one ticket is refused as under-planned" load
    else
        add_row "propose_floor_two_tickets" false "the two-ticket floor did not hold: $(one_line "$_r")" load
    fi

    # And the refusal NAMES THE ALTERNATIVE — a refusal stating only the rule leaves the
    # caller retrying the same thing, which is `check-floor.sh`'s own recorded discipline.
    if printf '%s' "$_r" | grep -q 'plain ticket'; then
        add_row "propose_floor_alternative" true "the under-planned refusal names what to do instead" load
    else
        add_row "propose_floor_alternative" false "the refusal states only the rule: $(one_line "$_r")" load
    fi

    # /propose writes NOTHING into the repository — the property that keeps it out of the
    # unattended-main-writer class.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _dirty=$(printf '%s\n' "$_before" "$_after" | sort | uniq -u | head -5)
    if [ -z "$_dirty" ]; then
        add_row "propose_clean" true "the survey and the writer added nothing to the checkout" load
    else
        add_row "propose_clean" false "the drill changed the checkout: $(one_line "$_dirty")" load
    fi

    rm -rf "$_root"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "propose" 0 "fail" 1
    fi
    emit_verdict "propose" 0 "pass" 0
}

# ---------------------------------------------------------------- dispatch

USAGE='{"ok": false, "reason": "usage", "detail": "loop-drill.sh seed|status|reset|verify-specificate <issue>|verify-implement <issue>|verify-plan [--json]|verify-status [--json]|verify-cadence [--json]|verify-planner [--json]|verify-standup [--json]|verify-moderate [--json]|verify-propose [--json]"}'

CMD="${1:-}"
[ -n "$CMD" ] || {
    echo "$USAGE" >&2
    exit 2
}
shift

# `--json` is a presentation flag on the verify stages, accepted in any position so the
# runbook's copy-paste order cannot be wrong.
ARGS=""
for a in "$@"; do
    case "$a" in
        --json) SHOW_ALL_ROWS="true" ;;
        *) ARGS="${ARGS} ${a}" ;;
    esac
done
# Word-splitting is intended: the verify stages take exactly one positional argument
# (an issue number), and `seed`/`status`/`reset` take none.
# shellcheck disable=SC2086
set -- $ARGS

case "$CMD" in
    seed) cmd_seed "$@" ;;
    status) cmd_status "$@" ;;
    reset) cmd_reset "$@" ;;
    verify-specificate) cmd_verify_specificate "$@" ;;
    verify-implement) cmd_verify_implement "$@" ;;
    verify-plan) cmd_verify_plan "$@" ;;
    verify-status) cmd_verify_status "$@" ;;
    verify-cadence) cmd_verify_cadence "$@" ;;
    verify-planner) cmd_verify_planner "$@" ;;
    verify-standup) cmd_verify_standup "$@" ;;
    verify-moderate) cmd_verify_moderate "$@" ;;
    verify-propose) cmd_verify_propose "$@" ;;
    *)
        echo "$USAGE" >&2
        exit 2
        ;;
esac
