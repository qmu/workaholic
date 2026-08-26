#!/bin/sh -eu
# WHAT HAS ALREADY BEEN RELEASED AND WHETHER ANYONE CONFIRMED IT — the reader that
# joins a target's draft plan to the releases and verifications that followed it.
#
#   read-release-history.sh [--target <slug>] [--releases] [--attempts]
#
# Stdout: rendered markdown lines (no heading — the caller owns those), one per
# record, newest first. With neither flag both sections are emitted, separated by a
# blank line. No records ⇒ no lines, and the caller says what that means.
#
# WHY THIS EXISTS (2026-08-18, issue #512's fourth gap). The pieces were separately
# correct and never joined: `/ship` §5-D records a deployment attempt into the
# story AND into `.workaholic/release-notes/<slug>.md`'s append-only
# `## Deployment Verification`; `record-release-cut.sh` and `confirm-release.sh`
# write the durable window record under `.workaholic/releases/`. A reader opening a
# target's draft saw the plan and nothing that came after it, so "plan → release →
# verification" was three documents in three places.
#
# IT CREATES NO THIRD STORE, WHICH IS THE WHOLE CONSTRAINT. Two stores exist by
# decision and the DERIVATION is the source of truth (`../SKILL.md` §7, *The two
# copies*). This reads the existing records and renders them; it writes nothing,
# appends nothing, and owns nothing. Continuity is achieved by deriving more into
# the one document, never by copying records into a new home that would drift.
#
# APPEND-ONLY IS PRESERVED BY NOT WRITING AT ALL. `record-evidence.sh` stays the one
# writer of an attempt and `confirm-release.sh` of a confirmation; a projection that
# re-rendered them could not violate their order because it never touches them.
#
# THE UNFLATTERING OUTCOMES RENDER EXACTLY AS LOUDLY AS `pass`. `fail`, `not_run`
# and `bypassed` are first-class in `/ship`'s contract, and a continuity feature
# that quietly showed only the successes would be worse than no continuity: it
# would make an unverified release look verified, which is the failure the whole
# verification section exists to prevent.
#
# TWO SCOPES, LABELLED, NEVER MERGED. A release window is repository-wide (a
# `release/*` branch carries the whole batch) while a deployment attempt is
# per-target. Rendering the first as if it were the second would tell a reader that
# their target was confirmed when what was confirmed was a batch containing it.

set -eu

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

TARGET=""
WANT_RELEASES=0
WANT_ATTEMPTS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --releases) WANT_RELEASES=1; shift ;;
    --attempts) WANT_ATTEMPTS=1; shift ;;
    *) echo "usage" >&2; exit 2 ;;
  esac
done
if [ "$WANT_RELEASES" -eq 0 ] && [ "$WANT_ATTEMPTS" -eq 0 ]; then
  WANT_RELEASES=1
  WANT_ATTEMPTS=1
fi

fm() {  # fm <file> <key> — the value of a frontmatter key, first block only.
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && /^---[[:space:]]*$/ { exit }
    index($0, key ":") == 1 {
      sub(/^[^:]*:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit
    }
  ' "$1"
}

if [ "$WANT_RELEASES" -eq 1 ]; then
  DIR="${ROOT}/.workaholic/releases"
  if [ -d "$DIR" ]; then
    # Newest first, by filename: a release record is named for its branch, whose
    # name is the cut timestamp, so the sort is chronological by construction.
    for f in $(find "$DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null | LC_ALL=C sort -r); do
      [ "$(basename "$f")" != "index.md" ] || continue
      branch=$(fm "$f" release_branch)
      [ -n "$branch" ] || continue
      status=$(fm "$f" status)
      cut_at=$(fm "$f" cut_at)
      carried=$(fm "$f" carried_count)
      method=$(fm "$f" confirmation_method)
      cstatus=$(fm "$f" confirmation_status)
      confirmed=$(fm "$f" confirmed_at)
      tag=$(fm "$f" tag)
      line="- \`${branch}\` — cut ${cut_at:-at an unrecorded time}, ${carried:-?} commit(s), **${status:-unknown}**"
      [ -z "$confirmed" ] || line="${line}; confirmation ${cstatus:-unrecorded} at ${confirmed}"
      [ -z "$method" ] || line="${line} (\`${method}\`)"
      [ -z "$tag" ] || line="${line}, tag \`${tag}\`"
      printf '%s\n' "$line"
    done
  fi
fi

if [ "$WANT_ATTEMPTS" -eq 1 ] && [ -n "$TARGET" ]; then
  [ "$WANT_RELEASES" -eq 0 ] || printf '\n'
  NOTE="${ROOT}/.workaholic/release-notes/${TARGET}.md"
  if [ -f "$NOTE" ]; then
    # Every `### Attempt` block under `## Deployment Verification`, reduced to the
    # one line a reader of the plan needs: when, what status, by which method.
    awk '
      /^## Deployment Verification[[:space:]]*$/ { insec = 1; next }
      /^## / && insec { insec = 0 }
      insec && /^### Attempt/ { when = ""; status = ""; method = ""; target = ""; have = 1 }
      insec && have && /^- \*\*When:\*\*/  { when = $0; sub(/^- \*\*When:\*\*[[:space:]]*/, "", when) }
      insec && have && /^- \*\*Target:\*\*/ { target = $0; sub(/^- \*\*Target:\*\*[[:space:]]*/, "", target) }
      insec && have && /^- \*\*Method declared:\*\*/ { method = $0; sub(/^- \*\*Method declared:\*\*[[:space:]]*/, "", method) }
      insec && have && /^- \*\*Status:\*\*/ {
        status = $0; sub(/^- \*\*Status:\*\*[[:space:]]*/, "", status)
        printf "- %s — **%s** (`%s`)%s\n", (when == "" ? "at an unrecorded time" : when),
          status, (method == "" ? "no method declared" : method),
          (target == "" ? "" : ", target `" target "`")
        have = 0
      }
    ' "$NOTE"
  fi
fi
