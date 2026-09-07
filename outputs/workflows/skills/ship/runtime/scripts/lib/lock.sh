#!/bin/sh

# Acquire one process-local exclusion lock. flock is preferred because the
# kernel releases it after every kind of process death. The portable fallback
# uses atomic mkdir and removes it only on an orderly exit; an abandoned lock is
# deliberately fail-closed because PID or mtime evidence cannot make deletion
# race-free in POSIX shell.
runtime_lock_acquire() {
    RUNTIME_LOCK_PATH=$1
    RUNTIME_LOCK_FD=${2:-9}
    RUNTIME_LOCK_WAIT=${3:-false}
    if [ "${WORKAHOLIC_LOCK_BACKEND:-auto}" != mkdir ] && command -v flock >/dev/null 2>&1; then
        RUNTIME_LOCK_BACKEND=flock
        : >"$RUNTIME_LOCK_PATH"
        eval "exec ${RUNTIME_LOCK_FD}>\"\$RUNTIME_LOCK_PATH\""
        if [ "$RUNTIME_LOCK_WAIT" = true ]; then flock -w 2 "$RUNTIME_LOCK_FD"; else flock -n "$RUNTIME_LOCK_FD"; fi
    else
        RUNTIME_LOCK_BACKEND=mkdir
        RUNTIME_LOCK_PATH="${RUNTIME_LOCK_PATH}.d"
        tries=0
        while ! mkdir "$RUNTIME_LOCK_PATH" 2>/dev/null; do
            [ "$RUNTIME_LOCK_WAIT" = true ] || return 1
            tries=$((tries + 1)); [ "$tries" -lt 200 ] || return 1
            sleep 0.01
        done
    fi
}

runtime_lock_release() {
    case "${RUNTIME_LOCK_BACKEND:-}" in
        flock) eval "exec ${RUNTIME_LOCK_FD}>&-" ;;
        mkdir) rmdir "$RUNTIME_LOCK_PATH" 2>/dev/null || true ;;
    esac
    RUNTIME_LOCK_BACKEND=
}
