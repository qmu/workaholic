#!/bin/sh -eu
# The proposal batch's processed-commit cursor (docs/loop-engineering-workflow.md
# C2/A3): feedback records are immutable, so "new" is exactly "added between the
# cursor and origin/main".
#
# THE CURSOR IS A PUSHED REF, NOT A RUNNER-LOCAL FILE. It lives at
# `refs/workaholic/proposal-cursor` on origin, and the local ref of the same name
# is the read-through copy. Decision C1's "one server runs the batch, so the
# cursor may be runner-local" was falsified by the deployment it now runs in: the
# routine starts a FRESH CONTAINER every tick, so a runner-local file never
# exists there, every read bootstrapped, and the batch stopped at its own
# "initialized" report forever. The repository is already this project's
# coordination medium (the claim protocol reads claims from pushed branches), so
# the cursor is stored the same way and push is the race arbiter.
#
#   read              -> {"commit", "initialized", "fetched"[, "pushed"]}
#                        Fetches the shared ref. Absent on origin -> bootstrap it
#                        to origin/main HEAD (or to a legacy file's value) AND
#                        PUSH IT, so initialization happens once per repository
#                        rather than once per container. Unreachable origin ->
#                        degrade to the last-fetched local copy, reported as
#                        `fetched: false` (the reader degrades; a stale cursor
#                        only re-reads an old window, and dedup absorbs that).
#   advance <commit>  -> {"advanced": true, "commit"}
#                        Pushes under `--force-with-lease` against the value this
#                        batch read, so two racing runners resolve by push and
#                        never by clock. A lost race is a reported no-op
#                        ({"advanced": false, "reason": "raced"}, exit 0) — the
#                        winner already covered the window. A genuine push
#                        failure is loud (exit 1): the next tick re-reads the
#                        same window, which is the safe direction.
#
# MIGRATION (living, idempotent): a legacy `.workaholic/proposal-cursor` file is
# folded into the ref on first touch — it seeds the bootstrap when the shared ref
# is absent, and is removed once the ref holds the value — then never consulted
# again. The ignore line is ensured for as long as that file can still exist.
#
# Never prompts; never fails on a missing cursor (read bootstraps instead).

set -eu

REF="refs/workaholic/proposal-cursor"
MODE="${1:-read}"

TOP="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$TOP" ] || { echo '{"error": "not_a_git_repo"}'; exit 1; }
LEGACY="${TOP}/.workaholic/proposal-cursor"

has_origin() { git remote get-url origin >/dev/null 2>&1; }

# The shared ref's value on origin. Prints the sha (empty when the ref is absent)
# and exits non-zero ONLY when origin could not be reached — so a caller can tell
# "no cursor yet" from "I could not look", which are opposite situations.
remote_value() {
    _ls=$(git ls-remote origin "$REF" 2>/dev/null) || return 1
    printf '%s\n' "$_ls" | awk 'NR==1 {print $1}'
}

local_value() { git rev-parse --verify -q "${REF}" 2>/dev/null || true; }

legacy_value() {
    [ -f "$LEGACY" ] || return 0
    _c=$(head -n 1 "$LEGACY" | tr -d '[:space:]')
    [ -n "$_c" ] || return 0
    git rev-parse --verify -q "${_c}^{commit}" >/dev/null 2>&1 || return 0
    git rev-parse "${_c}^{commit}"
}

# The legacy file is superseded the moment the ref holds a value.
fold_legacy() { rm -f "$LEGACY" 2>/dev/null || true; }

bootstrap_seed() {
    _s=$(git rev-parse --verify -q origin/main 2>/dev/null || true)
    [ -n "$_s" ] || _s=$(git rev-parse --verify -q main 2>/dev/null || true)
    [ -n "$_s" ] || _s=$(git rev-parse HEAD)
    printf '%s\n' "$_s"
}

# Adopt a known-remote value locally: fetch brings the objects, update-ref covers
# a fetch that failed after ls-remote succeeded. Neither is fatal — the sha is
# already known and is what the caller acts on.
adopt() {
    git fetch -q origin "+${REF}:${REF}" 2>/dev/null || git update-ref "$REF" "$1" 2>/dev/null || true
}

ensure_legacy_ignored() {
    COMMON="$(git rev-parse --git-common-dir 2>/dev/null || echo "${TOP}/.git")"
    case "$COMMON" in /*) : ;; *) COMMON="${TOP}/${COMMON}" ;; esac
    mkdir -p "${COMMON}/info"
    EXCLUDE="${COMMON}/info/exclude"
    if [ ! -f "$EXCLUDE" ] || ! grep -qxF '.workaholic/proposal-cursor' "$EXCLUDE"; then
        printf '%s\n' '.workaholic/proposal-cursor' >> "$EXCLUDE"
    fi
}

case "$MODE" in
    read)
        ensure_legacy_ignored
        if has_origin && RV=$(remote_value); then
            if [ -n "$RV" ]; then
                adopt "$RV"
                fold_legacy
                printf '{"commit": "%s", "initialized": false, "fetched": true}\n' "$RV"
                exit 0
            fi
            # Absent on origin: born once for the whole repository, not once per
            # container. Pre-existing feedback is treated as already-seen (a safe
            # cold start; replay is a human `git push --force` on the ref).
            SEED=$(legacy_value)
            [ -n "$SEED" ] || SEED=$(bootstrap_seed)
            if git push -q origin "${SEED}:${REF}" 2>/dev/null; then
                git update-ref "$REF" "$SEED"
                fold_legacy
                printf '{"commit": "%s", "initialized": true, "fetched": true, "pushed": true}\n' "$SEED"
                exit 0
            fi
            # The push lost: either another runner created the ref in the same
            # instant, or this runner cannot write. Adopt a winner if there is
            # one; otherwise say plainly that the value is local-only.
            RV2=$(remote_value || true)
            if [ -n "${RV2:-}" ]; then
                adopt "$RV2"
                fold_legacy
                printf '{"commit": "%s", "initialized": false, "fetched": true}\n' "$RV2"
                exit 0
            fi
            git update-ref "$REF" "$SEED"
            printf '{"commit": "%s", "initialized": true, "fetched": true, "pushed": false}\n' "$SEED"
            exit 0
        fi
        # No origin, or origin unreachable: the reader degrades to the
        # last-fetched copy and says so, rather than pretending to a fresh read.
        LV=$(local_value)
        [ -n "$LV" ] || LV=$(legacy_value)
        if [ -n "$LV" ]; then
            git update-ref "$REF" "$LV"
            printf '{"commit": "%s", "initialized": false, "fetched": false}\n' "$LV"
            exit 0
        fi
        SEED=$(bootstrap_seed)
        git update-ref "$REF" "$SEED"
        printf '{"commit": "%s", "initialized": true, "fetched": false, "pushed": false}\n' "$SEED"
        ;;
    advance)
        NEW="${2:-}"
        [ -n "$NEW" ] || { echo '{"advanced": false, "reason": "no_commit"}'; exit 1; }
        if ! git rev-parse --verify -q "${NEW}^{commit}" >/dev/null 2>&1; then
            printf '{"advanced": false, "reason": "unknown_commit", "commit": "%s"}\n' "$NEW"
            exit 1
        fi
        NEW=$(git rev-parse "${NEW}^{commit}")

        if ! has_origin; then
            git update-ref "$REF" "$NEW"
            printf '{"advanced": true, "commit": "%s", "pushed": false, "reason": "no_origin"}\n' "$NEW"
            exit 0
        fi

        EXPECT=$(local_value)
        if [ -n "$EXPECT" ]; then
            set -- push -q origin "--force-with-lease=${REF}:${EXPECT}" "${NEW}:${REF}"
        else
            set -- push -q origin "${NEW}:${REF}"
        fi
        if git "$@" 2>/dev/null; then
            git update-ref "$REF" "$NEW"
            printf '{"advanced": true, "commit": "%s"}\n' "$NEW"
            exit 0
        fi
        # A rejected push is either a lost race or a real failure, and the two
        # need opposite reactions — so ask the remote rather than parsing git's
        # error text.
        if RV=$(remote_value) && [ -n "$RV" ] && [ "$RV" != "${EXPECT:-}" ]; then
            adopt "$RV"
            printf '{"advanced": false, "reason": "raced", "commit": "%s"}\n' "$RV"
            exit 0
        fi
        printf '{"advanced": false, "reason": "push_failed", "commit": "%s"}\n' "$NEW"
        exit 1
        ;;
    *)
        echo '{"error": "bad_mode"}' >&2
        exit 1
        ;;
esac
