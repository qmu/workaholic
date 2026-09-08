cmd_verify_blocked_tick() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _run="${_mod}/run.sh"
    _step="${_mod}/step-blocked-tick.sh"
    _log="${_mod}/log-append.sh"
    _ask="${_mod}/ask-question.sh"
    for _f in "$_run" "$_step" "$_log" "$_ask"; do
        [ -f "$_f" ] || emit_err "blocked_tick_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _field() { printf '%s' "$1" | sed -n "s/.*\"$2\": *\"\\([^\"]*\\)\".*/\\1/p" | head -1; }

    # A checkout with a bare local origin, ready for the publish tree the persist opens.
    _seed() {
        _b="${1}/origin.git"; _c="${1}/clone"
        git init -q --bare -b main "$_b" >/dev/null 2>&1
        git init -q -b main "$_c" >/dev/null 2>&1
        (
            cd "$_c" \
                && git config user.email drill@example.invalid \
                && git config user.name Drill \
                && mkdir -p .workaholic/moderations \
                && printf 'seed\n' > .workaholic/README.md \
                && git add -A >/dev/null 2>&1 \
                && git commit -q -m 'Seed the tree' >/dev/null 2>&1 \
                && git remote add origin "$_b" \
                && git push -q -u origin main >/dev/null 2>&1
        )
    }

    # 1. THE OPENING REACHES THE BASE. A tick stopped after its first step leaves a section
    #    on the base carrying that step and nothing else — which is the whole premise the
    #    reading rests on.
    _fx="${_tmp}/live"
    mkdir -p "$_fx"
    _seed "$_fx" || emit_err "blocked_tick_fixture" 4 "could not build the throwaway repository"
    _day=$(date -u +%Y-%m-%d)
    _tick="$(date -u +%Y%m%d)-100000"
    _r=$(sh "$_run" --root "${_fx}/clone" --tick "$_tick" --only open-log 2>&1 || true)
    # THE OPENING IS WRITTEN WHERE IT IS READ (2026-09-03). It used to be pushed to an orphan log
    # branch by an opening persist, because a routine-fired tick's container was discarded. That
    # branch is retired and must not be reintroduced (`persist-log.sh`'s header); the log is
    # git-ignored and stays in the checkout, which is a checkout that persists between ticks. What
    # this drill asserts is unchanged -- a tick stopped after its first step still leaves a trace a
    # later tick can read -- only the place it looks moved, from a remote ref to the file itself.
    _base=$(cat "${_fx}/clone/.workaholic/moderations/${_day}.md" 2>/dev/null || true)
    case "${_base}" in
        *"## ${_tick}"*)
            case "$_base" in
                *'- `open-log`'*)
                    add_row "blocked_tick_opening_is_recorded" true "a tick stopped after its first step leaves its opening in the log" load ;;
                *) add_row "blocked_tick_opening_is_recorded" false "the section landed with no open-log line: $(one_line "$_base")" load ;;
            esac ;;
        *) add_row "blocked_tick_opening_is_recorded" false "the opening was not recorded: $(one_line "$_r")" load ;;
    esac

    # 2. THE READING, over a log written by the real writer: the TICK BEFORE LAST opened and
    #    never closed, so it is named — and a complete one is silent.
    _lx="${_tmp}/logs"
    mkdir -p "${_lx}/.workaholic"
    _A() { sh "$_log" --root "$_lx" --tick "$1" --step "$2" --status ok --summary 'drill' >/dev/null 2>&1 || true; }
    _A 20260831-100000 open-log
    _A 20260831-110000 open-log
    _A 20260831-110000 human-checkin
    _A 20260831-120000 open-log
    _s=$(sh "$_step" --tick 20260831-120000 --root "$_lx" 2>&1 || true)
    if printf '%s' "$_s" | jq -e '(.needs_agent | length == 1) and (.needs_agent[0].key == "blocked-tick:20260831-100000") and (.event | length > 0)' >/dev/null 2>&1; then
        add_row "blocked_tick_is_named" true "the tick before last opened and never closed, and is named once with its own key" load
    else
        add_row "blocked_tick_is_named" false "the stopped tick was not named: $(one_line "$_s")" load
    fi

    _A 20260831-100000 human-checkin
    _h=$(sh "$_step" --tick 20260831-120000 --root "$_lx" 2>&1 || true)
    if printf '%s' "$_h" | jq -e '(.status == "ok") and (.needs_agent | length == 0) and (.event == "")' >/dev/null 2>&1; then
        add_row "blocked_tick_healthy_is_silent" true "a complete previous section produces no question and no event" load
    else
        add_row "blocked_tick_healthy_is_silent" false "a healthy tick was not silent: $(one_line "$_h")" load
    fi

    # 2b. A COORDINATOR-ONLY SECTION IS NOT A MODERATE TICK (2026-09-07, ticket `20260907063154`).
    #     `/infinite-development` records each subagent finish as `loop-finish-<name>` under the
    #     COORDINATOR's tick id, into this same file, every five minutes — so a section holding
    #     nothing but such a line is the ordinary previous section. Taken as "the tick before last"
    #     it has `opened == 0`, which reaches the healthy branch, and the step whose whole job is to
    #     notice a stopped tick reports `the tick before last opened and closed` over one that
    #     stopped. MEASURED on the live log, verbatim: `blocked-tick: ok — the tick before last
    #     opened and closed; 1 step(s) recorded`, over a section holding one `loop-finish-implement`
    #     line. The fixture is built so the wrong answer is SILENT and the right one speaks.
    _ox="${_tmp}/owner"
    mkdir -p "${_ox}/.workaholic"
    _AO() { sh "$_log" --root "$_ox" --tick "$1" --step "$2" --status ok --summary 'drill' >/dev/null 2>&1 || true; }
    _AO 20260831-100000 open-log                   # the moderate tick that STOPPED
    _AO 20260831-105000 loop-finish-implement      # the coordinator's own section, alone
    _AO 20260831-110000 open-log                   # a healthy moderate tick
    _AO 20260831-110000 human-checkin
    _o=$(sh "$_step" --tick 20260831-120000 --root "$_ox" 2>&1 || true)
    if printf '%s' "$_o" | jq -e '(.needs_agent | length == 1) and (.needs_agent[0].key == "blocked-tick:20260831-100000")' >/dev/null 2>&1; then
        add_row "blocked_tick_skips_a_coordinator_section" true "a loop-finish-only section is stepped over, and the moderate tick that stopped is the one named" load
    else
        add_row "blocked_tick_skips_a_coordinator_section" false "the coordinator's section was read as the tick before last: $(one_line "$_o")" load
    fi

    #     ...AND ITS BREAKER, WRITTEN AGAINST THE BEHAVIOUR. Give the step a `log-read.sh` whose
    #     `--owner` is accepted and ignored — which is exactly what the reader did before this
    #     ticket — and the row above must go silent. A breaker satisfied by keeping the JSON shape,
    #     or by deleting the reader, would prove nothing about the scoping.
    _obroken="${_tmp}/owner-broken"
    mkdir -p "$_obroken"
    cp -R "${_mod}/." "$_obroken/"
    sed 's|if (want_owner != "all" \&\& owner_of(step) != want_owner) next|if (want_owner == "never-an-owner") next|' \
        "${_mod}/log-read.sh" > "${_obroken}/log-read.sh"
    chmod +x "${_obroken}/log-read.sh"
    _ob=$(sh "${_obroken}/step-blocked-tick.sh" --tick 20260831-120000 --root "$_ox" 2>&1 || true)
    if printf '%s' "$_ob" | jq -e '.needs_agent | length == 0' >/dev/null 2>&1; then
        add_row "blocked_tick_owner_breaker" true "with the owner filter defeated the stopped tick goes unreported (this drill can fail)" breaker
    else
        add_row "blocked_tick_owner_breaker" false "the breaker did not break: the stopped tick was still named with the owner filter defeated ($(one_line "$_ob")), so the row above proves nothing" breaker
    fi

    #     AND THE PROPOSE ARM STILL SEES ITS OWN LINES. It reads another owner DELIBERATELY, which
    #     is why the owner is a small named set rather than a boolean: *not moderate* is not one
    #     class, and a boolean would have silently broken this arm — the exact failure this ticket
    #     exists to stop repeating.
    #     Two propose sections, because this arm reads the tick BEFORE LAST on its own subject too:
    #     an older one that stopped, and a newer complete one behind it.
    _AO 20260831-095000 propose-open
    _AO 20260831-115000 propose-open
    _AO 20260831-115000 propose-close
    _p=$(sh "$_step" --tick 20260831-120000 --root "$_ox" 2>&1 || true)
    if printf '%s' "$_p" | jq -e '[.needs_agent[] | select(.key == "blocked-tick:propose:20260831-095000")] | length == 1' >/dev/null 2>&1; then
        add_row "blocked_tick_propose_arm_reads_its_own_owner" true "the propose arm still finds propose-open/propose-close under the moderation default" load
    else
        add_row "blocked_tick_propose_arm_reads_its_own_owner" false "the propose arm lost its lines to the moderation default: $(one_line "$_p")" load
    fi

    # 3. ONE QUESTION PER STOPPED HOUR, through the EXISTING gate. `ask-question.sh` gains
    #    nothing: the key the step composes is handed to it unchanged.
    _g1=$(sh "$_ask" --tick 20260831-120000 --key 'blocked-tick:20260831-100000' --root "$_lx" --hour 10 --weekday 3 2>&1 || true)
    sh "$_ask" --record-ask --tick 20260831-120000 --key 'blocked-tick:20260831-100000' --root "$_lx" --summary 'asked about a stopped tick' >/dev/null 2>&1 || true
    _g2=$(sh "$_ask" --tick 20260831-130000 --key 'blocked-tick:20260831-100000' --root "$_lx" --hour 10 --weekday 3 2>&1 || true)
    case "${_g1}|${_g2}" in
        *'"ask": true'*'|'*'"reason": "already_asked"'*)
            add_row "blocked_tick_asked_once" true "the second tick is refused already_asked, so a stopped hour costs one question" load ;;
        *) add_row "blocked_tick_asked_once" false "expected ask then already_asked, got: $(one_line "$_g1") / $(one_line "$_g2")" load ;;
    esac

    # 4. A LOG THAT EXISTS AND CANNOT BE READ IS NAMED, and asks nobody — never rendered as a
    #    quiet hour, which is the exact collapse this whole mission removes one level up.
    #    A reader that answers something this step cannot parse is the reachable instance:
    #    `log-read.sh` itself answers `read: false` only for a missing area, which is the
    #    healthy `skipped` below rather than a degradation.
    _unread="${_tmp}/unreadable"
    mkdir -p "$_unread"
    cp -R "${_mod}/." "$_unread/"
    printf '#!/bin/sh\nprintf "not json at all\\n"\n' > "${_unread}/log-read.sh"
    chmod +x "${_unread}/log-read.sh"
    _d=$(sh "${_unread}/step-blocked-tick.sh" --tick 20260831-120000 --root "$_lx" 2>&1 || true)
    if printf '%s' "$_d" | jq -e '(.status == "degraded") and (.reason | length > 0) and (.needs_agent | length == 0)' >/dev/null 2>&1; then
        add_row "blocked_tick_unreadable_is_named" true "an unreadable log is degraded by name ($(_field "$_d" reason)) and asks nobody" load
    else
        add_row "blocked_tick_unreadable_is_named" false "an unreadable log was not named, or asked somebody: $(one_line "$_d")" load
    fi

    #    ...and a repository that keeps NO log is `skipped` by name, not degraded. A step
    #    declining to run for a stated, healthy reason did not fail to see, and the root's
    #    impairment clause is deliberately built on that distinction.
    _none=$(sh "$_step" --tick 20260831-120000 --root "${_tmp}/absent" 2>&1 || true)
    if printf '%s' "$_none" | jq -e '(.status == "skipped") and (.reason == "no_log_area") and (.needs_agent | length == 0) and (.event == "")' >/dev/null 2>&1; then
        add_row "blocked_tick_no_log_is_skipped" true "a repository with no tick log is skipped by name, never degraded" load
    else
        add_row "blocked_tick_no_log_is_skipped" false "a missing log area was not skipped by name: $(one_line "$_none")" load
    fi

    # 5. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. Disable the opening persist and the
    #    base carries nothing for a tick that stopped after its first step — so row 1's premise
    #    is gone and there is nothing for the reading to notice.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${_mod}/." "$_broken/"
    sed 's|if \[ "$step" = open-log \] && \[ "$DO_LOG" -eq 1 \]|if [ "$step" = never-a-step ] \&\& [ "$DO_LOG" -eq 1 ]|' \
        "$_run" > "${_broken}/run.sh"
    chmod +x "${_broken}/run.sh"
    _bx="${_tmp}/breaker"
    mkdir -p "$_bx"
    _seed "$_bx" || true
    _btick="$(date -u +%Y%m%d)-140000"
    sh "${_broken}/run.sh" --root "${_bx}/clone" --tick "$_btick" --only open-log >/dev/null 2>&1 || true
    _bbase=$(git -C "${_bx}/origin.git" show "main:.workaholic/moderations/${_day}.md" 2>/dev/null || true)
    case "$_bbase" in
        *"## ${_btick}"*)
            add_row "blocked_tick_breaker" false "the breaker did not break: the opening reached the base with the opening persist disabled ($(one_line "$_bbase")), so row 1 proves nothing" breaker ;;
        *)
            add_row "blocked_tick_breaker" true "with the opening persist disabled a stopped tick leaves nothing on the base (this drill can fail)" breaker ;;
    esac

    # 6. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "blocked_tick_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "blocked_tick_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "blocked-tick" 0 "fail" 1
    fi
    emit_verdict "blocked-tick" 0 "pass" 0
}

# ------------------------------------------------------- verify-cadence-lapse
# A PERIODIC ARTIFACT THAT STOPPED BEING PRODUCED (2026-08-31, mission
# `notice-a-periodic-artifact-that-stopped-being-produced`).
#
# Every other step of the tick is driven by an object that EXISTS, so a producer that dies
# produces nothing and no step has anything to find — measured, a daily record stopped for
# four days while hourly ticks ran throughout and none reported it. A reading nothing proves
# is a reading that quietly stops working, which is that same failure one level up, so the
# whole chain is drilled here: declaration → reader → step → question.
#
# HERMETIC. The fixture is a throwaway git repository this function builds; the declaration is
# an environment variable it sets; the gate is exercised against the fixture's own tick log. No
# network, no `gh`, no Slack, no `origin`, no credential.
#
# THE FIXTURE'S VERDICTS DO NOT DEPEND ON THE DAY THE DRILL RUNS. The lapsed cadence's commit
# is dated 2001 and measured against a one-day period, and the current one is committed now and
# measured against a thirty-day period — so both answers hold whatever the run clock says. The
# ticket asked for controlled mtimes; the reader deliberately reads COMMIT time instead (a
# routine's container is a fresh clone, and git stamps every checked-out file with the
# checkout's own time), so the control is `GIT_COMMITTER_DATE` rather than `touch -t`.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR, not the return shape: wire the reader so an
# unresolvable pattern answers `lapsed` instead of `unreadable`, and the step must then hand
# over a candidate it must never hand over. A wrong `lapsed` sends a person after a producer
# that is working, which is the one way this reading can do harm, so that is the regression
# worth a row that has to fail.
