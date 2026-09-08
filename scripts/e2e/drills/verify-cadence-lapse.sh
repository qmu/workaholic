cmd_verify_cadence_lapse() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _reader="${_mod}/cadence-state.sh"
    _step="${_mod}/step-cadence-lapse.sh"
    _ask="${_mod}/ask-question.sh"
    for _f in "$_reader" "$_step" "$_ask"; do
        [ -f "$_f" ] || emit_err "cadence_lapse_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    mkdir -p "${_fx}/stale" "${_fx}/fresh" "${_fx}/.workaholic"
    _field() { printf '%s' "$1" | sed -n "s/.*\"$2\": *\"\\([^\"]*\\)\".*/\\1/p" | head -1; }

    (
        cd "$_fx" \
            && git init -q . >/dev/null 2>&1 \
            && git config user.email drill@example.invalid \
            && git config user.name Drill \
            && printf 'the producer stopped here\n' > stale/2001-01-01.md \
            && git add -A >/dev/null 2>&1 \
            && GIT_AUTHOR_DATE='2001-01-01T00:00:00+0000' GIT_COMMITTER_DATE='2001-01-01T00:00:00+0000' \
               git commit -q -m 'Add the stale artifact' >/dev/null 2>&1 \
            && printf 'produced just now\n' > fresh/today.md \
            && git add -A >/dev/null 2>&1 \
            && git commit -q -m 'Add the fresh artifact' >/dev/null 2>&1
    ) || emit_err "cadence_lapse_fixture" 4 "could not build the throwaway repository"

    _all='daily|stale/*.md|1d;weekly|fresh/*.md|30d;ghost|nothing/*.md|1d'
    _lapsed_only='daily|stale/*.md|1d'
    _current_only='weekly|fresh/*.md|30d'
    _ghost_only='ghost|nothing/*.md|1d'

    # 1. THE THREE STATES, FROM ONE READER. `lapsed` carries the age and the period; the
    #    unresolvable pattern carries a NAMED reason and a NULL age — never a zero, which reads
    #    as *produced this second*, and never `lapsed`.
    _r=$(WORKAHOLIC_CADENCES="$_all" sh "$_reader" --root "$_fx" 2>&1 || true)
    _ok_states=true
    printf '%s' "$_r" | jq -e '[.cadences[] | select(.name=="daily" and .state=="lapsed" and .age_hours > 0 and .period_hours == 24)] | length == 1' >/dev/null 2>&1 || _ok_states=false
    printf '%s' "$_r" | jq -e '[.cadences[] | select(.name=="weekly" and .state=="current")] | length == 1' >/dev/null 2>&1 || _ok_states=false
    printf '%s' "$_r" | jq -e '[.cadences[] | select(.name=="ghost" and .state=="unreadable" and .age_hours == null and (.reason | length > 0))] | length == 1' >/dev/null 2>&1 || _ok_states=false
    if [ "$_ok_states" = "true" ]; then
        add_row "cadence_reader_answers_three_states" true "lapsed with its age and period, current, and unreadable with a named reason and a null age" load
    else
        add_row "cadence_reader_answers_three_states" false "the reader did not answer all three states: $(one_line "$_r")" load
    fi

    # 2. A REPOSITORY DECLARING NOTHING IS A REAL ANSWER, not a degradation — and carries NO
    #    `readable` field, so a consumer not taught the term is unaffected.
    _none=$(WORKAHOLIC_CADENCES='' sh "$_reader" --root "$_fx" 2>&1; printf ' exit=%s' "$?")
    case "$_none" in
        *'"empty_reason": "no_cadence_declared"'*' exit=0')
            case "$_none" in
                *readable*) add_row "cadence_absent_is_not_degraded" false "an undeclared repository emitted a readable field: $(one_line "$_none")" load ;;
                *) add_row "cadence_absent_is_not_degraded" true "no declaration reads an empty set with a named reason, exit 0, no readable field" load ;;
            esac ;;
        *) add_row "cadence_absent_is_not_degraded" false "expected empty_reason no_cadence_declared and exit 0, got: $(one_line "$_none")" load ;;
    esac

    # 3. THE STEP: a lapse becomes one keyed candidate and an event; a current cadence asks
    #    nobody and renders no root line; an unreadable read is named and asks nobody; an
    #    undeclared repository is `skipped`, which is deliberately not impairment.
    _s_lapsed=$(WORKAHOLIC_CADENCES="$_lapsed_only" sh "$_step" --tick 20260831-130000 --root "$_fx" 2>&1 || true)
    if printf '%s' "$_s_lapsed" | jq -e '(.needs_agent | length == 1) and (.needs_agent[0].lapsed | length == 1) and (.needs_agent[0].lapsed[0].key == "cadence-lapsed:daily") and (.event | length > 0)' >/dev/null 2>&1; then
        add_row "cadence_lapse_reaches_the_checkin" true "a lapsed cadence is one candidate keyed cadence-lapsed:daily, with an event" load
    else
        add_row "cadence_lapse_reaches_the_checkin" false "the lapse did not reach the check-in: $(one_line "$_s_lapsed")" load
    fi

    _s_current=$(WORKAHOLIC_CADENCES="$_current_only" sh "$_step" --tick 20260831-130000 --root "$_fx" 2>&1 || true)
    if printf '%s' "$_s_current" | jq -e '(.status == "ok") and (.needs_agent | length == 0) and (.event == "")' >/dev/null 2>&1; then
        add_row "cadence_current_asks_nobody" true "a current cadence supplies no candidate and no event, so the root renders no line" load
    else
        add_row "cadence_current_asks_nobody" false "a current cadence was not silent: $(one_line "$_s_current")" load
    fi

    _s_ghost=$(WORKAHOLIC_CADENCES="$_ghost_only" sh "$_step" --tick 20260831-130000 --root "$_fx" 2>&1 || true)
    if printf '%s' "$_s_ghost" | jq -e '(.status == "degraded") and (.reason == "cadence_unreadable") and (.needs_agent | length == 0)' >/dev/null 2>&1; then
        add_row "cadence_unreadable_is_named" true "an unreadable read is degraded by name and asks nobody" load
    else
        add_row "cadence_unreadable_is_named" false "an unreadable read was not named, or asked somebody: $(one_line "$_s_ghost")" load
    fi

    _s_none=$(WORKAHOLIC_CADENCES='' sh "$_step" --tick 20260831-130000 --root "$_fx" 2>&1 || true)
    if printf '%s' "$_s_none" | jq -e '(.status == "skipped") and (.reason == "no_cadence_declared") and (.needs_agent | length == 0) and (.event == "")' >/dev/null 2>&1; then
        add_row "cadence_undeclared_is_byte_identical" true "a repository declaring nothing is skipped by name, asks nobody and renders no line" load
    else
        add_row "cadence_undeclared_is_byte_identical" false "an undeclared repository was not skipped by name: $(one_line "$_s_none")" load
    fi

    # 4. ONE LAPSE COSTS ONE QUESTION, however many ticks see it — the EXISTING gate, called
    #    with the key the step composes. `ask-question.sh` gains nothing and is not modified.
    _g1=$(sh "$_ask" --tick 20260831-130000 --key 'cadence-lapsed:daily' --root "$_fx" --hour 10 --weekday 3 2>&1 || true)
    sh "$_ask" --record-ask --tick 20260831-130000 --key 'cadence-lapsed:daily' --root "$_fx" --summary 'asked about a lapsed cadence' >/dev/null 2>&1 || true
    _g2=$(sh "$_ask" --tick 20260831-140000 --key 'cadence-lapsed:daily' --root "$_fx" --hour 10 --weekday 3 2>&1 || true)
    case "${_g1}|${_g2}" in
        *'"ask": true'*'|'*'"reason": "already_asked"'*)
            add_row "cadence_asked_once" true "the second tick is refused already_asked, so one lapse costs one question" load ;;
        *) add_row "cadence_asked_once" false "expected ask then already_asked, got: $(one_line "$_g1") / $(one_line "$_g2")" load ;;
    esac

    # 5. THE STEP WRITES NOTHING BUT ITS OWN LOG LINE, which `run.sh` writes — so a run of the
    #    step alone must leave even the fixture's own tree untouched.
    _fx_before=$(cd "$_fx" && git status --porcelain 2>/dev/null | grep -v '^?? .workaholic/moderations' | sort)
    WORKAHOLIC_CADENCES="$_all" sh "$_step" --tick 20260831-150000 --root "$_fx" >/dev/null 2>&1 || true
    _fx_after=$(cd "$_fx" && git status --porcelain 2>/dev/null | grep -v '^?? .workaholic/moderations' | sort)
    if [ "$_fx_before" = "$_fx_after" ]; then
        add_row "cadence_step_writes_nothing" true "the step left the fixture's tree byte-identical" load
    else
        add_row "cadence_step_writes_nothing" false "the step wrote into the tree it read" load
    fi

    # 6. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. Wire the reader so an unresolvable
    #    pattern answers `lapsed`, and the step must hand over a candidate it must never hand
    #    over. A breaker satisfied by keeping the JSON shape proves nothing.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${_mod}/." "$_broken/"
    sed 's|unreadable null '"''"' no_matching_artifact|lapsed 9999 "2001-01-01T00:00:00+00:00" '"''"'|' \
        "$_reader" > "${_broken}/cadence-state.sh"
    chmod +x "${_broken}/cadence-state.sh" "${_broken}/step-cadence-lapse.sh"
    _b=$(WORKAHOLIC_CADENCES="$_ghost_only" sh "${_broken}/step-cadence-lapse.sh" --tick 20260831-130000 --root "$_fx" 2>&1 || true)
    if printf '%s' "$_b" | jq -e '(.needs_agent | length) > 0' >/dev/null 2>&1; then
        add_row "cadence_breaker" true "with an unresolvable pattern wired to lapsed the step asks about a producer that may be fine (this drill can fail)" breaker
    else
        add_row "cadence_breaker" false "the breaker did not break: an unreadable pattern wired to lapsed still asked nobody ($(one_line "$_b")), so row 3 proves nothing" breaker
    fi

    # 7. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "cadence_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "cadence_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "cadence-lapse" 0 "fail" 1
    fi
    emit_verdict "cadence-lapse" 0 "pass" 0
}

# ------------------------------------------------------- verify-runner-advance
# THE RUNNER THAT REPORTS `running` FOREVER (2026-09-06, mission
# `see-a-frozen-runner-and-give-back-its-slot`).
#
# `ListAgents` says `running` for both "executing a tool" and "blocked forever on a permission
# dialog nobody will answer". Measured 2026-09-06: `implement-10` made its last tool call at
# 05:42:49 UTC and was reported `running` by nine consecutive calls until the parent stopped it
# by hand 38m29s later, holding a fan-out slot the whole time.
#
# WHAT IS DRILLED IS THE READER AND THE RULE IT IS BOUND BY, not the freeze. Driving a real
# subagent into a permission dialog is not something a hermetic drill can do, and asserting a
# fixture of one would prove nothing. What IS mechanical is the reading: which evidence
# separates the two states, and — far more important — that every reading the script cannot
# make comes back `unreadable` and frees nothing.
#
# HERMETIC. The fixture is a throwaway directory tree with controlled mtimes. No git, no
# network, no `gh`, no Slack, no credential — the reader makes no network call by contract, so
# a drill that needed one would be drilling the wrong thing.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR, not the return shape: wire the reader so a
# claim whose files cannot be read counts as flat rather than unreadable, and a runner that
# might be working must then be reported `not_advancing` and have its slot taken. A wrong
# `not_advancing` is the one way this reading can do harm — it spawns a second runner against a
# working one — so that is the regression worth a row that has to fail.
