#!/bin/sh -eu
# Bound a PR body file under GitHub's 65,536-character limit, in place.
# Usage: shrink-pr-body.sh <body-file> <branch>
# Output: JSON {shrunk, chars_before, chars_after}
#
# A carried concern corpus can push a story's Concerns section past the GitHub
# PR-body limit, which used to hard-stop /story at its very last step (gh refuses
# the create/update). When the body is over the limit, the Concerns section is
# replaced with a pointer to the committed story file — safe because the
# ship-time extractor (extract-deferred-concerns.sh) reads the STORY FILE,
# never the PR body, so extraction is byte-identical either way. If the body
# is still over the limit after that (some other section is the culprit), it
# is hard-truncated with a trailing pointer — a truncated PR body beats no PR.
# A body already under the limit is returned untouched (shrunk: false).
#
# THE HANDOFF SECTION IS NEVER DROPPED. A handoff unit's PR body carries the one
# thing the person picking the work up actually needs — what is done, what is not,
# the exact next step — and it is written precisely when a run could not finish, so
# it must survive every bounding path here. Relying on its position (it is written
# at the very top, so a head-truncation happens to keep it) would be an accident one
# template edit away from silently dropping it, so retention is explicit: the block
# is lifted out, the remainder is bounded, and the block is put back. It is exempt
# only from SHEDDING, not from arithmetic — a handoff that alone exceeds the limit
# is still truncated, because no PR body at all helps nobody.

set -eu

body_file="${1:-}"
branch="${2:-}"

if [ -z "$body_file" ] || [ -z "$branch" ] || [ ! -f "$body_file" ]; then
  echo '{"error": "usage: shrink-pr-body.sh <body-file> <branch>"}' >&2
  exit 1
fi

python3 - "$body_file" "$branch" <<'PY'
import json, re, sys

path, branch = sys.argv[1], sys.argv[2]
LIMIT = 65536

with open(path, encoding='utf-8', errors='replace') as h:
    text = h.read()
before = len(text)

if before <= LIMIT:
    print(json.dumps({"shrunk": False, "chars_before": before, "chars_after": before}))
    sys.exit(0)

story = f".workaholic/stories/{branch}.md"

# Match the Concerns heading BY NAME, keeping whatever number it carries. Story
# sections are numbered sequentially over the sections a story actually has, so
# Concerns is not always section 6 -- and the pointer that replaces it must keep
# the body's own numbering intact rather than reintroducing a stale "6.".
CONCERNS_RE = re.compile(r'^(##\s+(?:\d+[.)]\s*)?Concerns[^\n]*)\n.*?(?=^## |\Z)',
                         flags=re.MULTILINE | re.DOTALL)


def _pointer(m):
    return (f"{m.group(1)}\n\nThe concern set is too large for a GitHub PR body "
            f"(65,536-character limit), so it is not inlined here. Read the Concerns "
            f"section of the committed story file on this branch: `{story}`. The "
            f"ship-time deferred-concern extractor reads that file, never this PR body, "
            f"so nothing is lost.\n\n")


text = CONCERNS_RE.sub(_pointer, text)

if len(text) > LIMIT:
    note = f"\n\n*(PR body truncated at the GitHub limit — full text: `{story}`)*\n"
    # Lift the Handoff block out before truncating, and put it back afterwards, so
    # the section a person needs most survives a bound applied for reasons that have
    # nothing to do with it. `## Handoff` is matched at the start of a line and runs
    # to the next `## ` heading (or EOF), the same shape the section-6 rule uses.
    m = re.search(r'^## Handoff\b.*?(?=^## |\Z)', text, flags=re.MULTILINE | re.DOTALL)
    handoff = m.group(0) if m else ""
    budget = LIMIT - len(note) - len(handoff)
    if handoff and budget > 0:
        rest = text[:m.start()] + text[m.end():]
        text = handoff + rest[:budget] + note
    else:
        # No handoff, or one so large it leaves no room for anything else: fall back
        # to the plain bound. A truncated body still beats a refused PR.
        text = text[:LIMIT - len(note)] + note

with open(path, 'w', encoding='utf-8') as h:
    h.write(text)
print(json.dumps({"shrunk": True, "chars_before": before, "chars_after": len(text)}))
PY
