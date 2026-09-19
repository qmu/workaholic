# Every file in a state directory with its size and mtime, so a probe that truncates or touches
# one is visible. `stat -c` is GNU and `stat -f` is BSD; a machine with neither answers
# `unmeasurable`, which the caller reads as *not measured* rather than as *equal*.
codex_clock_state_fingerprint() {
    for _fp in "$1"/* "$1"/.[!.]*; do
        [ -e "$_fp" ] || continue
        stat -c '%n %s %Y' "$_fp" 2>/dev/null \
            || stat -f '%N %z %m' "$_fp" 2>/dev/null \
            || printf '%s unmeasurable\n' "$_fp"
    done | sort
}

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

    # A READING THAT CHANGES WHAT IT READS IS NOT AN OBSERVATION (2026-09-19, ticket
    # `20260919115510-read-worker-liveness-without-writing-or-locking`). `role_state()` and
    # `supervisor_lock_state()` opened each lock with `exec 8>` / `exec 7>`, which CREATES and
    # TRUNCATES the file and moves its mtime — so `--status`, documented four times over as a
    # surface that "starts nothing, writes nothing, takes no lock", destroyed the very forensics
    # it exists to provide. MEASURED by the reporter: three `worker-*.lock` files reading one
    # minute old, written by their own earlier `--status` call, in a repository whose supervisor
    # had been dead for twelve days. The fixture carries NO supervisor record, so the
    # `.supervisor.lock` probe is on the path too.
    mkdir -p "${_repo}/.codex-loop"
    for _lk in .supervisor.lock worker-implement.lock worker-propose.lock worker-moderate.lock; do
        printf 'held-by-nobody\n' > "${_repo}/.codex-loop/${_lk}"
    done
    printf '{"state":"sleeping","outcome":"ready","blocked_reason":"","tick_id":"t","finished_at":"","next_due":"","report_path":"","relay_state":"none"}\n' \
        > "${_repo}/.codex-loop/status.json"
    _lock_before=$(codex_clock_state_fingerprint "${_repo}/.codex-loop")
    (cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --status --json >/dev/null 2>&1 || true)
    (cd "$_repo" && PATH="${_bin}:$PATH" sh "$_launcher" --status >/dev/null 2>&1 || true)
    _lock_after=$(codex_clock_state_fingerprint "${_repo}/.codex-loop")
    case "$_lock_before" in
        *unmeasurable*|'')
            add_row "status_leaves_every_lock_byte_identical" false "the state directory could not be fingerprinted on this machine" load ;;
        *)
            if [ "$_lock_before" = "$_lock_after" ]; then
                add_row "status_leaves_every_lock_byte_identical" true "one --status --json and one --status leave every file in the state directory unchanged, size and mtime included" load
            else
                add_row "status_leaves_every_lock_byte_identical" false "a --status call moved the state directory: $(one_line "$_lock_after")" load
            fi ;;
    esac

    # THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR: restore the writing probes at both sites and
    # the same two read-only calls must move the locks again.
    _writeprobe="${_plugin}/skills/work/scripts/writeprobe-codex-loop.sh"
    sed 's/exec 8<"$_lock"/exec 8>"$_lock"/; s/exec 7<"$_sl_file"/exec 7>"$_sl_file"/' \
        "$_launcher" > "$_writeprobe"
    for _lk in .supervisor.lock worker-implement.lock worker-propose.lock worker-moderate.lock; do
        printf 'held-by-nobody\n' > "${_repo}/.codex-loop/${_lk}"
    done
    _wp_before=$(codex_clock_state_fingerprint "${_repo}/.codex-loop")
    (cd "$_repo" && PATH="${_bin}:$PATH" sh "$_writeprobe" --status --json >/dev/null 2>&1 || true)
    _wp_after=$(codex_clock_state_fingerprint "${_repo}/.codex-loop")
    if [ "$_wp_before" != "$_wp_after" ]; then
        add_row "status_write_probe_breaker" true "restoring the writing probe truncates the lock files a read-only status must leave alone (this drill can fail)" breaker
    else
        add_row "status_write_probe_breaker" false "the restored writing probe left the state directory unchanged, so the row above proves nothing: $(one_line "$_wp_after")" breaker
    fi
    rm -f "$_writeprobe"
    rm -rf "${_repo}/.codex-loop"

    # A REFUSAL THAT LEAVES NO EVIDENCE IS A SILENT FAILURE (2026-09-19, ticket
    # `20260919115510-recover-or-record-a-retired-plugin-tree-at-startup`). The startup's two
    # plugin-tree guards ran above the `REPO_ROOT` / `LOG_DIR` resolution and exited 2 outright,
    # so a supervisor launched against a tree that had moved died with no state directory and no
    # record anywhere — and `--status` then answered `absent`, the reading *never started*,
    # which is exactly the confusion `supervisor.json` was added to end. MEASURED: a supervisor
    # pinned to a retired plugin version died on 2026-09-07 and nobody saw it for twelve days.
    # The fixture isolates HOME, the registry and the clone home so the resolver can find no
    # complete replacement anywhere on the machine, which is the unrecoverable half.
    _retired_tree="${_tmp}/retired/workaholic"
    _retired_repo="${_tmp}/retired-repo"
    _retired_home="${_tmp}/retired-home"
    mkdir -p "$(dirname "$_retired_tree")" "$_retired_repo" "$_retired_home"
    git -C "$_retired_repo" -c init.defaultBranch=main init -q
    cp -R "${REPO_ROOT}/plugins/workaholic" "$_retired_tree"
    rm -f "${_retired_tree}/skills/work/SKILL.md"
    _retired_env="HOME=${_retired_home} WORKAHOLIC_SRC_HOME=${_tmp}/no-clone CLAUDE_PLUGIN_REGISTRY=${_tmp}/no-registry.json CODEX_PLUGIN_CACHE=${_tmp}/no-codex-cache CLAUDE_PLUGIN_CACHE=${_tmp}/no-claude-cache CLAUDE_PLUGIN_ROOT=${_retired_tree}"
    _retired_out=$(cd "$_retired_repo" && env $_retired_env PATH="${_bin}:$PATH" \
        sh "${_retired_tree}/skills/work/scripts/codex-loop.sh" --once --interval 60 2>&1 || true)
    _retired_record=$(cat "${_retired_repo}/.codex-loop/supervisor.json" 2>/dev/null || printf '')
    _retired_reading=$(printf '%s' "$_retired_record" | jq -r '"\(.state):\(.stopped_reason)"' 2>/dev/null || printf 'unreadable')
    case "$_retired_reading" in
        stopped:plugin_skill_missing)
            add_row "a_retired_tree_startup_records_its_stop" true "a supervisor that cannot read its own instructions leaves state=stopped naming plugin_skill_missing instead of dying unrecorded" load ;;
        *) add_row "a_retired_tree_startup_records_its_stop" false "the startup recorded $(one_line "$_retired_reading"): $(one_line "$_retired_out")" load ;;
    esac
    case "$_retired_out" in
        *plugin_skill_missing:*"work skill is incomplete"*)
            add_row "a_retired_tree_startup_keeps_its_stderr" true "the refusal still prints its own two lines and exits 2, unchanged" load ;;
        *) add_row "a_retired_tree_startup_keeps_its_stderr" false "the refusal's stderr changed: $(one_line "$_retired_out")" load ;;
    esac

    # THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR: restore the pre-repair early exit and the same
    # launch must die leaving no record at all.
    _earlyexit="${_retired_tree}/skills/work/scripts/earlyexit-codex-loop.sh"
    sed 's/^if \[ -n "$STARTUP_TREE_REFUSAL" \]; then$/if [ -n "$STARTUP_TREE_REFUSAL" ]; then startup_tree_refuse; exit 2;/' \
        "${_retired_tree}/skills/work/scripts/codex-loop.sh" > "$_earlyexit"
    rm -rf "${_retired_repo}/.codex-loop"
    (cd "$_retired_repo" && env $_retired_env PATH="${_bin}:$PATH" sh "$_earlyexit" --once --interval 60 >/dev/null 2>&1 || true)
    if [ -f "${_retired_repo}/.codex-loop/supervisor.json" ]; then
        add_row "retired_tree_startup_breaker" false "restoring the early exit still left a record, so the rows above prove nothing" breaker
    else
        add_row "retired_tree_startup_breaker" true "restoring the early exit leaves a stopped supervisor with no record anywhere (this drill can fail)" breaker
    fi
    rm -f "$_earlyexit"

    # A LAUNCH OUTSIDE A REPOSITORY STILL REFUSES BEFORE ANY RECORD. There is nowhere to write
    # one, and inventing a location for the state directory would be worse than the absence.
    _norepo=$(cd "$_tmp" && env $_retired_env PATH="${_bin}:$PATH" \
        sh "${_retired_tree}/skills/work/scripts/codex-loop.sh" --once 2>&1 || true)
    case "$_norepo" in
        repository_missing*) add_row "a_launch_outside_a_repository_writes_nothing" true "repository_missing still refuses ahead of every record" load ;;
        *) add_row "a_launch_outside_a_repository_writes_nothing" false "a launch outside a repository answered: $(one_line "$_norepo")" load ;;
    esac

    # A STOP THAT REACHES NO READER IS A SILENT STOP (2026-09-19, ticket
    # `20260919115511-announce-a-codex-clock-that-stopped-or-executed-nothing`). The supervisor's
    # whole escalation reach was a state file and a line on stderr, and nothing outside
    # `skills/work/` read the status surface — MEASURED: a loop stayed `blocked / interrupted`
    # for twelve days with a person looking at the repository. The transport is stubbed, so these
    # rows prove the loop and not the provider; Slack is undeliverable in this repository today
    # and the undeliverable case is asserted on the outbox and the refusal word, as it must be.
    _stub_sink="${_tmp}/announce-posts.txt"
    _stub="${_tmp}/announce-stub.sh"
    # WRITTEN AS A HEREDOC, NOT AS printf ESCAPES (2026-09-19). `\x27` is a bashism: dash's
    # printf emits it literally, so on a runner whose /bin/sh is dash the stub's last line was
    # broken quoting — it still appended to the sink, so the post rows passed, and it returned no
    # readable `notified`, so every announcement took the undeliverable branch and re-attempted
    # the next tick. MEASURED in CI against a checkout that passed locally under bash-as-sh:
    # `five ticks posted 1 calm and 4 red roots`.
    cat > "$_stub" <<'ANNOUNCE_STUB'
#!/bin/sh -eu
printf '%s\n---\n' "$1" >> "${STUB_SINK:?}"
printf '{"notified": true, "reason": ""}\n'
ANNOUNCE_STUB
    chmod +x "$_stub"
    : > "$_stub_sink"
    rm -rf "${_retired_repo}/.codex-loop"
    (cd "$_retired_repo" && env $_retired_env PATH="${_bin}:$PATH" \
        STUB_SINK="$_stub_sink" WORKAHOLIC_ANNOUNCE_NOTIFIER="$_stub" \
        sh "${_retired_tree}/skills/work/scripts/codex-loop.sh" --once --interval 60 >/dev/null 2>&1 || true)
    _announced=$(grep -c '⚪ Paused - codex clock stopped: plugin_skill_missing' "$_stub_sink" 2>/dev/null || printf 0)
    if [ "$_announced" = 1 ]; then
        add_row "a_stopped_clock_reaches_a_person" true "a supervisor that stops for a reason other than an ordinary end posts exactly one precondition-stop announcement carrying its reason word" load
    else
        add_row "a_stopped_clock_reaches_a_person" false "the stop produced ${_announced} announcement(s): $(one_line "$(cat "$_stub_sink" 2>/dev/null)")" load
    fi

    # ONE WALL, ONE ALERT. The same signature escalates ONCE from the calm shape to the red one
    # and is suppressed from there, which is `workaholic:notify`'s own dedup and escalation.
    _announcer="${_retired_tree}/skills/work/scripts/announce-stop.sh"
    _ann_log="${_tmp}/announce-log"
    rm -rf "$_ann_log"; : > "$_stub_sink"
    _n=1
    while [ "$_n" -le 5 ]; do
        env STUB_SINK="$_stub_sink" WORKAHOLIC_ANNOUNCE_NOTIFIER="$_stub" sh "$_announcer" \
            --log "$_ann_log" --signature 'codex worker not executing: implement (tick_not_executed)' \
            --text drill --now $((1789800000 + _n)) >/dev/null 2>&1 || true
        _n=$((_n + 1))
    done
    _paused=$(grep -c '⚪ Paused' "$_stub_sink" 2>/dev/null || printf 0)
    _blocked=$(grep -c '🔴 Blocked' "$_stub_sink" 2>/dev/null || printf 0)
    if [ "$_paused" = 1 ] && [ "$_blocked" = 1 ]; then
        add_row "a_clock_that_executes_nothing_is_one_alert" true "five ticks against one signature post one calm root and one escalation, and nothing after" load
    else
        add_row "a_clock_that_executes_nothing_is_one_alert" false "five ticks posted ${_paused} calm and ${_blocked} red roots" load
    fi

    # AN UNDELIVERABLE TRANSPORT IS A RECORDED REFUSAL, NEVER A POST.
    rm -rf "$_ann_log"
    _undeliverable=$(env -u SLACK_BOT_TOKEN sh "$_announcer" --log "$_ann_log" \
        --signature 'codex clock stopped: interrupted' --text drill 2>/dev/null || printf '{}')
    _ud_state=$(printf '%s' "$_undeliverable" | jq -r '"\(.announced):\(.reason):\(.outbox != null)"' 2>/dev/null || printf unreadable)
    case "$_ud_state" in
        false:no_token:true)
            add_row "an_undeliverable_announcement_is_carried" true "a refused transport retains the line in the outbox and names its refusal word rather than reading as posted" load ;;
        *) add_row "an_undeliverable_announcement_is_carried" false "an undeliverable announcement answered $(one_line "$_ud_state")" load ;;
    esac

    # THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR: remove the announcement and the same stop
    # reaches nobody again.
    _silent="${_retired_tree}/skills/work/scripts/silent-codex-loop.sh"
    sed 's/^announce_stop() {$/announce_stop() { return 0/' \
        "${_retired_tree}/skills/work/scripts/codex-loop.sh" > "$_silent"
    : > "$_stub_sink"
    rm -rf "${_retired_repo}/.codex-loop"
    (cd "$_retired_repo" && env $_retired_env PATH="${_bin}:$PATH" \
        STUB_SINK="$_stub_sink" WORKAHOLIC_ANNOUNCE_NOTIFIER="$_stub" \
        sh "$_silent" --once --interval 60 >/dev/null 2>&1 || true)
    if [ -s "$_stub_sink" ]; then
        add_row "stop_announcement_breaker" false "removing the announcement still posted something, so the rows above prove nothing" breaker
    else
        add_row "stop_announcement_breaker" true "removing the announcement leaves a stopped clock reaching nobody (this drill can fail)" breaker
    fi
    rm -f "$_silent"

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
