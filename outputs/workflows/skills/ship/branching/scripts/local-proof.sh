#!/bin/sh -eu
# The ONE declaration of the local proof set a main-bound merge stands on, and the one
# runner of it.
#
# Usage: local-proof.sh [--repo <path>] [--log-dir <path>] [--list]
# Output: one JSON line, ALWAYS exit 0
#   {"readable": bool, "repo": "...", "ok": bool, "complete": bool,
#    "checks": [{"name","required","ran","ok","seconds","log","reason"}],
#    "not_run": ["<name>: <reason>", ...], "failed": ["<name>", ...],
#    "scratch": {"used": bool, "path": "...", "reason": "..."}}
#
# WHY IT EXISTS (2026-09-19, ticket `20260919230700`). `merge-gate-policy.sh` answers
# `remote_checks_required: false` for `main`, and `branch-checks.sh` emits
# `pass development_main_local_proof` before it ever reaches a check reader. That is the
# RECORDED DESIGN — *`main` is the continuously auto-merged development branch and quality is
# gated at the `release/*` QA window* (`CLAUDE.md`, *The release tier*) — and this script does
# not touch it. What was missing is the thing the word asserts: the substitute. Nothing
# anywhere established that any local proof ran, still less WHICH one.
#
# MEASURED, 2026-09-19 (workflow `Validate Plugins`, id 223779125, read over REST): seven
# consecutive first-parent commits on `main` failed it — `f195a667f`, `915e115fd`,
# `6dcf73b41`, `d28e34429`, `52964b8c8`, `eb795c92f`, `3243c1c4f` — from 10:10:40Z to
# 11:45:28Z. The failing step on both ends of that range is job `validate`, step 9,
# "Test agentic loop contracts and consumers" — a command NEITHER of the two hard-coded
# pre-push lists ran. Those lists (`drive/scripts/catch-up-claim.sh` and
# `branching/scripts/prepare-publication.sh`) spelled the same three checks twice, were a
# strict subset of CI's `validate` job, and no report named which of them a unit executed.
#
# THE SET IS SPELLED HERE AND NOWHERE ELSE. It is the `validate` job's own repository
# commands plus `build-plugins/verify.mjs` (the `Outputs Freshness` gate the two former lists
# already carried) and the hermetic drill entry point `loop-drills.yml` runs on push.
# `scripts/test-workflow-scripts.mjs` pins the declaration against `validate-plugins.yml`, so
# a step added to CI and not here fails the suite.
#
# A CHECK THAT DID NOT RUN IS ITS OWN STATE AND NEVER A SOFT PASS, the rule `workaholic:ship`
# already holds for a deployment (*A failed or pending deployment is its own state*). Three
# fields, never collapsed:
#   * `ok`       — no check RAN AND FAILED. This is what a caller refuses on, and it keeps
#                  every existing `validation_failed:<check>` refusal byte-identical.
#   * `complete` — every REQUIRED check ran. An incomplete set is REPORTED, never a refusal:
#                  the two former lists skipped an absent check silently (`[ -f ] || continue`)
#                  and a consuming repository that carries none of these files must keep
#                  pushing exactly as it did. What changes is that the skip is now named.
#   * `not_run`  — one line per check that did not run, with its own reason
#                  (`not_selected`, `check_absent`, `interpreter_unavailable:<tok>`,
#                  `timeout:<n>s`). A check the kernel KILLED is not one of these: it ran,
#                  proved nothing, and is a `failed` row reading `killed:SIGKILL` — see below.
#
# EVERY CHECK RUNS, INCLUDING AFTER ONE HAS FAILED. Stopping at the first failure would make
# `not_run` mean two different things — *this could not run* and *we stopped early* — which is
# exactly the confusion this script exists to end. The stated cost is that a doomed push spends
# the whole set's wall clock before it is refused; a passing push spends the same either way.
#
# THE CHECKS RUN IN A CLEAN ENVIRONMENT, and that is not tidiness — it is
# `catch-up-claim.sh`'s own measured ruling, carried here so it holds at every call site rather
# than at one. A caller reaches this through the claim protocol's tunables
# (`WORKAHOLIC_CLAIM_STALE_HOURS`, `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`,
# `WORKAHOLIC_CLAIM_MERGED_LOOKUP`) and a repository's suite may legitimately assert on their
# DEFAULTS: a caller collapsing the heartbeat window turned 16 claim-protocol assertions red
# and refused a push over a branch whose suite passed.
#
# THE OUTPUT IS KEPT, NOT PRINTED — `catch-up-claim.sh`'s second ruling, carried here for the
# same reason. A refusal that discards its output cannot be diagnosed: `>/dev/null 2>&1` threw
# away the only evidence of WHY a check went red, and under the loop's subagents several runs
# share a multi-minute suite on one machine, so a check can lose to load in a way no
# single-session premise ever shows. Each check's bytes go to a log file whose path rides that
# check's row; a PASSING check's log is removed, so only what a reader needs survives.
# `prepare-publication.sh` discarded its output outright and gains the log by composing this.
#
# A KILLED REQUIRED CHECK REFUSES, AND IS NOT A TIMEOUT (2026-09-20, ticket `20260920014750`).
# Status `137` is `128 + SIGKILL` and was folded into the `124` arm, so a check the kernel ended
# part-way reported `ran: false`, `reason: "timeout:0s"` on a row declaring NO timeout, landed in
# `not_run` rather than `failed`, and left `ok: true` — a pass, over a check that proved nothing.
# MEASURED 2026-09-20 with a throwaway repository whose `verify.mjs` is
# `process.kill(process.pid, "SIGKILL")`: `{"ok": true, "complete": false,
# "not_run": ["verify.mjs: timeout:0s"], "failed": []}`, while the same command run directly
# exits 137. Both consumers refuse on `ok: false` alone, so that push went through.
#
# THE SPLIT IS ON WHETHER A TIMEOUT WAS APPLIED, never on the status alone. GNU `timeout` exits
# `137` when its own `--kill-after` escalation had to SIGKILL the child, so for a row that
# DECLARES a timeout `124` and `137` are one reading and stay byte-identical — that is the
# measured `agentic-loop.test.mjs` case this file's declaration comment records. For a row
# declaring `timeout 0` no timeout ran at all, so `137` is an external kill: it is
# `ran: true, ok: false, reason: "killed:SIGKILL"`, joins `failed`, and refuses through the
# existing `validation_failed:<check>` word.
#
# WHY A FAILURE RATHER THAN A THIRD REFUSING TERM (the ticket's `## Open Decisions`, decided
# here). `complete: false` is reported and never refuses, and BOTH sources that state that rule
# — this header above, and `drive/scripts/catch-up-claim.sh`'s own comment — give the same one
# reason for it: *a consuming repository that carries none of these files must keep pushing
# exactly as it did*. That reason is about `check_absent`. A kill is not that: the check is
# present, it started, and something ended it. Adding a `killed` term to `not_run` would make
# two consumers grow an arm they can forget to read, which is the defect this ticket is about,
# so the refusal takes a path no consumer can miss. `ran: true` is honest under this script's
# own semantics — `ran: false` is reserved for a check that was never launched (`not_selected`,
# `check_absent`, `interpreter_unavailable`) — and the reason string carries the signal, so the
# record loses no accuracy. STATED COST: a consuming repository on a constrained machine now
# gets refusals it did not get before. That is the correct direction — a refusal is retried, a
# push on an unproved check is not.
#
# THE CHECKS RUN UNDER A TMPDIR THIS SCRIPT OWNS, and that is mitigation, NOT the repair above.
# `test-workflow-scripts.mjs`, all 16 files under `scripts/tests/agentic-loop/` and
# `scripts/e2e/loop-drill.sh` create throwaway repositories under the OS temp directory, and
# nothing anywhere declared one. MEASURED on this machine the same morning: `/tmp` is **tmpfs**
# with no swap — `free -m` total 7,767, shared 2,146, available 825 — so 2.1 G of the machine's
# memory is the temp filesystem, permanently, for every process on it, with 89,959 top-level
# entries and up to 7 concurrent copies of the same multi-minute suite. A per-run directory
# under `LOG_DIR` (inside the git directory, never committed) is exported as `TMPDIR` around
# each check and removed when the run ends. `os.tmpdir()` reads `TMPDIR` on POSIX and so does
# `mktemp`, so every check that creates fixtures honours it; `verify.mjs` and
# `validate-metadata.mjs` create no temporary files and are unaffected either way.
# IT REDUCES PRESSURE AND DOES NOT REMOVE IT — the abort that produced this ticket was measured
# with `TMPDIR` ALREADY on local disk. A later reader must not take it for the fix.
#
# IT RUNS NOTHING OUTWARD. No network read, no push, no merge, no ref written, no gate.

PROG_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

REPO=""
LOG_DIR=""
LIST=false
# `--only <name>` narrows the run to one declared row. It exists so the set's own behaviour can
# be PROBED — a failing check, an absent interpreter — without spending the whole set's wall
# clock, and it narrows nothing a caller relies on: no call site passes it, and a narrowed run
# reports every other row `ran: false, reason: not_selected`, so `complete` goes false and the
# reading can never be mistaken for a full proof.
ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO=${2:-}; shift 2 ;;
        --log-dir) LOG_DIR=${2:-}; shift 2 ;;
        --only) ONLY=${2:-}; shift 2 ;;
        --list) LIST=true; shift ;;
        *) shift ;;
    esac
done

json_str() { printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' | tr -d '\n\r'; }

unreadable() {
    printf '{"readable": false, "reason": "%s", "repo": "%s", "ok": null, "complete": null, "checks": null, "not_run": null, "failed": null}\n' \
        "$(json_str "$1")" "$(json_str "${REPO:-}")"
    exit 0
}

# --- THE DECLARATION -----------------------------------------------------------------
# Fields, separated by `|@|`: name | required | timeout_seconds (0 = none) | probe path |
# command. The name is what a caller's `validation_failed:<name>` refusal carries, so the
# first three are spelled exactly as the two retired lists spelled them and no caller's `case`
# arm moves.
#
# `timeout` carries CI's OWN bound where CI declares one, so a check cannot pass here on a
# budget CI will not give it. A timeout is a `ran: false` reason of its own rather than a
# failure — the kept log is what makes the next occurrence readable.
#
# MEASURED ON THIS SET'S OWN FIRST FULL RUN (2026-09-19, this machine, ~20 concurrent loop
# runners): `agentic-loop.test.mjs` answered `130 passed, 0 failed, 1 cancelled` at
# `duration_ms 299847` and was killed at its 300s bound, reported `ran: false`,
# `reason: timeout:300s`, `complete: false` — while the same suite run alone on the same tree
# in the same hour answered `163 passed, 0 failed` in 115s. That is the stated cost behaving as
# designed rather than a defect: the set says it did not prove that check and names why, and
# the kept log carries the bytes. The bound is NOT raised past CI's own — a check that needs
# more time here than CI will give it has not been proved for the merge CI gates.
proof_set() {
    cat <<'DECL'
verify.mjs|@|true|@|0|@|scripts/build-plugins/verify.mjs|@|node scripts/build-plugins/verify.mjs
validate-metadata.mjs|@|true|@|0|@|scripts/build-plugins/validate-metadata.mjs|@|node scripts/build-plugins/validate-metadata.mjs
layout-doctor.sh|@|true|@|0|@|plugins/workaholic/hooks/layout-doctor.sh|@|r=$(bash plugins/workaholic/hooks/layout-doctor.sh .); printf '%s\n' "$r"; [ "$(printf '%s' "$r" | jq -r '.conforming')" = true ]
agentic-loop.test.mjs|@|true|@|300|@|scripts/tests/agentic-loop|@|node --test scripts/tests/agentic-loop/*.test.mjs
test-workflow-scripts.mjs|@|true|@|0|@|scripts/test-workflow-scripts.mjs|@|node scripts/test-workflow-scripts.mjs
loop-drill-hermetic|@|true|@|0|@|scripts/e2e/loop-drill.sh|@|sh scripts/e2e/loop-drill.sh verify-all --kind hermetic
DECL
}

if [ "$LIST" = true ]; then
    # The whole render happens inside the pipeline's own subshell, so the separator survives
    # between rows — a `while` loop fed by a pipe cannot hand a variable back to its caller.
    proof_set | {
        printf '{"readable": true, "checks": ['
        sep=""
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            name=${line%%|@|*}; rest=${line#*|@|}
            req=${rest%%|@|*}; rest=${rest#*|@|}
            tmo=${rest%%|@|*}; rest=${rest#*|@|}
            probe=${rest%%|@|*}; cmd=${rest#*|@|}
            printf '%s{"name": "%s", "required": %s, "timeout": %s, "probe": "%s", "command": "%s"}' \
                "$sep" "$(json_str "$name")" "$req" "$tmo" "$(json_str "$probe")" "$(json_str "$cmd")"
            sep=", "
        done
        printf ']}\n'
    }
    exit 0
fi

# --- The repository ------------------------------------------------------------------
if [ -n "$REPO" ]; then
    [ -d "$REPO" ] || unreadable repo_not_found
    REPO=$(CDPATH='' cd -- "$REPO" && pwd)
else
    REPO=$(git -C "$PROG_DIR" rev-parse --show-toplevel 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || printf '')
    [ -n "$REPO" ] || unreadable not_a_repository
fi
[ -d "$REPO" ] || unreadable repo_unreadable

# THE LOGS STAY INSIDE THE REPOSITORY'S OWN GIT DIRECTORY. `catch-up-claim.sh` wrote them beside
# its worktree, which is always under the git-ignored `.worktrees/`; a bare run from the main
# checkout has no such parent, and the same default would put them in the directory ABOVE the
# repository. The git directory is present for a worktree and a main checkout alike, is never
# committed, and already hosts the loop's own clone-local store (`.git/workaholic/runtime/`).
if [ -z "$LOG_DIR" ]; then
    LOG_DIR=$(git -C "$REPO" rev-parse --absolute-git-dir 2>/dev/null || printf '')
    [ -n "$LOG_DIR" ] || unreadable log_dir_unresolved
    LOG_DIR="${LOG_DIR}/workaholic"
    mkdir -p "$LOG_DIR" 2>/dev/null || unreadable log_dir_unwritable
fi
[ -d "$LOG_DIR" ] || unreadable log_dir_unwritable
# Resolved once, so a row's `log` is a path a reader can open rather than one carrying `..`.
LOG_DIR=$(CDPATH='' cd -- "$LOG_DIR" && pwd)

DECL_FILE="${LOG_DIR}/.local-proof-declaration.$$"
proof_set >"$DECL_FILE" 2>/dev/null || unreadable declaration_unreadable
[ -s "$DECL_FILE" ] || { rm -f "$DECL_FILE"; unreadable declaration_empty; }

# --- The scratch directory the checks run under --------------------------------------
# IT MUST BE OUTSIDE EVERY GIT REPOSITORY, and that is a MEASUREMENT rather than a preference.
# The obvious home is beneath `LOG_DIR`, inside the git directory — and putting it there breaks
# a required check in this very set: `scripts/tests/agentic-loop/legacy-contracts.test.mjs`
# asserts the *outside-repo refusal* of four publication scripts, so its fixture must not be
# inside a repository, and a `TMPDIR` under `.git/` makes git resolve the enclosing gitdir and
# answer `fatal: this operation must be run in a work tree` (status 128) where the test expects
# `{"error": "not inside a git repository"}` (status 1). MEASURED 2026-09-20: the same file
# exits 0 with `TMPDIR` on plain local disk and 1 with it under `.git/`. Every path inside the
# repository fails the same way, so the scratch directory lives under the user's cache — local
# disk, off the shared tmpfs, and on no ref — and the script PROVES that before using it.
#
# AND THE FALL-BACK IS NAMED, NEVER SILENT AND NEVER A REFUSAL. This half is mitigation: the
# repair is the killed-check reading above. A scratch directory that cannot be created, or that
# turns out to be inside a repository, leaves `TMPDIR` exactly as the caller set it and says so
# in `scratch` — refusing the whole proof over a temp directory would stop every merge the loop
# makes for a tidiness measure, which is a worse failure than the pressure it saves.
SCRATCH_DIR=""
SCRATCH_USED=false
SCRATCH_REASON=""
cleanup_scratch() { [ -z "${SCRATCH_DIR:-}" ] || rm -rf "$SCRATCH_DIR" 2>/dev/null || :; }
trap cleanup_scratch EXIT

_scratch_base="${XDG_CACHE_HOME:-${HOME:-}/.cache}"
if [ -z "${HOME:-}" ] && [ -z "${XDG_CACHE_HOME:-}" ]; then
    SCRATCH_REASON=no_cache_home
elif ! mkdir -p "${_scratch_base}/workaholic" 2>/dev/null; then
    SCRATCH_REASON=scratch_dir_unwritable
else
    _scratch_try="${_scratch_base}/workaholic/proof-tmp.$$"
    if ! mkdir -p "$_scratch_try" 2>/dev/null || [ ! -w "$_scratch_try" ]; then
        SCRATCH_REASON=scratch_dir_unwritable
        rm -rf "$_scratch_try" 2>/dev/null || :
    elif git -C "$_scratch_try" rev-parse --git-dir >/dev/null 2>&1; then
        # The one thing that would silently reintroduce the measured break.
        SCRATCH_REASON=scratch_dir_inside_repository
        rm -rf "$_scratch_try" 2>/dev/null || :
    else
        SCRATCH_DIR="$_scratch_try"
        SCRATCH_USED=true
    fi
fi

ROWS=""
NOT_RUN=""
FAILED=""
SET_OK=true
SET_COMPLETE=true

while IFS= read -r line; do
    [ -n "$line" ] || continue
    name=${line%%|@|*}; rest=${line#*|@|}
    required=${rest%%|@|*}; rest=${rest#*|@|}
    timeout_s=${rest%%|@|*}; rest=${rest#*|@|}
    probe=${rest%%|@|*}; cmd=${rest#*|@|}

    ran=false
    ok=false
    seconds=0
    log=""
    reason=""

    # A check the repository does not carry, and an interpreter that is not here, are each
    # their own reason. Neither is a silent skip and neither is `ok: true`.
    # A command the declaration spells as a shell expression rather than as a bare
    # invocation is run by `sh`, so `sh` is the interpreter whose absence would stop it.
    lead=${cmd%% *}
    case "$lead" in *=*|*'$'*|*'('*|*'"'*) lead=sh ;; esac
    if [ -n "$ONLY" ] && [ "$name" != "$ONLY" ]; then
        reason=not_selected
    elif [ ! -e "${REPO}/${probe}" ]; then
        reason=check_absent
    elif ! command -v "$lead" >/dev/null 2>&1; then
        reason="interpreter_unavailable:${lead}"
    else
        log="${LOG_DIR}/.local-proof-${name}.log"
        started=$(date +%s 2>/dev/null || printf 0)
        status=0
        # `timed` records whether a timeout was actually APPLIED, which is what tells a
        # timeout's own SIGKILL escalation from an external kill; the status alone cannot.
        timed=false
        if [ "$timeout_s" != 0 ] && command -v timeout >/dev/null 2>&1; then
            timed=true
            ( cd "$REPO" \
              && unset WORKAHOLIC_CLAIM_STALE_HOURS WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES \
                       WORKAHOLIC_CLAIM_MERGED_LOOKUP \
              && { [ "$SCRATCH_USED" = false ] || { TMPDIR="$SCRATCH_DIR"; export TMPDIR; }; } \
              && timeout --signal=TERM --kill-after=30s "$timeout_s" sh -c "$cmd" ) \
                >"$log" 2>&1 || status=$?
        else
            ( cd "$REPO" \
              && unset WORKAHOLIC_CLAIM_STALE_HOURS WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES \
                       WORKAHOLIC_CLAIM_MERGED_LOOKUP \
              && { [ "$SCRATCH_USED" = false ] || { TMPDIR="$SCRATCH_DIR"; export TMPDIR; }; } \
              && sh -c "$cmd" ) >"$log" 2>&1 || status=$?
        fi
        finished=$(date +%s 2>/dev/null || printf 0)
        seconds=$(( finished - started ))
        [ "$seconds" -ge 0 ] || seconds=0
        case "$status" in
            0)   ran=true; ok=true; rm -f "$log"; log="" ;;
            124) reason="timeout:${timeout_s}s" ;;
            # `137` is `128 + SIGKILL`. Under an APPLIED timeout it is that timeout's own
            # `--kill-after` escalation and keeps the timeout reading, byte-identical. With no
            # timeout applied nothing here killed it, so it is an external kill: the check
            # started, produced no verdict, and REFUSES as a failure.
            137) if [ "$timed" = true ]; then
                     reason="timeout:${timeout_s}s"
                 else
                     ran=true; reason="killed:SIGKILL"
                 fi ;;
            *)   ran=true; reason="exit:${status}" ;;
        esac
    fi

    if [ "$ran" = false ]; then
        NOT_RUN="${NOT_RUN}${NOT_RUN:+, }\"$(json_str "${name}: ${reason}")\""
        [ "$required" != true ] || SET_COMPLETE=false
    elif [ "$ok" = false ]; then
        SET_OK=false
        FAILED="${FAILED}${FAILED:+, }\"$(json_str "$name")\""
    fi

    ROWS="${ROWS}${ROWS:+, }{\"name\": \"$(json_str "$name")\", \"required\": ${required}, \"ran\": ${ran}, \"ok\": ${ok}, \"seconds\": ${seconds}, \"log\": \"$(json_str "$log")\", \"reason\": \"$(json_str "$reason")\"}"
done <"$DECL_FILE"

rm -f "$DECL_FILE"

printf '{"readable": true, "repo": "%s", "ok": %s, "complete": %s, "checks": [%s], "not_run": [%s], "failed": [%s], "scratch": {"used": %s, "path": "%s", "reason": "%s"}}\n' \
    "$(json_str "$REPO")" "$SET_OK" "$SET_COMPLETE" "$ROWS" "$NOT_RUN" "$FAILED" \
    "$SCRATCH_USED" "$(json_str "$SCRATCH_DIR")" "$(json_str "$SCRATCH_REASON")"
exit 0
