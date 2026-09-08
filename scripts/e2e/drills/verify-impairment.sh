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
        # A WORKING HOUR IS NAMED (2026-09-01): the root is held by the same window as the
        # questions, and a drill that read the wall clock could only pass during office hours.
        sh "$_render" --tick "$1" --root "$_fx" --questions "$3" --hour 10 --weekday 3 < "$2" 2>&1 || true
    }

    _logtick 20260819-084500 ok 'swept, 0 filed' ok 'no conflicts'
    _logtick 20260819-094500 ok 'swept, 0 filed' ok 'no conflicts'

    # 1. AN IMPAIRED TICK WITH A QUESTION SAYS, IN WORDS, WHAT IT COULD NOT READ. This is the
    #    whole ask, on the ordinary path.
    #
    #    WHAT IS MATCHED IS THE STEP'S OWN SUMMARY, not its id (2026-09-01). The line read
    #    `⚠️ inbound-sweep — degraded: no_slack_transport` -- a step id, a status word and a
    #    reason word -- and the developer's answer was *なんのことを言っているのかわからない*.
    #    The summary is the sentence the log has carried all along, so a person reads what could
    #    not be read and what follows from it; asserting the id here would pin the shape the
    #    change removed.
    _t2q=$(_render_at 20260819-104500 "${_tmp}/impaired.json" 1)
    _rt2q=$(_root_text "$_t2q")
    case "$_rt2q" in
        *'no Slack transport'*'could not read pull requests'*)
            add_row "impairment_is_named" true "the root says in words what each impaired step could not read" load ;;
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
                *'no Slack transport'*'could not read pull requests'*)
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
    _bq=$(sh "${_broken}/render-tick-post.sh" --tick 20260819-104500 --root "$_fx" --hour 10 --weekday 3 --questions 1 < "${_tmp}/impaired.json" 2>&1 || true)
    _b0=$(sh "${_broken}/render-tick-post.sh" --tick 20260819-104500 --root "$_fx" --hour 10 --weekday 3 --questions 0 < "${_tmp}/impaired.json" 2>&1 || true)
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
