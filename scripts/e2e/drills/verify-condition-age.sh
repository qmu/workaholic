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
