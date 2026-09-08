cmd_verify_work_drain() {
    _cu="${REPO_ROOT}/plugins/workaholic/skills/loops/scripts/claimable-units.sh"
    _cl="${REPO_ROOT}/plugins/workaholic/skills/work/scripts/codex-loop.sh"
    _rec="${REPO_ROOT}/plugins/workaholic/skills/story/scripts/record-unposted-line.sh"
    _read="${REPO_ROOT}/plugins/workaholic/skills/story/scripts/read-unposted-line.sh"
    for _f in "$_cu" "$_cl" "$_rec" "$_read"; do
        [ -f "$_f" ] || emit_err "work_drain_unreadable" 4 "$_f is not present"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)

    # ---- 1. THE SEEDED BACKLOG IS CLAIMABLE WORK -------------------------------------------
    # The five conditions the ask names reduce, for the dispatcher, to one question: is there
    # work a pass would act on. Each recovery state is fed in on its own so a single passing
    # term cannot mask a missing one.
    printf '%s' '{"units": [], "stranded": 0}' > "${_tmp}/rec-none.json"
    printf '%s' '{"units": [], "stranded": 0}' > "${_tmp}/rec-empty.json"
    printf '%s' '{"units": ["u2"], "stranded": 0}' > "${_tmp}/rec-catch.json"
    printf '%s' '{"units": [], "stranded": 1}' > "${_tmp}/rec-strand.json"
    printf '%s' '{"current":true,"shallow":false,"backlog_error":"","owner_unresolved":false,"placeholder_identity":false,"missions":[],"backlog":[],"resumable":[],"undelivered":[{"unit":"u1"}]}' > "${_tmp}/s-und.json"
    printf '%s' '{"current":true,"shallow":false,"backlog_error":"","owner_unresolved":false,"placeholder_identity":false,"missions":[],"backlog":[],"resumable":[],"undelivered":[]}' > "${_tmp}/s-empty.json"

    _und=$(sh "$_cu" --survey "${_tmp}/s-und.json" --recovery "${_tmp}/rec-none.json" 2>/dev/null || printf '')
    case "$_und" in
        *'"claimable":1'*) add_row "seeded_undelivered_unit_is_claimable" true "an undelivered unit alone dispatches a pass" load ;;
        *) add_row "seeded_undelivered_unit_is_claimable" false "an undelivered unit read as nothing to do: $(one_line "$_und")" load ;;
    esac
    _cat=$(sh "$_cu" --survey "${_tmp}/s-empty.json" --recovery "${_tmp}/rec-catch.json" 2>/dev/null || printf '')
    case "$_cat" in
        *'"claimable":1'*) add_row "seeded_catchable_claim_is_claimable" true "a catchable claim alone dispatches a pass" load ;;
        *) add_row "seeded_catchable_claim_is_claimable" false "a catchable claim read as nothing to do: $(one_line "$_cat")" load ;;
    esac
    _str=$(sh "$_cu" --survey "${_tmp}/s-empty.json" --recovery "${_tmp}/rec-strand.json" 2>/dev/null || printf '')
    case "$_str" in
        *'"claimable":1'*) add_row "seeded_stranded_publication_is_claimable" true "a stranded publication alone dispatches a pass" load ;;
        *) add_row "seeded_stranded_publication_is_claimable" false "a stranded publication read as nothing to do: $(one_line "$_str")" load ;;
    esac
    # AND A GENUINELY EMPTY REPOSITORY IS STILL EMPTY. Without this row the three above would
    # pass just as well for a counter that answered 1 for everything.
    _none=$(sh "$_cu" --survey "${_tmp}/s-empty.json" --recovery "${_tmp}/rec-empty.json" 2>/dev/null || printf '')
    case "$_none" in
        *'"claimable":0'*) add_row "an_empty_repository_dispatches_nothing" true "nothing to do still answers zero" load ;;
        *) add_row "an_empty_repository_dispatches_nothing" false "an empty repository did not answer zero: $(one_line "$_none")" load ;;
    esac

    # ---- 2 & 3. THE NEGATIVE CASES: A RUN THAT DID NOT HAPPEN NEVER READS AS ONE THAT DID ----
    # `worker_outcome` is read out of the launcher and exercised directly, so the drill tests the
    # shipped reader rather than a copy of it.
    _fn="${_tmp}/outcome.sh"
    sed -n '/^worker_outcome() {/,/^}/p' "$_cl" > "$_fn"
    if [ ! -s "$_fn" ]; then
        add_row "worker_outcome_reader_is_present" false "the launcher carries no worker_outcome reader" load
    else
        add_row "worker_outcome_reader_is_present" true "the launcher's own outcome reader was read out of it" load
        printf '%s' '{"executed":false,"outcome":"failed","reason":"plugin_command_missing","report":""}' > "${_tmp}/r-notexec.json"
        printf '%s' '{"executed":true,"outcome":"ok","reason":"","report":"1 units: 1 shipped"}' > "${_tmp}/r-ok.json"
        printf 'I could not execute the role body.\n' > "${_tmp}/r-prose.txt"
        _probe="${_tmp}/probe.sh"
        {
            cat "$_fn"
            printf 'printf "%%s|%%s|%%s\\n" "$(worker_outcome "$1" 0)" "$(worker_outcome "$2" 0)" "$(worker_outcome "$3" 0)"\n'
        } > "$_probe"
        _res=$(sh "$_probe" "${_tmp}/r-notexec.json" "${_tmp}/r-ok.json" "${_tmp}/r-prose.txt" 2>/dev/null || printf '')
        case "$_res" in
            not_executed:*'|ok|'unreadable:*)
                add_row "a_zero_exit_that_did_not_execute_is_not_a_finish" true "exit 0 with executed:false reads not_executed, a real run reads ok, and prose reads unreadable" load ;;
            *) add_row "a_zero_exit_that_did_not_execute_is_not_a_finish" false "the three outcomes did not separate: $(one_line "$_res")" load ;;
        esac
    fi

    # ---- 4. A FAILED DELIVERY IS CARRIED, SENT ONCE, AND CLEARED --------------------------
    # The record is the loop's own carry-and-retry shape; the point of the row is that a landed
    # send CLEARS it, which is what makes a second tick unable to post the line twice.
    _story="${_tmp}/story.md"
    printf -- '---\ntype: Story\n---\n\n# Drill story\n\nBody.\n' > "$_story"
    sh "$_rec" "$_story" "handoff" "post_refused" "a line the transport refused" >/dev/null 2>&1 || true
    _held=$(sh "$_read" "$_story" 2>/dev/null || printf '')
    sh "$_rec" "$_story" "handoff" "post_refused" "a line the transport refused" >/dev/null 2>&1 || true
    _held_twice=$(sh "$_read" "$_story" 2>/dev/null || printf '')
    _sections=$(grep -c '^## Unposted Line' "$_story" 2>/dev/null || printf 0)
    case "$_held" in
        *"a line the transport refused"*)
            if [ "$_sections" -eq 1 ] && [ "$_held" = "$_held_twice" ]; then
                add_row "a_refused_line_is_carried_once" true "the refused line is readable back and re-recording replaces rather than stacks it" load
            else
                add_row "a_refused_line_is_carried_once" false "re-recording did not stay idempotent (sections=${_sections})" load
            fi ;;
        *) add_row "a_refused_line_is_carried_once" false "the refused line was not readable back: $(one_line "$_held")" load ;;
    esac

    # ---- 5. RESTARTING STARTS NO SECOND WORKER --------------------------------------------
    # The per-role lock is what replaces `ListAgents` off Claude Code, and it is the whole of
    # "no duplicate worker" for a restart: a role already running is refused by name.
    _repo="${_tmp}/consumer"
    _bin="${_tmp}/bin"
    mkdir -p "$_repo" "$_bin"
    git -C "$_repo" -c init.defaultBranch=main init -q
    git -C "$_repo" config user.email drill@example.com
    git -C "$_repo" config user.name 'Loop Drill'
    printf 'consumer\n' > "${_repo}/README.md"
    git -C "$_repo" add README.md
    git -C "$_repo" commit -q -m initial
    mkdir -p "${_repo}/plugins/workaholic/skills/work/scripts" "${_repo}/plugins/workaholic/commands"
    cp "$_cl" "${_repo}/plugins/workaholic/skills/work/scripts/codex-loop.sh"
    for _n in infinite-development implement propose moderate; do
        printf '# %s\n' "$_n" > "${_repo}/plugins/workaholic/commands/${_n}.md"
    done
    printf '# work\n' > "${_repo}/plugins/workaholic/skills/work/SKILL.md"
    printf '#!/bin/sh\nexit 0\n' > "${_bin}/codex"
    chmod +x "${_bin}/codex"
    _lockdir="${_repo}/.codex-loop"
    mkdir -p "$_lockdir"
    # Hold the role's lock the way a live worker does, then ask for a dispatch.
    if command -v flock >/dev/null 2>&1; then
        ( exec 8>"${_lockdir}/worker-implement.lock"; flock -n 8; sleep 5 ) &
        _holder=$!
        sleep 1
        _second=$(cd "$_repo" && PATH="${_bin}:$PATH" sh plugins/workaholic/skills/work/scripts/codex-loop.sh \
            --dispatch implement --dry-run --log "$_lockdir" 2>&1 || true)
        kill "$_holder" 2>/dev/null || true
        wait "$_holder" 2>/dev/null || true
        case "$_second" in
            *already_running*) add_row "a_restart_starts_no_second_worker" true "a role already running is refused by name rather than started twice" load ;;
            *) add_row "a_restart_starts_no_second_worker" false "a second dispatch was not refused: $(one_line "$_second")" load ;;
        esac
    else
        add_row "a_restart_starts_no_second_worker" true "flock is absent; the pid-file fallback is exercised by verify-codex-clock" load
    fi

    # ---- THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR ---------------------------------------
    # Not a return shape: a counter that ignores the recovery term is the exact regression this
    # drill exists to catch, so the breaker removes that term and requires the drill to notice.
    _broken="${_tmp}/claimable-broken.sh"
    sed 's/(\$m + \$b + \$r + \$recovery)/($m + $b + $r)/' "$_cu" > "$_broken"
    _bres=$(sh "$_broken" --survey "${_tmp}/s-und.json" --recovery "${_tmp}/rec-none.json" 2>/dev/null || printf '')
    case "$_bres" in
        *'"claimable":0'*) add_row "work_drain_breaker" true "dropping the recovery term makes the seeded backlog read as idle (this drill can fail)" breaker ;;
        *) add_row "work_drain_breaker" false "dropping the recovery term did not change the answer: $(one_line "$_bres")" breaker ;;
    esac

    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "work_drain_writes_nothing_outside_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "work_drain_writes_nothing_outside_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then emit_verdict "work-drain" 0 "fail" 1; fi
    emit_verdict "work-drain" 0 "pass" 0
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
