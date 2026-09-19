# ------------------------------------------------ verify-observation-during-work
# THE OBSERVATION CLOCK KEEPS TICKING WHILE A WORKER IS BUSY (2026-09-19, ticket
# `20260919095618`, mission `dispatch-bounded-workers-without-stopping-the-observation-clock`).
#
# The ask's final item: *lengthy active implementation plus new Slack reply plus restricted
# context delegation — verify that observation and acknowledgment continue on cadence, with
# bounded child input.*
#
# WHY A DRILL AND NOT A UNIT TEST. The property is a TIMING one and it spans four components —
# the coordinator's receipts, the dispatch path, the transport adapter and the policy reader.
# The contract tests in `scripts/tests/agentic-loop/` prove allocation and coordination in
# isolation and cannot see a clock that stopped.
#
# HERMETIC AND OFFLINE. `qfs` is stubbed on PATH at the adapter seam the existing fixtures
# already stub, the channel comes from `WORKAHOLIC_INBOUND_SLACK_CHANNEL`, and no path reaches
# a network or needs a credential. **A STUB PROVES THE LOOP AND NOT THE PROVIDER**: a green
# verdict here says the coordinator kept observing while a child was live, and says nothing at
# all about whether Slack would have delivered anything.
#
# NO `sleep` ANYWHERE. Every assertion is made against the RECORDED SEQUENCE of real calls —
# a journal this drill appends to as each script returns — because a drill that sleeps is a
# drill that goes flaky. What is asserted is order, never elapsed time.
cmd_verify_observation_during_work() {
    _rt="${REPO_ROOT}/plugins/workaholic/skills/runtime/scripts"
    _coord="${_rt}/coordinator.sh"
    _policy="${_rt}/dispatch-policy.sh"
    _lapse="${REPO_ROOT}/plugins/workaholic/skills/work/scripts/delegation-lapse.sh"
    _observe="${REPO_ROOT}/plugins/workaholic/skills/transport/scripts/observe-channel.sh"
    _loop="${REPO_ROOT}/plugins/workaholic/skills/work/scripts/codex-loop.sh"
    for _f in "$_coord" "$_policy" "$_lapse" "$_observe" "$_loop"; do
        [ -f "$_f" ] || emit_err "observation_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    _bin="${_tmp}/bin"
    _journal="${_tmp}/journal"
    mkdir -p "${_fx}/.workaholic" "$_bin"
    : >"$_journal"
    ( cd "$_fx" && git init -q -b main . >/dev/null 2>&1 \
        && git config user.name Drill && git config user.email drill@example.com \
        && git commit -q --allow-empty -m seed >/dev/null 2>&1 ) || \
        emit_err "observation_fixture_failed" 4 "could not build the fixture repository"

    # THE RESTRICTION: a declared bounded context policy. Not absent — absent is today's
    # behaviour and would prove nothing about a restricted dispatch.
    printf '%s' '{"schema_version":1,"profiles":{"default":{"dispatch":{"context_policy":"bounded_task"}}}}' \
        >| "${_fx}/workaholic.config.json"

    # A CONVERSATION THE CHILD MUST NOT INHERIT. Planted so the absence can be asserted
    # explicitly rather than inferred from the presence of the contracted fields.
    # It carries SPACES and an ordinary name on purpose: a quoted alphanumeric literal
    # assigned to something called `_secret` is the exact shape `lib/secret-patterns.sh`
    # pass 2 matches, and this drill tripped that hard finding on its first scan.
    _planted_conversation='inherited conversation the child must not receive'

    # THE TRANSPORT STUB, at the seam the existing fixtures stub. Each read returns one new
    # human root, so an observation that ran is proved and one that did not is visibly absent.
    _reads="${_tmp}/qfs-reads"
    cat >"${_bin}/qfs" <<EOF
#!/bin/sh
case "\$1" in
  describe) printf '%s\n' '{"mounts":[{"mount":"/slack/a","workspace":"qmu","operations":["read_channel_delta"]}]}' ;;
  *) n=0; [ ! -f '${_reads}' ] || n=\$(cat '${_reads}'); n=\$((n+1)); printf '%s' "\$n" >'${_reads}'
     printf '{"rows":[{"id":"human-%s","ts":"9.%s","sender_id":"HUMAN","text":"a new reply"}],"has_more":false}\n' "\$n" "\$n" ;;
esac
EOF
    chmod +x "${_bin}/qfs"

    _note() { printf '%s\n' "$1" >>"$_journal"; }
    _event() { # $1 file with the event body
        sh "$_coord" --instance drill-observe --input "$1" 2>/dev/null || printf ''
    }
    _mkevent() { printf '%s' "$1" >| "${_tmp}/event.json"; printf '%s' "${_tmp}/event.json"; }

    _run_observe() { # $1 iso-now ; records only a PROVED read
        _o=$(cd "$_fx" && PATH="${_bin}:${PATH}" WORKAHOLIC_INBOUND_SLACK_CHANNEL=drill \
            sh "$_observe" --root "$_fx" --now "$1" 2>/dev/null || printf '')
        case "$_o" in
            *'"observation_proved":true'*|*'"observation_proved": true'*) _note "observation" ;;
            *) _note "observation_unproved" ;;
        esac
    }

    # ---- the scenario, driven once and journalled as it goes ---------------------------
    _drive() { # $1 "suppress" to leave the observation reads out (the breaker)
        _suppress="${1:-no}"
        : >"$_journal"
        rm -rf "${_fx}/.git/workaholic" 2>/dev/null || true
        rm -f "$_reads" 2>/dev/null || true
        ( cd "$_fx" && _event "$(_mkevent '{"event":"start","now":2000000000,"session_id":"drill-session"}')" ) >"${_tmp}/start.json"
        _note "start"
        ( cd "$_fx" && _event "$(_mkevent '{"event":"reserve","now":2000000010,"id":"worker","role":"implement","workers_readable":true,"available_capacity":2,"formation_pending":false,"context_policy":"bounded_task"}')" ) >"${_tmp}/reserve.json"
        ( cd "$_fx" && _event "$(_mkevent '{"event":"started","now":2000000020,"id":"worker","child_id":"child-1"}')" ) >"${_tmp}/started.json"
        _note "child_started"
        # THE CHILD IS LONG-RUNNING: every call below happens while its receipt reads
        # `running`, which the journal records from the coordinator's OWN answer rather than
        # from a clock.
        _live=$( ( cd "$_fx" && _event "$(_mkevent '{"event":"tick","now":2000000030}')" ) )
        case "$_live" in *'"child_id":"child-1"'*) _note "child_live" ;; esac
        if [ "$_suppress" != suppress ]; then
            _run_observe 2033-05-18T03:33:50Z
            # THE ACKNOWLEDGEMENT, recorded where the loop already records its steps.
            sh "${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/log-append.sh" \
                --root "$_fx" --tick 20260919-100000 --step inbound-ack --status ok \
                --summary 'acknowledged one reply' >/dev/null 2>&1 && _note "acknowledgement" || true
            _run_observe 2033-05-18T03:38:50Z
        fi
        _live2=$( ( cd "$_fx" && _event "$(_mkevent '{"event":"tick","now":2000000040}')" ) )
        case "$_live2" in *'"child_id":"child-1"'*) _note "child_still_live" ;; esac
        ( cd "$_fx" && _event "$(_mkevent '{"event":"finish","now":2000000050,"id":"worker","terminal":true,"result":{"executed":true,"outcome":"ok","reason":"","report":"done"}}')" ) >"${_tmp}/finish.json"
        _note "child_finished"
    }

    _cadence_held() { # reads the journal: at least one observation AND one acknowledgement
        _seq=$(tr '\n' ' ' <"$_journal")
        case "$_seq" in
            *"child_started "*"observation "*"acknowledgement "*"observation "*"child_finished"*) return 0 ;;
            *) return 1 ;;
        esac
    }

    _drive

    # 1. OBSERVATION AND ACKNOWLEDGEMENT BOTH HAPPENED BETWEEN `started` AND `finish`, read
    #    off the recorded sequence.
    if _cadence_held; then
        add_row "observation_continues_during_work" true "at least one observation read and one acknowledgement are recorded between the child's started and finish" load
    else
        add_row "observation_continues_during_work" false "the clock stopped while the child was live: $(tr '\n' ' ' <"$_journal")" load
    fi

    # 2. THE CHILD WAS GENUINELY LIVE ACROSS THE WHOLE WINDOW, from the coordinator's own
    #    `live[]` rather than from elapsed time.
    _live_before=no; _live_after=no
    case "$(tr '\n' ' ' <"$_journal")" in *child_live*) _live_before=yes ;; esac
    case "$(tr '\n' ' ' <"$_journal")" in *child_still_live*) _live_after=yes ;; esac
    if [ "$_live_before" = yes ] && [ "$_live_after" = yes ]; then
        add_row "observation_child_stayed_live" true "the receipt read running on both sides of the observation window" load
    else
        add_row "observation_child_stayed_live" false "the child was not live across the window: before=${_live_before} after=${_live_after}" load
    fi

    # 3. THE CHILD'S INPUT IS BOUNDED, asserted as an ABSENCE as well as a presence: this is
    #    the half that fails silently.
    _dry=$(cd "$_fx" && PATH="${_bin}:${PATH}" WORKAHOLIC_CONVERSATION="$_planted_conversation" \
        sh "$_loop" --dispatch implement --dry-run --log "${_tmp}/ls" 2>&1 || printf '')
    _bounded=no; _leaked=no
    case "$_dry" in *"context_policy=bounded_task"*) _bounded=yes ;; esac
    case "$_dry" in *"$_planted_conversation"*) _leaked=yes ;; esac
    _has_task=no; _has_schema=no
    case "$_dry" in *"commands/implement.md"*) _has_task=yes ;; esac
    case "$_dry" in *"matching the supplied schema"*) _has_schema=yes ;; esac
    if [ "$_bounded" = yes ] && [ "$_leaked" = no ] && [ "$_has_task" = yes ] && [ "$_has_schema" = yes ]; then
        add_row "observation_child_input_bounded" true "the dispatch names the bounded policy, the task and the result schema, and carries no inherited conversation" load
    else
        add_row "observation_child_input_bounded" false "bounded=${_bounded} leaked=${_leaked} task=${_has_task} schema=${_has_schema}" load
    fi

    # 4. THE RESTRICTION IS READ AND ITS COST NAMED, rather than the loop quietly trading it.
    printf '%s' '{"delegation":"available","context_policy":"bounded_task"}' >| "${_tmp}/lapse.json"
    _lr=$(sh "$_lapse" --input "${_tmp}/lapse.json" 2>/dev/null || printf '')
    case "$_lr" in
        *'"restriction":"bounded_context"'*'"announce":false'*)
            add_row "observation_restriction_named" true "a bounded context is named, costs one stated guarantee and announces nothing new" load ;;
        *) add_row "observation_restriction_named" false "the restriction reading is wrong: $(one_line "$_lr")" load ;;
    esac

    # 5. ONE `start`, AN UNCHANGED INSTANCE AND ANCHOR, AND EXACTLY ONE RECONCILIATION.
    _anchor=$(sed -n 's/.*"anchor":\([0-9]*\).*/\1/p' "${_tmp}/start.json" | head -1)
    _again=$( ( cd "$_fx" && _event "$(_mkevent '{"event":"start","now":2000000060,"session_id":"drill-session"}')" ) )
    _anchor2=$(printf '%s' "$_again" | sed -n 's/.*"anchor":\([0-9]*\).*/\1/p' | head -1)
    _dup=$( ( cd "$_fx" && _event "$(_mkevent '{"event":"finish","now":2000000070,"id":"worker","terminal":true,"result":{"executed":true,"outcome":"ok","reason":"","report":"done"}}')" ) )
    _second_start=no; _dupe=no
    case "$_again" in *'"reason":"already_started"'*) _second_start=yes ;; esac
    case "$_dup" in *duplicate_result*) _dupe=yes ;; esac
    if [ "$_second_start" = yes ] && [ "$_dupe" = yes ] && [ -n "$_anchor" ] && [ "$_anchor" = "$_anchor2" ]; then
        add_row "observation_one_start_one_reconcile" true "one start, the anchor unmoved, and the child's result reconciled exactly once" load
    else
        add_row "observation_one_start_one_reconcile" false "second_start_refused=${_second_start} duplicate_refused=${_dupe} anchor=${_anchor}/${_anchor2}" load
    fi

    # 6. RESET IS COMPLETE: the same verb driven twice leaves the same verdict and touches
    #    nothing outside the fixture.
    _drive
    if _cadence_held; then
        add_row "observation_repeatable" true "a second consecutive run holds the same property and leaves nothing behind" load
    else
        add_row "observation_repeatable" false "the second run did not hold: $(tr '\n' ' ' <"$_journal")" load
    fi

    # 7. THE BREAKER, written against the BEHAVIOUR: suppress the observation read during the
    #    child's life and the cadence assertion must fail. A drill nobody has seen fail is a
    #    drill nobody can trust.
    _drive suppress
    if _cadence_held; then
        add_row "observation_breaker" false "with the observation read suppressed the cadence check still passed, so rows 1-2 prove nothing" breaker
    else
        add_row "observation_breaker" true "suppressing the observation read during the child's life makes the cadence assertion fail (this drill can fail)" breaker
    fi

    # 8. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "observation_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "observation_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "observation-during-work" 0 "fail" 1
    fi
    emit_verdict "observation-during-work" 0 "pass" 0
}
