#!/bin/sh -eu
# Read back the finish line a run could not post, from a unit's branch story.
#
# The mirror of `record-unposted-line.sh`, and the only reader of that section's format. Two
# input shapes, because the two callers hold different things: a path, for a run standing in the
# worktree it just wrote, and `--ref <ref> --branch <branch>`, for a run reading another claim's
# tip with no worktree at all (the blob is fetched by the claim scan already, so this costs no
# network call).
#
# AN ABSENT SECTION IS NOT A FAILURE, and is the ordinary answer: every story written before this
# section existed, and every unit whose finish line landed, answers `found: false` with an empty
# reason. `readable: false` is the different fact -- the story itself could not be read -- and it
# is named rather than collapsed into `found: false`, because *nothing is waiting* and *I could
# not look* send a reader to different places.
#
# Usage: read-unposted-line.sh <story-file>
#        read-unposted-line.sh --ref <ref> --branch <branch>
# Output: {"found": bool, "readable": bool, "shape": "...", "reason": "...", "text": "...",
#          "unreadable_reason": ""}

set -eu

HEADING='## Unposted Line'

story=""
ref=""
branch=""

while [ $# -gt 0 ]; do
    case "$1" in
        --ref) ref="${2:-}"; shift 2 ;;
        --branch) branch="${2:-}"; shift 2 ;;
        *) story="$1"; shift ;;
    esac
done

json_str() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n\r\t' '   '
}

emit() {
    printf '{"found": %s, "readable": %s, "shape": "%s", "reason": "%s", "text": "%s", "unreadable_reason": "%s"}\n' \
        "$1" "$2" "$(json_str "${3:-}")" "$(json_str "${4:-}")" "$(json_str "${5:-}")" "${6:-}"
    exit 0
}

if [ -n "$ref" ] && [ -n "$branch" ]; then
    body=$(git cat-file blob "${ref}:.workaholic/stories/${branch}.md" 2>/dev/null || true)
    [ -n "$body" ] || emit false false "" "" "" story_unreadable
    block=$(printf '%s\n' "$body" | sed -n "/^${HEADING}\$/{n;n;p;n;p;n;p;}" 2>/dev/null || true)
else
    [ -n "$story" ] || emit false false "" "" "" no_story_argument
    [ -f "$story" ] || emit false false "" "" "" story_not_found
    block=$(sed -n "/^${HEADING}\$/{n;n;p;n;p;n;p;}" "$story" 2>/dev/null || true)
fi

[ -n "$block" ] || emit false true "" "" "" ""

shape=$(printf '%s\n' "$block" | sed -n '1s/^shape: //p')
why=$(printf '%s\n' "$block" | sed -n '2s/^reason: //p')
text=$(printf '%s\n' "$block" | sed -n '3s/^text: //p')

# A section present but not in the writer's own shape is a malformed record, never a line to
# send: posting a half-read line is the duplicate-or-wrong-text failure this whole record exists
# to avoid, so it reads as unreadable and the caller says so.
if [ -z "$shape" ] || [ -z "$why" ] || [ -z "$text" ]; then
    emit false false "" "" "" section_malformed
fi

emit true true "$shape" "$why" "$text" ""
