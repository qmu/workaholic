#!/bin/sh -eu
# Revise one LIVE strategy: the THIRD writer of this artifact, beside create.sh
# (creates) and close.sh (ends the lifecycle). Nothing else writes the file.
#
# WHY A THIRD WRITER EXISTS AT ALL. The two-writer rule was written to stop a
# machine AUTHORING the operator's direction, and that premise is untouched: this
# script carries a revision the operator ANNOUNCED, onto a pull request only they
# can merge (`/specificate`'s *changed* branch, and a strategy-touching publish
# never auto-merges). What it removes is the one act in this repository that
# required a person to edit the base by hand.
#
# BOUNDED TO THE THREE REVISABLE PARTS. `## Aim`, the Schedule (`target_date:`
# and the `## Schedule` prose) and `assignees:` — the three the model calls
# revisable. `slug`, `type`, `status`, `created_at`, `author` and `feedback:` are
# rewritten by nothing: they are unreachable from this interface AND the script
# asserts it over the candidate before writing, rather than trusting the caller.
# A closed strategy is history and is refused `not_active` — `close.sh` stays the
# only writer of an end state, and re-opening is not offered here either.
#
# NOTHING IS WRITTEN ON A REFUSAL. The candidate is composed under a temporary
# directory and validated there; the artifact is touched only by the final `mv`.
# A refusal therefore leaves the file and the index byte-identical — no partial
# write, no staged half, and no write-then-revert (a revert is a second write).
#
# Usage:
#   amend.sh <slug> [--target-date <YYYY-MM-DD>] [--schedule <prose>]
#            [--assignees <a>[,<b>...]] [--aim <prose>|-] [<workaholic-root>]
#
#   --aim -   reads the Aim prose from stdin (the shape create.sh uses); any
#             other value is the prose itself. Stdin is read only when asked for.
#   At least one revision must be named, or the call is refused `no_revision`:
#   an announcement that says only "this is going well" is not a revision.
#
# Output: one JSON object
#   {"amended": true,  "path": …, "slug": …, "revised": ["aim","target_date",…]}
#   {"amended": true,  "path": …, "slug": …, "revised": [], "reason": "already"}
#   {"amended": false, "reason": "no_slug"|"not_found"|"not_active"|"no_revision"
#                               |"bad_target_date"|"no_assignees"|"empty_schedule"
#                               |"empty_aim"|"immutable_field"|"bad_option"
#                               |"missing_value"|"malformed", …}
#
# The four floor refusals reuse create.sh's names VERBATIM (`bad_target_date` /
# `no_assignees` / `empty_schedule` / `empty_aim`) so one artifact never acquires
# two names for one refusal.
#
# IT STAGES THE ONE PATH AND NEVER COMMITS, exactly as create.sh does. It does
# NOT refresh the OKF indexes: no index-visible field is revisable here (title
# and status are immutable), so a refresh could only add an unrelated diff to a
# call whose contract is that it touched one file.

set -eu

SLUG=""
ROOT=""
NEW_DATE=""
NEW_SCHEDULE=""
NEW_ASSIGNEES=""
NEW_AIM=""
AIM_FROM_STDIN=0
have_date=0
have_schedule=0
have_assignees=0
have_aim=0

refuse() {
    printf '{"amended": false, "reason": "%s"}\n' "$1"
    exit 1
}
refuse_path() {
    printf '{"amended": false, "reason": "%s", "path": "%s"}\n' "$1" "$2"
    exit 1
}

need_value() {
    # $1 is the remaining argument count for the flag being read.
    [ "$1" -ge 2 ] || refuse missing_value
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --target-date) need_value "$#"; NEW_DATE="$2"; have_date=1; shift 2 ;;
        --schedule)    need_value "$#"; NEW_SCHEDULE="$2"; have_schedule=1; shift 2 ;;
        --assignees)   need_value "$#"; NEW_ASSIGNEES="$2"; have_assignees=1; shift 2 ;;
        --aim)
            need_value "$#"
            case "$2" in
                -) AIM_FROM_STDIN=1 ;;
                *) NEW_AIM="$2" ;;
            esac
            have_aim=1
            shift 2
            ;;
        --*) refuse bad_option ;;
        *)
            if [ -z "$SLUG" ]; then SLUG="$1"; else ROOT="$1"; fi
            shift
            ;;
    esac
done

[ -n "$SLUG" ] || refuse no_slug
[ -n "$ROOT" ] || ROOT=".workaholic"

if [ "$have_date" -eq 0 ] && [ "$have_schedule" -eq 0 ] && \
   [ "$have_assignees" -eq 0 ] && [ "$have_aim" -eq 0 ]; then
    refuse no_revision
fi

SCRIPT_DIR=$(dirname "$0")

DIR="${ROOT}/strategies"
FILE="${DIR}/${SLUG}.md"
[ -f "$FILE" ] || refuse_path not_found "$FILE"

# --- Input-level refusals, before anything is composed -----------------------
if [ "$have_date" -eq 1 ]; then
    case "$NEW_DATE" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;;
        *) refuse_path bad_target_date "$FILE" ;;
    esac
fi

fmt_list() {
    printf '%s' "$1" | tr ',' '\n' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' \
        | grep -v '^$' | paste -sd, - | sed -e 's/,/, /g'
}

ASSIGNEE_LIST=""
if [ "$have_assignees" -eq 1 ]; then
    ASSIGNEE_LIST=$(fmt_list "$NEW_ASSIGNEES")
    [ -n "$(printf '%s' "$ASSIGNEE_LIST" | tr -d '[:space:],')" ] || \
        refuse_path no_assignees "$FILE"
fi

if [ "$have_schedule" -eq 1 ]; then
    [ -n "$(printf '%s' "$NEW_SCHEDULE" | tr -d '[:space:]')" ] || \
        refuse_path empty_schedule "$FILE"
fi

if [ "$have_aim" -eq 1 ] && [ "$AIM_FROM_STDIN" -eq 1 ]; then
    NEW_AIM=$(cat)
fi
if [ "$have_aim" -eq 1 ]; then
    [ -n "$(printf '%s' "$NEW_AIM" | tr -d '[:space:]')" ] || \
        refuse_path empty_aim "$FILE"
fi

# --- The live-direction gate -------------------------------------------------
# A closed strategy is history. `close.sh` is the only writer of an end state and
# a decision that was ended and is being pursued again is a NEW strategy with its
# own dates, not a reverted field.
fm_value() {
    awk -v key="$1" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$FILE" 2>/dev/null || true
}

STATUS=$(fm_value status)
[ -n "$STATUS" ] || refuse_path malformed "$FILE"
[ "$STATUS" = "active" ] || refuse_path not_active "$FILE"

# --- Compose the candidate under a temporary directory -----------------------
WORK=$(mktemp -d "${TMPDIR:-/tmp}/workaholic-amend.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

fm_block() {
    awk 'NR==1 { if ($0 != "---") exit; next } /^---[ \t]*$/ { exit } { print }' "$1"
}

section_body() {
    awk -v want="## $2" '
        $0 == want { inside = 1; next }
        inside && /^## / { exit }
        inside { print }
    ' "$1"
}

trim_blanks() {
    awk '
        { lines[NR] = $0 }
        END {
            s = 1; while (s <= NR && lines[s] ~ /^[ \t]*$/) s++
            e = NR; while (e >= s && lines[e] ~ /^[ \t]*$/) e--
            for (i = s; i <= e; i++) print lines[i]
        }
    '
}

# 1. Frontmatter: only target_date and assignees may move.
CAND="${WORK}/candidate.md"
awk -v date="$NEW_DATE" -v hd="$have_date" -v asg="$ASSIGNEE_LIST" -v ha="$have_assignees" '
    NR==1 && $0 == "---" { infm = 1; print; next }
    infm && /^---[ \t]*$/ { infm = 0; print; next }
    infm && hd == "1" && /^target_date:/ { print "target_date: " date; next }
    infm && ha == "1" && /^assignees:/ { print "assignees: [" asg "]"; next }
    { print }
' "$FILE" > "$CAND"

# 2. The Aim prose.
if [ "$have_aim" -eq 1 ]; then
    printf '%s\n' "$NEW_AIM" | trim_blanks > "${WORK}/aim"
    awk -v want="## Aim" -v bodyfile="${WORK}/aim" '
        $0 == want && !done {
            print; print ""
            while ((getline line < bodyfile) > 0) print line
            close(bodyfile)
            print ""
            skipping = 1; done = 1
            next
        }
        skipping && /^## / { skipping = 0 }
        skipping { next }
        { print }
    ' "$CAND" > "${WORK}/next" && mv "${WORK}/next" "$CAND"
fi

# 3. The Schedule. `target_date:` and this section are ONE revisable part, so a
#    moved date rewrites the `Target: <date>` line create.sh renders here — a
#    strategy states its date once, not twice. A file carrying no such line keeps
#    none: this writer revises the operator's prose, it does not restructure it.
if [ "$have_schedule" -eq 1 ] || [ "$have_date" -eq 1 ]; then
    section_body "$CAND" Schedule | trim_blanks > "${WORK}/sched"

    TARGET_LINE=$(awk 'NR==1 && /^Target:[ \t]/ { print; exit }' "${WORK}/sched")
    if [ -n "$TARGET_LINE" ] && [ "$have_date" -eq 1 ]; then
        TARGET_LINE="Target: ${NEW_DATE}"
    fi

    # The section is three parts: the `Target:` line, the operator's prose, and the
    # trailing block of `Revised …` lines this script appends. Replacing the prose
    # must not drop the history — the record is APPEND-ONLY, so the block is carried
    # across a prose revision rather than rebuilt with it.
    split_sched() {
        awk -v part="$1" '
            { lines[NR] = $0 }
            END {
                s = (lines[1] ~ /^Target:[ \t]/) ? 2 : 1
                r = NR + 1
                while (r - 1 >= s && (lines[r - 1] ~ /^[ \t]*$/ ||
                       lines[r - 1] ~ /^Revised [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:/)) r--
                while (r <= NR && lines[r] ~ /^[ \t]*$/) r++
                if (part == "prose") { for (i = s; i < r; i++) print lines[i] }
                else { for (i = r; i <= NR; i++) if (lines[i] !~ /^[ \t]*$/) print lines[i] }
            }
        ' "${WORK}/sched"
    }
    split_sched revisions > "${WORK}/revs"
    if [ "$have_schedule" -eq 1 ]; then
        printf '%s\n' "$NEW_SCHEDULE" | trim_blanks > "${WORK}/prose"
    else
        split_sched prose | trim_blanks > "${WORK}/prose"
    fi

    {
        if [ -n "$TARGET_LINE" ]; then
            printf '%s\n\n' "$TARGET_LINE"
        fi
        cat "${WORK}/prose"
        if [ -s "${WORK}/revs" ]; then
            printf '\n'
            cat "${WORK}/revs"
        fi
    } > "${WORK}/schedbody"

    awk -v want="## Schedule" -v bodyfile="${WORK}/schedbody" '
        $0 == want && !done {
            print; print ""
            while ((getline line < bodyfile) > 0) print line
            close(bodyfile)
            print ""
            skipping = 1; done = 1
            next
        }
        skipping && /^## / { skipping = 0 }
        skipping { next }
        { print }
    ' "$CAND" > "${WORK}/next" && mv "${WORK}/next" "$CAND"
fi

# A rewritten last section leaves the blank line that separated it from the next
# one. Trailing blanks are stripped so the file keeps the shape create.sh gave it
# and a re-run compares byte-identical rather than growing by a line each time.
awk '
    { lines[NR] = $0 }
    END { e = NR; while (e >= 1 && lines[e] ~ /^[ \t]*$/) e--; for (i = 1; i <= e; i++) print lines[i] }
' "$CAND" > "${WORK}/next" && mv "${WORK}/next" "$CAND"

# --- Assert the immutable half, over the candidate ---------------------------
# Not a re-statement of the interface: the interface is what a caller sees, this
# is what the file says. The two disagreeing is exactly the failure worth naming.
fm_block "$FILE" | grep -v '^target_date:' | grep -v '^assignees:' > "${WORK}/fm-before" || true
fm_block "$CAND" | grep -v '^target_date:' | grep -v '^assignees:' > "${WORK}/fm-after" || true
if ! cmp -s "${WORK}/fm-before" "${WORK}/fm-after"; then
    refuse_path immutable_field "$FILE"
fi

# --- Idempotency -------------------------------------------------------------
# A revision already applied leaves the file byte-identical and reports `already`,
# exactly as close.sh does on a re-close. It is answered BEFORE the floor below so
# a pure no-op over an already-malformed file reports what is true — that there was
# nothing to write — rather than refusing a write nobody asked for.
if cmp -s "$FILE" "$CAND"; then
    printf '{"amended": true, "path": "%s", "slug": "%s", "revised": [], "reason": "already"}\n' \
        "$FILE" "$SLUG"
    exit 0
fi

# --- The write-time floor, carried HERE ---------------------------------------
# hooks/validate-strategy.sh holds a strategy to three properties and GRANDFATHERS
# git-tracked files — and every strategy an amendment touches is git-tracked, so the
# hook is silent on exactly these writes. The floor therefore holds at the writer,
# over the POST-REVISION artifact, refusing before anything is written. Write-then-
# revert is refused as a design: a revert is a second write, and the contract this
# artifact needs is that a refusal never wrote.
#
# The three properties are read from the hook rather than remembered: a `YYYY-MM-DD`
# `target_date`; a non-empty `assignees` (the one artifact where empty is a refusal,
# not team-owned); a non-empty `## Aim` AND `## Schedule`. The names are create.sh's
# verbatim so one artifact never acquires two names for one refusal.
cand_fm() {
    awk -v key="$1" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$CAND" 2>/dev/null || true
}

case "$(cand_fm target_date)" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;;
    *) refuse_path bad_target_date "$FILE" ;;
esac

[ -n "$(cand_fm assignees | sed -e 's/^\[//' -e 's/\]$//' -e 's/[ \t,]//g')" ] || \
    refuse_path no_assignees "$FILE"

[ -n "$(section_body "$CAND" Aim | tr -d '[:space:]')" ] || refuse_path empty_aim "$FILE"
[ -n "$(section_body "$CAND" Schedule | tr -d '[:space:]')" ] || refuse_path empty_schedule "$FILE"

REVISED=""
add_revised() { REVISED="${REVISED}${REVISED:+, }\"$1\""; }
WORDS=""
add_word() { WORDS="${WORDS}${WORDS:+, }$1"; }
if [ "$have_aim" -eq 1 ]; then add_revised aim; add_word "aim"; fi
if [ "$have_date" -eq 1 ]; then add_revised target_date; add_word "target date"; fi
if [ "$have_schedule" -eq 1 ]; then add_revised schedule; add_word "schedule"; fi
if [ "$have_assignees" -eq 1 ]; then add_revised assignees; add_word "assignee"; fi

# --- Record what moved, in the Schedule prose --------------------------------
# A revised direction says on its own face that it was revised — otherwise a reader
# sees only the current values and cannot tell a direction that has always said this
# from one re-dated twice. The history goes where the history already lives: `##
# Schedule` carries the shape around the date in prose, so one short line is appended
# there. NO frontmatter key, no second artifact, no changelog area — a `revised_at:`
# field would need a reader, and the artifact's model is deliberately small.
#
# APPEND-ONLY: a previous line is never rewritten and never reordered, so a reader
# scanning down the section reads the direction's history in order. It goes at the
# END of the section, which is what puts it AFTER the operator's new prose when the
# revision touched the prose itself — their words lead, the machine's follow.
#
# It is IDEMPOTENT WITH THE REVISION: this point is reached only past the `already`
# return above, so a no-op appends nothing and the file cannot grow a line on every
# tick that re-ran the same ask.
TODAY=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh" 2>/dev/null \
    | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//' | cut -c1-10)
case "$TODAY" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;;
    *) TODAY=$(date -u +%Y-%m-%d) ;;
esac

awk -v want="## Schedule" -v line="Revised ${TODAY}: ${WORDS}." '
    BEGIN { pending = 0 }
    function flush_section(   i, e, prev) {
        e = n
        while (e >= 1 && buf[e] ~ /^[ \t]*$/) e--
        for (i = 1; i <= e; i++) print buf[i]
        prev = (e >= 1) ? buf[e] : ""
        if (prev !~ /^Revised [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:/) print ""
        print line
        print ""
        n = 0
    }
    $0 == want && !done { print; pending = 1; done = 1; n = 0; next }
    pending && /^## / { flush_section(); pending = 0; print; next }
    pending { buf[++n] = $0; next }
    { print }
    END { if (pending) flush_section() }
' "$CAND" > "${WORK}/next" && mv "${WORK}/next" "$CAND"

awk '
    { lines[NR] = $0 }
    END { e = NR; while (e >= 1 && lines[e] ~ /^[ \t]*$/) e--; for (i = 1; i <= e; i++) print lines[i] }
' "$CAND" > "${WORK}/next" && mv "${WORK}/next" "$CAND"

mv "$CAND" "$FILE"

git add "$FILE" 2>/dev/null || true

printf '{"amended": true, "path": "%s", "slug": "%s", "revised": [%s]}\n' \
    "$FILE" "$SLUG" "$REVISED"
