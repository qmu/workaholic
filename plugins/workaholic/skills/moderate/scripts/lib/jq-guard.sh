#!/bin/sh
# Record a jq COMPILE error so a step that could not run its own reading stops
# reading as a step that looked and found nothing.
#
# WHY IT EXISTS (2026-08-29, mission `make-a-direction-s-lifecycle-a-declared-stage`).
# Every reader in this skill is written around one rule — *a read we could not make must
# never render as a reading we made* — and the shape that breaks it is everywhere:
#
#     subjects=$(printf '%s' "$STATE" | jq -c '…' 2>/dev/null || echo '[]')
#
# The fallback is CORRECT for a data problem and CATASTROPHIC for our own: a jq program
# that does not compile discards the same way, so the step emits `[]` and reports
# `status: ok`. Measured while shipping *Show a direction's stage where directions are
# read*: `step-direction-health.sh` reported `1 expiring … 1 to ask` with the expiring
# direction's own question silently gone, because one missing parenthesis inside the
# embedded program made the whole expression uncompilable. `sh -n` passes (the shell
# parses fine — it is the embedded jq that does not), so the suite's own
# `every shipped shell script parses` row provably does not catch it.
#
# THE TWO CASES ARE TOLD APART BY jq'S OWN EXIT STATUS, not by a new convention: jq
# answers **3** for a compile error, 5 for a runtime or input error, 1 for `-e` with a
# null/false result, 0 for success. Exit 3 means the program itself is wrong — our defect,
# the step cannot run at all. Everything else is a fact about the data and keeps every
# existing fallback exactly as it was.
#
# A SHADOWING FUNCTION RATHER THAN 58 EDITED CALL SITES. The defect is the SHAPE, not the
# file (the ticket's own Consideration), and this repository carries the shape at 58
# reachable call sites across 18 scripts — many multi-line, several inside `$( … )` command
# substitutions. Editing each is 58 chances to write the classification differently; a
# function named `jq` is adopted by every one of them, present and future, at one `.` line
# per script. It calls `command jq`, so there is no recursion, and it is a shell function,
# so it is NOT exported to child processes: a script's guard covers that script's own
# embedded programs and nothing else. A child that wants the same cover sources this file
# itself, which is why the helper scripts a step shells out to source it too.
#
# BEHAVIOUR IS BYTE-IDENTICAL apart from the record. Stdin, stdout, stderr, arguments and
# the exit status all pass through untouched — nothing is captured, redirected or
# suppressed, so the caller's own `2>/dev/null` keeps deciding who sees jq's words. That
# redirection is deliberately NOT removed (the ticket's step 6: the stderr of a
# legitimately degraded read is noise on an hourly unattended run, and the fix is to
# classify, not to shout).
#
# WHAT THE RECORD CARRIES, AND WHY THAT IS ENOUGH. One line naming the script whose
# program failed to compile — not jq's message, which is on a stderr this function
# deliberately does not touch. The two surfaces divide the job: at RUN time the loop needs
# to know that this step's reading is worthless, which the script name answers; at BUILD
# time the suite's `every embedded jq program compiles` row names the exact program and
# jq's own words, before the tick ever runs.
#
# ONE DERIVATION OF "THIS STEP COULD NOT READ". This file only RECORDS; nothing here
# decides what a compile error means for a step's status. `run.sh` is the one place that
# reads the record and reclassifies the step `degraded` with reason `jq_compile_error`,
# beside the `step_missing` / `step_error` / `no_output` / `bad_output` it already owns. A
# step consulting the record for itself would be a second derivation of the same fact.
#
# WHEN NOTHING IS LISTENING it is inert: with `WORKAHOLIC_JQ_COMPILE_ERRORS` unset (a step
# run by hand, a drill invoking a script directly) the wrapper is a pass-through and the
# script behaves exactly as it did.

# Installed once, however many libraries source this file.
if [ -z "${_JQ_GUARD_INSTALLED:-}" ]; then
    _JQ_GUARD_INSTALLED=1

    jq() {
        _jqg_rc=0
        command jq "$@" || _jqg_rc=$?
        # 3 is jq's own "compile error" — the one status that means the program, not the
        # data, is wrong. Appended, never truncated here: `run.sh` owns the file's life.
        if [ "$_jqg_rc" -eq 3 ] && [ -n "${WORKAHOLIC_JQ_COMPILE_ERRORS:-}" ]; then
            printf '%s\n' "$(basename -- "$0")" >> "$WORKAHOLIC_JQ_COMPILE_ERRORS" 2>/dev/null || true
        fi
        return "$_jqg_rc"
    }
fi
