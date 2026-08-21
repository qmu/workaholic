#!/bin/sh -eu
# Measure where a branch story's lines actually are, section by section.
#
# The story template is edited on assumption more often than on evidence: four
# structural edits landed on 2026-08-01 to make stories shorter and the mean grew
# 29% instead (127 -> 164 lines). This script is the instrument that answers
# "which section carries the lines" before a fifth edit is attempted, and the same
# instrument re-run afterwards is what proves the edit worked.
#
# Usage: story-sections.sh [--table] <story-file>...
# Output: JSON (default) or an aligned table (--table)
#   {files, total_lines, mean_lines, sections: [{name, files, total, mean, blocks}]}
#     files       stories measured
#     mean_lines  total_lines / files — the headline number
#     sections[]  one row per top-level `##` heading, ordered by total descending
#       name      heading text with any leading `N.` ordinal stripped, so
#                 `## 5. Concerns` and `## 6. Concerns` aggregate as one section
#                 (numbering is per-story navigation and is not stable — see the
#                 report skill's *Omit, never pad*)
#       files     how many of the measured stories carry the section at all
#       total     lines across every story, heading line included
#       mean      total / files-measured (NOT / files-carrying): a section present
#                 in half the stories contributes half as much to a story's length,
#                 and the question here is what a story costs on average
#       blocks    `###` subsections beneath it, summed — separates "this section is
#                 long because it has many blocks" from "its blocks are verbose"
#
# A section's lines include its blank lines and its `###` subsections; the counts
# therefore sum to the file's line count minus the YAML frontmatter, so shares are
# comparable. Content inside fenced code blocks never opens a section (a mermaid
# diagram or a markdown example carrying a `##` line is body text, not structure).

set -eu

FORMAT=json
if [ "${1:-}" = "--table" ]; then
    FORMAT=table
    shift
fi

if [ "$#" -eq 0 ]; then
    echo 'usage: story-sections.sh [--table] <story-file>...' >&2
    exit 2
fi

awk -v format="$FORMAT" '
FNR == 1 {
    nfiles++
    section = "(preamble)"
    fenced = 0
    infm = (NF > 0 && $0 == "---") ? 1 : 0
    fmline = 1
    seen_in_file_reset = 1
    delete seen_here
    next_is_body = 0
}
{
    # YAML frontmatter is metadata, not prose — excluded so shares sum to the body.
    if (infm) {
        if (FNR > 1 && $0 == "---") infm = 0
        next
    }
    if ($0 ~ /^```/) fenced = !fenced
    if (!fenced && $0 ~ /^## /) {
        name = substr($0, 4)
        sub(/^[0-9]+\.[ ]*/, "", name)
        sub(/[ \t]+$/, "", name)
        section = name
        if (!((FILENAME SUBSEP section) in seen_here)) {
            seen_here[FILENAME, section] = 1
            present[section]++
        }
        if (!(section in order)) order[section] = ++norder
    }
    if (!fenced && $0 ~ /^### /) blocks[section]++
    lines[section]++
    total++
}
END {
    if (nfiles == 0) exit 0
    n = 0
    for (s in lines) { names[++n] = s }
    # Order by total lines descending — the section carrying the growth reads first.
    for (i = 1; i < n; i++) {
        for (j = i + 1; j <= n; j++) {
            if (lines[names[j]] > lines[names[i]]) { t = names[i]; names[i] = names[j]; names[j] = t }
        }
    }
    if (format == "table") {
        printf "%-34s %6s %7s %8s %7s\n", "SECTION", "FILES", "TOTAL", "MEAN", "BLOCKS"
        for (i = 1; i <= n; i++) {
            s = names[i]
            printf "%-34s %6d %7d %8.1f %7d\n", s, present[s], lines[s], lines[s] / nfiles, blocks[s]
        }
        printf "%-34s %6d %7d %8.1f\n", "TOTAL", nfiles, total, total / nfiles
        exit 0
    }
    printf "{\"files\": %d, \"total_lines\": %d, \"mean_lines\": %.1f, \"sections\": [", nfiles, total, total / nfiles
    for (i = 1; i <= n; i++) {
        s = names[i]
        esc = s
        gsub(/\\/, "\\\\", esc)
        gsub(/"/, "\\\"", esc)
        printf "%s{\"name\": \"%s\", \"files\": %d, \"total\": %d, \"mean\": %.1f, \"blocks\": %d}",
            (i > 1 ? ", " : ""), esc, present[s], lines[s], lines[s] / nfiles, blocks[s]
    }
    printf "]}\n"
}
' "$@"
