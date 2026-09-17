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

    # 4. THE PLANNING INPUT: 観察中 remains available to the agent beside every other stage.
    #    The declaration informs judgement; it does not mechanically stop learning.
    _s=$(_survey)
    _sel=$(_f "$_s" '.selected | sort | join(",")')
    _obs=$(_f "$_s" '[.eligible[] | select(.slug == "settled") | .stage] | join("")')
    if [ "$_obs" = "観察中" ] && [ "$_sel" = "improving,running,settled,unstaged" ]; then
        add_row "observing_remains_eligible" true "the 観察中 direction remains eligible context beside every other stage" load
    else
        add_row "observing_remains_eligible" false "expected 観察中 + improving,running,settled,unstaged; got '${_obs}' / '${_sel}'" load
    fi
    _keep=$(_f "$_s" '[.eligible[] | select(.slug == "settled") | (.pace|tostring), (.overdue|tostring), (.dormant|tostring), (.quiescent|tostring)] | length')
    if [ "$_keep" = "4" ]; then
        add_row "observing_still_visible" true "the eligible row carries every reading, so the agent sees stage and evidence together" load
    else
        add_row "observing_still_visible" false "the observing row lost its readings" load
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

    # 9. THE BREAKER: restore the retired stage gate. Row 4 must fail because a declaration
    #    that should inform the agent would mechanically remove the direction from its choices.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/." "${_broken}/"
    sed '/elif \.owns != "mine" then "not_mine"/a\
           elif (.stage == "観察中") then "observing"' \
        "$_srv" > "${_broken}/skills/propose/scripts/survey-strategies.sh"
    _bs=$( cd "$_fx" && sh "${_broken}/skills/propose/scripts/survey-strategies.sh" \
        --open-proposals "${_tmp}/open.json" "30 days ago" "$_wh" 2>/dev/null || true )
    _bsel=$(_f "$_bs" '.selected | sort | join(",")')
    _bobs=$(_f "$_bs" '[.refused[] | select(.slug == "settled") | .reason] | join("")')
    if [ "$_bobs" = "observing" ] && [ "$_bsel" = "improving,running,unstaged" ]; then
        add_row "stage_breaker" true "restoring the retired observing gate removes the settled direction, so the eligibility assertion can fail" breaker
    else
        add_row "stage_breaker" false "the breaker did not restore the observing refusal: refused='${_bobs}' selected='${_bsel}'" breaker
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

# ------------------------------------------------------------- verify-codex-clock

# The supported CLI clock must launch from the installed full plugin, with no supervisor copied
# into the consuming repository. The breaker removes that packaged launcher and proves the
# compatibility entrypoint names the clock layer rather than misdiagnosing the intact skill.
codex_clock_wait_workers() {
    # Dispatch returns before its worker. Deleting the logs at that point races the worker's
    # writes, and deleting a held lock also lets the next scenario bypass it. Wait for the
    # actual dispatched processes, including the breaker workers that deliberately hold no
    # lock. Detached children cannot be shell-waited; a zombie has already stopped writing.
    _cw_pids=$(printf '%s\n' "$1" | sed -n 's/.*started pid=\([0-9][0-9]*\).*/\1/p')
    for _cw_pid in $_cw_pids; do
        _cw_remaining=30
        while kill -0 "$_cw_pid" 2>/dev/null; do
            _cw_state=$(ps -p "$_cw_pid" -o stat= 2>/dev/null || true)
            case "$_cw_state" in *Z*) break ;; esac
            if [ "$_cw_remaining" -eq 0 ]; then
                add_row "codex_clock_workers_stopped" false "worker ${_cw_pid} did not exit; preserving fixture ${_tmp}" load
                emit_verdict "codex-clock" 0 "fail" 1
            fi
            sleep 1
            _cw_remaining=$((_cw_remaining - 1))
        done
    done
}
