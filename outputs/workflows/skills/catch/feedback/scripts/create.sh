#!/bin/sh -eu
# Register one feedback: an immutable record of inbound project context, written to
# .workaholic/feedbacks/<YYYYMMDDHHMMSS>-<slug>.md (flat area — records never move).
# The body arrives on stdin, in the contributor's own words; frontmatter is stamped
# from the gather skill; the slug rule is REUSED from mission/scripts/slug.sh (the
# single slug source) and the timestamp prefix comes from created_at, so filenames
# sort chronologically and never collide. Refuses an existing filename and unknown
# kind/source values. Refreshes the OKF bundle indexes and git-stages the file.
#
# A feedback has NO status field and is never edited after this write — resolution
# or mootness is a NEW entry naming the old one via the optional supersedes
# argument (see feedback/SKILL.md, Immutability).
#
# THREE axes are recorded and they answer three different questions, so none of
# them substitutes for another (feedback/reference/schema.md, Field semantics):
#   subject = WHOSE opinion this is   (a person, a meeting, an observer AI, ...)
#   source  = WHICH CHANNEL it arrived through (meeting | slack | discussion | development)
#   author  = WHO RAN THE CAPTURE     (a git identity; under a routine, the runner)
# `subject` is REQUIRED and is never defaulted — least of all to the author. A
# routine writes most of this stream, so a defaulted subject would say every
# opinion in the project is the runner's, which is the exact failure `assignees`
# had before P6. A caller that does not know the subject must find it, not guess.
#
# A FOURTH FACT IS RECORDED WHEN THE ASK STATES IT: `review_surface`, the surface
# the person who asked will look at to judge whether the work landed — a package, a
# route, a screen, a rendered page. `work/scripts/feedback-outcome.sh` has always
# compared an `expected_surface` against the `verified_surface` a run observed, and
# until 2026-09-19 (ticket `20260919094701`) BOTH sides were supplied by whoever
# composed the facts: the gate's input was asserted by the party the gate checks,
# which is the same defect this repository names for `open_proposal` and for every
# proof in `drive/reference/claims.md`. Measured on a consuming repository: a request
# about a public prototype screen was implemented in the application package's shell,
# the item was closed, and the channel summary claimed the work landed.
#
# WHY THE FEEDBACK RECORD AND NOT THE TICKET OR THE MISSION. Three candidates, one
# chosen, and the two rejected are named here rather than left to be re-derived:
#   * THE FEEDBACK RECORD (chosen). It is the grain `feedback-outcome.sh` actually
#     reconciles — its items are keyed on `.feedback` — so the reader resolves the
#     value with no second walk and no relation. It is written once by ONE writer
#     (this script) from the person's own words, and it is IMMUTABLE, so the loop
#     cannot move the gate's input while implementing the work the gate checks.
#   * THE TICKET (rejected). Closest to the work, but a request routinely becomes
#     several tickets, so the reader would have to fold N values into one and decide
#     what a disagreement meant; and a replan rewrites tickets, which would hand the
#     implementing party the ability to edit the expectation it is judged against.
#   * THE MISSION (rejected). One value per correction pass is the right SHAPE, but a
#     mission is the loop's own decomposition rather than the ask, it is mutable, and
#     an ask answered by a loose ticket has no mission at all.
# The immutability objection — that a wrong surface can never be corrected — is
# answered by the stream's own correction mechanism: a new record naming the old in
# `supersedes` (SKILL.md, *Immutability*). A wrong PERSISTED surface is arguable by
# the person who wrote the ask; a wrong ASSERTED one is invisible.
#
# IT IS NEVER INFERRED AND NEVER FLOORED. It is written only when the ask names the
# surface; most asks are not about a rendered screen, so an absent value is the
# ORDINARY case and reconciles as `surface_unresolved` rather than as a pass. A
# guessed surface is worse than none, because the gate would then compare a guess
# against a guess.
#
# Usage: printf '%s\n' "<body>" | create.sh --subject <subject> [--review-surface <surface>] "<title>" <kind> <source> [supersedes-filename]
#   subject: <kind>[:<identity>]; kind is the closed set
#            person | meeting | observer_ai | customer | team | other
#            and the identity after the colon is free text ("person:a@qmu.jp",
#            "meeting:2026-08-13 planning", "observer_ai:[Implement] routine")
#   kind:    insight | instruction | concern | material | answer
#   source:  meeting | slack | discussion | development
# Output: JSON {created, path[, reason]}
#
# `--subject` is an OPTION, deliberately: the positional contract every caller
# already uses is left exactly where it was, so adding the axis moved no argument.

set -eu

SUBJECT=""
REVIEW_SURFACE=""
# Both are OPTIONS and both are read in a loop, deliberately: the positional
# contract every caller already uses is left exactly where it was, so adding an axis
# moves no argument, and a caller may pass them in either order.
while :; do
    case "${1:-}" in
        --subject) SUBJECT="${2:-}"; shift 2 || shift ;;
        --review-surface) REVIEW_SURFACE="${2:-}"; shift 2 || shift ;;
        *) break ;;
    esac
done

TITLE="${1:-}"
KIND="${2:-}"
SOURCE="${3:-}"
SUPERSEDES="${4:-}"

[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }

[ -n "$(printf '%s' "$SUBJECT" | tr -d '[:space:]')" ] || {
    echo '{"created": false, "reason": "no_subject"}'; exit 1; }
case "${SUBJECT%%:*}" in
    person|meeting|observer_ai|customer|team|other) : ;;
    *) echo '{"created": false, "reason": "bad_subject_kind"}'; exit 1 ;;
esac

case "$KIND" in
    insight|instruction|concern|material|answer) : ;;
    *) echo '{"created": false, "reason": "bad_kind"}'; exit 1 ;;
esac
# `development` was in this script's own usage header, in `SKILL.md` and in
# `validate-feedback.sh` and missing only here, so the one writer refused a value
# every reader accepted — found 2026-08-18 while filing a record about a defect
# born in development, which had to be filed as `discussion`. Widened rather than
# narrowed: three sources agree it is valid, and it is the one that names a
# concern the loop raised about itself.
case "$SOURCE" in
    meeting|slack|discussion|development) : ;;
    *) echo '{"created": false, "reason": "bad_source"}'; exit 1 ;;
esac

# Body from stdin. An empty body is refused: a feedback with no content records
# nothing — the record IS the prose.
BODY=$(cat)
[ -n "$(printf '%s' "$BODY" | tr -d '[:space:]')" ] || { echo '{"created": false, "reason": "empty_body"}'; exit 1; }

SCRIPT_DIR=$(dirname "$0")

# created_at / author from the single canonical gather script (one line per field).
META=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

# Timestamp prefix: the first 14 digits of created_at (YYYYMMDDHHMMSS).
TS=$(printf '%s' "$CREATED_AT" | tr -dc '0-9' | cut -c1-14)
[ -n "$TS" ] || { echo '{"created": false, "reason": "no_timestamp"}'; exit 1; }

# Slug rule lives in mission/scripts/slug.sh (the single source), reused verbatim.
SLUG=$(sh "${SCRIPT_DIR}/../../mission/scripts/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

DIR=".workaholic/feedbacks"
FILE="${DIR}/${TS}-${SLUG}.md"

if [ -e "$FILE" ]; then
    printf '{"created": false, "reason": "exists", "path": "%s"}\n' "$FILE"
    exit 1
fi

mkdir -p "$DIR"
{
    printf -- '---\n'
    printf 'type: Feedback\n'
    printf 'title: %s\n' "$TITLE"
    printf 'kind: %s\n' "$KIND"
    printf 'source: %s\n' "$SOURCE"
    printf 'subject: %s\n' "$SUBJECT"
    printf 'created_at: %s\n' "$CREATED_AT"
    printf 'author: %s\n' "$AUTHOR"
    printf 'supersedes: %s\n' "$SUPERSEDES"
    # One frontmatter line, so a multi-line surface is folded rather than corrupting
    # the block. Written always, empty when the ask named none — an absent value and
    # an empty one must read alike to `work/scripts/review-surface.sh`, and a key that
    # is sometimes missing is a key every reader has to test for twice.
    printf 'review_surface: %s\n' "$(printf '%s' "$REVIEW_SURFACE" | tr '\n' ' ')"
    printf -- '---\n'
    printf '\n# %s\n\n' "$TITLE"
    printf '%s\n' "$BODY"
} > "$FILE"

# Refresh the OKF bundle indexes so the registering commit ships a fresh hierarchy
# (best-effort: an index problem must not block feedback capture).
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

printf '{"created": true, "path": "%s", "review_surface": "%s"}\n' \
    "$FILE" "$(json_escape "$(printf '%s' "$REVIEW_SURFACE" | tr '\n' ' ')")"
