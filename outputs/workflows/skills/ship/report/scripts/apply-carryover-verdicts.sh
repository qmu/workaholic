#!/bin/bash
# Apply carry-over judge verdicts to the corresponding files. Verdicts arrive
# on stdin as a JSON array of {path, verdict, resolved_by_pr?, resolved_by_commit?}.
# For "resolved" verdicts, flips status, records the resolving PR/commit, and
# moves the file into .workaholic/concerns/archive/. For "still_active"
# verdicts, leaves the file untouched.
#
# Output: JSON summary {resolved: N, still_active: N, files_resolved: [...]}.
# The returned paths point to the new archive locations.

set -e

input=$(cat)

if [[ -z "$input" || "$input" == "[]" ]]; then
  echo '{"resolved":0,"still_active":0,"files_resolved":[]}'
  exit 0
fi

archive_dir=".workaholic/concerns/archive"
mkdir -p "$archive_dir"

# Use python (preferred) or node to parse JSON and emit shell-friendly lines.
parse() {
  python3 - "$input" <<'PY' 2>/dev/null
import json, sys
data = json.loads(sys.argv[1])
for item in data:
    path = item.get("path", "")
    verdict = item.get("verdict", "still_active")
    rpr = item.get("resolved_by_pr") or ""
    rcommit = item.get("resolved_by_commit") or ""
    # Tab-delimited so paths with spaces survive; paths shouldn't have tabs.
    print(f"{path}\t{verdict}\t{rpr}\t{rcommit}")
PY
}

resolved_count=0
still_active_count=0
files_resolved=()

while IFS=$'\t' read -r path verdict rpr rcommit; do
  [[ -z "$path" ]] && continue
  [[ ! -f "$path" ]] && continue

  if [[ "$verdict" == "resolved" ]]; then
    awk -v rpr="$rpr" -v rcommit="$rcommit" '
      /^---$/ { c++ }
      c==1 && /^status:/ { print "status: resolved"; next }
      c==1 && /^resolved_by_pr:/ { print "resolved_by_pr: " rpr; next }
      c==1 && /^resolved_by_commit:/ { print "resolved_by_commit: " rcommit; next }
      { print }
    ' "$path" > "${path}.tmp" && mv "${path}.tmp" "$path"

    dest="${archive_dir}/$(basename "$path")"
    git mv "$path" "$dest" 2>/dev/null || mv "$path" "$dest"
    resolved_count=$((resolved_count+1))
    files_resolved+=("$dest")
  else
    still_active_count=$((still_active_count+1))
  fi
done < <(parse)

# Build JSON output.
files_json="["
for idx in "${!files_resolved[@]}"; do
  if [[ $idx -gt 0 ]]; then
    files_json+=","
  fi
  files_json+="\"${files_resolved[$idx]}\""
done
files_json+="]"

echo "{\"resolved\":${resolved_count},\"still_active\":${still_active_count},\"files_resolved\":${files_json}}"
