cmd_verify_directed_notification() {
    _spec="${REPO_ROOT}/plugins/workaholic/skills/specificate/scripts/notify-slack.sh"
    _notify="${REPO_ROOT}/plugins/workaholic/skills/notify/SKILL.md"
    _catalog="${REPO_ROOT}/plugins/workaholic/skills/notify/reference/notifications.md"
    _modwf="${REPO_ROOT}/plugins/workaholic/skills/moderate/reference/workflow.md"
    _routing="${REPO_ROOT}/plugins/workaholic/skills/drive/reference/routing.md"
    _askq="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/ask-question.sh"
    _tmod="${REPO_ROOT}/plugins/workaholic/commands/moderate.md"
    _timp="${REPO_ROOT}/plugins/workaholic/commands/implement.md"
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
[ -n "$out" ] && printf '{"ok":true,"channel":"C0DRILL0","ts":"1724371200.000200","message":{"user":"U0BOT"}}' > "$out"
printf '200'
STUB
    chmod +x "${_bin}/curl"
    _post() {
        : > "$_cap"
        ( PATH="${_bin}:$PATH" WORKAHOLIC_DRILL_CAPTURE="$_cap" \
          SLACK_BOT_TOKEN="${1}" WORKAHOLIC_SLACK_CHANNEL=C0DRILL0 \
          WORKAHOLIC_SLACK_API_URL='http://stub.invalid/chat.postMessage' \
          WORKAHOLIC_TRANSPORT_OCCURRENCE_ID="drill-$$" \
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

    # 7. THE COMMANDS. *The command is the ceiling*: the rule sanctions the shape and only the
    #    command lets a session running that routine emit it (2026-09-01 — before then this read
    #    the routine templates, which is where the shapes used to live).
    _tm=''
    for _pair in "${_tmod}:🙋" "${_timp}:🟡 Handoff"; do
        _p="${_pair%:*}"; _shape="${_pair##*:}"
        grep -q -- '--thread-ts' "$_p" || _tm="${_tm} $(basename "$_p")(carrier)"
        grep -q "$_shape" "$_p" || _tm="${_tm} $(basename "$_p")(shape)"
    done
    if [ -z "$_tm" ]; then
        add_row "templates_name_shape_and_carrier" true "both commands name the shape they authorize and the transport that carries it" load
    else
        add_row "templates_name_shape_and_carrier" false "a command names one without the other:${_tm}" load
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
