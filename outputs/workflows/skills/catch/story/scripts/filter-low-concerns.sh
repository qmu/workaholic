#!/bin/sh -eu
# Drop the low-severity concern blocks from a PR-BODY file, in place.
# Usage: filter-low-concerns.sh <body-file> <branch>
# Output: JSON {filtered, dropped, kept}
#
# THE STORY FILE KEEPS EVERY SEVERITY; ONLY THIS RENDERING DROPS ANY. The committed
# story is the durable artifact and the ONLY thing ship's extract-deferred-concerns.sh
# parses, so every concern -- `low` included -- still becomes a kind: concern feedback
# record keyed on its concern_id. What this script changes is what a reviewer is asked
# to read: a `low` concern is a nice-to-have or a passing observation, and putting it in
# front of the reviewer costs attention that the urgent and moderate ones need.
#
# Filtering here rather than at write time is the whole point. A concern filtered out of
# the STORY would never be extracted, never keyed, and never join the open set later
# readers compute -- it would simply stop being recorded, silently, which is the masked
# failure the observability policy forbids. Divergence between story file and PR body is
# established practice, not a new idea: shrink-pr-body.sh already replaces this same
# section in the body with a pointer while the extractor keeps reading the file.
#
# What was dropped is always REPORTED, never merely absent: the section keeps a line
# naming the count and pointing at the story file, so a reviewer who wants the full set
# knows it exists and where it is.
#
# The Concerns heading is matched BY NAME, tolerating any leading number. Story sections
# are numbered sequentially over the sections a story actually has, so Concerns is not
# always section 6.

set -eu

body_file="${1:-}"
branch="${2:-}"

if [ -z "$body_file" ] || [ -z "$branch" ] || [ ! -f "$body_file" ]; then
  echo '{"error": "usage: filter-low-concerns.sh <body-file> <branch>"}' >&2
  exit 1
fi

python3 - "$body_file" "$branch" <<'PY'
import json, re, sys

path, branch = sys.argv[1], sys.argv[2]
story = f".workaholic/stories/{branch}.md"

with open(path, encoding='utf-8', errors='replace') as h:
    text = h.read()

SECTION_RE = re.compile(r'^(##\s+(?:\d+[.)]\s*)?Concerns[^\n]*\n)(.*?)(?=^## |\Z)',
                        flags=re.MULTILINE | re.DOTALL)

state = {"dropped": 0, "kept": 0, "filtered": False}


def is_low(block):
    m = re.search(r'^\s*-?\s*\*\*Severity:\*\*\s*(\S+)', block, re.MULTILINE)
    return bool(m) and m.group(1).strip().lower() == 'low'


def rewrite(m):
    heading, body = m.group(1), m.group(2)
    # The lookahead split always yields the pre-first-block text as element 0.
    parts = re.split(r'(?m)^(?=###\s)', body)
    preamble, blocks = parts[0], [p for p in parts[1:] if p.strip()]
    if not blocks:
        return m.group(0)

    kept = [b for b in blocks if not is_low(b)]
    dropped = len(blocks) - len(kept)
    state["kept"] += len(kept)
    if dropped == 0:
        return m.group(0)
    state["dropped"] += dropped
    state["filtered"] = True

    noun = "concern" if dropped == 1 else "concerns"
    note = (f"*{dropped} low-severity {noun} {'is' if dropped == 1 else 'are'} recorded in "
            f"the story file (`{story}`) and extracted to the feedback stream, but not "
            f"listed here.*\n\n")
    return heading + preamble + "".join(kept) + note


text = SECTION_RE.sub(rewrite, text)

if state["filtered"]:
    with open(path, 'w', encoding='utf-8') as h:
        h.write(text)

print(json.dumps({"filtered": state["filtered"],
                  "dropped": state["dropped"],
                  "kept": state["kept"]}))
PY
