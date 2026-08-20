#!/bin/sh -eu
# Put this tick's log sections on the base branch — the closing act of a tick.
#
# WHY IT EXISTS (2026-08-17, issue #471, ticket
# ticket `20260817131500`). `log-append.sh` writes into
# the CHECKOUT, and a routine-fired `[Moderate]` tick runs in a fresh container
# cloned from the base. Without this step the log dies with the container, which
# breaks two things at once: every dedup that reads the log (`stuck:<digest>`,
# `doc-drift`'s already-filed set, the check-in's asked-once and held sets, the
# inbound sweep's window) behaves as if no earlier tick ever ran and re-fires
# hourly, and an hourly unattended process is left with NO record of what it did.
# A hand-run is unaffected — the checkout survives it — which is exactly why the
# failure is invisible in the case somebody watches.
#
# THE SEAM: THE PUBLISH TREE, DIRECTLY (the ticket's Open Decision, resolved
# here). Two candidates were on the table.
#
#   - A pull request per tick. Refused: twenty-four pull requests a day for a
#     log, each asking a human to approve a line that records what a machine
#     already did. A review with no possible verdict is not a gate, it is noise
#     that trains its reviewer to stop looking.
#   - `publish-tree-commit.sh`, the direct (non-PR) form. Chosen. Its
#     "post-merge seams only" wording is about WHEN a direct commit is owed no
#     approval, and an append-only operational log is that case by construction:
#     nothing in it is a decision, and there is no content a reviewer could rule
#     on. The caller's checkout is left byte-identical, no `work-*` branch is
#     created, and no `publish-main` ref ever reaches origin — so the claim
#     protocol never sees this.
#
# WHY THIS IS NOT THE UNATTENDED-`main`-WRITER CLASS `workaholic:ship` §7
# REFUSED. That section refused three writer designs, and this matches none of
# them, on each design's own stated ground:
#
#   - "Refresh a merged note on `main`" was refused as SELF-REFERENTIAL: the
#     plan's datum is the base sha, so the refresh's own commit changes the
#     number it reports and each refresh invalidates itself. A log append has no
#     such loop — its content is the tick's own probe results, fixed before this
#     script runs, and appending it changes no input to any step of the tick that
#     wrote it. What later ticks read out of it (the dedup sets) is the POINT,
#     not an invalidation.
#   - "Push the refresh into each open PR's branch" was refused because those
#     branches belong to whoever holds their claim. This writes to no branch at
#     all: the commit lands on the base and `publish-main` stays local.
#   - "Run `/ship` itself, hourly" was refused because `/ship` merges. This
#     merges nothing, opens nothing, and reads no pull request.
#
# CONFLICT TOLERANCE IS A UNION, NOT A REBASE. Two containers ticking in the
# same minute both append to the same day file, and a textual rebase of two
# end-of-file appends conflicts. So the merge is done against a freshly fetched
# base on every attempt: whatever the base already carries is left untouched, and
# only what this checkout has and the base does not is appended. A rejected push
# therefore does not retry the same patch — it re-opens the publish tree at the
# new base and re-unions, so both ticks land and neither erases the other.
# Attempts are bounded (`--attempts`, default 3): sustained divergence is
# something a human should see, not something a loop should hide.
#
# THE UNION IS BY `(tick, step)`, NOT BY `(tick)` (2026-08-18, PR #489,
# ticket `20260818064158-carry-the-tick-log-step-filed-lines-to-the-base`). It
# was by section until then, and that made a whole class of line permanently
# unreachable: `run.sh` runs this script as its closing act, but the agent acts
# on `needs_agent` only AFTER `run.sh` returns, so every `<step>-filed` line —
# what the tick FILED, as opposed to what it found — is appended to the checkout
# after the persist has already landed the section. A second persist could not
# carry them either: by-section union asks only "does the base have `## <tick>`?",
# and it does, so it reported `already_current` and was correct by its own rule
# while the lines died with the container. Measured on tick `20260818-063819`,
# and invisible to a hand-run because a hand-run's checkout survives.
#
# So a section the base already carries is now merged LINE-WISE: for each of this
# checkout's entries in that section, the base's copy is asked whether it already
# has a line for that STEP, and only the steps it lacks are appended, in this
# checkout's order, at the end of that section. Nothing is rewritten, reordered
# or removed — a `(tick, step)` the base already has WINS over a differing local
# copy, which keeps the log append-only in substance exactly as `log-append.sh`'s
# refusal to rewrite an earlier line does, and keeps two containers sharing one
# section (a resumed tick keeps its id) from clobbering each other's entries.
#
# THE OTHER TWO FORKS, AND WHY THIS ONE. The feedback record named three:
#
#   - "Persist twice." Not an alternative but the other half of this one: a
#     second persist is what the agent now runs after recording its `<step>-filed`
#     lines (`workaholic:moderate`, *The run*), and it is inert unless the union
#     can update a section that has already landed — which is this change. Both
#     halves ship together; either alone fixes nothing.
#   - "Move the agent's filing before the persist." Refused. It takes the closing
#     act away from `run.sh`, which is the one thing that guarantees a tick that
#     dies part-way still puts what it recorded on the base. A tick that died
#     between the ninth step and the agent's filing would then persist NOTHING,
#     where today it at least persists every probe line — trading a missing
#     subset of the log for a missing whole one.
#
# The second persist is the agent's act, so `run.sh` is unchanged: it still owns
# its closing act, and the extra persist is idempotent (`already_current` when
# the agent filed nothing).
#
# IT CARRIES EVERY MISSING SECTION, NOT JUST THIS TICK'S. A tick whose persist
# failed leaves its section behind in the checkout; the next tick in the same
# container carries both up. That is also why the retry loop can safely discard
# a diverged publish commit — the checkout's day file, never this script's
# working state, is the source.
#
# THE LAST PERSIST'S OWN LOG LINE IS NOT ON THE BASE, AND DOES NOT NEED TO BE.
# The outcome is known only after the push, so a line recording it could only be
# written afterwards — and writing it, pushing again, and recording THAT does not
# terminate. It is written into the checkout (where a hand-run and the run report
# read it) and the base gets the evidence that actually answers the question:
# the tick's section is there iff its persist succeeded, and when it did not the
# run report names the reason. `run.sh` logs it under the step id `persist-log`;
# since the agent persists again afterwards, that line now does reach the base,
# and it is the SECOND persist's outcome — reported in the session, never
# logged — that stays off it, for the same non-terminating reason.
#
# Usage:
#   persist-log.sh --tick <YYYYMMDD-HHMMSS> [--root <repo-root>] [--base <branch>]
#                  [--attempts <n>]
#
# Output: one JSON line
#   {"persisted": true|false, "status": "filed|ok|skipped|degraded", "reason": "<stable>",
#    "summary": "<one line>", "sections": <n>, "lines": <n>, "attempts": <n>,
#    "changed": true|false, "sha": "<pushed sha>", "closed": true|false,
#    "close_reason": "<reason>"}
#
# `sections` counts whole `## <tick>` sections appended; `lines` counts entries
# merged into a section the base already carried. A persist that carried only
# late `<step>-filed` lines reports `sections: 0` with a non-zero `lines`.
#
# `status` is the tick log's closed vocabulary. Stable reasons:
#   persisted | already_current | no_log | not_a_repo | root_not_repo_root
#   no_origin | origin_unreachable | base_unresolved | dirty_publish_tree
#   diverged | push_failed | commit_failed
#
# `no_origin` is `skipped`, not `degraded`: a local-only checkout has no base to
# publish to, so nothing went wrong. Every other failure above is `degraded` —
# the base exists and the log did not reach it.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
BRANCHING="${SCRIPT_DIR}/../../branching/scripts"

TICK=''
ROOT='.'
BASE='main'
ATTEMPTS=3

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)     TICK="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        --base)     BASE="${2:-}"; shift 2 ;;
        --attempts) ATTEMPTS="${2:-3}"; shift 2 ;;
        *) printf '{"persisted": false, "status": "degraded", "reason": "unknown_argument", "summary": "unknown argument: %s"}\n' "$1"; exit 1 ;;
    esac
done

case "$TICK" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) printf '{"persisted": false, "status": "degraded", "reason": "bad_tick", "summary": "the tick id is not YYYYMMDD-HHMMSS"}\n'; exit 1 ;;
esac

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

report() {
    # $1 persisted  $2 status  $3 reason  $4 summary  $5 sections  $6 lines
    # $7 attempts  $8 changed  $9 sha  $10 closed  $11 close_reason
    printf '{"persisted": %s, "status": "%s", "reason": "%s", "summary": "%s", "sections": %s, "lines": %s, "attempts": %s, "changed": %s, "sha": "%s", "closed": %s, "close_reason": "%s"}\n' \
        "$1" "$2" "$3" "$(json_escape "$4")" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}"
    exit 0
}

DAY=$(printf '%s' "$TICK" | cut -c1-4)-$(printf '%s' "$TICK" | cut -c5-6)-$(printf '%s' "$TICK" | cut -c7-8)
LOG_REL=".workaholic/moderations/${DAY}.md"

if [ ! -d "$ROOT" ]; then
    report false skipped not_a_repo "the log root ${ROOT} does not exist" 0 0 0 false '' false ''
fi
root_abs=$(cd -- "$ROOT" && pwd)

# THE PUBLISH TARGET IS THE REPOSITORY THE LOG LIVES IN, and nothing else. A
# `--root` outside a git work tree (the drill's throwaway root, a hermetic
# fixture) is skipped by name rather than published into whatever repository the
# caller's cwd happens to be — publishing one tree's log into another
# repository's history is the one way this script could do real damage.
repo_root=$(git -C "$root_abs" rev-parse --show-toplevel 2>/dev/null || printf '')
if [ -z "$repo_root" ]; then
    report false skipped not_a_repo "the log root is not inside a git repository, so there is no base to publish to" 0 0 0 false '' false ''
fi
if [ "$root_abs" != "$repo_root" ]; then
    report false skipped root_not_repo_root "the log root is not the repository root (${root_abs} vs ${repo_root})" 0 0 0 false '' false ''
fi

LOCAL_LOG="${root_abs}/${LOG_REL}"
if [ ! -f "$LOCAL_LOG" ]; then
    report false skipped no_log "no tick log at ${LOG_REL} to persist" 0 0 0 false '' false ''
fi

# --- the union ---------------------------------------------------------------
# Sections present in the checkout's day file, in file order. The heading is the
# tick id, which is what makes "already there" answerable without a diff.
local_ticks=$(grep '^## ' "$LOCAL_LOG" | sed 's/^## //' || true)

close_tree() {
    out=$(cd "$repo_root" && sh "${BRANCHING}/close-publish-tree.sh" "$BASE" 2>/dev/null || true)
    case "$out" in
        *'"ok": true'*) CLOSED=true; CLOSE_REASON='' ;;
        *) CLOSED=false; CLOSE_REASON=$(printf '%s' "$out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p') ;;
    esac
    [ -n "$CLOSE_REASON" ] || CLOSE_REASON=''
}

CLOSED=false
CLOSE_REASON=''
attempt=0
carried=0
merged_lines=0

# Scratch for the line-wise union. Outside the repository and the publish tree,
# so a run that dies mid-merge leaves neither carrying a stray file.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

while [ "$attempt" -lt "$ATTEMPTS" ]; do
    attempt=$((attempt + 1))

    open_out=$(cd "$repo_root" && sh "${BRANCHING}/open-publish-tree.sh" "$BASE" 2>/dev/null || true)
    case "$open_out" in
        *'"ok": true'*) ;;
        *)
            reason=$(printf '%s' "$open_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
            [ -n "$reason" ] || reason=open_failed
            # A repository with NO remote is a precondition that is absent, not a
            # source that could not be read: a hand-run in a local-only checkout
            # has nowhere to publish and nothing has gone wrong. Everything else
            # here — an unreachable origin, a base that does not resolve, a
            # publish tree left dirty by an interrupted run — is a degradation,
            # because the base exists and the log did not reach it.
            case "$reason" in
                no_origin) st=skipped ;;
                *)         st=degraded ;;
            esac
            report false "$st" "$reason" "the publish tree would not open (${reason}); the log stays in the checkout" 0 0 "$attempt" false '' false ''
            ;;
    esac

    publish_path="${repo_root}/.publish"
    target="${publish_path}/${LOG_REL}"

    # An absent OR empty target takes the whole file: the two-file readers below
    # distinguish their inputs by which one they saw first, and an empty base
    # copy would make every local line read as one the base already has.
    if [ ! -s "$target" ]; then
        mkdir -p "$(dirname -- "$target")"
        cp "$LOCAL_LOG" "$target"
        carried=$(printf '%s\n' "$local_ticks" | grep -c '[^[:space:]]' || true)
        merged_lines=0
    else
        carried=0
        merged_lines=0
        for t in $local_ticks; do
            if ! grep -q "^## ${t}\$" "$target"; then
                # Heading plus body, with the section's trailing blank lines dropped
                # so appended sections stay one blank line apart however the source
                # was spaced.
                section=$(awk -v head="## $t" '
                    $0 == head { inside = 1; print; next }
                    inside && substr($0, 1, 3) == "## " { exit }
                    inside { print }
                ' "$LOCAL_LOG" | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }')
                [ -n "$section" ] || continue
                printf '\n%s\n' "$section" >> "$target"
                carried=$((carried + 1))
                continue
            fi

            # The section is already on the base: union its ENTRIES by step id.
            # `key()` is the step slug out of "- `<step>`: <status> — <summary>",
            # so a line whose `(tick, step)` the base already carries is left
            # exactly as the base has it, whatever this checkout says — the same
            # append-only-in-substance rule `log-append.sh` applies within a run.
            awk -v head="## $t" '
                function key(line,   rest, i) {
                    if (substr(line, 1, 3) != "- `") return "=" line
                    rest = substr(line, 4)
                    i = index(rest, "`: ")
                    if (i == 0) return "=" line
                    return substr(rest, 1, i - 1)
                }
                FNR == 1 { fileno++ }
                fileno == 1 {
                    if ($0 == head) { inside = 1; next }
                    if (inside && substr($0, 1, 3) == "## ") { inside = 0 }
                    if (inside && substr($0, 1, 3) == "- `") seen[key($0)] = 1
                    next
                }
                {
                    if ($0 == head) { mine = 1; next }
                    if (mine && substr($0, 1, 3) == "## ") { mine = 0 }
                    if (!mine || substr($0, 1, 3) != "- `") next
                    k = key($0)
                    if (k in seen) next
                    seen[k] = 1
                    print
                }
            ' "$target" "$LOCAL_LOG" > "$WORK/missing"

            [ -s "$WORK/missing" ] || continue
            n=$(grep -c '' "$WORK/missing")

            # Inserted at the END of that section, in this checkout's order, with
            # the section's trailing blank lines held back so the new entries land
            # against the last one rather than after the section break.
            awk -v head="## $t" -v missfile="$WORK/missing" '
                BEGIN { n = 0; while ((getline l < missfile) > 0) miss[++n] = l }
                function release(   i) { for (i = 1; i <= held; i++) print hold[i]; held = 0 }
                function emit(   i) { if (inside && !done) { for (i = 1; i <= n; i++) print miss[i]; done = 1 } }
                {
                    if ($0 == head) { release(); print; inside = 1; next }
                    if (substr($0, 1, 3) == "## ") { emit(); release(); inside = 0; print; next }
                    if (inside && NF == 0) { hold[++held] = $0; next }
                    release(); print
                }
                END { emit(); release() }
            ' "$target" > "$WORK/merged"
            cat "$WORK/merged" > "$target"
            merged_lines=$((merged_lines + n))
        done
    fi

    if [ -z "$(git -C "$publish_path" status --porcelain -- "$LOG_REL" 2>/dev/null)" ]; then
        close_tree
        report true ok already_current "every line of ${DAY} is already on ${BASE}" 0 0 "$attempt" false '' "$CLOSED" "$CLOSE_REASON"
    fi

    commit_out=$(cd "$repo_root" && sh "${BRANCHING}/publish-tree-commit.sh" \
        "Log the propose tick ${TICK}" \
        "An hourly unattended tick's only audit trail is what it writes down, and the routine's container is discarded after the run." \
        "The ${DAY} moderations log on ${BASE} now carries this tick's steps, so the next tick's dedups and a human's audit read the same record." \
        "None" \
        "None" \
        "Appended by section against a freshly fetched base, so concurrent ticks union rather than conflict." \
        "$LOG_REL" 2>/dev/null || true)

    case "$commit_out" in
        *'"ok": true'*)
            sha=$(printf '%s' "$commit_out" | sed -n 's/.*"sha": "\([^"]*\)".*/\1/p')
            close_tree
            report true filed persisted "${carried} tick section(s) and ${merged_lines} late line(s) of ${DAY} recorded on ${BASE}" "$carried" "$merged_lines" "$attempt" true "$sha" "$CLOSED" "$CLOSE_REASON"
            ;;
        *'"reason": "nothing_to_commit"'*)
            close_tree
            report true ok already_current "every line of ${DAY} is already on ${BASE}" 0 0 "$attempt" false '' "$CLOSED" "$CLOSE_REASON"
            ;;
        *'"reason": "diverged"'*|*'"reason": "push_failed"'*)
            # The base moved under us. Re-open (which resets the publish branch to
            # the new base, discarding this attempt's commit) and re-union; the
            # checkout's day file is the source, so nothing is lost by discarding.
            reason=$(printf '%s' "$commit_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
            continue
            ;;
        *)
            reason=$(printf '%s' "$commit_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
            [ -n "$reason" ] || reason=commit_failed
            close_tree
            report false degraded "$reason" "the log could not be committed to ${BASE} (${reason}); it stays in the checkout" "$carried" "$merged_lines" "$attempt" true '' "$CLOSED" "$CLOSE_REASON"
            ;;
    esac
done

[ -n "${reason:-}" ] || reason=diverged
close_tree
report false degraded "$reason" "the base moved under ${ATTEMPTS} attempts (${reason}); the log stays in the checkout" "$carried" "$merged_lines" "$ATTEMPTS" true '' "$CLOSED" "$CLOSE_REASON"
