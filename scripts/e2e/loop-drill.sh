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
#   loop-drill.sh verify-identity-handoff [--json]  # does the loop stamp an address it can drive?
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

    # THE EXPECTED COUNT IS DERIVED FROM `run.sh`'s OWN `STEPS`, NOT WRITTEN HERE (2026-08-26).
    # It was a literal — nine, then ten — and it went stale every single time a step was added,
    # which is twice more since it was last corrected: the drill has read `expected ten` against
    # a fifteen-step tick since 2026-08-24 and failed on every run, exactly the defect its own
    # previous comment records. The property worth drilling was never the number; it is that
    # EVERY registered step contributes a reported line, so the drill now asks `run.sh` how many
    # it registers and compares. A step added tomorrow needs no edit here, and a step that stops
    # reporting still fails the drill.
    _want=$(sed -n "s/^STEPS='\([^']*\)'.*/\1/p" \
                "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/run.sh" | wc -w | tr -d ' ')
    _steps=$(printf '%s' "$_out" | awk '{ n = gsub(/"step":/, "&"); print n + 0 }')
    if [ "${_want:-0}" -gt 0 ] && [ "${_steps:-0}" -eq "$_want" ]; then
        add_row "moderate_steps" true "all ${_want} registered steps reported" load
    else
        add_row "moderate_steps" false "expected ${_want:-?} reported steps (run.sh's own STEPS), got ${_steps:-0}: $(one_line "$_out")" load
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
        # One line per registered step plus the closing act's own `persist-log` line — derived
        # from `run.sh`'s `STEPS` for the same reason the count above is (2026-08-26): a literal
        # here goes stale on the next step and turns the drill red for a reason that has nothing
        # to do with what it drills.
        _want_lines=$((_want + 1))
        _lines=$(grep -c '^- `' "$_log" || true)
        if [ "$_sections" = "1" ] && [ "$_lines" = "$_want_lines" ]; then
            add_row "moderate_log" true "one tick section carrying ${_want} step lines and the persist" load
        else
            add_row "moderate_log" false "expected 1 section and ${_want_lines} lines, got ${_sections} and ${_lines}" load
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

# ------------------------------------------------------------- verify-revision
# Can the operator revise a LIVE direction through the loop, and does the machine refuse
# everything it must? This is the first write into `.workaholic/strategies/` a machine makes on
# the operator's behalf, and its whole safety rests on a set of REFUSALS — so the refusals are
# drilled by name, each asserting the artifact is byte-identical afterwards, and the exemption
# that keeps the operator's merge the authorship is drilled beside them.
#
# NO NETWORK AND NO CREDENTIAL. The strategy half is local files; the publish half runs against a
# bare local origin with `gh` stubbed, and the stub answers a SUCCESSFUL merge on purpose — a stub
# that refused would let the exemption pass for the wrong reason.
#
# THE DELIBERATELY BROKEN ROW is `revision_immutable_field_unreachable`. It hands the writer a
# flag for a field the model calls immutable. If the interface were widened — a `--status`, a
# `--feedback`, a `--slug` — this row goes red, and it must: that is the difference between a
# machine CARRYING the operator's revision and a machine AUTHORING their direction.
cmd_verify_revision() {
    _amend="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/amend.sh"
    _create="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/create.sh"
    _close="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/close.sh"
    _pub="${REPO_ROOT}/plugins/workaholic/skills/branching/scripts"
    for _f in "$_amend" "$_create" "$_close"; do
        [ -f "$_f" ] || emit_err "revision_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _root="${_tmp}/tree"; _bin="${_tmp}/bin"
    mkdir -p "${_root}/.workaholic" "$_bin"
    ( cd "$_root" && git -c init.defaultBranch=main init -q . \
      && git config user.email drill@example.com && git config user.name Drill \
      && git config commit.gpgsign false ) >/dev/null 2>&1 || true

    _file="${_root}/.workaholic/strategies/ship-the-platform.md"
    _hash() { git -C "$_root" hash-object "$_file" 2>/dev/null || echo missing; }
    _amendit() { ( cd "$_root" && sh "$_amend" "$@" .workaholic ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n 's/.*"'"$2"'": *"\([^"]*\)".*/\1/p' | head -1; }
    _fm() { grep -m1 "^$1:" "$_file" 2>/dev/null || true; }
    _revlines() { grep -c '^Revised [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]: ' "$_file" 2>/dev/null || true; }

    ( cd "$_root" && printf 'Build the platform.\n' | sh "$_create" \
        "Ship the platform" 2026-09-30 "a@example.com" "Start now, freeze in October." \
        "20260101000000-x.md" .workaholic ) >/dev/null 2>&1 || true

    if [ -f "$_file" ] && [ "$(_fm status)" = "status: active" ]; then
        add_row "revision_fixture" true "a live direction exists -- the shape under test" load
    else
        add_row "revision_fixture" false "create.sh did not leave a live direction at ${_file}" load
        rm -rf "$_tmp"
        emit_verdict "revision" 0 "fail" 1
    fi

    _slug0=$(_fm slug); _type0=$(_fm type); _created0=$(_fm created_at); _fb0=$(_fm feedback)
    _untouched() { # $1 = row context
        [ "$(_fm slug)" = "$_slug0" ] && [ "$(_fm type)" = "$_type0" ] \
            && [ "$(_fm created_at)" = "$_created0" ] && [ "$(_fm feedback)" = "$_fb0" ]
    }

    # 1. THE DATE MOVED. The revised part changed, every other field is byte-identical, and one
    # line was appended to the Schedule.
    _o=$(_amendit ship-the-platform --target-date 2026-10-31)
    if printf '%s' "$_o" | grep -q '"amended": true' && [ "$(_fm target_date)" = "target_date: 2026-10-31" ] \
        && _untouched && [ "$(_revlines)" = "1" ] && grep -q '^Target: 2026-10-31$' "$_file"; then
        add_row "revision_date_moved" true "the date moved in the frontmatter and in the Schedule, and one line records it" load
    else
        add_row "revision_date_moved" false "the date revision did not land cleanly: $(one_line "$_o")" load
    fi

    # 2. THE AIM SHARPENED, through the stdin form the model documents.
    _o=$( ( cd "$_root" && printf 'Build the platform, not a document about it.\n' \
        | sh "$_amend" ship-the-platform --aim - .workaholic ) 2>&1 || true )
    if printf '%s' "$_o" | grep -q '"amended": true' \
        && grep -q '^Build the platform, not a document about it\.$' "$_file" \
        && _untouched && [ "$(_fm target_date)" = "target_date: 2026-10-31" ] && [ "$(_revlines)" = "2" ]; then
        add_row "revision_aim_sharpened" true "the aim moved on stdin, the date did not, and a second line records it" load
    else
        add_row "revision_aim_sharpened" false "the aim revision did not land cleanly: $(one_line "$_o")" load
    fi

    # 3. THE ASSIGNEE CHANGED.
    _o=$(_amendit ship-the-platform --assignees "b@example.com, c@example.com")
    if printf '%s' "$_o" | grep -q '"amended": true' \
        && [ "$(_fm assignees)" = "assignees: [b@example.com, c@example.com]" ] \
        && _untouched && [ "$(_revlines)" = "3" ]; then
        add_row "revision_assignee_changed" true "the owner moved and a third line records it, in order" load
    else
        add_row "revision_assignee_changed" false "the assignee revision did not land cleanly: $(one_line "$_o")" load
    fi

    # 4. A NO-OP APPENDS NOTHING. Without this the file grows a line on every tick that re-ran
    # the same ask, which is how an append-only record becomes noise.
    _h=$(_hash)
    _o=$(_amendit ship-the-platform --assignees "b@example.com, c@example.com")
    if [ "$(_field "$_o" reason)" = "already" ] && [ "$_h" = "$(_hash)" ]; then
        add_row "revision_noop_appends_nothing" true "a re-applied revision reports already and leaves the file byte-identical" load
    else
        add_row "revision_noop_appends_nothing" false "a no-op was not idempotent: $(one_line "$_o")" load
    fi

    # 5. AN ASK NAMING NOTHING REVISABLE. "This is going well" is not a revision.
    _h=$(_hash)
    _o=$(_amendit ship-the-platform)
    if [ "$(_field "$_o" reason)" = "no_revision" ] && [ "$_h" = "$(_hash)" ]; then
        add_row "revision_no_revision_refused" true "an ask naming nothing revisable is refused no_revision with nothing written" load
    else
        add_row "revision_no_revision_refused" false "expected no_revision with the file untouched: $(one_line "$_o")" load
    fi

    # 6. A FLOOR BREACH. The write-time hook GRANDFATHERS git-tracked files, so it is silent on
    # exactly these writes and the writer carries the floor itself.
    _h=$(_hash)
    _o=$(_amendit ship-the-platform --assignees "  ,  ")
    if [ "$(_field "$_o" reason)" = "no_assignees" ] && [ "$_h" = "$(_hash)" ]; then
        add_row "revision_floor_breach_refused" true "a floor breach is refused by create.sh's own name with nothing written" load
    else
        add_row "revision_floor_breach_refused" false "expected no_assignees with the file untouched: $(one_line "$_o")" load
    fi

    # THE DELIBERATELY BROKEN ROW. A flag for a field the model calls immutable. A drill that
    # cannot fail proves nothing, and this is the row that would go red if the interface were
    # widened into authoring the operator's direction rather than carrying their revision.
    _h=$(_hash)
    _o=$(_amendit ship-the-platform --status achieved)
    if [ "$(_field "$_o" reason)" = "bad_option" ] && [ "$_h" = "$(_hash)" ] \
        && [ "$(_fm status)" = "status: active" ]; then
        add_row "revision_immutable_field_unreachable" true "an immutable field is unreachable from the interface -- this drill can fail" load
    else
        add_row "revision_immutable_field_unreachable" false "an immutable field was reachable: $(one_line "$_o")" load
    fi

    # 7. A CLOSED DIRECTION IS HISTORY. `close.sh` stays the only writer of an end state, and
    # re-opening is offered nowhere.
    ( cd "$_root" && sh "$_close" ship-the-platform achieved .workaholic ) >/dev/null 2>&1 || true
    _h=$(_hash)
    _o=$(_amendit ship-the-platform --target-date 2027-01-01)
    if [ "$(_field "$_o" reason)" = "not_active" ] && [ "$_h" = "$(_hash)" ]; then
        add_row "revision_not_active_refused" true "a closed direction is refused not_active with nothing written" load
    else
        add_row "revision_not_active_refused" false "expected not_active with the file untouched: $(one_line "$_o")" load
    fi

    # 8. THE EXEMPTION. A publish whose tree touches `.workaholic/strategies/` does not merge
    # even with WORKAHOLIC_AUTO_MERGE=1 -- the operator's merge is what authors that artifact,
    # and since 2026-08-27 that is the seam's refusal rather than the caller's judgement.
    _origin="${_tmp}/origin"; _pubtree="${_tmp}/pub"
    git -c init.defaultBranch=main init -q --bare "$_origin" >/dev/null 2>&1 || true
    git clone -q "$_origin" "$_pubtree" >/dev/null 2>&1 || true
    ( cd "$_pubtree" && git config user.email drill@example.com && git config user.name Drill \
      && git config commit.gpgsign false && echo seed > README.md \
      && git add -A && git commit -qm seed && git push -q origin main ) >/dev/null 2>&1 || true
    printf '#!/bin/sh\ncase "$1 $2" in\n  "api user") printf "tester\\n"; exit 0 ;;\nesac\ncase "$*" in\n  *pulls*POST*) echo %s; exit 0 ;;\n  *merge*) echo %s; exit 0 ;;\nesac\necho ""\n' \
        "'{\"html_url\":\"https://drill.invalid/pr/1\",\"number\":1}'" "'{\"merged\":true}'" > "${_bin}/gh"
    chmod +x "${_bin}/gh"
    _pubout=$( ( cd "$_pubtree" && sh "${_pub}/open-publish-tree.sh" >/dev/null 2>&1
        mkdir -p .publish/.workaholic/strategies
        cp "$_file" .publish/.workaholic/strategies/ship-the-platform.md
        PATH="${_bin}:$PATH" WORKAHOLIC_AUTO_MERGE=1 sh "${_pub}/publish-tree-pr.sh" \
            "Propose strategy ship-the-platform" why None None None verify \
            .workaholic/strategies/ship-the-platform.md 2>/dev/null
        sh "${_pub}/close-publish-tree.sh" >/dev/null 2>&1 ) | grep '"merge_reason"' | tail -1 )
    if [ "$(_field "$_pubout" merge_reason)" = "strategy_touching" ] \
        && printf '%s' "$_pubout" | grep -q '"merged": false'; then
        add_row "revision_publish_never_merges" true "a strategy-touching publish is left open even with WORKAHOLIC_AUTO_MERGE=1" load
    else
        add_row "revision_publish_never_merges" false "a strategy-touching publish was not held open: $(one_line "$_pubout")" load
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "revision_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "revision_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "revision" 0 "fail" 1
    fi
    emit_verdict "revision" 0 "pass" 0
}

# ------------------------------------------------------ verify-direction-health
# Does the loop SAY when it has run out of direction? Three states used to be silent and
# each was byte-identical to a healthy idle hour, so "did it work?" is unanswerable by
# watching a channel — an hour with no post looks the same whether the reading fired or
# the step is broken. These rows answer it instead, with NO NETWORK and NO CREDENTIAL.
#
# THE OPEN-PROPOSAL READ IS SUPPLIED, NOT STUBBED. `survey-strategies.sh` makes exactly one
# network call (the open-proposal gate) and refuses the whole tick rather than proceed
# without it. Handing the answer in through `--open-proposals` drills the real path; faking
# the transport would drill a path that does not exist.
cmd_verify_direction_health() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-direction-health.sh"
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    if [ ! -f "$_reader" ] || [ ! -f "$_step" ]; then
        emit_err "direction_health_unreadable" 4 "direction-state.sh or step-direction-health.sh is not present in this checkout"
    fi

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    mkdir -p "${_root}/.workaholic/strategies" "${_root}/.workaholic/feedbacks"
    printf -- '---\ntype: Feedback\n---\n\nx\n' > "${_root}/.workaholic/feedbacks/20260101000000-a.md"
    _gone=$(date -u -d "-30 days" +%Y-%m-%d 2>/dev/null || echo 2000-01-01)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _mk() { # slug target
        cat > "${_root}/.workaholic/strategies/$1.md" <<EOF
---
type: Strategy
title: T $1
slug: $1
status: active
target_date: $2
assignees: [${_me}]
feedback: [20260101000000-a.md]
---

# $1

## Aim

a

## Schedule

s
EOF
    }
    # `gone` is the case `pace` CANNOT carry: past its date WHILE PRODUCING WORK, so `pace`
    # reads `on_course` and nobody was ever told. The landed work is a mission attributed
    # through the same feedback ref, which is what `attributed-work.sh` walks.
    _mk gone "$_gone"
    _mk quiet "$_far"
    mkdir -p "${_root}/.workaholic/missions/archive/landed"
    printf -- '---\ntype: Mission\ntitle: Landed\nslug: landed\nstatus: achieved\nfeedback: [20260101000000-a.md]\n---\n\n# Landed\n' \
        > "${_root}/.workaholic/missions/archive/landed/mission.md"
    _open="${_root}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"

    _state=$(cd "$REPO_ROOT" && sh "$_reader" --open-proposals "$_open" "14 days ago" "${_root}/.workaholic" 2>&1) || true
    # The readers emit two formattings — jq's compact one and the shell printf's spaced
    # one — so every match below tolerates the optional space rather than assuming a producer.
    _stateof() { printf '%s' "$_state" | sed -n "s/.*\"slug\": *\"$1\", *[^}]*\"state\": *\"\([a-z]*\)\".*/\1/p" | head -1; }

    for _pair in "gone:overdue" "quiet:dormant"; do
        _slug=${_pair%%:*}; _want=${_pair#*:}
        _got=$(_stateof "$_slug")
        if [ "$_got" = "$_want" ]; then
            add_row "direction_state_${_slug}" true "${_slug} reads ${_want}" load
        else
            add_row "direction_state_${_slug}" false "expected ${_want} for ${_slug}, got '${_got:-nothing}': $(one_line "$_state")" load
        fi
    done

    # `none` is the REPOSITORY-level reading: no active strategy at all.
    _empty=$(mktemp -d); mkdir -p "${_empty}/.workaholic"
    _none=$(cd "$REPO_ROOT" && sh "$_reader" --open-proposals "$_open" "14 days ago" "${_empty}/.workaholic" 2>&1) || true
    if printf '%s' "$_none" | grep -q '"repository":[ ]*"none"'; then
        add_row "direction_state_none" true "a tree with no active strategy reads none at the repository level" load
    else
        add_row "direction_state_none" false "expected repository none: $(one_line "$_none")" load
    fi

    # A READING THAT COULD NOT BE MADE IS NAMED, never folded into any other answer.
    printf '{"ok": false, "reason": "list_failed"}\n' > "${_root}/bad.json"
    _bad=$(cd "$REPO_ROOT" && sh "$_reader" --open-proposals "${_root}/bad.json" "14 days ago" "${_root}/.workaholic" 2>&1) || true
    if printf '%s' "$_bad" | grep -q '"readable":[ ]*false' && printf '%s' "$_bad" | grep -q '"repository":[ ]*"unreadable"'; then
        add_row "direction_state_unreadable" true "a survey that refused is reported unreadable, never as quiet" load
    else
        add_row "direction_state_unreadable" false "a refused survey was not named: $(one_line "$_bad")" load
    fi

    # THE QUESTION KEYS. They are what `ask-question.sh`'s asked-once ledger keys on, so a
    # key that drifts is a question asked twice or never.
    _out=$(cd "$REPO_ROOT" && sh "$_step" --tick 20260101-000000 --root "$_root" --open-proposals "$_open" 2>&1) || true
    _keys=$(printf '%s' "$_out" | tr ',' '\n' | sed -n 's/.*"key": *"\([^"]*\)".*/\1/p' | sort | tr '\n' ' ')
    if [ "$_keys" = "direction-dormant:quiet direction-overdue:gone " ]; then
        add_row "direction_health_keys" true "the step asks exactly direction-overdue:gone and direction-dormant:quiet" load
    else
        add_row "direction_health_keys" false "unexpected question keys: '${_keys}'" load
    fi
    # THE ACT NAMED IN THE `overdue` BODY (2026-08-27). Re-dating is something the operator can
    # now do THROUGH the loop, so the question about an expired direction must offer it -- in
    # THEIR vocabulary (*re-date it*, never *run amend.sh*), inside notify's 25-word bound, and
    # with the closing clause restated rather than dropped. The `dormant` body deliberately does
    # NOT move: a direction nothing is answering is not thereby mis-dated.
    _obody=$(sed -n 's/.*then "\(Re-date it[^"]*\)".*/\1/p' "$_step" | head -1)
    _owords=$(printf '%s' "$_obody" | wc -w | tr -d ' ')
    if printf '%s' "$_out" | grep -q 'Re-date it, announce that it ended, or say it still stands' \
        && printf '%s' "$_out" | grep -q 'the loop carries what you announce' \
        && [ -n "$_obody" ] && [ "$_owords" -le 25 ] \
        && ! printf '%s' "$_obody" | grep -q 'amend.sh'; then
        add_row "direction_health_overdue_names_the_revision" true "the overdue body names re-dating, in the operator's vocabulary, in ${_owords} words" load
    else
        add_row "direction_health_overdue_names_the_revision" false "the overdue body does not name the revision act inside the bound (${_owords} words): $(one_line "$_obody")" load
    fi
    if printf '%s' "$_out" | grep -q 'File its next move, or say it still stands'; then
        add_row "direction_health_dormant_unchanged" true "the dormant body was not widened by reflex" load
    else
        add_row "direction_health_dormant_unchanged" false "the dormant body moved: $(one_line "$_out")" load
    fi

    _nout=$(cd "$REPO_ROOT" && sh "$_step" --tick 20260101-000000 --root "$_empty" --open-proposals "$_open" 2>&1) || true
    if printf '%s' "$_nout" | grep -q '"key":[ ]*"direction-none"'; then
        add_row "direction_health_key_none" true "an empty tree asks direction-none, addressed to nobody" load
    else
        add_row "direction_health_key_none" false "the repository-level key is missing: $(one_line "$_nout")" load
    fi

    # ASKED ONCE. The gate is the check-in's, not this step's, so the drill exercises the
    # gate with this step's key: the first ask is allowed, the second is refused by name.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _a1=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-000000 --key "direction-overdue:gone" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000000 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-010000 --key "direction-overdue:gone" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "direction_health_asked_once" true "the same key is refused on a later tick: $(printf '%s' "$_a2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "direction_health_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "direction_health_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi

    # IT WROTE NOTHING, `.workaholic/strategies/` INCLUDED. The fixtures are outside the
    # checkout, so the checkout must be byte-identical to what it was before the drill.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "direction_health_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "direction_health_writes_nothing" false "the drill changed the working tree" load
    fi
    _seeded=$(ls "${_root}/.workaholic/strategies" | sort | tr '\n' ' ')
    if [ "$_seeded" = "gone.md quiet.md " ]; then
        add_row "direction_health_fixtures_intact" true "the seeded strategies area is untouched by the reader and the step" load
    else
        add_row "direction_health_fixtures_intact" false "the fixture strategies area changed: '${_seeded}'" load
    fi

    rm -rf "$_root" "$_empty" "$_qroot"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "direction-health" 0 "fail" 1
    fi
    emit_verdict "direction-health" 0 "pass" 0
}

# ------------------------------------------------------------- verify-arrival
# Does the loop SAY when a direction has arrived? Every reading the direction layer carried
# before this answered *is this direction in trouble* — `pace`, `overdue`, `dormant`. None
# answered *has it arrived*, so a direction whose work was all in looked exactly like one still
# running, and once its date passed the loop reported that SUCCESS as an hourly
# `direction-overdue` question. These rows answer it, with NO NETWORK and NO CREDENTIAL.
#
# THE FIXTURE IS A GIT REPOSITORY, and it has to be. `landed[]` is `attributed-work.sh`'s set of
# attributed artifacts that CHANGED INSIDE THE WINDOW, and that reading is `git log --since`. A
# fixture that is only a directory tree yields an empty `landed[]` for every strategy, so
# `quiescent` would be `false` everywhere and every row below would pass while proving nothing.
#
# THE OPEN-PROPOSAL READ IS SUPPLIED, NOT STUBBED — `verify-direction-health`'s rule, for its
# reason: the survey makes exactly one network call and refuses the tick rather than proceed
# without it, so handing the answer in through `--open-proposals` drills the real path.
#
# THE DATES ARE PASSED IN, never taken from the wall clock inside an assertion, so the drill
# does not rot on a fixed date.
#
# AND ONE FIXTURE DELIBERATELY BREAKS THE SEAM: `busy` has landed work AND work still waiting.
# It must read `live`, never `arrived`. If `quiescent` ever stopped reading `waiting_missions +
# waiting_count`, every other row here would still pass — which is exactly how a drill converts
# an unproven claim into a believed one.
cmd_verify_arrival() {
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _reader="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-direction-health.sh"
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    for _f in "$_survey" "$_reader" "$_step" "$_ask"; do
        [ -f "$_f" ] || emit_err "arrival_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _gone=$(date -u -d "-30 days" +%Y-%m-%d 2>/dev/null || echo 2000-01-01)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    mkdir -p "${_root}/.workaholic/strategies" "${_root}/.workaholic/feedbacks" \
             "${_root}/.workaholic/missions/archive" "${_root}/.workaholic/missions/active" \
             "${_root}/.workaholic/tickets/todo"
    _mkfb() { printf -- '---\ntype: Feedback\n---\n\nx\n' > "${_root}/.workaholic/feedbacks/2026010100000$1-$1.md"; }
    _mkst() { # slug target feedback-ref
        cat > "${_root}/.workaholic/strategies/$1.md" <<EOF
---
type: Strategy
title: T $1
slug: $1
status: active
target_date: $2
assignees: [${_me}]
feedback: [$3]
---

# $1

## Aim

a

## Schedule

s
EOF
    }
    _mkmission() { # slug status area feedback-ref
        mkdir -p "${_root}/.workaholic/missions/$3/$1"
        printf -- '---\ntype: Mission\ntitle: M %s\nslug: %s\nstatus: %s\nfeedback: [%s]\n---\n\n# M %s\n' \
            "$1" "$1" "$2" "$4" "$1" > "${_root}/.workaholic/missions/$3/$1/mission.md"
    }
    for _r in a b c d; do _mkfb "$_r"; done
    _mkst arrived     "$_far"  2026010100000a-a.md
    _mkst latearrived "$_gone" 2026010100000a-a.md
    _mkst quiet       "$_far"  2026010100000b-b.md
    _mkst gone        "$_gone" 2026010100000c-c.md
    _mkst busy        "$_far"  2026010100000d-d.md
    _mkmission landed  achieved archive 2026010100000a-a.md
    _mkmission shipped achieved archive 2026010100000d-d.md
    _mkmission running active   active  2026010100000d-d.md
    printf -- '---\nmission: running\n---\n\n# Q\n' > "${_root}/.workaholic/tickets/todo/20260101000001-q.md"
    _open="${_root}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    printf '{"ok": false, "reason": "list_failed"}\n' > "${_root}/bad.json"
    ( cd "$_root" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true

    _state=$(cd "$_root" && sh "$_reader" --open-proposals "$_open" "14 days ago" "${_root}/.workaholic" 2>&1) || true
    # The readers emit two formattings — jq's compact one and the shell printf's spaced one —
    # so every match tolerates the optional space rather than assuming a producer.
    _stateof() { printf '%s' "$_state" | sed -n "s/.*\"slug\": *\"$1\", *[^}]*\"state\": *\"\([a-z]*\)\".*/\1/p" | head -1; }
    _landedof() { printf '%s' "$_state" | sed -n "s/.*\"slug\": *\"$1\", *[^}]*\"landed\": *\([0-9][0-9]*\).*/\1/p" | head -1; }

    # THE FIXTURE HAS TO BE THE SHAPE UNDER TEST. `landed[]` is a `git log --since` reading, so
    # a fixture that produced none would make every arrival row below vacuously true.
    if [ "$(_landedof arrived)" != "0" ] && [ -n "$(_landedof arrived)" ]; then
        add_row "arrival_fixture" true "the fixture really produces attributed work inside the window ($(_landedof arrived) item(s))" load
    else
        add_row "arrival_fixture" false "no attributed work landed in the fixture, so no arrival row would prove anything: $(one_line "$_state")" load
        rm -rf "$_root"
        emit_verdict "arrival" 0 "fail" 1
    fi

    # THE FOUR READINGS. `latearrived` is the one the mission exists for: past its date AND
    # finished, which must read `arrived` rather than `overdue`.
    for _pair in "arrived:arrived" "latearrived:arrived" "quiet:dormant" "gone:overdue"; do
        _slug=${_pair%%:*}; _want=${_pair#*:}
        _got=$(_stateof "$_slug")
        if [ "$_got" = "$_want" ]; then
            add_row "arrival_state_${_slug}" true "${_slug} reads ${_want}" load
        else
            add_row "arrival_state_${_slug}" false "expected ${_want} for ${_slug}, got '${_got:-nothing}': $(one_line "$_state")" load
        fi
    done

    # THE DELIBERATELY BROKEN SEAM. `busy` has landed work AND a queued ticket behind an active
    # mission. If `quiescent` ever stopped reading the waiting terms, this is the only row that
    # would notice — every other row here would still pass.
    if [ "$(_stateof busy)" = "live" ]; then
        add_row "arrival_waiting_work_is_not_arrival" true "a direction with work still waiting reads live, never arrived -- this drill can fail" load
    else
        add_row "arrival_waiting_work_is_not_arrival" false "a direction with waiting work read '$(_stateof busy)', so arrival is being asserted over work in flight" load
    fi

    # A READING WE COULD NOT MAKE IS NAMED, never dressed as an arrival.
    _bad=$(cd "$_root" && sh "$_reader" --open-proposals "${_root}/bad.json" "14 days ago" "${_root}/.workaholic" 2>&1) || true
    if printf '%s' "$_bad" | grep -q '"readable":[ ]*false' \
        && printf '%s' "$_bad" | grep -q '"repository":[ ]*"unreadable"' \
        && printf '%s' "$_bad" | grep -q '"arrived":[ ]*0'; then
        add_row "arrival_state_unreadable" true "a survey that refused is unreadable with zero arrivals, never a silent arrival" load
    else
        add_row "arrival_state_unreadable" false "a refused survey was not named: $(one_line "$_bad")" load
    fi

    # THE QUESTION KEY. It is what `ask-question.sh`'s asked-once ledger keys on, so a key that
    # drifts is a question asked twice or never.
    _out=$(cd "$_root" && sh "$_step" --tick 20260101-000000 --root "$_root" --open-proposals "$_open" 2>&1) || true
    _keys=$(printf '%s' "$_out" | tr ',' '\n' | sed -n 's/.*"key": *"\([^"]*\)".*/\1/p' | sort | tr '\n' ' ')
    if [ "$_keys" = "direction-arrived:arrived direction-arrived:latearrived direction-dormant:quiet direction-overdue:gone " ]; then
        add_row "arrival_question_keys" true "the step asks direction-arrived for both arrived directions and nothing about the live one" load
    else
        add_row "arrival_question_keys" false "unexpected question keys: '${_keys}'" load
    fi

    # THE BODY IS A DESCRIPTION OF THE READING. It names WHAT LANDED and THE DATE, stays inside
    # notify's 25-word bound, and asserts NOTHING about the direction being finished -- the
    # discipline `dormant` is already held to.
    _abody=$(printf '%s' "$_out" | sed -n 's/.*"body": *"\(Everything attributed[^"]*\)".*/\1/p' | head -1)
    _awords=$(printf '%s' "$_abody" | wc -w | tr -d ' ')
    if printf '%s' "$_out" | grep -q 'item(s) landed, dated ' \
        && [ -n "$_abody" ] && [ "$_awords" -le 25 ] \
        && printf '%s' "$_abody" | grep -q 'the loop closes nothing' \
        && ! printf '%s' "$_abody" | grep -qi 'is finished\|is done\|has been achieved'; then
        add_row "arrival_body_describes_the_reading" true "the arrival question names what landed and the date in ${_awords} words, and claims nothing about being finished" load
    else
        add_row "arrival_body_describes_the_reading" false "the arrival body is wrong (${_awords} words): $(one_line "$_abody")" load
    fi

    # THE ROOT LINE NAMES A REPOSITORY EVENT and links the direction; an all-`live` tick renders
    # no line at all, which is the independent guard against a nothing-happened line.
    if printf '%s' "$_out" | grep -q '"event": "[^"]*direction[s]* ha[sve][^"]*work in' \
        && printf '%s' "$_out" | grep -q 'strategies/arrived.md'; then
        add_row "arrival_event" true "the tick reports the arrival as a repository event and links the direction" load
    else
        add_row "arrival_event" false "the arrival did not reach the root: $(one_line "$_out")" load
    fi
    _live=$(mktemp -d)
    mkdir -p "${_live}/.workaholic/strategies" "${_live}/.workaholic/feedbacks" \
             "${_live}/.workaholic/missions/active" "${_live}/.workaholic/tickets/todo"
    cp "${_root}/.workaholic/feedbacks/2026010100000d-d.md" "${_live}/.workaholic/feedbacks/"
    cp "${_root}/.workaholic/strategies/busy.md" "${_live}/.workaholic/strategies/"
    cp -r "${_root}/.workaholic/missions/active/running" "${_live}/.workaholic/missions/active/"
    cp "${_root}/.workaholic/tickets/todo/20260101000001-q.md" "${_live}/.workaholic/tickets/todo/"
    ( cd "$_live" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true
    _lout=$(cd "$_live" && sh "$_step" --tick 20260101-000000 --root "$_live" --open-proposals "$_open" 2>&1) || true
    if printf '%s' "$_lout" | grep -q '"event": ""'; then
        add_row "arrival_all_live_renders_no_line" true "a tick with nothing but live directions supplies an empty event" load
    else
        add_row "arrival_all_live_renders_no_line" false "an all-live tick produced an event: $(one_line "$_lout")" load
    fi

    # ASKED ONCE. The gate is the check-in's, not this step's, so the drill exercises the gate
    # with this step's new key: the first ask is allowed, the second refused by name.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _a1=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-000000 --key "direction-arrived:arrived" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000000 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-010000 --key "direction-arrived:arrived" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "arrival_asked_once" true "the same key is refused on a later tick: $(printf '%s' "$_a2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "arrival_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "arrival_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi

    # NO READING CLOSES A DIRECTION. The mission that added `arrived` is exactly the one that
    # tempts a fourth writer, so the drill checks what the step can EXECUTE rather than what its
    # prose promises. `test-workflow-scripts.mjs` holds the same line; both is deliberate.
    _closure=$(sed 's/^[[:space:]]*#.*$//' "$_step" "${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh")
    if printf '%s' "$_closure" | grep -q 'close\.sh\|amend\.sh\|create\.sh'; then
        add_row "arrival_closes_nothing" false "the step's closure reaches a strategy writer" load
    else
        add_row "arrival_closes_nothing" true "neither the step nor the reader can reach create.sh, amend.sh or close.sh" load
    fi

    # IT WROTE NOTHING. The fixtures are outside the checkout, so the checkout must be
    # byte-identical, and the seeded strategies area must be untouched by reader and step alike.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "arrival_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "arrival_writes_nothing" false "the drill changed the working tree" load
    fi
    _seeded=$(cd "$_root" && git status --porcelain -- .workaholic/strategies | tr -d '\n')
    if [ -z "$_seeded" ]; then
        add_row "arrival_fixtures_intact" true "the seeded strategies area is untouched by the reader and the step" load
    else
        add_row "arrival_fixtures_intact" false "the fixture strategies area changed: '${_seeded}'" load
    fi

    rm -rf "$_root" "$_live" "$_qroot"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "arrival" 0 "fail" 1
    fi
    emit_verdict "arrival" 0 "pass" 0
}

# --------------------------------------------------------------- verify-residue
# Does the loop say what it could NOT see before calling a direction arrived? `quiescent`
# renders as *this direction has arrived* — a reading that invites the operator to CLOSE the
# direction — and it was true of everything the citation walk could see and blind to everything
# it could not. Measured on this repository at 2026-08-28 00:41 UTC: the strategy
# `an-autonomous-improvement-loop-run-by-the-routines` read `quiescent: true` with 125 landed
# items while FOUR active missions and TEN queued tickets read `attributed: false`.
#
# NO NETWORK AND NO CREDENTIAL. The survey's one remote read is the open-proposal gate, and it
# is SUPPLIED through `--open-proposals` exactly as `verify-arrival` supplies it, so the drilled
# path is the real one. The fixture is git-backed for the same reason `verify-arrival`'s is:
# `landed[]` is a `git log --since` read, and a bare file tree would make every arrival row
# below vacuously true.
#
# THE BREAKER ROW IS `residue_reads_the_active_area`. It wires the reader at the ARCHIVED
# missions instead of the active ones, which is the one edit that would make this drill pass
# forever while reporting a residue nobody could act on — an archived mission is finished, so a
# residue drawn from it is never empty and never actionable.
cmd_verify_residue() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/unattributed-work.sh"
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _state="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-direction-health.sh"
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _carry="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/carry-attribution.sh"
    for _f in "$_reader" "$_survey" "$_state" "$_step" "$_ask" "$_carry"; do
        [ -f "$_f" ] || emit_err "residue_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _W="${_root}/.workaholic"
    mkdir -p "${_W}/strategies" "${_W}/feedbacks" "${_W}/missions/active" \
             "${_W}/missions/archive" "${_W}/tickets/todo" "${_W}/tickets/archive/work-x"
    printf -- '---\ntype: Feedback\n---\n\ncited by the direction\n' > "${_W}/feedbacks/20260101000000-a.md"
    printf -- '---\ntype: Feedback\n---\n\ncited by nobody\n'        > "${_W}/feedbacks/20260101000000-b.md"
    cat > "${_W}/strategies/dir1.md" <<EOF
---
type: Strategy
title: T dir1
slug: dir1
status: active
target_date: ${_far}
assignees: [${_me}]
feedback: [20260101000000-a.md]
---

# dir1

## Aim

a

## Schedule

s
EOF
    mkdir -p "${_W}/missions/archive/landed" "${_W}/missions/active/orphan"
    printf -- '---\ntype: Mission\ntitle: Landed\nslug: landed\nstatus: achieved\nfeedback: [20260101000000-a.md]\n---\n\n# Landed\n' \
        > "${_W}/missions/archive/landed/mission.md"
    printf -- '---\nmission: landed\nstatus: done\n---\n\n# T1\n' > "${_W}/tickets/archive/work-x/20260101000001-t1.md"
    printf -- '---\ntype: Mission\ntitle: Orphan\nslug: orphan\nstatus: active\nfeedback: [20260101000000-b.md]\n---\n\n# Orphan\n' \
        > "${_W}/missions/active/orphan/mission.md"
    # The breaker row's bait: an ARCHIVED mission nothing attributes. It is finished, so it must
    # never reach a residue an operator is asked to act on -- and it is the only fixture entry
    # that would appear if the reader were ever wired at the archive area.
    mkdir -p "${_W}/missions/archive/retired"
    printf -- '---\ntype: Mission\ntitle: Retired\nslug: retired\nstatus: abandoned\nfeedback: [20260101000000-b.md]\n---\n\n# Retired\n' \
        > "${_W}/missions/archive/retired/mission.md"
    printf -- '---\nmission: orphan\n---\n\n# T2\n' > "${_W}/tickets/todo/20260102000000-t2.md"
    printf -- '---\nmission: orphan\n---\n\n# T3\n' > "${_W}/tickets/todo/20260103000000-t3.md"
    _open="${_root}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    ( cd "$_root" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true

    # THE HONEST READ. The residue names the active mission nothing attributes, with its queued
    # count, and the loose queue rides that mission's row rather than being listed twice.
    _res=$(cd "$_root" && sh "$_reader" --root "$_W" 2>&1) || true
    if printf '%s' "$_res" | grep -q '"readable": *true' \
        && printf '%s' "$_res" | grep -q '"slug": *"orphan"' \
        && printf '%s' "$_res" | grep -q '"queued": *2' \
        && printf '%s' "$_res" | grep -q '"mission_count": *1'; then
        add_row "residue_honest_read" true "the residue names orphan with its two queued tickets" load
    else
        add_row "residue_honest_read" false "the residue did not name what no direction claims: $(one_line "$_res")" load
    fi

    # THE BREAKER ROW. Reading the ARCHIVED area instead of the active one is the edit that
    # would keep every other row here green while the residue named finished work nobody can act
    # on. `retired` is archived AND unattributed -- the exact entry that appears if the reader is
    # ever wired at the archive, and the only one in this fixture that would.
    if printf '%s' "$_res" | grep -q '"slug": *"retired"'; then
        add_row "residue_reads_the_active_area" false "an ARCHIVED mission reached the residue, so the reader is not reading the active area -- this drill can fail" load
    else
        add_row "residue_reads_the_active_area" true "only active missions reach the residue; the archived, unattributed one does not" load
    fi

    # THE DEGRADED READ, AND IT IS NOT AN EMPTY RESIDUE. The reader it composes is removed from
    # a COPY of the plugin tree, so the strategy itself stays perfectly legible and only the
    # residue is blind -- which is the only fixture that exercises the term rather than passing
    # on `unreadable`.
    _blindtree=$(mktemp -d)
    cp -r "${REPO_ROOT}/plugins" "${_blindtree}/plugins"
    rm -f "${_blindtree}/plugins/workaholic/skills/strategy/scripts/mission-strategy.sh"
    _bsurvey="${_blindtree}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _bstate="${_blindtree}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _bres=$(cd "$_root" && sh "${_blindtree}/plugins/workaholic/skills/strategy/scripts/unattributed-work.sh" --root "$_W" 2>&1) || true
    if printf '%s' "$_bres" | grep -q '"readable": *false' \
        && printf '%s' "$_bres" | grep -q '"reason": *"no_mission_strategy_script"' \
        && printf '%s' "$_bres" | grep -q '"mission_count": *null'; then
        add_row "residue_degraded_is_named" true "a residue we could not read is named with its reason and NULL counts, never zeroed ones" load
    else
        add_row "residue_degraded_is_named" false "a degraded residue read was not named: $(one_line "$_bres")" load
    fi

    # THE ARRIVAL, AND ITS REFUSAL. The same tree, read twice: with the residue readable the
    # direction reads `arrived`; with it blind, no arrival is claimed at all.
    _ok=$(cd "$_root" && sh "$_state" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    _bad=$(cd "$_root" && sh "$_bstate" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_ok" | grep -q '"state": *"arrived"'; then
        add_row "residue_nonempty_leaves_the_arrival" true "a residue read and found non-empty leaves the arrival standing -- only an UNREADABLE one refuses it" load
    else
        add_row "residue_nonempty_leaves_the_arrival" false "the arrival did not survive a non-empty residue: $(one_line "$_ok")" load
    fi
    if printf '%s' "$_bad" | grep -q '"state": *"arrived"'; then
        add_row "residue_blind_refuses_the_arrival" false "an arrival was claimed over a tree the loop could not see: $(one_line "$_bad")" load
    else
        add_row "residue_blind_refuses_the_arrival" true "no arrival is claimed over a residue we could not read" load
    fi

    # THE QUESTION NAMES THE RESIDUE BY SLUG. A count alone costs the operator the same
    # hand-read the defect costs them.
    _out=$(cd "$_root" && sh "$_step" --tick 20260101-000000 --root "$_root" --open-proposals "$_open" 2>&1) || true
    if printf '%s' "$_out" | grep -q 'not attributed to any direction: orphan (2 queued)' \
        && printf '%s' "$_out" | grep -q '"key": *"direction-arrived:dir1"'; then
        add_row "residue_named_in_the_question" true "the arrival question names orphan and its queued count" load
    else
        add_row "residue_named_in_the_question" false "the arrival question did not name the residue: $(one_line "$_out")" load
    fi

    # ASKED ONCE, over this reading's own key. The gate is the check-in's; the drill exercises
    # it with the key this step supplies.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _a1=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-000000 --key "direction-arrived:dir1" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000000 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-010000 --key "direction-arrived:dir1" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "residue_asked_once" true "the arrival question is asked once, whatever its body says" load
        else
            add_row "residue_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "residue_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi

    # THE RESIDUE MOVES NO GATE. The survey is read with the residue present and with the
    # unattributed mission REMOVED (never attributed -- attributing it would put this
    # direction's own work in flight and move `work_waiting` for an unrelated reason).
    _gates() { printf '%s' "$1" | sed -n 's/.*"selected": *\(\[[^]]*\]\).*/\1/p'; }
    _s1=$(cd "$_root" && sh "$_survey" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    _empty=$(mktemp -d); cp -r "${_W}" "${_empty}/.workaholic"
    rm -rf "${_empty}/.workaholic/missions/active/orphan" \
           "${_empty}/.workaholic/tickets/todo/20260102000000-t2.md" \
           "${_empty}/.workaholic/tickets/todo/20260103000000-t3.md"
    ( cd "$_empty" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true
    _s2=$(cd "$_empty" && sh "$_survey" --open-proposals "$_open" "14 days ago" "${_empty}/.workaholic" 2>&1) || true
    if [ -n "$(_gates "$_s1")" ] && [ "$(_gates "$_s1")" = "$(_gates "$_s2")" ]; then
        add_row "residue_moves_no_gate" true "emptying the residue leaves selected byte-identical: $(_gates "$_s1")" load
    else
        add_row "residue_moves_no_gate" false "the residue moved the selection: '$(_gates "$_s1")' vs '$(_gates "$_s2")'" load
    fi

    # THE ATTRIBUTION CARRY LANDS, IS IDEMPOTENT, AND REFUSES A CLOSED DIRECTION LEAVING THE
    # MISSION BYTE-IDENTICAL. This is the operator's ruling reaching the tree through the loop.
    _mfile="${_W}/missions/active/orphan/mission.md"
    _c1=$(cd "$_root" && sh "$_carry" dir1 orphan "$_W" 2>&1) || true
    if printf '%s' "$_c1" | grep -q '"carried": *true' \
        && grep -q '^feedback: \[20260101000000-b.md, 20260101000000-a.md\]$' "$_mfile"; then
        add_row "residue_carry_lands" true "the operator's ruling appends the direction's own refs and keeps the mission's" load
    else
        add_row "residue_carry_lands" false "the carry did not land: $(one_line "$_c1")" load
    fi
    _snap=$(cat "$_mfile")
    _c2=$(cd "$_root" && sh "$_carry" dir1 orphan "$_W" 2>&1) || true
    if printf '%s' "$_c2" | grep -q '"reason": *"already"' && [ "$_snap" = "$(cat "$_mfile")" ]; then
        add_row "residue_carry_is_idempotent" true "a re-run adds nothing and leaves the mission byte-identical" load
    else
        add_row "residue_carry_is_idempotent" false "the re-run was not a no-op: $(one_line "$_c2")" load
    fi
    printf -- 's/^status: active$/status: achieved/\n' > /dev/null
    sed 's/^status: active$/status: achieved/' "${_W}/strategies/dir1.md" > "${_root}/closed.md" \
        && mv "${_root}/closed.md" "${_W}/strategies/dir1.md"
    _c3=$(cd "$_root" && sh "$_carry" dir1 orphan "$_W" 2>&1) || true
    if printf '%s' "$_c3" | grep -q '"reason": *"not_active"' && [ "$_snap" = "$(cat "$_mfile")" ]; then
        add_row "residue_carry_refuses_a_closed_direction" true "a closed direction acquires no new work, and the refusal wrote nothing" load
    else
        add_row "residue_carry_refuses_a_closed_direction" false "the refusal was wrong or it wrote: $(one_line "$_c3")" load
    fi

    # IT WROTE NOTHING IN THE CHECKOUT. Every fixture is outside it.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "residue_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "residue_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_root" "$_blindtree" "$_qroot" "$_empty"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "residue" 0 "fail" 1
    fi
    emit_verdict "residue" 0 "pass" 0
}

# --------------------------------------------------------- verify-merged-claim
# Can the oracle tell a MERGED claim from a live one, at both grains? A squash merge leaves
# the content on the base and no commit on it, so `base..ref` stays positive forever and a
# finished unit is claimed forever — and until 2026-08-26 every MISSION claim was out of
# scope by construction. Measured here the same day: three of five claims headed pull
# requests #521, #537 and #546, all merged, all mission units, one offered `resumable: true`
# five days after its own pull request merged.
#
# FOUR READINGS, NO NETWORK AND NO CREDENTIAL. The batch grain is answered from the tree, so
# it needs nothing stubbed at all. The mission grain is answered by `claim-merged.sh`, the
# protocol's one network read, so the transport is stubbed on PATH — `merged` for the third
# row, and a refusing stub for the fourth, which is the reading the drill exists to keep
# honest: an answer we could not make must leave the row's verdict exactly where it was.
#
# THE FIXTURE IS A REAL SQUASH MERGE, not a simulated one. A normal merge takes `base..ref`
# to zero and `claims_scan` drops the branch before any verdict is reached, so the drill
# would pass while proving nothing.
cmd_verify_merged_claim() {
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _reader="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/claim-merged.sh"
    if [ ! -f "$_lister" ] || [ ! -f "$_reader" ]; then
        emit_err "merged_claim_unreadable" 4 "list-claims.sh or claim-merged.sh is not present in this checkout"
    fi

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" "${_work}/.workaholic/missions/active/drilled"
    printf -- '---\ntype: Mission\ntitle: D\nslug: drilled\nstatus: active\nassignees: [%s]\nclaim: work-20260101-000000\n---\n\n# D\n' "$_me" \
        > "${_work}/.workaholic/missions/active/drilled/mission.md"
    printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: work-20260101-000001\n---\n\n# T\n' "$_me" \
        > "${_work}/.workaholic/tickets/todo/20260101000001-t.md"
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    # Two claim branches, each ONE commit that both edits the artifact and carries the fixed
    # `Claim a PR-unit` subject with its `Unit:` trailer — the shape `claims_scan` actually
    # reads. The claim commit must TOUCH the stamped file, because the artifact list is
    # "files this commit touched that still carry the stamp at the tip".
    ( cd "$_work" && git checkout -q -b work-20260101-000000 main \
      && printf -- '---\ntype: Mission\ntitle: D\nslug: drilled\nstatus: active\nassignees: [%s]\nclaim: work-20260101-000000\n---\n\n# D\n\nclaimed\n' "$_me" \
        > .workaholic/missions/active/drilled/mission.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: drilled" \
      && git push -q origin work-20260101-000000 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q -b work-20260101-000001 main \
      && printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: work-20260101-000001\n---\n\n# T\n\nclaimed\n' "$_me" \
        > .workaholic/tickets/todo/20260101000001-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-20260101000001" \
      && git push -q origin work-20260101-000001 ) >/dev/null 2>&1 || true

    # The BATCH unit is driven and its ticket archived, then BOTH branches are squash-merged
    # so their content is on the base and their commits are not.
    ( cd "$_work" && git checkout -q work-20260101-000001 \
      && mkdir -p .workaholic/tickets/archive/work-20260101-000001 \
      && git mv .workaholic/tickets/todo/20260101000001-t.md .workaholic/tickets/archive/work-20260101-000001/ \
      && _git commit -qm "Archive the ticket" && git push -q origin work-20260101-000001 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q main \
      && git merge --squash -q work-20260101-000000 && _git commit -qm "Squash the mission claim" ) >/dev/null 2>&1 || true
    ( cd "$_work" && git merge --squash -q work-20260101-000001 && _git commit -qm "Squash the batch claim" \
      && git push -q origin main ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) || true

    _ahead=$( ( cd "$_read" && git rev-list --count origin/main..origin/work-20260101-000000 ) 2>/dev/null || echo 0 )
    if [ "${_ahead:-0}" -gt 0 ]; then
        add_row "merged_claim_fixture" true "the squash-merged claim branch is still ahead of the base, which is the shape under test" load
    else
        add_row "merged_claim_fixture" false "the fixture is not a squash merge (ahead=${_ahead}); the drill would prove nothing" load
        rm -rf "$_tmp"
        emit_verdict "merged-claim" 0 "fail" 1
    fi

    _stub() { printf '#!/bin/sh\n%s\n' "$1" > "${_bin}/gh"; chmod +x "${_bin}/gh"; }
    _verdict() { # unit
        printf '%s' "$_claims" | tr '{' '\n' | grep "\"unit\": \"$1\"" \
            | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1
    }
    _scan() { _claims=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_lister" ) 2>&1 || true ); }

    # 1 + 2. A MERGED BATCH CLAIM, answered from the tree with no transport at all — and a
    # LIVE claim beside it, which is what keeps this from being a blanket verdict.
    _stub "echo '[]'"
    _scan
    if [ "$(_verdict batch-20260101000001)" = "superseded" ]; then
        add_row "merged_claim_batch" true "a squash-merged batch claim reads superseded, with no network" load
    else
        add_row "merged_claim_batch" false "expected superseded for the batch grain, got '$(_verdict batch-20260101000001)': $(one_line "$_claims")" load
    fi
    _live=$(_verdict drilled)
    if [ -n "$_live" ] && [ "$_live" != "superseded" ]; then
        add_row "merged_claim_live" true "with no merged pull request the mission claim keeps its local verdict (${_live})" load
    else
        add_row "merged_claim_live" false "a claim with no merged pull request read '${_live:-nothing}': $(one_line "$_claims")" load
    fi

    # 3. A MERGED MISSION CLAIM — the reading this mission exists for, and the one no local
    # signal can reach: `mission.md` is never archived, so only the pull request answers.
    _stub "echo '[{\"number\":1,\"merged_at\":\"2026-08-26T00:00:00Z\"}]'"
    _scan
    if [ "$(_verdict drilled)" = "superseded" ]; then
        add_row "merged_claim_mission" true "a merged pull request makes a mission claim superseded" load
    else
        add_row "merged_claim_mission" false "expected superseded for the mission grain, got '$(_verdict drilled)': $(one_line "$_claims")" load
    fi

    # 4. AN UNANSWERABLE READ leaves the verdict exactly where it was and is NAMED. This is
    # the row that keeps the offline contract honest: a wrong `merged` releases work still in
    # flight, a wrong `in flight` only delays a claim.
    _stub "echo boom >&2; exit 1"
    _scan
    if [ "$(_verdict drilled)" = "$_live" ]; then
        add_row "merged_claim_unanswerable" true "a refused lookup leaves the mission claim on its local verdict (${_live})" load
    else
        add_row "merged_claim_unanswerable" false "a refused lookup changed the verdict to '$(_verdict drilled)': $(one_line "$_claims")" load
    fi
    if printf '%s' "$_claims" | grep -q '"branch": "work-20260101-000000", "reason": "transport_error"'; then
        add_row "merged_claim_named" true "and the claim it could not answer for is named, with its reason" load
    else
        add_row "merged_claim_named" false "the unanswered claim was not named: $(one_line "$_claims")" load
    fi

    # NO `gh` CALL REACHES A NETWORK, and the drill writes nothing into the checkout.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "merged_claim_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "merged_claim_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "merged-claim" 0 "fail" 1
    fi
    emit_verdict "merged-claim" 0 "pass" 0
}

# ------------------------------------------------------ verify-identity-handoff
# Does the loop still stamp an address it can drive? The link this drills runs across three
# components — the issue's assignee, the address `/specificate` stamps, and the survey that
# offers the unit — and it broke IN THE SEAM, not inside any one of them. Each component was
# internally consistent, nothing tested the walk, and the break was invisible for five days
# while every hourly tick reported a clean survey.
#
# THREE INPUTS, NO NETWORK AND NO CREDENTIAL. A canonical address, a mapped alias, and a
# login no entry names. The first two must reach the survey as the same person's work; the
# third must be team-owned, claimable by anyone, and stamped with no invented address.
#
# THE FAILURE DIRECTION IS DRILLED TOO. A test that only proves the happy path would have
# passed throughout the five stranded days, so the last row deliberately stamps an unmapped
# address and requires the survey to exclude it — proving the drill can fail.
cmd_verify_identity_handoff() {
    _identity="${REPO_ROOT}/plugins/workaholic/skills/gather/scripts/identity.sh"
    _draft="${REPO_ROOT}/plugins/workaholic/skills/specificate/scripts/scaffold-draft.sh"
    _ticket="${REPO_ROOT}/plugins/workaholic/skills/specificate/scripts/scaffold-proposed-ticket.sh"
    _plan="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/plan-units.sh"
    for _f in "$_identity" "$_draft" "$_ticket" "$_plan"; do
        [ -f "$_f" ] || emit_err "identity_handoff_unreadable" 4 "$(basename "$_f") is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _repo="${_tmp}/repo"
    mkdir -p "${_repo}/.claude" "${_repo}/.workaholic/feedbacks"
    _git() { git -c user.email=a@qmu.jp -c user.name=Drill -c commit.gpgsign=false "$@"; }
    ( cd "$_repo" && git -c init.defaultBranch=main init -q && git config user.email a@qmu.jp \
      && git config user.name Drill && git config commit.gpgsign false ) >/dev/null 2>&1 || true
    printf 'tamurayoshiya=a@qmu.jp,tamura.yoshiya@gmail.com\n' > "${_repo}/.claude/git-identities"
    printf -- '---\ntype: Feedback\nkind: instruction\nsource: slack\n---\n\n# Ask\n' \
        > "${_repo}/.workaholic/feedbacks/20260826000000-ask.md"
    ( cd "$_repo" && _git add -A && _git commit -qm seed ) >/dev/null 2>&1 || true

    # The run's own step: resolve the assignee, then pass ONLY what resolved.
    _stamp_for() {
        _ans=$( ( cd "$_repo" && sh "$_identity" "$1" ) 2>/dev/null || true )
        case "$_ans" in
            *'"resolved": true'*)
                printf -- '--assignee %s' "$(printf '%s' "$_ans" | sed -n 's/.*"canonical": "\([^"]*\)".*/\1/p')" ;;
            *) printf '' ;;
        esac
    }
    # A LOOSE ticket is what the survey offers as ordinary backlog. A mission needs an
    # acceptance plan before it is drivable (`no_plan`), and the plan is a human's
    # interrogation rather than anything this seam writes — so the mission half is drilled
    # for the address it STAMPS and the loose half for the address the survey ACTS on.
    _emit_mission() { # title, assignee-input -> mission.md path
        _flag=$(_stamp_for "$2")
        _m=$( ( cd "$_repo" && sh "$_draft" "$1" $_flag 20260826000000-ask.md ) 2>/dev/null || true )
        printf '%s' "$_m" | sed -n 's/.*"path": "\([^"]*\)".*/\1/p'
    }
    _emit() { # title, assignee-input -> ticket path
        _flag=$(_stamp_for "$2")
        _t=$( ( cd "$_repo" && sh "$_ticket" "$1 step" --loose --feedback 20260826000000-ask.md $_flag ) 2>/dev/null || true )
        printf '%s' "$_t" | sed -n 's/.*"path": "\([^"]*\)".*/\1/p'
    }
    _offered() { ( cd "$_repo" && sh "$_plan" ) 2>/dev/null | tr '{' '\n' | grep -c "\"path\": \"$1\"" || true; }
    _assignees() { sed -n 's/^assignees:[[:space:]]*//p' "${_repo}/$1" | head -1; }

    # 1. A CANONICAL address, and 2. A MAPPED ALIAS: both stamp the canonical address, and
    # both reach the survey as work this identity can drive.
    for _pair in 'canonical:a@qmu.jp' 'alias:tamura.yoshiya@gmail.com'; do
        _label=${_pair%%:*}; _input=${_pair#*:}
        _mpath=$(_emit_mission "Drill mission ${_label}" "$_input")
        if [ -n "$_mpath" ] && [ "$(_assignees "$_mpath")" = "[a@qmu.jp]" ]; then
            add_row "identity_handoff_${_label}_mission" true "the mission it emits carries the canonical address too" load
        else
            add_row "identity_handoff_${_label}_mission" false "the mission stamped '$(_assignees "$_mpath")'" load
        fi
        _path=$(_emit "Drill ${_label}" "$_input")
        if [ -n "$_path" ] && [ "$(_assignees "$_path")" = "[a@qmu.jp]" ]; then
            add_row "identity_handoff_${_label}_stamped" true "an issue assigned to the ${_label} stamps the canonical address" load
        else
            add_row "identity_handoff_${_label}_stamped" false "expected [a@qmu.jp], got '$(_assignees "$_path")'" load
        fi
        ( cd "$_repo" && _git add -A && _git commit -qm "emit ${_label}" ) >/dev/null 2>&1 || true
        if [ "$(_offered "$_path")" -gt 0 ]; then
            add_row "identity_handoff_${_label}_offered" true "and the survey offers it to that identity" load
        else
            add_row "identity_handoff_${_label}_offered" false "the survey did not offer the ${_label} unit; the link is broken in the seam" load
        fi
    done

    # 3. AN UNMAPPED login: team-owned, no invented address, and offered as claimable rather
    # than excluded — which is the whole reason the writer refuses to guess.
    _path=$(_emit "Drill unmapped" "stranger")
    ( cd "$_repo" && _git add -A && _git commit -qm "emit unmapped" ) >/dev/null 2>&1 || true
    case "$(_assignees "$_path")" in
        ''|'[]')
            add_row "identity_handoff_unmapped_team_owned" true "an unmapped login produces team-owned work, never a guessed address" load ;;
        *)
            add_row "identity_handoff_unmapped_team_owned" false "an unmapped login stamped '$(_assignees "$_path")'" load ;;
    esac
    if [ "$(_offered "$_path")" -gt 0 ]; then
        add_row "identity_handoff_unmapped_offered" true "and team-owned work is offered as claimable, not excluded" load
    else
        add_row "identity_handoff_unmapped_offered" false "team-owned work was not offered; it is stranded exactly as a wrong address would be" load
    fi

    # 4. THE FAILURE DIRECTION. Dropping the resolution — stamping the address straight off
    # the issue — must make the walk fail, or this drill is documentation.
    printf 'tamurayoshiya=a@qmu.jp\n' > "${_repo}/.claude/git-identities"
    _bad=$( ( cd "$_repo" && sh "$_ticket" "Drill unresolved" --loose --feedback 20260826000000-ask.md \
        --assignee tamura.yoshiya@gmail.com ) 2>/dev/null || true )
    _badpath=$(printf '%s' "$_bad" | sed -n 's/.*"path": "\([^"]*\)".*/\1/p')
    ( cd "$_repo" && _git add -A && _git commit -qm "emit unresolved" ) >/dev/null 2>&1 || true
    if [ "$(_offered "$_badpath")" -eq 0 ]; then
        add_row "identity_handoff_fails_when_dropped" true "an address the mapping does not name is excluded, so the drill can fail" load
    else
        add_row "identity_handoff_fails_when_dropped" false "an unmapped address was still offered; this drill cannot fail and proves nothing" load
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "identity_handoff_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "identity_handoff_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "identity-handoff" 0 "fail" 1
    fi
    emit_verdict "identity-handoff" 0 "pass" 0
}

# ---------------------------------------------------------------- verify-close
# Does a unit the loop FINISHES actually close? The closing seam is the one the loop cannot
# prove by running: a real refusal needs a real session class, and waiting for a tick to
# reproduce one is exactly what let four undelivered pull requests (#622, #625, #633, #635)
# accumulate unnoticed while every run reported `ok`.
#
# FOUR OUTCOMES, ONE FIXTURE, NO NETWORK. The seam's whole vocabulary is a pure function of a
# refusal string and a scan tier, so all four are reachable with the transport stubbed:
#
#   1. merged                     the REST merge succeeds; nothing is recorded and the claim
#                                 is released by the merge itself, so the oracle never sees it.
#   2. session-type, then retried `merge-reason.sh` answers `session_type_cannot_merge` -- the
#                                 ONE refusal `rules/shell.md` allows a connector retry for.
#   3. refused, unretryable       any other rung: no retry, the refusal is recorded, and the
#                                 claim reads `report_undelivered`.
#   4. scan-held                  a `hard`/`confirm` finding held the pull request; no merge
#                                 was attempted, the claim stays `queue_drained`, `ok` stands.
#
# AND ONE ROW THAT DELIBERATELY BREAKS THE SEAM, the property `verify-merged-claim` and
# `verify-identity-handoff` both carry: a drill that passes over a broken seam is worse than no
# drill, because it converts an unproven claim into a believed one.
cmd_verify_close() {
    _reason="${REPO_ROOT}/plugins/workaholic/skills/branching/scripts/merge-reason.sh"
    _gate="${REPO_ROOT}/plugins/workaholic/skills/release-scan/scripts/gate-decision.sh"
    _recorder="${REPO_ROOT}/plugins/workaholic/skills/story/scripts/record-merge-outcome.sh"
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh"
    for _f in "$_reason" "$_gate" "$_recorder" "$_lister" "$_step"; do
        [ -f "$_f" ] || emit_err "close_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    # ---- the vocabulary half: pure functions over a refusal string and a scan verdict ----
    _word() { sh "$_reason" "$1" 2>/dev/null || true; }

    # 2. THE ONE REFUSAL WITH A SECOND ATTEMPT. Keyed on the MESSAGE, with a bare 403 behind
    # it -- that one is a missing permission, which a different transport does not fix.
    if [ "$(_word 'HTTP 403: {"message":"Merging pull requests is not permitted for this session type"}')" \
        = "session_type_cannot_merge" ]; then
        add_row "close_retryable_refusal" true "the session-type refusal reaches the one rung a connector retry may answer" load
    else
        add_row "close_retryable_refusal" false "the session-type refusal did not reach its own rung" load
    fi

    # 3. EVERY OTHER RUNG IS UNRETRYABLE, and each is a different next action -- which is the
    # whole reason they are not one `merge_failed`.
    _unretryable_ok=true
    if [ "$(_word 'HTTP 405: Pull Request is not mergeable')" != "merge_not_allowed" ]; then _unretryable_ok=false; fi
    if [ "$(_word 'HTTP 409: Head branch was modified')" != "head_moved" ]; then _unretryable_ok=false; fi
    if [ "$(_word 'HTTP 403: Resource not accessible by integration')" != "merge_forbidden" ]; then _unretryable_ok=false; fi
    if [ "$(_word 'curl: (7) Failed to connect')" != "merge_failed" ]; then _unretryable_ok=false; fi
    if [ "$_unretryable_ok" = true ]; then
        add_row "close_unretryable_refusals" true "every other rung classifies to its own word and none reaches the retry" load
    else
        add_row "close_unretryable_refusals" false "a refusal rung did not classify to its own word" load
    fi

    # 4. THE SCAN-HELD ROW. `hard`/`confirm` holds the pull request and NO merge is attempted;
    # `override_only` is a granularity nudge and does not hold it.
    # THE ROUTE MERGES ON `pass` OR `override_only`, never on the binary verdict -- so that is
    # what this row reads. An `override`-tier finding still answers `decision: block`; what
    # makes it not hold the merge is `override_only: true`.
    _mergeable() {
        printf '%s' "$1" | sh "$_gate" 2>/dev/null \
            | sed -n 's/.*"decision": *"\([a-z_]*\)".*"override_only": *\([a-z]*\).*/\1 \2/p'
    }
    _held=$(_mergeable '{"verdict": "fail", "findings": [{"category": "secret", "severity": "hard"}]}')
    _nudge=$(_mergeable '{"verdict": "fail", "findings": [{"category": "size", "severity": "override"}]}')
    if [ "$_held" = "block false" ] && [ "$_nudge" = "block true" ]; then
        add_row "close_scan_held" true "a hard finding holds the merge while an override-tier one is a nudge the route merges through" load
    else
        add_row "close_scan_held" false "the tier reading did not separate a hard finding (${_held}) from an override one (${_nudge})" load
    fi

    # ---- the durable half: the outcome a run records, and what the oracle reads back ----
    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" "${_work}/.workaholic/stories"
    printf -- '---\ncreated_at: 2026-01-01T00:00:01+09:00\nauthor: %s\n---\n\n# T1\n' "$_me" \
        > "${_work}/.workaholic/tickets/todo/20260101000001-t.md"
    printf -- '---\ncreated_at: 2026-01-01T00:00:02+09:00\nauthor: %s\n---\n\n# T2\n' "$_me" \
        > "${_work}/.workaholic/tickets/todo/20260101000002-t.md"
    printf -- '---\ncreated_at: 2026-01-01T00:00:03+09:00\nauthor: %s\n---\n\n# T3\n' "$_me" \
        > "${_work}/.workaholic/tickets/todo/20260101000003-t.md"
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    # Three units driven to the SAME shape -- drained queue, story at the tip, pull request
    # open. That identity is the defect: `claimed_reported` covered all of them, so the loop's
    # own undelivered work and a unit waiting on a person were one word.
    _report() { # $1 = branch, $2 = ticket basename, $3 = outcome ("" records nothing)
        # `.workaholic/stories/` is recreated on every call: git tracks no empty directory,
        # so the seed commit carries none and checking out `main` for the next branch removes
        # the one the previous branch created.
        ( cd "$_work" \
          && mkdir -p ".workaholic/tickets/archive/$1" ".workaholic/stories" \
          && git mv ".workaholic/tickets/todo/$2" ".workaholic/tickets/archive/$1/" \
          && printf -- '---\ntype: Story\nbranch: %s\n---\n\n## 1. Overview\n\ndone\n' "$1" \
            > ".workaholic/stories/$1.md" \
          && { [ -z "$3" ] || sh "$_recorder" ".workaholic/stories/$1.md" "$3" >/dev/null; } \
          && _git add -A && _git commit -qm "Report the unit" \
          && git push -q origin "$1" ) >/dev/null 2>&1 || true
    }

    # A unit whose merge the TRANSPORT refused. The branch names are literal, as in every other
    # drill here: they are the canonical pattern the guard enforces.
    ( cd "$_work" && git checkout -q -B work-20260101-000000 main \
      && printf -- '---\ncreated_at: 2026-01-01T00:00:01+09:00\nauthor: %s\nclaim: work-20260101-000000\n---\n\n# T1\n\nclaimed\n' "$_me" \
        > .workaholic/tickets/todo/20260101000001-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-refused" ) >/dev/null 2>&1 || true
    _report work-20260101-000000 20260101000001-t.md "merge_refused: session_type_cannot_merge"

    # A unit a SCAN FINDING held -- the same shape, the opposite next action.
    ( cd "$_work" && git checkout -q -B work-20260102-000000 main \
      && printf -- '---\ncreated_at: 2026-01-01T00:00:02+09:00\nauthor: %s\nclaim: work-20260102-000000\n---\n\n# T2\n\nclaimed\n' "$_me" \
        > .workaholic/tickets/todo/20260101000002-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-held" ) >/dev/null 2>&1 || true
    _report work-20260102-000000 20260101000002-t.md "merge_not_attempted: hard"

    # THE DELIBERATELY BROKEN SEAM: the same finished shape with NOTHING recorded.
    ( cd "$_work" && git checkout -q -B work-20260103-000000 main \
      && printf -- '---\ncreated_at: 2026-01-01T00:00:03+09:00\nauthor: %s\nclaim: work-20260103-000000\n---\n\n# T3\n\nclaimed\n' "$_me" \
        > .workaholic/tickets/todo/20260101000003-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-silent" ) >/dev/null 2>&1 || true
    _report work-20260103-000000 20260101000003-t.md ""

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) || true
    printf '#!/bin/sh\necho "[]"\n' > "${_bin}/gh"; chmod +x "${_bin}/gh"
    _claims=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_lister" ) 2>&1 || true )
    _verdict() {
        printf '%s' "$_claims" | tr '{' '\n' | grep "\"unit\": \"$1\"" \
            | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1
    }

    # The fixture has to BE the shape under test, or every row below proves nothing.
    if [ -n "$(_verdict batch-refused)" ] && [ -n "$(_verdict batch-held)" ]; then
        add_row "close_fixture" true "three finished units are claimed, drained and reported -- the shape under test" load
    else
        add_row "close_fixture" false "the fixture did not produce reported claims (refused='$(_verdict batch-refused)' held='$(_verdict batch-held)' silent='$(_verdict batch-silent)')" load
        rm -rf "$_tmp"
        emit_verdict "close" 0 "fail" 1
    fi

    # 3 (durable). A REFUSED MERGE reads its own verdict, so the survey stops calling it a
    # human's business and the token stops covering it.
    if [ "$(_verdict batch-refused)" = "report_undelivered" ]; then
        add_row "close_refused_is_undelivered" true "a unit whose merge was refused reads report_undelivered, with no network" load
    else
        add_row "close_refused_is_undelivered" false "expected report_undelivered, got '$(_verdict batch-refused)': $(one_line "$_claims")" load
    fi

    # 4 (durable). A SCAN-HELD PULL REQUEST IS UNCHANGED -- it waits on a person by design, and
    # making it anything else puts `ok` out of reach on runs where every gate worked.
    if [ "$(_verdict batch-held)" = "queue_drained" ]; then
        add_row "close_held_is_unchanged" true "a scan-held pull request still reads queue_drained, exactly as before" load
    else
        add_row "close_held_is_unchanged" false "expected queue_drained, got '$(_verdict batch-held)': $(one_line "$_claims")" load
    fi

    # 1. THE MERGED OUTCOME, proved as an ABSENCE. A merged unit's branch is released by the
    # merge, so the oracle never sees it and nothing is recorded -- which is why this row asks
    # who the tick ASKS ABOUT rather than what a merged claim reads.
    _asked=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000000 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_asked" | grep -q '"unit": *"batch-refused"' \
        && ! printf '%s' "$_asked" | grep -q '"unit": *"batch-held"'; then
        add_row "close_asks_about_the_refused_one" true "the tick asks a person about the undelivered unit and about neither the scan-held nor the merged one" load
    else
        add_row "close_asks_about_the_refused_one" false "the question set was wrong: $(one_line "$_asked")" load
    fi

    # THE DELIBERATELY BROKEN ROW. A drill that only walks the happy path would have passed
    # throughout the days those four pull requests sat open. With the outcome NOT recorded the
    # oracle must fall back to `queue_drained` -- the silence this mission removed -- because
    # the new verdict is claimed only on positive evidence. Proving that the silence returns
    # when the record is missing is what proves this drill can fail.
    if [ "$(_verdict batch-silent)" = "queue_drained" ]; then
        add_row "close_unrecorded_stays_silent" true "an unrecorded outcome falls back to queue_drained, so the verdict is never asserted without evidence -- this drill can fail" load
    else
        add_row "close_unrecorded_stays_silent" false "an unrecorded outcome read '$(_verdict batch-silent)', so the verdict is being asserted without evidence" load
    fi

    # NO NETWORK, AND NOTHING WRITTEN INTO THE CHECKOUT.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "close_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "close_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "close" 0 "fail" 1
    fi
    emit_verdict "close" 0 "pass" 0
}

# --------------------------------------------------------------- verify-retire
# Does a claim the oracle PROVES empty actually leave the table? The retirement is destructive
# and outward-facing — a pull request closed, a branch deleted, a worktree reaped — so it is the
# last act that should be proved by waiting for a tick to perform one.
#
# NO NETWORK. The fixture is a local bare origin and `gh` is stubbed on PATH, so every act is
# real against the fixture and none of them leaves the machine. A `superseded` batch claim is
# reachable offline by construction (its tickets are archived on the base), which is what makes
# the whole drill local. The branch names are literal, as in every other drill here: they are
# the canonical pattern the guard enforces.
#
# WHAT IT PROVES:
#   1. the proof is acted on           a superseded claim's pull request, branch and worktree
#   2. a judgement is refused BY NAME  `not_superseded:<verdict>` carries the verdict's own word
#   3. two live claims are refused     `ambiguous_claim`, never picked between
#   4. it is idempotent                a second run reports success and changes nothing
#   5. the step asks nobody anything   `needs_agent` is empty; a retirement is not a question
#
# AND ONE ROW THAT DELIBERATELY BREAKS THE SEAM: a LIVE claim handed to the writer. If the gate
# were widened to any claim, that row would be retired and this drill would pass while the loop
# tore down work another run was driving. Proving the refusal is what proves the drill can fail.
cmd_verify_retire() {
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _retirer="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/retire-claim.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh"
    for _f in "$_lister" "$_retirer" "$_step"; do
        [ -f "$_f" ] || emit_err "retire_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo"
    for _n in 1 2 3 4 5 6 7 8 9; do
        printf -- '---\ncreated_at: 2026-01-01T00:00:0%s+09:00\nauthor: %s\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_n" > "${_work}/.workaholic/tickets/todo/2026010100000${_n}-t.md"
    done
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    # THE BLOCKED-DELETE SEAM. Act 2 is refused on every tick in the container the loop actually
    # runs in (measured 2026-08-27: both `git push --delete` and the REST ref-delete answer 403),
    # and until now the drill covered only the happy path -- a behaviour nothing drills is a
    # behaviour the next change can lose. A bare repository's own `update` hook reproduces the
    # refusal exactly where the real one happens, server side, with no network: git runs
    # receive-pack locally over the file transport, so this is the same code path a remote
    # refusal takes. It is scoped to ONE ref on purpose, so a retirable claim can be retired in
    # the same tick and the narrowing below is provable rather than asserted.
    printf '#!/bin/sh\nif [ "$1" = "refs/heads/work-20260101-000006" ] && [ "$3" = "0000000000000000000000000000000000000000" ]; then\n  echo "deleting this branch is not permitted" >&2\n  exit 1\nfi\nexit 0\n' > "${_origin}/hooks/update"
    chmod +x "${_origin}/hooks/update"

    # The claim commit must TOUCH the stamped file: the artifact list is "files this commit
    # touched that still carry the stamp at the tip".
    _stamp() { # $1 = branch, $2 = ticket basename
        printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: %s\n---\n\n# T\n\nclaimed\n' \
            "$_me" "$1" > "${_work}/.workaholic/tickets/todo/$2"
    }

    # THE PROOF: a claim whose ticket is archived on the BASE. Its content reached the base by
    # another route, so the branch can never land -- which is exactly `superseded`. Two of them,
    # because a retirement REMOVES its claim: the second row below cannot be proved on a unit
    # the first row already retired.
    ( cd "$_work" && git checkout -q -b work-20260101-000000 main \
      && _stamp work-20260101-000000 20260101000001-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-superseded" \
      && git push -q origin work-20260101-000000 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q -b work-20260101-000004 main \
      && _stamp work-20260101-000004 20260101000005-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-superseded-two" \
      && git push -q origin work-20260101-000004 ) >/dev/null 2>&1 || true
    # A THIRD, reserved for the STEP. The step retires every superseded row it finds, so the
    # rows that drive the writer directly must not be the same claims -- and the event assertion
    # needs one superseded claim still standing when the step runs.
    ( cd "$_work" && git checkout -q -b work-20260101-000005 main \
      && _stamp work-20260101-000005 20260101000006-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-superseded-three" \
      && git push -q origin work-20260101-000005 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q main \
      && mkdir -p .workaholic/tickets/archive/work-20260101-000000 \
      && git mv .workaholic/tickets/todo/20260101000001-t.md .workaholic/tickets/archive/work-20260101-000000/ \
      && git mv .workaholic/tickets/todo/20260101000005-t.md .workaholic/tickets/archive/work-20260101-000000/ \
      && git mv .workaholic/tickets/todo/20260101000006-t.md .workaholic/tickets/archive/work-20260101-000000/ \
      && _git commit -qm "Archive the tickets elsewhere" && git push -q origin main ) >/dev/null 2>&1 || true

    # A JUDGEMENT beside it: a live claim whose ticket is still queued.
    ( cd "$_work" && git checkout -q -b work-20260101-000001 main \
      && _stamp work-20260101-000001 20260101000002-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-live" \
      && git push -q origin work-20260101-000001 ) >/dev/null 2>&1 || true

    # TWO LIVE CLAIMS on one unit -- the state the protocol cannot produce and must refuse.
    ( cd "$_work" && git checkout -q -b work-20260101-000002 main \
      && _stamp work-20260101-000002 20260101000003-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-ambiguous" \
      && git push -q origin work-20260101-000002 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q -b work-20260101-000003 main \
      && _stamp work-20260101-000003 20260101000004-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-ambiguous" \
      && git push -q origin work-20260101-000003 ) >/dev/null 2>&1 || true

    # THE BLOCKED-DELETE TRIO, pushed now and made superseded LATER (their tickets stay queued
    # until the blocked phase below). Held back deliberately: the step retires every superseded
    # row it finds, so a claim that reads superseded during the rows above would be retired by
    # them and there would be nothing left to block. All three are superseded in the same tick,
    # and each ends in a DIFFERENT outcome, which is what makes the narrowing provable:
    #
    #   -000006  batch-blocked    the `update` hook refuses its delete   → refused ON THE DELETE
    #   -000007  batch-retirable  everything succeeds                    → retired
    #   -000008  batch-closefail  the stub refuses its pull-request close → refused, NOT on the
    #                                                                       delete
    #
    # The third exists only so the breaker row has something to catch: `batch-retirable` alone
    # would prove the candidate set is not *every superseded row*, and `batch-closefail` proves
    # it is not *every refusal* either. Without it a widening to any refusal passes unnoticed
    # (measured while writing this drill — the row passed against a deliberately broken seam).
    ( cd "$_work" && git checkout -q -b work-20260101-000006 main \
      && _stamp work-20260101-000006 20260101000007-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-blocked" \
      && git push -q origin work-20260101-000006 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q -b work-20260101-000007 main \
      && _stamp work-20260101-000007 20260101000008-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-retirable" \
      && git push -q origin work-20260101-000007 ) >/dev/null 2>&1 || true
    ( cd "$_work" && git checkout -q -b work-20260101-000008 main \
      && _stamp work-20260101-000008 20260101000009-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-closefail" \
      && git push -q origin work-20260101-000008 ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) || true
    # The stub answers `gh api user` (so `available` reads true) and every pulls query with
    # whatever this drill wants that unit's pull request to be. An empty list is a fixture whose
    # unit has no pull request, which the writer reports as the SUCCESS `none`.
    _stub() { printf '#!/bin/sh\n%s\n' "$1" > "${_bin}/gh"; chmod +x "${_bin}/gh"; }
    _stub "echo '[]'"
    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "retire_no_network" true "the stub is what gh resolves to, and the origin is a local bare repository -- no row below reaches the network" load
    else
        add_row "retire_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "retire" 0 "fail" 1
    fi

    _retire() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_retirer" "$1" ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n 's/.*"'"$2"'": *"\([^"]*\)".*/\1/p' | head -1; }

    _claims=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_lister" ) 2>&1 || true )
    _verdict() { printf '%s' "$_claims" | tr '{' '\n' | grep "\"unit\": \"$1\"" \
        | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1; }
    _live_verdict=$(_verdict batch-live)

    # The fixture has to BE the shape under test, or every row below proves nothing.
    if [ "$(_verdict batch-superseded)" = "superseded" ] && [ -n "$_live_verdict" ] \
        && [ "$_live_verdict" != "superseded" ]; then
        add_row "retire_fixture" true "one claim reads superseded and a live one sits beside it -- the shape under test" load
    else
        add_row "retire_fixture" false "the fixture is wrong (superseded='$(_verdict batch-superseded)' live='${_live_verdict}'): $(one_line "$_claims")" load
        rm -rf "$_tmp"
        emit_verdict "retire" 0 "fail" 1
    fi

    # 1. THE PROOF IS ACTED ON. All three acts run and each reports its own word: no pull
    # request to close (`none`), the remote branch deleted, no worktree here (`absent`).
    _out=$(_retire batch-superseded)
    if printf '%s' "$_out" | grep -q '"retired": true' \
        && [ "$(_field "$_out" remote_branch_deleted)" = "deleted" ] \
        && [ "$(_field "$_out" pull_request_closed)" = "none" ]; then
        add_row "retire_acts_on_the_proof" true "the superseded claim's branch is deleted and its three acts are each named" load
    else
        add_row "retire_acts_on_the_proof" false "the retirement did not complete: $(one_line "$_out")" load
    fi

    # 4a. NOTHING IS RETIRED TWICE. A completed retirement DELETES the branch, and the claim
    # oracle is the set of unmerged remote branches -- so the row is simply gone and a second
    # run has nothing to act on. `no_such_claim` with all three acts `not_attempted` is the
    # honest answer, and it is the property that matters: re-running is safe and changes
    # nothing. (The drill asserted `already_gone` here first and the fixture disproved it --
    # that word is reachable only on a PARTIAL retirement, which 4b covers.)
    _again=$(_retire batch-superseded)
    if [ "$(_field "$_again" reason)" = "no_such_claim" ] \
        && [ "$(_field "$_again" remote_branch_deleted)" = "not_attempted" ]; then
        add_row "retire_not_twice" true "a completed retirement leaves no claim, so a second run attempts nothing -- re-running is safe" load
    else
        add_row "retire_not_twice" false "the second run did not leave the claim retired-and-gone: $(one_line "$_again")" load
    fi

    # 4b. AN ALREADY-CLOSED PULL REQUEST IS A SUCCESS, not a degradation. This is the
    # idempotence that has to hold in practice: a partial retirement (measured 2026-08-05, a
    # cloud container may PUSH but not DELETE a branch) leaves the claim standing, and the next
    # tick must finish the job rather than trip over the act that already succeeded.
    _stub "echo '[{\"number\":7,\"state\":\"closed\"}]'"
    _closed=$(_retire batch-superseded-two)
    if printf '%s' "$_closed" | grep -q '"retired": true' \
        && [ "$(_field "$_closed" pull_request_closed)" = "already_closed" ]; then
        add_row "retire_already_closed_is_success" true "an already-closed pull request reports already_closed and the retirement still succeeds" load
    else
        add_row "retire_already_closed_is_success" false "an already-closed pull request was not treated as a success: $(one_line "$_closed")" load
    fi
    _stub "echo '[]'"

    # 3. TWO LIVE CLAIMS ARE REFUSED, never picked between: the protocol settles a race by the
    # push, so this state cannot arise from the sanctioned path, and choosing silently is how a
    # runner tears down work another run is still driving.
    _amb=$(_retire batch-ambiguous)
    if [ "$(_field "$_amb" reason)" = "ambiguous_claim" ] \
        && [ "$(_field "$_amb" remote_branch_deleted)" = "not_attempted" ]; then
        add_row "retire_ambiguous_refused" true "a unit held by two live claims is refused ambiguous_claim with nothing attempted" load
    else
        add_row "retire_ambiguous_refused" false "expected ambiguous_claim with nothing attempted, got: $(one_line "$_amb")" load
    fi

    # 5. THE STEP ASKS NOBODY ANYTHING ABOUT A RETIREMENT THAT SUCCEEDED. The claim is proved
    # empty and the acts all ran, so there is no judgement for a person to make -- the sharpest
    # contrast with the three steps beside it. The rule is narrowed rather than reversed by the
    # blocked rows below, and row 12 is the guard on that narrowing.
    _stepout=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000000 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_stepout" | grep -q '"needs_agent": \[\]'; then
        add_row "retire_step_asks_nothing" true "the step carries an empty needs_agent -- it acts and reports, it never asks" load
    else
        add_row "retire_step_asks_nothing" false "the step produced a question: $(one_line "$_stepout")" load
    fi

    # 6. A RETIREMENT IS A REPOSITORY EVENT, so the root gets a line naming what was retired.
    # The run above still had `batch-superseded-three` standing, which is why the third
    # superseded claim exists.
    if printf '%s' "$_stepout" | grep -q '"event": "[^"]' \
        && printf '%s' "$_stepout" | grep -q 'retired'; then
        add_row "retire_step_renders_an_event" true "a tick that retired a claim supplies an event naming what it retired" load
    else
        add_row "retire_step_renders_an_event" false "a tick that retired a claim supplied no event: $(one_line "$_stepout")" load
    fi

    # 7. AND A TICK THAT RETIRED NOTHING SUPPLIES NO EVENT AT ALL, so the renderer emits no
    # line. This is the half that is easy to leave unasserted and is exactly the failure the
    # 2026-08-23 rule exists against: `no new documentation drift` announced that NOTHING
    # HAPPENED while the diff rendered it as a change. Every superseded claim is retired by
    # now, so this run is the nothing-happened case.
    _idle=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000001 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_idle" | grep -q '"event": ""' \
        && printf '%s' "$_idle" | grep -q '"status": "ok"'; then
        add_row "retire_idle_renders_no_line" true "a tick that retired nothing supplies no event, so the root renders no line" load
    else
        add_row "retire_idle_renders_no_line" false "a tick that retired nothing still supplied an event: $(one_line "$_idle")" load
    fi

    # THE DELIBERATELY BROKEN ROW. A LIVE claim handed straight to the writer. If the gate were
    # widened to any claim -- or read a judgement as a proof -- this row would retire a branch
    # another run is driving, and the drill would pass while the loop destroyed work. The
    # refusal must carry the verdict's OWN word, so a reader is told which judgement it was.
    _live_out=$(_retire batch-live)
    if [ "$(_field "$_live_out" reason)" = "not_superseded:${_live_verdict}" ] \
        && [ "$(_field "$_live_out" remote_branch_deleted)" = "not_attempted" ]; then
        add_row "retire_refuses_a_judgement" true "a live claim is refused by its own verdict word with nothing attempted -- this drill can fail" load
    else
        add_row "retire_refuses_a_judgement" false "a live claim was not refused by name: $(one_line "$_live_out")" load
    fi

    # ------------------------------------------------------------------------------------
    # THE BLOCKED RETIREMENT — the case that has been true in production on every tick since
    # the mechanism landed: the delete refused, the other two acts standing. Everything below
    # runs over the same fixture with no network; the refusal comes from the origin's own
    # `update` hook installed at the top of this drill.
    # ------------------------------------------------------------------------------------
    # The two held-back claims become superseded now: their tickets are archived on the base,
    # which is what `superseded` means.
    ( cd "$_work" && git checkout -q main \
      && git mv .workaholic/tickets/todo/20260101000007-t.md .workaholic/tickets/archive/work-20260101-000000/ \
      && git mv .workaholic/tickets/todo/20260101000008-t.md .workaholic/tickets/archive/work-20260101-000000/ \
      && git mv .workaholic/tickets/todo/20260101000009-t.md .workaholic/tickets/archive/work-20260101-000000/ \
      && _git commit -qm "Archive the blocked trio elsewhere" && git push -q origin main ) >/dev/null 2>&1 || true

    # An OPEN pull request on each, so Act 1 has something to close and "the acts that stand" is
    # a real fact rather than a vacuous one -- except on `batch-closefail`, whose PATCH the stub
    # refuses, giving a superseded unit refused on an act that is NOT the delete.
    _blocked_stub() { # $1 = the state the default pull request is in
        _stub "case \"\$*\" in
  *pulls/11*) exit 1 ;;
  *work-20260101-000008*) echo '[{\"number\":11,\"state\":\"open\"}]' ;;
  *) echo '[{\"number\":9,\"state\":\"$1\"}]' ;;
esac"
    }
    _blocked_stub open

    _bclaims=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_lister" ) 2>&1 || true )
    _bverdict() { printf '%s' "$_bclaims" | tr '{' '\n' | grep "\"unit\": \"$1\"" \
        | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1; }
    if [ "$(_bverdict batch-blocked)" = "superseded" ] \
        && [ "$(_bverdict batch-retirable)" = "superseded" ] \
        && [ "$(_bverdict batch-closefail)" = "superseded" ]; then
        add_row "retire_blocked_fixture" true "all three held-back claims now read superseded, and the origin refuses to delete one of the three branches -- the production shape" load
    else
        add_row "retire_blocked_fixture" false "the blocked fixture is wrong (blocked='$(_bverdict batch-blocked)' retirable='$(_bverdict batch-retirable)' closefail='$(_bverdict batch-closefail)'): $(one_line "$_bclaims")" load
        rm -rf "$_tmp"
        emit_verdict "retire" 0 "fail" 1
    fi

    # 8. THE NAMED WORD, NOT A GENERIC REFUSAL. `partial_retirement` collapsed a refused close,
    # a refused delete and a dirty worktree into one string; the reader must learn WHICH act is
    # blocked. The two acts that stand are on the same row.
    _blk=$(_retire batch-blocked)
    if [ "$(_field "$_blk" reason)" = "branch_delete_failed" ] \
        && [ "$(_field "$_blk" remote_branch_deleted)" = "failed" ] \
        && [ "$(_field "$_blk" pull_request_closed)" = "closed" ] \
        && [ "$(_field "$_blk" worktree_reaped)" = "absent" ]; then
        add_row "retire_blocked_names_the_act" true "a refused delete reports branch_delete_failed with the pull-request close and the worktree standing beside it" load
    else
        add_row "retire_blocked_names_the_act" false "the refused delete did not name its own act: $(one_line "$_blk")" load
    fi

    # 9. NOTHING ALREADY DONE IS UNDONE, and a re-run takes only the one remaining act. The
    # stub now answers `closed`, which is the world after the first run's Act 1.
    _blocked_stub closed
    _blk2=$(_retire batch-blocked)
    _still=$( ( cd "$_origin" && git for-each-ref --format='%(refname:short)' refs/heads ) \
        | grep -c '^work-20260101-000006$' || true )
    if [ "$(_field "$_blk2" pull_request_closed)" = "already_closed" ] \
        && [ "$(_field "$_blk2" reason)" = "branch_delete_failed" ] \
        && [ "$_still" = "1" ] && [ "$(_bverdict batch-blocked)" = "superseded" ]; then
        add_row "retire_blocked_undoes_nothing" true "a re-run leaves the pull request closed, re-attempts only the delete, and the branch and its superseded verdict both stand" load
    else
        add_row "retire_blocked_undoes_nothing" false "the re-run did not resume from what already stood (branch_present='${_still}'): $(one_line "$_blk2")" load
    fi

    # 10. THE CALLER REPORTS WHAT STANDS AND WHAT IS BLOCKED. A refused row rendered only its
    # reason until now, so a re-run of one act read as a re-run of three. This tick also retires
    # `batch-retirable`, which is what makes row 12 a real test rather than a vacuous one.
    _bstep=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000002 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_bstep" | grep -q 'batch-blocked refused (branch_delete_failed; pr already_closed, branch failed, worktree absent)'; then
        add_row "retire_blocked_reports_what_stands" true "the refused row names the acts that stand beside the act that is blocked" load
    else
        add_row "retire_blocked_reports_what_stands" false "the refused row dropped the acts that stand: $(one_line "$_bstep")" load
    fi

    # 11. THE BLOCKED UNIT REACHES ITS CLAIM HOLDER, keyed once and naming the exact branch --
    # a question that does not name the branch does not say what to delete.
    if printf '%s' "$_bstep" | grep -q '"key":"retire-blocked:batch-blocked"' \
        && printf '%s' "$_bstep" | grep -q '"branch":"work-20260101-000006"' \
        && printf '%s' "$_bstep" | grep -q "\"owner\":\"${_me}\"" \
        && printf '%s' "$_bstep" | grep -q '"refusal":"branch_delete_failed"'; then
        add_row "retire_blocked_asks_the_holder" true "one question, keyed retire-blocked:batch-blocked, addressed to the claim holder, naming the branch and the refusal" load
    else
        add_row "retire_blocked_asks_the_holder" false "the blocked unit reached nobody: $(one_line "$_bstep")" load
    fi

    # 12. THE DELIBERATELY BROKEN ROW, and it catches BOTH widenings. In this one tick,
    # `batch-retirable` was retired and `batch-closefail` was refused on an act that is not the
    # delete. If `needs_agent` were widened to every superseded row, the first would draw a
    # question; if it were widened to every refusal, the second would. Either way this row
    # fails, which is what proves the drill can. It is the guard on the rule being NARROWED
    # rather than reversed, and the two-outcome fixture is deliberate: an earlier version of
    # this row carried only `batch-retirable` and passed against a seam broken to *any refusal*.
    if printf '%s' "$_bstep" | grep -q 'retire-blocked:batch-retirable'; then
        add_row "retire_blocked_only_the_blocked" false "a unit whose retirement SUCCEEDED still drew a question -- the candidate set was widened to every superseded row" load
    elif printf '%s' "$_bstep" | grep -q 'retire-blocked:batch-closefail'; then
        add_row "retire_blocked_only_the_blocked" false "a unit refused on the pull-request CLOSE still drew a question -- the candidate set was widened to every refusal" load
    else
        add_row "retire_blocked_only_the_blocked" true "neither a retirement that succeeded nor one refused on another act asks anybody anything; only the blocked delete does (this drill can fail)" load
    fi

    # 13. A STANDING BLOCK IS NOT AN HOURLY CHANGE. Two consecutive ticks over an unchanged
    # blocked set must render an identical summary -- the root calls a step changed when its
    # summary moves, and a status restated hourly is read by nobody by the second day. Both
    # ticks run after `batch-retirable` is gone, so the set really is unchanged.
    _t3=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000003 --root "$_read" ) 2>&1 || true )
    _t4=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000004 --root "$_read" ) 2>&1 || true )
    _s3=$(printf '%s' "$_t3" | sed -n 's/.*"summary": *"\([^"]*\)".*/\1/p')
    _s4=$(printf '%s' "$_t4" | sed -n 's/.*"summary": *"\([^"]*\)".*/\1/p')
    if [ -n "$_s3" ] && [ "$_s3" = "$_s4" ] && printf '%s' "$_t4" | grep -q '"event": ""'; then
        add_row "retire_blocked_summary_stable" true "two ticks over an unchanged blocked set render an identical summary and no root line" load
    else
        add_row "retire_blocked_summary_stable" false "a held block moved the summary or produced an event (t3='${_s3}' t4='${_s4}')" load
    fi

    # 14. ASKED ONCE. The gate is the check-in's, not this step's, so the drill exercises the
    # gate with this step's key: the first ask is allowed, the second is refused by name.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _askscript="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _b1=$(cd "$REPO_ROOT" && sh "$_askscript" --tick 20260101-000002 --key "retire-blocked:batch-blocked" \
        --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _blogstep=$(printf '%s' "$_b1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_b1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000002 --step "$_blogstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _b2=$(cd "$REPO_ROOT" && sh "$_askscript" --tick 20260101-000003 --key "retire-blocked:batch-blocked" \
            --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_b2" | grep -q '"ask": false'; then
            add_row "retire_blocked_asked_once" true "the same key is refused on a later tick: $(printf '%s' "$_b2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "retire_blocked_asked_once" false "the asked-once gate did not hold: $(one_line "$_b2")" load
        fi
    else
        add_row "retire_blocked_asked_once" false "the first ask was refused: $(one_line "$_b1")" load
    fi
    rm -rf "$_qroot"

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "retire_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "retire_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "retire" 0 "fail" 1
    fi
    emit_verdict "retire" 0 "pass" 0
}

# --------------------------------------------------------- verify-base-health
# Did the base survive what the loop merged -- and does that reading stay a READING? The loop
# merges its own work onto `main` every half hour and nothing read a check run, so a green base
# and a base nobody looked at were one reading.
#
# NO NETWORK: a local bare origin and a `gh` stub on PATH that answers out of a fixture
# directory. The drill ASSERTS the stub is what `gh` resolves to rather than assuming it.
#
# WHAT IT PROVES:
#   1. the reader's three states       green, red with the failing check names, and every
#                                      `unanswerable` reason -- including a commit with NO
#                                      checks at all, which must never read as green
#   2. the walk's two outcomes         a red tip attributed to a mid-walk merge with its pull
#                                      request and author, and the `unattributable` tail
#   3. the asked-once gate             two ticks over one red commit, one question, keyed
#                                      `base-red:<commit>`; a degraded read asks nothing
#   4. the reading gates NOTHING       the survey the terminal token is derived from is
#                                      byte-identical over a red base and a green one, and no
#                                      script in the driving chain reaches either reader
#
# AND ONE ROW THAT DELIBERATELY BREAKS THE SEAM: the reader is handed a commit the fixture gives
# no checks for -- the single most tempting wrong answer, since an empty check list looks like
# "nothing failed". If it ever answers `green`, `base_health_can_fail` goes red. That row is the
# INTENTIONAL one: an operator reading a red drill should look at it first.
cmd_verify_base_health() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/read-base-checks.sh"
    _walk="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/attribute-base-red.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-base-health.sh"
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _plan="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/plan-units.sh"
    for _f in "$_reader" "$_walk" "$_step" "$_ask" "$_plan"; do
        [ -f "$_f" ] || emit_err "base_health_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"
    _bin="${_tmp}/bin"; _st="${_tmp}/stubs"
    mkdir -p "$_origin" "$_bin" "$_st"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo"
    printf -- '---\ncreated_at: 2026-01-01T00:00:01+09:00\nauthor: %s\n---\n\n# T\n' "$_me" \
        > "${_work}/.workaholic/tickets/todo/20260101000001-t.md"
    ( cd "$_work" && _git add -A && _git commit -qm seed ) >/dev/null 2>&1 || true
    for _n in 2 3 4 5; do
        ( cd "$_work" && _git commit -q --allow-empty -m "merge ${_n}" ) >/dev/null 2>&1 || true
    done
    ( cd "$_work" && git push -q origin main ) >/dev/null 2>&1 || true
    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) || true

    # Newest first, exactly the order the walk visits them in.
    _shas=$(cd "$_read" && git rev-list origin/main)
    _tip=$(printf '%s\n' "$_shas" | sed -n 1p)
    _c4=$(printf '%s\n' "$_shas" | sed -n 2p)
    _c3=$(printf '%s\n' "$_shas" | sed -n 3p)
    _c2=$(printf '%s\n' "$_shas" | sed -n 4p)
    _c1=$(printf '%s\n' "$_shas" | sed -n 5p)

    # The stub answers per commit out of a fixture directory, so a case is set by writing files
    # rather than by branching inside the stub. A sha with no fixture answers an EMPTY check
    # list -- which is the deliberately broken seam's input.
    printf '#!/bin/sh\ncase "$2" in\n  */check-runs*) _s=$(echo "$2" | sed "s|.*/commits/||; s|/check-runs.*||")\n     if [ -f "%s/$_s.json" ]; then cat "%s/$_s.json"; else echo %s; fi ;;\n  */pulls*) cat "%s/pulls" 2>/dev/null || { echo "no pulls" >&2; exit 1; } ;;\n  user) printf "tester\\n" ;;\n  *) echo "unexpected $2" >&2; exit 1 ;;\nesac\n' \
        "$_st" "$_st" "'{\"total_count\":0,\"check_runs\":[]}'" "$_st" > "${_bin}/gh"
    chmod +x "${_bin}/gh"
    printf '[{"number":42,"merged_at":"2026-01-02T00:00:00Z","html_url":"https://example.invalid/pull/42","user":{"login":"tester"}}]\n' \
        > "${_st}/pulls"

    _GREEN='{"total_count":1,"check_runs":[{"name":"CI","status":"completed","conclusion":"success"}]}'
    _RED='{"total_count":2,"check_runs":[{"name":"Validate Plugins","status":"completed","conclusion":"failure"},{"name":"CI","status":"completed","conclusion":"success"}]}'
    _PENDING='{"total_count":1,"check_runs":[{"name":"CI","status":"in_progress","conclusion":null}]}'
    _set() { printf '%s\n' "$2" > "${_st}/$1.json"; }
    _clear() { rm -f "${_st}/$1.json"; }

    _run() { ( cd "$_read" && PATH="${_bin}:$PATH" "$@" ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n 's/.*"'"$2"'": *"\([^"]*\)".*/\1/p' | head -1; }
    _read_at() { _run sh "$_reader" "$1"; }

    # 0. THE TRANSPORT IS THE STUB. Asserted rather than assumed: a drill that silently reached
    # the network would prove nothing about the offline contract it claims to check.
    _which=$( ( cd "$_read" && PATH="${_bin}:$PATH" command -v gh ) 2>/dev/null || true )
    if [ "$_which" = "${_bin}/gh" ]; then
        add_row "base_health_offline" true "gh resolves to the drill's stub, so no network call is made" load
    else
        add_row "base_health_offline" false "gh resolved to '${_which}', not the drill's stub" load
    fi

    # 1. THE READER'S THREE STATES.
    _set "$_tip" "$_GREEN"
    _g=$(_read_at "$_tip")
    if [ "$(_field "$_g" state)" = "green" ]; then
        add_row "base_health_reads_green" true "every completed check passing reads green" load
    else
        add_row "base_health_reads_green" false "a passing commit did not read green: $(one_line "$_g")" load
    fi

    _set "$_tip" "$_RED"
    _r=$(_read_at "$_tip")
    if [ "$(_field "$_r" state)" = "red" ] \
        && printf '%s' "$_r" | grep -q '"name":"Validate Plugins"'; then
        add_row "base_health_reads_red_with_names" true "a failing check reads red and the failing check is named" load
    else
        add_row "base_health_reads_red_with_names" false "a failing commit did not read red-with-names: $(one_line "$_r")" load
    fi

    _set "$_tip" "$_PENDING"
    _p=$(_read_at "$_tip")
    _clear "$_tip"
    _n=$(_read_at "$_tip")
    _u=$(_run sh "$_reader" 0000000000000000000000000000000000000000)
    if [ "$(_field "$_p" reason)" = "checks_pending" ] \
        && [ "$(_field "$_n" state)" = "unanswerable" ] \
        && [ "$(_field "$_n" reason)" = "no_checks" ] \
        && [ "$(_field "$_u" state)" = "unanswerable" ]; then
        add_row "base_health_unanswerable_by_name" true "a running check, a checkless commit and an unknown commit are each unanswerable by their own reason" load
    else
        add_row "base_health_unanswerable_by_name" false "a degradation did not read unanswerable by name: $(one_line "$_p") / $(one_line "$_n")" load
    fi

    # 2. THE WALK. Red tip, red middle, green behind -- the culprit is the OLDEST red after the
    # last green, never the tip.
    _set "$_tip" "$_RED"; _set "$_c4" "$_RED"; _set "$_c3" "$_RED"
    _set "$_c2" "$_GREEN"; _set "$_c1" "$_GREEN"
    _w=$(_run sh "$_walk")
    if [ "$(_field "$_w" state)" = "red" ] \
        && printf '%s' "$_w" | grep -q "\"commit\": \"${_c3}\"" \
        && printf '%s' "$_w" | grep -q '"pull_request": "https://example.invalid/pull/42"' \
        && printf '%s' "$_w" | grep -q '"author": "tester"'; then
        add_row "base_health_attributes_the_merge" true "the oldest red commit after the last green one is named, with its pull request and author" load
    else
        add_row "base_health_attributes_the_merge" false "the walk did not attribute the mid-walk merge: $(one_line "$_w")" load
    fi

    _wb=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_BASE_ATTRIBUTION_MAX=2 \
        sh "$_walk" ) 2>&1 || true )
    if [ "$(_field "$_wb" state)" = "unattributable" ] \
        && [ "$(_field "$_wb" reason)" = "bound_exhausted" ] \
        && printf '%s' "$_wb" | grep -q '"attributed": null'; then
        add_row "base_health_unattributable_tail" true "a walk that exhausts its bound answers unattributable, never the tip" load
    else
        add_row "base_health_unattributable_tail" false "an exhausted walk did not answer unattributable: $(one_line "$_wb")" load
    fi

    # 3. THE STEP, AND THE ASKED-ONCE GATE.
    _s=$( ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_step" --tick 20260101-000000 --root "$_read" ) 2>&1 || true )
    _key=$(printf '%s' "$_s" | sed -n 's/.*"key": *"\([^"]*\)".*/\1/p' | head -1)
    if [ "$_key" = "base-red:${_c3}" ] && printf '%s' "$_s" | grep -q '"status": "ok"'; then
        add_row "base_health_step_asks_once_per_commit" true "the step keys its question on the attributed commit, not on the tick or the day" load
    else
        add_row "base_health_step_asks_once_per_commit" false "the step's question key is wrong: $(one_line "$_s")" load
    fi

    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _a1=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-000000 --key "$_key" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000000 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-010000 --key "$_key" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "base_health_asked_once" true "a second tick over the same red commit is refused: $(printf '%s' "$_a2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "base_health_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "base_health_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi
    rm -rf "$_qroot"

    # A DEGRADED READ ASKS NOTHING. Our own blindness is not a finding about the repository.
    for _sha in "$_tip" "$_c4" "$_c3" "$_c2" "$_c1"; do _clear "$_sha"; done
    _sd=$( ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_step" --tick 20260101-000000 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_sd" | grep -q '"status": "degraded"' \
        && printf '%s' "$_sd" | grep -q '"needs_agent": \[\]' \
        && printf '%s' "$_sd" | grep -q '"event": ""'; then
        add_row "base_health_degraded_asks_nothing" true "a read we could not make asks nobody and renders no line" load
    else
        add_row "base_health_degraded_asks_nothing" false "a degraded read still asked or rendered: $(one_line "$_sd")" load
    fi

    # A GREEN BASE IS SILENCE.
    _set "$_tip" "$_GREEN"
    _sg=$( ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_step" --tick 20260101-000000 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_sg" | grep -q '"needs_agent": \[\]' && printf '%s' "$_sg" | grep -q '"event": ""'; then
        add_row "base_health_green_is_silent" true "a green base asks nobody and renders no root line" load
    else
        add_row "base_health_green_is_silent" false "a green base was not silent: $(one_line "$_sg")" load
    fi

    # 4. THE READING GATES NOTHING. Proved two ways, because the token is derived from the
    # SURVEY and the survey is the only thing the token can move with: the survey's own output
    # is byte-identical over a red base and a green one (the base's checks are a GitHub fact and
    # the tree is the same either way), and no script in the driving chain reaches either
    # reader at all -- so there is nothing for a gate to be built out of.
    _set "$_tip" "$_GREEN"
    _pg=$( ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_plan" ) 2>&1 || true )
    _set "$_tip" "$_RED"
    _pr=$( ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_plan" ) 2>&1 || true )
    if [ -n "$_pg" ] && [ "$_pg" = "$_pr" ]; then
        add_row "base_health_survey_unmoved" true "the survey the terminal token is derived from is byte-identical over a red base and a green one" load
    else
        add_row "base_health_survey_unmoved" false "the survey differed between a red base and a green one" load
    fi

    _reached=""
    for _f in plan-units.sh claim.sh archive.sh effective-policy.sh verification-handoff.sh \
              retry-undelivered.sh retire-claim.sh land-unit.sh; do
        _p="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/${_f}"
        [ -f "$_p" ] || continue
        if grep -v '^[[:space:]]*#' "$_p" | grep -q 'read-base-checks.sh\|attribute-base-red.sh'; then
            _reached="${_reached} ${_f}"
        fi
    done
    if [ -z "$_reached" ]; then
        add_row "base_health_gates_nothing" true "no script in the driving chain reaches either reader, so no gate can be built out of it" load
    else
        add_row "base_health_gates_nothing" false "the driving chain reaches the base reading:${_reached}" load
    fi

    # THE DELIBERATELY BROKEN ROW, and the one an operator reading a red drill should look at
    # first. The fixture gives this commit NO checks at all -- the most tempting wrong answer,
    # because an empty check list looks exactly like "nothing failed". If the reader ever calls
    # it green, a base nobody looked at becomes indistinguishable from a base that passed, and
    # this row is what goes red.
    _clear "$_c4"
    _broken=$(_read_at "$_c4")
    if [ "$(_field "$_broken" state)" = "unanswerable" ] && [ "$(_field "$_broken" ok)" != "true" ]; then
        add_row "base_health_can_fail" true "INTENTIONAL CASE: a commit with no checks is unanswerable, never green -- this drill can fail" load
    else
        add_row "base_health_can_fail" false "INTENTIONAL CASE: a commit with no checks did not read unanswerable: $(one_line "$_broken")" load
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "base_health_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "base_health_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "base-health" 0 "fail" 1
    fi
    emit_verdict "base-health" 0 "pass" 0
}

# ------------------------------------------------------- verify-delivery-retry
# Does a unit an EARLIER run could not deliver get its merge re-attempted? Naming
# `report_undelivered` was half the repair; nothing offered the unit its one remaining action,
# so it was delivered by nobody until a person opened the pull request.
#
# NO NETWORK: the same local bare origin and the same PATH stub as `verify-retire`.
#
# WHAT IT PROVES:
#   1. the survey offers it              in `undelivered[]`, never as backlog
#   2. the proof reaches the transport   only a `report_undelivered` unit gets past both gates
#   3. a scan-held unit is never tried   the gate working is not the loop stopping
#
# AND ONE ROW THAT DELIBERATELY BREAKS THE SEAM: a unit finished in the identical shape with
# NOTHING recorded. Its verdict falls back to `queue_drained`, so the retry must refuse it -- a
# retry that acted there would be merging on an assumption rather than on a recorded refusal,
# and this drill would pass while it did.
cmd_verify_delivery_retry() {
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _retry="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/retry-undelivered.sh"
    _planner="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/plan-units.sh"
    _recorder="${REPO_ROOT}/plugins/workaholic/skills/story/scripts/record-merge-outcome.sh"
    for _f in "$_lister" "$_retry" "$_planner" "$_recorder"; do
        [ -f "$_f" ] || emit_err "retry_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" "${_work}/.workaholic/stories"
    for _n in 1 2 3; do
        printf -- '---\ncreated_at: 2026-01-01T00:00:0%s+09:00\nauthor: %s\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_n" > "${_work}/.workaholic/tickets/todo/2026010100000${_n}-t.md"
    done
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    _stamp() { # $1 = branch, $2 = ticket basename
        printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: %s\n---\n\n# T\n\nclaimed\n' \
            "$_me" "$1" > "${_work}/.workaholic/tickets/todo/$2"
    }
    # Three units driven to the IDENTICAL finished shape -- drained queue, story at the tip,
    # pull request open. That identity is why the recorded outcome is the only thing that tells
    # them apart, and why the third is the seam worth breaking. `.workaholic/stories/` is
    # recreated on every call: git tracks no empty directory, so checking out `main` for the
    # next branch removes the one the previous branch created.
    _report() { # $1 = branch, $2 = ticket basename, $3 = outcome ("" records nothing)
        ( cd "$_work" \
          && mkdir -p ".workaholic/tickets/archive/$1" ".workaholic/stories" \
          && git mv ".workaholic/tickets/todo/$2" ".workaholic/tickets/archive/$1/" \
          && printf -- '---\ntype: Story\nbranch: %s\n---\n\n## 1. Overview\n\ndone\n' "$1" \
            > ".workaholic/stories/$1.md" \
          && { [ -z "$3" ] || sh "$_recorder" ".workaholic/stories/$1.md" "$3" >/dev/null; } \
          && _git add -A && _git commit -qm "Report the unit" \
          && git push -q origin "$1" ) >/dev/null 2>&1 || true
    }

    # A unit whose merge the TRANSPORT refused -- the one the retry exists for.
    ( cd "$_work" && git checkout -q -b work-20260101-000000 main \
      && _stamp work-20260101-000000 20260101000001-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-refused" ) >/dev/null 2>&1 || true
    _report work-20260101-000000 20260101000001-t.md "merge_refused: session_type_cannot_merge"

    # A unit a SCAN FINDING held -- the same shape, the opposite next action.
    ( cd "$_work" && git checkout -q -b work-20260101-000001 main \
      && _stamp work-20260101-000001 20260101000002-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-held" ) >/dev/null 2>&1 || true
    _report work-20260101-000001 20260101000002-t.md "merge_not_attempted: hard"

    # THE DELIBERATELY BROKEN SEAM: the same finished shape with NOTHING recorded.
    ( cd "$_work" && git checkout -q -b work-20260101-000002 main \
      && _stamp work-20260101-000002 20260101000003-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-silent" ) >/dev/null 2>&1 || true
    _report work-20260101-000002 20260101000003-t.md ""

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) || true
    printf '#!/bin/sh\necho "[]"\n' > "${_bin}/gh"; chmod +x "${_bin}/gh"

    _run() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_retry" "$1" ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n 's/.*"'"$2"'": *"\([^"]*\)".*/\1/p' | head -1; }

    _claims=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_lister" ) 2>&1 || true )
    _verdict() { printf '%s' "$_claims" | tr '{' '\n' | grep "\"unit\": \"$1\"" \
        | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1; }

    if [ "$(_verdict batch-refused)" = "report_undelivered" ] \
        && [ "$(_verdict batch-held)" = "queue_drained" ]; then
        add_row "retry_fixture" true "one unit reads report_undelivered and a scan-held one reads queue_drained -- the shape under test" load
    else
        add_row "retry_fixture" false "the fixture is wrong (refused='$(_verdict batch-refused)' held='$(_verdict batch-held)'): $(one_line "$_claims")" load
        rm -rf "$_tmp"
        emit_verdict "delivery-retry" 0 "fail" 1
    fi

    # 1. THE SURVEY OFFERS IT IN A FIELD OF ITS OWN, and still excludes it. Loosening the
    # exclusion would put the unit's ARCHIVED tickets back into `backlog[]`, where a run would
    # claim them fresh and re-drive work already written, pushed and sitting at an open pull
    # request -- so both halves are asserted, not just the offer.
    _plan=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_planner" ) 2>&1 || true )
    if printf '%s' "$_plan" | grep -q '"undelivered": \[{"unit": "batch-refused"' \
        && printf '%s' "$_plan" | grep -q 'claimed_undelivered'; then
        add_row "retry_offered_in_its_own_field" true "the survey offers the undelivered unit in undelivered[] while still excluding it claimed_undelivered" load
    else
        add_row "retry_offered_in_its_own_field" false "the survey did not offer the unit in a field of its own: $(one_line "$_plan")" load
    fi

    # 2. THE PROOF REACHES THE TRANSPORT, once. With no pull request in the stub's answer the
    # attempt stops at `no_open_pull_request` -- which is precisely the proof that both gates
    # passed and the merge seam was reached, with no network call made.
    _out=$(_run batch-refused)
    if [ "$(_field "$_out" reason)" = "no_open_pull_request" ]; then
        add_row "retry_reaches_the_transport" true "the undelivered unit passes both gates and reaches the merge seam" load
    else
        add_row "retry_reaches_the_transport" false "the undelivered unit did not reach the merge seam: $(one_line "$_out")" load
    fi

    # 3. A SCAN-HELD PULL REQUEST IS NEVER TRIED. It waits on a person BY DESIGN -- the gate
    # working is not the loop stopping -- and the verdict chain keeps it out of the retry
    # entirely, which is what this row proves rather than assumes.
    _held=$(_run batch-held)
    if [ "$(_field "$_held" reason)" = "not_undelivered:queue_drained" ] \
        && printf '%s' "$_held" | grep -q '"attempted": false'; then
        add_row "retry_scan_held_never_tried" true "a scan-held unit never reaches the retry and is refused by name" load
    else
        add_row "retry_scan_held_never_tried" false "a scan-held unit was not refused by name: $(one_line "$_held")" load
    fi

    # THE DELIBERATELY BROKEN ROW. The same finished shape with NOTHING recorded: the verdict
    # falls back to `queue_drained`, so the retry must refuse it. A retry that acted here would
    # be merging on an assumption rather than on the recorded refusal, and this drill would pass
    # while it did.
    _silent=$(_run batch-silent)
    if printf '%s' "$_silent" | grep -q '"attempted": false' \
        && [ "$(_field "$_silent" reason)" = "not_undelivered:queue_drained" ]; then
        add_row "retry_unrecorded_never_tried" true "an unrecorded outcome is never retried, so no merge rests on an assumption -- this drill can fail" load
    else
        add_row "retry_unrecorded_never_tried" false "an unrecorded outcome reached the merge seam: $(one_line "$_silent")" load
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "retry_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "retry_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "delivery-retry" 0 "fail" 1
    fi
    emit_verdict "delivery-retry" 0 "pass" 0
}

# ------------------------------------------------------- verify-handoff-question
# Does the one act a DECLARED handoff is waiting on reach the person who can perform it?
# `awaiting_verification` appeared nowhere outside `drive/` until 2026-08-27: §6 left such a
# unit's pull request open and its claim standing on purpose, and then nothing addressed anybody
# again — while `stalled-units`, once the tip went stale, asked the WRONG question about it.
#
# NO NETWORK: a local bare origin and a `gh` stub on PATH. The drill ASSERTS the stub is what
# `gh` resolves to rather than assuming it.
#
# THE FIXTURE REACHES THE VERDICT THROUGH THE REAL DERIVATION, never by forcing it: reported
# (a branch story at the tip), work still queued, and the declaration on the QUEUED work. A drill
# over a forced verdict proves the renderer and nothing about the oracle, so the oracle is
# asserted first — a failure downstream is then attributable to the step rather than to a
# mis-built fixture.
#
# WHAT IT PROVES:
#   1. the oracle                 `list-claims.sh` reads `awaiting_verification` for the unit
#   2. asked once, in the right   one `needs_agent` entry keyed `handoff-unit:<unit>`, addressed
#      words                      to the claim HOLDER, carrying the declared reason VERBATIM
#   3. a second tick is silent    the asked-once ledger, spent through `ask-question.sh`
#   4. `stalled-units` is silent  no `stalled-unit:<unit>` for the same unit in the same tick,
#                                 counted in its summary instead — and a genuinely stale claim
#                                 beside it is still asked about exactly as before
#   5. nothing is cleared         the claim stands, the branch is untouched, and neither the
#                                 fixture checkout nor this repository is written to
#
# AND ONE ROW THAT DELIBERATELY BREAKS THE SEAM: a unit whose declaring ticket has been DRIVEN
# (archived out of todo at the tip) while other work stays queued. The declaration is read from
# the queued work, so the verdict must fall back and no question may be asked. That row is the
# INTENTIONAL one — it is the self-releasing property, and if the reading ever consulted the
# archived work instead, every other row here would still pass.
cmd_verify_handoff_question() {
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _detail="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/declared-handoff-detail.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh"
    _stalled="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh"
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    for _f in "$_lister" "$_detail" "$_step" "$_stalled" "$_ask"; do
        [ -f "$_f" ] || emit_err "handoff_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    # The declared reason, deliberately unlike any title in the fixture, so a row that matched a
    # title instead of the field would fail rather than pass by coincidence.
    _reason="an API token and account id must be added as repository secrets"

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" "${_work}/.workaholic/stories"
    # $1 = basename, $2 = the declared reason ("" for none)
    _ticket() {
        printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nverification_handoff: %s\n---\n\n# Wire the deploy target\n' \
            "$_me" "$2" > "${_work}/.workaholic/tickets/todo/$1"
    }
    _ticket 20260101000001-declared.md "$_reason"
    _ticket 20260101000002-plain.md ""
    _ticket 20260101000003-released.md "$_reason"
    _ticket 20260101000004-still-queued.md ""
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    # The claim commit must TOUCH the stamped file: the artifact list is "files this commit
    # touched that still carry the stamp at the tip".
    _stamp() { # $1 = branch, $2 = ticket basename, $3 = declared reason
        printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: %s\nverification_handoff: %s\n---\n\n# Wire the deploy target\n\nclaimed\n' \
            "$_me" "$1" "$3" > "${_work}/.workaholic/tickets/todo/$2"
    }
    # $1 = branch -- what `/story` commits when it opens the pull request. The `mkdir` is
    # load-bearing: git prunes the empty `stories/` directory on every checkout away from a
    # branch that carried one, so a later branch's story would fail to write and its whole
    # `&&` chain would fall silently through to `|| true`.
    _story() {
        mkdir -p "${_work}/.workaholic/stories"
        printf -- '---\ntype: Story\ntitle: %s\n---\n\n# %s\n' "$1" "$1" \
            > "${_work}/.workaholic/stories/$1.md"
    }

    # THE UNIT UNDER TEST: reported, work still queued, and the declaration on that queued work.
    ( cd "$_work" && git checkout -q -b work-20260101-000000 main \
      && _stamp work-20260101-000000 20260101000001-declared.md "$_reason" \
      && _story work-20260101-000000 \
      && _git add -A && _git commit -qm "Claim a PR-unit" -m "Unit: batch-handoff" \
      && git push -q origin work-20260101-000000 ) >/dev/null 2>&1 || true

    # A CONTROL BESIDE IT: reported, work queued, nothing declared. It reads `parked_with_pr`,
    # so `stalled-units` must still ask about it once its tip goes stale.
    ( cd "$_work" && git checkout -q -b work-20260101-000001 main \
      && _stamp work-20260101-000001 20260101000002-plain.md "" \
      && _story work-20260101-000001 \
      && _git add -A && _git commit -qm "Claim a PR-unit" -m "Unit: batch-plain" \
      && git push -q origin work-20260101-000001 ) >/dev/null 2>&1 || true

    # THE DELIBERATELY BROKEN SEAM: the declaring ticket has been DRIVEN -- archived out of todo
    # at the tip -- while other work stays queued. The declaration lives on the queued work, so
    # the verdict must fall back and no question may be asked.
    ( cd "$_work" && git checkout -q -b work-20260101-000002 main \
      && _stamp work-20260101-000002 20260101000003-released.md "$_reason" \
      && _stamp work-20260101-000002 20260101000004-still-queued.md "" \
      && _story work-20260101-000002 \
      && _git add -A && _git commit -qm "Claim a PR-unit" -m "Unit: batch-released" \
      && mkdir -p "${_work}/.workaholic/tickets/archive/work-20260101-000002" \
      && _git mv .workaholic/tickets/todo/20260101000003-released.md \
                .workaholic/tickets/archive/work-20260101-000002/ \
      && _git commit -qm "Archive the declared ticket" \
      && git push -q origin work-20260101-000002 ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) || true

    # The stub answers `gh api user` (so `available` reads true) and every pulls query with an
    # empty list -- a fixture whose unit has no pull request, which the reading reports as
    # coordinates left unstated rather than as a dropped candidate.
    printf '#!/bin/sh\necho "[]"\n' > "${_bin}/gh"; chmod +x "${_bin}/gh"
    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "handoff_question_no_network" true "the stub is what gh resolves to, so no row below reaches the network" load
    else
        add_row "handoff_question_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "handoff-question" 0 "fail" 1
    fi

    _in() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 WORKAHOLIC_CLAIM_STALE_HOURS=0 "$@" ) 2>&1 || true; }

    # 1. THE ORACLE FIRST. If the fixture does not reach the verdict through the real derivation,
    # every row below proves nothing -- so this one is load-bearing and stops the drill.
    _claims=$(_in sh "$_lister")
    _verdict() { printf '%s' "$_claims" | tr '{' '\n' | grep "\"unit\": \"$1\"" \
        | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1; }
    _plain_verdict=$(_verdict batch-plain)
    if [ "$(_verdict batch-handoff)" = "awaiting_verification" ] && [ -n "$_plain_verdict" ] \
        && [ "$_plain_verdict" != "awaiting_verification" ]; then
        add_row "handoff_question_fixture" true "the oracle reads awaiting_verification, with an ordinary parked claim beside it -- the shape under test" load
    else
        add_row "handoff_question_fixture" false "the fixture is wrong (handoff='$(_verdict batch-handoff)' plain='${_plain_verdict}'): $(one_line "$_claims")" load
        rm -rf "$_tmp"
        emit_verdict "handoff-question" 0 "fail" 1
    fi

    # 2. ONE QUESTION, ADDRESSED TO THE HOLDER, IN THE DECLARED WORDS. The reason is asserted as
    # the WHOLE string the ticket wrote, not a substring of any title in the fixture.
    _out=$(_in sh "$_step" --tick 20260101-000000 --root "$_read")
    if printf '%s' "$_out" | grep -q '"key":"handoff-unit:batch-handoff"' \
        && printf '%s' "$_out" | grep -q "\"declared_reason\":\"${_reason}\"" \
        && printf '%s' "$_out" | grep -q "\"owner\":\"${_me}\""; then
        add_row "handoff_question_asked" true "one question, keyed handoff-unit:batch-handoff, addressed to the claim holder, quoting the declared reason verbatim" load
    else
        add_row "handoff_question_asked" false "the question is missing, misaddressed, or does not carry the declared reason: $(one_line "$_out")" load
    fi

    # ...and only the unit that declared one. The released unit must not appear.
    if printf '%s' "$_out" | grep -q 'handoff-unit:batch-released'; then
        add_row "handoff_question_releases_on_drive" false "a unit whose declaring ticket was driven is still asked about -- the reading consulted the ARCHIVED work" load
    else
        add_row "handoff_question_releases_on_drive" true "a unit whose declaring ticket was driven is not asked about -- the reading is self-releasing (this drill can fail)" load
    fi

    # 3. ASKED ONCE. The gate is the check-in's, not this step's, so the drill exercises the gate
    # with this step's key: the first ask is allowed, the second is refused by name.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _a1=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-000000 --key "handoff-unit:batch-handoff" \
        --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000000 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-010000 --key "handoff-unit:batch-handoff" \
            --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "handoff_question_asked_once" true "the same key is refused on a later tick: $(printf '%s' "$_a2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "handoff_question_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "handoff_question_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi
    rm -rf "$_qroot"

    # 4. `stalled-units` IS SILENT ON THE SAME UNIT, IN THE SAME TICK -- and still asks about the
    # ordinary parked claim beside it. One step asks and the other filters; either half alone is
    # a defect, and a unit drawing two differently-worded questions is the cost being prevented.
    _sout=$(_in sh "$_stalled" --tick 20260101-000000 --root "$_read")
    if ! printf '%s' "$_sout" | grep -q 'stalled-unit:batch-handoff'; then
        if printf '%s' "$_sout" | grep -q 'stalled-unit:batch-plain' \
            && printf '%s' "$_sout" | grep -q 'awaiting a declared verification'; then
            add_row "handoff_question_stalled_silent" true "stalled-units asks nothing about the declared handoff, counts it as a finding, and still asks about the parked claim beside it" load
        else
            add_row "handoff_question_stalled_silent" false "the filter dropped more than the declared handoff, or stopped counting it: $(one_line "$_sout")" load
        fi
    else
        add_row "handoff_question_stalled_silent" false "stalled-units still asks the wrong question about the declared handoff: $(one_line "$_sout")" load
    fi

    # 5. NOTHING WAS CLEARED. The claim stands with the same verdict, the branch is untouched,
    # and the fixture checkout carries no write at all -- the step's whole licence is to report.
    _after_claims=$(_in sh "$_lister")
    _fixture_dirty=$( ( cd "$_read" && git status --porcelain 2>/dev/null ) | head -1 )
    _branches=$( ( cd "$_origin" && git for-each-ref --format='%(refname:short)' refs/heads ) | sort | tr '\n' ' ')
    if [ "$_claims" = "$_after_claims" ] && [ -z "$_fixture_dirty" ] \
        && [ "$_branches" = "main work-20260101-000000 work-20260101-000001 work-20260101-000002 " ]; then
        add_row "handoff_question_clears_nothing" true "the claim stands with the same verdict, every branch survives, and the fixture checkout is unwritten" load
    else
        add_row "handoff_question_clears_nothing" false "the drill's step changed state (dirty='${_fixture_dirty}' branches='${_branches}')" load
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "handoff_question_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "handoff_question_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "handoff-question" 0 "fail" 1
    fi
    emit_verdict "handoff-question" 0 "pass" 0
}

# ---------------------------------------------------------------- verify-return-path
#
# THE RETURN PATH: an answer written in a question's own thread reaches the loop's work.
#
# Walks the five stages in order over LOCAL fixtures with the transport stubbed and NO
# NETWORK AT ALL -- ask -> reply -> record -> file -> stamp -- and asserts after each. The
# negatives are half the contract and are asserted beside the happy path: a machine's own
# reply is never an answer, a second tick over the same thread files nothing and stamps
# nothing, a candidate with no coordinate is NAMED rather than searched for, and a failed
# stamp changes nothing.
#
# THE BREAKER ROW IS THE POINT OF THE DRILL. The natural mistake is to wire the read at the
# CHANNEL instead of the question's own thread, which silently reintroduces the channel
# history read this design avoids and which `workaholic:notify`'s two-query bound protects.
# The drill runs a COPY of the step with the channel wired in and asserts it FAILS the same
# check the real step passes -- so a drill that would pass over a broken implementation is
# caught here rather than in production.
#
# The Slack half is fixture data on purpose: what is under test is which writer sees a reply,
# not the transport.
cmd_verify_return_path() {
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _state="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/question-state.sh"
    _record="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/record-answer.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-question-answers.sh"
    _filer="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh"
    for _f in "$_ask" "$_state" "$_record" "$_step" "$_filer"; do
        [ -f "$_f" ] || emit_err "return_path_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _fx="${_tmp}/repo"; _bin="${_tmp}/bin"
    mkdir -p "${_fx}/.workaholic" "$_bin"

    _key="stalled-unit:drill-unit"
    _coord="C0DRILL01:1756345678.123456"
    _answer_ts="1756345999.000100"
    _words="Yes - and please make the drill say which thread it read."

    # The stub answers `gh api user` and one issue POST, and NOTHING else: a query this drill
    # did not anticipate must fail loudly rather than return a plausible empty answer.
    printf '#!/bin/sh\ncase "$*" in\n  *"api user"*) printf "drill-runner\\n"; exit 0 ;;\n  *issues*POST*|*POST*issues*) cat >/dev/null; echo %s; exit 0 ;;\nesac\necho "unexpected gh call: $*" >&2; exit 1\n' \
        "'{\"html_url\": \"https://example.invalid/issues/1\", \"number\": 1, \"assignees\": [{\"login\": \"drill-runner\"}]}'" \
        > "${_bin}/gh"
    chmod +x "${_bin}/gh"
    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "return_path_no_network" true "the stub is what gh resolves to, so no row below reaches the network" load
    else
        add_row "return_path_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "return-path" 0 "fail" 1
    fi

    _in() { ( cd "$_fx" && PATH="${_bin}:$PATH" "$@" ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n "s/.*\"$2\": *\"\\([^\"]*\\)\".*/\\1/p" | head -1; }

    # 1. THE COORDINATE IS RECORDED WHERE THE QUESTION WAS POSTED.
    _gate=$(_in sh "$_ask" --tick 20260101-100000 --root "$_fx" --key "$_key" \
        --to drill@example.com --hour 10 --weekday 1)
    _logstep=$(_field "$_gate" log_step)
    _in sh "$_ask" --record-ask --tick 20260101-100000 --root "$_fx" --key "$_key" \
        --log-step "$_logstep" --coordinate "$_coord" >/dev/null
    # A second question, deliberately posted with NO coordinate: an ordinary state that must be
    # named rather than searched for.
    _in sh "$_ask" --record-ask --tick 20260101-100000 --root "$_fx" --key "direction-dormant:drill" >/dev/null
    _st=$(_in sh "$_state" --root "$_fx" --key "$_key")
    if [ "$(_field "$_st" coordinate)" = "$_coord" ] && [ "$(_field "$_st" state)" = "asked" ]; then
        add_row "return_path_coordinate_recorded" true "the coordinate the question was posted at is recoverable by its key, with no search" load
    else
        add_row "return_path_coordinate_recorded" false "the coordinate did not round-trip: $(one_line "$_st")" load
    fi

    # 2. THE READ NAMES THE RIGHT CANDIDATES -- and only them.
    _out=$(_in sh "$_step" --tick 20260101-110000 --root "$_fx")
    if printf '%s' "$_out" | grep -q "\"key\":\"${_key}\",\"coordinate\":\"${_coord}\"" \
        && printf '%s' "$_out" | grep -q '"no_coordinate":\[{"slug":"direction-dormant'; then
        add_row "return_path_read_names_thread" true "one thread to read on the recorded coordinate; the coordinate-less question is named, not searched for" load
    else
        add_row "return_path_read_names_thread" false "the candidate set is wrong: $(one_line "$_out")" load
    fi
    # THE BOUND, ASSERTED RATHER THAN TRUSTED: no channel, no window, no search.
    if printf '%s' "$_out" | grep -q 'NO search, NO channel history' \
        && ! printf '%s' "$_out" | grep -q 'window_hours'; then
        add_row "return_path_no_channel_read" true "the read is bounded to one thread per candidate on a known coordinate; no channel and no window are named" load
    else
        add_row "return_path_no_channel_read" false "the read is not bounded to the question's own thread: $(one_line "$_out")" load
    fi

    # 3. THE ANSWER IS RECORDED THROUGH THE ONE WRITER -- and a machine's post is not one.
    # The thread is fixture data; the judgement is the agent's, so what the drill asserts is
    # that the bar is stated and that the HUMAN reply is what reaches the writer.
    _in sh "$_record" --root "$_fx" --tick 20260101-110000 --key "$_key" --answer "$_words" >/dev/null
    _st=$(_in sh "$_state" --root "$_fx" --key "$_key")
    if [ "$(_field "$_st" state)" = "answered" ] \
        && printf '%s' "$_st" | grep -qF "$_words"; then
        add_row "return_path_answer_recorded" true "the question reads answered and carries the person's words verbatim" load
    else
        add_row "return_path_answer_recorded" false "the answer did not reach the writer: $(one_line "$_st")" load
    fi
    if printf '%s' "$_out" | grep -q 'excluded BY SHAPE and is never an answer'; then
        add_row "return_path_machine_post_excluded" true "the read hands back the bar: a machine's own post is never an answer" load
    else
        add_row "return_path_machine_post_excluded" false "the judgement's bar is not carried to the agent: $(one_line "$_out")" load
    fi

    # 4. AN ANSWER THAT ASKS FOR WORK FILES EXACTLY ONE ISSUE, THROUGH THE FILER THE SWEEP
    # ALREADY USES. The dedup marker is the answer message's own coordinate, read back out of
    # the issue ledger by `list-swept-slack-refs.sh` -- the same marker and the same reader.
    printf '%s\n' "$_words" > "${_tmp}/body"
    _filed=$(_in sh "$_filer" --slack-ref "C0DRILL01:${_answer_ts}" \
        --permalink "https://example.invalid/archives/C0DRILL01/p1" \
        --subject "person:drill" --assignee drill-runner \
        acme/drill "Make the drill say which thread it read" "${_tmp}/body")
    if printf '%s' "$_filed" | grep -q '"ok": true'; then
        add_row "return_path_issue_filed" true "the answer became one [FB] issue through file-inbound-ask.sh, assigned to the running identity" load
    else
        add_row "return_path_issue_filed" false "the filing did not go through the one filer: $(one_line "$_filed")" load
    fi

    # 5. A SECOND TICK FILES NOTHING AND STAMPS NOTHING. The dedup is structural: an answered
    # question is not a candidate, so no cursor and no second ledger exist.
    _out2=$(_in sh "$_step" --tick 20260101-120000 --root "$_fx")
    if ! printf '%s' "$_out2" | grep -q "\"key\":\"${_key}\""; then
        add_row "return_path_filed_once" true "the answered question is no longer a thread to read, so a later tick files and stamps nothing" load
    else
        add_row "return_path_filed_once" false "a later tick would read and file the same answer again: $(one_line "$_out2")" load
    fi

    # 6. THE STAMP IS A REACTION AND NOTHING ELSE, NAMED ONCE IN THE CATALOG.
    _catalog="${REPO_ROOT}/plugins/workaholic/skills/notify/reference/notifications.md"
    _template="${REPO_ROOT}/plugins/workaholic/skills/workaholify/routines/moderate.md"
    _emoji=$(sed -n 's/.*an answer the tick read is stamped where it was written: `\(:[a-z_]*:\)`.*/\1/p' "$_catalog" | head -1)
    if [ -n "$_emoji" ] && grep -qF "$_emoji" "$_template" \
        && grep -q 'post \*\*no reply\*\* for that event' "$_template"; then
        add_row "return_path_stamp_is_a_reaction" true "the catalog names ${_emoji} once, the routine authorizes it, and no reply is posted for this event" load
    else
        add_row "return_path_stamp_is_a_reaction" false "the stamp is not a single-sourced reaction, or the template still allows a reply" load
    fi
    # A FAILED STAMP CHANGES NOTHING: the recording and the filing both happened before it was
    # attempted, so the state after a stamp that never lands is the state asserted above.
    _st2=$(_in sh "$_state" --root "$_fx" --key "$_key")
    if [ "$(_field "$_st2" state)" = "answered" ]; then
        add_row "return_path_stamp_not_load_bearing" true "with no stamp attempted at all the answer stays recorded and the question stays answered" load
    else
        add_row "return_path_stamp_not_load_bearing" false "the recording depends on the stamp: $(one_line "$_st2")" load
    fi

    # 7. THE BREAKER ROW, LABELLED AS THE INTENTIONAL FAILURE. A copy of the step wired at the
    # CHANNEL instead of the question's own thread must fail the bound check above.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/." "$_broken/"
    # Both halves of the bound are broken, because both are what the mistake would look
    # like: the phrase that forbids a history read, and a window the step has no business
    # naming at all.
    _wire_at_channel() {
        sed -e 's/NO search, NO channel history/read the channel over the window/' \
            -e 's/surface: "slack",/surface: "slack", window_hours: 26,/' \
            "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-question-answers.sh" \
            > "${_broken}/step-question-answers.sh"
        chmod +x "${_broken}/step-question-answers.sh"
    }
    _wire_at_channel
    _bout=$(_in sh "${_broken}/step-question-answers.sh" --tick 20260101-130000 --root "$_fx")
    if printf '%s' "$_bout" | grep -q 'NO search, NO channel history'; then
        add_row "return_path_breaker" false "the breaker row did not break the seam, so this drill cannot fail" load
    else
        add_row "return_path_breaker" true "a step wired at the channel fails the bound check the real step passes (this drill can fail)" load
    fi

    # 8. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "return_path_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "return_path_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "return-path" 0 "fail" 1
    fi
    emit_verdict "return-path" 0 "pass" 0
}

USAGE='{"ok": false, "reason": "usage", "detail": "loop-drill.sh seed|status|reset|verify-specificate <issue>|verify-implement <issue>|verify-plan [--json]|verify-status [--json]|verify-cadence [--json]|verify-planner [--json]|verify-standup [--json]|verify-moderate [--json]|verify-propose [--json]|verify-direction-health [--json]|verify-arrival [--json]|verify-residue [--json]|verify-revision [--json]|verify-merged-claim [--json]|verify-identity-handoff [--json]|verify-close [--json]|verify-retire [--json]|verify-delivery-retry [--json]|verify-handoff-question [--json]|verify-base-health [--json]|verify-return-path [--json]"}'

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
    verify-direction-health) cmd_verify_direction_health "$@" ;;
    verify-arrival) cmd_verify_arrival "$@" ;;
    verify-residue) cmd_verify_residue "$@" ;;
    verify-revision) cmd_verify_revision "$@" ;;
    verify-merged-claim) cmd_verify_merged_claim "$@" ;;
    verify-identity-handoff) cmd_verify_identity_handoff "$@" ;;
    verify-close) cmd_verify_close "$@" ;;
    verify-retire) cmd_verify_retire "$@" ;;
    verify-delivery-retry) cmd_verify_delivery_retry "$@" ;;
    verify-handoff-question) cmd_verify_handoff_question "$@" ;;
    verify-base-health) cmd_verify_base_health "$@" ;;
    verify-return-path) cmd_verify_return_path "$@" ;;
    *)
        echo "$USAGE" >&2
        exit 2
        ;;
esac
