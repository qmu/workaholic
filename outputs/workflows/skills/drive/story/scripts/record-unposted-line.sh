#!/bin/sh -eu
# Record a finish line the transport would not carry, into the unit's own branch story, so a
# later tick can send it.
#
# WHY IT EXISTS (2026-09-03, mission `deliver-a-post-the-transport-refused-or-say-it-reached-nobody`).
# A notification is never load-bearing, so a refused post has always been reported and then
# dropped -- and the report dies with the container. Measured 2026-09-02: two `/implement` runs
# minutes apart in one session, one with every connector call refused and three finish lines
# lost, the other posting three of the same shape. The loop turns every five minutes, so a post
# that failed once has a natural second chance and nothing was carrying it there.
#
# THE STORY IS THE HOME, AND NO NEW ARTIFACT IS CREATED. `.workaholic/stories/<branch>.md` is
# already the branch's own record of what its run did, already committed at the tip, and already
# the blob the claim oracle fetches -- `record-merge-outcome.sh` writes its section there for
# exactly this reason. Reading one more section out of a blob already in hand costs no network
# call and no second lookup.
#
# IT IS IDEMPOTENT: re-running with the same shape, reason and text rewrites nothing, and a
# later run recording a DIFFERENT line replaces the section rather than stacking a second one.
# The question is "what is still unsent", and two answers in one file is the ambiguity this
# exists to remove. `--clear` removes the section, and that is what a landed re-send calls: a
# duplicate post is the loud failure here and a lost one the quiet failure, so the record has to
# be precise enough to tell a landed line from an unsent one, and the tree is that record.
#
# IT IS NOT A RETRY MECHANISM AND NOT A TIMER. It writes a fact and nothing else. The re-send
# rides a tick that already runs (`workaholic:drive` §1); a tick that does not run simply does
# not retry, which is the bound that keeps this from becoming a second liveness authority
# beside the branch tip.
#
# Usage: record-unposted-line.sh <story-file> <shape> <reason> <text>
#        record-unposted-line.sh --clear <story-file>
#   <shape>  the post shape's own label, verbatim -- `🟢 Implemented`, `🟡 Handoff`, `📝 FB`.
#   <reason> why it did not post, in the notification-outcome vocabulary the caller already
#            reports: `post_refused`, `no_slack_transport`, `no_token`, `slack_<error>`. It is
#            NOT validated against a list here -- `workaholic:notify` owns that vocabulary and a
#            second copy of it is a second thing to keep in step.
#   <text>   the line itself, as it would have been posted.
#   Each of the three must be ONE line, because the reader takes one line each.
# Output: {"recorded": bool, "story": "...", "changed": bool, "cleared": bool, "reason": ""}

set -eu

HEADING='## Unposted Line'

cleared=false
if [ "${1:-}" = "--clear" ]; then
    cleared=true
    shift
    story="${1:-}"
    shape=""
    why=""
    text=""
else
    story="${1:-}"
    shape="${2:-}"
    why="${3:-}"
    text="${4:-}"
fi

# The inputs are echoed back sanitized: an unescaped quote or newline in the refusal itself
# would make the refusal invalid JSON, and a caller parsing it would get a syntax error instead
# of the reason (`record-merge-outcome.sh` carries the same guard for the same measured cause).
json_str() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n\r\t' '   '
}

emit() {
    printf '{"recorded": %s, "story": "%s", "changed": %s, "cleared": %s, "reason": "%s"}\n' \
        "$1" "$(json_str "$story")" "$3" "$cleared" "${2:-}"
    [ "$1" = "true" ] && exit 0 || exit 1
}

one_line() {
    [ "$(printf '%s' "$1" | wc -l | tr -d ' ')" = "0" ]
}

[ -n "$story" ] || emit false no_story_argument false
[ -f "$story" ] || emit false story_not_found false

if [ "$cleared" = "false" ]; then
    [ -n "$shape" ] || emit false no_shape_argument false
    [ -n "$why" ] || emit false no_reason_argument false
    [ -n "$text" ] || emit false no_text_argument false
    one_line "$shape" || emit false shape_not_one_line false
    one_line "$why" || emit false reason_not_one_line false
    one_line "$text" || emit false text_not_one_line false
fi

# The section is always heading, blank, then the three labelled lines in this order.
existing=$(sed -n "/^${HEADING}\$/{n;n;p;n;p;n;p;}" "$story" 2>/dev/null || true)

if [ "$cleared" = "true" ]; then
    [ -n "$existing" ] || emit true "" false
    tmp=$(mktemp)
    sed "/^${HEADING}\$/,\$d" "$story" > "$tmp"
    printf '%s\n' "$(cat "$tmp")" > "${tmp}.trimmed"
    mv "${tmp}.trimmed" "$story"
    rm -f "$tmp"
    emit true "" true
fi

wanted=$(printf 'shape: %s\nreason: %s\ntext: %s' "$shape" "$why" "$text")

if [ "$existing" = "$wanted" ]; then
    emit true "" false
fi

tmp=$(mktemp)
# Drop any previous section (it runs to end of file -- the section is always written last), then
# append the current answer. Exactly one blank line before the heading, whatever the body ended
# with.
sed "/^${HEADING}\$/,\$d" "$story" > "$tmp"
printf '%s' "$(cat "$tmp")" > "${tmp}.trimmed"
mv "${tmp}.trimmed" "$tmp"
{
    echo ""
    echo ""
    echo "$HEADING"
    echo ""
    echo "shape: $shape"
    echo "reason: $why"
    echo "text: $text"
} >> "$tmp"
mv "$tmp" "$story"

emit true "" true
