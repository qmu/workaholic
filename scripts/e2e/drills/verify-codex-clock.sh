cmd_verify_codex_clock() {
    _launcher_src="${REPO_ROOT}/plugins/workaholic/skills/work/scripts/codex-loop.sh"
    _shim_src="${REPO_ROOT}/scripts/codex-loop.sh"
    [ -f "$_launcher_src" ] || emit_err "codex_clock_unreadable" 4 "$_launcher_src is not present"

    # Delete a launch tree between real ticks. The fixture also removes every candidate and
    # neuters the boundary check, proving refusal and the original stale-path execution.
    _retired=$(node "${REPO_ROOT}/scripts/e2e/fixtures/codex-retired-path.mjs" "$REPO_ROOT" 2>&1 || true)
    for _retired_case in recovery workspace missing breaker; do
        _retired_ok=$(printf '%s' "$_retired" | jq -r --arg k "$_retired_case" '.[$k] // false' 2>/dev/null || printf false)
        _retired_bearing=load
        [ "$_retired_case" != breaker ] || _retired_bearing=breaker
        if [ "$_retired_ok" = true ]; then
            add_row "retired_plugin_${_retired_case}" true "a removed launch tree: ${_retired_case} proved with observed worker prompts and supervisor state" "$_retired_bearing"
        else
            add_row "retired_plugin_${_retired_case}" false "retired-tree fixture failed: $(one_line "$_retired")" "$_retired_bearing"
        fi
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _repo="${_tmp}/consumer"
    _plugin="${_tmp}/installed/workaholic"
    _bin="${_tmp}/bin"
    mkdir -p "$_repo" "$(dirname "$_plugin")" "$_bin"
    git -C "$_repo" -c init.defaultBranch=main init -q
    git -C "$_repo" config user.email drill@example.com
    git -C "$_repo" config user.name 'Loop Drill'
    printf 'empty consumer\n' > "${_repo}/README.md"
    git -C "$_repo" add README.md
    git -C "$_repo" commit -q -m initial
    cp -R "${REPO_ROOT}/plugins/workaholic" "$_plugin"
    printf '#!/bin/sh\nexit 0\n' > "${_bin}/codex"
    chmod +x "${_bin}/codex"

    _launcher="${_plugin}/skills/work/scripts/codex-loop.sh"
    _out=$(cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --dry-run --once 2>&1 || true)
    case "$_out" in
        *"codex exec -C ${_repo}"*)
            add_row "installed_codex_clock_launches" true "the full plugin launches one dry-run tick from an otherwise empty consuming repository" load ;;
        *) add_row "installed_codex_clock_launches" false "the installed launcher did not produce the tick command: $(one_line "$_out")" load ;;
    esac

    # THE DISPATCH CLAIMS THE ROLE BEFORE IT RETURNS (2026-09-06, ticket `20260906210556`).
    # `--dispatch` returns at once by design, and the lock used to be taken by the detached
    # child — so the claim did not exist yet when the run that made it returned, and a second
    # dispatch in that window read `idle` and started a second worker. The pair below is issued
    # CONCURRENTLY, which is the shape that exposes the window; a sequential pair is hidden by
    # the first dispatch's own return latency on an unloaded machine.
    _slowbin="${_tmp}/slowbin"
    mkdir -p "$_slowbin"
    printf '#!/bin/sh\nsleep 3\nexit 0\n' > "${_slowbin}/codex"
    chmod +x "${_slowbin}/codex"
    _pair=$(cd "$_repo" && PATH="${_slowbin}:$PATH" sh -c \
        "{ sh '$_launcher' --dispatch implement 2>&1 & sh '$_launcher' --dispatch implement 2>&1 & wait; }" \
        2>&1 || true)
    _started=$(printf '%s\n' "$_pair" | grep -c 'started pid=' || true)
    _refused=$(printf '%s\n' "$_pair" | grep -c 'already_running' || true)
    if [ "$_started" = 1 ] && [ "$_refused" = 1 ]; then
        add_row "dispatch_claims_before_it_returns" true "two concurrent dispatches of one role start one worker and refuse the other" load
    else
        add_row "dispatch_claims_before_it_returns" false "concurrent dispatches started ${_started} worker(s) and refused ${_refused}: $(one_line "$_pair")" load
    fi
    codex_clock_wait_workers "$_pair"

    # THE SECOND BREAKER, WRITTEN AGAINST THE BEHAVIOUR. Not a return shape: make the parent's
    # own claim a no-op and nothing holds the role at all — the worker is told `--claimed` and so
    # takes nothing either — and then even a SEQUENTIAL second dispatch starts a second worker.
    # Beside the real launcher, so `SCRIPT_DIR`/`PLUGIN_ROOT` still resolve to the installed
    # plugin; the worker it spawns is the unmodified launcher, which is the point — with the
    # parent claiming nothing and the child told `--claimed`, nothing holds the role.
    _noclaim="${_plugin}/skills/work/scripts/noclaim-codex-loop.sh"
    sed 's/^dispatch_claim_role() {$/dispatch_claim_role() { return 0/' "$_launcher" > "$_noclaim"
    rm -rf "${_repo}/.codex-loop"
    _b1=$(cd "$_repo" && PATH="${_slowbin}:$PATH" sh "$_noclaim" --dispatch implement 2>&1 || true)
    _b2=$(cd "$_repo" && PATH="${_slowbin}:$PATH" sh "$_noclaim" --dispatch implement 2>&1 || true)
    case "$_b1$_b2" in
        *already_running*) add_row "dispatch_claim_breaker" false "removing the dispatch's own claim still refused the second dispatch: $(one_line "$_b2")" breaker ;;
        *"started pid="*"started pid="*) add_row "dispatch_claim_breaker" true "removing the dispatch's own claim starts a second worker for one role (this drill can fail)" breaker ;;
        *) add_row "dispatch_claim_breaker" false "the neutered launcher did not dispatch at all: $(one_line "$_b1$_b2")" breaker ;;
    esac
    codex_clock_wait_workers "$(printf '%s\n%s\n' "$_b1" "$_b2")"
    add_row "codex_clock_workers_stopped" true "every dispatched worker exited before its logs or installed launcher were removed" load
    rm -rf "${_repo}/.codex-loop"

    # A DELIVERED RELAY IS NOT AN EXECUTED TICK (2026-09-07, ticket
    # `20260907082737-refuse-a-healthy-outcome-for-a-tick-that-executed-nothing`). The
    # acknowledgement branch wrote `ready` and `parent_connector` from the relay word alone, so a
    # tick that reported it had executed nothing came back healthy — MEASURED 2026-09-06 (#1052).
    # The rows below drive that branch directly; no `codex` run is involved, so they are hermetic.
    _ack_fixture() {
        mkdir -p "${_repo}/.codex-loop"
        cat > "${_repo}/.codex-loop/envelope.json" <<'RELAY_ENVELOPE'
{"protocol":"workaholic.codex-slack-relay/v1","tick_id":"20260907T000000Z","executed":false,"reason":"no tick ran","outcome":"ok","slack_intents":[{"key":"k1","operation":"post_root","channel":"C1","text":"hi"}]}
RELAY_ENVELOPE
        cat > "${_repo}/.codex-loop/ack.json" <<'RELAY_ACK'
{"protocol":"workaholic.codex-slack-relay/v1","tick_id":"20260907T000000Z","results":[{"key":"k1","outcome":"delivered"}]}
RELAY_ACK
        cat > "${_repo}/.codex-loop/status.json" <<STATUS_FIXTURE
{"state":"blocked","outcome":"$1","blocked_reason":"$2","tick_id":"20260907T000000Z","started_at":"2026-09-07T00:00:00Z","finished_at":"2026-09-07T00:01:00Z","report_path":"${_repo}/.codex-loop/envelope.json","transcript_path":"","transport_verdict":"$3","next_due":null,"relay_envelope_path":"${_repo}/.codex-loop/envelope.json"}
STATUS_FIXTURE
    }
    _ack_reading() {
        jq -r '[.outcome, .transport_verdict] | join(" ")' "${_repo}/.codex-loop/status.json" 2>/dev/null || printf 'unreadable'
    }

    _ack_fixture tick_not_executed "not_executed:no tick ran" unknown
    (cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --ack "${_repo}/.codex-loop/ack.json" >/dev/null 2>&1 || true)
    case "$(_ack_reading)" in
        "tick_not_executed unknown")
            add_row "a_delivered_relay_leaves_a_non_executing_tick_unhealthy" true "the tick keeps its own outcome and an unknown transport after its intents were delivered" load ;;
        *) add_row "a_delivered_relay_leaves_a_non_executing_tick_unhealthy" false "the acknowledgement graded it $(_ack_reading)" load ;;
    esac

    _ack_fixture relay_pending awaiting_parent_ack pending_parent
    (cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --ack "${_repo}/.codex-loop/ack.json" >/dev/null 2>&1 || true)
    case "$(_ack_reading)" in
        "ready parent_connector")
            add_row "a_delivered_relay_still_releases_a_pending_tick" true "a tick the relay was withholding records exactly what it recorded before" load ;;
        *) add_row "a_delivered_relay_still_releases_a_pending_tick" false "a healthy relay tick came back $(_ack_reading)" load ;;
    esac

    _relay_contract="${_plugin}/skills/work/scripts/relay-contract.sh"
    jq 'del(.executed)' "${_repo}/.codex-loop/envelope.json" > "${_tmp}/no-executed.json"
    _unstated=$(sh "$_relay_contract" envelope "${_tmp}/no-executed.json" 2>&1 || true)
    case "$_unstated" in
        *malformed_envelope*)
            add_row "an_envelope_that_states_no_execution_fails_closed" true "an envelope omitting executed is refused rather than assumed to have run" load ;;
        *) add_row "an_envelope_that_states_no_execution_fails_closed" false "the envelope validated without executed: $(one_line "$_unstated")" load ;;
    esac

    # THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR. Restore the pre-repair acknowledgement — a
    # healthy write on the relay word alone — and the non-executing tick must come back `ready`.
    _oldack="${_plugin}/skills/work/scripts/oldack-codex-loop.sh"
    sed 's/if (\.outcome == "relay_pending" or \.outcome == "ready") then/if true then/' \
        "$_launcher" > "$_oldack"
    _ack_fixture tick_not_executed "not_executed:no tick ran" unknown
    (cd "$_repo" && PATH="${_bin}:$PATH" sh "$_oldack" --ack "${_repo}/.codex-loop/ack.json" >/dev/null 2>&1 || true)
    case "$(_ack_reading)" in
        "ready parent_connector")
            add_row "false_healthy_ack_breaker" true "restoring the unconditional healthy write grades a non-executing tick ready (this drill can fail)" breaker ;;
        *) add_row "false_healthy_ack_breaker" false "the neutered acknowledgement did not reproduce the false-healthy write: $(_ack_reading)" breaker ;;
    esac
    rm -f "$_oldack"
    rm -rf "${_repo}/.codex-loop"

    # A LIVE SUPERVISOR IS NOT AN UNWRITTEN RECORD (2026-09-07, ticket
    # `20260907082737-tell-a-live-supervisor-from-a-succeeded-tick-and-an-unwritten-record`).
    # `supervisor_reading` answered from its record file alone, so an older supervisor holding the
    # lock and turning was reported `never_started` — MEASURED 2026-09-06 (#1052), the operator
    # could neither see the live supervisor nor start a working one. The lock is read as
    # EVIDENCE here; it stays the only concurrency authority and this reading refuses nothing.
    if command -v flock >/dev/null 2>&1; then
        mkdir -p "${_repo}/.codex-loop"
        _suplock="${_repo}/.codex-loop/.supervisor.lock"
        sh -c "exec 9>'$_suplock'; flock -n 9 || exit 1; sleep 30" &
        _holder=$!
        sleep 1
        _held=$(cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --status 2>&1 | head -n 1)
        case "$_held" in
            *running_unrecorded*)
                add_row "a_held_supervisor_lock_is_never_never_started" true "a live supervisor with no record of its own is named rather than reported as never started" load ;;
            *) add_row "a_held_supervisor_lock_is_never_never_started" false "a held supervisor lock read: $(one_line "$_held")" load ;;
        esac
        # THE BREAKER, AGAINST THE BEHAVIOUR: answer from the record file alone again, and the
        # same live supervisor comes back `never_started`.
        _blindsup="${_plugin}/skills/work/scripts/blindsup-codex-loop.sh"
        sed 's/^    if \[ ! -f "\$SUPERVISOR_FILE" \]; then$/    if [ ! -f "$SUPERVISOR_FILE" ]; then printf '"'"'never_started'"'"'; return 0;/' \
            "$_launcher" > "$_blindsup"
        _blind=$(cd "$_repo" && PATH="${_bin}:$PATH" sh "$_blindsup" --status 2>&1 | head -n 1)
        case "$_blind" in
            *never_started*)
                add_row "supervisor_liveness_breaker" true "reading the record file alone reports a live supervisor as never_started (this drill can fail)" breaker ;;
            *) add_row "supervisor_liveness_breaker" false "the neutered reader did not reproduce never_started: $(one_line "$_blind")" breaker ;;
        esac
        rm -f "$_blindsup"
        for _p in $(fuser "$_suplock" 2>/dev/null || true); do kill "$_p" 2>/dev/null || true; done
        kill "$_holder" 2>/dev/null || true
        wait "$_holder" 2>/dev/null || true
        _free=$(cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --status 2>&1 | head -n 1)
        case "$_free" in
            *never_started*)
                add_row "an_unheld_lock_still_means_never_started" true "a repository with no supervisor and no record reads exactly as it did before" load ;;
            *) add_row "an_unheld_lock_still_means_never_started" false "a free lock with no record read: $(one_line "$_free")" load ;;
        esac
        rm -rf "${_repo}/.codex-loop"
    else
        add_row "supervisor_liveness_needs_flock" true "flock is absent; the supervisor-lock evidence reads unverifiable by design" advisory
    fi

    # A PID IS NOT A LIVENESS PROOF ACROSS A REBOOT. `role_state`'s pid-file fallback tested
    # `kill -0` alone, dropping the boot-id term `liveness_reading` carries — so a recycled pid
    # number refused every start of that role forever, while the role's own record read
    # `died_unrecorded:reboot`, a proof the process was gone.
    _noflock="${_tmp}/noflock"
    mkdir -p "$_noflock"
    for _c in sh jq git date cat printf sed grep tr sleep kill rm mkdir dirname basename awk ls mktemp; do
        _cp=$(command -v "$_c" 2>/dev/null) && ln -sf "$_cp" "${_noflock}/${_c}"
    done
    printf '#!/bin/sh\nexit 0\n' > "${_noflock}/codex"
    chmod +x "${_noflock}/codex"
    mkdir -p "${_repo}/.codex-loop"
    sleep 30 &
    _livepid=$!
    printf '%s\n' "$_livepid" > "${_repo}/.codex-loop/worker-implement.pid"
    printf '{"state":"running","pid":"%s","boot_id":"00000000-0000-0000-0000-000000000000","started_at":"2026-09-07T00:00:00Z"}\n' \
        "$_livepid" > "${_repo}/.codex-loop/worker-implement.json"
    _recycled=$(cd "$_repo" && PATH="$_noflock" sh "$_launcher" --dispatch implement --dry-run 2>&1 | head -n 1)
    case "$_recycled" in
        *already_running*) add_row "a_recycled_pid_does_not_refuse_a_start_forever" false "a pid the record proves is from another boot still refused the start: $(one_line "$_recycled")" load ;;
        *"would start"*)   add_row "a_recycled_pid_does_not_refuse_a_start_forever" true "a pid the record proves belongs to another boot no longer holds the role" load ;;
        *) add_row "a_recycled_pid_does_not_refuse_a_start_forever" false "the dispatch answered neither: $(one_line "$_recycled")" load ;;
    esac
    printf '{"state":"running","pid":"%s","boot_id":"%s","started_at":"2026-09-07T00:00:00Z"}\n' \
        "$_livepid" "$(tr -d '\n' </proc/sys/kernel/random/boot_id 2>/dev/null || printf '')" \
        > "${_repo}/.codex-loop/worker-implement.json"
    _samboot=$(cd "$_repo" && PATH="$_noflock" sh "$_launcher" --dispatch implement --dry-run 2>&1 | head -n 1)
    case "$_samboot" in
        *already_running*) add_row "a_live_worker_on_this_boot_is_still_refused" true "a genuinely running role is refused exactly as before" load ;;
        *) add_row "a_live_worker_on_this_boot_is_still_refused" false "a live worker on this boot was not refused: $(one_line "$_samboot")" load ;;
    esac
    rm -f "${_repo}/.codex-loop/worker-implement.json"
    _unknown=$(cd "$_repo" && PATH="$_noflock" sh "$_launcher" --dispatch implement --dry-run 2>&1 | head -n 1)
    case "$_unknown" in
        *already_running*) add_row "an_unreadable_liveness_never_starts_a_second_worker" true "with no record to supply a boot id the role stays held, which is the safe direction for a concurrency answer" load ;;
        *) add_row "an_unreadable_liveness_never_starts_a_second_worker" false "an unverifiable pid started a second worker: $(one_line "$_unknown")" load ;;
    esac
    kill "$_livepid" 2>/dev/null || true
    wait "$_livepid" 2>/dev/null || true
    rm -rf "${_repo}/.codex-loop"

    mkdir -p "${_repo}/scripts"
    cp "$_shim_src" "${_repo}/scripts/codex-loop.sh"
    rm "$_launcher"
    _broken=$(cd "$_repo" && PATH="${_bin}:$PATH" sh scripts/codex-loop.sh --dry-run --once 2>&1 || true)
    case "$_broken" in
        *clock_wrapper_missing:*plugin_skill_missing:*)
            add_row "codex_clock_breaker" false "the missing launcher was also misdiagnosed as a missing skill: $(one_line "$_broken")" breaker ;;
        *clock_wrapper_missing:*)
            add_row "codex_clock_breaker" true "removing the packaged launcher produces clock_wrapper_missing and no plugin-skill diagnosis (this drill can fail)" breaker ;;
        *) add_row "codex_clock_breaker" false "removing the packaged launcher did not produce clock_wrapper_missing: $(one_line "$_broken")" breaker ;;
    esac

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "codex_clock_writes_nothing_outside_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "codex_clock_writes_nothing_outside_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then emit_verdict "codex-clock" 0 "fail" 1; fi
    emit_verdict "codex-clock" 0 "pass" 0
}


# ------------------------------------------------------------- verify-work-drain
#
# ONE RUN AGAINST A SEEDED BACKLOG, AND THE THREE WAYS IT MUST NOT LIE (2026-09-06, mission
# `finish-the-backlog-without-handing-it-back-to-the-operator`). The ask's own acceptance is a
# DEMONSTRATION rather than a return shape: a disposable repository carrying recovery states the
# loop must work rather than hand over, and three negative cases none of which may read as
# completed-and-notified.
#
# WHAT THIS DRILL PROVES, AND IT IS THE HERMETIC HALF. It seeds the states, then asserts the
# readings and the acts the loop makes on them with no network, no credential and no agent:
#   1. recovery work is CLAIMABLE — a repository whose only work is an undelivered unit, a
#      catchable claim or a stranded publication is not an idle one, so a pass is dispatched;
#   2. a worker that exits ZERO while reporting it did not execute records NO healthy finish and
#      leaves its role due;
#   3. a report this loop cannot read is `unreadable:<reason>` and never `ok`;
#   4. a failed delivery is carried, retried ONCE and cleared on a landed send — never duplicated;
#   5. restarting leaves NO duplicate worker, because the per-role lock refuses `already_running`.
#
# WHAT IT DELIBERATELY DOES NOT PROVE, STATED RATHER THAN LEFT TO BE DISCOVERED. A live `/work`
# run driving a real queue across BOTH entrypoints, an interruption mid-drive, and a plugin-cache
# replacement each need a running agent and a real Slack surface. A hermetic drill cannot spawn
# one, and a drill that pretended to would be exactly the false green this mission exists to end.
# That demonstration is its own ticket; this drill is what a push can run on every commit.
