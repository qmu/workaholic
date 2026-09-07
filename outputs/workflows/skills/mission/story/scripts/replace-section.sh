#!/bin/sh -eu
# Replace one level-two Markdown section without changing its neighbours.
# Usage: replace-section.sh FILE HEADING BODY_FILE

FILE=${1:-}; HEADING=${2:-}; BODY=${3:-}
[ -f "$FILE" ] && [ -f "$BODY" ] && [ -n "$HEADING" ] || {
  printf '{"ok":false,"reason":"invalid_arguments"}\n'; exit 1;
}
case "$HEADING" in '## '*) ;; *) HEADING="## $HEADING";; esac

tmp=$(mktemp); trap 'rm -f "$tmp" "${tmp}.clean"' EXIT HUP INT TERM
awk -v heading="$HEADING" -v body="$BODY" '
  function write_body( line) { while ((getline line < body) > 0) print line; close(body) }
  $0 == heading {
    if (!written) { print heading; print ""; write_body(); written=1 }
    skipping=1; next
  }
  skipping && /^## / { skipping=0 }
  !skipping { print }
  END { if (!written) { if (NR > 0) print ""; print heading; print ""; write_body() } }
' "$FILE" > "$tmp"
awk '{ lines[NR]=$0 } END { n=NR; while (n>0 && lines[n]=="") n--; for(i=1;i<=n;i++) print lines[i] }' "$tmp" > "${tmp}.clean"
printf '\n' >> "${tmp}.clean"
if cmp -s "$FILE" "${tmp}.clean"; then
  printf '{"ok":true,"changed":false}\n'
else
  cat "${tmp}.clean" > "$FILE"
  printf '{"ok":true,"changed":true}\n'
fi
