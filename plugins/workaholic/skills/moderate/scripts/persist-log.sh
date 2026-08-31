#!/bin/sh -eu
# Put this tick's log sections on the log's own ref — the closing act of a tick.
#
# THE TARGET IS A DEDICATED REF, NOT THE BASE (2026-08-31, mission
# `take-the-moderation-tick-s-log-off-main`). Until then this script committed the day file
# onto `main` through the publish tree, two or three times a tick. That was right about
# DURABILITY and wrong about WHOSE HISTORY IT IS: measured over one day on a consuming
# repository, `main` took 275 commits — 138 `.workaholic/`-only, 5 touching the product —
# and the largest single author was this log. `main` is the development target's history.
#
# The ref, the measured 403 that forces its namespace, and the two ref-walking mechanisms'
# rules are `workaholic:moderate`, *Where the log lives, and why it is not `main`*, with the
# string itself in `lib/log-ref.sh`. What did NOT change is everything the union buys: the
# `(tick, step)` merge, the bounded retry against a freshly fetched target, the carry of
# every missing section, and the closed `status`/`reason` vocabulary.
#
# THE PUBLISH TREE IS GONE FROM THE LOG HALF, AND THE TWO PROPERTIES IT BOUGHT ARE KEPT BY
# BETTER MEANS. It was chosen for a fresh base and a byte-identical caller checkout. The ref
# path gets the first from `git fetch` and the second by CONSTRUCTION: the commit is built
# with plumbing against a scratch index (`GIT_INDEX_FILE`), so no working tree, no HEAD and
# no index of the caller's is touched at any point — there is no `.publish/` checkout to
# leave behind and no window in which an interrupted run leaves one dirty. The record half
# below still uses the publish tree, because its target is still the base.
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
# THE SEAM WAS THE PUBLISH TREE UNTIL 2026-08-31, AND ITS REJECTED ALTERNATIVE STILL
# STANDS. A pull request per tick was refused then and stays refused: twenty-four pull
# requests a day for a log, each asking a human to approve a line that records what a
# machine already did. A review with no possible verdict is not a gate, it is noise that
# trains its reviewer to stop looking. What changed is only the TARGET — the log's own
# ref instead of the base — and the mechanism, which is now plumbing rather than a
# checkout (see the top of this header).
#
# IT CARRIES THE TICK'S FEEDBACK RECORDS TOO (2026-08-23), AND THOSE STAY ON THE BASE
# (2026-08-31). `create.sh` stages a record and stops, so a finding the inbound sweep or
# issue triage wrote died with the container while the tick reported it filed. The records
# are named one by one with `--record <repo-relative-path>` — never a sweep of whatever is
# staged, which would let an unrelated container file reach the base. A record already on
# the base is left untouched (a feedback record is immutable), so two concurrent ticks both
# land and nothing is rewritten. They are KNOWLEDGE, cited through the `feedback:` relation,
# so they did not move with the log; the second half of this script is their seam and it
# still uses the publish tree. Every prohibition is unmoved: no `work-*` branch, no claim,
# no pull request, no merge.
#
# WHY THE RECORD HALF IS NOT THE UNATTENDED-`main`-WRITER CLASS `workaholic:ship` §7
# REFUSED. That section refused three writer designs, and this matches none of them, on
# each design's own stated ground:
#
#   - "Refresh a merged note on `main`" was refused as SELF-REFERENTIAL: the
#     plan's datum is the base sha, so the refresh's own commit changes the
#     number it reports and each refresh invalidates itself. Writing a record has no
#     such loop — its content is fixed before this script runs, and committing it
#     changes no input to any step of the tick that wrote it.
#   - "Push the refresh into each open PR's branch" was refused because those
#     branches belong to whoever holds their claim. This writes to no branch at
#     all: the commit lands on the base and `publish-main` stays local.
#   - "Run `/ship` itself, hourly" was refused because `/ship` merges. This
#     merges nothing, opens nothing, and reads no pull request.
#
# CONFLICT TOLERANCE IS A UNION, NOT A REBASE. Two containers ticking in the
# same minute both append to the same day file, and a textual rebase of two
# end-of-file appends conflicts. So the merge is done against a freshly fetched
# target on every attempt: whatever the ref already carries is left untouched, and
# only what this checkout has and the ref does not is appended. A rejected push
# therefore does not retry the same patch — it re-fetches the ref and re-unions,
# so both ticks land and neither erases the other.
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
#   diverged | push_failed | commit_failed | log_ref_unreachable
#
# `no_origin` is `skipped`, not `degraded`: a local-only checkout has nowhere to
# publish to, so nothing went wrong. Every other failure above is `degraded` —
# the target exists and the log did not reach it.
#
# `log_ref_unreachable` IS ITS OWN REASON AND IS NOT FOLDED INTO AN EXISTING ONE.
# A fetch that could not reach the ref and a ref that does not exist yet are
# different facts: the second is the ordinary state of a repository whose first
# tick has not run, and the first is a degradation. `lib/log-ref.sh` tells them
# apart, and a run that could not reach the ref leaves the log in the checkout.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
BRANCHING="${SCRIPT_DIR}/../../branching/scripts"

TICK=''
ROOT='.'
BASE='main'
ATTEMPTS=3
RECORDS=''

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)     TICK="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        --base)     BASE="${2:-}"; shift 2 ;;
        --attempts) ATTEMPTS="${2:-3}"; shift 2 ;;
        --record)   RECORDS="${RECORDS}${2:-}
"; shift 2 ;;
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
    printf '{"persisted": %s, "status": "%s", "reason": "%s", "summary": "%s", "sections": %s, "lines": %s, "attempts": %s, "changed": %s, "sha": "%s", "closed": %s, "close_reason": "%s", "records": [%s]}\n' \
        "$1" "$2" "$3" "$(json_escape "$4")" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${RECORDS_JSON:-}"
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


# --- the log half: publish to the log's own ref ------------------------------
# The ref, and why `refs/heads/` is the only namespace this can use, are ruled in
# `workaholic:moderate`; the string lives in `lib/log-ref.sh` so the publisher and the
# reader cannot drift apart.
. "${SCRIPT_DIR}/lib/log-ref.sh"

LOG_DIR_ABS="${root_abs}/${WORKAHOLIC_LOG_DIR_REL}"

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
RECORDS_JSON=''

# Scratch for the union and for the scratch index. Outside the repository, so a run that
# dies mid-merge leaves nothing behind in the checkout -- which is the byte-identical
# guarantee, now held by construction rather than by a cleanup step.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# EVERY DAY FILE THE CHECKOUT CARRIES IS CONSIDERED, NOT JUST THIS TICK'S. The union has
# always carried every missing SECTION of the current day; extending that to every day file
# closes the day-boundary hole in the same rule -- a tick whose persist failed at 23:50 left
# its section behind, and the next tick's file is a different day, so nothing carried it up.
# On a ref that does not exist yet this is also the SEED: the whole local history becomes
# the ref's first commit, which is what makes the cutover from `main` an ordinary persist.
day_files=$(find "$LOG_DIR_ABS" -maxdepth 1 -name '*.md' 2>/dev/null | sort || true)

log_sha=''
log_changed=false

while [ "$attempt" -lt "$ATTEMPTS" ]; do
    attempt=$((attempt + 1))
    carried=0
    merged_lines=0

    fetch_state=$(workaholic_log_fetch "$root_abs")
    case "$fetch_state" in
        no_origin)
            # A local-only checkout has nowhere to publish. Nothing has gone wrong.
            report false skipped no_origin "no origin is configured, so the log stays in the checkout" 0 0 "$attempt" false '' false ''
            ;;
        unreachable)
            report false degraded log_ref_unreachable "the log ref could not be fetched; the log stays in the checkout for the next tick" 0 0 "$attempt" false '' false ''
            ;;
    esac
    # `ok` (the ref is here) or `absent` (no tick has ever published; this run creates it).

    ref_exists=false
    [ "$fetch_state" = ok ] && ref_exists=true

    rm -rf "$WORK/stage"
    mkdir -p "$WORK/stage"
    changed_rels=''

    for local_file in $day_files; do
        [ -f "$local_file" ] || continue
        day_name=$(basename "$local_file" .md)
        case "$day_name" in
            [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
            *) continue ;;
        esac
        rel="${WORKAHOLIC_LOG_DIR_REL}/${day_name}.md"

        # The ref's copy of this day, or empty when the ref has no such file. An absent OR
        # empty remote copy takes the whole local file: the two-file readers below tell
        # their inputs apart by which they saw first, and an empty remote copy would make
        # every local line read as one the ref already has.
        : > "$WORK/remote"
        if [ "$ref_exists" = true ]; then
            git -C "$root_abs" show "${WORKAHOLIC_LOG_REMOTE_REF}:${rel}" > "$WORK/remote" 2>/dev/null || : > "$WORK/remote"
        fi

        target="$WORK/stage/${day_name}.md"
        if [ ! -s "$WORK/remote" ]; then
            cp "$local_file" "$target"
            carried=$((carried + $(grep -c '^## ' "$local_file" 2>/dev/null || echo 0)))
            changed_rels="${changed_rels} ${rel}"
            continue
        fi

        cp "$WORK/remote" "$target"
        local_ticks=$(grep '^## ' "$local_file" | sed 's/^## //' || true)
        for t in $local_ticks; do
            if ! grep -q "^## ${t}\$" "$target"; then
                # Heading plus body, with the section's trailing blank lines dropped so
                # appended sections stay one blank line apart however the source was spaced.
                section=$(awk -v head="## $t" '
                    $0 == head { inside = 1; print; next }
                    inside && substr($0, 1, 3) == "## " { exit }
                    inside { print }
                ' "$local_file" | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }')
                [ -n "$section" ] || continue
                printf '\n%s\n' "$section" >> "$target"
                carried=$((carried + 1))
                continue
            fi

            # The section is already on the ref: union its ENTRIES by step id. `key()` is
            # the step slug out of "- `<step>`: <status> -- <summary>", so a line whose
            # `(tick, step)` the ref already carries is left exactly as the ref has it,
            # whatever this checkout says -- the same append-only-in-substance rule
            # `log-append.sh` applies within a run.
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
            ' "$target" "$local_file" > "$WORK/missing"

            [ -s "$WORK/missing" ] || continue
            n=$(grep -c '' "$WORK/missing")

            # Inserted at the END of that section, in this checkout's order, with the
            # section's trailing blank lines held back so the new entries land against the
            # last one rather than after the section break.
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

        if cmp -s "$WORK/remote" "$target"; then
            rm -f "$target"
        else
            changed_rels="${changed_rels} ${rel}"
        fi
    done

    if [ -z "$changed_rels" ]; then
        log_changed=false
        break
    fi

    # THE COMMIT IS BUILT WITH PLUMBING AGAINST A SCRATCH INDEX. No working tree, no HEAD
    # and no index of the caller's is touched at any point, so the caller's checkout is
    # byte-identical by construction rather than by a cleanup step -- and no `work-*`
    # branch, claim, worktree or pull request is created, exactly as before.
    GIT_INDEX_FILE="$WORK/index"
    export GIT_INDEX_FILE
    rm -f "$GIT_INDEX_FILE"
    if [ "$ref_exists" = true ]; then
        if ! git -C "$root_abs" read-tree "$WORKAHOLIC_LOG_REMOTE_REF" 2>/dev/null; then
            unset GIT_INDEX_FILE
            report false degraded commit_failed "the log ref's tree could not be read; the log stays in the checkout" "$carried" "$merged_lines" "$attempt" false '' false ''
        fi
    fi
    index_ok=true
    for rel in $changed_rels; do
        day_name=$(basename "$rel" .md)
        blob=$(git -C "$root_abs" hash-object -w "$WORK/stage/${day_name}.md" 2>/dev/null || true)
        if [ -z "$blob" ]; then index_ok=false; break; fi
        git -C "$root_abs" update-index --add --cacheinfo "100644,${blob},${rel}" 2>/dev/null || { index_ok=false; break; }
    done
    if [ "$index_ok" != true ]; then
        unset GIT_INDEX_FILE
        report false degraded commit_failed "the log tree could not be staged; the log stays in the checkout" "$carried" "$merged_lines" "$attempt" false '' false ''
    fi
    tree=$(git -C "$root_abs" write-tree 2>/dev/null || true)
    unset GIT_INDEX_FILE
    if [ -z "$tree" ]; then
        report false degraded commit_failed "the log tree could not be written; the log stays in the checkout" "$carried" "$merged_lines" "$attempt" false '' false ''
    fi

    if [ "$ref_exists" = true ]; then
        prev_tree=$(git -C "$root_abs" rev-parse "${WORKAHOLIC_LOG_REMOTE_REF}^{tree}" 2>/dev/null || true)
        if [ "$tree" = "$prev_tree" ]; then
            log_changed=false
            break
        fi
        commit=$(git -C "$root_abs" commit-tree "$tree" -p "$WORKAHOLIC_LOG_REMOTE_REF" \
            -m "Log the moderation tick ${TICK}" 2>/dev/null || true)
    else
        # THE FIRST COMMIT IS AN ORPHAN -- no parent, so the log's history shares no commit
        # with the base and nothing on it can ever read as work in flight.
        commit=$(git -C "$root_abs" commit-tree "$tree" \
            -m "Log the moderation tick ${TICK}" 2>/dev/null || true)
    fi
    if [ -z "$commit" ]; then
        report false degraded commit_failed "the log commit could not be created; the log stays in the checkout" "$carried" "$merged_lines" "$attempt" false '' false ''
    fi

    # THE PUSH IS THE ONLY OUTWARD ACT, AND IT CREATES NO LOCAL BRANCH. That is why
    # `guard-git-branch.sh` needs no rule about this ref: the guard matches local
    # branch-creation surfaces, and a push into a ref is not one.
    if git -C "$root_abs" push --quiet origin "${commit}:${WORKAHOLIC_LOG_REF}" >/dev/null 2>&1; then
        log_sha="$commit"
        log_changed=true
        break
    fi

    # Rejected: the ref moved under us (another container ticked in the same minute). Do
    # NOT replay this patch -- re-fetch and re-union, so both ticks land and neither erases
    # the other. The checkout's day files are the source, so discarding this attempt's
    # commit loses nothing.
    if [ "$attempt" -ge "$ATTEMPTS" ]; then
        report false degraded diverged "the log ref moved under ${ATTEMPTS} attempts; the log stays in the checkout" "$carried" "$merged_lines" "$ATTEMPTS" true '' false ''
    fi
done

# --- the record half: the tick's own feedback records, onto the base ---------
# A DIFFERENT PAYLOAD WITH A DIFFERENT DESTINATION, and the split is deliberate (2026-08-31,
# mission `take-the-moderation-tick-s-log-off-main`). The tick log is an operational log and
# leaves `main`; the feedback records the tick writes are KNOWLEDGE under the OKF floor,
# cited by missions and tickets through the `feedback:` relation, and they belong on the base
# exactly where they are -- moving them onto the log ref would make every `feedback:` ref the
# loop later writes unresolvable.
#
# SCOPED TO THE TICK'S OWN RECORDS, NAMED ONE BY ONE (`--record`), never a sweep of whatever
# happens to be staged -- a sweep would let an unrelated file in the container ride an
# unattended commit to the base, which is the one thing this seam must never become.
#
# A RECORD ON THE BASE IS NEVER REWRITTEN. A feedback record is immutable by its own skill's
# rule, so "already there" is success, not a conflict, and two concurrent ticks writing
# different records both land because they touch different files.
#
# A tick with NO records opens no publish tree and makes no commit to the base at all, which
# is what makes "no commit on the base writes the log" true of the whole script rather than
# only of its first half.
RECORD_PATHS=''
_rsep=''
if [ -n "$RECORDS" ]; then
    printf '%s\n' "$RECORDS" | while IFS= read -r _r; do
        [ -n "$_r" ] || continue
        printf '%s\n' "$_r"
    done > "$WORK/records" 2>/dev/null || : > "$WORK/records"

    if [ -s "$WORK/records" ]; then
        rec_attempt=0
        while [ "$rec_attempt" -lt "$ATTEMPTS" ]; do
            rec_attempt=$((rec_attempt + 1))
            RECORD_PATHS=''
            RECORDS_JSON=''
            _rsep=''

            open_out=$(cd "$repo_root" && sh "${BRANCHING}/open-publish-tree.sh" "$BASE" 2>/dev/null || true)
            case "$open_out" in
                *'"ok": true'*) ;;
                *)
                    reason=$(printf '%s' "$open_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
                    [ -n "$reason" ] || reason=open_failed
                    case "$reason" in
                        no_origin) st=skipped ;;
                        *)         st=degraded ;;
                    esac
                    # THE TWO HALVES REPORT INDEPENDENTLY. A record carry that failed must
                    # not be hidden by a log persist that worked, and a failed log persist
                    # must not be reported as a failed filing.
                    report "$log_changed" "$st" "$reason" "the log reached its ref; the tick's records could not (${reason})" "$carried" "$merged_lines" "$attempt" "$log_changed" "$log_sha" false ''
                    ;;
            esac

            publish_path="${repo_root}/.publish"
            while IFS= read -r rel; do
                [ -n "$rel" ] || continue
                src="${root_abs}/${rel}"
                dst="${publish_path}/${rel}"
                if [ ! -f "$src" ]; then
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "missing"}' "$(json_escape "$rel")")"
                    _rsep=', '
                    continue
                fi
                if [ -f "$dst" ]; then
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "already_on_base"}' "$(json_escape "$rel")")"
                    _rsep=', '
                    continue
                fi
                mkdir -p "$(dirname -- "$dst")" 2>/dev/null || true
                if cp "$src" "$dst" 2>/dev/null; then
                    RECORD_PATHS="${RECORD_PATHS} ${rel}"
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "carried"}' "$(json_escape "$rel")")"
                else
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "unreadable"}' "$(json_escape "$rel")")"
                fi
                _rsep=', '
            done < "$WORK/records"

            if [ -z "$RECORD_PATHS" ]; then
                close_tree
                break
            fi

            commit_out=$(cd "$repo_root" && sh "${BRANCHING}/publish-tree-commit.sh" \
                "Record the moderation tick findings" \
                "An unattended tick writes a feedback record and its container is discarded, so a finding reported as filed was lost." \
                "The records this tick wrote are on ${BASE}, where the feedback: relation resolves them." \
                "None" \
                "None" \
                "Named one by one, never a sweep; a record already on the base is left untouched." \
                $RECORD_PATHS 2>/dev/null || true)

            case "$commit_out" in
                *'"ok": true'*|*'"reason": "nothing_to_commit"'*)
                    close_tree
                    break
                    ;;
                *'"reason": "diverged"'*|*'"reason": "push_failed"'*)
                    close_tree
                    continue
                    ;;
                *)
                    reason=$(printf '%s' "$commit_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
                    [ -n "$reason" ] || reason=commit_failed
                    close_tree
                    report "$log_changed" degraded "$reason" "the log reached its ref; the tick's records could not be committed to ${BASE} (${reason})" "$carried" "$merged_lines" "$attempt" "$log_changed" "$log_sha" "$CLOSED" "$CLOSE_REASON"
                    ;;
            esac
        done
    fi
fi

if [ "$log_changed" = true ]; then
    _nrec=$(printf '%s' "$RECORD_PATHS" | wc -w | tr -d ' ')
    report true filed persisted "${carried} tick section(s), ${merged_lines} late line(s) of ${DAY} and ${_nrec} record(s) published" "$carried" "$merged_lines" "$attempt" true "$log_sha" "$CLOSED" "$CLOSE_REASON"
fi

report true ok already_current "every line of ${DAY} is already on the log ref" 0 0 "$attempt" false '' "$CLOSED" "$CLOSE_REASON"
