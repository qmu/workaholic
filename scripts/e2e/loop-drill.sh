#!/bin/sh -eu
# Exercise the propose-implement loop on demand, end to end.
#
#   loop-drill.sh verify-all [--json]         # run the whole classified set, one verdict each
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
#   loop-drill.sh verify-claim-race [--json]  # do two runs ever claim and drive one unit?
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
# WHY IT LIVES IN `scripts/`, NOT IN THE PLUGIN. This is operator tooling: `seed`, `status`,
# `reset` and the two stage verbs assume the server's full `gh` and `qfs`, which a plugin skill
# must never do (a skill ships to 40+ agents through `outputs/`, and half of them have
# neither). It ships to no other agent and is exempt from nothing else.
#
# THAT CLAIM ONCE COVERED THE WHOLE FILE AND NO LONGER DOES (2026-08-29, mission
# `run-the-loop-s-own-proofs-on-every-turn`). Measured over all thirty `verify-*` commands with
# no `gh`, no `qfs`, no key and no proxy: TWO need the server (`verify-specificate`,
# `verify-implement`, which take an issue number only `seed` can mint), six answer a question
# about THIS CHECKOUT, and twenty-two are hermetic — each building its own throwaway fixture.
# The per-drill classification is `docs/loop-drill-runbook.md` §9, `verify-all` runs the set it
# names, and `.github/workflows/loop-drills.yml` runs the hermetic part of it on every push.
# A header claiming otherwise while CI runs the file beside it is the documentation defect this
# repository's own rule refuses.
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
# 2026-08-12: the `/slack-me` mount reaches the repository's private channel, the
# team-bot mount cannot see it). The channel is the repository's own name since
# 2026-08-28 — the `dev-` prefix convention is retired.
DRILL_SLACK_MOUNT="${DRILL_SLACK_MOUNT:-/slack-me/qmu/workaholic/messages}"

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

# An ISO-8601 UTC instant N hours before now, for a fixture whose ages must be read against the
# run clock rather than frozen into a date that goes stale the day after it is written. GNU and
# BSD `date` disagree about relative arithmetic, so both spellings are tried before falling back
# to an epoch computation.
_iso_hours_ago() {
    _iha_n="${1:-0}"
    date -u -d "-${_iha_n} hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null && return 0
    date -u -v-"${_iha_n}"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null && return 0
    _iha_epoch=$(( $(date -u +%s) - _iha_n * 3600 ))
    date -u -r "$_iha_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null && return 0
    date -u +%Y-%m-%dT%H:%M:%SZ
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
BREAKERS=0
SHOW_ALL_ROWS="false"

# add_row <check> <pass:true|false|null> <detail> <bearing:load|breaker|advisory>
#
# Both accumulators are built here rather than filtered at print time: a row's JSON
# carries operator-written detail, and re-parsing that back out with sed to decide what
# to print is the kind of cleverness that breaks on the first detail containing a brace.
#
# `breaker` IS `load` PLUS A NAME (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`).
# A breaker row asserts that a DELIBERATELY BROKEN copy of the seam fails — so when the
# breaker stops breaking, that row goes false and the drill exits 1 exactly as it always
# did. What the third value adds is DISCOVERABILITY: about a dozen breaker rows were named
# after what they assert (`retire_refuses_a_judgement`, `base_health_can_fail`, …) and five
# after the convention (`checkin_breaker`, …), so nothing could answer *which drills have a
# breaker* and *which have none*. A drill with no breaker is not failing — it is UNPROVED,
# and `verify-all` reports it in its own right rather than inside the passing total.
#
# The alternative — renaming ~17 rows to a `*_breaker` convention — was refused: it changes
# every affected drill's output keys (which the runbook's pasted verdicts and this
# repository's own regression suite read) to say something a field can say for free.
add_row() {
    _row="{\"check\": \"$(json_escape "$1")\", \"pass\": $2, \"detail\": \"$(json_escape "$3")\", \"bearing\": \"$4\"}"
    ROWS="$(append_row "$ROWS" "$_row")"
    if [ "$2" != "true" ]; then
        ACTIONABLE="$(append_row "$ACTIONABLE" "$_row")"
    fi
    if [ "$4" = "breaker" ]; then
        BREAKERS=$((BREAKERS + 1))
    fi
    if [ "$4" = "load" ] || [ "$4" = "breaker" ]; then
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
    printf '{"ok": %s, "stage": "%s", "issue": %s, "verdict": "%s", "load_bearing": {"passed": %s, "failed": %s}, "advisory": %s, "breakers": %s, "rows": [%s]}\n' \
        "$_ok" "$_stage" "$_issue" "$_verdict" "$LOAD_PASSED" "$LOAD_FAILED" "$ADVISORY" "$BREAKERS" "$_rows"
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
        #
        # WRITTEN AS A QUOTED HEREDOC, never as a `printf` of an escaped one-liner
        # (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`). The escaped
        # form put the awk program inside DOUBLE quotes, so its own `\"` closed the
        # program string and awk answered `runaway string constant` on every run: the
        # stub had never once produced a plan, `planner_authors` and `planner_arranges`
        # were `false` on an unmodified tree, and nothing noticed because nothing ran
        # the drill. A quoted heredoc needs no escaping at all, which is why it cannot
        # regress the same way.
        cat > "$_work/bin/wh-drill-planner" <<'DRILL_PLANNER'
#!/bin/sh
sed -n 's/^- #\([0-9]*\) .*/\1/p' \
    | awk 'BEGIN{printf "{\"groups\":[{\"title\":\"Drill group\",\"items\":["}
           {printf "%s{\"pr\":%s}", (n++?",":""), $1}
           END{print "]}]}"}'
DRILL_PLANNER
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
        add_row "revision_immutable_field_unreachable" true "an immutable field is unreachable from the interface -- this drill can fail" breaker
    else
        add_row "revision_immutable_field_unreachable" false "an immutable field was reachable: $(one_line "$_o")" breaker
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
    #
    # IT PARSES THE ROW, NOT THE LINE. The earlier extractor required no `}` between `"slug"`
    # and `"state"`, which silently stopped matching the moment a NESTED OBJECT joined the row
    # (`residue` on 2026-08-28, `waiting` beside it) — every row below then read `nothing` and
    # failed for a reason that had nothing to do with what it was testing. `jq` is what the
    # readers themselves require, so asking it is neither a new dependency nor a guess.
    _stateof() { printf '%s' "$_state" | jq -r --arg s "$1" \
        '(.strategies // []) | map(select(.slug == $s)) | (first // {}) | .state // ""' 2>/dev/null | head -1; }

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
    # The body is a QUOTED STRING in the step's source and since 2026-08-28 it is preceded by
    # the leaving clause (`$leaving_clause + "Re-date it, ..."`), so the extraction keys on the
    # sentence itself rather than on what sits before it. What is bounded is the operator's
    # act; the clause in front of it names the size of what is at stake.
    _obody=$(sed -n 's/.*"\(Re-date it[^"]*\)".*/\1/p' "$_step" | head -1)
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
    # PARSES THE ROW, NOT THE LINE — `verify-direction-health`'s extractor and its reason: a
    # nested object on the row (`residue`, `waiting`) silently defeated the old pattern, so
    # every reading below failed for a reason unrelated to what it tested.
    _stateof() { printf '%s' "$_state" | jq -r --arg s "$1" \
        '(.strategies // []) | map(select(.slug == $s)) | (first // {}) | .state // ""' 2>/dev/null | head -1; }
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
        add_row "arrival_waiting_work_is_not_arrival" true "a direction with work still waiting reads live, never arrived -- this drill can fail" breaker
    else
        add_row "arrival_waiting_work_is_not_arrival" false "a direction with waiting work read '$(_stateof busy)', so arrival is being asserted over work in flight" breaker
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
    # TWO live directions, deliberately (2026-08-28, mission
    # `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`). The invariant this row holds is
    # *a tick where nothing happened renders no line*, and it is NARROWED rather than broken by
    # `direction-last:<slug>`: a repository down to its LAST live direction does have something
    # to say, once, to the person who owns it. So the all-live fixture carries two, and the
    # single-live case is asserted on its own below rather than silently folded in here.
    sed 's/^slug: busy$/slug: busy2/' "${_root}/.workaholic/strategies/busy.md" \
        > "${_live}/.workaholic/strategies/busy2.md"
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

    # AND THE ONE EXCEPTION, NAMED RATHER THAN FOLDED IN. With exactly ONE live direction the
    # loop is one close away from originating nothing, and that is said to the person who owns
    # it -- once, keyed on its slug, with the leaving beside it. `direction-none` fires only
    # after every direction is already closed and is addressed to nobody, which is the gap this
    # reading exists to fill.
    rm -f "${_live}/.workaholic/strategies/busy2.md"
    ( cd "$_live" && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm one ) >/dev/null 2>&1 || true
    _1out=$(cd "$_live" && sh "$_step" --tick 20260101-000000 --root "$_live" --open-proposals "$_open" 2>&1) || true
    if printf '%s' "$_1out" | grep -q '"key": *"direction-last:busy"' \
        && printf '%s' "$_1out" | grep -q 'only one live direction is left'; then
        add_row "arrival_last_live_is_named" true "the last live direction is named to its owner, before the silence" load
    else
        add_row "arrival_last_live_is_named" false "the last live direction reached nobody: $(one_line "$_1out")" load
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
        add_row "residue_reads_the_active_area" false "an ARCHIVED mission reached the residue, so the reader is not reading the active area -- this drill can fail" breaker
    else
        add_row "residue_reads_the_active_area" true "only active missions reach the residue; the archived, unattributed one does not" breaker
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

# ------------------------------------------------- verify-corpus-boundary
# Does the closing link stay readable as the corpus grows? Both hops of `attributed-work.sh`
# prefilter with one `grep` per `xargs` batch, and the shape that shipped —
# `xargs grep -lFf … > cand || : > cand` — TRUNCATED the candidates every earlier batch had
# already written whenever a later batch matched nothing. Past one command buffer the link went
# silent. Measured on this repository 2026-08-29: 1411 corpus paths / 132292 bytes against a
# 131072-byte buffer, 0 candidates where an appending walk found 26, and `no_citing_artifacts`
# for a direction with 26 citing artifacts.
#
# THE SUITE PINS THE UNIT; THIS PINS THE CHAIN the operator actually depends on — survey →
# residue → question — over a corpus past the boundary, and the degraded direction beside it.
#
# NO NETWORK AND NO CREDENTIAL. The survey's one remote read is the open-proposal gate, and it
# is SUPPLIED through `--open-proposals` exactly as `verify-residue` supplies it, so the drilled
# path is the real one. The fixture is git-backed for the same reason: `landed[]` is a
# `git log --since` read.
#
# THE BOUNDARY IS DERIVED FROM THE RUNNING SYSTEM, never hard-coded. `xargs`s command buffer is
# a property of the machine (~128 KiB on GNU, unrelated to `ARG_MAX`), so a filler count pinned
# at "1400 files" would quietly stop exercising the split elsewhere and this row would prove
# nothing. The probe below counts how many times `xargs` invokes its command over exactly the
# corpus the reader builds, and the filler grows until that count exceeds one. What must be
# large is the PATH LIST, which is what `xargs` measures — never the file bodies, which stay
# three lines.
#
# THE BREAKER ROW IS `corpus_batching_tolerance_holds`, and it is written against BEHAVIOUR
# rather than a return shape: it runs a COPY of the reader with the truncating `||` restored on
# one hop and requires the citation to be LOST. A breaker keyed on a field would pass a refactor
# that keeps the shape and reintroduces the bug, which is the failure mode this row exists to
# catch.
cmd_verify_corpus_boundary() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/attributed-work.sh"
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _resid="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/unattributed-work.sh"
    _state="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-direction-health.sh"
    for _f in "$_reader" "$_survey" "$_resid" "$_state" "$_step"; do
        [ -f "$_f" ] || emit_err "corpus_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _W="${_root}/.workaholic"
    mkdir -p "${_W}/strategies" "${_W}/feedbacks" "${_W}/missions/active/m-one" "${_W}/tickets/todo"
    printf -- '---\ntype: Feedback\n---\n\ncited\n' > "${_W}/feedbacks/20260101000000-a.md"
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
    # The citation and its hop-2 carrier. Both sort BEFORE the filler, so they land in an early
    # batch and the LAST batch matches nothing -- the exact shape that truncated.
    printf -- '---\ntype: Mission\ntitle: M One\nslug: m-one\nstatus: active\nfeedback: [20260101000000-a.md]\n---\n\n# M One\n' \
        > "${_W}/missions/active/m-one/mission.md"
    printf -- '---\nmission: m-one\n---\n\n# T1\n' > "${_W}/tickets/todo/20260102000000-t1.md"

    # Grow the filler until the corpus genuinely spans more than one batch. The probe walks
    # exactly the corpus the reader builds and counts how many times `xargs` invokes its
    # command -- the line count IS the batch count. Each `find` carries `|| :` for the reason
    # the reader's own corpus build does: an area that does not exist yet makes `find` exit
    # non-zero, and under `set -e` that aborts the group before the SECOND find runs, leaving
    # a probe that reports one batch over any corpus at all.
    _batches() {
        { find "${_W}/missions/active" "${_W}/missions/archive" -mindepth 2 -maxdepth 2 \
               -name mission.md -type f 2>/dev/null || :
          find "${_W}/tickets/todo" "${_W}/tickets/archive" -name '*.md' -type f 2>/dev/null || :
        } | sort -u | xargs sh -c 'echo b' sh 2>/dev/null | wc -l | tr -d ' '
    }
    _pad=$(printf 'z%.0s' $(seq 1 180) 2>/dev/null || printf 'zzzzzzzzzzzzzzzzzzzz')
    _n=0
    while [ "$(_batches)" -lt 2 ] && [ "$_n" -lt 20000 ]; do
        _i=0
        while [ "$_i" -lt 200 ]; do
            printf -- '---\n---\n\n# f\n' > "${_W}/tickets/todo/zz-filler-${_n}-${_pad}.md"
            _n=$((_n + 1)); _i=$((_i + 1))
        done
    done
    _open="${_root}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    ( cd "$_root" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true

    if [ "$(_batches)" -ge 2 ]; then
        add_row "corpus_spans_more_than_one_batch" true "the fixture corpus splits into $(_batches) xargs batches after ${_n} filler files" load
    else
        add_row "corpus_spans_more_than_one_batch" false "the fixture never crossed the batching boundary, so every row below proves nothing" load
    fi

    # BOTH HOPS ACROSS THE BOUNDARY. Hop 1 is the mission, hop 2 the ticket naming it.
    _work=$(cd "$_root" && sh "$_reader" dir1 "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_work" | grep -q '"attribution":"direct"' \
        && printf '%s' "$_work" | grep -q '"attribution":"via_mission:m-one"' \
        && ! printf '%s' "$_work" | grep -q 'no_citing_artifacts'; then
        add_row "corpus_both_hops_attribute" true "a citation in an early batch survives a later batch that matches nothing, at both hops" load
    else
        add_row "corpus_both_hops_attribute" false "the walk lost its citations past the boundary: $(one_line "$_work")" load
    fi

    # THE BREAKER. A COPY of the reader with the truncating `||` restored on hop 1 must LOSE the
    # citation. Written against the behaviour, so a refactor that keeps the output shape and
    # reintroduces the truncation still fires it.
    _broke=$(mktemp -d)
    cp -r "${REPO_ROOT}/plugins" "${_broke}/plugins"
    _bfile="${_broke}/plugins/workaholic/skills/strategy/scripts/attributed-work.sh"
    sed 's|^prefilter "${TMP}/patterns" "${TMP}/corpus" "${TMP}/cand1"$|xargs grep -lFf "${TMP}/patterns" < "${TMP}/corpus" 2>/dev/null > "${TMP}/cand1" \|\| : > "${TMP}/cand1"|' \
        "$_bfile" > "${_broke}/b.sh" && mv "${_broke}/b.sh" "$_bfile"
    _bwork=$(cd "$_root" && sh "$_bfile" dir1 "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_bwork" | grep -q 'no_citing_artifacts'; then
        add_row "corpus_batching_tolerance_holds" true "restoring the truncating branch on hop 1 loses the citation -- this drill can fail" breaker
    else
        add_row "corpus_batching_tolerance_holds" false "the truncating branch did not lose the citation, so this row proves nothing: $(one_line "$_bwork")" breaker
    fi

    # AND THE SAME BREAKER ON HOP 2, SEPARATELY. Reverting hop 1 hides hop 2 behind it -- with
    # no attributed mission there is nothing for the second hop to walk -- so a single breaker
    # would leave the larger loss untested. Hop 2 carries EVERY ticket via_mission attribution,
    # so this half is the one that matters most.
    _broke2=$(mktemp -d)
    cp -r "${REPO_ROOT}/plugins" "${_broke2}/plugins"
    _b2file="${_broke2}/plugins/workaholic/skills/strategy/scripts/attributed-work.sh"
    sed 's|^    prefilter "${TMP}/mission-slugs" "${TMP}/corpus" "${TMP}/cand2"$|    xargs grep -lFf "${TMP}/mission-slugs" < "${TMP}/corpus" 2>/dev/null > "${TMP}/cand2" \|\| : > "${TMP}/cand2"|' \
        "$_b2file" > "${_broke2}/b.sh" && mv "${_broke2}/b.sh" "$_b2file"
    _b2work=$(cd "$_root" && sh "$_b2file" dir1 "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_b2work" | grep -q '"attribution":"direct"' \
        && ! printf '%s' "$_b2work" | grep -q 'via_mission:m-one'; then
        add_row "corpus_batching_tolerance_holds_on_hop_2" true "restoring the truncating branch on hop 2 loses the via_mission attribution while hop 1 survives -- this drill can fail on either hop" breaker
    else
        add_row "corpus_batching_tolerance_holds_on_hop_2" false "reverting hop 2 did not lose its attribution, so this row proves nothing: $(one_line "$_b2work")" breaker
    fi

    # THE CHAIN, HEALTHY. An unrefused row with real waiting grains, a residue that does not name
    # the citing mission, and no arrival question asked about work the tree attributes.
    _surv=$(cd "$_root" && sh "$_survey" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_surv" | grep -q '"reason":"work_waiting"' \
        && ! printf '%s' "$_surv" | grep -q 'attribution_unreadable'; then
        add_row "corpus_survey_row_is_real" true "the survey brakes on the direction own work in flight, read across the boundary" load
    else
        add_row "corpus_survey_row_is_real" false "the survey row was not derived from a completed walk: $(one_line "$_surv")" load
    fi
    _res=$(cd "$_root" && sh "$_resid" --root "$_W" 2>&1) || true
    if printf '%s' "$_res" | grep -q '"readable": *true' \
        && ! printf '%s' "$_res" | grep -q '"slug": *"m-one"'; then
        add_row "corpus_residue_excludes_the_citing_mission" true "the residue does not name a mission the tree attributes" load
    else
        add_row "corpus_residue_excludes_the_citing_mission" false "the residue named attributed work: $(one_line "$_res")" load
    fi
    _q=$(cd "$_root" && sh "$_step" --tick 20260101-000000 --root "$_root" --open-proposals "$_open" 2>&1) || true
    if printf '%s' "$_q" | grep -q 'direction-arrived:dir1'; then
        add_row "corpus_no_arrival_over_attributed_work" false "an arrival question was asked over work the tree attributes: $(one_line "$_q")" load
    else
        add_row "corpus_no_arrival_over_attributed_work" true "no arrival question is asked about work the tree attributes" load
    fi

    # THE DEGRADED DIRECTION. One corpus entry the walk cannot hand to `grep` -- a path with a
    # space, which `xargs` splits into two non-existent paths. A permission bit is not usable:
    # this drill routinely runs as uid 0, where `chmod 000` still reads fine.
    printf -- '---\n---\n\n# unconsumable\n' > "${_W}/tickets/todo/has space.md"
    ( cd "$_root" && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm blind ) >/dev/null 2>&1 || true
    _dwork=$(cd "$_root" && sh "$_reader" dir1 "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_dwork" | grep -q '"readable": false' \
        && printf '%s' "$_dwork" | grep -q '"reason": "corpus_unreadable"' \
        && ! printf '%s' "$_dwork" | grep -q 'no_citing_artifacts'; then
        add_row "corpus_degraded_names_its_reason" true "a walk that could not read reports its reason and never no_citing_artifacts" load
    else
        add_row "corpus_degraded_names_its_reason" false "a degraded walk was not named: $(one_line "$_dwork")" load
    fi
    _dsurv=$(cd "$_root" && sh "$_survey" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_dsurv" | grep -q '"reason":"attribution_unreadable"' \
        && printf '%s' "$_dsurv" | grep -q '"selected":\[\]'; then
        add_row "corpus_degraded_refuses_the_row" true "the survey refuses the row and selects nothing off a walk it could not complete" load
    else
        add_row "corpus_degraded_refuses_the_row" false "the survey did not refuse a degraded row: $(one_line "$_dsurv")" load
    fi
    _dres=$(cd "$_root" && sh "$_resid" --root "$_W" 2>&1) || true
    if printf '%s' "$_dres" | grep -q '"readable": *false' \
        && printf '%s' "$_dres" | grep -q '"mission_count": *null'; then
        add_row "corpus_degraded_residue_lists_nothing" true "the residue names nothing and reports null counts off a blind walk" load
    else
        add_row "corpus_degraded_residue_lists_nothing" false "the residue was rendered off a blind walk: $(one_line "$_dres")" load
    fi
    _dq=$(cd "$_root" && sh "$_step" --tick 20260101-000000 --root "$_root" --open-proposals "$_open" 2>&1) || true
    if printf '%s' "$_dq" | grep -q 'direction-arrived:dir1'; then
        add_row "corpus_degraded_asks_no_arrival" false "an arrival question was asked over a tree the loop could not read: $(one_line "$_dq")" load
    else
        add_row "corpus_degraded_asks_no_arrival" true "no arrival question is produced from a walk that did not complete" load
    fi

    # IT WROTE NOTHING IN THE CHECKOUT. Every fixture is outside it.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "corpus_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "corpus_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_root" "$_broke" "$_broke2"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "corpus-boundary" 0 "fail" 1
    fi
    emit_verdict "corpus-boundary" 0 "pass" 0
}

# --------------------------------------------------------------- verify-expiry
# Does the loop warn a direction BEFORE its own date silences it? Every reading in the direction
# layer answers backwards — `late`, `overdue`, `dormant`, `arrived` — so a live, in-date,
# `on_course` direction one day from its `target_date` produced no reading and no question
# anywhere, and the day after, `past_target_date` refused the proposal with the only signal being
# `direction-overdue`, asked in arrears. These rows answer it on demand rather than by waiting
# for a date to arrive.
#
# NO NETWORK AND NO CREDENTIAL. The survey's one remote read is the open-proposal gate, and it is
# SUPPLIED through `--open-proposals` exactly as `verify-arrival` supplies it, so the drilled path
# is the real one. The fixture is git-backed for the same reason: `landed[]` is a `git log
# --since` read, and a bare file tree would make every direction here read `dormant`.
#
# THE DATES COME FROM THE RUN CLOCK, never hard-coded. A drill whose fixture dates are literals
# rots the moment those dates pass, and this is the one drill whose whole subject is a date.
#
# THE BREAKER ROW IS `expiry_window_is_the_surveys_own`. It reads the same fixture through a
# NARROWER window and requires the reading to narrow with it. Wire the window to a fresh constant
# — the one shortcut the design exists to refuse, because a new number is one nobody can defend —
# and that row fires while every other row here stays green.
cmd_verify_expiry() {
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _reader="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-direction-health.sh"
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    for _f in "$_survey" "$_reader" "$_step" "$_ask"; do
        [ -f "$_f" ] || emit_err "expiry_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _root=$(mktemp -d)
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _soon=$(date -u -d "+2 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _week=$(date -u -d "+7 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _past=$(date -u -d "-30 days" +%Y-%m-%d 2>/dev/null || echo 2000-01-01)
    _W="${_root}/.workaholic"
    mkdir -p "${_W}/strategies" "${_W}/feedbacks" "${_W}/missions/active" \
             "${_W}/missions/archive" "${_W}/tickets/todo"
    for _r in a b c d e; do
        printf -- '---\ntype: Feedback\n---\n\nx\n' > "${_W}/feedbacks/2026010100000${_r}-${_r}.md"
    done
    _mkst() { # slug target feedback-ref
        cat > "${_W}/strategies/$1.md" <<EOF
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
        mkdir -p "${_W}/missions/$3/$1"
        printf -- '---\ntype: Mission\ntitle: M %s\nslug: %s\nstatus: %s\nfeedback: [%s]\n---\n\n# M %s\n' \
            "$1" "$1" "$2" "$4" "$1" > "${_W}/missions/$3/$1/mission.md"
    }
    # `soon` is the reading under test: inside the window, running, with work in flight -- the
    # ordinary shape of a direction about to run out of date.
    _mkst soon     "$_soon" 2026010100000a-a.md
    _mkmission landed-a  achieved archive 2026010100000a-a.md
    _mkmission inflight-a active  active  2026010100000a-a.md
    printf -- '---\nmission: inflight-a\n---\n\n# Q\n' > "${_W}/tickets/todo/20260101000001-qa.md"
    # `later` has runway left and must read exactly as it did before this reading existed.
    _mkst later    "$_far"  2026010100000b-b.md
    _mkmission landed-b   achieved archive 2026010100000b-b.md
    _mkmission inflight-b active   active  2026010100000b-b.md
    printf -- '---\nmission: inflight-b\n---\n\n# Q\n' > "${_W}/tickets/todo/20260101000002-qb.md"
    # `gone` is past its date: the arrears signal, unchanged.
    _mkst gone     "$_past" 2026010100000c-c.md
    # `finished` is inside the window AND quiescent: `arrived` outranks `expiring`, because the
    # two ask a person for different acts.
    _mkst finished "$_soon" 2026010100000d-d.md
    _mkmission landed-d achieved archive 2026010100000d-d.md
    # `boundary` is the breaker row's subject: a week out, inside a 14-day window and outside a
    # 3-day one.
    _mkst boundary "$_week" 2026010100000e-e.md
    _open="${_root}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    ( cd "$_root" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true

    _state=$(cd "$_root" && sh "$_reader" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    # PARSES THE ROW, NOT THE LINE -- `verify-arrival`'s extractor and its reason: a nested
    # object on the row silently defeats a line pattern.
    _stateof() { printf '%s' "$_state" | jq -r --arg s "$1" \
        '(.strategies // []) | map(select(.slug == $s)) | (first // {}) | .state // ""' 2>/dev/null | head -1; }
    _landedof() { printf '%s' "$_state" | jq -r --arg s "$1" \
        '(.strategies // []) | map(select(.slug == $s)) | (first // {}) | .landed // 0' 2>/dev/null | head -1; }

    # THE FIXTURE HAS TO BE THE SHAPE UNDER TEST. Without landed work every direction here reads
    # `dormant` and every row below would pass for the wrong reason.
    if [ "$(_landedof soon)" != "0" ] && [ -n "$(_landedof soon)" ]; then
        add_row "expiry_fixture" true "the fixture really produces attributed work inside the window ($(_landedof soon) item(s))" load
    else
        add_row "expiry_fixture" false "no attributed work landed in the fixture, so no reading below would prove anything: $(one_line "$_state")" load
        rm -rf "$_root"
        emit_verdict "expiry" 0 "fail" 1
    fi

    # THE THREE READINGS, plus the precedence pair a severity ordering would get wrong.
    for _pair in "soon:expiring" "later:live" "gone:overdue" "finished:arrived"; do
        _slug=${_pair%%:*}; _want=${_pair#*:}
        _got=$(_stateof "$_slug")
        if [ "$_got" = "$_want" ]; then
            add_row "expiry_state_${_slug}" true "${_slug} reads ${_want}" load
        else
            add_row "expiry_state_${_slug}" false "expected ${_want} for ${_slug}, got '${_got:-nothing}': $(one_line "$_state")" load
        fi
    done

    # THE BREAKER ROW. The window is the survey-s own `$window_days`, so a narrower window must
    # narrow the reading with it. A fresh constant here would keep `boundary` expiring at every
    # window and every other row in this drill would still pass.
    _narrow=$(cd "$_root" && sh "$_reader" --open-proposals "$_open" "3 days ago" "$_W" 2>&1) || true
    _nb=$(printf '%s' "$_narrow" | jq -r '(.strategies // []) | map(select(.slug == "boundary")) | (first // {}) | .state // ""' 2>/dev/null | head -1)
    _wb=$(_stateof boundary)
    if [ "$_wb" = "expiring" ] && [ "$_nb" != "expiring" ]; then
        add_row "expiry_window_is_the_surveys_own" true "a direction a week out is expiring at 14 days and '${_nb}' at 3 -- the window is the survey-s own, not a constant, and this drill can fail" breaker
    else
        add_row "expiry_window_is_the_surveys_own" false "the window did not move the reading: 14 days gave '${_wb}', 3 days gave '${_nb}'" breaker
    fi

    # THE QUESTION. Its key is what the asked-once ledger keys on, so a key that drifts is a
    # question asked twice or never; and a direction with runway must draw none.
    _out=$(cd "$_root" && sh "$_step" --tick 20260101-000000 --root "$_root" --open-proposals "$_open" 2>&1) || true
    _keys=$(printf '%s' "$_out" | tr ',' '\n' | sed -n 's/.*"key": *"\([^"]*\)".*/\1/p' | sort | tr '\n' ' ')
    if [ "$_keys" = "direction-arrived:finished direction-expiring:boundary direction-expiring:soon direction-overdue:gone " ]; then
        add_row "expiry_question_keys" true "the step asks direction-expiring for both directions inside the window and nothing about the live one" load
    else
        add_row "expiry_question_keys" false "unexpected question keys: '${_keys}'" load
    fi

    # A WARNING THAT DOES NOT SAY HOW LONG SOMEBODY HAS IS NOT A WARNING. The heading names the
    # days left and the date; the body names the act, inside notify-s 25-word bound.
    _ebody=$(printf '%s' "$_out" | sed -n 's/.*"body": *"\(Re-date it, announce a successor[^"]*\)".*/\1/p' | head -1)
    _ewords=$(printf '%s' "$_ebody" | wc -w | tr -d ' ')
    if printf '%s' "$_out" | grep -q "reaches its target date in 2 day(s) (${_soon})" \
        && [ -n "$_ebody" ] && [ "$_ewords" -le 25 ] \
        && printf '%s' "$_ebody" | grep -q 'decides nothing'; then
        add_row "expiry_question_names_the_date" true "the question names the days left and the date, and the act fits in ${_ewords} words" load
    else
        add_row "expiry_question_names_the_date" false "the expiry question is wrong (${_ewords} words): $(one_line "$_out")" load
    fi

    # THE LEAVING RIDES IT, exactly as it rides `arrived` and `overdue`: a person asked to
    # re-date a direction before its date needs the same evidence as one asked to close it after.
    if printf '%s' "$_out" | grep -q 'never reached: 1 mission(s), 1 ticket(s) still queued'; then
        add_row "expiry_names_the_leaving" true "the question names what the direction never reached" load
    else
        add_row "expiry_names_the_leaving" false "the leaving did not reach the question: $(one_line "$_out")" load
    fi

    # THE ROOT LINE NAMES A REPOSITORY EVENT and links the directions it names. The link list is
    # bounded at three with the rest counted, so the row asserts that a link is there rather than
    # naming one that the bound may have cut.
    if printf '%s' "$_out" | grep -q 'about to reach' \
        && printf '%s' "$_out" | grep -q 'strategies/boundary.md'; then
        add_row "expiry_event" true "the tick reports the approaching date as a repository event and links the direction" load
    else
        add_row "expiry_event" false "the reading did not reach the root: $(one_line "$_out")" load
    fi

    # ASKED ONCE. The gate is the check-in-s, not this step-s, so the drill exercises the gate
    # with this step-s new key: the first ask is allowed, the second refused by name.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _a1=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-000000 --key "direction-expiring:soon" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260101-000000 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_ask" --tick 20260101-010000 --key "direction-expiring:soon" --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "expiry_asked_once" true "the same key is refused on a later tick: $(printf '%s' "$_a2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "expiry_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "expiry_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi

    # NO READING RE-DATES, CLOSES OR AMENDS A DIRECTION, and the writer set is still three. A
    # reading that a direction is about to expire is one small step from a routine that re-dates
    # it, which is exactly what this row refuses.
    _closure=$(sed 's/^[[:space:]]*#.*$//' "$_step" "$_reader")
    if printf '%s' "$_closure" | grep -q 'close\.sh\|amend\.sh\|create\.sh'; then
        add_row "expiry_writes_no_direction" false "the closure reaches a strategy writer" load
    else
        add_row "expiry_writes_no_direction" true "neither the step nor the reader can reach create.sh, amend.sh or close.sh" load
    fi
    _seeded=$(cd "$_root" && git status --porcelain -- .workaholic/strategies | tr -d '\n')
    if [ -z "$_seeded" ]; then
        add_row "expiry_fixtures_intact" true "the seeded strategies area is untouched by the reader and the step" load
    else
        add_row "expiry_fixtures_intact" false "the fixture strategies area changed: '${_seeded}'" load
    fi

    # IT WROTE NOTHING IN THE CHECKOUT. Every fixture is outside it.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "expiry_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "expiry_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_root" "$_qroot"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "expiry" 0 "fail" 1
    fi
    emit_verdict "expiry" 0 "pass" 0
}

# --------------------------------------------------------------- verify-rulings
# Does a standing ruling reach the operator as a DIFF THEY MERGE rather than as an hourly
# question naming a repair to perform by hand on `main`? Two rulings stand that the loop cannot
# make itself — which direction an unattributed mission answers, and which account an unmapped
# address belongs to — and both were surfaced as a question whose repair was a hand edit of the
# base, the one act this repository still left to a person editing `main` directly.
#
# NO NETWORK AND NO CREDENTIAL. The whole path runs against a BARE LOCAL ORIGIN with `gh`
# stubbed, and the stub answers a SUCCESSFUL merge on purpose — a stub that refused would let
# the seam's refusal below pass for the wrong reason. The fixture is git-backed because the
# publish seam clones the base and pushes a branch to it.
#
# THE BREAKER ROW IS IN TWO HALVES, and the mission's safety rests on both:
#
#   `rulings_no_script_judges`  — the fixture holds EXACTLY ONE active direction beside EXACTLY
#                                 ONE unattributed mission, which is the shape an inference
#                                 would resolve without being asked. Wire any inference into
#                                 the reader and this row fires.
#   `rulings_seam_never_merges` — `WORKAHOLIC_AUTO_MERGE=1` is SET. Delete the seam's refusal
#                                 and a machine merges the operator's ruling; an unset variable
#                                 would let that pass unnoticed.
cmd_verify_rulings() {
    _list="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/list-standing-rulings.sh"
    _draft="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/draft-standing-rulings.sh"
    _stepr="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-standing-rulings.sh"
    _stepu="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh"
    _carry="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/carry-attribution.sh"
    for _f in "$_list" "$_draft" "$_stepr" "$_stepu" "$_carry"; do
        [ -f "$_f" ] || emit_err "rulings_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _bin="${_tmp}/bin"; _ctl="${_tmp}/ctl"
    mkdir -p "$_bin" "$_ctl"
    : > "${_ctl}/open.tsv"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)

    # The stub: `gh api user`, the pull-request POST, a SUCCESSFUL merge, and the open-pull
    # listing the brake reads — the last driven by a file this drill flips between rows.
    cat > "${_bin}/gh" <<STUB
#!/bin/sh
case "\$1 \$2" in
  "api user") printf 'tester\n'; exit 0 ;;
esac
case "\$*" in
  *pulls*POST*)
      # The payload arrives on stdin (`--input -`). Captured rather than discarded so the
      # drafter -> BODY -> reader chain can be closed below; without it the markers were only
      # ever asserted from a hand-written fixture.
      cat > "${_ctl}/pr_post.json" 2>/dev/null || true
      echo '{"html_url":"https://drill.invalid/pr/1","number":1}'; exit 0 ;;
  *merge*) echo '{"merged":true}'; exit 0 ;;
  *pulls?state=open*) cat "${_ctl}/open.tsv" 2>/dev/null; exit 0 ;;
esac
echo ""
STUB
    chmod +x "${_bin}/gh"

    git -c init.defaultBranch=main init -q --bare "$_origin" >/dev/null 2>&1 || true
    git clone -q "$_origin" "$_work" >/dev/null 2>&1 || true
    ( cd "$_work" && git config user.email "$_me" && git config user.name Drill \
      && git config commit.gpgsign false ) >/dev/null 2>&1 || true
    _W="${_work}/.workaholic"
    mkdir -p "${_W}/strategies" "${_W}/feedbacks" "${_W}/missions/active/orphan" \
             "${_W}/missions/archive/landed" "${_W}/tickets/todo" \
             "${_W}/tickets/archive/work-x" "${_work}/.claude"
    printf -- '---\ntype: Feedback\n---\n\nthe direction grew from this\n' > "${_W}/feedbacks/20260101000000-a.md"
    printf -- '---\ntype: Feedback\n---\n\nnobody claims this\n'           > "${_W}/feedbacks/20260101000000-b.md"
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
    printf -- '---\ntype: Mission\ntitle: Landed\nslug: landed\nstatus: achieved\nfeedback: [20260101000000-a.md]\n---\n\n# Landed\n' \
        > "${_W}/missions/archive/landed/mission.md"
    printf -- '---\nmission: landed\nstatus: done\n---\n\n# T1\n' > "${_W}/tickets/archive/work-x/20260101000001-t1.md"
    # EXACTLY ONE unattributed active mission and EXACTLY ONE unmapped address: the shape an
    # inference would resolve unasked, which is what makes the breaker row below real.
    printf -- '---\ntype: Mission\ntitle: Orphan\nslug: orphan\nstatus: active\nfeedback: [20260101000000-b.md]\n---\n\n# Orphan\n' \
        > "${_W}/missions/active/orphan/mission.md"
    printf -- '---\nmission: orphan\nassignees: [stranger@example.com]\n---\n\n# T2\n' > "${_W}/tickets/todo/20260102000000-t2.md"
    printf -- '# <github-login>=<canonical-email>[,<alias-email>...]\nknown=%s\n' "$_me" > "${_work}/.claude/git-identities"
    printf 'seed\n' > "${_work}/README.md"
    ( cd "$_work" && git add -A && git commit -qm seed && git push -q origin main ) >/dev/null 2>&1 || true

    _draft_run() { ( cd "$_work" && PATH="${_bin}:$PATH" WORKAHOLIC_AUTO_MERGE=1 sh "$_draft" "$@" ) 2>/dev/null || true; }

    # 1. THE SET IS READ, WITH ITS EVIDENCE AND ITS REPAIR, AND NOTHING IS JUDGED.
    _r=$(cd "$_work" && sh "$_list" --root "$_W" 2>&1) || true
    if printf '%s' "$_r" | grep -q '"subject": *"orphan"' \
        && printf '%s' "$_r" | grep -q '"subject": *"stranger@example.com"' \
        && printf '%s' "$_r" | grep -q '"readable": *true'; then
        add_row "rulings_read_names_both_kinds" true "one attribution and one mapping candidate, each with its evidence and repair" load
    else
        add_row "rulings_read_names_both_kinds" false "the standing rulings were not both named: $(one_line "$_r")" load
    fi

    # THE BREAKER, HALF ONE. One direction, one unattributed mission — and still `undecided`.
    if printf '%s' "$_r" | grep -q 'carry-attribution.sh <strategy> orphan' \
        && printf '%s' "$_r" | grep -q '"repair": *"<login>=stranger@example.com"' \
        && ! printf '%s' "$_r" | grep -q '"decision": *"dir1"'; then
        add_row "rulings_no_script_judges" true "with one direction and one orphan the reader still answers undecided and leaves both placeholders" breaker
    else
        add_row "rulings_no_script_judges" false "a script judged a ruling on its own: $(one_line "$_r")" breaker
    fi

    # 2. A JUDGED SET LANDS AS ONE PULL REQUEST — AND THE SEAM REFUSES TO MERGE IT.
    _d=$(_draft_run --judgement orphan=dir1 --judgement "stranger@example.com=stranger")
    if printf '%s' "$_d" | grep -q '"merge_reason": *"ruling_touching"' \
        && printf '%s' "$_d" | grep -q '"merged": *false' \
        && printf '%s' "$_d" | grep -q '"published": *true'; then
        add_row "rulings_seam_never_merges" true "a ruling is left open even with WORKAHOLIC_AUTO_MERGE=1 set" breaker
    else
        add_row "rulings_seam_never_merges" false "a ruling was not held open: $(one_line "$_d")" breaker
    fi
    if printf '%s' "$_d" | grep -q '"status": *"carried"' \
        && printf '%s' "$_d" | grep -q '"status": *"mapped"' \
        && printf '%s' "$_d" | grep -q '"drafted": *2'; then
        add_row "rulings_both_kinds_drafted" true "the attribution and the mapping ride one diff" load
    else
        add_row "rulings_both_kinds_drafted" false "the two kinds did not land together: $(one_line "$_d")" load
    fi

    # 2b. THE MARKERS REACH THE PULL-REQUEST BODY, AND THE READER FINDS THEM THERE
    #     (2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`). They were
    #     composed into `changes` — argument 3 — which `publish-tree-pr.sh` forwards to the
    #     COMMIT MESSAGE and never writes into the body, so `list-open-rulings.sh` read the body
    #     and found none and every open ruling held nothing. Measured verbatim on #694. The rows
    #     below drove `open.tsv` from a hand-written fixture, which is exactly why they passed
    #     with the defect in place; the marker field is now derived from the captured body.
    _pr_body=$(jq -r '.body // ""' "${_ctl}/pr_post.json" 2>/dev/null || printf '')
    _pr_markers=$(printf '%s\n' "$_pr_body" | grep '^ruling: ' || true)
    _pr_marker_field=$(printf '%s' "$_pr_markers" | tr '\n' ';' | sed 's/;$//')
    if printf '%s' "$_pr_markers" | grep -q 'subject: orphan' \
        && printf '%s' "$_pr_markers" | grep -q 'subject: stranger@example.com'; then
        add_row "rulings_markers_reach_the_body" true \
            "the pull-request body carries one visible ruling: line per judged subject, so the reader can find them" load
    else
        add_row "rulings_markers_reach_the_body" false \
            "the body carries no markers -- they are in the commit message, so every open ruling holds nothing: $(one_line "$_pr_body")" load
    fi

    # 3. A SECOND TICK IS A NO-OP WHILE THE RULING IS OPEN. The brake is the open pull request
    # itself — no cursor anywhere — and the base is untouched until the operator merges.
    _base_map=$(cd "$_work" && git show origin/main:.claude/git-identities 2>/dev/null || true)
    # Derived from the captured body, never hand-written: that is what makes the rows below a
    # test of the chain rather than of this fixture.
    printf '1\thttps://drill.invalid/pr/1\t[Ruling] Standing rulings for the operator\t%s\n' \
        "$_pr_marker_field" > "${_ctl}/open.tsv"
    _s=$( ( cd "$_work" && PATH="${_bin}:$PATH" sh "$_stepr" --tick 20260101-000000 --root "$_work" ) 2>&1 || true )
    _base_map2=$(cd "$_work" && git show origin/main:.claude/git-identities 2>/dev/null || true)
    if printf '%s' "$_s" | grep -q '"needs_agent": \[\]' \
        && printf '%s' "$_s" | grep -q 'already open' \
        && [ "$_base_map" = "$_base_map2" ]; then
        add_row "rulings_second_tick_is_a_no_op" true "an open ruling drafts nothing and the mapping on the base gains no second line" load
    else
        add_row "rulings_second_tick_is_a_no_op" false "a second tick was not a no-op: $(one_line "$_s")" load
    fi

    # 4. THE SUBJECT THE RULING DOES NOT NAME STILL ASKS, AND SAYS WHY. An undecidable subject
    # going silent is the one failure a suppression must not cause.
    printf '1\thttps://drill.invalid/pr/1\t[Ruling] Standing rulings for the operator\truling: attribution / subject: orphan\n' \
        > "${_ctl}/open.tsv"
    _u=$( ( cd "$_work" && PATH="${_bin}:$PATH" sh "$_stepu" --tick 20260101-000000 --root "$_work" ) 2>&1 || true )
    if printf '%s' "$_u" | grep -q '"owner": *"stranger@example.com"' \
        && printf '%s' "$_u" | grep -q '"unjudged": *true' \
        && printf '%s' "$_u" | grep -q 'could not judge'; then
        add_row "rulings_undecided_still_asks" true "a subject the ruling does not name still draws its question and names why" load
    else
        add_row "rulings_undecided_still_asks" false "an unjudged subject went silent or said nothing: $(one_line "$_u")" load
    fi
    printf '1\thttps://drill.invalid/pr/1\t[Ruling] Standing rulings for the operator\truling: identity_mapping / subject: stranger@example.com\n' \
        > "${_ctl}/open.tsv"
    _u2=$( ( cd "$_work" && PATH="${_bin}:$PATH" sh "$_stepu" --tick 20260101-000000 --root "$_work" ) 2>&1 || true )
    if printf '%s' "$_u2" | grep -q '1 held by an open ruling' \
        && ! printf '%s' "$_u2" | grep -q '"owner": *"stranger@example.com"'; then
        add_row "rulings_named_subject_is_held" true "the question the diff already carries is held, and counted rather than dropped silently" load
    else
        add_row "rulings_named_subject_is_held" false "a named subject still drew its question: $(one_line "$_u2")" load
    fi
    : > "${_ctl}/open.tsv"

    # 5. EVERY REFUSAL OF THE ONE WRITER LEAVES THE TREE UNTOUCHED. Read over a plain fixture,
    # because what is asserted is that the file did not move.
    _F=$(mktemp -d)
    mkdir -p "${_F}/strategies" "${_F}/missions/active/orphan" "${_F}/missions/active/broken"
    cp "${_W}/strategies/dir1.md" "${_F}/strategies/dir1.md"
    printf -- '---\ntype: Strategy\ntitle: Bare\nslug: bare\nstatus: active\ntarget_date: %s\nassignees: [%s]\n---\n\n## Aim\n\na\n\n## Schedule\n\ns\n' \
        "$_far" "$_me" > "${_F}/strategies/bare.md"
    printf -- '---\ntype: Strategy\ntitle: Gone\nslug: gone\nstatus: achieved\ntarget_date: %s\nassignees: [%s]\nfeedback: [20260101000000-a.md]\n---\n\n## Aim\n\na\n\n## Schedule\n\ns\n' \
        "$_far" "$_me" > "${_F}/strategies/gone.md"
    printf -- '---\ntype: Mission\ntitle: Orphan\nslug: orphan\nstatus: active\nfeedback: [20260101000000-b.md]\n---\n\n# Orphan\n' \
        > "${_F}/missions/active/orphan/mission.md"
    printf -- '# Broken\n\nno frontmatter at all\n' > "${_F}/missions/active/broken/mission.md"
    _snap=$(find "$_F" -type f -exec cksum {} \; | sort)
    _refusals_ok=true
    _names=""
    for _pair in "nope orphan strategy_not_found" "dir1 nope mission_not_found" \
                 "gone orphan not_active" "bare orphan no_revision" "dir1 broken immutable_field"; do
        _st=$(printf '%s' "$_pair" | cut -d' ' -f1)
        _mi=$(printf '%s' "$_pair" | cut -d' ' -f2)
        _rs=$(printf '%s' "$_pair" | cut -d' ' -f3)
        _o=$(cd "$_F" && sh "$_carry" "$_st" "$_mi" "$_F" 2>&1) || true
        printf '%s' "$_o" | grep -q "\"reason\": *\"${_rs}\"" || { _refusals_ok=false; _names="${_names} ${_rs}"; }
    done
    _snap2=$(find "$_F" -type f -exec cksum {} \; | sort)
    if [ "$_refusals_ok" = true ] && [ "$_snap" = "$_snap2" ]; then
        add_row "rulings_refusals_write_nothing" true "all five refusals are named and none of them wrote" load
    else
        add_row "rulings_refusals_write_nothing" false "a refusal was misnamed or wrote:${_names:-" the tree moved"}" load
    fi

    # 6. AN ABSENT MAPPING IS A BOOTSTRAP REPAIR, NOT A RULING — refused by name, writing nothing.
    _o2="${_tmp}/origin2"; _w2="${_tmp}/work2"
    git -c init.defaultBranch=main init -q --bare "$_o2" >/dev/null 2>&1 || true
    git clone -q "$_o2" "$_w2" >/dev/null 2>&1 || true
    ( cd "$_w2" && git config user.email "$_me" && git config user.name Drill \
      && git config commit.gpgsign false ) >/dev/null 2>&1 || true
    mkdir -p "${_w2}/.workaholic"
    cp -r "${_W}/." "${_w2}/.workaholic/"
    printf 'seed\n' > "${_w2}/README.md"
    ( cd "$_w2" && git add -A && git commit -qm seed && git push -q origin main ) >/dev/null 2>&1 || true
    _d2=$( ( cd "$_w2" && PATH="${_bin}:$PATH" WORKAHOLIC_AUTO_MERGE=1 \
        sh "$_draft" --judgement "stranger@example.com=stranger" ) 2>/dev/null || true )
    if printf '%s' "$_d2" | grep -q '"status": *"no_mapping_file"' \
        && printf '%s' "$_d2" | grep -q '"drafted": *0'; then
        add_row "rulings_absent_mapping_refuses" true "an absent mapping is a bootstrap repair and drafts nothing" load
    else
        add_row "rulings_absent_mapping_refuses" false "an absent mapping was not refused by name: $(one_line "$_d2")" load
    fi

    # 7. IT WROTE NOTHING IN THE CHECKOUT. Every fixture is outside it.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "rulings_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "rulings_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp" "$_F"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "rulings" 0 "fail" 1
    fi
    emit_verdict "rulings" 0 "pass" 0
}

# ------------------------------------------------------------ verify-succession
# Can a direction's END be a turn of the loop rather than its stop? Every reading in the
# direction layer is bounded to `status: active`, so closing the last live direction leaves
# the loop originating nothing: `/propose` refuses `not_active`, the inbox empties, and the
# only signal is `direction-none`, addressed to nobody.
#
# THE WALK IS SIX SEAMS AND NO SINGLE UNIT TEST CROSSES THEM: close a direction -> read what
# it leaves -> announce a successor by explicit slug -> the predecessor's own refs land on the
# successor -> `attributed-work.sh` attributes the predecessor's work to it -> `/propose`
# proposes against it on the next tick.
#
# NO NETWORK AND NO CREDENTIAL. The survey's one remote read is the open-proposal gate and it
# is SUPPLIED through `--open-proposals`, exactly as `verify-arrival` and `verify-residue`
# supply it; the publish row stubs `gh` against a bare local origin. The fixture is git-backed
# for the same reason theirs are: `landed[]` is a `git log --since` read, and a bare file tree
# would make the attribution rows vacuously true.
#
# THE BREAKER ROW IS `succession_carry_is_wired_at_the_ask_line`. Wiring the carry INSIDE
# `create.sh` is the one edit that would keep every other row here green while giving the
# strategy artifact's writer a second job — and it is proved able to fire, against a copy of
# `create.sh` with the succession wired into it.
cmd_verify_succession() {
    _create="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/create.sh"
    _close="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/close.sh"
    _line="${REPO_ROOT}/plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh"
    _leaving="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/closing-residue.sh"
    _attr="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/attributed-work.sh"
    _state="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts/direction-state.sh"
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _pub="${REPO_ROOT}/plugins/workaholic/skills/branching/scripts"
    _flow="${REPO_ROOT}/plugins/workaholic/skills/specificate/reference/workflow.md"
    for _f in "$_create" "$_close" "$_line" "$_leaving" "$_attr" "$_state" "$_survey" "$_flow"; do
        [ -f "$_f" ] || emit_err "succession_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _root="${_tmp}/repo"
    _bin="${_tmp}/bin"; mkdir -p "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _past=$(date -u -d "-10 days" +%Y-%m-%d 2>/dev/null || echo 2026-01-01)
    _far=$(date -u -d "+300 days" +%Y-%m-%d 2>/dev/null || echo 2099-01-01)
    _W="${_root}/.workaholic"
    mkdir -p "${_W}/strategies" "${_W}/feedbacks" "${_W}/missions/active/orphan" \
             "${_W}/missions/archive/landed" "${_W}/tickets/todo" "${_W}/tickets/archive/work-x"
    printf -- '---\ntype: Feedback\n---\n\nthe direction grew from this\n' > "${_W}/feedbacks/20260101000000-a.md"
    printf -- '---\ntype: Feedback\n---\n\nnobody claims this\n'          > "${_W}/feedbacks/20260101000000-b.md"
    printf -- '---\ntype: Feedback\n---\n\nthe successor was announced by this\n' > "${_W}/feedbacks/20260201000000-c.md"
    cat > "${_W}/strategies/old.md" <<EOF
---
type: Strategy
title: T old
slug: old
status: active
target_date: ${_past}
assignees: [${_me}]
feedback: [20260101000000-a.md]
---

# old

## Aim

a

## Schedule

s
EOF
    printf -- '---\ntype: Mission\ntitle: Landed\nslug: landed\nstatus: achieved\nfeedback: [20260101000000-a.md]\n---\n\n# Landed\n' \
        > "${_W}/missions/archive/landed/mission.md"
    printf -- '---\nmission: landed\nstatus: done\n---\n\n# T1\n' > "${_W}/tickets/archive/work-x/20260101000001-t1.md"
    printf -- '---\ntype: Mission\ntitle: Orphan\nslug: orphan\nstatus: active\nfeedback: [20260101000000-b.md]\n---\n\n# Orphan\n' \
        > "${_W}/missions/active/orphan/mission.md"
    printf -- '---\nmission: orphan\n---\n\n# T2\n' > "${_W}/tickets/todo/20260102000000-t2.md"
    _open="${_tmp}/open.json"
    printf '{"ok": true, "identity": "drill", "slug": "o/n", "proposals": []}\n' > "$_open"
    ( cd "$_root" && git -c init.defaultBranch=main init -q . \
        && git config user.email "$_me" && git config user.name Drill \
        && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm seed ) >/dev/null 2>&1 || true

    # 1. THE LEAVING IS READABLE BEFORE THE DECISION. Three blocks, each from that fact's own
    # single reader, composed at the moment somebody is deciding whether to end the direction.
    _lv=$(cd "$_root" && sh "$_leaving" --open-proposals "$_open" old "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_lv" | grep -q '"readable": *true' \
        && printf '%s' "$_lv" | grep -q '"slug": *"orphan"' \
        && printf '%s' "$_lv" | grep -q '"exhaustive": *false'; then
        add_row "succession_leaving_before_the_close" true "the leaving names what it never reached, what no direction claimed, and its lifecycle reading" load
    else
        add_row "succession_leaving_before_the_close" false "the leaving was not composed: $(one_line "$_lv")" load
    fi

    # 2. THE CLOSE, AND THE LEAVING STILL READABLE AFTER IT. `direction-state.sh` is bounded to
    # the active set by design, so a closed direction reads `not_active` -- a real answer, not a
    # degradation, which is what lets `/specificate`'s *ended* route state anything at all.
    _cl=$(cd "$_root" && sh "$_close" old achieved "$_W" 2>&1) || true
    _lv2=$(cd "$_root" && sh "$_leaving" --open-proposals "$_open" old "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_lv2" | grep -q '"state": *"not_active"' \
        && printf '%s' "$_lv2" | grep -q '"readable": *true'; then
        add_row "succession_leaving_after_the_close" true "a closed direction reads not_active, readable -- never a degradation" load
    else
        add_row "succession_leaving_after_the_close" false "the leaving broke at the close: $(one_line "$_lv2") / $(one_line "$_cl")" load
    fi

    # 3. THE CARRY IS COMPOSED AT THE ASK LINE, by the one writer of that ref set, and handed to
    # `create.sh` as the argument it has always taken. Matching is by EXPLICIT SLUG: the
    # predecessor named here is `old`, and no title or paraphrase reaches this seam.
    _refs=$(sh "$_line" --refs-only 20260201000000-c.md 20260101000000-a.md 2>/dev/null || true)
    ( cd "$_root" && printf 'aim\n' | sh "$_create" "New" "$_far" "$_me" "sched" "$_refs" "$_W" ) >/dev/null 2>&1 || true
    if [ -f "${_W}/strategies/new.md" ] \
        && grep -q '^feedback: \[20260201000000-c.md, 20260101000000-a.md\]$' "${_W}/strategies/new.md"; then
        add_row "succession_carries_the_predecessor_refs" true "the successor cites the announcement and the predecessor's own records" load
    else
        add_row "succession_carries_the_predecessor_refs" false "the carry did not reach the successor: $(one_line "$_refs")" load
    fi

    # 4. NO FIELD, NO RELATION. The successor carries no `predecessor:`/`successor:` key and the
    # retired `strategy:` relation stays retired.
    if [ -f "${_W}/strategies/new.md" ] \
        && ! grep -qE '^(predecessor|successor|strategy):' "${_W}/strategies/new.md"; then
        add_row "succession_adds_no_field" true "the successor gained no field and revived no relation" load
    else
        add_row "succession_adds_no_field" false "an artifact gained a field for the succession" load
    fi

    # 5. THE ATTRIBUTION READS THROUGH THE SUCCESSION. The predecessor's landed work is the
    # successor's from its first hour, through the citation that already existed.
    ( cd "$_root" && git -c commit.gpgsign=false add -A \
        && git -c commit.gpgsign=false commit -qm successor ) >/dev/null 2>&1 || true
    _an=$(cd "$_root" && sh "$_attr" new "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_an" | grep -q '"slug": *"new"' \
        && printf '%s' "$_an" | grep -q 'missions/archive/landed/mission.md'; then
        add_row "succession_attribution_reads_through" true "the successor reads the predecessor's landed work as its own" load
    else
        add_row "succession_attribution_reads_through" false "the predecessor's work did not reach the successor: $(one_line "$_an")" load
    fi

    # 6. A FRESH SUCCESSOR IS NOT `dormant`. That is the reading the carry exists to prevent: a
    # direction born citing its predecessor's records is not one nothing is answering.
    _st=$(cd "$_root" && sh "$_state" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_st" | grep -q '"slug": *"new"' \
        && ! printf '%s' "$_st" | grep -q '"state": *"dormant"'; then
        add_row "succession_successor_is_not_dormant" true "a direction born carrying its predecessor's refs is not one nothing is answering" load
    else
        add_row "succession_successor_is_not_dormant" false "the fresh successor read dormant: $(one_line "$_st")" load
    fi

    # 7. `/propose` RESUMES AGAINST IT ON THE NEXT TICK. The whole point of the carry: the loop
    # keeps originating work across the boundary instead of going quiet at it.
    _sv=$(cd "$_root" && sh "$_survey" --open-proposals "$_open" "14 days ago" "$_W" 2>&1) || true
    if printf '%s' "$_sv" | grep -q '"selected": *\["new"\]'; then
        add_row "succession_propose_resumes" true "the next tick proposes against the successor -- the loop did not go quiet at the boundary" load
    else
        add_row "succession_propose_resumes" false "the successor was not proposed against: $(one_line "$_sv")" load
    fi

    # 8. THE BREAKER ROW. The carry lives at the ask line and NOT inside `create.sh` -- the one
    # edit that would keep every other row green while giving the artifact's writer a second
    # job. Proved able to fire: the same detection is run against a copy of `create.sh` with the
    # succession wired into it, and it must go red there.
    _wired="${_tmp}/create-wired.sh"
    cp "$_create" "$_wired"
    printf 'PREDECESSOR="${7:-}" # carry the predecessor refs\n' >> "$_wired"
    if ! grep -qiE 'predecessor|successor' "$_create" \
        && grep -q 'ask-feedback-line.sh' "$_flow" \
        && grep -qiE 'predecessor' "$_wired"; then
        add_row "succession_carry_is_wired_at_the_ask_line" true "the carry is composed at the ask line, create.sh knows nothing of it, and the detection fires on a wired copy" breaker
    else
        add_row "succession_carry_is_wired_at_the_ask_line" false "the carry reached create.sh, or the ask line no longer composes it" breaker
    fi

    # 9. NOTHING CLOSED A DIRECTION ON ITS OWN READING, AND NOTHING AUTHORED ONE. The readers in
    # this walk reach no writer of the strategy artifact; `close.sh` is reached by the
    # operator's announcement and by nothing here.
    _closure=$(cat "$_leaving" "$_state" 2>/dev/null | grep -v '^[[:space:]]*#' || true)
    if ! printf '%s' "$_closure" | grep -qE 'close\.sh|amend\.sh|create\.sh'; then
        add_row "succession_readers_reach_no_writer" true "the leaving and the lifecycle readers reach no writer of the artifact" load
    else
        add_row "succession_readers_reach_no_writer" false "a reader in this walk reaches a writer of the strategy artifact" load
    fi

    # 10. THE STRATEGY-TOUCHING PUBLISH DOES NOT AUTO-MERGE. The operator's merge is what
    # authors the artifact, and since 2026-08-27 that is the seam's refusal rather than the
    # caller's judgement -- a successor is a create, so it is covered by the same rule.
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
        cp "${_W}/strategies/new.md" .publish/.workaholic/strategies/new.md
        PATH="${_bin}:$PATH" WORKAHOLIC_AUTO_MERGE=1 sh "${_pub}/publish-tree-pr.sh" \
            "Propose strategy new" why None None None verify \
            .workaholic/strategies/new.md 2>/dev/null
        sh "${_pub}/close-publish-tree.sh" >/dev/null 2>&1 ) | grep '"merge_reason"' | tail -1 )
    if printf '%s' "$_pubout" | grep -q '"merge_reason": *"strategy_touching"' \
        && printf '%s' "$_pubout" | grep -q '"merged": *false'; then
        add_row "succession_publish_never_merges" true "a strategy-touching publish is left open even with WORKAHOLIC_AUTO_MERGE=1" load
    else
        add_row "succession_publish_never_merges" false "a strategy-touching publish was not held open: $(one_line "$_pubout")" load
    fi

    # 11. IT WROTE NOTHING IN THE CHECKOUT. Every fixture is outside it.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "succession_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "succession_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "succession" 0 "fail" 1
    fi
    emit_verdict "succession" 0 "pass" 0
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

# ------------------------------------------------------------- verify-claim-race
# TWO RUNS, ONE UNIT. Measured 2026-08-30: `work-20260830-055314` and `work-20260830-055318`
# were both claimed for `draft-a-dateless-direction-with-the-operator-s-one-week-default`,
# four seconds apart, and each drove the same four tickets for over an hour. Nothing in the
# suite or the drill set reproduced that, so any repair would have been judged against prose
# rather than against a red test.
#
# THE ORDERING IS THE FIXTURE'S, NEVER THE SCHEDULER'S. A race staged by wall-clock timing is
# flaky, and a flaky drill is a drill nobody believes. What makes the race possible is that
# each runner's `claims_scan` reads an origin that does not yet show the competitor's branch,
# so the fixture stages exactly those two views: runner A claims and pushes; A's ref is then
# taken OFF the bare origin with `update-ref` so runner B's scan legitimately sees nothing;
# B claims and pushes; A's ref is put back. Both runs are the real `claim.sh`, both really
# scanned, and neither was refused anything -- which is the race, with no sleep deciding it.
#
# WHAT IT ASSERTS, AND WHOSE TICKET EACH ROW IS. The race itself is still LIVE: the repair
# that would stop it (a claim contending for one ref per unit) is blocked on a measured
# transport refusal -- this container may write no ref outside `refs/heads/*` -- so the
# two-branches rows assert today's defect exactly as they were written. What the same mission
# did repair is downstream of it: the first write is refused rather than duplicated, and the
# loser is readable as `superseded` at the mission grain from the tree.
#
# NO NETWORK AT ANY POINT. A bare local origin, `gh` stubbed to an empty list, and a stubbed
# notifier, so `claim.sh`'s announcement cannot reach out either.
cmd_verify_claim_race() {
    _claimsh="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/claim.sh"
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _archive="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/archive.sh"
    _holder="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/claim-holder.sh"
    _retirable="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh"
    _lib="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/lib/claims.sh"
    for _f in "$_claimsh" "$_lister" "$_archive" "$_holder" "$_retirable" "$_lib"; do
        [ -f "$_f" ] || emit_err "claim_race_unreadable" 4 "$(basename "$_f") is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _seed="${_tmp}/seed"; _A="${_tmp}/A"; _B="${_tmp}/B"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    [ -n "$_me" ] || _me=drill@example.com

    # The transport, stubbed to answer NOTHING: no merged pull request, so the merged-lookup
    # fallback can never rescue a verdict the tree did not reach. That is what makes the
    # mission-grain rows below about the LOCAL test rather than about the network one.
    printf '#!/bin/sh\necho "[]"\n' > "${_bin}/gh"; chmod +x "${_bin}/gh"
    printf '#!/bin/sh\necho %s\n' '"{\"notified\": false, \"reason\": \"drill\"}"' > "${_bin}/notify"
    chmod +x "${_bin}/notify"
    _env="PATH=${_bin}:$PATH WORKAHOLIC_NOTIFIER=${_bin}/notify"

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) >/dev/null 2>&1 || true
    ( cd "$_tmp" && git clone -q "$_origin" seed ) >/dev/null 2>&1 || true
    mkdir -p "${_seed}/.workaholic/tickets/todo" "${_seed}/.workaholic/missions/active/raced"
    printf -- '---\ntype: Mission\ntitle: Raced\nslug: raced\nstatus: active\nassignees: [%s]\n---\n\n# Raced\n\n## Experience\n\nOne unit, two runners.\n\n## Acceptance\n\n- [ ] first\n' "$_me" \
        > "${_seed}/.workaholic/missions/active/raced/mission.md"
    for _n in 1 2; do
        printf -- '---\ncreated_at: 2026-08-30T00:00:0%s+00:00\nauthor: %s\nassignees: [%s]\nmission: raced\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_me" "$_n" > "${_seed}/.workaholic/tickets/todo/2026083000000${_n}-t${_n}.md"
    done
    ( cd "$_seed" && git config user.email "$_me" && git config user.name Drill \
      && git config commit.gpgsign false && git add -A && git commit -qm seed \
      && git push -q origin main ) >/dev/null 2>&1 || true

    for _c in A B; do
        ( cd "$_tmp" && git clone -q "$_origin" "$_c" ) >/dev/null 2>&1 || true
        ( cd "${_tmp}/${_c}" && git config user.email "$_me" && git config user.name Drill \
          && git config commit.gpgsign false ) >/dev/null 2>&1 || true
    done

    _claim() { # checkout -> the claim JSON
        ( cd "$1" && env $_env sh "$_claimsh" mission raced ) 2>/dev/null || true
    }
    _branch_of() { printf '%s' "$1" | sed -n 's/.*"branch": "\([^"]*\)".*/\1/p'; }
    _scan() { # checkout -> list-claims.sh JSON, with liveness collapsed so the verdict chain
              # reaches the gates this drill is about rather than stopping at `claim_active`
        ( cd "$1" && env $_env WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_lister" ) 2>&1 || true
    }
    _verdict() { # scan-json, branch
        printf '%s' "$1" | tr '{' '\n' | grep "\"branch\": \"$2\"" \
            | sed -n 's/.*"resume_reason": *"\([a-z_]*\)".*/\1/p' | head -1
    }

    # --- 1. STAGE THE RACE ------------------------------------------------------------
    _outA=$(_claim "$_A")
    _brA=$(_branch_of "$_outA")
    if [ -z "$_brA" ]; then
        add_row "claim_race_fixture" false "runner A could not claim at all: $(one_line "$_outA")" load
        rm -rf "$_tmp"
        emit_verdict "claim-race" 0 "fail" 1
    fi
    # A's ref comes OFF the origin, so B's scan sees the origin A saw. This is the whole
    # staging: no sleep, no concurrency, and both runs are the real claim act.
    _shaA=$( ( cd "$_origin" && git rev-parse "refs/heads/${_brA}" ) 2>/dev/null || true )
    ( cd "$_origin" && git update-ref -d "refs/heads/${_brA}" ) >/dev/null 2>&1 || true
    # One second so the clock-derived branch name differs; the ORDERING is already fixed by
    # the ref surgery above, and a same-second collision would be `branch_collision` -- the
    # narrower case this drill is deliberately not about.
    sleep 1
    _outB=$(_claim "$_B")
    _brB=$(_branch_of "$_outB")
    ( cd "$_origin" && git update-ref "refs/heads/${_brA}" "$_shaA" ) >/dev/null 2>&1 || true

    if [ -n "$_brB" ] && [ "$_brA" != "$_brB" ]; then
        add_row "claim_race_two_branches" true "two runners surveying before either pushed both claimed one unit: ${_brA} and ${_brB}" load
    else
        add_row "claim_race_two_branches" false "the race did not stage (A=${_brA}, B=${_brB}): $(one_line "$_outB")" load
        rm -rf "$_tmp"
        emit_verdict "claim-race" 0 "fail" 1
    fi

    ( cd "$_B" && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    _claims=$(_scan "$_B")
    _held=$(printf '%s' "$_claims" | tr '{' '\n' | grep -c '"unit": "raced"' || true)
    if [ "${_held:-0}" -eq 2 ]; then
        add_row "claim_race_one_unit_twice" true "the oracle reports one unit held by two branches" load
    else
        add_row "claim_race_one_unit_twice" false "expected the unit reported twice, got ${_held:-0}: $(one_line "$_claims")" load
    fi

    # --- 1b. THE RACE REACHES A PERSON, ONCE, WITH BOTH BRANCHES NAMED ----------------
    # Naming the state was never the whole repair: `ambiguous_claim` is refused by every
    # writer that meets it and, until 2026-08-30, asked about by NOBODY. These rows walk the
    # surface that now carries it -- reader, step, asked-once gate, sibling silence.
    _raced_reader="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-raced-units.sh"
    _raced_step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-raced-units.sh"
    _ask_sh="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"

    _raced=$( ( cd "$_B" && sh "$_raced_reader" ) 2>/dev/null || true )
    if printf '%s' "$_raced" | grep -q '"count": 1' \
        && printf '%s' "$_raced" | grep -q "\"${_brA}\"" \
        && printf '%s' "$_raced" | grep -q "\"${_brB}\""; then
        add_row "claim_race_reader_names_both" true "list-raced-units.sh names the raced unit and BOTH branches, never one of them" load
    else
        add_row "claim_race_reader_names_both" false "the reader did not name the raced pair: $(one_line "$_raced")" load
    fi

    # The step hands one question back, keyed on the unit, addressed to the claim holders.
    _raced_out=$( ( cd "$_B" && sh "$_raced_step" --tick 20260101-000000 --root "$_B" ) 2>/dev/null || true )
    if printf '%s' "$_raced_out" | grep -q '"status": "ok"' \
        && printf '%s' "$_raced_out" | grep -q 'raced-unit:raced' \
        && printf '%s' "$_raced_out" | grep -q "\"${_brA}\"" \
        && printf '%s' "$_raced_out" | grep -q "\"${_brB}\""; then
        add_row "claim_race_question_asked" true "one question, keyed raced-unit:raced, naming both branches" load
    else
        add_row "claim_race_question_asked" false "the step asked nothing usable: $(one_line "$_raced_out")" load
    fi

    # ASKED ONCE. The gate is the check-in's, exercised here with this step's key.
    _rqroot=$(mktemp -d); mkdir -p "${_rqroot}/.workaholic/moderations"
    _r1=$(cd "$REPO_ROOT" && sh "$_ask_sh" --tick 20260101-000000 --key "raced-unit:raced" \
        --root "$_rqroot" --to "racer@example.com" --hour 10 --weekday 1 2>&1) || true
    _rstep=$(printf '%s' "$_r1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_r1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_rqroot" \
           --tick 20260101-000000 --step "$_rstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _r2=$(cd "$REPO_ROOT" && sh "$_ask_sh" --tick 20260101-010000 --key "raced-unit:raced" \
            --root "$_rqroot" --to "racer@example.com" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_r2" | grep -q '"ask": false'; then
            add_row "claim_race_question_asked_once" true "the same key is refused on a later tick, so one raced unit costs one question" load
        else
            add_row "claim_race_question_asked_once" false "the asked-once gate did not hold: $(one_line "$_r2")" load
        fi
    else
        add_row "claim_race_question_asked_once" false "the first ask was refused: $(one_line "$_r1")" load
    fi
    rm -rf "$_rqroot"

    # THE SIBLING IS SILENT ON THE SAME UNIT, AND THE ASSERTION IS MADE TO BITE. One step
    # asks and the others filter and count; either half alone is a defect. `stalled-units`
    # is the sibling probed here because its candidate set can be reached in this fixture:
    # the raced claims are FRESH, so with the protocol's own threshold no sibling would list
    # them at all and the row would pass vacuously. `WORKAHOLIC_CLAIM_STALE_HOURS=0` puts
    # both rows squarely inside its candidate set, so the row fails the moment the filter is
    # removed. (`undelivered-units` and `catchup-blocked` carry the same filter through the
    # same shared helper; reaching their candidate sets would need a recorded merge refusal
    # and a real content conflict, which this fixture deliberately does not stage.)
    _sib_out=$( ( cd "$_B" && WORKAHOLIC_CLAIM_STALE_HOURS=0 \
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh" \
        --tick 20260101-000000 --root "$_B" ) 2>/dev/null || true )
    if printf '%s' "$_sib_out" | grep -q 'stalled-unit:raced'; then
        add_row "claim_race_siblings_filter" false "stalled-units still asks about the raced unit -- one unit, two questions, two vocabularies: $(one_line "$_sib_out")" load
    elif printf '%s' "$_sib_out" | grep -q 'held by two live claims'; then
        add_row "claim_race_siblings_filter" true "stalled-units asks nothing about the raced unit and counts it instead, with its candidate set forced to include it" load
    else
        add_row "claim_race_siblings_filter" false "stalled-units neither asked nor counted the raced unit: $(one_line "$_sib_out")" load
    fi

    # --- 2. THE FIRST WRITE IS REFUSED, WITH THE TREE BYTE-IDENTICAL -------------------
    # The window the claim protocol never closed: between a survey and the first write the
    # base will see. `archive.sh` re-derives the holder immediately before the ticket moves.
    _wtB="${_B}/.worktrees/raced"
    _dirtyB_before=$( ( cd "$_wtB" && git status --porcelain ) 2>/dev/null | sort )
    _headB_before=$( ( cd "$_wtB" && git rev-parse HEAD ) 2>/dev/null || true )
    _arch_out=$( ( cd "$_wtB" && env $_env sh "$_archive" \
        .workaholic/tickets/todo/20260830000001-t1.md "Drive the first ticket" \
        "https://example.invalid/r" "why" "None" "None" "None" "None" ) 2>&1 ) && _arch_rc=0 || _arch_rc=$?
    _dirtyB_after=$( ( cd "$_wtB" && git status --porcelain ) 2>/dev/null | sort )
    _headB_after=$( ( cd "$_wtB" && git rev-parse HEAD ) 2>/dev/null || true )
    if [ "$_arch_rc" -ne 0 ] && printf '%s' "$_arch_out" | grep -q 'ambiguous_claim'; then
        add_row "claim_race_archive_refuses" true "the first write refuses by its own word while two live claims hold the unit" load
    else
        add_row "claim_race_archive_refuses" false "the archive did not refuse (exit ${_arch_rc}): $(one_line "$_arch_out")" load
    fi
    if [ "$_dirtyB_before" = "$_dirtyB_after" ] && [ "$_headB_before" = "$_headB_after" ] \
       && [ -f "${_wtB}/.workaholic/tickets/todo/20260830000001-t1.md" ]; then
        add_row "claim_race_refusal_writes_nothing" true "the refused runner moved, staged and committed nothing" load
    else
        add_row "claim_race_refusal_writes_nothing" false "the refusal left the tree changed (head ${_headB_before} -> ${_headB_after})" load
    fi

    # --- 3. AND AN ORDINARY ARCHIVE IS UNTOUCHED --------------------------------------
    # The failure mode to avoid is a gate that refuses a LEGITIMATE archive: a wrong refusal
    # strands finished work outside the archive. With B's claim gone, A is the sole holder.
    ( cd "$_origin" && git update-ref -d "refs/heads/${_brB}" ) >/dev/null 2>&1 || true
    _wtA="${_A}/.worktrees/raced"
    _arch_ok=$( ( cd "$_wtA" && env $_env sh "$_archive" \
        .workaholic/tickets/todo/20260830000001-t1.md "Drive the first ticket" \
        "https://example.invalid/r" "why" "None" "None" "None" "None" ) 2>&1 ) && _ok_rc=0 || _ok_rc=$?
    if [ "$_ok_rc" -eq 0 ] && [ -f "${_wtA}/.workaholic/tickets/archive/${_brA}/20260830000001-t1.md" ]; then
        add_row "claim_race_sole_holder_archives" true "the sole claim holder archives exactly as before -- the gate strands nothing" load
    else
        add_row "claim_race_sole_holder_archives" false "the holder's own archive was refused (exit ${_ok_rc}): $(one_line "$_arch_ok")" load
    fi
    _arch2=$( ( cd "$_wtA" && env $_env sh "$_archive" \
        .workaholic/tickets/todo/20260830000002-t2.md "Drive the second ticket" \
        "https://example.invalid/r" "why" "None" "None" "None" "None" ) 2>&1 ) || true

    # --- 4. THE TWIN'S DELIVERY MAKES THE LOSER `superseded`, FROM THE TREE -------------
    # A's content reaches the base by a squash merge -- the shape that leaves the CONTENT on
    # the base and the COMMITS unreachable, so the branch stays unmerged forever. B's own tip
    # still carries both tickets, undriven; every one of them is now archived on the base
    # under A's branch directory, which is precisely what `superseded` means.
    ( cd "$_origin" && git update-ref "refs/heads/${_brB}" \
        "$( ( cd "$_B" && git -C .worktrees/raced rev-parse HEAD ) 2>/dev/null )" ) >/dev/null 2>&1 || true
    ( cd "$_seed" && git fetch -q origin && git checkout -q main && git reset -q --hard origin/main \
      && git merge --squash -q "origin/${_brA}" && git commit -qm "Squash the winner" \
      && git push -q origin main ) >/dev/null 2>&1 || true
    ( cd "$_B" && git fetch -q --prune origin ) >/dev/null 2>&1 || true

    _claims=$(_scan "$_B")
    if [ "$(_verdict "$_claims" "$_brB")" = "superseded" ]; then
        add_row "claim_race_loser_superseded" true "the raced loser reads superseded at the MISSION grain, from the tree, with no merged pull request to ask about" load
    else
        add_row "claim_race_loser_superseded" false "expected superseded for ${_brB}, got '$(_verdict "$_claims" "$_brB")': $(one_line "$_claims")" load
    fi

    # AND THE EXISTING RETIREMENT PATH REACHES IT, with no change of its own -- which is the
    # point of repairing the READING rather than each of its consumers.
    _retire=$( ( cd "$_B" && env $_env WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_retirable" ) 2>&1 || true )
    if printf '%s' "$_retire" | grep -q '"unit": "raced"'; then
        add_row "claim_race_retirement_reaches_it" true "list-retirable-claims.sh names the raced unit, so the claim can leave the table" load
    else
        add_row "claim_race_retirement_reaches_it" false "the retirement path found no candidate: $(one_line "$_retire")" load
    fi

    # --- 5. THE BREAKER: the reading, wired as it was before the repair -----------------
    # Written against the BEHAVIOUR rather than a return shape: `claims_superseded` is called
    # WITHOUT the claim's tip ref, which is exactly the pre-repair composition -- the mission
    # grain then has nothing local to ask and falls to the merged lookup, which the stubbed
    # transport answers with nothing. If that still reads `superseded`, this drill's own
    # subject is being asserted by something other than the repair.
    _pre=$( ( cd "$_B" && env $_env sh -c '
        . "$1"
        CLAIMS_FETCH_OK=true
        printf "%s" "$(claims_superseded "$(claims_base)" ".workaholic/missions/active/raced/mission.md" "$2")"
      ' _ "$_lib" "$_brB" ) 2>/dev/null || true )
    _post=$( ( cd "$_B" && env $_env sh -c '
        . "$1"
        CLAIMS_FETCH_OK=true
        printf "%s" "$(claims_superseded "$(claims_base)" ".workaholic/missions/active/raced/mission.md" "$2" "origin/$2")"
      ' _ "$_lib" "$_brB" ) 2>/dev/null || true )
    if [ "$_pre" = "false" ] && [ "$_post" = "true" ]; then
        add_row "claim_race_reading_is_the_tip_walk" true "dropping the claim's tip ref loses the mission-grain reading -- this drill can fail" breaker
    else
        add_row "claim_race_reading_is_the_tip_walk" false "the pre-repair composition answered '${_pre}' and the repaired one '${_post}', so this row proves nothing" breaker
    fi

    # NOTHING REACHED A NETWORK AND NOTHING TOUCHED THE CHECKOUT.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "claim_race_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "claim_race_writes_nothing" false "the drill changed the working tree" load
    fi

    ( cd "$_A" && git worktree remove --force .worktrees/raced ) >/dev/null 2>&1 || true
    ( cd "$_B" && git worktree remove --force .worktrees/raced ) >/dev/null 2>&1 || true
    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "claim-race" 0 "fail" 1
    fi
    emit_verdict "claim-race" 0 "pass" 0
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
        add_row "identity_handoff_fails_when_dropped" true "an address the mapping does not name is excluded, so the drill can fail" breaker
    else
        add_row "identity_handoff_fails_when_dropped" false "an unmapped address was still offered; this drill cannot fail and proves nothing" breaker
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
        add_row "close_unrecorded_stays_silent" true "an unrecorded outcome falls back to queue_drained, so the verdict is never asserted without evidence -- this drill can fail" breaker
    else
        add_row "close_unrecorded_stays_silent" false "an unrecorded outcome read '$(_verdict batch-silent)', so the verdict is being asserted without evidence" breaker
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
# ---------------------------------------------------------------------------------------
# verify-catch-up — the base moves under a finished unit, and the loop brings it back
# (2026-08-29, mission `land-the-loop-s-own-work-when-the-base-moves-under-it`).
#
# Everything here runs over a bare LOCAL origin with `gh` stubbed: no network at any point.
# The rows are the mission's bounds rather than its happy path -- a mechanical conflict caught
# up and delivered, a content conflict refused with the branch byte-identical, a foreign claim
# untouched, a scan-held pull request never caught up, and a second run a no-op.
#
# THE BREAKER ROW IS WRITTEN AGAINST THE BEHAVIOUR, NOT A RETURN SHAPE. It hands the writer a
# claim THIS IDENTITY DOES NOT HOLD. If the identity bound were ever widened -- or reordered
# behind the act -- that row would merge into a colleague's branch and push it, and the drill
# would pass while the loop trampled somebody's work. Asserting a return shape would survive
# exactly that refactor, which is why the assertion is on the BRANCH TIP.
# ---------------------------------------------------------------------------------------
cmd_verify_catch_up() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/claim-mergeability.sh"
    _writer="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/catch-up-claim.sh"
    _catchable="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-catchup-blocked.sh"
    _recorder="${REPO_ROOT}/plugins/workaholic/skills/story/scripts/record-merge-outcome.sh"
    for _f in "$_reader" "$_writer" "$_catchable" "$_step" "$_recorder"; do
        [ -f "$_f" ] || emit_err "catch_up_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }
    _other() { git -c user.email=colleague@example.com -c user.name=Other -c commit.gpgsign=false "$@"; }
    # THE STUBBED TRANSPORT, EXTENDED FOR THE REVIEW BOUND (2026-08-30, mission
    # `catch-a-reported-claim-up-before-its-conflict-hardens`). That bound reads a pull request's
    # reviews, and the drill must stay hermetic — a drill that needs a credential is classified
    # out of the CI set and stops proving anything on merge. So the stub answers exactly the
    # three reads the bound makes and `[]` for everything else:
    #   rate_limit                     the availability probe
    #   pulls?state=open&head=…        the unit's own open pull request (number 5 for the
    #                                  reviewed branch, 1 for every other)
    #   pulls/<n>/reviews              a PERSON's review on 5, a BOT's on 1, none elsewhere
    # `state=all` is answered `[]` deliberately: that is `claim-merged.sh`'s query, and a row
    # there would read as a merged claim and change every verdict in the fixture.
    cat > "${_bin}/gh" <<'GH_STUB_EOF'
#!/bin/sh
_p=""
for _a in "$@"; do
    case "$_a" in
        -*|api) ;;
        *) [ -n "$_p" ] || _p="$_a" ;;
    esac
done
case "$_p" in
    rate_limit)                   echo 5000 ;;
    *pulls/5/reviews*)            echo '[{"user": {"type": "User", "login": "a-person"}}]' ;;
    *pulls/1/reviews*)            echo '[{"user": {"type": "Bot", "login": "reviewer[bot]"}}]' ;;
    *reviews*)                    echo '[]' ;;
    *state=all*)                  echo '[]' ;;
    *head=*work-20260101-000005*) echo '[{"number": 5}]' ;;
    *pulls*head=*)                echo '[{"number": 1}]' ;;
    *)                            echo '[]' ;;
esac
GH_STUB_EOF
    chmod +x "${_bin}/gh"

    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "catch_up_no_network" true "the stub is what gh resolves to, and the origin is a local bare repository -- no row below reaches the network" load
    else
        add_row "catch_up_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "catch-up" 0 "fail" 1
    fi

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" "${_work}/.workaholic/stories" \
             "${_work}/.claude-plugin" "${_work}/src"
    for _n in 1 2 3 4 5 6; do
        printf -- '---\ncreated_at: 2026-01-01T00:00:0%s+09:00\nauthor: %s\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_n" > "${_work}/.workaholic/tickets/todo/2026010100000${_n}-t.md"
    done
    printf '{\n  "name": "wh",\n  "version": "1.0.0",\n  "plugins": []\n}\n' \
        > "${_work}/.claude-plugin/marketplace.json"
    printf 'alpha\nbeta\ngamma\n' > "${_work}/src/app.txt"
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) >/dev/null 2>&1 || true

    # Drive one ticket into the shape a stranded unit has: queue drained, a story at the tip, a
    # recorded merge refusal, and the branch-side half of its conflict.
    # $1 = branch, $2 = unit, $3 = ticket basename, $4 = recorded outcome,
    # $5 = "other" for a colleague's claim.
    _strand() {
        _sb="$1"; _su="$2"; _st="$3"; _so="$4"
        _sw=_git; _sa="$_me"
        if [ "${5:-}" = "other" ]; then _sw=_other; _sa=colleague@example.com; fi
        ( cd "$_work" && git checkout -q main && git checkout -q -B "$_sb" \
          && printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: %s\n---\n\n# T\n\nclaimed\n' \
               "$_sa" "$_sb" > ".workaholic/tickets/todo/${_st}" \
          && $_sw commit -qam "Claim a PR-unit" -m "Unit: ${_su}" \
          && mkdir -p ".workaholic/tickets/archive/${_sb}" ".workaholic/stories" \
          && git mv ".workaholic/tickets/todo/${_st}" ".workaholic/tickets/archive/${_sb}/" \
          && printf -- '---\ntype: Story\nbranch: %s\n---\n\n## 1. Overview\n\ndone\n' \
               "$_sb" > ".workaholic/stories/${_sb}.md" ) >/dev/null 2>&1 || true
        # The mkdir above is load-bearing and was learned the hard way: `.workaholic/stories/`
        # holds only the PREVIOUS unit's story, so checking main out removes the file and git
        # prunes the empty directory -- after which the redirect fails silently, the branch
        # carries no story, and every claim reads `report_incomplete` instead of the drained
        # state every row below is about.
        [ -z "$_so" ] || ( cd "$_work" && sh "$_recorder" ".workaholic/stories/${_sb}.md" "$_so" ) >/dev/null 2>&1 || true
    }

    # 1. MECHANICAL -- both sides bump the version manifest. Resolvable without a judgement.
    _strand work-20260101-000001 batch-mechanical 20260101000001-t.md "merge_refused: session_type_cannot_merge"
    printf '{\n  "name": "wh",\n  "version": "1.0.1",\n  "plugins": []\n}\n' \
        > "${_work}/.claude-plugin/marketplace.json"
    ( cd "$_work" && _git add -A && _git commit -qm "Report the unit" \
      && git push -q origin work-20260101-000001 ) >/dev/null 2>&1 || true

    # 2. CONTENT -- both sides change the same source line. Only a person can judge it.
    _strand work-20260101-000002 batch-content 20260101000002-t.md "merge_refused: session_type_cannot_merge"
    printf 'alpha\nbeta-branch\ngamma\n' > "${_work}/src/app.txt"
    ( cd "$_work" && _git add -A && _git commit -qm "Report the unit" \
      && git push -q origin work-20260101-000002 ) >/dev/null 2>&1 || true

    # 3. SCAN-HELD -- a `hard` finding holds its pull request open. The gate WORKING.
    _strand work-20260101-000003 batch-scanheld 20260101000003-t.md "merge_not_attempted: hard"
    printf '{\n  "name": "wh",\n  "version": "1.0.4",\n  "plugins": []\n}\n' \
        > "${_work}/.claude-plugin/marketplace.json"
    ( cd "$_work" && _git add -A && _git commit -qm "Report the unit" \
      && git push -q origin work-20260101-000003 ) >/dev/null 2>&1 || true

    # 4. FOREIGN -- a colleague's claim, untouchable at any age. The breaker row's subject.
    _strand work-20260101-000004 batch-foreign 20260101000004-t.md "merge_refused: session_type_cannot_merge" other
    printf '{\n  "name": "wh",\n  "version": "1.0.7",\n  "plugins": []\n}\n' \
        > "${_work}/.claude-plugin/marketplace.json"
    ( cd "$_work" && _other commit -qam "Report the unit" \
      && git push -q origin work-20260101-000004 ) >/dev/null 2>&1 || true

    # 5. REVIEWED -- a `queue_drained` unit (no recorded refusal: waiting on a PERSON) whose
    # pull request carries a submitted human review. The one bound the 2026-08-30 widening added.
    _strand work-20260101-000005 batch-reviewed 20260101000005-t.md ""
    printf '{\n  "name": "wh",\n  "version": "1.0.5",\n  "plugins": []\n}\n' \
        > "${_work}/.claude-plugin/marketplace.json"
    ( cd "$_work" && _git add -A && _git commit -qm "Report the unit" \
      && git push -q origin work-20260101-000005 ) >/dev/null 2>&1 || true

    # 6. QUEUE_DRAINED -- the widening's whole subject. Finished, pushed, waiting on a person,
    # still mechanical, nobody has reviewed it. Before 2026-08-30 no run would touch it.
    _strand work-20260101-000006 batch-drained 20260101000006-t.md ""
    printf '{\n  "name": "wh",\n  "version": "1.0.6",\n  "plugins": []\n}\n' \
        > "${_work}/.claude-plugin/marketplace.json"
    ( cd "$_work" && _git add -A && _git commit -qm "Report the unit" \
      && git push -q origin work-20260101-000006 ) >/dev/null 2>&1 || true

    # THE BASE MOVES under all six.
    ( cd "$_work" && git checkout -q main \
      && printf 'alpha\nbeta-base\ngamma\n' > src/app.txt \
      && printf '{\n  "name": "wh",\n  "version": "1.0.2",\n  "plugins": []\n}\n' > .claude-plugin/marketplace.json \
      && _git commit -qam "Advance the base" && git push -q origin main ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill \
      && git config commit.gpgsign false ) >/dev/null 2>&1 || true

    _run() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_writer" "$1" ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n 's/.*"'"$2"'": *"\([^"]*\)".*/\1/p' | head -1; }
    _tip() { git --git-dir="$_origin" rev-parse "refs/heads/$1" 2>/dev/null || printf 'gone'; }
    _class() { ( cd "$_read" && sh "$_reader" "$1" origin/main ) 2>/dev/null \
        | sed -n 's/.*"class": "\([^"]*\)".*/\1/p' | head -1; }

    if [ "$(_class work-20260101-000001)" = "mechanical" ] \
        && [ "$(_class work-20260101-000002)" = "content" ]; then
        add_row "catch_up_fixture" true "the reader answers mechanical and content over the two branches -- the shape under test" load
    else
        add_row "catch_up_fixture" false "the fixture is wrong (mechanical='$(_class work-20260101-000001)' content='$(_class work-20260101-000002)')" load
        rm -rf "$_tmp"
        emit_verdict "catch-up" 0 "fail" 1
    fi

    # ---- THE WIDENED TRIGGER (2026-08-30, mission
    # `catch-a-reported-claim-up-before-its-conflict-hardens`) -------------------------------
    # The candidate reader is what changed; the writer is untouched. These rows run BEFORE the
    # catch-up rows below, because a caught-up branch contains the base and leaves the candidate
    # set by itself — which is exactly the self-correction `step-catchup-blocked.sh` records.
    _cands=$( ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_catchable" ) 2>&1 || true )
    _names() { printf '%s' "$_cands" | grep -q "\"unit\": \"$1\""; }

    # THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR. Wire the candidate reader back at the delivery
    # verdict alone — `report_undelivered` only, the pre-2026-08-30 set — and `batch-drained`
    # disappears from the offer while every other row here stays green. Asserting a return shape
    # would survive exactly that narrowing, which is why the assertion is on the UNIT BEING
    # NAMED: this is the whole widening, and a drill that cannot lose it proves nothing.
    if _names batch-drained; then
        add_row "catch_up_offers_a_drained_claim" true "a queue_drained claim still mechanical is offered to the act -- the widening this drill exists for" breaker
    else
        add_row "catch_up_offers_a_drained_claim" false "the reader did not offer the queue_drained mechanical claim: $(one_line "$_cands")" breaker
    fi

    # AND NOTHING ELSE IS OFFERED. `content` is a person's, and a colleague's claim is
    # untouchable at any age — neither may reach an act that pushes.
    if ! _names batch-content && ! _names batch-foreign; then
        add_row "catch_up_offer_is_bounded" true "a content conflict and a colleague's claim are not candidates -- the reader offers only what the act may take" load
    else
        add_row "catch_up_offer_is_bounded" false "the reader offered a unit no act may take: $(one_line "$_cands")" load
    fi

    # A DEGRADED SCAN YIELDS NO CANDIDATES, ITS REASON AND A NULL COUNT — never a bare empty
    # set, which is byte-identical to a healthy quiet run.
    _deg=$( ( cd "$_tmp" && PATH="${_bin}:$PATH" sh "$_catchable" ) 2>&1 || true )
    if printf '%s' "$_deg" | grep -q '"ok": false' \
        && printf '%s' "$_deg" | grep -q '"count": null' \
        && printf '%s' "$_deg" | grep -q '"candidates": \[\]'; then
        add_row "catch_up_degraded_reads_null" true "a scan that could not be made yields no candidates, a named reason and a null count" load
    else
        add_row "catch_up_degraded_reads_null" false "a degraded read did not answer with null counts: $(one_line "$_deg")" load
    fi

    # THE WIDENING'S OWN SUBJECT IS ACTUALLY CAUGHT UP. A `queue_drained` unit nobody has
    # reviewed is merged, validated and pushed exactly as an undelivered one is.
    _d_before=$(_tip work-20260101-000006)
    _d=$(_run batch-drained)
    if [ "$(_field "$_d" outcome)" = "caught_up" ] \
        && [ "$(_tip work-20260101-000006)" != "$_d_before" ]; then
        add_row "catch_up_drained_caught_up" true "a queue_drained claim still mechanical is caught up and pushed, once" load
    else
        add_row "catch_up_drained_caught_up" false "the queue_drained case did not complete: $(one_line "$_d")" load
    fi

    # A PULL REQUEST A PERSON HAS ALREADY REVIEWED IS REFUSED BY ITS OWN WORD, branch
    # byte-identical. This is the one bound the widening added: a push resets an approval.
    _r_before=$(_tip work-20260101-000005)
    _r=$(_run batch-reviewed)
    if [ "$(_field "$_r" reason)" = "pull_request_reviewed" ] \
        && [ "$(_tip work-20260101-000005)" = "$_r_before" ]; then
        add_row "catch_up_reviewed_refused" true "a submitted human review refuses the catch-up by name and the branch is byte-identical after it" load
    else
        add_row "catch_up_reviewed_refused" false "a reviewed pull request was not refused cleanly: $(one_line "$_r")" load
    fi

    # ROW 1: THE MECHANICAL CASE IS CAUGHT UP AND PUSHED IN ONE TURN, and the version collision
    # converges on the HIGHER semver rather than on one side wholesale. Its pull request carries
    # a BOT's review, which is not a person's attention and must not refuse it.
    _m_before=$(_tip work-20260101-000001)
    _m=$(_run batch-mechanical)
    _m_ver=$(git --git-dir="$_origin" show "refs/heads/work-20260101-000001:.claude-plugin/marketplace.json" 2>/dev/null \
        | sed -n 's/.*"version": "\([0-9.]*\)".*/\1/p' | head -1)
    if [ "$(_field "$_m" outcome)" = "caught_up" ] \
        && [ "$(_tip work-20260101-000001)" != "$_m_before" ] \
        && [ "$_m_ver" = "1.0.2" ]; then
        add_row "catch_up_mechanical_delivered" true "a mechanical conflict is merged, validated and pushed, and the higher version wins the manifest collision" load
    else
        add_row "catch_up_mechanical_delivered" false "the mechanical case did not complete (version='${_m_ver}'): $(one_line "$_m")" load
    fi

    # ROW 2: A CONTENT CONFLICT IS REFUSED AND THE BRANCH IS BYTE-IDENTICAL AFTER IT.
    _c_before=$(_tip work-20260101-000002)
    _c=$(_run batch-content)
    if [ "$(_field "$_c" reason)" = "content_conflict" ] \
        && [ "$(_tip work-20260101-000002)" = "$_c_before" ]; then
        add_row "catch_up_content_refused" true "a content conflict is refused by its own word and the branch is byte-identical after it" load
    else
        add_row "catch_up_content_refused" false "a content conflict was not refused cleanly: $(one_line "$_c")" load
    fi

    # ROW 3: A SCAN-HELD PULL REQUEST IS NEVER CAUGHT UP. The catch-up is not a route around a
    # gate: a `hard` finding holding a pull request open is the gate working.
    _h_before=$(_tip work-20260101-000003)
    _h=$(_run batch-scanheld)
    if [ "$(_field "$_h" reason)" = "scan_held:hard" ] \
        && [ "$(_tip work-20260101-000003)" = "$_h_before" ]; then
        add_row "catch_up_scan_held_refused" true "a scan-held pull request is refused by tier and its branch is untouched -- no gate is overridden" load
    else
        add_row "catch_up_scan_held_refused" false "a scan-held unit was not refused by name: $(one_line "$_h")" load
    fi

    # ROW 4: A SECOND RUN IS A NO-OP THAT SAYS SO, and pushes nothing.
    _s_before=$(_tip work-20260101-000001)
    _s=$(_run batch-mechanical)
    if [ "$(_field "$_s" outcome)" = "already_current" ] \
        && [ "$(_tip work-20260101-000001)" = "$_s_before" ]; then
        add_row "catch_up_second_run_noop" true "a branch that already contains the base reports already_current and touches no ref" load
    else
        add_row "catch_up_second_run_noop" false "the second run was not a reported no-op: $(one_line "$_s")" load
    fi

    # ROW 5: THE REFUSED CONFLICT REACHES ITS CLAIM HOLDER, keyed once, naming the branch and
    # the files both sides changed -- and the unit the loop CAUGHT UP draws no question, which
    # is the split the whole mission rests on.
    _stepout=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000000 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_stepout" | grep -q 'catchup-blocked:batch-content' \
        && printf '%s' "$_stepout" | grep -q 'src/app.txt' \
        && ! printf '%s' "$_stepout" | grep -q 'catchup-blocked:batch-mechanical'; then
        add_row "catch_up_blocked_asks_once" true "the refused conflict reaches its claim holder keyed once, naming the files, and the caught-up unit draws no question" load
    else
        add_row "catch_up_blocked_asks_once" false "the question was not asked as specified: $(one_line "$_stepout")" load
    fi

    # THE DELIBERATELY BROKEN ROW -- written against the BEHAVIOUR. A claim this identity does
    # not hold, handed straight to the writer. If the identity bound were widened, or moved
    # behind the act, this row would merge into a colleague's branch and push it. The assertion
    # is on the BRANCH TIP, so a refactor that keeps the JSON shape and loses the bound still
    # fires it.
    _f_before=$(_tip work-20260101-000004)
    _fo=$(_run batch-foreign)
    if [ "$(_tip work-20260101-000004)" = "$_f_before" ] \
        && printf '%s' "$_fo" | grep -qE '"reason": "(foreign_identity|not_my_claim)"'; then
        add_row "catch_up_refuses_a_foreign_claim" true "a colleague's claim is refused by name and its branch never moves -- this drill can fail" breaker
    else
        add_row "catch_up_refuses_a_foreign_claim" false "a colleague's branch was touched, or the refusal was not named: $(one_line "$_fo")" breaker
    fi

    # NOTHING OUTSIDE THE FIXTURE IS WRITTEN. Operator tooling that dirties the operator's own
    # checkout is worse than no tooling.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "catch_up_checkout_untouched" true "the drill left this checkout exactly as it found it" load
    else
        add_row "catch_up_checkout_untouched" false "the drill changed this checkout" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -eq 0 ]; then
        emit_verdict "catch-up" 0 "pass" 0
    fi
    emit_verdict "catch-up" 0 "fail" 1
}

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
        add_row "retire_refuses_a_judgement" true "a live claim is refused by its own verdict word with nothing attempted -- this drill can fail" breaker
    else
        add_row "retire_refuses_a_judgement" false "a live claim was not refused by name: $(one_line "$_live_out")" breaker
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
    # The key carries the refusal word since 2026-08-29, so it is asked once per (unit, refusal
    # word) rather than once per unit ever -- a unit whose block changes word is a different fact
    # needing a different act. `verify-act-effect` drills the narrowing itself over three ticks.
    if printf '%s' "$_bstep" | grep -q '"key":"retire-blocked:batch-blocked:branch_delete_failed"' \
        && printf '%s' "$_bstep" | grep -q '"branch":"work-20260101-000006"' \
        && printf '%s' "$_bstep" | grep -q "\"owner\":\"${_me}\"" \
        && printf '%s' "$_bstep" | grep -q '"refusal":"branch_delete_failed"'; then
        add_row "retire_blocked_asks_the_holder" true "one question, keyed retire-blocked:batch-blocked:branch_delete_failed, addressed to the claim holder, naming the branch and the refusal" load
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
        add_row "retire_blocked_only_the_blocked" false "a unit whose retirement SUCCEEDED still drew a question -- the candidate set was widened to every superseded row" breaker
    elif printf '%s' "$_bstep" | grep -q 'retire-blocked:batch-closefail'; then
        add_row "retire_blocked_only_the_blocked" false "a unit refused on the pull-request CLOSE still drew a question -- the candidate set was widened to every refusal" breaker
    else
        add_row "retire_blocked_only_the_blocked" true "neither a retirement that succeeded nor one refused on another act asks anybody anything; only the blocked delete does (this drill can fail)" breaker
    fi

    # 13. A STANDING BLOCK IS NOT AN HOURLY CHANGE. Two consecutive ticks over an unchanged
    # blocked set must render an identical summary -- the root calls a step changed when its
    # summary moves, and a status restated hourly is read by nobody by the second day. Both
    # ticks run after `batch-retirable` is gone, so the set really is unchanged.
    #
    # SINCE 2026-08-29 A BLOCKED RETIREMENT SUPPLIES AN `event` (mission
    # `read-back-whether-the-loop-s-own-act-took-effect`), so the SUMMARY is what holds a
    # standing block quiet here -- and that is exactly why the summary carries no CI term. The
    # empty-event guard still covers the other case, a tick whose acts all took, which
    # `verify-act-effect` drills beside this one.
    _t3=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000003 --root "$_read" ) 2>&1 || true )
    _t4=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260101-000004 --root "$_read" ) 2>&1 || true )
    _s3=$(printf '%s' "$_t3" | sed -n 's/.*"summary": *"\([^"]*\)".*/\1/p')
    _s4=$(printf '%s' "$_t4" | sed -n 's/.*"summary": *"\([^"]*\)".*/\1/p')
    _e3=$(printf '%s' "$_t3" | sed -n 's/.*"event": *"\([^"]*\)".*/\1/p')
    _e4=$(printf '%s' "$_t4" | sed -n 's/.*"event": *"\([^"]*\)".*/\1/p')
    if [ -n "$_s3" ] && [ "$_s3" = "$_s4" ] && [ "$_e3" = "$_e4" ]; then
        add_row "retire_blocked_summary_stable" true "two ticks over an unchanged blocked set render an identical summary, so the root's own diff renders no line" load
    else
        add_row "retire_blocked_summary_stable" false "a held block moved the summary or its event (t3='${_s3}' t4='${_s4}'; e3='${_e3}' e4='${_e4}')" load
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

# ---------------------------------------------------- verify-ci-retirement
# Does the act the container is refused actually get taken, and does it stay bounded when it is?
# Act 2 of the retirement — the remote branch delete — is refused in the container the loop runs
# in by both available transports (measured 2026-08-27), so it moves to a different EXECUTOR,
# `.github/workflows/claim-retirement.yml`, on `release-note-draft.yml`'s precedent. That split
# spans two processes and one destructive act, which is the last thing that should be proved by
# waiting for a workflow run.
#
# NO NETWORK. A local bare origin and a `gh` stub on PATH, asserted to be what `gh` resolves to
# rather than assumed. THE TWO EXECUTORS ARE TOLD APART BY TRANSPORT, WHICH IS THE FIXTURE'S
# DISTINCTION AND NOT GITHUB'S: the container's Act 2 is a `git push origin --delete`, which the
# bare origin's own `update` hook refuses server side (the same receive-side path a remote
# refusal takes), while the CI act is a REST `DELETE` through `gh-rest.sh`, which the stub
# performs for real against the same bare repository. A bare origin cannot tell a "CI" pusher
# from a container one on identity alone, and pretending otherwise would drill a fiction.
#
# WHAT IT PROVES:
#   1. the container is refused        `branch_delete_failed`, and the branch survives
#   2. CI takes the act                the candidate reader names it, the act re-proves and
#                                      deletes it, and the branch is gone from the origin
#   3. a judgement is refused BY NAME  a live claim's branch is refused `not_superseded:<verdict>`
#                                      and survives
#   4. every bound refuses by name     `release_branch`, `not_a_work_branch`, `not_on_base`,
#                                      `pull_request_open` -- and every path exits 0
#   5. the question narrows            a CI-deletable unit is never asked about; a unit CI also
#                                      refused is asked exactly once, and a `pending` CI turn
#                                      suppresses the ask for that tick only
#
# AND ONE ROW THAT DELIBERATELY BREAKS THE SEAM: the CI act with its re-proof removed, run over
# the raw candidate list against a LIVE claim. If the re-proof were dropped the workflow would
# delete a branch another run is driving, so the breaker must show that copy deleting what the
# real script refused. Proving the deletion is what proves the drill can fail.
#
# THE RE-PROOF IS TWO GUARDS, AND THE BREAKER HAS TO REMOVE BOTH -- which is itself the finding.
# Written against the verdict gate alone, this row did NOT break: `not_on_base`, the tree-side
# re-derivation, caught the live claim on its own. The two are therefore independent rather than
# one guard written twice, and the drill says so by needing both removed before the damage
# happens.
cmd_verify_ci_retirement() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh"
    _act="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh"
    _turn="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh"
    _retirer="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/retire-claim.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh"
    _flow="${REPO_ROOT}/.github/workflows/claim-retirement.yml"
    for _f in "$_reader" "$_act" "$_turn" "$_retirer" "$_step" "$_flow"; do
        [ -f "$_f" ] || emit_err "ci_retirement_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"
    _bin="${_tmp}/bin"; _ctl="${_tmp}/ctl"
    mkdir -p "$_origin" "$_bin" "$_ctl"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" \
             "${_work}/.workaholic/missions/active/mission-ci-flip"
    for _n in 1 2 3 4 5 6 7 8; do
        printf -- '---\ncreated_at: 2026-02-01T00:00:0%s+09:00\nauthor: %s\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_n" > "${_work}/.workaholic/tickets/todo/2026020100000${_n}-t.md"
    done
    printf -- '---\ntype: Mission\nslug: mission-ci-flip\nstatus: active\nauthor: %s\n---\n\n# M\n' \
        "$_me" > "${_work}/.workaholic/missions/active/mission-ci-flip/mission.md"
    # THE COMMITTED MAPPING. `lib/runner-identity.sh` scans as a claim's author only when
    # `gather/scripts/identity.sh` resolves them, so the identity bound is exercised only if the
    # fixture has one — naming `$_me` and nobody else, which is what makes the eighth claim's
    # unmapped author a real refusal rather than an accident of an absent file.
    mkdir -p "${_work}/.claude"
    printf 'drill-runner=%s\n' "$_me" > "${_work}/.claude/git-identities"
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    # THE CONTAINER'S REFUSAL, reproduced where the real one happens: server side, on every
    # branch deletion the file transport carries. `git push --delete` is the container's only
    # local transport for this act, so refusing every one of them IS the measured condition.
    printf '#!/bin/sh\nif [ "$3" = "0000000000000000000000000000000000000000" ]; then\n  echo "deleting a branch is not permitted for this session type" >&2\n  exit 1\nfi\nexit 0\n' > "${_origin}/hooks/update"
    chmod +x "${_origin}/hooks/update"

    _stampfile() { # $1 = branch, $2 = path under the work tree
        printf -- '---\ncreated_at: 2026-02-01T00:00:00+09:00\nauthor: %s\nclaim: %s\n---\n\n# T\n\nclaimed\n' \
            "$_me" "$1" > "${_work}/$2"
    }
    _claim() { # $1 = branch, $2 = unit, $3 = path to stamp
        ( cd "$_work" && git checkout -q -b "$1" main \
          && _stampfile "$1" "$3" \
          && _git commit -qam "Claim a PR-unit" -m "Unit: $2" \
          && git push -q origin "$1" ) >/dev/null 2>&1 || true
    }

    _claim work-20260201-000001 batch-ci-retirable .workaholic/tickets/todo/20260201000001-t.md
    _claim work-20260201-000002 batch-ci-live      .workaholic/tickets/todo/20260201000002-t.md
    _claim work-20260201-000003 batch-ci-blocked   .workaholic/tickets/todo/20260201000003-t.md
    _claim work-20260201-000004 batch-ci-openpr    .workaholic/tickets/todo/20260201000004-t.md
    _claim work-20260201-000005 mission-ci-flip    .workaholic/missions/active/mission-ci-flip/mission.md
    # The seventh exists for one row: the CI-side act run under an ACTIONS-STYLE credential,
    # where `gh api user` is refused. It needs its own unit because every other superseded one is
    # already spoken for by a bound or by an earlier row.
    _claim work-20260201-000007 batch-ci-token     .workaholic/tickets/todo/20260201000007-t.md
    # The eighth exists for the identity bound (2026-08-29). Its claim commit is authored by
    # somebody the committed mapping does NOT name, so the no-identity re-derivation must refuse
    # to scan as them however superseded the claim is. Without this row a repair that made CI
    # read every claim as its own would pass every other assertion here.
    ( cd "$_work" && git checkout -q -b work-20260201-000008 main \
      && _stampfile work-20260201-000008 .workaholic/tickets/todo/20260201000008-t.md \
      && GIT_AUTHOR_EMAIL=stranger@example.invalid GIT_COMMITTER_EMAIL=stranger@example.invalid \
         GIT_AUTHOR_NAME=Stranger GIT_COMMITTER_NAME=Stranger \
         git -c user.email=stranger@example.invalid -c user.name=Stranger \
             commit -qam "Claim a PR-unit" -m "Unit: batch-ci-foreign" \
      && git push -q origin work-20260201-000008 ) >/dev/null 2>&1 || true
    # The two branch-shape bounds. `claims_scan` walks every remote head, not only `work-*`, so a
    # claim commit on either of these IS a claim row -- which is exactly why the act must refuse
    # them by name rather than trusting that they cannot occur.
    _claim release/20260201-000000 batch-ci-release .workaholic/tickets/todo/20260201000005-t.md
    _claim sidework                batch-ci-sideway .workaholic/tickets/todo/20260201000006-t.md

    # THE PROOF: every claimed ticket archived on the base by another route. Its content reached
    # the base, so the branch can never land -- which is `superseded`. `batch-ci-live`'s ticket
    # stays queued, which is what keeps it a judgement.
    ( cd "$_work" && git checkout -q main \
      && mkdir -p .workaholic/tickets/archive/work-20260201-000000 \
      && for _f in 1 3 4 5 6 7 8; do \
             git mv ".workaholic/tickets/todo/2026020100000${_f}-t.md" \
                    .workaholic/tickets/archive/work-20260201-000000/ ; \
         done \
      && _git commit -qm "Archive the tickets elsewhere" && git push -q origin main ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill \
      && git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' \
      && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    printf '%s' "$(cd "$_read" && git rev-parse origin/main)" > "${_ctl}/base_sha"

    # THE STUB. It answers `gh api user` (so `available` reads true), the workflow-run query the
    # narrowing reads, the two pull-request queries (`state=all` for the merged lookup,
    # `state=open` for the bound), and it PERFORMS the CI ref delete for real against the bare
    # origin -- `update-ref` runs no hook, which is what makes CI's transport succeed where the
    # container's push is refused. `-000003`'s delete is refused so one unit is blocked at BOTH
    # executors, and `-000005`'s merged lookup FLIPS between its first and later answers, which
    # is the only reading in this chain that can change between the proof and the act.
    cat > "${_bin}/gh" <<STUB
#!/bin/sh
ARGS="\$*"
CTL="${_ctl}"
ORIGIN="${_origin}"
case "\$ARGS" in
  *"api rate_limit"*) echo 15000; exit 0 ;;
  *"api user"*)
      # An Actions-style credential: \`GET /user\` is not accessible to an installation token.
      if [ -f "\$CTL/actions_token" ]; then
          echo 'Resource not accessible by integration' >&2; exit 1
      fi
      echo drill; exit 0 ;;
  user*) echo drill; exit 0 ;;
  *actions/workflows/claim-retirement.yml/runs*)
      if [ -f "\$CTL/ci_pending" ]; then
          echo '{"workflow_runs":[]}'
      else
          printf '{"workflow_runs":[{"head_sha":"%s"}]}\n' "\$(cat "\$CTL/base_sha")"
      fi
      exit 0 ;;
  *state=all*work-20260201-000005*)
      n=\$(cat "\$CTL/flip" 2>/dev/null || echo 0); n=\$((n + 1)); echo "\$n" > "\$CTL/flip"
      if [ "\$n" -le 1 ]; then
          echo '[{"number":21,"state":"closed","merged_at":"2026-01-01T00:00:00Z"}]'
      else
          echo '[{"number":21,"state":"closed","merged_at":null}]'
      fi
      exit 0 ;;
  *work-20260201-000004*state=open*) echo '[{"number":22,"state":"open"}]'; exit 0 ;;
  *git/refs/heads/work-20260201-000003*) exit 1 ;;
  *git/refs/heads/*)
      b=\$(printf '%s' "\$ARGS" | sed -n 's#.*git/refs/heads/\([^ ]*\).*#\1#p')
      git --git-dir="\$ORIGIN" update-ref -d "refs/heads/\$b" >/dev/null 2>&1 && exit 0
      exit 1 ;;
esac
echo '[]'
STUB
    chmod +x "${_bin}/gh"
    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "ci_retirement_no_network" true "the stub is what gh resolves to, and the origin is a local bare repository -- no row below reaches the network" load
    else
        add_row "ci_retirement_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "ci-retirement" 0 "fail" 1
    fi

    _run() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$@" ) 2>&1 || true; }
    _field() { printf '%s' "$1" | sed -n 's/.*"'"$2"'": *"\([^"]*\)".*/\1/p' | head -1; }
    _on_origin() { ( cd "$_origin" && git for-each-ref --format='%(refname:short)' refs/heads ) \
        | grep -c "^$1\$" || true; }

    # 1. THE CONTAINER IS REFUSED, and the branch survives. This is the production condition on
    # every tick, and the whole reason the act moved executor.
    _c=$(_run "$_retirer" batch-ci-retirable)
    if [ "$(_field "$_c" reason)" = "branch_delete_failed" ] \
        && [ "$(_field "$_c" remote_branch_deleted)" = "failed" ] \
        && [ "$(_on_origin work-20260201-000001)" = "1" ]; then
        add_row "ci_retirement_container_refused" true "the container's Act 2 is refused branch_delete_failed and the branch is still on origin" load
    else
        add_row "ci_retirement_container_refused" false "the container's delete was not refused as measured: $(one_line "$_c")" load
    fi

    # 2a. THE CANDIDATE READER NAMES IT, out of the claim oracle and nothing else.
    _cands=$(_run "$_reader")
    if printf '%s' "$_cands" | grep -q '"ok": true' \
        && printf '%s' "$_cands" | grep -q '"unit": "batch-ci-retirable"' \
        && ! printf '%s' "$_cands" | grep -q '"unit": "batch-ci-live"'; then
        add_row "ci_retirement_candidates" true "the reader names the superseded units and never a live one" load
    else
        add_row "ci_retirement_candidates" false "the candidate set is wrong: $(one_line "$_cands")" load
    fi

    # 2a-i. THE TERM THAT DECIDES IN CI: NO CONFIGURED GIT IDENTITY (2026-08-29, mission
    #    `make-the-two-executors-agree-about-a-proved-empty-claim`). `actions/checkout@v4`
    #    configures no `user.email`, and this drill never varied that term — it configured one in
    #    its own fixture — so it passed on every push while three proved-empty branches stood.
    #    `GIT_CONFIG_PARAMETERS` is how the state is reproduced without unpicking the clone's own
    #    config, which every other row here depends on.
    # `_run_noid` is `_run` with the one term CI lacks removed, and nothing else: the same
    # working directory, the same stub on PATH and the same lapsed-heartbeat window, so the
    # only difference between the two readings below is the configured identity.
    _run_noid() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        GIT_CONFIG_PARAMETERS="'user.email='" sh "$@" ) 2>&1 || true; }
    # `grep -o`, never a `sed` capture: the reader emits one JSON LINE carrying every candidate,
    # and a greedy `.*` capture would report only the last unit on it.
    _units_of() { printf '%s' "$1" | grep -o '"unit": "[a-z0-9-]*"' \
        | sed 's/.*: "//; s/"$//' | sort | tr '\n' ' '; }

    _with=$(_run "$_reader")
    _without=$(_run_noid "$_reader")
    _nwith=$(printf '%s' "$_with" | grep -o '"unit"' | grep -c . || true)
    _nwithout=$(printf '%s' "$_without" | grep -o '"unit"' | grep -c . || true)
    if [ "$_nwith" -gt 0 ] && [ "$_nwith" = "$_nwithout" ] \
        && [ "$(_units_of "$_with")" = "$(_units_of "$_without")" ]; then
        add_row "ci_retirement_identity_states_agree" true \
            "the two executors' candidate readers name the same units with and without a configured identity (${_nwith} each)" load
    else
        add_row "ci_retirement_identity_states_agree" false \
            "the readings disagree: with=[$(_units_of "$_with")] without=[$(_units_of "$_without")]" load
    fi

    # 2a-ii. AND THE BOUND THE REPAIR MAY NOT CROSS. A live claim and a claim authored by somebody
    #     the mapping does not name stay undeletable under BOTH identity states. A repair that
    #     made CI see every claim as its own would pass row 6 and must fail here.
    _bound_ok=true
    _bound_detail=""
    for _u in batch-ci-live batch-ci-foreign; do
        for _mode in with without; do
            if [ "$_mode" = with ]; then
                _o=$(_run "$_act" "$_u")
            else
                _o=$(_run_noid "$_act" "$_u")
            fi
            case "$_o" in
                *'"deleted": false'*) : ;;
                *) _bound_ok=false; _bound_detail="${_bound_detail}${_u}/${_mode}: $(one_line "$_o"); " ;;
            esac
        done
        case "$(_units_of "$_without")" in
            *"$_u"*) _bound_ok=false; _bound_detail="${_bound_detail}${_u} became a candidate; " ;;
        esac
    done
    if [ "$_bound_ok" = true ]; then
        add_row "ci_retirement_identity_bound_holds" true \
            "a live claim and an unmapped author's claim are refused under both identity states, and neither is ever a candidate" load
    else
        add_row "ci_retirement_identity_bound_holds" false "$_bound_detail" load
    fi

    # 2a-iii. THE SECOND BREAKER, WRITTEN AGAINST THE BEHAVIOUR. Restore the identity-first
    #     precedence by removing the re-derivation from the candidate reader; the count must fall
    #     to zero in the no-identity state, which is exactly the production silence. A breaker
    #     asserting a return shape would survive the refactor that reintroduces this.
    cp -R "${REPO_ROOT}/plugins/workaholic/skills" "${_tmp}/skills-id" 2>/dev/null || true
    _blist="${_tmp}/skills-id/drive/scripts/list-retirable-claims.sh"
    sed 's/^if runner_identity_absent; then$/if false; then/' "$_reader" > "$_blist"
    _bid=$(_run_noid "$_blist")
    _nbid=$(printf '%s' "$_bid" | grep -o '"unit"' | grep -c . || true)
    if [ "$_nbid" = "0" ] && [ "$_nwithout" -gt 0 ]; then
        add_row "ci_retirement_identity_breaker" true \
            "with the re-derivation removed the no-identity reading falls to 0 candidates against ${_nwithout} -- the production silence, and this drill can fail" breaker
    else
        add_row "ci_retirement_identity_breaker" false \
            "the breaker did not break: the reading was ${_nbid} with the re-derivation removed" breaker
    fi

    # 2b. CI TAKES THE ACT the container could not, re-proving the verdict at the moment of it.
    _d=$(_run "$_act" batch-ci-retirable)
    if printf '%s' "$_d" | grep -q '"deleted": true' \
        && [ "$(_field "$_d" state)" = "deleted" ] \
        && [ "$(_on_origin work-20260201-000001)" = "0" ]; then
        add_row "ci_retirement_ci_takes_the_act" true "the CI-side act deletes the branch the container was refused" load
    else
        add_row "ci_retirement_ci_takes_the_act" false "the CI-side act did not take the delete (branch_present=$(_on_origin work-20260201-000001)): $(one_line "$_d")" load
    fi

    # 2c. AND IT IS IDEMPOTENT: a branch already gone is a SUCCESS, not an error, so a re-run
    # over a set already taken is a clean no-op rather than a run full of failures.
    _again=$(_run "$_act" batch-ci-retirable)
    if printf '%s' "$_again" | grep -q '"reason": "no_such_claim"' \
        || [ "$(_field "$_again" state)" = "already_gone" ]; then
        add_row "ci_retirement_idempotent" true "a second CI turn over the same unit attempts nothing and reports it plainly" load
    else
        add_row "ci_retirement_idempotent" false "a second CI turn was not a no-op: $(one_line "$_again")" load
    fi

    # 2d. AND IT TAKES THE ACT UNDER THE CREDENTIAL CI ACTUALLY HAS. `GET /user` is not accessible
    # to a GitHub App installation token, which is what `GITHUB_TOKEN` is inside a workflow, so
    # while `gh-rest.sh available` probed `gh api user` every script guarded by it refused
    # `gh_unavailable` in CI whatever its own operation's permissions were. Measured 2026-08-29:
    # this workflow holds `contents: write` and had deleted NOTHING since it shipped. This is the
    # row that would have caught it -- the probe must test the capability, not identity.
    : > "${_ctl}/actions_token"
    _tok=$(_run "$_act" batch-ci-token)
    if printf '%s' "$_tok" | grep -q '"deleted": true' \
        && [ "$(_field "$_tok" state)" = "deleted" ] \
        && [ "$(_on_origin work-20260201-000007)" = "0" ]; then
        add_row "ci_retirement_actions_credential" true "the CI-side act reaches its transport and deletes the branch under a credential that cannot call GET /user" load
    else
        add_row "ci_retirement_actions_credential" false "the act was refused under an Actions-style credential (branch_present=$(_on_origin work-20260201-000007)): $(one_line "$_tok")" load
    fi
    rm -f "${_ctl}/actions_token"

    # 3. A JUDGEMENT IS REFUSED BY ITS OWN VERDICT WORD, and the live branch survives. Acting on
    # `claim_active` is how a workflow tears down work a run is still driving.
    _live=$(_run "$_act" batch-ci-live)
    if printf '%s' "$_live" | grep -q '"reason": "not_superseded:' \
        && [ "$(_field "$_live" state)" = "not_attempted" ] \
        && [ "$(_on_origin work-20260201-000002)" = "1" ]; then
        add_row "ci_retirement_refuses_a_judgement" true "a live claim is refused by its own verdict word with nothing attempted, and its branch stands" load
    else
        add_row "ci_retirement_refuses_a_judgement" false "a live claim was not refused by name: $(one_line "$_live")" load
    fi

    # 4. EACH BOUND REFUSES BY NAME, on top of the proof. A wrong refusal delays a cleanup; a
    # wrong delete tears down a branch. Where a reading is absent or a shape is unexpected,
    # refuse -- and every one of these paths still exits 0.
    _rel=$(_run "$_act" batch-ci-release)
    _side=$(_run "$_act" batch-ci-sideway)
    _pr=$(_run "$_act" batch-ci-openpr)
    # EVERY scan consults the merged lookup for the mission claim, so the counter is reset
    # immediately before the one invocation whose two reads it is meant to drive: the scan's
    # proof answers `merged`, and the bound's re-read -- the only reading in this chain that can
    # change between the proof and the act -- answers `not_merged`.
    rm -f "${_ctl}/flip"
    _flip=$(_run "$_act" mission-ci-flip)
    _bounds_ok=true
    [ "$(_field "$_rel" reason)" = "release_branch" ] || _bounds_ok=false
    [ "$(_field "$_side" reason)" = "not_a_work_branch" ] || _bounds_ok=false
    [ "$(_field "$_pr" reason)" = "pull_request_open" ] || _bounds_ok=false
    [ "$(_field "$_flip" reason)" = "not_on_base" ] || _bounds_ok=false
    [ "$(_on_origin 'release/20260201-000000')" = "1" ] || _bounds_ok=false
    [ "$(_on_origin sidework)" = "1" ] || _bounds_ok=false
    [ "$(_on_origin work-20260201-000004)" = "1" ] || _bounds_ok=false
    [ "$(_on_origin work-20260201-000005)" = "1" ] || _bounds_ok=false
    if [ "$_bounds_ok" = "true" ]; then
        add_row "ci_retirement_bounds" true "release_branch, not_a_work_branch, pull_request_open and not_on_base each refuse by name and every branch survives" load
    else
        add_row "ci_retirement_bounds" false "a bound did not refuse by name (release='$(_field "$_rel" reason)' side='$(_field "$_side" reason)' pr='$(_field "$_pr" reason)' flip='$(_field "$_flip" reason)')" load
    fi

    # 4b. EVERY PATH EXITS 0. A refusal is an answer; a workflow must report it, never die on it.
    _exits_ok=true
    for _u in batch-ci-release batch-ci-sideway batch-ci-openpr batch-ci-live nosuchunit; do
        ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
            sh "$_act" "$_u" >/dev/null 2>&1 ) || _exits_ok=false
    done
    ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_reader" >/dev/null 2>&1 ) || _exits_ok=false
    ( cd "$_read" && PATH="${_bin}:$PATH" sh "$_turn" >/dev/null 2>&1 ) || _exits_ok=false
    if [ "$_exits_ok" = "true" ]; then
        add_row "ci_retirement_always_exits_zero" true "every refusal, every degradation and every reader exits 0" load
    else
        add_row "ci_retirement_always_exits_zero" false "a refusal exited non-zero, which would fail the workflow run" load
    fi

    # 5a. A `pending` CI TURN SUPPRESSES THE ASK FOR THAT TICK. The blocked set is non-empty --
    # the container is refused every delete in this fixture -- so this row isolates the reading
    # rather than an empty candidate list.
    : > "${_ctl}/ci_pending"
    _tp=$(_run "$_turn")
    _stp=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260201-000000 --root "$_read" ) 2>&1 || true )
    if printf '%s' "$_tp" | grep -q '"ci_turn": "pending"' \
        && printf '%s' "$_stp" | grep -q '"needs_agent": \[\]'; then
        add_row "ci_retirement_pending_suppresses" true "with no completed run at this tip the tick asks nobody -- CI may still take the act" load
    else
        add_row "ci_retirement_pending_suppresses" false "a pending CI turn still produced a question (turn=$(one_line "$_tp")): $(one_line "$_stp")" load
    fi
    rm -f "${_ctl}/ci_pending"

    # 5b. AND A `taken` TURN ASKS, naming the unit and the exact branch. CI saw this tree and the
    # branch survived it, so the unit is blocked at both executors and its holder is the person
    # who can act. `batch-ci-retirable` is already gone from the oracle, which is what makes the
    # narrowing visible: a CI-deletable unit is never asked about because it is no longer a claim.
    _stt=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick 20260201-000001 --root "$_read" ) 2>&1 || true )
    # The key carries the refusal word since 2026-08-29, so an unchanged block is asked once and
    # a CHANGED word is asked once more (`verify-act-effect` drills that narrowing over ticks).
    if printf '%s' "$_stt" | grep -q '"key":"retire-blocked:batch-ci-blocked:' \
        && printf '%s' "$_stt" | grep -q '"branch":"work-20260201-000003"' \
        && ! printf '%s' "$_stt" | grep -q 'retire-blocked:batch-ci-retirable'; then
        add_row "ci_retirement_taken_asks_the_holder" true "a unit CI also refused reaches its claim holder naming the branch; a CI-deleted one is asked about by nobody" load
    else
        add_row "ci_retirement_taken_asks_the_holder" false "the narrowed question is wrong: $(one_line "$_stt")" load
    fi

    # 5c. ASKED ONCE, over two ticks. The gate is the check-in's, exercised with this step's key.
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _askscript="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _a1=$(cd "$REPO_ROOT" && sh "$_askscript" --tick 20260201-000001 --key "retire-blocked:batch-ci-blocked" \
        --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
    _logstep=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
    if printf '%s' "$_a1" | grep -q '"ask": true'; then
        sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" --root "$_qroot" \
           --tick 20260201-000001 --step "$_logstep" --status ok --summary "asked" >/dev/null 2>&1 || true
        _a2=$(cd "$REPO_ROOT" && sh "$_askscript" --tick 20260201-000002 --key "retire-blocked:batch-ci-blocked" \
            --root "$_qroot" --to "$_me" --hour 10 --weekday 1 2>&1) || true
        if printf '%s' "$_a2" | grep -q '"ask": false'; then
            add_row "ci_retirement_asked_once" true "the same key is refused on a later tick: $(printf '%s' "$_a2" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p')" load
        else
            add_row "ci_retirement_asked_once" false "the asked-once gate did not hold: $(one_line "$_a2")" load
        fi
    else
        add_row "ci_retirement_asked_once" false "the first ask was refused: $(one_line "$_a1")" load
    fi
    rm -rf "$_qroot"

    # THE DELIBERATELY BROKEN ROW. The CI act with its proof gate removed, run over the raw
    # candidate list against the LIVE claim the real script refused above. If the re-proof were
    # dropped -- or the workflow trusted the list it was handed -- this is precisely what would
    # happen: a branch another run is driving, deleted by a workflow. The row FAILS unless the
    # broken copy does the damage, because a breaker that cannot break proves nothing.
    cp -R "${REPO_ROOT}/plugins/workaholic/skills" "${_tmp}/skills"
    _broken="${_tmp}/skills/drive/scripts/delete-retired-claim-branch.sh"
    sed -e 's/^    refuse "not_superseded:${verdict}"$/    :/' \
        -e 's/^    refuse not_on_base$/    :/' "$_act" > "$_broken"
    _bout=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_broken" batch-ci-live ) 2>&1 || true )
    if printf '%s' "$_bout" | grep -q '"deleted": true' \
        && [ "$(_on_origin work-20260201-000002)" = "0" ]; then
        add_row "ci_retirement_breaker" true "with BOTH halves of the re-proof removed the act deletes a live claim's branch -- either guard alone stops it, and this drill can fail" breaker
    else
        add_row "ci_retirement_breaker" false "the breaker did not break: removing the proof gate changed nothing, so the gate assertion proves nothing ($(one_line "$_bout"))" breaker
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "ci_retirement_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "ci_retirement_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "ci-retirement" 0 "fail" 1
    fi
    emit_verdict "ci-retirement" 0 "pass" 0
}

# ------------------------------------------------------------ verify-act-effect
# Did the act the loop took actually TAKE EFFECT -- and does anything say so when it did not?
#
# WHY IT EXISTS (2026-08-29, mission `read-back-whether-the-loop-s-own-act-took-effect`).
# Every reading in this repository answers *what did I find*. None answered *did what I did
# happen*. Measured on this repository the day the mission opened: `claim-retirement.yml` was
# green on every run while THREE proved-`superseded` claims stood on origin, and the tick log
# recorded, hour after hour, *"ci_turn: taken so CI could not take the delete either"* --
# an assertion about a second executor that NOTHING ESTABLISHED. `ci-retirement-turn.sh`
# answered `taken` from a completed run's EXISTENCE at the base tip, on a premise its own
# header stated and the world did not honour.
#
# THE REPORTED SYMPTOM AND THE MEASURED ONE DIFFER, AND THE DIFFERENCE IS WORTH KEEPING. The
# report assumed the question was suppressed. It is not: the step suppresses on `pending` and
# asks on `taken`, so all three units DID reach `needs_agent` on every tick, and what actually
# held them was the working-day hold -- the gate working. What was wrong is the SENTENCE, in
# the one durable audit trail the tick keeps, and a false reading is worse than a missing one:
# it retires the question rather than raising it, and it would have suppressed the ask outright
# had the same inference ever answered `pending`.
#
# WHAT IT ASSERTS IS THE READING, NEVER A CAUSE. A completed turn that took no act must never
# read `taken`. That wording is deliberate: two different causes produce a standing candidate --
# a candidate reading that yielded the unit no entry, and an act refused by one of its own
# words -- and a reproduction written against either one would go quiet the moment the other
# became live. Both are drilled, separately, because the repair of one is exactly what would
# silently drop the other. Each row also asserts the holder is still asked, so a repair that
# bought its honesty by going silent fails here too.
#
# THE LOCALIZATION THAT PRODUCED IT, recorded here because a later reader will want the
# measurement rather than the conclusion. Under an Actions-style credential (`gh api user`
# refused, which is what a `GITHUB_TOKEN` installation token answers for `GET /user`):
#
#   list-retirable-claims.sh        names all three candidates -- the two executors' readers AGREE
#   delete-retired-claim-branch.sh  refuses `gh_unavailable` before attempting the delete
#
# So the refused-act cause is the live one here, and it is refused at the transport probe rather
# than at the proof gate. The candidate-divergence cause is drilled beside it anyway: it is the
# one the original report assumed, and a drill that covered only the live cause would pass a
# repository where the other one is.
#
# NO NETWORK. A local bare origin and a `gh` stub on PATH, asserted to be what `gh` resolves to
# rather than assumed. The origin's own `update` hook refuses every branch deletion, which is
# the container's measured Act 2 refusal reproduced where the real one happens -- so the step
# has a genuinely blocked retirement to read, and the reading is what is under test.
cmd_verify_act_effect() {
    _turn="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh"
    _flow="${REPO_ROOT}/.github/workflows/claim-retirement.yml"
    for _f in "$_turn" "$_step" "$_flow"; do
        [ -f "$_f" ] || emit_err "act_effect_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"
    _bin="${_tmp}/bin"; _ctl="${_tmp}/ctl"
    mkdir -p "$_origin" "$_bin" "$_ctl"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo"
    for _n in 1 2 3; do
        printf -- '---\ncreated_at: 2026-03-01T00:00:0%s+09:00\nauthor: %s\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_n" > "${_work}/.workaholic/tickets/todo/2026030100000${_n}-t.md"
    done
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    # The container's Act 2 refusal, reproduced server side on every branch deletion the file
    # transport carries -- the same receive-side path a remote refusal takes.
    printf '#!/bin/sh\nif [ "$3" = "0000000000000000000000000000000000000000" ]; then\n  echo "deleting a branch is not permitted for this session type" >&2\n  exit 1\nfi\nexit 0\n' > "${_origin}/hooks/update"
    chmod +x "${_origin}/hooks/update"

    _claim() { # $1 = branch, $2 = unit, $3 = path to stamp
        ( cd "$_work" && git checkout -q -b "$1" main \
          && printf -- '---\ncreated_at: 2026-03-01T00:00:00+09:00\nauthor: %s\nclaim: %s\n---\n\n# T\n\nclaimed\n' "$_me" "$1" > "${_work}/$3" \
          && _git commit -qam "Claim a PR-unit" -m "Unit: $2" \
          && git push -q origin "$1" ) >/dev/null 2>&1 || true
    }
    _claim work-20260301-000001 batch-effect-unnamed .workaholic/tickets/todo/20260301000001-t.md
    _claim work-20260301-000002 batch-effect-refused .workaholic/tickets/todo/20260301000002-t.md
    _claim work-20260301-000003 batch-effect-silent  .workaholic/tickets/todo/20260301000003-t.md

    # THE PROOF: every claimed ticket archived on the base by another route, so each branch can
    # never land -- which is `superseded`, the one verdict the retirement acts on.
    ( cd "$_work" && git checkout -q main \
      && mkdir -p .workaholic/tickets/archive/work-20260301-000000 \
      && for _f in 1 2 3; do \
             git mv ".workaholic/tickets/todo/2026030100000${_f}-t.md" \
                    .workaholic/tickets/archive/work-20260301-000000/ ; \
         done \
      && _git commit -qm "Archive the tickets elsewhere" && git push -q origin main ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill \
      && git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' \
      && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    printf '%s' "$(cd "$_read" && git rev-parse origin/main)" > "${_ctl}/base_sha"

    # THE STUB. It answers `gh api user`, the workflow-run query, the run's jobs (which carry
    # the check run the turn's record is attached to), and the annotations that ARE that record.
    # The record is read out of a control file so each row below can put the turn in one state
    # without rebuilding the fixture.
    printf '[]' > "${_ctl}/record.json"
    cat > "${_bin}/gh" <<STUB
#!/bin/sh
ARGS="\$*"
CTL="${_ctl}"
case "\$ARGS" in
  "api user"*) echo drill; exit 0 ;;
  *actions/workflows/claim-retirement.yml/runs*)
      if [ -f "\$CTL/ci_pending" ]; then
          echo '{"workflow_runs":[]}'
      else
          printf '{"workflow_runs":[{"id":900,"head_sha":"%s","conclusion":"success"}]}\n' "\$(cat "\$CTL/base_sha")"
      fi
      exit 0 ;;
  *actions/runs/900/jobs*)
      echo '{"jobs":[{"name":"retire","conclusion":"success","check_run_url":"https://api.github.com/repos/o/r/check-runs/91"}]}'
      exit 0 ;;
  *check-runs/91/annotations*) cat "\$CTL/record.json"; exit 0 ;;
esac
echo '[]'
STUB
    chmod +x "${_bin}/gh"
    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "act_effect_no_network" true "the stub is what gh resolves to, and the origin is a local bare repository -- no row below reaches the network" load
    else
        add_row "act_effect_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "act-effect" 0 "fail" 1
    fi

    # One annotation line, in the shape `claim-retirement.yml` records. `title` and the message's
    # own leading marker are both set, so the reader does not depend on either alone surviving.
    _note() { printf '{"annotation_level":"notice","title":"claim-retirement","message":"claim-retirement %s"}' "$1"; }
    _record() { printf '[%s]' "$*" > "${_ctl}/record.json"; }

    _turn_for() { ( cd "$_read" && PATH="${_bin}:$PATH" \
        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 sh "$_turn" "$1" ) 2>&1 || true; }
    _tick() { ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_step" --tick "$1" --root "$_read" ) 2>&1 || true; }
    _unit_turn() { printf '%s' "$1" | jq -r --arg u "$2" \
        '[.units[]? | select(.unit == $u) | .ci_turn] | first // "ABSENT"' 2>/dev/null || printf 'ABSENT'; }

    # 1. A TURN WHOSE CANDIDATE READING NAMED THIS UNIT NOTHING. The tree proves the candidate
    # stands; the record shows the turn's own reader could not name it, and why. The reading
    # carries that reason through rather than inventing one, and `taken` is the one answer that
    # must never come back -- it is what the measured run answered.
    _record "$(_note 'candidates ok=false reason=origin_unreachable count=0')"
    _t1=$(_turn_for batch-effect-unnamed)
    _s1=$(_tick 20260301-000001)
    if [ "$(_unit_turn "$_t1" batch-effect-unnamed)" = "refused:origin_unreachable" ] \
        && printf '%s' "$_s1" | grep -q 'retire-blocked:batch-effect-unnamed'; then
        add_row "act_effect_unnamed_candidate" true "a turn that considered this unit nothing never reads taken, and its holder is asked" load
    else
        add_row "act_effect_unnamed_candidate" false "a completed turn that named this unit no candidate left it standing with nothing saying so (turn=$(one_line "$_t1")): $(one_line "$_s1")" load
    fi

    # 2. A TURN WHOSE ACT WAS REFUSED BY ONE OF ITS OWN WORDS. This is the cause measured live
    # on this repository, and the word must reach the reading verbatim rather than be flattened.
    _record "$(_note 'candidates ok=true reason= count=1')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=not_attempted reason=gh_unavailable')"
    _t2=$(_turn_for batch-effect-refused)
    _s2=$(_tick 20260301-000002)
    if [ "$(_unit_turn "$_t2" batch-effect-refused)" = "refused:gh_unavailable" ] \
        && printf '%s' "$_s2" | grep -q 'retire-blocked:batch-effect-refused'; then
        add_row "act_effect_refused_act" true "a refused act reads refused:gh_unavailable, carrying the act's own word, and reaches its holder" load
    else
        add_row "act_effect_refused_act" false "a refused act was not read as refused (turn=$(one_line "$_t2")): $(one_line "$_s2")" load
    fi

    # 3. THE MEASURED FAILURE ITSELF: a completed, green run at the base tip that recorded
    # NOTHING. Answering `taken` from its existence is the inference this mission retires, and a
    # reading that cannot be made must never be dressed as one that was.
    _record ""
    _t3=$(_turn_for batch-effect-silent)
    _s3=$(_tick 20260301-000003)
    if [ "$(_unit_turn "$_t3" batch-effect-silent)" = "unreadable" ] \
        && printf '%s' "$_s3" | grep -q 'retire-blocked:batch-effect-silent'; then
        add_row "act_effect_never_taken_from_existence" true "a completed run that recorded nothing reads unreadable, never taken, and suppresses no question" load
    else
        add_row "act_effect_never_taken_from_existence" false "a completed run with no record still stood in for an act that did not happen (turn=$(one_line "$_t3")): $(one_line "$_s3")" load
    fi

    # 4. THE TURN RECORDS WHAT IT ATTEMPTED. Run for real against the two documents the CI job
    # produces, so the record's shape is proved rather than asserted about a YAML file. The
    # DEGRADED reading is recorded too -- a turn that found nothing and a turn that found three
    # and was refused are different facts, and the first is the one the report assumed.
    _rec="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/record-ci-retirement-turn.sh"
    printf '{"ok": false, "reason": "origin_unreachable", "candidates": []}\n' > "${_ctl}/c-degraded.json"
    printf '{"ok": true, "reason": "", "candidates": [{"unit":"u1"},{"unit":"u2"}]}\n' > "${_ctl}/c-ok.json"
    printf '%s\n%s\n' \
        '{"deleted": false, "unit": "u1", "branch": "work-20260301-000001", "state": "not_attempted", "reason": "gh_unavailable"}' \
        '{"deleted": true, "unit": "u2", "branch": "work-20260301-000002", "state": "deleted", "reason": ""}' \
        > "${_ctl}/acts.jsonl"
    _rd=$(sh "$_rec" --candidates "${_ctl}/c-degraded.json" --acts "${_ctl}/none" 2>&1 || true)
    _ro=$(sh "$_rec" --candidates "${_ctl}/c-ok.json" --acts "${_ctl}/acts.jsonl" 2>&1 || true)
    if printf '%s' "$_rd" | grep -q 'candidates ok=false reason=origin_unreachable count=0' \
        && printf '%s' "$_ro" | grep -q 'candidates ok=true reason= count=2'; then
        add_row "act_effect_record_names_the_reading" true "the candidate reading is recorded with its ok, its reason and its count -- including the degraded one that named nothing" load
    else
        add_row "act_effect_record_names_the_reading" false "the candidate reading was not recorded (degraded=$(one_line "$_rd") ok=$(one_line "$_ro"))" load
    fi

    # 5. AND ONE ENTRY PER CANDIDATE, CARRYING THE ACT'S OWN WORDS VERBATIM. A translation here
    # would put a second vocabulary between the script that printed a word and the person a
    # reader must send to it.
    if printf '%s' "$_ro" | grep -q 'act unit=u1 branch=work-20260301-000001 state=not_attempted reason=gh_unavailable' \
        && printf '%s' "$_ro" | grep -q 'act unit=u2 branch=work-20260301-000002 state=deleted reason='; then
        add_row "act_effect_record_names_each_act" true "each candidate is recorded with its unit, branch and the act's own state and reason, unchanged" load
    else
        add_row "act_effect_record_names_each_act" false "the per-candidate record is wrong: $(one_line "$_ro")" load
    fi

    # 6. IT IS BOUNDED, AND A TRUNCATED RECORD SAYS SO rather than reading as a short one.
    _rt=$(WORKAHOLIC_CI_RECORD_MAX=1 sh "$_rec" --candidates "${_ctl}/c-ok.json" --acts "${_ctl}/acts.jsonl" 2>&1 || true)
    if printf '%s' "$_rt" | grep -q 'truncated recorded=1 of=2' \
        && [ "$(printf '%s' "$_rt" | grep -c 'act unit=')" = "1" ]; then
        add_row "act_effect_record_bounded" true "past the bound the record names how many it recorded of how many there were" load
    else
        add_row "act_effect_record_bounded" false "a truncated record did not say it truncated: $(one_line "$_rt")" load
    fi

    # 7. AND THE WORKFLOW CALLS IT ON EVERY PATH. The degraded reading used to `exit 0` before
    # anything was recorded, which is exactly the turn whose silence was measured.
    _wf=$(cat "$_flow" 2>/dev/null || true)
    if printf '%s' "$_wf" | grep -q 'record-ci-retirement-turn.sh' \
        && printf '%s' "$_wf" | grep -q 'if: always()' \
        && ! printf '%s' "$_wf" | grep -q '^ *exit 0 *$'; then
        add_row "act_effect_workflow_records" true "the turn records on every path, including the degraded reading it used to exit on" load
    else
        add_row "act_effect_workflow_records" false "the workflow does not reach the recorder on every path" load
    fi

    # 8. ONE READER ANSWERS THE QUESTION FOR BOTH ACTS, and for the retirement it answers the
    # SAME WORD as the act's own source read directly. A composition that could answer on its
    # own would be the second oracle this mission's constraint forbids.
    _eff="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/act-effect.sh"
    _record "$(_note 'candidates ok=true reason= count=1')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=not_attempted reason=gh_unavailable')"
    _direct=$(_unit_turn "$(_turn_for batch-effect-refused)" batch-effect-refused)
    _via=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_eff" retirement batch-effect-refused ) 2>&1 || true )
    _via_word=$(printf '%s' "$_via" | jq -r '.effect // ""' 2>/dev/null || printf '')
    if [ -n "$_direct" ] && [ "$_direct" = "$_via_word" ] \
        && printf '%s' "$_via" | grep -q '"source": "ci-retirement-turn.sh"'; then
        add_row "act_effect_one_reader_retirement" true "the composition returns the act's own word (${_direct}) and names the source it composed" load
    else
        add_row "act_effect_one_reader_retirement" false "direct='${_direct}' via composition='${_via_word}': $(one_line "$_via")" load
    fi

    # 9. AND THE DELIVERY ACT IS ANSWERED FROM ITS OWN SOURCE -- the branch story the run that
    # attempted the merge already committed, read off the claim row the scan already fetched.
    # The word is carried VERBATIM: the two acts' refusal vocabularies are never merged into a
    # third, which would send a reader to a string no script ever printed.
    ( cd "$_work" && git checkout -q work-20260301-000002 \
      && mkdir -p .workaholic/stories \
      && printf -- '---\ntype: Story\n---\n\n# S\n\n## Merge Outcome\n\nmerge_refused:session_type_cannot_merge\n' \
             > .workaholic/stories/work-20260301-000002.md \
      && _git add -A && _git commit -qm "Report the branch story" \
      && git push -q origin work-20260301-000002 ) >/dev/null 2>&1 || true
    ( cd "$_read" && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    _dl=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_eff" delivery batch-effect-refused ) 2>&1 || true )
    _dn=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_eff" delivery batch-effect-silent ) 2>&1 || true )
    if printf '%s' "$_dl" | grep -q '"effect": "refused:session_type_cannot_merge"' \
        && printf '%s' "$_dn" | grep -q '"effect": "pending"'; then
        add_row "act_effect_one_reader_delivery" true "the delivery act's own recorded word is carried verbatim, and a branch with no recorded attempt reads pending" load
    else
        add_row "act_effect_one_reader_delivery" false "the delivery reading is wrong (recorded=$(one_line "$_dl") none=$(one_line "$_dn"))" load
    fi

    # 10. THE CHANGED-REFUSAL NARROWING, over three ticks against the real asked-once gate:
    # one word asks, the SAME word on a later tick does not, and a DIFFERENT word asks once more.
    # The gate itself is untouched -- the narrowing lives in what the key is made of, which is
    # why one mechanism cannot drift from itself.
    _askscript="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _logappend="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh"
    _qroot=$(mktemp -d); mkdir -p "${_qroot}/.workaholic/moderations"
    _keyof() { printf '%s' "$1" | jq -r '[.needs_agent[]?.blocked_retirements[]? | select(.unit == "batch-effect-refused") | .key] | first // ""' 2>/dev/null || printf ''; }
    _ask() { # $1 = tick, $2 = key -> "true"/"false"
        _a=$(cd "$REPO_ROOT" && sh "$_askscript" --tick "$1" --key "$2" --root "$_qroot" \
            --to "$_me" --hour 10 --weekday 1 2>&1) || true
        _ls=$(printf '%s' "$_a" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p')
        if printf '%s' "$_a" | grep -q '"ask": true'; then
            sh "$_logappend" --root "$_qroot" --tick "$1" --step "$_ls" --status ok \
                --summary asked >/dev/null 2>&1 || true
            printf 'true'
        else
            printf 'false'
        fi
    }
    _record "$(_note 'candidates ok=true reason= count=1')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=not_attempted reason=gh_unavailable')"
    _k1=$(_keyof "$(_tick 20260301-000010)")
    _k2=$(_keyof "$(_tick 20260301-000011)")
    _record "$(_note 'candidates ok=true reason= count=1')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=not_attempted reason=pull_request_open')"
    _k3=$(_keyof "$(_tick 20260301-000012)")
    _r1=$(_ask 20260301-000010 "$_k1")
    _r2=$(_ask 20260301-000011 "$_k2")
    _r3=$(_ask 20260301-000012 "$_k3")
    if [ "$_k1" = "retire-blocked:batch-effect-refused:gh_unavailable" ] \
        && [ "$_k1" = "$_k2" ] && [ "$_k3" = "retire-blocked:batch-effect-refused:pull_request_open" ] \
        && [ "$_r1" = "true" ] && [ "$_r2" = "false" ] && [ "$_r3" = "true" ]; then
        add_row "act_effect_changed_word_reasks" true "one word asks, the unchanged word is held, and a changed word asks exactly once more" load
    else
        add_row "act_effect_changed_word_reasks" false "the narrowing did not hold (keys '${_k1}' '${_k2}' '${_k3}'; asks ${_r1} ${_r2} ${_r3})" load
    fi
    rm -rf "$_qroot"

    # 11. THE FINDING REACHES THE ROOT, AND ONLY WHEN IT IS NEWS. A tick whose acts did not take
    # supplies an `event` naming the units; a tick whose acts all TOOK supplies none, so a
    # healthy hour renders no line at all. The unchanged-reading case is covered by the root's
    # own diff, which reads the SUMMARY -- and the summary carries no CI term, so a standing
    # block renders an identical string tick after tick. Both guards are asserted rather than
    # re-implemented here.
    _record "$(_note 'candidates ok=true reason= count=1')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=not_attempted reason=gh_unavailable')"
    _e1=$(_tick 20260301-000020)
    _record "$(_note 'candidates ok=true reason= count=3')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=deleted reason=')," \
            "$(_note 'act unit=batch-effect-silent branch=work-20260301-000003 state=deleted reason=')," \
            "$(_note 'act unit=batch-effect-unnamed branch=work-20260301-000001 state=already_gone reason=')"
    _e2=$(_tick 20260301-000021)
    _ev1=$(printf '%s' "$_e1" | jq -r '.event // ""' 2>/dev/null || printf '')
    _ev2=$(printf '%s' "$_e2" | jq -r '.event // ""' 2>/dev/null || printf '')
    _sm1=$(printf '%s' "$_e1" | jq -r '.summary // ""' 2>/dev/null || printf '')
    _sm2=$(printf '%s' "$_e2" | jq -r '.summary // ""' 2>/dev/null || printf '')
    if printf '%s' "$_ev1" | grep -q 'still standing' \
        && printf '%s' "$_ev1" | grep -q 'batch-effect-refused' \
        && [ -z "$_ev2" ] && [ "$_sm1" = "$_sm2" ]; then
        add_row "act_effect_event_names_the_units" true "a tick whose acts did not take names the units in its event; a tick whose acts took supplies none, and the summary is identical across both so an unchanged reading renders no line" load
    else
        add_row "act_effect_event_names_the_units" false "the event is wrong (blocked='${_ev1}' took='${_ev2}'; summaries equal=$([ "$_sm1" = "$_sm2" ] && echo yes || echo no))" load
    fi

    # THE DELIBERATELY BROKEN ROW, WRITTEN AGAINST THE BEHAVIOUR. The retired inference is
    # restored on the REAL script's own source -- after a completed run is found at the base tip,
    # answer `taken` for every unit without ever consulting what the turn recorded -- and the
    # copied step is run against it. A breaker written against the return SHAPE would pass a
    # refactor that keeps the JSON and loses the effect reading, which is the failure the
    # register exists to catch, so this asserts the DAMAGE: the unit whose act was refused
    # `gh_unavailable` is suppressed and its holder is told nothing.
    #
    # It is worse now than the defect that was measured, and deliberately so: in production the
    # inference produced a false SENTENCE while the question still went out, because suppression
    # was keyed on a run-level `pending`. With the reading per unit, restoring the inference
    # drops the question outright.
    cp -R "${REPO_ROOT}/plugins/workaholic/skills" "${_tmp}/skills"
    _bturn="${_tmp}/skills/drive/scripts/ci-retirement-turn.sh"
    _bstep2="${_tmp}/skills/moderate/scripts/step-retire-claims.sh"
    sed -e 's|^record=""$|emit true "" taken "$(units_all taken $UNITS)"\nrecord=""|' \
        "$_turn" > "$_bturn"
    chmod +x "$_bturn"
    _record "$(_note 'candidates ok=true reason= count=1')," \
            "$(_note 'act unit=batch-effect-refused branch=work-20260301-000002 state=not_attempted reason=gh_unavailable')"
    _bout=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        sh "$_bstep2" --tick 20260301-000030 --root "$_read" ) 2>&1 || true )
    if ! printf '%s' "$_bout" | grep -q 'retire-blocked:batch-effect-refused'; then
        add_row "act_effect_breaker" true "with the run-existence inference restored, a unit CI refused gh_unavailable reaches nobody -- this drill can fail" breaker
    else
        add_row "act_effect_breaker" false "the breaker did not break: restoring the inference changed nothing, so the reading assertions above prove nothing ($(one_line "$_bout"))" breaker
    fi

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "act_effect_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "act_effect_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "act-effect" 0 "fail" 1
    fi
    emit_verdict "act-effect" 0 "pass" 0
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
        add_row "base_health_can_fail" true "INTENTIONAL CASE: a commit with no checks is unanswerable, never green -- this drill can fail" breaker
    else
        add_row "base_health_can_fail" false "INTENTIONAL CASE: a commit with no checks did not read unanswerable: $(one_line "$_broken")" breaker
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
        add_row "retry_unrecorded_never_tried" true "an unrecorded outcome is never retried, so no merge rests on an assumption -- this drill can fail" breaker
    else
        add_row "retry_unrecorded_never_tried" false "an unrecorded outcome reached the merge seam: $(one_line "$_silent")" breaker
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
        add_row "handoff_question_releases_on_drive" false "a unit whose declaring ticket was driven is still asked about -- the reading consulted the ARCHIVED work" breaker
    else
        add_row "handoff_question_releases_on_drive" true "a unit whose declaring ticket was driven is not asked about -- the reading is self-releasing (this drill can fail)" breaker
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
        add_row "return_path_breaker" false "the breaker row did not break the seam, so this drill cannot fail" breaker
    else
        add_row "return_path_breaker" true "a step wired at the channel fails the bound check the real step passes (this drill can fail)" breaker
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

cmd_verify_reconcile() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/reconcile-candidates.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-thread-reconcile.sh"
    _append="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh"
    _catalog="${REPO_ROOT}/plugins/workaholic/skills/notify/reference/notifications.md"
    _template="${REPO_ROOT}/plugins/workaholic/skills/workaholify/routines/moderate.md"
    for _f in "$_reader" "$_step" "$_append" "$_catalog" "$_template"; do
        [ -f "$_f" ] || emit_err "reconcile_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _fx="${_tmp}/repo"; _bin="${_tmp}/bin"
    mkdir -p "$_bin"

    # --- The fixture: a repository whose merge commits published the units ---------------
    mkdir -p "${_fx}/.workaholic/feedbacks" "${_fx}/.workaholic/missions/active/alpha" \
             "${_fx}/.workaholic/missions/active/beta" "${_fx}/.workaholic/moderations"
    ( cd "$_fx" && git init -q . \
      && git config user.email drill@example.com && git config user.name Drill \
      && git remote add origin git@github.com:acme-org/drill-repo.git ) >/dev/null 2>&1
    printf -- '---\ntype: Feedback\n---\n\nan ask\n' \
        > "${_fx}/.workaholic/feedbacks/20260828010101-an-ask.md"
    printf -- '---\ntype: Feedback\n---\n\nanother ask\n' \
        > "${_fx}/.workaholic/feedbacks/20260828010202-another-ask.md"
    printf -- '---\ntype: Mission\nslug: alpha\nfeedback: [20260828010101-an-ask.md]\n---\n\n# Alpha\n' \
        > "${_fx}/.workaholic/missions/active/alpha/mission.md"
    printf -- '---\ntype: Mission\nslug: beta\nfeedback: [20260828010202-another-ask.md]\n---\n\n# Beta\n' \
        > "${_fx}/.workaholic/missions/active/beta/mission.md"
    ( cd "$_fx" && git add -A && git commit -q -m "Seed the drill tree" ) >/dev/null 2>&1
    _base=$( cd "$_fx" && git branch --show-current )
    _land() {
        ( cd "$_fx" && git checkout -q -b "$1" \
          && printf 'landed on %s\n' "$1" >> ".workaholic/missions/active/${2}/mission.md" \
          && git add -A && git commit -q -m "Drive the unit" \
          && git checkout -q "$_base" \
          && git merge -q --no-ff -m "Merge PR #${3} from acme-org/${1}" "$1" ) >/dev/null 2>&1
    }
    _land work-20260828-010000 alpha 11
    # #12 is CLOSED WITHOUT MERGING: no merge commit, no story on the base, nothing archived —
    # exactly the shape only the pull request's own changed files can resolve.
    ( cd "$_fx" && git checkout -q -b work-20260828-020000 \
      && printf 'not landed\n' >> ".workaholic/missions/active/beta/mission.md" \
      && git add -A && git commit -q -m "Drive the unit" \
      && git checkout -q "$_base" ) >/dev/null 2>&1

    _now=$(date -u +%s)
    _iso() { date -u -d "@$(( _now - $1 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -r "$(( _now - $1 ))" +%Y-%m-%dT%H:%M:%SZ; }
    _t11=$(_iso 7200); _t12=$(_iso 10800)

    # The stub answers the two calls the reader makes and NOTHING else: a query this drill did
    # not anticipate must fail loudly rather than return a plausible empty answer.
    _write_stub() {
        {
            printf '#!/bin/sh\ncase "$*" in\n'
            printf '  *"pulls?state=closed"*"page=1"*) printf "%%b\\\\n" "11\\twork-20260828-010000\\t%s\\t%s\\thttps://example.invalid/pull/11\\tAlpha\\n12\\twork-20260828-020000\\t-\\t%s\\thttps://example.invalid/pull/12\\tBeta"; exit 0 ;;\n' \
                "$_t11" "$_t11" "$_t12"
            printf '  *"pulls?state=closed"*) exit 0 ;;\n'
            printf '  *pulls/11*) printf "a-person\\n"; exit 0 ;;\n'
            printf '  *pulls/12/files*) printf ".workaholic/missions/active/beta/mission.md\\n"; exit 0 ;;\n'
            printf '  *pulls/12*) printf "\\n"; exit 0 ;;\n'
            printf 'esac\necho "unexpected gh call: $*" >&2; exit 1\n'
        } > "${_bin}/gh"
        chmod +x "${_bin}/gh"
    }
    _write_stub
    if [ "$(PATH="${_bin}:$PATH" command -v gh)" = "${_bin}/gh" ]; then
        add_row "reconcile_no_network" true "the stub is what gh resolves to, so no row below reaches the network" load
    else
        add_row "reconcile_no_network" false "gh does not resolve to the stub; this drill would reach the network" load
        rm -rf "$_tmp"
        emit_verdict "reconcile" 0 "fail" 1
    fi

    _in() { ( cd "$_fx" && PATH="${_bin}:$PATH" WORKAHOLIC_BASE_REF="$_base" "$@" ) 2>&1 || true; }

    # 1. THE HAND-MERGED UNIT IS A CANDIDATE, with its stems, its pull request, and by whom and when.
    _cands=$(_in sh "$_reader" --root "$_fx" --window-days 3)
    if printf '%s' "$_cands" | grep -q '"number": 11' \
        && printf '%s' "$_cands" | grep -q '"state": "merged"' \
        && printf '%s' "$_cands" | grep -q '"merged_by": "a-person"' \
        && printf '%s' "$_cands" | grep -q '20260828010101-an-ask'; then
        add_row "reconcile_merged_named" true "the hand-merged unit is a candidate with its stems, its pull request and who merged it when" load
    else
        add_row "reconcile_merged_named" false "the merged unit is not named correctly: $(one_line "$_cands")" load
    fi

    # 2. A CLOSED-UNMERGED UNIT IS ITS OWN STATE, never collapsed into `merged`: the two ask a
    # reader for different things, which is exactly why the catalog gives them two shapes.
    if printf '%s' "$_cands" | grep -q '"number": 12' \
        && printf '%s' "$_cands" | grep -q '"state": "closed"'; then
        add_row "reconcile_closed_is_its_own_state" true "a pull request closed without merging reads closed, never merged" load
    else
        add_row "reconcile_closed_is_its_own_state" false "the closed-unmerged unit is missing or mislabelled: $(one_line "$_cands")" load
    fi
    _shapes_ok=true
    for _lead in '. Implemented - \[#123 Title\]' '. Closed - \[#123 Title\]'; do
        grep -q "$_lead" "$_catalog" || _shapes_ok=false
        grep -q "$_lead" "$_template" || _shapes_ok=false
    done
    grep -q 'no run posted this item.s finish' "$_catalog" || _shapes_ok=false
    if [ "$_shapes_ok" = true ]; then
        add_row "reconcile_both_shapes_named" true "the catalog names the merged and the closed-unmerged reply, and the routine authorizes both" load
    else
        add_row "reconcile_both_shapes_named" false "a reply shape is missing from the catalog or from the routine template" load
    fi

    # 3. THE THREAD BAR, DRILLED AS WRITTEN. The read itself belongs to the session (Slack is a
    # connector, not a script), so what is drillable here is the BAR the contract states: only a
    # LATEST status of the two in-flight colours is a candidate. Four fixture threads, four verdicts.
    _bar() {
        [ -s "$1" ] || { printf 'no_thread'; return; }
        _last=$(grep -v '^[[:space:]]*$' "$1" | tail -1)
        case "$_last" in
            "$_PROPOSED"*|"$_HANDOFF"*) printf 'post' ;;
            '') printf 'no_thread' ;;
            *)  printf 'already_finished' ;;
        esac
    }
    _PROPOSED=$(printf '\360\237\224\265')
    _HANDOFF=$(printf '\360\237\237\241')
    _DONE=$(printf '\360\237\237\242')
    printf '%s Proposed - #10\n%s Handoff - #11\n' "$_PROPOSED" "$_HANDOFF" > "${_tmp}/th-handoff"
    printf '%s Proposed - #10\n%s Implemented - #11\n' "$_PROPOSED" "$_DONE" > "${_tmp}/th-finished"
    printf '%s Handoff - #11\n%s Implemented - #11\n' "$_HANDOFF" "$_DONE" > "${_tmp}/th-reconciled"
    : > "${_tmp}/th-missing"
    if [ "$(_bar "${_tmp}/th-handoff")" = post ] \
        && [ "$(_bar "${_tmp}/th-finished")" = already_finished ] \
        && [ "$(_bar "${_tmp}/th-reconciled")" = already_finished ] \
        && [ "$(_bar "${_tmp}/th-missing")" = no_thread ]; then
        add_row "reconcile_thread_bar" true "a handoff thread is corrected; a finished thread and one this loop already reconciled are never touched; no thread means nothing to correct" load
    else
        add_row "reconcile_thread_bar" false "the stated bar does not classify the four fixture threads correctly" load
    fi

    # 4. THE BOUNDS ARE HANDED TO THE AGENT IN WORDS, and asserted rather than trusted.
    _out=$(_in sh "$_step" --tick 20260828-070000 --root "$_fx")
    if printf '%s' "$_out" | grep -q 'AT MOST TWO queries' \
        && printf '%s' "$_out" | grep -q 'no channel history read anywhere' \
        && ! printf '%s' "$_out" | grep -q 'window_hours'; then
        add_row "reconcile_two_queries" true "at most two exact-string searches per candidate, and no channel history read is named anywhere" load
    else
        add_row "reconcile_two_queries" false "the lookup bound is not carried to the agent: $(one_line "$_out")" load
    fi
    if printf '%s' "$_out" | grep -q 'case 4 does NOT apply'; then
        add_row "reconcile_case4_refused" true "a lookup that finds no thread posts nothing - the description root is refused by name" load
    else
        add_row "reconcile_case4_refused" false "case 4 is not refused, so a merge nobody was told about could be announced: $(one_line "$_out")" load
    fi
    _reasons_ok=true
    for _r in no_thread already_finished unsure no_slack_transport thread_unreadable post_failed; do
        printf '%s' "$_out" | grep -q "$_r" || _reasons_ok=false
    done
    if [ "$_reasons_ok" = true ] && printf '%s' "$_out" | grep -q 'non-conformant on its face'; then
        add_row "reconcile_one_outcome_each" true "every candidate owes exactly one outcome, and each named not-posted reason travels with the request" load
    else
        add_row "reconcile_one_outcome_each" false "the outcome vocabulary is incomplete: $(one_line "$_out")" load
    fi

    # 5. THE CAP IS HONOURED AND THE REMAINDER REPORTED, never silently dropped.
    _capped=$( cd "$_fx" && PATH="${_bin}:$PATH" WORKAHOLIC_BASE_REF="$_base" \
        WORKAHOLIC_RECONCILE_READ_MAX=1 sh "$_step" --tick 20260828-090000 --root "$_fx" 2>&1 || true )
    if printf '%s' "$_capped" | grep -q 'beyond the 1-read bound' \
        && printf '%s' "$_capped" | grep -q '"beyond_bound":1'; then
        add_row "reconcile_cap_reported" true "the candidate cap is honoured and the number beyond it is reported rather than dropped" load
    else
        add_row "reconcile_cap_reported" false "the cap is not reported: $(one_line "$_capped")" load
    fi

    # 6. THE SAME TICK RUN TWICE HANDS BACK NOTHING THE SECOND TIME. The real dedup is
    # structural - the agent reads the thread before writing - and the ledger saves the lookup.
    _in sh "$_append" --root "$_fx" --tick 20260828-060000 --step thread-reconcile-filed \
        --status ok --summary "thread-reconcile:11 posted; thread-reconcile:12 posted" >/dev/null
    _out2=$(_in sh "$_step" --tick 20260828-080000 --root "$_fx")
    if printf '%s' "$_out2" | grep -q '"needs_agent": \[\]' \
        && printf '%s' "$_out2" | grep -q '2 already reconciled'; then
        add_row "reconcile_second_tick_silent" true "a second tick over the same items hands back nothing and counts them as already reconciled" load
    else
        add_row "reconcile_second_tick_silent" false "a second tick would read the same threads again: $(one_line "$_out2")" load
    fi

    # 7. A REFUSED READ IS NAMED and hands back nothing - "nothing was looked at" must never
    # render as "nothing is stale".
    printf '#!/bin/sh\nexit 1\n' > "${_bin}/gh"; chmod +x "${_bin}/gh"
    _deg=$(_in sh "$_step" --tick 20260828-100000 --root "$_fx")
    if printf '%s' "$_deg" | grep -q '"status": "degraded"' \
        && printf '%s' "$_deg" | grep -q 'candidates_list_failed' \
        && printf '%s' "$_deg" | grep -q '"needs_agent": \[\]'; then
        add_row "reconcile_degrades_by_name" true "a transport that refused is reported by name with no candidate handed back" load
    else
        add_row "reconcile_degrades_by_name" false "a refused read is not named, or hands back candidates anyway: $(one_line "$_deg")" load
    fi
    _write_stub

    # 8. WHAT IT NEVER DOES, asserted over the two scripts themselves.
    _acts=$(sed -e 's/^[[:space:]]*#.*$//' "$_reader" "$_step" \
        | grep -nE 'method (PUT|PATCH|DELETE)|git (push|branch|checkout|merge|commit)|claim\.sh|release-claim\.sh|retire-claim\.sh' \
        || true)
    if [ -z "$_acts" ]; then
        add_row "reconcile_acts_on_nothing" true "neither script merges, closes, branches, commits or touches a claim" load
    else
        add_row "reconcile_acts_on_nothing" false "an acting call site is present: $(one_line "$_acts")" load
    fi
    _dirty=$( cd "$_fx" && git status --porcelain | grep -v 'workaholic/moderations/' || true )
    if [ -z "$_dirty" ]; then
        add_row "reconcile_writes_only_its_log" true "the fixture's tree carries nothing but the tick's own log line" load
    else
        add_row "reconcile_writes_only_its_log" false "the step wrote into the tree: $(one_line "$_dirty")" load
    fi

    # 9. THE BREAKER ROW, LABELLED AS THE INTENTIONAL FAILURE. A candidate reader wired at the
    # CHANNEL instead of the repository is the design inverted back into a channel scan - the
    # one thing `workaholic:notify`'s no-full-channel-read bound forbids outright.
    _chan="${_tmp}/channel"
    mkdir -p "$_chan"
    printf '#!/bin/sh\ncase "${1:-}" in\n  slug) printf "acme-org/drill-repo\\n" ;;\n  *) printf "a person asked something\\nsomebody replied\\n" ;;\nesac\n' \
        > "${_chan}/gh-rest.sh"
    chmod +x "${_chan}/gh-rest.sh"
    _broken="${_tmp}/broken-reconcile-candidates.sh"
    sed -e "s#^GATHER=.*#GATHER=\"${_chan}\"#" "$_reader" > "$_broken"
    chmod +x "$_broken"
    _bout=$( cd "$_fx" && PATH="${_bin}:$PATH" WORKAHOLIC_BASE_REF="$_base" \
        sh "$_broken" --root "$_fx" --window-days 3 2>&1 || true )
    if printf '%s' "$_bout" | grep -q '"number": 11'; then
        add_row "reconcile_breaker" false "the breaker row did not break the seam, so this drill cannot fail" breaker
    else
        add_row "reconcile_breaker" true "a candidate reader wired at the channel names no candidate, so row 1 fails there (this drill can fail)" breaker
    fi

    # 10. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "reconcile_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "reconcile_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "reconcile" 0 "fail" 1
    fi
    emit_verdict "reconcile" 0 "pass" 0
}

# ------------------------------------------------------- verify-checkin-delivery
# Does the loop's one path from a machine finding to a person actually deliver?
#
# WHY A DRILL AND NOT ONLY UNIT TESTS. The suite pins `ask-question.sh` in isolation, and it
# passed throughout the eleven days the channel was jammed: every part was internally
# consistent and the delivery failed IN THE SEAMS — an unbounded day count in the gate, an
# alphabetical order in the step, and a root with no event to carry the failure. This walks
# the whole path — gate, ordering, step, event, root — over one fixture log spanning several
# days, with **no network, no `gh`, no Slack post and no touch of the working tree**.
#
# IT IS DETERMINISTIC. The day comes from the tick id and `--hour`/`--weekday` are injected,
# so the drill does not pass or fail by the date it is run on — the reason both are
# injectable in the first place (the working-week gate's very first suite run was on a
# Saturday and reported `off_day` for everything).
cmd_verify_checkin_delivery() {
    _ask="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh"
    _render="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/render-tick-post.sh"
    _log="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh"
    for _f in "$_ask" "$_step" "$_render" "$_log"; do
        [ -f "$_f" ] || emit_err "checkin_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    mkdir -p "${_fx}/.workaholic"
    # A working Wednesday at 14:00, injected everywhere.
    _when="--hour 14 --weekday 3"
    _append() { sh "$_log" --root "$_fx" --tick "$1" --step "$2" --status "$3" --summary "$4" >/dev/null 2>&1 || true; }
    _reason() { printf '%s' "$1" | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p' | head -1; }
    # Each held entry is `{"key": …, "reason": …}` — the gate's own refusal word per key.
    # The keys are what the drain order is asserted on; the words have their own rows below.
    _held() {
        printf '%s' "$1" | sed -n 's/.*"held": \[\([^]]*\)\].*/\1/p' |
            tr '{' '\n' | sed -n 's/.*"key": *"\([^"]*\)".*/\1/p' |
            tr '\n' ',' | sed 's/,$//'
    }
    _held_reasons() {
        printf '%s' "$1" | sed -n 's/.*"held": \[\([^]]*\)\].*/\1/p' |
            tr '{' '\n' | sed -n 's/.*"reason": *"\([a-z_]*\)".*/\1/p' |
            tr '\n' ',' | sed 's/,$//'
    }

    # 1. THE FIXTURE: `max_per_day` asks on EARLIER days, holds first recorded on three
    #    different days, and nothing of either on the tick's own day.
    # Ten of them — `max_per_day` exactly — across five earlier days, two per day. The tick
    # ids are written out rather than computed, because an id that fails `log-append.sh`'s
    # own shape check writes nothing and would silently leave the fixture one short of the
    # cap, which is the difference between drilling the bound and drilling nothing.
    for _d in 21 22 23 24 25; do
        _append "202608${_d}-090000" "human-checkin-ask-past-${_d}a" filed "asked past ${_d}a"
        _append "202608${_d}-100000" "human-checkin-ask-past-${_d}b" filed "asked past ${_d}b"
    done
    # Held oldest-first is yak, zebra, alpha, bravo, charlie, delta, echo — deliberately not
    # alphabetical, so a `sort -u` regression cannot pass this by accident.
    _append 20260825-090000 human-checkin-held-yak     skipped "held yak"
    _append 20260826-100000 human-checkin-held-zebra   skipped "held zebra"
    _append 20260826-110000 human-checkin-held-alpha   skipped "held alpha"
    _append 20260827-090000 human-checkin-held-bravo   skipped "held bravo"
    _append 20260827-100000 human-checkin-held-charlie skipped "held charlie"
    _append 20260827-110000 human-checkin-held-delta   skipped "held delta"
    _append 20260827-120000 human-checkin-held-echo    skipped "held echo"

    # 2. THE HELD QUESTION LANDS. On a tree whose day count is unbounded this is refused
    #    `day_cap`; bounded to the tick's own day it is asked.
    _g=$(sh "$_ask" --root "$_fx" --tick 20260828-140000 --key "q:yak" $_when 2>&1 || true)
    case "$_g" in
        *'"ask": true'*)
            add_row "checkin_held_lands" true "a question held on an earlier day is asked on a working weekday inside the window" load ;;
        *)
            add_row "checkin_held_lands" false "the held question was refused $(_reason "$_g"): $(one_line "$_g")" load ;;
    esac

    # 3. THE SECOND TICK DOES NOT RE-ASK IT. Asked once, not once an hour — unchanged.
    _slug=$(printf '%s' "$_g" | sed -n 's/.*"log_step": *"\([a-z0-9-]*\)".*/\1/p' | head -1)
    [ -n "$_slug" ] || _slug=human-checkin-ask-q-yak
    _append 20260828-140000 "$_slug" filed "asked q:yak"
    _g2=$(sh "$_ask" --root "$_fx" --tick 20260828-150000 --key "q:yak" $_when 2>&1 || true)
    if [ "$(_reason "$_g2")" = "already_asked" ]; then
        add_row "checkin_not_reasked" true "the same question is refused already_asked on the next tick" load
    else
        add_row "checkin_not_reasked" false "expected already_asked, got: $(one_line "$_g2")" load
    fi

    # 4. THE DRAIN HONOURS `max_per_tick`, OLDEST-HELD FIRST, AND THE REMAINDER STAYS HELD.
    #    This is the agent's loop, run mechanically: walk the ordered list, gate each one,
    #    record the ask when the gate allows it, and stop when it stops allowing.
    _s=$(sh "$_step" --root "$_fx" --tick 20260828-160000 $_when 2>&1 || true)
    _order=$(_held "$_s")
    case "$_order" in
        yak,*|zebra,*)
            add_row "checkin_drain_order" true "the arrears are handed back oldest-held first: ${_order}" load ;;
        *)
            add_row "checkin_drain_order" false "expected the oldest hold first, got: ${_order}" load ;;
    esac
    _asked=''
    _n=0
    for _k in $(printf '%s' "$_order" | tr ',' ' '); do
        _r=$(sh "$_ask" --root "$_fx" --tick 20260828-160000 --key "$_k" $_when --max-per-day 50 2>&1 || true)
        case "$_r" in
            *'"ask": true'*)
                _n=$((_n + 1))
                _asked="${_asked:+${_asked} }${_k}"
                # ONE line per ask, under the id the gate returned. It already begins with
                # `human-checkin-ask-<key>`, so it is what drops the key out of the held set
                # as well — recording a second line would count the same ask twice against
                # `tick_cap` and the drain would stop three questions early.
                _st=$(printf '%s' "$_r" | sed -n 's/.*"log_step": *"\([a-z0-9-]*\)".*/\1/p' | head -1)
                _append 20260828-160000 "$_st" filed "asked ${_k}" ;;
            *) ;;
        esac
    done
    if [ "$_n" -eq 5 ]; then
        add_row "checkin_drain_capped" true "the tick asks exactly max_per_tick (5) and holds the rest: ${_asked}" load
    else
        add_row "checkin_drain_capped" false "expected 5 asked in one tick, got ${_n} (${_asked})" load
    fi
    _s2=$(sh "$_step" --root "$_fx" --tick 20260828-170000 $_when 2>&1 || true)
    _left=$(_held "$_s2")
    if [ -n "$_left" ] && ! printf '%s' "$_left" | grep -q "$(printf '%s' "$_asked" | cut -d' ' -f1)"; then
        add_row "checkin_remainder_held" true "the ones that did not fit are still held: ${_left}" load
    else
        add_row "checkin_remainder_held" false "the remainder was lost or the asked ones came back: ${_left}" load
    fi

    # 5. A GENUINELY SPENT DAY STILL HOLDS. The cap was kept, not removed — `max_per_day`
    #    lines ON THE TICK'S OWN DAY still refuse, and still hold.
    _spent="${_tmp}/spent"
    mkdir -p "${_spent}/.workaholic"
    _i=1
    while [ "$_i" -le 10 ]; do
        sh "$_log" --root "$_spent" --tick 20260828-130000 --step "human-checkin-ask-today-${_i}" \
            --status filed --summary "asked today ${_i}" >/dev/null 2>&1 || true
        _i=$((_i + 1))
    done
    _sp=$(sh "$_ask" --root "$_spent" --tick 20260828-140000 --key "q:one-more" $_when 2>&1 || true)
    case "$_sp" in
        *'"reason": "day_cap"'*'"hold": true'*)
            add_row "checkin_spent_day_holds" true "a day genuinely spent still refuses day_cap, and still holds the question" load ;;
        *)
            add_row "checkin_spent_day_holds" false "the cap was not kept: $(one_line "$_sp")" load ;;
    esac

    # 6. A TICK THAT DELIVERED NOTHING SUPPLIES ITS EVENT, AND THE ROOT CARRIES IT.
    sh "$_log" --root "$_spent" --tick 20260826-100000 --step human-checkin-held-stuck \
        --status skipped --summary "held stuck" >/dev/null 2>&1 || true
    _fail=$(sh "$_step" --root "$_spent" --tick 20260828-140000 $_when 2>&1 || true)
    _event=$(printf '%s' "$_fail" | sed -n 's/.*"event": *"\([^"]*\)".*/\1/p' | head -1)
    _delivery=$(printf '%s' "$_fail" | sed -n 's/.*"delivery": *"\([a-z_]*\)".*/\1/p' | head -1)
    if [ "$_delivery" = "cap_spent" ] && [ -n "$_event" ]; then
        add_row "checkin_failure_is_an_event" true "a tick with candidates and none delivered names cap_spent and supplies an event" load
    else
        add_row "checkin_failure_is_an_event" false "expected cap_spent with an event, got delivery='${_delivery}' event='${_event}'" load
    fi
    # The root carries it with ZERO questions, which is the whole point: with none it says
    # nothing at all and its silence is indistinguishable from a quiet hour.
    sh "$_log" --root "$_spent" --tick 20260828-120000 --step doc-drift --status ok --summary "no drift" >/dev/null 2>&1 || true
    _rows="{\"rows\": [{\"step\": \"doc-drift\", \"status\": \"ok\", \"summary\": \"no drift\", \"event\": \"\"}, {\"step\": \"human-checkin\", \"status\": \"ok\", \"summary\": \"held and undelivered\", \"event\": \"$(json_escape "$_event")\"}]}"
    _post=$(printf '%s' "$_rows" | sh "$_render" --tick 20260828-140000 --root "$_spent" 2>&1 || true)
    case "$_post" in
        *'"post": true'*)
            add_row "checkin_root_carries_it" true "the root posts on the delivery failure with zero questions" load ;;
        *)
            add_row "checkin_root_carries_it" false "the root stayed silent about a tick that reached nobody: $(one_line "$_post")" load ;;
    esac
    # ...and a quiet hour supplies none and posts nothing, unchanged.
    _quiet="{\"rows\": [{\"step\": \"doc-drift\", \"status\": \"ok\", \"summary\": \"no drift\", \"event\": \"\"}, {\"step\": \"human-checkin\", \"status\": \"ok\", \"summary\": \"nothing waiting\", \"event\": \"\"}]}"
    _qpost=$(printf '%s' "$_quiet" | sh "$_render" --tick 20260828-140000 --root "$_spent" 2>&1 || true)
    case "$_qpost" in
        *'"post": false'*)
            add_row "checkin_quiet_hour_silent" true "a tick with no event still posts nothing, so the gate did not become a status line" load ;;
        *)
            add_row "checkin_quiet_hour_silent" false "a quiet hour posted: $(one_line "$_qpost")" load ;;
    esac

    # 7. THE BREAKER ROW, LABELLED AS THE INTENTIONAL FAILURE. Written against the COUNT and
    #    not against the gate's output shape, so a future refactor that keeps the shape and
    #    loses the bound still fires it: point `asked_today` back at the unbounded reader and
    #    row 2 must fail. A drill that cannot fail proves nothing, and this is the exact
    #    regression the mission exists to prevent.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/." "$_broken/"
    sed 's/^asked_today=.*/asked_today=$(count_log_prefix human-checkin-ask "" "")/' \
        "$_ask" > "${_broken}/ask-question.sh"
    chmod +x "${_broken}/ask-question.sh"
    _bfx="${_tmp}/bfx"
    mkdir -p "${_bfx}/.workaholic"
    for _d in 21 22 23 24 25; do
        sh "$_log" --root "$_bfx" --tick "202608${_d}-090000" \
            --step "human-checkin-ask-past-${_d}a" --status filed --summary "asked past" >/dev/null 2>&1 || true
        sh "$_log" --root "$_bfx" --tick "202608${_d}-100000" \
            --step "human-checkin-ask-past-${_d}b" --status filed --summary "asked past" >/dev/null 2>&1 || true
    done
    _b=$(sh "${_broken}/ask-question.sh" --root "$_bfx" --tick 20260828-140000 --key "q:yak" $_when 2>&1 || true)
    if [ "$(_reason "$_b")" = "day_cap" ]; then
        add_row "checkin_breaker" true "with the day count unbounded again the held question is refused day_cap (this drill can fail)" breaker
    else
        add_row "checkin_breaker" false "the breaker did not break: an unbounded count still asked the question, so row 2 proves nothing ($(one_line "$_b"))" breaker
    fi

    # 8. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE, AND NOTHING WAS POSTED.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "checkin_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "checkin_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "checkin-delivery" 0 "fail" 1
    fi
    emit_verdict "checkin-delivery" 0 "pass" 0
}

# ------------------------------------------------------- verify-condition-age
# HOW LONG HAS THIS CONDITION BEEN STANDING (2026-08-30, mission
# `say-how-long-the-loop-has-been-stuck`).
#
# Every reading in this repository was instantaneous: each said WHAT is stuck and none said HOW
# LONG, and the asked-once gate means a person is told exactly once either way. Measured: five
# queued tickets stamped with an address the identity mapping does not name, undrivable since
# 2026-08-19, each asked about once — days ago. This walks the whole chain — log, reader, bound,
# question, report — with **no network, no `gh`, no Slack post and no touch of the working tree**.
#
# THE FIXTURE'S LEDGER LINES ARE WRITTEN BY THE REAL WRITER. `ask-question.sh --record-ask` is
# driven rather than hand-authored, so the drill cannot pass against a line shape the writer never
# produces — `verify-ci-retirement`'s measured lesson, where a fixture that configured for itself
# the one term production lacked passed on every push while production was silent.
#
# WHICH STEP IS EXERCISED END TO END, AND WHY ONLY ONE. `step-undrivable-units.sh` is fully local
# — it walks `.workaholic/` through the ownership readers — so the drill runs it over two ticks
# and asserts its summary and its keys byte-identical with and without an age. The other three age
# consumers read the CLAIM ORACLE, which fetches; standing up a bare origin per step would drill
# the oracle rather than the age, so for those the drill asserts the COMPOSITION (each reaches the
# one reader) and the suite's `testProofJudgementSplit` carries the acting-call-site bans.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR: a copy of the reader wired to walk only the
# current tick. Every age must then collapse to 1 — not merely return a different shape — which is
# the regression that would make an eleven-day blocker read as one that just started.
cmd_verify_condition_age() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _age="${_mod}/condition-age.sh"
    _ask="${_mod}/ask-question.sh"
    _log="${_mod}/log-append.sh"
    _undriv="${_mod}/step-undrivable-units.sh"
    for _f in "$_age" "$_ask" "$_log" "$_undriv"; do
        [ -f "$_f" ] || emit_err "condition_age_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    mkdir -p "${_fx}/.workaholic"
    _field() { printf '%s' "$1" | sed -n "s/.*\"$2\": *\"\\([^\"]*\\)\".*/\\1/p" | head -1; }
    _num() { printf '%s' "$1" | sed -n "s/.*\"$2\": *\\([0-9a-z]*\\).*/\\1/p" | head -1; }
    _append() { sh "$_log" --root "$_fx" --tick "$1" --step "$2" --status "$3" --summary "$4" >/dev/null 2>&1 || true; }

    KEY="undrivable-unit:.workaholic/tickets/todo/20260819-stuck.md"

    # 1. THE LEDGER, THROUGH ITS REAL WRITER, ON AN EARLIER DAY — then four later ticks naming
    #    OTHER steps: what the age counts is how many ticks have RUN since, not how many times
    #    this key was named.
    sh "$_ask" --record-ask --root "$_fx" --tick 20260819-105000 --key "$KEY" \
        --coordinate 'C0AB12CD3:1724371200.000100' --summary 'asked about an undrivable unit' >/dev/null 2>&1 || true
    for _t in 20260820-105000 20260821-105000 20260822-105000 20260823-105000; do
        _append "$_t" base-health ok "green"
    done

    _r=$(sh "$_age" --key "$KEY" --root "$_fx" 2>&1 || true)
    if [ "$(_field "$_r" first_seen)" = "20260819-105000" ] && [ "$(_num "$_r" ticks)" = "5" ]; then
        add_row "age_reads_the_earliest_tick" true "a key first named days ago reads that tick, with 5 ticks since" load
    else
        add_row "age_reads_the_earliest_tick" false "expected 20260819-105000 / 5, got: $(one_line "$_r")" load
    fi

    # 2. ABSENT IS NOT DEGRADED. A key the ledger never carried is the first time anybody is
    #    being asked — an ordinary state, and it must carry NO `readable` field, so a consumer
    #    not taught the term is unaffected.
    _a=$(sh "$_age" --key "undrivable-unit:.workaholic/tickets/todo/never.md" --root "$_fx" 2>&1 || true)
    case "$_a" in
        *'"first_seen": null'*'"ticks": 0'*)
            case "$_a" in
                *readable*) add_row "age_absent_is_readable" false "an absent key emitted a readable field: $(one_line "$_a")" load ;;
                *) add_row "age_absent_is_readable" true "a key nobody has asked about reads null/0 with no readable field" load ;;
            esac ;;
        *) add_row "age_absent_is_readable" false "expected first_seen null and ticks 0, got: $(one_line "$_a")" load ;;
    esac

    # 3. A LOG THAT EXISTS AND CANNOT BE READ IS NAMED, WITH NULL COUNTS — never zeroed ones,
    #    because zero reads as *nothing has been asked*, which is the opposite.
    _bad="${_tmp}/bad"
    mkdir -p "${_bad}/.workaholic"
    : > "${_bad}/.workaholic/moderations"
    _d=$(sh "$_age" --key "$KEY" --root "$_bad" 2>&1 || true)
    case "$_d" in
        *'"ticks": null'*'"readable": false'*|*'"readable": false'*'"ticks": null'*)
            if [ -n "$(_field "$_d" reason)" ]; then
                add_row "age_unreadable_is_named" true "an unreadable log is named ($(_field "$_d" reason)) with null counts" load
            else
                add_row "age_unreadable_is_named" false "unreadable with no named reason: $(one_line "$_d")" load
            fi ;;
        *) add_row "age_unreadable_is_named" false "expected readable:false with null counts, got: $(one_line "$_d")" load ;;
    esac

    # 4. THE BOUND. Cut → `truncated` and a FLOOR with real counts and no degradation; uncut →
    #    byte-identical to an unbounded walk.
    _cut=$(WORKAHOLIC_CONDITION_AGE_MAX_DAYS=2 sh "$_age" --key "$KEY" --root "$_fx" 2>&1 || true)
    case "$_cut" in
        *'"truncated": true'*)
            case "$_cut" in
                *readable*) add_row "age_bound_is_not_a_degradation" false "a cut walk reported readable:false: $(one_line "$_cut")" load ;;
                *) add_row "age_bound_is_not_a_degradation" true "a cut walk is truncated, with real counts and no readable:false" load ;;
            esac ;;
        *) add_row "age_bound_is_not_a_degradation" false "expected truncated:true under a 2-day bound, got: $(one_line "$_cut")" load ;;
    esac
    _unb=$(WORKAHOLIC_CONDITION_AGE_MAX_DAYS=9999 sh "$_age" --key "$KEY" --root "$_fx" 2>&1 || true)
    if [ "$_unb" = "$_r" ]; then
        add_row "age_uncut_is_byte_identical" true "a log shorter than the bound reads byte-identically to an unbounded walk" load
    else
        add_row "age_uncut_is_byte_identical" false "a bound larger than the log changed the reading: $(one_line "$_unb")" load
    fi

    # 5. THE STEP: the age rides `needs_agent`, the SUMMARY does not move, and the KEY does not
    #    move — so nothing is re-asked by the changed wording.
    mkdir -p "${_fx}/.workaholic/tickets/todo" "${_fx}/.claude"
    printf 'created_at: 2026-08-19T00:00:00+00:00\nassignees: [nobody@example.invalid]\n' > "${_tmp}/fm"
    { printf -- '---\n'; cat "${_tmp}/fm"; printf -- '---\n\n# Stuck\n'; } \
        > "${_fx}/.workaholic/tickets/todo/20260819-stuck.md"
    _s1=$(sh "$_undriv" --tick 20260830-100000 --root "$_fx" 2>&1 || true)
    _sum1=$(_field "$_s1" summary)
    case "$_s1" in
        *'"age"'*'"first_seen":"20260819-105000"'*|*'"age": {'*'"first_seen": "20260819-105000"'*)
            add_row "age_rides_the_question" true "the step attaches the reader's own words to its candidate" load ;;
        *)
            case "$_s1" in
                *'"age"'*) add_row "age_rides_the_question" true "the step attaches an age to its candidate" load ;;
                *) add_row "age_rides_the_question" false "no age on the candidate: $(one_line "$_s1")" load ;;
            esac ;;
    esac
    case "$_s1" in
        *'"key":"undrivable-unit:.workaholic/tickets/todo/20260819-stuck.md"'*|*'"key": "undrivable-unit:.workaholic/tickets/todo/20260819-stuck.md"'*)
            add_row "age_key_did_not_move" true "the candidate key is unchanged, so already_asked is byte-identical" load ;;
        *) add_row "age_key_did_not_move" false "the candidate key moved: $(one_line "$_s1")" load ;;
    esac
    case "$_sum1" in
        *20260819*|*tick*|*age*|*asked*)
            add_row "age_stays_out_of_the_summary" false "the summary carries an age term: ${_sum1}" load ;;
        *) add_row "age_stays_out_of_the_summary" true "the summary names counts only: ${_sum1}" load ;;
    esac
    # A SECOND TICK, with the ledger a tick longer, must leave the summary byte-identical: a
    # summary that moves with the age marks the step changed hourly by construction, which is the
    # retired `📦 Release Preparation` shape.
    _append 20260830-100000 base-health ok "green"
    _s2=$(sh "$_undriv" --tick 20260830-110000 --root "$_fx" 2>&1 || true)
    if [ "$(_field "$_s2" summary)" = "$_sum1" ]; then
        add_row "age_summary_is_stable" true "an hour later the summary is byte-identical, so the root renders no new line" load
    else
        add_row "age_summary_is_stable" false "the summary moved with the age: $(_field "$_s2" summary)" load
    fi

    # 6. THE OTHER THREE CONSUMERS COMPOSE THE ONE READER (see the header for why they are not
    #    executed here), and no gate, survey or sort reaches it.
    _missing=''
    for _c in step-undelivered-units.sh step-stalled-units.sh step-retire-claims.sh; do
        grep -q 'read_age' "${_mod}/${_c}" 2>/dev/null || _missing="${_missing} ${_c}"
    done
    if [ -z "$_missing" ]; then
        add_row "age_reaches_every_consumer" true "all four question steps compose the one reader" load
    else
        add_row "age_reaches_every_consumer" false "these steps compose no age:${_missing}" load
    fi
    _gates=''
    for _g in "${_mod}/ask-question.sh" \
              "${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/plan-units.sh" \
              "${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"; do
        # A PATH THAT DOES NOT EXIST MUST NOT PASS THIS ROW. `grep` over a missing file
        # matches nothing, so a mistyped path would report *gates nothing* about a script
        # nobody checked — which is the shape of a test that proves only itself.
        if [ ! -f "$_g" ]; then
            _gates="${_gates} $(basename "$_g")(absent)"
        elif grep -v '^[[:space:]]*#' "$_g" | grep -q 'condition-age.sh'; then
            _gates="${_gates} $(basename "$_g")"
        fi
    done
    if [ -z "$_gates" ]; then
        add_row "age_gates_nothing" true "the gate, the driving survey and the proposing survey never reach the reader" load
    else
        add_row "age_gates_nothing" false "a gate or survey reads the age, or its path is wrong:${_gates}" load
    fi

    # 7. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. Written against the BEHAVIOUR: wire the
    #    walk at a single tick and every age must collapse to 1. A drill that cannot fail
    #    proves nothing, and this is the exact regression the mission exists to prevent.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${_mod}/." "$_broken/"
    sed 's|^all_out=$(sh "$LOG_READ".*|all_out=$(sh "$LOG_READ" --root "$ROOT" --tick "$first_seen" 2>/dev/null \|\| true)|' \
        "$_age" > "${_broken}/condition-age.sh"
    chmod +x "${_broken}/condition-age.sh"
    _b=$(sh "${_broken}/condition-age.sh" --key "$KEY" --root "$_fx" 2>&1 || true)
    if [ "$(_num "$_b" ticks)" = "1" ]; then
        add_row "age_breaker" true "with the walk wired at a single tick every age collapses to 1 (this drill can fail)" breaker
    else
        add_row "age_breaker" false "the breaker did not break: the age survived the walk being wired at a single tick ($(one_line "$_b")), so row 1 proves nothing" breaker
    fi

    # 8. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "age_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "age_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "condition-age" 0 "fail" 1
    fi
    emit_verdict "condition-age" 0 "pass" 0
}

# ------------------------------------------------------- verify-directed-notification
# THE POST WHOSE WHOLE PURPOSE IS TO REACH A PERSON (2026-08-31, mission
# `notify-the-person-a-directed-question-addresses`).
#
# Every post reaches Slack as the operator's own account, and Slack notifies nobody of their own
# message — so the two shapes that exist to REACH somebody (`/moderate`'s `🙋` question and the
# `🟡 Handoff` ask) carried a `<@U…>` that, in the single-developer configuration, resolved to the
# poster and paged nobody. A notification path is exactly the kind that fails SILENTLY: this one
# went unnoticed until an operator asked a session directly, twice.
#
# WHAT IS DRILLED, AND WHAT CANNOT BE. This walks transport → rule → call site → template with
# **no network, no `gh`, no credential and no Slack post**: `curl` is stubbed on PATH for the
# transport rows, so the assertion is on the BYTES that would have gone out. What no drill can
# prove is that a human's phone buzzed — that half is the mission's handoff ticket, deliberately
# separate so the mechanical proof is not held hostage to a credential.
#
# WHY THE RULE AND THE CALL SITES ARE READ RATHER THAN RUN. The carrier selection is a rule an
# AGENT executes from prose (`workaholic:notify`, *Which transport carries which shape, and why*),
# not a script — there is no function to call. So the drill proves the two halves that are
# checkable: the transport CAN do what the rule asks of it, and every document the agent reads
# states the rule the same way. The gate's own immunity is proved by EXECUTION, below.
#
# THE BREAKER IS IN TWO HALVES, EACH WRITTEN AGAINST THE BEHAVIOUR. One restores the pre-repair
# TRANSPORT (`--thread-ts` removed, so a bot can only ever post a root); one restores the
# pre-repair RULE (the enumerated directed set removed, so availability alone decides the
# carrier). Either alone would leave the other half unproved.
cmd_verify_directed_notification() {
    _spec="${REPO_ROOT}/plugins/workaholic/skills/specificate/scripts/notify-slack.sh"
    _notify="${REPO_ROOT}/plugins/workaholic/skills/notify/SKILL.md"
    _catalog="${REPO_ROOT}/plugins/workaholic/skills/notify/reference/notifications.md"
    _modwf="${REPO_ROOT}/plugins/workaholic/skills/moderate/reference/workflow.md"
    _routing="${REPO_ROOT}/plugins/workaholic/skills/drive/reference/routing.md"
    _askq="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _tmod="${REPO_ROOT}/plugins/workaholic/skills/workaholify/routines/moderate.md"
    _timp="${REPO_ROOT}/plugins/workaholic/skills/workaholify/routines/implement.md"
    for _f in "$_spec" "$_notify" "$_catalog" "$_modwf" "$_routing" "$_askq" "$_tmod" "$_timp"; do
        [ -f "$_f" ] || emit_err "directed_notification_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _bin="${_tmp}/bin"
    _cap="${_tmp}/payload.json"
    mkdir -p "$_bin"
    # A `curl` STUB rather than a listener: no socket, no port to race, and what is asserted is
    # the payload the script built. It records every invocation, so "nothing was posted" is a
    # checkable absence rather than an assumption.
    cat > "${_bin}/curl" <<'STUB'
#!/bin/sh
out=""; data=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    --data) data="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s' "$data" > "$WORKAHOLIC_DRILL_CAPTURE"
[ -n "$out" ] && printf '{"ok": true}' > "$out"
printf '200'
STUB
    chmod +x "${_bin}/curl"
    _post() {
        : > "$_cap"
        ( PATH="${_bin}:$PATH" WORKAHOLIC_DRILL_CAPTURE="$_cap" \
          SLACK_BOT_TOKEN="${1}" WORKAHOLIC_SLACK_CHANNEL=C0DRILL0 \
          WORKAHOLIC_SLACK_API_URL='http://stub.invalid/chat.postMessage' \
          sh "$_spec" $2 "$3" 2>&1 || true )
    }
    TS='1724371200.000100'

    # 1. THE TRANSPORT CAN REPLY INTO A THREAD. Without this the bot could only ever post a
    #    keyed ROOT, which is precisely why the model called it a fallback no call site may pick.
    _r=$(_post xoxb-drill "--thread-ts ${TS}" '🙋 <@U0OPERATOR> - a question')
    _payload=$(cat "$_cap" 2>/dev/null || true)
    case "${_r}|${_payload}" in
        *'"notified": true'*'"thread_ts": "'${TS}'"'*)
            add_row "directed_reply_carries_the_thread" true "the bot's reply carries the coordinate verbatim, so it lands in the root's own thread" load ;;
        *) add_row "directed_reply_carries_the_thread" false "expected notified with thread_ts ${TS}, got: $(one_line "$_r") / $(one_line "$_payload")" load ;;
    esac

    # 2. AND EVERY UNDIRECTED POST IS BYTE-IDENTICAL TO WHAT IT ALWAYS WAS. The rule adds a
    #    capability; a root that started carrying a thread key would be a silent behaviour change
    #    in every caller that never asked for one.
    ROOT_TEXT='🔎 Moderation - 2 change(s), 1 question(s)'
    _r=$(_post xoxb-drill "" "$ROOT_TEXT")
    _payload=$(cat "$_cap" 2>/dev/null || true)
    # Compared against the PRE-REPAIR BUILDER re-run here, not against a literal typed into this
    # drill: the real one escapes non-ASCII, and a hand-written expectation would be asserting
    # this drill's idea of the payload rather than the payload the script used to send.
    _expected=$(printf '%s' "$ROOT_TEXT" | WORKAHOLIC_SLACK_CHANNEL=C0DRILL0 python3 -c \
        'import json,sys,os; print(json.dumps({"channel": os.environ["WORKAHOLIC_SLACK_CHANNEL"], "text": sys.stdin.read()}))' 2>/dev/null || true)
    if [ -n "$_expected" ] && [ "$_payload" = "$_expected" ]; then
        add_row "undirected_post_is_unchanged" true "with no flag the payload is byte-identical to the pre-repair builder's" load
    else
        add_row "undirected_post_is_unchanged" false "the payload diverged from the pre-repair builder's: $(one_line "$_payload")" load
    fi

    # 3. A MALFORMED COORDINATE IS REFUSED BY NAME AND NOTHING IS POSTED. Silently posting a ROOT
    #    where a reply was asked for is invisible from the caller's side — the whole reason the
    #    flag refuses rather than drops.
    _r=$(_post xoxb-drill "--thread-ts not-a-ts" '🙋 <@U0OPERATOR> - a question')
    _payload=$(cat "$_cap" 2>/dev/null || true)
    case "${_r}|${_payload}" in
        *bad_thread_ts*'|') add_row "malformed_coordinate_posts_nothing" true "a malformed coordinate is refused bad_thread_ts and nothing reaches the transport" load ;;
        *bad_thread_ts*) add_row "malformed_coordinate_posts_nothing" false "refused by name but something was posted: $(one_line "$_payload")" load ;;
        *) add_row "malformed_coordinate_posts_nothing" false "expected bad_thread_ts, got: $(one_line "$_r")" load ;;
    esac

    # 4. WITH NO TOKEN THE DIRECTED POST FALLS BACK AND IS REPORTED — never dropped, and never
    #    counted as delivered. `exit 0` is the contract: a notification is never load-bearing.
    _r=$(_post "" "--thread-ts ${TS}" '🙋 <@U0OPERATOR> - a question')
    _payload=$(cat "$_cap" 2>/dev/null || true)
    case "${_r}|${_payload}" in
        *'"notified": false'*no_token*'|')
            add_row "no_token_falls_back_and_is_reported" true "with no bot token the transport reports no_token, posts nothing, and the caller falls back to the connector" load ;;
        *) add_row "no_token_falls_back_and_is_reported" false "expected a reported no_token no-op, got: $(one_line "$_r") / $(one_line "$_payload")" load ;;
    esac

    # 5. THE RULE. The directed set is ENUMERATED — a judgement made at post time is exactly what
    #    the enumeration exists to prevent — and it names both shapes and the deliberate-edit bar.
    _rule=$(sed -n '/Which transport carries which shape/,/^## /p' "$_notify" 2>/dev/null || true)
    _miss=''
    for _t in '🙋' '🟡 Handoff' 'deliberate edit'; do
        case "$_rule" in *"$_t"*) : ;; *) _miss="${_miss} [${_t}]" ;; esac
    done
    if [ -n "$_rule" ] && [ -z "$_miss" ]; then
        add_row "rule_enumerates_the_directed_set" true "the model names both directed shapes and makes extending the set a deliberate edit" load
    else
        add_row "rule_enumerates_the_directed_set" false "the carrier rule is absent or incomplete:${_miss:-(section not found)}" load
    fi
    case "$_rule" in
        *connector*) add_row "rule_keeps_every_other_shape_on_the_connector" true "the rule states the connector carries everything else" load ;;
        *) add_row "rule_keeps_every_other_shape_on_the_connector" false "the rule names no carrier for the undirected shapes" load ;;
    esac

    # 6. THE CALL SITES read the same rule. Two consumers, and a document that states it
    #    differently is how an agent starts posting the wrong shape from the wrong account.
    _sites=''
    grep -q 'thread-ts' "$_modwf" || _sites="${_sites} moderate/reference/workflow.md"
    grep -q 'omitted rather than guessed' "$_routing" || _sites="${_sites} drive/reference/routing.md(addressee)"
    grep -q 'mention_unresolved' "$_routing" || _sites="${_sites} drive/reference/routing.md(report)"
    if [ -z "$_sites" ]; then
        add_row "call_sites_state_the_same_rule" true "both call sites name the carrier, the addressee and what an unresolved address does" load
    else
        add_row "call_sites_state_the_same_rule" false "these documents do not state it:${_sites}" load
    fi

    # 7. THE TEMPLATES. *The prompt is the ceiling*: the rule sanctions the shape and only a
    #    template lets a session running that routine emit it.
    _tm=''
    for _pair in "${_tmod}:🙋" "${_timp}:🟡 Handoff"; do
        _p="${_pair%:*}"; _shape="${_pair##*:}"
        grep -q -- '--thread-ts' "$_p" || _tm="${_tm} $(basename "$_p")(carrier)"
        grep -q "$_shape" "$_p" || _tm="${_tm} $(basename "$_p")(shape)"
    done
    if [ -z "$_tm" ]; then
        add_row "templates_name_shape_and_carrier" true "both routine templates name the shape they authorize and the transport that carries it" load
    else
        add_row "templates_name_shape_and_carrier" false "a template names one without the other:${_tm}" load
    fi

    # 8. THE GATE DID NOT MOVE, PROVED BY EXECUTION rather than by reading a diff. The same key
    #    on the same fixture must answer BYTE-IDENTICALLY with a bot token and without one: the
    #    change is which account speaks, never which questions are asked.
    _fx="${_tmp}/fx"
    mkdir -p "${_fx}/.workaholic"
    _g1=$(SLACK_BOT_TOKEN=xoxb-drill WORKAHOLIC_QUIET_HOURS=22-08 WORKAHOLIC_WORK_DAYS=1-7 \
          sh "$_askq" --root "$_fx" --tick 20260831-100000 --key 'handoff-unit:drill-unit' 2>&1 || true)
    _g2=$(SLACK_BOT_TOKEN= WORKAHOLIC_QUIET_HOURS=22-08 WORKAHOLIC_WORK_DAYS=1-7 \
          sh "$_askq" --root "$_fx" --tick 20260831-100000 --key 'handoff-unit:drill-unit' 2>&1 || true)
    if [ -n "$_g1" ] && [ "$_g1" = "$_g2" ]; then
        add_row "gate_is_transport_blind" true "the gate answers byte-identically with and without a bot token" load
    else
        add_row "gate_is_transport_blind" false "the gate's answer moved with the transport: $(one_line "$_g1") vs $(one_line "$_g2")" load
    fi
    # And it never reads the transport at all — the structural half of the same property, so a
    # future gate cannot start branching on a token while still answering identically today.
    if grep -v '^[[:space:]]*#' "$_askq" | grep -qE 'notify-slack|SLACK_BOT_TOKEN'; then
        add_row "gate_never_reads_the_transport" false "the gate reads the transport, so its caps and holds can diverge by surface" load
    else
        add_row "gate_never_reads_the_transport" true "the gate names no transport, so no key, cap or hold can branch on one" load
    fi

    # 9. BREAKER A — THE PRE-REPAIR TRANSPORT. With `--thread-ts` removed the bot can only post a
    #    ROOT, which is the restriction that kept the one non-operator identity away from the one
    #    shape that needed it. Row 1 must then be unreachable.
    _brk="${_tmp}/broken-transport.sh"
    sed '/--thread-ts)/,/;;/d; s/if sys\.argv\[1\]:/if False:/' "$_spec" > "$_brk"
    chmod +x "$_brk"
    : > "$_cap"
    _b=$( PATH="${_bin}:$PATH" WORKAHOLIC_DRILL_CAPTURE="$_cap" SLACK_BOT_TOKEN=xoxb-drill \
          WORKAHOLIC_SLACK_CHANNEL=C0DRILL0 WORKAHOLIC_SLACK_API_URL='http://stub.invalid/chat.postMessage' \
          sh "$_brk" --thread-ts "$TS" '🙋 <@U0OPERATOR> - a question' 2>&1 || true )
    if grep -q 'thread_ts' "$_cap" 2>/dev/null; then
        add_row "directed_notification_breaker_transport" false "the breaker did not break: a thread key survived the flag's removal, so row 1 proves nothing" breaker
    else
        add_row "directed_notification_breaker_transport" true "with --thread-ts removed the bot can only post a root (this drill can fail)" breaker
    fi

    # 10. BREAKER B — THE PRE-REPAIR RULE. With the enumerated directed set gone, availability
    #     alone decides the carrier, which is the state that made the whole defect invisible.
    _brkdoc="${_tmp}/broken-rule.md"
    sed '/^### Which transport carries which shape/,/^### /d' "$_notify" > "$_brkdoc"
    _brule=$(sed -n '/Which transport carries which shape/,/^## /p' "$_brkdoc" 2>/dev/null || true)
    case "$_brule" in
        *'🟡 Handoff'*) add_row "directed_notification_breaker_rule" false "the breaker did not break: the directed set survived the section's removal, so rows 5-6 prove nothing" breaker ;;
        *) add_row "directed_notification_breaker_rule" true "with the enumerated set removed no shape is bot-carried and availability alone decides (this drill can fail)" breaker ;;
    esac

    # 11. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE, and no Slack post left this machine.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "directed_notification_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "directed_notification_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "directed-notification" 0 "fail" 1
    fi
    emit_verdict "directed-notification" 0 "pass" 0
}

# ---------------------------------------------------------- verify-impairment
# WHICH STEPS THE TICK COULD NOT READ (2026-08-31, mission
# `name-the-steps-a-tick-could-not-read`).
#
# `run.sh` classified every step `ok|filed|skipped|degraded|blocked` with a reason and
# `render-tick-post.sh` read NEITHER field, so a tick where six steps saw nothing rendered
# exactly like one where everything was read — and with no question it posted nothing at all.
# Measured: 24 of 25 consecutive ticks in that state, found four days later by asking.
#
# HERMETIC. The renderer's whole input is a JSON document on stdin and a tick log on disk,
# both of which the fixture writes — no network, no `gh`, no Slack, no `origin`. The log is
# written through `log-append.sh`, THE REAL WRITER, because a drill that passes against a line
# shape the writer never produces proves nothing.
#
# WHAT IS DRILLED, AND WHY IT IS THIS AND NOT A SHAPE ASSERTION. The defect is a REPORTING
# SILENCE, the class a return-shape assertion is worst at catching: a refactor that keeps
# `impaired[]` in the JSON and loses the render would pass one. So the rows are about what a
# person would read, and THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR — the pre-change parse
# restored, dropping `status` — and must show BOTH halves of the measured failure: the
# impairment going unnamed on a root that posts, and the impaired tick going silent.
#
# THE TWO ROWS THAT CARRY THE MISSION are `impairment_survives_the_diff` (two consecutive
# identically-impaired ticks BOTH name it — the property a diff-gated render would fail) and
# `impairment_middle_tick_is_silent` (the middle of three does not POST — the property that
# keeps this from being the hourly status root retired twice). Either alone is a defect.
cmd_verify_impairment() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _render="${_mod}/render-tick-post.sh"
    _log="${_mod}/log-append.sh"
    for _f in "$_render" "$_log"; do
        [ -f "$_f" ] || emit_err "impairment_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    mkdir -p "${_fx}/.workaholic"

    _field() { printf '%s' "$1" | sed -n "s/.*\"$2\": *\"\\([^\"]*\\)\".*/\\1/p" | head -1; }
    _root_text() { printf '%s' "$1" | sed -n 's/.*"root_text": "\([^"]*\)".*/\1/p' | head -1; }

    # The run's JSON, in the shape `run.sh` emits: `status` and `reason` sit between `step` and
    # `summary`. `doc-drift` is `skipped` in every document on purpose — row 7 is what proves a
    # healthy refusal to run is never reported as a blindness.
    _mkrun() { # $1 inbound-status $2 inbound-reason $3 inbound-summary $4 merge-status $5 merge-reason $6 merge-summary
        printf '{"tick": "fixture", "steps": [{"step": "open-log", "status": "ok", "reason": "", "summary": "log opened", "needs_agent": 0, "logged": true, "event": ""}, {"step": "inbound-sweep", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": 0, "logged": true, "event": ""}, {"step": "merge-conflicts", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": 0, "logged": true, "event": ""}, {"step": "doc-drift", "status": "skipped", "reason": "budget", "summary": "not reached", "needs_agent": 0, "logged": true, "event": ""}, {"step": "base-health", "status": "ok", "reason": "", "summary": "base green", "needs_agent": 0, "logged": true, "event": ""}]}\n' \
            "$1" "$2" "$3" "$4" "$5" "$6"
    }
    _mkrun ok '' 'swept, 0 filed' ok '' 'no conflicts' > "${_tmp}/healthy.json"
    _mkrun degraded no_slack_transport 'no Slack transport' degraded gh_unavailable 'could not read pull requests' > "${_tmp}/impaired.json"

    _logtick() { # $1 tick $2 inbound-status $3 inbound-summary $4 merge-status $5 merge-summary
        sh "$_log" --root "$_fx" --tick "$1" --step open-log --status ok --summary "log opened" >/dev/null 2>&1 || true
        sh "$_log" --root "$_fx" --tick "$1" --step inbound-sweep --status "$2" --summary "$3" >/dev/null 2>&1 || true
        sh "$_log" --root "$_fx" --tick "$1" --step merge-conflicts --status "$4" --summary "$5" >/dev/null 2>&1 || true
        sh "$_log" --root "$_fx" --tick "$1" --step doc-drift --status skipped --summary "not reached" >/dev/null 2>&1 || true
        sh "$_log" --root "$_fx" --tick "$1" --step base-health --status ok --summary "base green" >/dev/null 2>&1 || true
    }
    _render_at() { # $1 tick $2 run-json $3 questions
        sh "$_render" --tick "$1" --root "$_fx" --questions "$3" < "$2" 2>&1 || true
    }

    _logtick 20260819-084500 ok 'swept, 0 filed' ok 'no conflicts'
    _logtick 20260819-094500 ok 'swept, 0 filed' ok 'no conflicts'

    # 1. AN IMPAIRED TICK WITH A QUESTION NAMES EVERY IMPAIRED STEP AND ITS REASON, AND CARRIES
    #    THE COUNT IN THE HEAD. This is the whole ask, on the ordinary path.
    _t2q=$(_render_at 20260819-104500 "${_tmp}/impaired.json" 1)
    _rt2q=$(_root_text "$_t2q")
    case "$_rt2q" in
        *'2 step(s) could not read'*'inbound-sweep — degraded: no_slack_transport'*'merge-conflicts — degraded: gh_unavailable'*)
            add_row "impairment_is_named" true "the root names both impaired steps with their reasons and carries the count in its head" load ;;
        *) add_row "impairment_is_named" false "the root did not name the impairment: ${_rt2q}" load ;;
    esac

    # 2. THE FOURTH GATE: the same tick with ZERO questions POSTS, under its own reason. Before
    #    this, that tick emitted `post: false` and was byte-identical to a quiet hour — the
    #    silence the operator found four days later.
    # The TOP-LEVEL reason, matched as an exact leading substring rather than through a field
    # helper: `impaired[]` carries a `reason` of its own on every entry, and a greedy read of
    # the whole document answers with the LAST one.
    _t2=$(_render_at 20260819-104500 "${_tmp}/impaired.json" 0)
    case "$_t2" in
        '{"post": true, "reason": "ready_impairment"'*)
            add_row "impairment_earns_a_root" true "an impairment nobody has been told about posts a root with no question, as ready_impairment" load ;;
        *) add_row "impairment_earns_a_root" false "expected post true with reason ready_impairment, got: $(one_line "$_t2")" load ;;
    esac
    _logtick 20260819-104500 degraded 'no Slack transport' degraded 'could not read pull requests'

    # 3. THE OUTSIDE-THE-DIFF PROPERTY. An hour later, degraded identically, the change diff
    #    finds NOTHING (`change_count: 0`) — and the root still names all of it. A diff-gated
    #    clause would have said it once, yesterday, and gone quiet for the next twenty-four
    #    ticks, which is the measured defect rather than its fix.
    _t3q=$(_render_at 20260819-114500 "${_tmp}/impaired.json" 1)
    _rt3q=$(_root_text "$_t3q")
    case "$_t3q" in
        *'"change_count": 0'*)
            case "$_rt3q" in
                *'2 step(s) could not read'*'inbound-sweep — degraded'*'merge-conflicts — degraded'*)
                    add_row "impairment_survives_the_diff" true "a second identically-impaired tick still names all of it, with change_count 0" load ;;
                *) add_row "impairment_survives_the_diff" false "the diff swallowed the impairment on the second tick: ${_rt3q}" load ;;
            esac ;;
        *) add_row "impairment_survives_the_diff" false "expected change_count 0 on an unchanged tick, got: $(one_line "$_t3q")" load ;;
    esac

    # 4. THE ANTI-RESTATEMENT PROPERTY, and the other half of the design. The SAME tick with no
    #    question POSTS NOTHING: the statement rides every root, the POST is on change only, so
    #    a standing impairment never opens a root every hour for days. Without this row the
    #    mechanism is `📦 Release Preparation`, which was retired for exactly that.
    _t3=$(_render_at 20260819-114500 "${_tmp}/impaired.json" 0)
    case "$_t3" in
        *'"post": false'*) add_row "impairment_middle_tick_is_silent" true "an unchanged impairment with no question posts nothing — it is stated, never restated" load ;;
        *) add_row "impairment_middle_tick_is_silent" false "an unchanged impairment opened a root of its own: $(one_line "$_t3")" load ;;
    esac
    _logtick 20260819-114500 degraded 'no Slack transport' degraded 'could not read pull requests'

    # 5. CLEARING BREAKS SILENCE EXACTLY ONCE, and the root it earns says why it posted — a
    #    root whose head has no impairment term and whose body is empty is the content-free
    #    status line this repository has retired twice.
    _t4=$(_render_at 20260819-124500 "${_tmp}/healthy.json" 0)
    case "$_t4" in
        *'"post": true'*)
            case "$(_root_text "$_t4")" in
                *'every step read this tick'*) add_row "impairment_cleared_posts_once" true "a cleared impairment earns one root, and that root says what cleared" load ;;
                *) add_row "impairment_cleared_posts_once" false "the clearing root said nothing about why it posted: $(_root_text "$_t4")" load ;;
            esac ;;
        *) add_row "impairment_cleared_posts_once" false "a cleared impairment posted nothing: $(one_line "$_t4")" load ;;
    esac
    _logtick 20260819-124500 ok 'swept, 0 filed' ok 'no conflicts'
    _t5=$(_render_at 20260819-134500 "${_tmp}/healthy.json" 0)
    case "$_t5" in
        *'"post": false'*) add_row "impairment_then_silence" true "the tick after a clearing is quiet again" load ;;
        *) add_row "impairment_then_silence" false "the clearing kept posting: $(one_line "$_t5")" load ;;
    esac

    # 6. A HEALTHY TICK IS WHAT IT ALWAYS WAS. The head carries no third term and the body no
    #    clause, so a repository that is never impaired sees no change at all from this mission.
    _t5q=$(_render_at 20260819-134500 "${_tmp}/healthy.json" 1)
    _t5q_ready=no
    case "$_t5q" in '{"post": true, "reason": "ready"'*) _t5q_ready=yes ;; esac
    if [ "$(_root_text "$_t5q")" = "🔎 Moderation - 0 change(s), 1 question(s)" ] \
       && [ "$_t5q_ready" = yes ]; then
        add_row "impairment_healthy_is_unchanged" true "a healthy tick's root and reason are what they were before this mission" load
    else
        add_row "impairment_healthy_is_unchanged" false "a healthy tick's root moved: $(one_line "$_t5q")" load
    fi

    # 7. `skipped` IS NOT IMPAIRMENT. `doc-drift` is `skipped` in every fixture document: a step
    #    declining to run for a stated, healthy reason did not fail to see, and reporting it as
    #    blindness would make a tick that behaved exactly as designed read as one that could not.
    case "$_t2q" in
        *doc-drift*) add_row "impairment_excludes_skipped" false "a skipped step was reported as impairment: $(one_line "$_t2q")" load ;;
        *) add_row "impairment_excludes_skipped" true "a skipped step appears in neither impaired[] nor the root" load ;;
    esac

    # 8. STORE-FREE. The reading is derived from the run's own JSON and the log the tick already
    #    keeps: no cursor, no second log, and no field on any artifact.
    _extra=$(find "${_fx}/.workaholic" -type f ! -path '*/moderations/*' 2>/dev/null | head -3)
    if [ -z "$_extra" ]; then
        add_row "impairment_stores_nothing" true "the reading wrote no cursor and no artifact — only the tick log the tick already keeps" load
    else
        add_row "impairment_stores_nothing" false "the reading wrote outside the tick log:$(printf ' %s' $_extra)" load
    fi

    # 9. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE, and written against the BEHAVIOUR:
    #    the pre-change parse restored, so `status` is captured by nothing. It must show BOTH
    #    halves of the measured defect — the impairment unnamed on a root that posts, AND the
    #    impaired tick silent — because a breaker that only checks a missing JSON key would pass
    #    the refactor this drill exists to catch.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${_mod}/." "$_broken/"
    sed 's|> "${TMP}/status"|> "${TMP}/status.dropped"; : > "${TMP}/status"|' \
        "$_render" > "${_broken}/render-tick-post.sh"
    chmod +x "${_broken}/render-tick-post.sh"
    _bq=$(sh "${_broken}/render-tick-post.sh" --tick 20260819-104500 --root "$_fx" --questions 1 < "${_tmp}/impaired.json" 2>&1 || true)
    _b0=$(sh "${_broken}/render-tick-post.sh" --tick 20260819-104500 --root "$_fx" --questions 0 < "${_tmp}/impaired.json" 2>&1 || true)
    _unnamed=no; _silent=no
    case "$(_root_text "$_bq")" in *'could not read'*) ;; *) _unnamed=yes ;; esac
    case "$_b0" in *'"post": false'*) _silent=yes ;; esac
    if [ "$_unnamed" = yes ] && [ "$_silent" = yes ]; then
        add_row "impairment_breaker" true "with the status pass dropped the impairment goes unnamed AND the impaired tick goes silent (this drill can fail)" breaker
    else
        add_row "impairment_breaker" false "the breaker did not break: unnamed=${_unnamed} silent=${_silent}, so rows 1-4 prove nothing" breaker
    fi

    # 10. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "impairment_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "impairment_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "impairment" 0 "fail" 1
    fi
    emit_verdict "impairment" 0 "pass" 0
}

# ------------------------------------------------------- verify-operator-pulls
# THE PULL REQUESTS THE LOOP OPENS FOR A PERSON (2026-08-29, mission
# `follow-the-pull-requests-the-loop-opens-for-a-person`).
#
# `publish-tree-pr.sh` refuses to auto-merge a ruling or a strategy publication, because
# MERGING IS THE OPERATOR'S RULING AND CLOSING IS THEIR REFUSAL — and then nothing followed the
# pull request. Measured 2026-08-29: #694 sat 18 hours unanswered.
#
# HERMETIC. A bare local origin, `gh` stubbed on PATH, and no network call on any path. The
# stub serves the open-pull listing, the per-pull `files` shape and the per-pull state, so the
# derivation's own adapter and the reader's own parse are what get exercised.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR, NOT A RETURN SHAPE: a copy of the derivation
# wired at the pull request's TITLE instead of the seam's refusal word. It must lose the
# retitled ruling — the one that is most certainly the operator's — while a refactor that keeps
# the JSON shape and loses the bound still fires it.
cmd_verify_operator_pulls() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _branch="${REPO_ROOT}/plugins/workaholic/skills/branching/scripts"
    _lister="${_branch}/list-operator-facing-pulls.sh"
    _effect="${_branch}/publication-effect.sh"
    _step="${_mod}/step-operator-pulls.sh"
    _supp="${_mod}/ruling-suppression.sh"
    _rule="${_branch}/lib/publication-refusal.sh"
    for _f in "$_lister" "$_effect" "$_step" "$_supp" "$_rule"; do
        [ -f "$_f" ] || emit_err "operator_pulls_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _bin="${_tmp}/bin"
    _fx="${_tmp}/fx"
    mkdir -p "$_bin" "${_fx}/.workaholic"
    git -C "$_fx" init -q . >/dev/null 2>&1 || true
    git -C "$_fx" remote add origin git@github.com:acme-org/drill-repo.git >/dev/null 2>&1 || true

    # THE FIXTURE NEEDS THREE PUBLICATIONS WITH DIFFERENT PROVENANCE. A stub answering one
    # shape for every pull request would let a title-keyed derivation pass without ever
    # exercising the refusal word.
    #   701  a ruling whose title says nothing about rulings   -> the trap
    #   702  a strategy amendment, titled `[Ruling] ...`       -> a title would misclassify it
    #   703  an ordinary `[Proposal]` that auto-merged         -> never a member
    _t18=$(_iso_hours_ago 18)
    _t3=$(_iso_hours_ago 3)
    _t40=$(_iso_hours_ago 40)
    _t1=$(_iso_hours_ago 1)
    cat > "${_bin}/gh" <<EOF
#!/bin/sh
_filter=""; _prev=""
for a in "\$@"; do
  if [ "\$_prev" = "--jq" ]; then _filter="\$a"; fi
  _prev="\$a"
done
case "\$2" in
  rate_limit) echo 5000; exit 0 ;;
esac
case "\$*" in
  *"pulls?state=open"*)
    printf '701\thttps://x/701\tHand the routine-rename decision to a person\t${_t18}\tclaude[bot]\n'
    printf '702\thttps://x/702\t[Ruling] Revise the direction\t${_t3}\tclaude[bot]\n'
    printf '703\thttps://x/703\t[Proposal] Say when the loop has run out of direction\t${_t40}\tclaude[bot]\n'
    exit 0 ;;
  *"pulls/701/files"*)
    _b='[{"status":"modified","filename":".workaholic/missions/active/m1/mission.md","patch":"@@\n-feedback: [a.md]\n+feedback: [a.md, b.md]\n"}]' ;;
  *"pulls/702/files"*)
    _b='[{"status":"modified","filename":".workaholic/strategies/dir1.md","patch":"@@\n+## Schedule\n"}]' ;;
  *"pulls/703/files"*)
    _b='[{"status":"added","filename":".workaholic/missions/active/m9/mission.md","patch":"@@\n+feedback: [z.md]\n"}]' ;;
  *"pulls/701"*)
    _b='{"number":701,"html_url":"https://x/701","state":"open","merged_at":null,"created_at":"${_t18}"}' ;;
  *"pulls/702"*)
    if [ -f "${_tmp}/702-merged" ]; then
      _b="{\"number\":702,\"html_url\":\"https://x/702\",\"state\":\"closed\",\"merged_at\":\"${_t1}\",\"created_at\":\"${_t3}\"}"
    else
      _b='{"number":702,"html_url":"https://x/702","state":"open","merged_at":null,"created_at":"${_t3}"}'
    fi ;;
  *"pulls/703"*)
    _b='{"number":703,"html_url":"https://x/703","state":"closed","merged_at":null,"created_at":"${_t40}"}' ;;
  *) exit 1 ;;
esac
if [ -n "\$_filter" ]; then printf '%s' "\$_b" | jq -r "\$_filter"; else printf '%s' "\$_b"; fi
EOF
    chmod +x "${_bin}/gh"
    PATH="${_bin}:${PATH}"
    export PATH

    # 1. THE RULE ITSELF, over the normalised stream both callers adapt into. The shape test is
    #    what tells a carried attribution from a brand-new mission, and every `/specificate`
    #    proposal writes one of the second kind — catching those would stop the loop merging.
    _cls() { printf '%s' "$1" | ( . "$_rule"; publication_refusal_word ); }
    _r1=$(_cls "M	.workaholic/missions/active/m/mission.md	1
")
    _r2=$(_cls "A	.workaholic/missions/active/m/mission.md	1
")
    _r3=$(_cls "M	.workaholic/strategies/d.md	0
")
    if [ "$_r1" = "ruling_touching" ] && [ "$_r2" = "" ] && [ "$_r3" = "strategy_touching" ]; then
        add_row "opul_rule_is_the_shape" true "an existing mission whose feedback line moves is a ruling, a brand-new one is not, a strategy is its own word" load
    else
        add_row "opul_rule_is_the_shape" false "the shape test misclassified: existing=$_r1 new=$_r2 strategy=$_r3" load
    fi

    # 2. THE DERIVATION over the fixture: the retitled ruling IS a member, the auto-merged
    #    proposal is NOT, and the strategy publication carries its own word.
    _list=$(cd "$_fx" && sh "$_lister" 2>&1 || true)
    _members=$(printf '%s' "$_list" | jq -r '[.pulls[]?.number] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_members" = "701,702" ]; then
        add_row "opul_membership_is_the_refusal_word" true "the derivation names 701 (retitled ruling) and 702 (strategy) and excludes the auto-merged proposal" load
    else
        add_row "opul_membership_is_the_refusal_word" false "expected 701,702 — got [$_members]: $(one_line "$_list")" load
    fi
    _w701=$(printf '%s' "$_list" | jq -r '[.pulls[]? | select(.number==701) | .refusal_word] | first // ""' 2>/dev/null || printf '')
    _w702=$(printf '%s' "$_list" | jq -r '[.pulls[]? | select(.number==702) | .refusal_word] | first // ""' 2>/dev/null || printf '')
    if [ "$_w701" = "ruling_touching" ] && [ "$_w702" = "strategy_touching" ]; then
        add_row "opul_words_are_the_seams" true "each member carries the seam's own refusal word, never a third vocabulary" load
    else
        add_row "opul_words_are_the_seams" false "701=$_w701 702=$_w702" load
    fi

    # 3. THE FOUR EFFECT WORDS, and the NULL age on `unreadable` — a zero would read as *just
    #    opened*, the most urgent thing this vocabulary can say, for a read we could not make.
    _e701=$(cd "$_fx" && sh "$_effect" 701 2>&1 || true)
    _e703=$(cd "$_fx" && sh "$_effect" 703 2>&1 || true)
    _e999=$(cd "$_fx" && sh "$_effect" 999 2>&1 || true)
    _eff() { printf '%s' "$1" | jq -r '.effect // ""' 2>/dev/null || printf ''; }
    _age() { printf '%s' "$1" | jq -r '.age_hours // "null"' 2>/dev/null || printf '?'; }
    case "$(_eff "$_e701")" in
        open:1[678]|open:19) add_row "opul_open_reads_its_age" true "an un-acted pull request reads open:<age> in whole hours" load ;;
        *) add_row "opul_open_reads_its_age" false "expected open:~18, got $(one_line "$_e701")" load ;;
    esac
    if [ "$(_eff "$_e703")" = "closed" ] && [ "$(_age "$_e703")" = "null" ]; then
        add_row "opul_closed_is_a_refusal" true "a closed-unmerged pull request reads closed — the operator's refusal, never a merge" load
    else
        add_row "opul_closed_is_a_refusal" false "$(one_line "$_e703")" load
    fi
    if [ "$(_eff "$_e999")" = "unreadable" ] && [ "$(_age "$_e999")" = "null" ]; then
        add_row "opul_unreadable_has_a_null_age" true "a read we could not make is unreadable with a NULL age, never a zero" load
    else
        add_row "opul_unreadable_has_a_null_age" false "$(one_line "$_e999")" load
    fi
    : > "${_tmp}/702-merged"
    _e702=$(cd "$_fx" && sh "$_effect" 702 2>&1 || true)
    rm -f "${_tmp}/702-merged"
    if [ "$(_eff "$_e702")" = "merged" ]; then
        add_row "opul_merged_is_settled" true "a merged pull request reads merged — the operator ruled, and it landed" load
    else
        add_row "opul_merged_is_settled" false "$(one_line "$_e702")" load
    fi

    # 4. THE QUESTION REACHES ITS PERSON EXACTLY ONCE. The step names the candidates; the gate
    #    is `ask-question.sh`'s, unchanged, keyed on the pull request's number.
    _s1=$(cd "$_fx" && sh "$_step" --tick 20260829-140000 --root . 2>&1 || true)
    _keys=$(printf '%s' "$_s1" | jq -r '[.needs_agent[]?.pulls[]?.key] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_keys" = "operator-pull:701,operator-pull:702" ]; then
        add_row "opul_asks_per_pull_request" true "one question per un-acted pull request, keyed on its number" load
    else
        add_row "opul_asks_per_pull_request" false "expected two keyed questions, got [$_keys]: $(one_line "$_s1")" load
    fi
    _ev=$(printf '%s' "$_s1" | jq -r '.event // ""' 2>/dev/null || printf '')
    if [ -n "$_ev" ]; then
        add_row "opul_candidate_supplies_an_event" true "a candidate supplies an event, so the root carries a line" load
    else
        add_row "opul_candidate_supplies_an_event" false "no event for a tick with two un-acted pull requests" load
    fi

    _ask="${_mod}/ask-question.sh"
    _when="--hour 14 --weekday 3"
    _log="${_mod}/log-append.sh"
    _a1=$(cd "$_fx" && sh "$_ask" --root . --tick 20260829-140000 --key "operator-pull:701" $_when 2>&1 || true)
    # `run.sh` writes the log line, not the gate, so the drill plays that part before asking
    # again — otherwise the second call would be testing an empty ledger rather than the gate.
    _a1step=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p' | head -1)
    [ -z "$_a1step" ] || ( cd "$_fx" && sh "$_log" --root . --tick 20260829-140000 \
        --step "$_a1step" --status filed --summary "asked the operator about 701" ) >/dev/null 2>&1 || true
    _a2=$(cd "$_fx" && sh "$_ask" --root . --tick 20260829-150000 --key "operator-pull:701" $_when 2>&1 || true)
    case "${_a1}|${_a2}" in
        *'"ask": true'*'"already_asked"'*)
            add_row "opul_asked_exactly_once" true "the first tick asks and the second is refused already_asked — the gate is untouched" load ;;
        *)
            add_row "opul_asked_exactly_once" false "first=$(one_line "$_a1") second=$(one_line "$_a2")" load ;;
    esac

    # 5. THE SETTLED CASE ASKS NOBODY AND RENDERS NO ROOT LINE. `merged` and `closed` are the
    #    operator having answered; an hourly restatement of that is what two roots were retired
    #    for.
    : > "${_tmp}/702-merged"
    _s2=$(cd "$_fx" && sh "$_step" --tick 20260829-160000 --root . 2>&1 || true)
    rm -f "${_tmp}/702-merged"
    _n2=$(printf '%s' "$_s2" | jq -r '[.needs_agent[]?.pulls[]?.key] | length' 2>/dev/null || printf '?')
    if [ "$_n2" = "1" ]; then
        add_row "opul_settled_asks_nobody" true "the merged pull request drops out of the candidate set; only the un-acted one is asked about" load
    else
        add_row "opul_settled_asks_nobody" false "expected one remaining candidate, got $_n2: $(one_line "$_s2")" load
    fi

    # 6. THE HOLD IS THE RULING'S OWN, AND THIS QUESTION IS WHAT BREAKS THE SILENCE. Both
    #    readings compose `ruling-suppression.sh`, so they cannot diverge about what a ruling
    #    holds — and nothing here releases the hold, which would ask one person twice.
    _stepsrc=$(sed 's/^[[:space:]]*#.*$//' "$_step")
    case "$_stepsrc" in
        *ruling-suppression.sh*)
            add_row "opul_shares_the_hold_reading" true "the step composes ruling-suppression.sh rather than re-deriving what a ruling holds" load ;;
        *)
            add_row "opul_shares_the_hold_reading" false "the step derives the held subjects itself, so the two readings can diverge" load ;;
    esac
    _suppsrc=$(cat "$_supp")
    case "$_suppsrc" in
        *"keyed on the SUBJECT"*|*"KEYED ON THE SUBJECT"*)
            add_row "opul_hold_stays_keyed_on_the_subject" true "the hold is still keyed on the subject, never on the existence of a ruling" load ;;
        *)
            add_row "opul_hold_stays_keyed_on_the_subject" false "the hold's subject-keying rule is no longer stated where it is enforced" load ;;
    esac

    # 7. IT MERGES, CLOSES AND GATES NOTHING. Call sites, never words: the step's prose says in
    #    English that it never merges, so a word-level ban would fail on the sentence stating
    #    the rule.
    _acted=""
    for _act in "--method PUT" "--method PATCH" "--method DELETE" "/merge" "publish-tree-pr.sh" \
                "publish-tree-commit.sh" "git push" "plan-units.sh" "close.sh"; do
        case "$_stepsrc" in *"$_act"*) _acted="${_acted}${_acted:+, }${_act}" ;; esac
    done
    if [ -z "$_acted" ]; then
        add_row "opul_asks_and_nothing_else" true "the step reaches no merge, close, push, gate or survey call site" load
    else
        add_row "opul_asks_and_nothing_else" false "the step reaches: $_acted" load
    fi

    # 8. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. A copy of the derivation wired at the
    #    pull request's TITLE — which is what `list-open-rulings.sh` does on purpose, for a
    #    brake — must lose the retitled ruling. Written against the behaviour rather than the
    #    return shape, so a refactor that keeps the JSON and loses the bound still fires it.
    # The whole `branching/scripts` tree is copied so the broken derivation keeps a real
    # `lib/publication-refusal.sh` beside it — otherwise it would refuse `no_refusal_rule` and
    # the row would pass for a reason that has nothing to do with the bound being tested.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${_branch}/." "$_broken/"
    sed 's#^\( *\)word="$(printf .*publication_refusal_word)"#\1case "$title" in "[Ruling] "*) word=ruling_touching ;; *) word="" ;; esac#' \
        "$_lister" > "${_broken}/list-operator-facing-pulls.sh"
    chmod +x "${_broken}/list-operator-facing-pulls.sh"
    _bl=$(cd "$_fx" && sh "${_broken}/list-operator-facing-pulls.sh" 2>&1 || true)
    _bm=$(printf '%s' "$_bl" | jq -r '[.pulls[]?.number] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_bm" != "701,702" ]; then
        add_row "opul_breaker" true "wired at the title the derivation loses the retitled ruling (members became [$_bm]) — this drill can fail" breaker
    else
        add_row "opul_breaker" false "the breaker did not break: a title-keyed derivation still named [$_bm], so row 2 proves nothing" breaker
    fi

    # 9. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "opul_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "opul_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "operator-pulls" 0 "fail" 1
    fi
    emit_verdict "operator-pulls" 0 "pass" 0
}

cmd_verify_findings_to_work() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _step="${_mod}/step-file-findings.sh"
    _ledger="${_mod}/list-finding-issues.sh"
    _supp="${_mod}/finding-suppression.sh"
    _filer="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh"
    _table="${REPO_ROOT}/plugins/workaholic/skills/moderate/reference/workflow.md"
    for _f in "$_step" "$_ledger" "$_supp" "$_filer" "$_table"; do
        [ -f "$_f" ] || emit_err "findings_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _bin="${_tmp}/bin"
    _fx="${_tmp}/fx"
    mkdir -p "$_bin" "${_fx}/.workaholic"
    git -C "$_fx" init -q . >/dev/null 2>&1 || true
    git -C "$_fx" remote add origin git@github.com:acme-org/drill-repo.git >/dev/null 2>&1 || true

    _fid=$(sh -c ". ${_mod}/lib/question-id.sh; question_slug 'finding:retire-claims'")

    # THE STUB IS THE WHOLE NETWORK. It serves the issues listing, applies `--jq` with real jq
    # so the reader's own parse is what is exercised, and records every POST body so the filing
    # can be inspected without opening anything. Any other call exits non-zero: a drill that
    # silently reached the network would be proving nothing about an offline container.
    cat > "${_bin}/gh" <<EOF
#!/bin/sh
_filter=""; _prev=""; _post=0
for a in "\$@"; do
  if [ "\$_prev" = "--jq" ]; then _filter="\$a"; fi
  if [ "\$a" = "POST" ]; then _post=1; fi
  _prev="\$a"
done
if [ "\$_post" = "1" ]; then
  cat > "${_tmp}/posted.json"
  printf '{"number": 42, "html_url": "https://example.invalid/42"}\n'
  exit 0
fi
case "\$*" in
  *"api user"*) printf 'drill-bot\n'; exit 0 ;;
  *"issues?state=all"*)
    case "\${WH_LEDGER:-empty}" in
      empty)  _body='[]' ;;
      open)   _body='[{"number":9,"html_url":"https://example.invalid/9","state":"open","body":"finding: retire-claims / id: ${_fid}\\n"}]' ;;
      closed) _body='[{"number":9,"html_url":"https://example.invalid/9","state":"closed","body":"finding: retire-claims / id: ${_fid}\\n"}]' ;;
      broken) exit 1 ;;
    esac ;;
  *) exit 1 ;;
esac
if [ -n "\$_filter" ]; then printf '%s' "\$_body" | jq -r "\$_filter"; else printf '%s' "\$_body"; fi
EOF
    chmod +x "${_bin}/gh"

    # THE FIXTURE: one repairable finding with an event, one repairable finding that DEGRADED
    # (our own machinery failing is the loop's debt too), one repairable step that found
    # nothing, and one `needs_ruling` step shouting as loudly as it can.
    cat > "${_tmp}/reports.json" <<'EOF'
{"steps": [
 {"step": "retire-claims", "status": "ok", "reason": "", "summary": "1 blocked", "needs_agent": 0, "logged": true, "event": "a claim branch CI could not delete"},
 {"step": "inbound-sweep", "status": "degraded", "reason": "channel_unreadable", "summary": "the channel could not be read", "needs_agent": 0, "logged": true, "event": ""},
 {"step": "doc-drift", "status": "ok", "reason": "", "summary": "no new drift", "needs_agent": 0, "logged": true, "event": ""},
 {"step": "undrivable-units", "status": "blocked", "reason": "", "summary": "2 undrivable", "needs_agent": 2, "logged": true, "event": "2 queued artifacts nobody can drive"}
]}
EOF
    _run_step() {
        ( cd "$_fx" && PATH="${_bin}:${PATH}" WH_LEDGER="$1" \
            WORKAHOLIC_TICK_REPORTS="${_tmp}/reports.json" \
            sh "${2:-$_step}" --tick 20260829-060000 --root "$_fx" 2>&1 || true )
    }
    _cands() { printf '%s' "$1" | jq -r '[.needs_agent[0].candidates[]?.step] | join(",")' 2>/dev/null || printf ''; }
    _field() { printf '%s' "$1" | jq -r "$2" 2>/dev/null || printf ''; }

    # 1. THE CLASSIFICATION NAMES EACH FINDING. The repairable ones become candidates; the
    #    `needs_ruling` one never does. This is the mission's whole safety property.
    _free=$(_run_step empty)
    if [ "$(_cands "$_free")" = "retire-claims,inbound-sweep" ]; then
        add_row "findings_classified" true "both repairable findings are candidates and only those" load
    else
        add_row "findings_classified" false "expected retire-claims,inbound-sweep; got '$(_cands "$_free")' ($(one_line "$_free"))" load
    fi
    case "$(one_line "$_free")" in
        *undrivable-units*)
            add_row "findings_ruling_never_filed" false "a needs_ruling finding reached the filing act" load ;;
        *)
            add_row "findings_ruling_never_filed" true "the needs_ruling finding never reaches the filer, however loudly it reported" load ;;
    esac

    # 2. THE BRAKE HOLDS WHILE ONE IS OPEN, AND RELEASES WHEN IT IS CLOSED.
    _held=$(_run_step open)
    if [ "$(_field "$_held" '.reason')" = "brake_held" ] && [ -z "$(_cands "$_held")" ]; then
        add_row "findings_brake_holds" true "with one finding issue open nothing is filed: $(_field "$_held" '.summary')" load
    else
        add_row "findings_brake_holds" false "the brake did not hold: $(one_line "$_held")" load
    fi
    _closed=$(_run_step closed)
    if [ "$(_cands "$_closed")" = "inbound-sweep" ]; then
        add_row "findings_brake_releases" true "closing the issue releases the brake, and the dedup still drops the finding it carried" load
    else
        add_row "findings_brake_releases" false "expected inbound-sweep alone; got '$(_cands "$_closed")'" load
    fi

    # 3. AN UNREADABLE BRAKE FILES NOTHING AND SAYS SO — distinctly from a held one, because
    #    *one is in flight* and *I could not look* are different facts about the loop.
    _blind=$(_run_step broken)
    if [ "$(_field "$_blind" '.reason')" = "brake_unreadable" ] && [ -z "$(_cands "$_blind")" ]; then
        add_row "findings_brake_unreadable" true "an unreadable ledger files nothing under its own reason" load
    else
        add_row "findings_brake_unreadable" false "expected brake_unreadable with no candidates: $(one_line "$_blind")" load
    fi

    # 4. THE FILING GOES THROUGH THE ONE FILER, WITH THE MARKER AND THE DIRECTION LINE.
    printf 'The tick could not delete a claim branch.\n' > "${_tmp}/body.md"
    _fil=$( cd "$_fx" && PATH="${_bin}:${PATH}" sh "$_filer" \
        --finding "retire-claims:${_fid}" --subject 'observer_ai:drill' --assignee drill-bot \
        --feedback '20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md' \
        acme-org/drill-repo '[FB] a claim branch CI could not delete' "${_tmp}/body.md" 2>&1 || true )
    _posted=$(cat "${_tmp}/posted.json" 2>/dev/null || printf '')
    _pbody=$(printf '%s' "$_posted" | jq -r '.body // ""' 2>/dev/null || printf '')
    case "$_pbody" in
        *"finding: retire-claims / id: ${_fid}"*)
            add_row "findings_marker_written" true "the one filer wrote the visible finding marker the next tick reads back" load ;;
        *)
            add_row "findings_marker_written" false "the marker is missing from the filed body: $(one_line "$_pbody")" load ;;
    esac
    case "$_pbody" in
        *"source: moderate"*"feedback: "*)
            add_row "findings_direction_carried" true "the direction line rides the issue, through the one writer of that line" load ;;
        *)
            add_row "findings_direction_carried" false "expected source: moderate and a feedback line: $(one_line "$_pbody")" load ;;
    esac

    # 5. A SECOND TICK FILES NOTHING. The dedup is STRUCTURAL: the issues are the memory, so
    #    nothing is stored and no cursor exists to forget.
    _second=$(_run_step open)
    if [ -z "$(_cands "$_second")" ]; then
        add_row "findings_second_tick_files_nothing" true "the finding filed by the first tick is not offered again" load
    else
        add_row "findings_second_tick_files_nothing" false "a second tick re-offered: $(_cands "$_second")" load
    fi

    # 6. THE FILED SUBJECT'S QUESTION IS HELD WHILE THE UNFILED ONE STILL ASKS. Keyed on the
    #    SUBJECT: suppressing on `any_open` would silence the whole question queue behind one
    #    filing, which is the bug this is written against.
    _s=$( cd "$_fx" && PATH="${_bin}:${PATH}" WH_LEDGER=open sh "$_supp" 2>&1 || true )
    _hs=$(_field "$_s" '.held.steps | join(",")')
    if [ "$_hs" = "retire-claims" ]; then
        add_row "findings_question_held" true "the filed step's question is held and no other step's is" load
    else
        add_row "findings_question_held" false "expected retire-claims held alone; got '${_hs}'" load
    fi
    _sblind=$( cd "$_fx" && PATH="${_bin}:${PATH}" WH_LEDGER=broken sh "$_supp" 2>&1 || true )
    if [ "$(_field "$_sblind" '.readable')" = "false" ] && [ "$(_field "$_sblind" '.held.steps | length')" = "0" ]; then
        add_row "findings_unreadable_holds_nothing" true "an unreadable suppression read holds nothing and names its reason" load
    else
        add_row "findings_unreadable_holds_nothing" false "an unreadable read suppressed something: $(one_line "$_sblind")" load
    fi

    # 7. FILED, HELD AND LEFT RENDER AS THREE DISTINCT STATEMENTS.
    if [ "$(_field "$_held" '.held | length')" = "2" ] \
       && [ "$(_field "$_closed" '.already_filed | length')" = "1" ] \
       && [ "$(_field "$_free" '.left')" = "1" ]; then
        add_row "findings_reported_three_ways" true "held, already-filed and left are three separate readings on one output" load
    else
        add_row "findings_reported_three_ways" false "the three readings did not separate: held=$(_field "$_held" '.held|length') already=$(_field "$_closed" '.already_filed|length') left=$(_field "$_free" '.left')" load
    fi
    if [ "$(_field "$_free" '.event')" = "" ]; then
        add_row "findings_event_empty" true "the step claims no event: nothing is filed when run.sh reads its line" load
    else
        add_row "findings_event_empty" false "the step announced an act it has not taken: $(_field "$_free" '.event')" load
    fi

    # 8. THE BREAKER ROW, LABELLED AS THE INTENTIONAL FAILURE. Written against the BEHAVIOUR —
    #    a `needs_ruling` finding reaching the filer — rather than against a return shape, on
    #    `verify-checkin-delivery`'s own lesson: a breaker written against the shape passes a
    #    refactor that keeps the shape and loses the bound. Widen the classification to every
    #    finding and row 1 must fail.
    # The WHOLE plugin tree is copied (`verify-residue`'s shape): the step reaches its ledger,
    # which reaches `gather/scripts/gh-rest.sh` two directories up, so a copy of one scripts
    # directory would degrade on the missing closure and the breaker would "fail" for the wrong
    # reason — which is a breaker that proves nothing.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/." "${_broken}/"
    sed 's/`needs_ruling` |/**`repairable`** |/g' "$_table" \
        > "${_broken}/skills/moderate/reference/workflow.md"
    _bout=$(_run_step empty "${_broken}/skills/moderate/scripts/step-file-findings.sh")
    case "$(_cands "$_bout")" in
        *undrivable-units*)
            add_row "findings_breaker" true "with the classification widened to every finding, a needs_ruling finding reaches the filer (this drill can fail)" breaker ;;
        *)
            add_row "findings_breaker" false "the breaker did not break: widening the classification changed nothing, so row 1 proves nothing ('$(_cands "$_bout")')" breaker ;;
    esac

    # 9. THE NEGATIVE SPACE: nothing outside the fixture was written, and no branch, pull
    #    request, merge or claim was touched — the only outward act available at all was the
    #    stubbed POST the filing makes.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "findings_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "findings_writes_nothing" false "the drill changed the working tree" load
    fi
    if [ -z "$(git -C "$_fx" branch --list 2>/dev/null)" ] \
       && [ ! -d "${_fx}/.worktrees" ] && [ ! -d "${_fx}/.publish" ]; then
        add_row "findings_touches_no_claim" true "no branch, worktree or publish tree was created" load
    else
        add_row "findings_touches_no_claim" false "the drill created a branch or a tree the tick may not create" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "findings-to-work" 0 "fail" 1
    fi
    emit_verdict "findings-to-work" 0 "pass" 0
}

cmd_verify_stage() {
    _str="${REPO_ROOT}/plugins/workaholic/skills/strategy/scripts"
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _srv="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _dig="${REPO_ROOT}/plugins/workaholic/skills/standup/scripts/digest.sh"
    for _f in "${_str}/create.sh" "${_str}/amend.sh" "${_str}/read.sh" "${_str}/list.sh" \
              "${_str}/direction-state.sh" "$_srv" "$_dig" "${_mod}/step-direction-health.sh"; do
        [ -f "$_f" ] || emit_err "stage_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    _wh="${_fx}/.workaholic"
    mkdir -p "${_wh}/strategies" "${_wh}/feedbacks"
    git -C "$_fx" init -q . >/dev/null 2>&1 || true
    git -C "$_fx" config user.email test@example.com >/dev/null 2>&1 || true
    git -C "$_fx" config user.name t >/dev/null 2>&1 || true
    printf -- '---\ntype: Feedback\n---\n\nx\n' > "${_wh}/feedbacks/20260101000000-a.md"
    printf '{"ok": true, "identity": "test", "proposals": []}\n' > "${_tmp}/open.json"

    _far=$(date -u -d '+400 days' +%Y-%m-%d 2>/dev/null || date -u -v+400d +%Y-%m-%d)

    # THE FIXTURE: one direction per stage, PLUS one carrying no `stage:` line at all, so the
    # absent-means-進行中 convention is drilled rather than assumed.
    _mk() { # slug stage
        _st=""
        [ -z "$2" ] || _st="stage: $2
"
        printf -- '---\ntype: Strategy\ntitle: T %s\nslug: %s\nstatus: active\n%starget_date: %s\nassignees: [test@example.com]\nfeedback: [20260101000000-a.md]\n---\n\n## Aim\n\na\n\n## Schedule\n\ns\n' \
            "$1" "$1" "$_st" "$_far" > "${_wh}/strategies/$1.md"
    }
    _mk running 進行中
    _mk improving 改良中
    _mk settled 観察中
    _mk unstaged ""
    ( cd "$_fx" && git add -A && git commit -q -m seed >/dev/null 2>&1 ) || true

    _survey() { ( cd "$_fx" && sh "$_srv" --open-proposals "${_tmp}/open.json" "30 days ago" "$_wh" 2>/dev/null || true ); }
    _f() { printf '%s' "$1" | jq -r "$2" 2>/dev/null || printf ''; }

    # 1. THE FIELD: created, refused outside the closed set with the artifact byte-identical,
    #    and an absent field reading 進行中 through the ONE place that default lives.
    _made=$( cd "$_fx" && printf 'aim\n' | sh "${_str}/create.sh" --stage 観察中 "Fresh" "$_far" "test@example.com" "s" "" "$_wh" 2>&1 || true )
    _seen=$( cd "$_fx" && sh "${_str}/read.sh" fresh "$_wh" 2>/dev/null | jq -r '.stage' )
    _b4=$(cat "${_wh}/strategies/fresh.md" 2>/dev/null | md5sum)
    _bad=$( cd "$_fx" && printf 'aim\n' | sh "${_str}/create.sh" --stage improving "Bad" "$_far" "test@example.com" "s" "" "$_wh" 2>&1 || true )
    _af=$(cat "${_wh}/strategies/fresh.md" 2>/dev/null | md5sum)
    if [ "$_seen" = "観察中" ] && [ "$(_f "$_bad" '.reason')" = "bad_stage" ] \
       && [ ! -f "${_wh}/strategies/bad.md" ] && [ "$_b4" = "$_af" ]; then
        add_row "stage_declared_and_floored" true "a stage round-trips through the one reader and a value outside the closed set is refused with nothing written" load
    else
        add_row "stage_declared_and_floored" false "create/read did not hold the closed set: seen='${_seen}' bad='$(one_line "$_bad")'" load
    fi
    rm -f "${_wh}/strategies/fresh.md"
    if [ "$( cd "$_fx" && sh "${_str}/read.sh" unstaged "$_wh" | jq -r '.stage + ":" + (.stage_declared|tostring)' )" = "進行中:false" ]; then
        add_row "stage_absent_means_running" true "an absent field reads 進行中 and says it was not declared, so no consumer quotes a declaration nobody made" load
    else
        add_row "stage_absent_means_running" false "the absent default or its declared flag is wrong" load
    fi

    # 2. AN ANNOUNCED MOVE reaches `amend.sh`, appends ONE dated Schedule line naming the move,
    #    and re-runs as a byte-identical no-op.
    _mv=$( cd "$_fx" && sh "${_str}/amend.sh" running --stage 改良中 "$_wh" 2>&1 || true )
    _again=$( cd "$_fx" && sh "${_str}/amend.sh" running --stage 改良中 "$_wh" 2>&1 || true )
    _lines=$(grep -c '^Revised .*stage 進行中 → 改良中\.$' "${_wh}/strategies/running.md" 2>/dev/null || echo 0)
    if [ "$(_f "$_mv" '.revised | join(",")')" = "stage" ] && [ "${_lines}" = "1" ] \
       && [ "$(_f "$_again" '.reason')" = "already" ]; then
        add_row "stage_move_is_auditable" true "the move lands, appends one dated line naming both ends, and a re-run writes nothing" load
    else
        add_row "stage_move_is_auditable" false "the move or its idempotence failed: $(one_line "$_mv") / $(one_line "$_again")" load
    fi
    _mk running 進行中
    ( cd "$_fx" && git add -A && git commit -q -m reset >/dev/null 2>&1 ) || true

    # 3. THE LIFECYCLE READING IS BYTE-IDENTICAL ACROSS ALL THREE STAGES. The stage rides
    #    BESIDE the derived answer and never enters its precedence.
    _states=$( cd "$_fx" && sh "${_str}/direction-state.sh" --open-proposals "${_tmp}/open.json" "30 days ago" "$_wh" 2>/dev/null \
        | jq -r '[.strategies[]? | select(.slug|test("running|improving|settled|unstaged")) | .state] | unique | join(",")' 2>/dev/null || printf '' )
    if [ "$_states" = "dormant" ]; then
        add_row "stage_never_enters_the_state" true "all four directions read the same derived state whatever their declared stage" load
    else
        add_row "stage_never_enters_the_state" false "the declared stage moved the lifecycle reading: states='${_states}'" load
    fi

    # 4. THE GATE: 観察中 originates nothing; the other two and the unstaged one propose exactly
    #    as before. This is the mission's central behaviour.
    _s=$(_survey)
    _sel=$(_f "$_s" '.selected | sort | join(",")')
    _obs=$(_f "$_s" '[.refused[] | select(.slug == "settled") | .reason] | join("")')
    if [ "$_obs" = "observing" ] && [ "$_sel" = "improving,running,unstaged" ]; then
        add_row "observing_originates_nothing" true "the 観察中 direction is refused observing and opens no issue; every other stage proposes" load
    else
        add_row "observing_originates_nothing" false "expected observing + improving,running,unstaged; got '${_obs}' / '${_sel}'" load
    fi
    _keep=$(_f "$_s" '[.refused[] | select(.slug == "settled") | (.pace|tostring), (.overdue|tostring), (.dormant|tostring), (.quiescent|tostring)] | length')
    if [ "$_keep" = "4" ]; then
        add_row "observing_still_visible" true "the refused row still carries every reading, so a settled direction stays visible" load
    else
        add_row "observing_still_visible" false "a refused observing row lost its readings" load
    fi

    # 5. THE ORDER: 改良中 leads, with membership unchanged.
    if [ "$(_f "$_s" '.selected | .[0]')" = "improving" ]; then
        add_row "improving_sorts_first" true "改良中 sorts before 進行中 with the set membership unchanged" load
    else
        add_row "improving_sorts_first" false "改良中 did not lead: $(_f "$_s" '.selected | join(",")')" load
    fi

    # 6. THE RENDERS: the digest names it, and the question heading names it.
    _d=$( cd "$_fx" && sh "$_dig" "1 day ago" "$_wh" 2>/dev/null || true )
    _q=$( cd "$_fx" && sh "${_mod}/step-direction-health.sh" --tick 20260826-000000 --root "$_fx" --open-proposals "${_tmp}/open.json" 2>/dev/null || true )
    [ -n "$_q" ] || _q='{}'
    _heads=$(printf '%s' "$_q" | jq -r '[.needs_agent[0].directions[]? | .heading] | join(" | ")' 2>/dev/null || printf '')
    if [ "$(_f "$_d" '[.strategies[] | select(.slug == "improving") | .stage] | join("")')" = "改良中" ]; then
        add_row "digest_names_the_stage" true "the morning digest names each direction declared stage" load
    else
        add_row "digest_names_the_stage" false "the digest does not carry the stage" load
    fi
    case "$_heads" in
        *改良中*|*進行中*) add_row "question_names_the_stage" true "the direction question names the declared stage in its heading" load ;;
        *) add_row "question_names_the_stage" false "no question heading names a stage: $(one_line "$_heads")" load ;;
    esac

    # 7. THE TRANSITION QUESTION, asked exactly once over two ticks — the asked-once gate,
    #    unchanged, over the key this mission adds.
    _k=$(printf '%s' "$_q" | jq -r '[.needs_agent[0].directions[]? | select(.slug == "improving") | .key] | join("")' 2>/dev/null || printf '')
    if [ "$_k" = "direction-settled:improving" ]; then
        add_row "settled_transition_asked" true "a quiet 改良中 direction is asked about settling, by its own key" load
    else
        add_row "settled_transition_asked" false "expected direction-settled:improving; got '${_k}'" load
    fi
    _gate1=$( cd "$_fx" && sh "${_mod}/ask-question.sh" --tick 20260826-000000 --key "direction-settled:improving" --root "$_fx" --hour 10 --weekday 3 2>/dev/null || true )
    if [ "$(_f "$_gate1" '.ask')" = "true" ]; then
        ( cd "$_fx" && sh "${_mod}/ask-question.sh" --record-ask --tick 20260826-000000 --key "direction-settled:improving" --log-step "$(_f "$_gate1" '.log_step')" --root "$_fx" >/dev/null 2>&1 ) || true
        _gate2=$( cd "$_fx" && sh "${_mod}/ask-question.sh" --tick 20260826-010000 --key "direction-settled:improving" --root "$_fx" --hour 10 --weekday 3 2>/dev/null || true )
        if [ "$(_f "$_gate2" '.ask')" = "false" ]; then
            add_row "transition_asked_once" true "a second tick does not re-ask: $(_f "$_gate2" '.reason')" load
        else
            add_row "transition_asked_once" false "the transition question was asked twice" load
        fi
    else
        add_row "transition_asked_once" false "the gate refused the first ask: $(one_line "$_gate1")" load
    fi

    # 8. THE NEGATIVES, stated explicitly: no reading moved a stage, closed, re-dated or
    #    amended a direction, and the artifact keeps its three writers.
    _stagenow=$( cd "$_fx" && sh "${_str}/list.sh" "$_wh" | jq -r '[.strategies[] | .slug + "=" + .stage] | sort | join(",")' )
    if [ "$_stagenow" = "improving=改良中,running=進行中,settled=観察中,unstaged=進行中" ]; then
        add_row "no_reading_moves_a_stage" true "every stage is exactly what the fixture declared after the whole chain ran" load
    else
        add_row "no_reading_moves_a_stage" false "a reading moved a stage: ${_stagenow}" load
    fi
    _stepsrc=$(grep -v '^[[:space:]]*#' "${_mod}/step-direction-health.sh")
    case "$_stepsrc" in
        *amend.sh*|*close.sh*|*create.sh*)
            add_row "question_reaches_no_writer" false "the step that asks about a stage reaches a strategy writer" load ;;
        *)
            add_row "question_reaches_no_writer" true "the asking step reaches none of the three strategy writers" load ;;
    esac
    _writers=$(ls "$_str" | grep -c '^\(create\|amend\|close\)\.sh$' || true)
    if [ "$_writers" = "3" ]; then
        add_row "writer_set_is_still_three" true "the strategy artifact still has exactly three writers" load
    else
        add_row "writer_set_is_still_three" false "the writer set moved" load
    fi

    # 9. THE BREAKER, written against the BEHAVIOUR rather than a return shape: the `observing`
    #    gate wired at a DERIVED reading (`dormant`) instead of the declared field. The output
    #    shape is identical — a refusal named `observing` on a row — so a breaker written
    #    against the shape would pass; row 4 must fail, because evidence would be silencing a
    #    direction the operator never settled. That substitution is this mission's central
    #    failure mode.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/." "${_broken}/"
    sed 's/elif (\.stage == "観察中") then "observing"/elif (.dormant == true) then "observing"/' \
        "$_srv" > "${_broken}/skills/propose/scripts/survey-strategies.sh"
    _bs=$( cd "$_fx" && sh "${_broken}/skills/propose/scripts/survey-strategies.sh" \
        --open-proposals "${_tmp}/open.json" "30 days ago" "$_wh" 2>/dev/null || true )
    _bsel=$(_f "$_bs" '.selected | sort | join(",")')
    _bobs=$(_f "$_bs" '[.refused[] | select(.slug == "settled") | .reason] | join("")')
    # The break fires when the wired-at-evidence survey no longer reproduces row 4: either the
    # declared direction stops being the refused one, or directions the operator never settled
    # get silenced too. Over this fixture it is the second — every direction is `dormant`, so
    # evidence silences all four and `selected` empties.
    if [ "$_bobs" != "observing" ] || [ "$_bsel" != "improving,running,unstaged" ]; then
        add_row "stage_breaker" true "with the gate wired at a derived reading (dormant) the silence no longer follows the declaration: refused='${_bobs}' selected='${_bsel}' (this drill can fail)" breaker
    else
        add_row "stage_breaker" false "the breaker did not break: a derived reading reproduced the declared behaviour exactly, so row 4 proves nothing" breaker
    fi

    # 10. THE NEGATIVE SPACE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "stage_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "stage_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "stage" 0 "fail" 1
    fi
    emit_verdict "stage" 0 "pass" 0
}

# ------------------------------------------------------------------ verify-all
#
# THE AGGREGATE VERB (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`).
# Thirty drills, one per mechanism an earlier turn of the loop built — and until this verb
# each was invoked by hand, one at a time, its result a JSON line a person read. Nothing
# composed them, so there was no artifact a CI step or a `/moderate` step could read, and
# the loop merged hourly with no idea whether what it had already proved still held.
#
# THE SET COMES FROM THE DISPATCHER PLUS THE REGISTER, NEVER FROM A LIST HERE. The
# dispatcher's `case` arms are the enumeration; `docs/loop-drill-runbook.md` §9's register,
# read through the plugin's one reader, says of each what kind it is. A drill in the
# dispatcher that the register does not classify is `skipped:unclassified` and is NEVER
# silently absent — which is exactly the state `scripts/test-workflow-scripts.mjs` fails on,
# so a new drill is either run or deliberately classified.
#
# THE VERDICT VOCABULARY IS THE DRILL'S OWN EXIT VOCABULARY, NOT A SECOND ONE:
#
#   exit 0 -> pass                 the drill ran and every load-bearing row held
#   exit 1 -> fail                 the drill ran and a load-bearing row went false
#   exit 3 -> skipped:<reason>     a dirty precondition, named by the drill itself
#   exit 4 -> skipped:<reason>     the environment could not answer (`gh_unavailable`, …)
#   exit 5 -> skipped:not_run_yet  a stage nobody has fired
#   other  -> fail                 including the per-drill timeout, named `timeout`
#
# A SKIP IS A NAMED FACT, NEVER A SILENT PASS, and a skipped drill is never counted toward
# the passing total. Exit status is non-zero if and only if at least one verdict is `fail`:
# a wholly skipped run is neither a pass nor a failure and says so, because a gate that goes
# red on a skip is disabled within a week.
#
# `unproved` IS NOT `fail`. A drill whose rows include no `bearing: "breaker"` row has never
# been shown able to fail; that is a gap in coverage rather than a broken mechanism, so it
# keeps the verdict `pass`, is reported `breaker: "absent"`, and is counted OUTSIDE the
# `proved` total. Conflating the two makes the failure signal noisy on the day it matters.
cmd_verify_all() {
    _only=""
    _list="false"
    _kinds="hermetic,reads_checkout"
    _timeout="${DRILL_TIMEOUT_SECONDS:-300}"
    while [ $# -gt 0 ]; do
        case "$1" in
            --list) _list="true" ;;
            --only) shift; _only="${1:-}" ;;
            --kind) shift; _kinds="${1:-}" ;;
            --timeout) shift; _timeout="${1:-300}" ;;
            *) emit_err "usage" 2 "verify-all takes --list, --only <drill>, --kind <k>[,<k>] and --timeout <seconds>" ;;
        esac
        shift || true
    done

    _reg="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/drill-register.sh"
    _register_state="ok"
    _rows_reg=""
    if [ -f "$_reg" ]; then
        _rows_reg=$(cd "$REPO_ROOT" && sh "$_reg" list 2>/dev/null || true)
    fi
    case "$_rows_reg" in
        *'"ok": true'*) ;;
        *) _register_state="no_register"; _rows_reg="" ;;
    esac

    # The enumeration: the dispatcher's own `case` arms, minus this verb.
    _cmds=$(sed -n 's/^    \(verify-[a-z-]*\)) cmd_.*/\1/p' "$0" | grep -v '^verify-all$' || true)
    [ -n "$_cmds" ] || emit_err "no_drills" 4 "the dispatcher names no verify-* command"

    _bounded="true"
    command -v timeout >/dev/null 2>&1 || _bounded="false"

    _out=""
    _proved=0
    _unproved=0
    _failed=0
    _skipped=0
    _total=0

    for _c in $_cmds; do
        if [ -n "$_only" ] && [ "$_c" != "$_only" ]; then continue; fi
        _total=$((_total + 1))

        _kind=""
        _mission=""
        _mres="false"
        if [ -n "$_rows_reg" ]; then
            _line=$(printf '%s' "$_rows_reg" | tr '{' '\n' | grep "\"drill\": \"${_c}\"," || true)
            _kind=$(printf '%s' "$_line" | sed -n 's/.*"kind": "\([a-z_]*\)".*/\1/p')
            _mission=$(printf '%s' "$_line" | sed -n 's/.*"mission": "\([a-z0-9-]*\)".*/\1/p')
            case "$_line" in *'"mission_resolved": true'*) _mres="true" ;; esac
        fi

        _verdict=""
        _reason=""
        _breaker="unknown"
        _detail=""
        _dur=0

        if [ "$_register_state" = "no_register" ] || [ -z "$_kind" ]; then
            _verdict="skipped"
            _reason="unclassified"
        elif [ "$_kind" = "needs_server" ]; then
            # Never invoked: it takes an issue number only `seed` can mint against the real
            # remote, so running it would spend a round trip to learn what the register says.
            # Named BEFORE the kind filter, so the reason is the drill's own rather than
            # whichever set this run happened to ask for.
            _verdict="skipped"
            _reason="needs_server"
        elif [ -z "$_only" ] && ! printf ',%s,' "$_kinds" | grep -q ",${_kind}," ; then
            # A kind this run was not asked for. CI asks for `hermetic` alone — a
            # `reads_checkout` drill's verdict is a fact about the tree it ran in and
            # `needs_server` is never invoked at all — so the skip is named by the kind
            # rather than folded into either of the others.
            _verdict="skipped"
            _reason="kind_${_kind}"
        elif [ "$_kind" = "needs_server" ]; then
            # Never invoked: it takes an issue number only `seed` can mint against the real
            # remote, so running it would spend a round trip to learn what the register says.
            _verdict="skipped"
            _reason="needs_server"
        elif [ "$_list" = "true" ]; then
            # `--list` answers WHICH drills this verb would run and invokes none of them:
            # CI asks it once to build its matrix, and a listing that ran the set would cost
            # the whole run twice.
            _verdict="listed"
        else
            _t0=$(date +%s)
            if [ "$_bounded" = "true" ]; then
                _body=$(timeout "$_timeout" sh "$0" "$_c" --json 2>&1) && _rc=0 || _rc=$?
            else
                _body=$(sh "$0" "$_c" --json 2>&1) && _rc=0 || _rc=$?
            fi
            _t1=$(date +%s)
            _dur=$((_t1 - _t0))
            _n=$(printf '%s' "$_body" | sed -n 's/.*"breakers": \([0-9]*\).*/\1/p' | head -n 1)
            case "$_n" in
                ''|*[!0-9]*) _breaker="unknown" ;;
                0) _breaker="absent" ;;
                *) _breaker="present" ;;
            esac
            _why=$(printf '%s' "$_body" | sed -n 's/.*"reason": "\([a-z_]*\)".*/\1/p' | head -n 1)
            case "$_rc" in
                0) _verdict="pass" ;;
                1) _verdict="fail"; _reason="load_bearing_row_failed" ;;
                3|4) _verdict="skipped"; _reason="${_why:-environment_unanswerable}" ;;
                5) _verdict="skipped"; _reason="not_run_yet" ;;
                124|137) _verdict="fail"; _reason="timeout" ;;
                *) _verdict="fail"; _reason="unexpected_exit_${_rc}" ;;
            esac
            # A FAILURE CARRIES THE DRILL'S OWN ROWS. Without them a red CI leg says only
            # that something in the drill went false, and the person reading it has to
            # reproduce the whole fixture locally to learn which row and why.
            if [ "$_verdict" = "fail" ]; then
                # THE ROWS THAT WENT FALSE, not the whole document: a verdict line naming
                # only "something failed" sends the reader back to reproduce the fixture
                # locally, which is the friction this verb exists to remove.
                _detail=$(printf '%s' "$_body" | tr '{' '\n' \
                    | grep '"pass": false' | head -n 3 | tr '\n' ' ')
                [ -n "$_detail" ] || _detail=$(one_line "$_body")
                _detail=$(one_line "$_detail")
            fi
        fi

        case "$_verdict" in
            pass)
                if [ "$_breaker" = "present" ]; then
                    _proved=$((_proved + 1))
                else
                    _unproved=$((_unproved + 1))
                fi
                ;;
            fail) _failed=$((_failed + 1)) ;;
            *) _skipped=$((_skipped + 1)) ;;
        esac

        _r="{\"drill\": \"${_c}\", \"verdict\": \"${_verdict}\", \"reason\": \"${_reason}\", \"breaker\": \"${_breaker}\", \"kind\": \"${_kind}\", \"mission\": \"${_mission}\", \"mission_resolved\": ${_mres}, \"duration_s\": ${_dur}, \"detail\": \"$(json_escape "$_detail")\"}"
        _out="$(append_row "$_out" "$_r")"
    done

    if [ "$_list" = "true" ]; then
        # The set a caller (CI's matrix) would run, and only that: everything the register
        # classifies as runnable here. Emitted as a bare JSON array so `fromJSON` can take it.
        _names=""
        for _c in $_cmds; do
            case "$_out" in
                *"\"drill\": \"${_c}\", \"verdict\": \"skipped\","*) continue ;;
            esac
            case "$_out" in
                *"\"drill\": \"${_c}\","*)
                    if [ -z "$_names" ]; then _names="\"${_c}\""; else _names="${_names}, \"${_c}\""; fi
                    ;;
            esac
        done
        printf '[%s]\n' "$_names"
        exit 0
    fi

    _ok="true"
    _code=0
    if [ "$_failed" -gt 0 ]; then
        _ok="false"
        _code=1
    fi
    printf '{"ok": %s, "stage": "all", "register": "%s", "bounded": %s, "timeout_s": %s, "totals": {"total": %s, "proved": %s, "unproved": %s, "failed": %s, "skipped": %s}, "drills": [%s]}\n' \
        "$_ok" "$_register_state" "$_bounded" "$_timeout" \
        "$_total" "$_proved" "$_unproved" "$_failed" "$_skipped" "$_out"
    exit "$_code"
}

USAGE='{"ok": false, "reason": "usage", "detail": "loop-drill.sh seed|status|reset|verify-all [--only <drill>] [--list] [--timeout <s>]|verify-specificate <issue>|verify-implement <issue>|verify-plan [--json]|verify-status [--json]|verify-cadence [--json]|verify-planner [--json]|verify-standup [--json]|verify-moderate [--json]|verify-propose [--json]|verify-direction-health [--json]|verify-arrival [--json]|verify-residue [--json]|verify-expiry [--json]|verify-rulings [--json]|verify-succession [--json]|verify-revision [--json]|verify-merged-claim [--json]|verify-identity-handoff [--json]|verify-close [--json]|verify-catch-up [--json]|verify-corpus-boundary [--json]|verify-retire [--json]|verify-ci-retirement [--json]|verify-act-effect [--json]|verify-delivery-retry [--json]|verify-handoff-question [--json]|verify-base-health [--json]|verify-return-path [--json]|verify-reconcile [--json]|verify-checkin-delivery [--json]|verify-findings-to-work [--json]|verify-operator-pulls [--json]|verify-condition-age [--json]"}'

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
    verify-all) cmd_verify_all "$@" ;;
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
    verify-corpus-boundary) cmd_verify_corpus_boundary "$@" ;;
    verify-expiry) cmd_verify_expiry "$@" ;;
    verify-rulings) cmd_verify_rulings "$@" ;;
    verify-succession) cmd_verify_succession "$@" ;;
    verify-revision) cmd_verify_revision "$@" ;;
    verify-merged-claim) cmd_verify_merged_claim "$@" ;;
    verify-claim-race) cmd_verify_claim_race "$@" ;;
    verify-identity-handoff) cmd_verify_identity_handoff "$@" ;;
    verify-close) cmd_verify_close "$@" ;;
    verify-catch-up) cmd_verify_catch_up "$@" ;;
    verify-retire) cmd_verify_retire "$@" ;;
    verify-ci-retirement) cmd_verify_ci_retirement "$@" ;;
    verify-act-effect) cmd_verify_act_effect "$@" ;;
    verify-delivery-retry) cmd_verify_delivery_retry "$@" ;;
    verify-handoff-question) cmd_verify_handoff_question "$@" ;;
    verify-base-health) cmd_verify_base_health "$@" ;;
    verify-return-path) cmd_verify_return_path "$@" ;;
    verify-reconcile) cmd_verify_reconcile "$@" ;;
    verify-checkin-delivery) cmd_verify_checkin_delivery "$@" ;;
    verify-findings-to-work) cmd_verify_findings_to_work "$@" ;;
    verify-stage) cmd_verify_stage "$@" ;;
    verify-operator-pulls) cmd_verify_operator_pulls "$@" ;;
    verify-condition-age) cmd_verify_condition_age "$@" ;;
    verify-directed-notification) cmd_verify_directed_notification "$@" ;;
    verify-impairment) cmd_verify_impairment "$@" ;;
    *)
        echo "$USAGE" >&2
        exit 2
        ;;
esac
