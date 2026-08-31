#!/bin/sh -eu
# Bring the log branch's day files into this checkout, before any step reads them.
#
#   hydrate-log.sh [--root <repo-root>] [--days <n>]
#
# Output (one JSON line):
#   {"ok", "ref", "state": "hydrated|absent|skipped|degraded", "reason", "files": <n>,
#    "days": [...]}
#
# WHY IT EXISTS (2026-09-01, issue #782). The log used to be committed to `main`, so a fresh
# container's clone CARRIED it: every reader -- `log-read.sh`'s dedup sets, `question-state.sh`,
# `record-answer.sh`, `condition-age.sh`, `filed-records.sh`, `step-blocked-tick.sh` -- read the
# working tree and found the whole history there. Moving the log to its own branch takes that
# away in one stroke: `main`'s tree no longer has `.workaholic/moderations/` at all, so without
# this step every one of those readers would answer "no earlier tick ever ran" and the whole
# dedup would re-fire hourly. **This step is not a convenience; it is the other half of the
# move**, and shipping one without the other is worse than shipping neither.
#
# IT WRITES GIT-IGNORED FILES, DELIBERATELY. `.workaholic/moderations/` is in `.gitignore` now,
# so what this materialises can never be staged into a `main` commit by an ordinary `git add -A`
# -- which is the property that keeps the log off `main` by construction rather than by every
# writer remembering. `log-append.sh` keeps writing to exactly the same path, so no reader and
# no writer had to learn a new one.
#
# THE BASE COPY WINS ON THE FILES IT HAS, and that is safe because the log is append-only in
# substance: a day the branch carries is written over the checkout's copy, and `persist-log.sh`'s
# union then re-carries anything local the branch lacked on the next persist. The reverse rule
# -- keep the local copy -- would let a container that half-wrote a day file mask what other
# containers had already landed, which is the failure mode this whole store exists to avoid.
# A day file the branch does NOT have is left exactly where it is, untouched.
#
# IT IS BOUNDED (`--days`, default 30). The readers that walk the log are bounded too
# (`condition-age.sh`'s `WORKAHOLIC_CONDITION_AGE_MAX_DAYS`), and an unbounded checkout of every
# day file this repository has ever logged grows without limit for no reader's benefit. The
# newest N day files are taken; a walk that was cut says so rather than pretending completeness.
#
# EVERY FAILURE IS NAMED AND NONE IS FATAL. A tick that could not hydrate still runs: it simply
# has no memory of earlier ticks, which makes it over-report rather than under-report -- the same
# asymmetry the claim scan keeps. The reason rides the step's own report so a re-firing dedup is
# legible as *we could not read* rather than as *there was nothing there*.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT='.'
DAYS=30
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --days) DAYS="${2:-30}"; shift 2 ;;
        *) printf '{"ok": false, "ref": "", "state": "degraded", "reason": "unknown_argument", "files": 0, "days": []}\n'; exit 1 ;;
    esac
done
case "$DAYS" in ''|*[!0-9]*) DAYS=30 ;; esac

REF=$(sh "${SCRIPT_DIR}/log-ref.sh")
FILES=0
DAYS_JSON=''

emit() {
    printf '{"ok": %s, "ref": "%s", "state": "%s", "reason": "%s", "files": %s, "days": [%s]}\n' \
        "$1" "$REF" "$2" "${3:-}" "$FILES" "$DAYS_JSON"
    exit 0
}

repo_root=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || printf '')
[ -n "$repo_root" ] || emit false skipped not_a_repo
git -C "$repo_root" config --get remote.origin.url >/dev/null 2>&1 || emit false skipped no_origin

# One fetch, into the remote-tracking ref only. `--no-tags` keeps a log fetch from dragging the
# repository's tags in, which `report-deploy-status.sh` reads and which are not this step's to
# refresh.
if ! git -C "$repo_root" fetch --quiet --no-tags origin \
        "+refs/heads/${REF}:refs/remotes/origin/${REF}" >/dev/null 2>&1; then
    # An origin that has no such branch yet is `absent`, not a degradation: a repository whose
    # first tick has not run has no log, and that is the correct answer rather than a failure.
    if [ -z "$(git -C "$repo_root" ls-remote --heads origin "$REF" 2>/dev/null || printf '')" ]; then
        emit true absent no_log_branch
    fi
    emit false degraded fetch_failed
fi

tip="refs/remotes/origin/${REF}"
git -C "$repo_root" rev-parse --verify --quiet "${tip}^{commit}" >/dev/null 2>&1 || emit true absent no_log_branch

# Newest first by filename, which is `YYYY-MM-DD.md` and therefore sorts as a date.
listing=$(git -C "$repo_root" ls-tree -r --name-only "$tip" -- .workaholic/moderations 2>/dev/null \
    | sed -n 's#^\.workaholic/moderations/\(.*\.md\)$#\1#p' | sort -r | head -n "$DAYS" || true)
[ -n "$listing" ] || emit true absent no_day_files

dir="${repo_root}/.workaholic/moderations"
mkdir -p "$dir" 2>/dev/null || emit false degraded unwritable

for f in $listing; do
    if git -C "$repo_root" show "${tip}:.workaholic/moderations/${f}" > "${dir}/${f}.hydrating" 2>/dev/null; then
        mv "${dir}/${f}.hydrating" "${dir}/${f}"
        FILES=$((FILES + 1))
        if [ -z "$DAYS_JSON" ]; then DAYS_JSON="\"${f%.md}\""; else DAYS_JSON="${DAYS_JSON},\"${f%.md}\""; fi
    else
        rm -f "${dir}/${f}.hydrating"
        emit false degraded read_failed
    fi
done

emit true hydrated '' 
