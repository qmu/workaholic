#!/bin/sh -eu
# List feedback records ADDED under .workaholic/feedbacks/ between the cursor
# commit and origin/main (falling back to local main, then HEAD, when no origin
# is known - same resolution as cursor.sh's bootstrap). index.md excluded.
# Pure read; the window is exact because feedback records are immutable
# (docs/loop-engineering-workflow.md A3) - nothing is ever edited into novelty.
#
# Usage: new-feedback.sh <cursor-commit>
# Output: JSON array [{path, title, kind, source, author}], [] when none.

set -eu

CURSOR="${1:-}"
[ -n "$CURSOR" ] || { echo '[]'; exit 0; }

git rev-parse --verify -q "${CURSOR}^{commit}" >/dev/null 2>&1 || { echo '[]'; exit 0; }

TIP=$(git rev-parse --verify -q origin/main 2>/dev/null || true)
[ -n "$TIP" ] || TIP=$(git rev-parse --verify -q main 2>/dev/null || true)
[ -n "$TIP" ] || TIP=$(git rev-parse HEAD)

FILES=$(git diff --name-only --diff-filter=A "${CURSOR}".."${TIP}" -- '.workaholic/feedbacks/*.md' 2>/dev/null | grep -v '/index\.md$' || true)

# Frontmatter summary per record, assembled in one python pass (json escapes).
printf '%s\n' "$FILES" | python3 -c '
import json, re, sys, os
out = []
for line in sys.stdin:
    p = line.strip()
    if not p or not os.path.isfile(p):
        continue
    with open(p, encoding="utf-8", errors="replace") as h:
        t = h.read()
    m = re.match(r"^---\n(.*?)\n---\n", t, re.DOTALL)
    fm = m.group(1) if m else ""
    def get(k):
        km = re.search(r"^" + k + r":[ \t]*(.*)$", fm, re.MULTILINE)
        return km.group(1).strip() if km else ""
    out.append({"path": p, "title": get("title"), "kind": get("kind"),
                "source": get("source"), "author": get("author")})
print(json.dumps(out))
'
