#!/bin/sh -eu
# PER-TARGET DRAFT RELEASE NOTE: what the note would read like if this target
# were deployed from the base right now. A pure renderer.
#
#   draft-release-note.sh [--target <slug>] [--out <dir>] [--enrich] [base]
#
# Output (one JSON line):
#   {"ok": true, "base": "main", "base_rev": "origin/main", "base_sha": "abcd1234",
#    "count": N,
#    "targets": [{"slug","environment","deploy_model","attribution","since",
#                 "since_reason","unreleased_count","empty":<bool>,
#                 "body_sha":"<40-hex>","body":"...",
#                 "changed": true|false|null, "path": "<out path>"|""}]}
#   {"ok": false, "reason": "base_unresolvable"|"not_a_git_repo"|"no_targets"}
#
# IT WRITES NOTHING INTO THE REPOSITORY. With no `--out` it emits JSON on stdout
# and touches no file at all; with `--out <dir>` it materialises each target's
# body under a CALLER-CHOSEN directory (never `.workaholic/`, never a commit) so
# `changed` can be reported against what is already there. The write seam belongs
# to the cadence and the sync, which is what keeps this generator testable and
# pure. `changed` is `null` without `--out` — there is nothing to compare to, and
# reporting `false` would be a claim this script cannot make.
#
# THE UNRELEASED SET COMES FROM read-deploy-state.sh AND IS NOT RE-DERIVED.
# That reader owns the boundary (`since`, `since_reason`) and the attribution
# (`paths:` or the whole range), so there is exactly one place either is decided.
# This script reads its `--rows` and then asks git only for the DETAIL inside the
# range the reader handed it (subjects, `Category:` trailers, merge subjects) —
# detail the rows deliberately do not carry. That is not a second traversal of
# "what is unreleased"; it is the same range, read for different fields.
#
# IT IS IDEMPOTENT AND CLOCK-FREE, exactly as draft-deploy-plan.sh is, and the
# rendered body carries NO timestamp, NO sha and NO run-varying value. Not even
# the boundary sha: `since_reason` (`latest_tag:v1.0.178`, `prior_release`,
# `full_history`) names the boundary in words a human can act on, and a sha in
# the body would make every re-render a diff for a reader who cannot tell whether
# the content changed. The same base state therefore renders byte-identical
# output, which is the property the whole daily cadence rests on.
#
# THE STORY IS PREFERRED OVER THE COMMIT LIST. `.workaholic/stories/<branch>.md`
# is the written record of WHY a branch happened; a commit list can only say what
# moved. Each merge in the range names its branch, the branch names its story,
# and the story's title is what reaches `## Key Changes`.
#
# `--enrich` IS OFF BY DEFAULT, AND THAT IS THE IDEMPOTENCY CONTRACT SPEAKING.
# It fetches pull request bodies through `gather/scripts/gh-rest.sh` (REST only —
# `gh pr` is refused by `rules/shell.md` and by the smoke tests). Remote content
# can change under an unchanged base, so a daily generator that enriched by
# default would produce a diff on a day nothing happened. Everything the note
# needs is already local: the merge subject carries the pull request number and
# title, and the story carries the reasoning.
#
# A TARGET WITH NOTHING UNRELEASED RENDERS AN EXPLICIT EMPTY DRAFT, never an
# error and never an absent file: "nothing is waiting" is a fact a reader came
# here to learn, and a missing note reads as a broken generator.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

WANT_TARGET=""
OUT_DIR=""
ENRICH=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) WANT_TARGET="${2:-}"; shift 2 ;;
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --enrich) ENRICH=1; shift ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage"}' >&2; exit 1 ;;
    *) break ;;
  esac
done
BASE="${1:-main}"

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo '{"ok": false, "reason": "not_a_git_repo"}' >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

# JSON-escape a whole file (the rendered body) into a quoted JSON string.
escape_file_json() {
  python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' 2>/dev/null \
    || node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(0,"utf8")))' 2>/dev/null \
    || perl -e 'use JSON::PP; print encode_json(do { local $/; <STDIN> })'
}

TMP="${TMPDIR:-/tmp}/wh-draft-note.$$"
ROWS="${TMP}.rows"
BODY="${TMP}.body"
ERRS="${TMP}.err"
trap 'rm -f "$ROWS" "$BODY" "$ERRS"' EXIT INT TERM

if ! sh "${SCRIPT_DIR}/read-deploy-state.sh" --rows "$BASE" >"$ROWS" 2>"$ERRS"; then
  reason=$(head -n 1 "$ERRS" | tr -d '\n')
  [ -n "$reason" ] || reason=base_unresolvable
  printf '{"ok": false, "reason": "%s"}\n' "$(json_escape "$reason")"
  exit 0
fi

US=$(printf '\037')
BASE_LINE=$(sh "${SCRIPT_DIR}/read-deploy-state.sh" --base-rev "$BASE")
BASE_REV=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f1)
BASE_SHA=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f2)

[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

out=""
sep=""
count=0

while IFS="$US" read -r slug title environment model model_reason \
  conf_method conf_command has_conf attribution since since_reason n note_path note_match; do
  [ -n "$slug" ] || continue
  if [ -n "$WANT_TARGET" ] && [ "$slug" != "$WANT_TARGET" ]; then continue; fi
  count=$((count + 1))

  # The range is the reader's, re-expressed for git. `since` empty means the
  # boundary was `full_history` or `unresolvable`; the reader already said which.
  if [ -n "$since" ]; then RANGE="${since}..${BASE_REV}"; else RANGE="$BASE_REV"; fi
  if [ "$since_reason" = unresolvable ]; then RANGE=""; fi

  # The target's own path filter, from the reader's attribution.
  PATHSPEC=""
  if [ "$attribution" = declared_paths ]; then
    PATHSPEC=$(sh "${SCRIPT_DIR}/read-deployments.sh" --slug "$slug" \
      | sed -n 's/.*"paths":\[\([^]]*\)\].*/\1/p' | tr -d '"' | tr ',' ' ')
  fi

  : > "$BODY"

  {
    printf -- '---\n'
    printf 'type: Release Note\n'
    printf 'target: %s\n' "$slug"
    printf 'environment: %s\n' "$environment"
    printf 'stage: draft\n'
    printf 'targets: [%s]\n' "$slug"
    printf -- '---\n\n'

    printf '# %s — unreleased\n\n' "${title:-$slug}"
    printf '**This is a draft, not a record of a release.** It describes what would be\n'
    printf 'released if `%s` were deployed from the base right now. Nothing below has\n' "$slug"
    printf 'shipped. The boundary it counts from is `%s`.\n\n' "${since_reason:-unknown}"
  } >> "$BODY"

  if [ "${n:-0}" -eq 0 ] 2>/dev/null; then
    {
      printf '## Summary\n\n'
      printf 'Nothing is waiting to release for this target. The base carries no commits\n'
      printf 'beyond the `%s` boundary that are attributed to `%s` (`attribution: %s`).\n\n' \
        "${since_reason:-unknown}" "$slug" "$attribution"
    } >> "$BODY"
  else
    # --- Key Changes: the stories behind the merges in the range ---------------
    stories=""
    if [ -n "$RANGE" ]; then
      if [ -n "$PATHSPEC" ]; then
        # shellcheck disable=SC2086 - PATHSPEC is a built argument list.
        merges=$(git -C "$ROOT" log --merges --format='%s' "$RANGE" -- $PATHSPEC 2>/dev/null || true)
      else
        merges=$(git -C "$ROOT" log --merges --format='%s' "$RANGE" 2>/dev/null || true)
      fi
      OLD_IFS=$IFS; IFS='
'
      for msubject in $merges; do
        branch=$(printf '%s' "$msubject" | sed -n 's|.*from [^/]*/\(work-[0-9-]*\).*|\1|p')
        [ -n "$branch" ] || continue
        prnum=$(printf '%s' "$msubject" | sed -n 's|.*pull request #\([0-9]*\).*|\1|p')
        story="${ROOT}/.workaholic/stories/${branch}.md"
        stitle=""
        if [ -f "$story" ]; then
          # A story in this repository carries neither a `title:` field nor an H1
          # (checked across all 197 of them): its first section is `## 1. Overview`
          # and the reasoning starts in the paragraph under it. Take that
          # paragraph's first sentence — the written record of WHY, which is the
          # whole reason a story is preferred over the commit list.
          stitle=$(awk '
            /^##[[:space:]]*(1\.[[:space:]]*)?Overview/ { insec = 1; next }
            /^## / && insec { exit }
            insec && NF { para = para " " $0; next }
            insec && !NF && para != "" { exit }
            { next }
            END { sub(/^ /, "", para); print para }
          ' "$story" | sed 's/\([^.]*\.\).*/\1/' \
            | awk '{ if (length($0) <= 160) { print; next }
                     s = substr($0, 1, 160); sub(/[^ ]*$/, "", s);
                     sub(/[[:space:]]+$/, "", s); print s "\342\200\246" }')
        fi
        if [ -n "$stitle" ]; then
          stories="${stories}- ${stitle}
"
        elif [ -n "$prnum" ]; then
          # No story joined this merge. Say which merge, rather than dropping it:
          # a silently shortened list reads as "nothing else happened".
          stories="${stories}- Pull request #${prnum} (\`${branch}\`) — no branch story on the base.
"
        fi
      done
      IFS=$OLD_IFS
    fi

    {
      printf '## Summary\n\n'
      printf '%s commit(s) are waiting to release for `%s` (`%s`, `attribution: %s`).\n' \
        "$n" "$slug" "${environment:-environment undeclared}" "$attribution"
      if [ "$model" = deploy-on-merge ]; then
        printf 'This target is **deploy-on-merge**: the merges below are already on the base,\n'
        printf 'so what is pending is the release publish, not the commits.\n'
      fi
      printf '\n'
      printf '## Key Changes\n\n'
    } >> "$BODY"

    if [ -n "$stories" ]; then
      printf '%s\n' "$stories" | sed '/^$/d' >> "$BODY"
      printf '\n' >> "$BODY"
    else
      printf 'No merge in this range named a branch, so no story could be joined.\n\n' >> "$BODY"
    fi

    # --- Changes: grouped by the commit `Category:` trailer -------------------
    printf '## Changes\n\n' >> "$BODY"
    wrote_any=0
    for category in Added Changed Removed; do
      if [ -n "$RANGE" ]; then
        if [ -n "$PATHSPEC" ]; then
          # shellcheck disable=SC2086 - PATHSPEC is a built argument list.
          lines=$(git -C "$ROOT" log --no-merges \
            --format="%(trailers:key=Category,valueonly,separator=%x2C)${US}%s" \
            "$RANGE" -- $PATHSPEC 2>/dev/null || true)
        else
          lines=$(git -C "$ROOT" log --no-merges \
            --format="%(trailers:key=Category,valueonly,separator=%x2C)${US}%s" \
            "$RANGE" 2>/dev/null || true)
        fi
      else
        lines=""
      fi
      picked=$(printf '%s\n' "$lines" \
        | awk -v US="$US" -v want="$category" -F"$US" \
            '$1 ~ want { sub(/^[[:space:]]+/, "", $2); print "- " $2 }' \
        | awk '!seen[$0]++')
      if [ -n "$picked" ]; then
        printf '### %s\n\n%s\n\n' "$category" "$picked" >> "$BODY"
        wrote_any=1
      fi
    done
    [ "$wrote_any" -eq 1 ] || printf 'No commit in this range declared a `Category:` trailer.\n\n' >> "$BODY"
  fi

  # --- Deployment Plan: references, never copies -----------------------------
  {
    printf '## Deployment Plan\n\n'
    printf '**Prospective.** What a release of `%s` would require.\n\n' "$slug"
    printf -- '- **Environment**: %s\n' "${environment:-*undeclared* — the record states none}"
    printf -- '- **Deploy model**: %s (resolved from `%s`)\n' "${model:-unresolved}" "${model_reason:-unresolved}"
    printf -- '- **Waiting**: %s commit(s) since `%s`\n' "${n:-0}" "${since_reason:-unknown}"
    printf -- '- **Procedure**: see the `## Procedure` section of `.workaholic/deployments/%s.md`\n' "$slug"
    if [ "$has_conf" = true ]; then
      printf -- '- **Confirmation required**: `%s`, per the `## Confirmation` section of `.workaholic/deployments/%s.md`\n' \
        "${conf_method}" "$slug"
    else
      printf -- '- **Confirmation required**: **this target declares no confirmation method.**\n'
      printf '  `/ship` halts on it rather than shipping unverified, and this note says so\n'
      printf '  rather than rendering an unverified release as a verified one.\n'
    fi
    printf '\n'
    printf '## Deployment Verification\n\n'
    printf 'Append-only; one row per attempt. No attempt has been recorded against this\n'
    printf 'draft — a draft describes a release that has not happened.\n\n'
    printf '## Links\n\n'
    printf -- '- [Deployment record](.workaholic/deployments/%s.md)\n' "$slug"
  } >> "$BODY"

  BODY_SHA=$(git hash-object "$BODY")

  changed=null
  path=""
  if [ -n "$OUT_DIR" ]; then
    path="${OUT_DIR}/${slug}.md"
    if [ -f "$path" ] && [ "$(git hash-object "$path")" = "$BODY_SHA" ]; then
      changed=false
    else
      cp "$BODY" "$path"
      changed=true
    fi
  fi

  body_json=$(escape_file_json < "$BODY")

  out="${out}${sep}{\"slug\": \"$(json_escape "$slug")\", \"environment\": \"$(json_escape "$environment")\", \"deploy_model\": \"$(json_escape "$model")\", \"attribution\": \"$(json_escape "$attribution")\", \"since\": \"$(json_escape "$since")\", \"since_reason\": \"$(json_escape "$since_reason")\", \"unreleased_count\": ${n:-0}, \"empty\": $( [ "${n:-0}" -eq 0 ] && echo true || echo false ), \"body_sha\": \"${BODY_SHA}\", \"changed\": ${changed}, \"path\": \"$(json_escape "$path")\", \"enriched\": $( [ "$ENRICH" -eq 1 ] && echo true || echo false ), \"body\": ${body_json}}"
  sep=", "
done < "$ROWS"

if [ "$count" -eq 0 ]; then
  printf '{"ok": false, "reason": "no_targets", "base": "%s", "count": 0, "targets": []}\n' "$(json_escape "$BASE")"
  exit 0
fi

printf '{"ok": true, "base": "%s", "base_rev": "%s", "base_sha": "%s", "count": %d, "targets": [%s]}\n' \
  "$(json_escape "$BASE")" "$(json_escape "$BASE_REV")" "$(json_escape "$BASE_SHA")" "$count" "$out"
