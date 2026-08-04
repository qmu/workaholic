#!/bin/sh -eu
# Catch the current work branch up with origin/<base> before deploy, so the
# artifact that gets deployed and confirmed equals what will land on merge.
# Fetches origin and merges origin/<base> into the current branch.
#
# Catching up is MANDATORY before any deploy step (a stale branch either reverts
# merged work or, for an idempotent deploy-on-merge release, silently no-ops it).
# On conflict this classifies the conflict so the ship flow can act deterministically:
#   - APPEND-ONLY: a `.workaholic/` artifact both sides only appended to (a mission
#     `## Changelog`, an OKF `index.md`). Reconciled HERE, by keeping both sides --
#     there is no behavioural judgement to make. See lib/append-only.sh for why the
#     scope is ruled by path and the resolution by conflict shape.
#   - "mechanical": every remaining conflicted path is a version/lockstep manifest or
#     under outputs/ — routine reconciliation the agent performs itself (merge,
#     resolve, re-run the pre-merge proof, re-bump the version past any collision).
#   - "content": some other path conflicts — a human must judge it; halt and ask.
#
# THE APPEND-ONLY PASS EXISTS BECAUSE THE CLASSIFIER WAS COSTING MERGES. Measured on
# a ship where the base had advanced by one merged unit: seven files conflicted, five
# were manifests already classed mechanical, and TWO were `.workaholic/` append-only
# files. Those two alone forced the whole catch-up to `content` — which interactively
# costs one prompt, but in the unattended `/drive` run demotes an `auto` unit to the
# PR path to wait for a human. And it recurred on every concurrent pair of units,
# because both sides always append to the mission changelog and the story index.
# A classifier that reports "needs human judgement" for a case it can decide trains
# the reader to override it on sight, which is how a genuine content conflict
# eventually gets waved through.
#
# The merge is completed when NOTHING is left unmerged after that pass, and aborted
# otherwise, so the caller always acts from a clean tree. An abort discards the
# append-only resolutions too — they are reported as `append_only_files` so the agent
# redoing a `mechanical` merge knows which paths it may simply keep both sides of.
#
# What this reports is HONEST about scope: it reconciles the current WORK BRANCH with
# origin/<base>. It does NOT touch — and makes no claim about — the local `main` ref
# (on the desk layout a worktree cannot move the `main` another worktree pins, and
# catch-up does not try to). So the "already up to date" answer below is named for the
# work branch, not for `main`: `branch_up_to_date` is true iff merging origin/<base>
# into the branch was a no-op. It deliberately does NOT say "main is current" — an
# earlier `already_current` field did, and read as a currency it never verified.
#
# Usage: bash catchup-main.sh [base-branch]   (default base: main)
# Output: JSON
#   {"caught_up": true,  "base": "main", "branch_up_to_date": true|false,
#    "resolved_append_only": ["..."]}
#   {"caught_up": false, "base": "main", "conflict": true,
#    "conflict_class": "mechanical"|"content", "conflicted_files": ["..."],
#    "append_only_files": ["..."]}

set -eu

base="${1:-main}"

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/append-only.sh"

git fetch origin "$base" --quiet 2>/dev/null || git fetch origin --quiet

before=$(git rev-parse HEAD)

# Render a newline-separated file list as a JSON array body.
json_list() {
    printf '%s\n' "$1" | awk 'NF{ printf "%s\"%s\"", sep, $0; sep="," }'
}

if git merge --no-edit "origin/${base}" >/dev/null 2>&1; then
    after=$(git rev-parse HEAD)
    if [ "$before" = "$after" ]; then
        printf '{"caught_up": true, "base": "%s", "branch_up_to_date": true, "resolved_append_only": []}\n' "$base"
    else
        printf '{"caught_up": true, "base": "%s", "branch_up_to_date": false, "resolved_append_only": []}\n' "$base"
    fi
else
    # Capture the unmerged paths BEFORE resolving or aborting.
    conflicted=$(git diff --name-only --diff-filter=U)

    # Read the lists back from files rather than piping into `while`: a pipeline runs
    # its loop in a subshell, and both loops below have to set variables the rest of
    # this script reads.
    listfile="${TMPDIR:-/tmp}/wh-catchup-$$"

    # Pass 1: reconcile the append-only `.workaholic/` artifacts in place. A path only
    # leaves the unmerged set when BOTH the path scope and the shape test accept it,
    # so a mission.md whose conflict is a ticked acceptance box stays unmerged and
    # falls through to the classifier below as `content`, exactly as before.
    append_only=""
    printf '%s\n' "$conflicted" > "$listfile"
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        if append_only_candidate "$f" && append_only_resolve "$f"; then
            append_only="${append_only}${f}
"
        fi
    done < "$listfile"

    remaining=$(git diff --name-only --diff-filter=U)

    completed=0
    if [ -z "$remaining" ]; then
        # Everything that conflicted was an append on both sides. Complete the merge:
        # the branch is now caught up, and the ship (or the unattended `/drive` run)
        # proceeds instead of stopping for a decision nobody had to make. A commit that
        # somehow fails falls through to the abort path below rather than reporting a
        # catch-up that did not happen.
        if git commit --no-edit --quiet >/dev/null 2>&1; then
            completed=1
        fi
    fi

    if [ "$completed" -eq 1 ]; then
        printf '{"caught_up": true, "base": "%s", "branch_up_to_date": false, "resolved_append_only": [%s]}\n' \
            "$base" "$(json_list "$append_only")"
    else
        # Classify what is LEFT: mechanical iff every remaining conflicted path is one
        # of the version/lockstep manifests or lives under outputs/ (a strict
        # allowlist — anything else is content). An empty `remaining` here means the
        # completion commit itself failed, which is not a path question at all — that
        # needs a human, so it classes content.
        class="content"
        if [ -n "$remaining" ]; then
            class="mechanical"
            printf '%s\n' "$remaining" > "$listfile"
            while IFS= read -r f; do
                [ -n "$f" ] || continue
                case "$f" in
                    .claude-plugin/marketplace.json) ;;
                    plugins/workaholic/.claude-plugin/plugin.json) ;;
                    plugins/workaholic/.codex-plugin/plugin.json) ;;
                    outputs/*) ;;
                    *) class="content" ;;
                esac
            done < "$listfile"
        fi

        git merge --abort >/dev/null 2>&1 || true

        printf '{"caught_up": false, "base": "%s", "conflict": true, "conflict_class": "%s", "conflicted_files": [%s], "append_only_files": [%s]}\n' \
            "$base" "$class" "$(json_list "$conflicted")" "$(json_list "$append_only")"
    fi

    rm -f "$listfile"
fi
