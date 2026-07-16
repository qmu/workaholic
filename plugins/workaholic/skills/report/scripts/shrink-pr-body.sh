#!/bin/sh -eu
# Bound a PR body file under GitHub's 65,536-character limit, in place.
# Usage: shrink-pr-body.sh <body-file> <branch>
# Output: JSON {shrunk, chars_before, chars_after}
#
# A carried concern corpus can push a story's section 6 past the GitHub PR-body
# limit, which used to hard-stop /report at its very last step (gh refuses the
# create/update). When the body is over the limit, section 6 (Concerns) is
# replaced with a pointer to the committed story file — safe because the
# ship-time extractor (extract-deferred-concerns.sh) reads the STORY FILE,
# never the PR body, so extraction is byte-identical either way. If the body
# is still over the limit after that (some other section is the culprit), it
# is hard-truncated with a trailing pointer — a truncated PR body beats no PR.
# A body already under the limit is returned untouched (shrunk: false).

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
pointer = (f"## 6. Concerns\n\nThe concern set is too large for a GitHub PR body "
           f"(65,536-character limit), so it is not inlined here. Read section 6 of the "
           f"committed story file on this branch: `{story}`. The ship-time deferred-concern "
           f"extractor reads that file, never this PR body, so nothing is lost.\n\n")
text = re.sub(r'^## 6\. Concerns\s*\n.*?(?=^## |\Z)', pointer, text,
              flags=re.MULTILINE | re.DOTALL)

if len(text) > LIMIT:
    note = f"\n\n*(PR body truncated at the GitHub limit — full text: `{story}`)*\n"
    text = text[:LIMIT - len(note)] + note

with open(path, 'w', encoding='utf-8') as h:
    h.write(text)
print(json.dumps({"shrunk": True, "chars_before": before, "chars_after": len(text)}))
PY
