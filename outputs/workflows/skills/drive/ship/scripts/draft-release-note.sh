#!/bin/sh -eu
# PER-TARGET DRAFT RELEASE NOTE: what the note would read like if this target
# were deployed from the base right now. A pure renderer.
#
#   draft-release-note.sh [--target <slug>] [--out <dir>] [--enrich]
#                         [--plan <path|->] [--facts-out <dir>] [base]
#
# Output (one JSON line):
#   {"ok": true, "base": "main", "base_rev": "origin/main", "base_sha": "abcd1234",
#    "count": N,
#    "targets": [{"slug","environment","deploy_model","attribution","since",
#                 "since_reason","unreleased_count","empty":<bool>,
#                 "body_sha":"<40-hex>","body":"...","plan":{...},
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
# THAT SENTENCE IS SUPERSEDED IN PLACE, NOT DELETED (2026-08-18, issue #512). It
# now reads: THE SAME BASE STATE PLUS THE SAME PLAN RENDERS BYTE-IDENTICAL OUTPUT.
# The property did not weaken and was never the defect -- the absence of judgment
# was. `--plan` accepts an agent-authored ARRANGEMENT of the facts this script
# derives (what ships together, in what order, at what risk, what is held back);
# with no plan the output is byte-identical to what this renderer produced before
# the seam existed, which is the one thing the seam had to prove. The plan is
# rendered by `render-release-plan.sh`, its document is
# `../reference/release-plan.md`, and a plan that cannot be applied (unreadable,
# malformed, written for another target, no `python3`) is NOT applied: the derived
# list renders and the named reason rides the JSON, because a note that looks
# planned and was not is worse than one that says it is a list.
#
# A PLAN WRITTEN FOR AN OLDER BASE IS RENDERED AS STALE, NOT AS CURRENT. The plan
# carries the `base_sha` it was written against; when that is not the base being
# rendered, the note says so in a line naming both shas, and everything the plan
# could not have known about falls into its *Not arranged by the plan* group. A
# stale plan is never silently refreshed -- refreshing it would mean authoring the
# judgment the plan exists to carry.
#
# THE PLAN'S HOME IS THE CALLER'S. This script reads `--plan` and looks in no
# well-known location, exactly as `--out` does. What is fixed is that no home may
# be inside git (SKILL.md §7's measured refusal applies unchanged: for a target
# declaring no `paths:`, the commit storing the plan increments the very count the
# plan is about) and that no home is trusted for freshness -- the document's own
# `base_sha` is what answers that.
#
# THE STORY IS PREFERRED OVER THE COMMIT LIST. `.workaholic/stories/<branch>.md`
# is the written record of WHY a branch happened; a commit list can only say what
# moved. Each merge in the range names its branch, the branch names its story,
# and the story's title is what reaches `## Key Changes`.
#
# WHEN NO STORY JOINED THE MERGE, THE FALLBACK IS THE MERGE COMMIT'S BODY — the
# pull request's own title (2026-08-18, issue #496). Until then this arm emitted
# `Pull request #N (branch) — no branch story on the base.`, a line whose entire
# content is the absence of a summary. It is not a rare fallback but a routine
# one: a `/specificate` pull request is published through the publish tree and
# auto-merges without ever running `/story`, so it structurally never has a
# story, and proposal merges are the most frequent merge kind in this repository.
#
# THE FALLBACK IS THE BODY, NOT THE SUBJECT, AND THAT DISTINCTION IS THE WHOLE
# FIX. The reporter proposed falling back to "the merge's own commit subject",
# and that subject reads `Merge pull request #503 from qmu/work-20260818-130444`
# — the number and the branch, which is exactly what the placeholder already
# said. GitHub puts the pull request's TITLE in the merge commit's body, so the
# informative string is local git data already in the range: no network, no
# `--enrich`, and byte-identical for an unchanged base.
#
# THE FALLBACK CHAIN, IN ORDER, AND WHY EACH RUNG EXISTS (2026-08-18, issue #512):
#
#   1. The branch story's Overview sentence -- the written record of WHY, and the
#      only rung a human authored about this change specifically.
#   2. The merge commit body's pull request title -- what the change was called.
#      Reached by every `/specificate` merge, which never has a story; measured on this
#      repository over `v1.0.170..main`, 38 of 68 merges (56%) land here.
#   3. `Pull request #N (branch)` -- a merge whose body somebody emptied. Named
#      rather than dropped: a shortened list reads as "nothing else happened".
#
# Rungs 2 and 3 then gain SUB-BULLETS from `resolve-merge-substance.sh`: what that
# merge published on the base -- the feedback record it wrote (`Asked for:`), the
# mission it planned, the tickets it queued. A story-bearing merge is never asked,
# because the story is the better answer and a second summary beside it would only
# compete with it. The labels are honest by design: a feedback record says what
# somebody ASKED FOR, which is not always what the merge DID, and a wrong summary
# is worse than a thin one. The detail rides the same row, so no merge is dropped,
# reordered or capped by it, and it is local git plus base-tree reads, so `--enrich`
# stays off by default and the same base state renders the same detail.
#
# "PREFER MERGES THAT HAVE A STORY" INTRODUCES NO SELECTION (the ticket's Open
# Decision, resolved here). Three readings were on the table; this is (a),
# fallback only, order unchanged and chronological:
#
#   - (b) Reorder so story-bearing lines come first. Refused: it turns the
#     section from a timeline into a ranking, which a reader of a release note
#     does not expect and cannot see the rule for.
#   - (c) Cap the list and fill the cap with story-bearing merges. Refused: it
#     silently drops merges, which is the exact failure mode the placeholder was
#     written to avoid ("a silently shortened list reads as 'nothing else
#     happened'"). A bounded section is not worth an unbounded lie.
#
# The renderer performs no selection today — it emits one line per merge in the
# whole range — so "prefer" had nothing to act on unless a cap or a reordering
# were added. With every line now carrying a title, there is nothing left to
# prefer away FROM: the report's actual complaint (lines that teach a reader
# nothing) is answered by the fallback alone.
#
# `--enrich` IS OFF BY DEFAULT, AND THAT IS THE IDEMPOTENCY CONTRACT SPEAKING.
# It fetches pull request bodies through `gather/scripts/gh-rest.sh` (REST only —
# `gh pr` is refused by `rules/shell.md` and by the smoke tests). Remote content
# can change under an unchanged base, so a daily generator that enriched by
# default would produce a diff on a day nothing happened. Everything the note
# needs is already local: the merge subject carries the pull request number, its
# body carries that pull request's title, and the story carries the reasoning.
#
# A TARGET WITH NOTHING UNRELEASED RENDERS AN EXPLICIT EMPTY DRAFT, never an
# error and never an absent file: "nothing is waiting" is a fact a reader came
# here to learn, and a missing note reads as a broken generator.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

WANT_TARGET=""
OUT_DIR=""
ENRICH=0
PLAN_PATH=""
FACTS_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target) WANT_TARGET="${2:-}"; shift 2 ;;
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --enrich) ENRICH=1; shift ;;
    --plan) PLAN_PATH="${2:-}"; shift 2 ;;
    --facts-out) FACTS_DIR="${2:-}"; shift 2 ;;
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

# Drop leading and trailing blank lines from a section body before it is quoted,
# so a record whose section starts on the line after its heading does not render
# an empty `>` row at the top of the quote.
trim_blank_edges() {
  awk 'BEGIN { started = 0 }
       { lines[NR] = $0; if (NF) { if (!started) { first = NR; started = 1 } last = NR } }
       END { for (i = first; i <= last; i++) print lines[i] }'
}

TMP="${TMPDIR:-/tmp}/wh-draft-note.$$"
ROWS="${TMP}.rows"
BODY="${TMP}.body"
ERRS="${TMP}.err"
FACTS="${TMP}.facts"
PLAN_FILE="${TMP}.plan"
PLAN_OUT="${TMP}.planout"
PLAN_STATUS="${TMP}.planstatus"
trap 'rm -f "$ROWS" "$BODY" "$ERRS" "$FACTS" "$PLAN_FILE" "$PLAN_OUT" "$PLAN_STATUS"' EXIT INT TERM

# `--plan -` is read ONCE, here: the render loop runs per target, and a stdin
# plan consumed by the first target would leave every later one planless for a
# reason nothing would report.
if [ "$PLAN_PATH" = "-" ]; then
  cat > "$PLAN_FILE"
  PLAN_PATH="$PLAN_FILE"
fi

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
# `--facts-out` materialises exactly what the plan seam is handed, so a PLANNER
# reads the same rows the renderer would render rather than deriving its own view
# of the range. One derivation, two readers.
[ -z "$FACTS_DIR" ] || mkdir -p "$FACTS_DIR"

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
  # Per target, because a plan names ONE target: a plan applied to the target it
  # was written for says nothing about the next one in the same run.
  PLAN_JSON='{"present": false, "reason": "not_supplied"}'
  [ -z "$PLAN_PATH" ] || PLAN_JSON='{"present": false, "reason": "empty_range"}'

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
    : > "$FACTS"
    if [ -n "$RANGE" ]; then
      # ONE LINE RULE, WRITTEN ONCE. Both sources of a `## Key Changes` line — the
      # story's Overview sentence and the merge body's pull request title — are cut
      # to the same 160 characters and balanced the same way, so this awk function
      # is textually shared by the two programs below rather than written twice.
      # `clamp()` never returns an odd number of backticks: an unclosed span
      # corrupts the markdown of everything after the line, so it is closed before
      # the ellipsis (measured 2026-08-18 over 199 stories: the clamp is the last
      # remaining way to open one).
      CLAMP_FN='
        function clamp(s,   ell) {
          ell = 0
          if (length(s) > 160) {
            s = substr(s, 1, 160); sub(/[^ ]*$/, "", s); sub(/[[:space:]]+$/, "", s)
            ell = 1
          }
          if (gsub(/`/, "`", s) % 2) s = s "`"
          if (ell) s = s "\342\200\246"
          return s
        }'
      # One record per merge, subject and body-title on ONE line so the loop below
      # keeps its line-at-a-time shape: records are separated by RS, the two fields
      # by US, and the body is reduced to its first non-empty line (GitHub writes
      # the pull request's title there).
      # THE SHA RIDES THE RECORD (2026-08-18, issue #512), because a story-less
      # merge's substance is resolved from that merge's own diff and there is no
      # second traversal to recover it from.
      MERGE_FMT='%x1e%H%x1f%s%x1f%b'
      merge_split='
        BEGIN { RS = "\036" }
        {
          if ($0 !~ /[^ \t\n]/) next
          i = index($0, "\037")
          if (i == 0) next
          sha = substr($0, 1, i - 1); rest = substr($0, i + 1)
          gsub(/[ \t\n]/, "", sha)
          j = index(rest, "\037")
          if (j == 0) { subj = rest; body = "" }
          else        { subj = substr(rest, 1, j - 1); body = substr(rest, j + 1) }
          gsub(/\n/, " ", subj)
          sub(/^[ \t]+/, "", subj); sub(/[ \t]+$/, "", subj)
          n = split(body, line, "\n"); t = ""
          for (k = 1; k <= n; k++) { if (line[k] ~ /[^ \t]/) { t = line[k]; break } }
          sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
          print sha "\037" subj "\037" clamp(t)
        }'
      if [ -n "$PATHSPEC" ]; then
        # shellcheck disable=SC2086 - PATHSPEC is a built argument list.
        merges=$(git -C "$ROOT" log --merges --format="$MERGE_FMT" "$RANGE" -- $PATHSPEC 2>/dev/null | awk "${CLAMP_FN}${merge_split}" || true)
      else
        merges=$(git -C "$ROOT" log --merges --format="$MERGE_FMT" "$RANGE" 2>/dev/null | awk "${CLAMP_FN}${merge_split}" || true)
      fi
      US=$(printf '\037')
      OLD_IFS=$IFS; IFS='
'
      for mrecord in $merges; do
        msha=${mrecord%%"$US"*}
        mrest=${mrecord#*"$US"}
        msubject=${mrest%%"$US"*}
        mtitle=${mrest#*"$US"}
        [ "$mtitle" != "$mrest" ] || mtitle=''
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
          ' "$story" | awk "${CLAMP_FN}"'
            {
              # A SENTENCE ENDS AT A PERIOD FOLLOWED BY WHITESPACE OR THE END OF THE
              # LINE (2026-08-18, ticket 20260818131500). The rule was "up to the
              # first period", which cut inside `check-version-bump.sh` and left an
              # unclosed backtick that corrupted the rest of the rendered release —
              # 32 of the 199 stories in this repository rendered that way. The cheaper
              # whitespace rule was measured against the whole corpus before the
              # backtick-aware alternative the ticket also offered: it fixes all 32
              # and mis-splits no abbreviation in any of them, so the more general
              # rule was not needed.
              out = $0
              n = length($0)
              for (i = 1; i <= n; i++) {
                if (substr($0, i, 1) != ".") continue
                if (i == n || substr($0, i + 1, 1) ~ /[ \t]/) { out = substr($0, 1, i); break }
              }
              print clamp(out)
            }')
        fi
        # ONE LINE, TWO CONSUMERS. The line is composed once and appended both to
        # the derived list and to the facts file a plan arranges, so a planned
        # note and a planless one can never disagree about what a merge says —
        # a plan supplies arrangement, never a change's own text.
        line=""
        if [ -n "$stitle" ]; then
          line="$stitle"
        elif [ -n "$mtitle" ]; then
          # No story joined this merge — the structural case for every `/specificate`
          # pull request, which auto-merges without ever running `/story`. The
          # merge commit's body is that pull request's own title, so the line says
          # what landed instead of saying that nothing says what landed.
          if [ -n "$prnum" ]; then
            line="${mtitle} (#${prnum})"
          else
            line="$mtitle"
          fi
        elif [ -n "$prnum" ]; then
          # Neither a story nor a title: a merge commit whose body somebody
          # emptied. Say which merge, rather than dropping it — a silently
          # shortened list reads as "nothing else happened".
          line="Pull request #${prnum} (\`${branch}\`) — no branch story on the base."
        fi
        # A STORY-LESS MERGE IS ASKED WHAT ELSE IT PUBLISHED (2026-08-18, issue
        # #512). 38 of 68 merges over `v1.0.170..main` carry no story — the
        # majority path — and the substance is already on the base: the proposal's
        # feedback record, the mission it planned, the tickets it queued. The
        # detail rides the SAME row as sub-bullets: no merge is dropped, reordered
        # or capped by it, and a merge that published nothing renders unchanged.
        # A merge WITH a story is never asked — the story is the better answer and
        # a second summary beside it would only compete with it.
        detail=""
        if [ -z "$stitle" ] && [ -n "$line" ]; then
          detail=$(sh "${SCRIPT_DIR}/resolve-merge-substance.sh" "$msha" 2>/dev/null \
            | awk "${CLAMP_FN}"'NF { print clamp($0) }' || true)
        fi
        if [ -n "$line" ]; then
          stories="${stories}- ${line}
"
          factline="$line"
          if [ -n "$detail" ]; then
            OLD_IFS2=$IFS; IFS='
'
            for dline in $detail; do
              stories="${stories}  - ${dline}
"
              factline="${factline}$(printf '\036')${dline}"
            done
            IFS=$OLD_IFS2
          fi
          printf '%s%s%s%s%s\n' "$prnum" "$US" "$branch" "$US" "$factline" >> "$FACTS"
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

    [ -z "$FACTS_DIR" ] || cp "$FACTS" "${FACTS_DIR}/${slug}.facts"

    # A plan arranges this section or nothing does. `present: false` — including
    # every refusal — falls through to the derived list below, unchanged.
    if [ -n "$PLAN_PATH" ]; then
      : > "$PLAN_OUT"
      printf '{"present": false, "reason": "unreadable"}\n' > "$PLAN_STATUS"
      sh "${SCRIPT_DIR}/render-release-plan.sh" --plan "$PLAN_PATH" --facts "$FACTS" \
        --target "$slug" --base-sha "$BASE_SHA" --status-out "$PLAN_STATUS" \
        > "$PLAN_OUT" 2>/dev/null || true
      PLAN_JSON=$(cat "$PLAN_STATUS")
    fi

    if [ -n "$PLAN_PATH" ] && [ -s "$PLAN_OUT" ] \
      && grep -q '"present": true' "$PLAN_STATUS" 2>/dev/null; then
      cat "$PLAN_OUT" >> "$BODY"
      printf '\n' >> "$BODY"
    else
      # A PLAN WAS EXPECTED AND DID NOT ARRIVE: SAY SO ON THE NOTE'S FACE
      # (2026-08-18, Open Decision 2 on the planner ticket). Passing `--plan` IS
      # the expectation, so any non-application under it is visible here as well
      # as in the JSON — otherwise a reader cannot tell a deliberate list from a
      # planner that broke, which is the one thing this fallback must not hide. A
      # render with no `--plan` at all expects nothing and stays silent.
      if [ -n "$PLAN_PATH" ]; then
        plan_reason=$(printf '%s' "$PLAN_JSON" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
        case "${plan_reason:-unknown}" in
          empty_range) : ;;
          *)
            printf '> *No release plan was applied to this draft (`%s`), so the merges below\n' \
              "${plan_reason:-unknown}"
            printf '> are listed as derived rather than arranged.*\n\n' ;;
        esac >> "$BODY"
      fi
      if [ -n "$stories" ]; then
        printf '%s\n' "$stories" | sed '/^$/d' >> "$BODY"
        printf '\n' >> "$BODY"
      else
        printf 'No merge in this range named a branch, so no story could be joined.\n\n' >> "$BODY"
      fi
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
    printf -- '- **Confirmation method**: %s\n' \
      "$( [ "$has_conf" = true ] && printf '`%s`' "$conf_method" \
          || printf '**none declared** — `/ship` halts on this target rather than shipping it unverified, and this note says so rather than rendering an unverified release as a verified one' )"
    printf '\n'
  } >> "$BODY"

  # The procedure and the confirmation are QUOTED, not referenced — and the quote
  # is regenerated from the record on every render, so it cannot drift from the
  # text `/ship` gates on. The citation names the authored source and says which
  # document to edit, which is what keeps this from becoming a second, editable
  # copy of a human's contract.
  {
    printf '### Procedure\n\n'
    printf 'Quoted verbatim from the `## Procedure` section of\n'
    printf '`.workaholic/deployments/%s.md`, which a human authors. Edit that record —\n' "$slug"
    printf 'never this note: the quote is regenerated on every render and anything typed\n'
    printf 'here is lost.\n\n'
  } >> "$BODY"
  proc=$(sh "${SCRIPT_DIR}/read-deployments.sh" --section "$slug" Procedure || true)
  if [ -n "$(printf '%s' "$proc" | tr -d '[:space:]')" ]; then
    printf '%s\n' "$proc" | trim_blank_edges | sed 's/^/>/;s/^>\(.\)/> \1/' >> "$BODY"
    printf '\n' >> "$BODY"
  else
    printf '> *The record declares no `## Procedure`.*\n\n' >> "$BODY"
  fi

  {
    printf '### Verification required after release\n\n'
    printf 'Quoted verbatim from the `## Confirmation` section of\n'
    printf '`.workaholic/deployments/%s.md`. This is the evidence the gate rests on.\n\n' "$slug"
  } >> "$BODY"
  conf=$(sh "${SCRIPT_DIR}/read-deployments.sh" --section "$slug" Confirmation || true)
  if [ -n "$(printf '%s' "$conf" | tr -d '[:space:]')" ]; then
    printf '%s\n' "$conf" | trim_blank_edges | sed 's/^/>/;s/^>\(.\)/> \1/' >> "$BODY"
    printf '\n' >> "$BODY"
  else
    printf '> *The record declares no `## Confirmation`, so there is nothing to run and\n'
    printf '> nothing this note could report as verified.*\n\n' >> "$BODY"
  fi

  # --- Releases: what the plan above turned into ------------------------------
  # THE JOIN (2026-08-18, issue #512's fourth gap). The plan, the release and the
  # verification were three correct records in three places, so no single document
  # carried a release through its life. They are DERIVED here rather than copied:
  # `read-release-history.sh` reads the records their own writers own, so this adds
  # no third store and cannot violate their append-only order — it never writes.
  releases=$(sh "${SCRIPT_DIR}/read-release-history.sh" --releases 2>/dev/null || true)
  {
    printf '## Releases\n\n'
    printf 'Derived from `.workaholic/releases/` — the durable ship records, written at the\n'
    printf 'cut by `record-release-cut.sh` and at each confirmation attempt by\n'
    printf '`confirm-release.sh`. A window is **repository-wide**: it carries the whole\n'
    printf 'batch, so a confirmation here says the batch containing `%s` reached\n' "$slug"
    printf 'production, not that this target was checked on its own — the per-target\n'
    printf 'evidence is the section below.\n\n'
  } >> "$BODY"
  if [ -n "$releases" ]; then
    printf '%s\n\n' "$releases" >> "$BODY"
  else
    printf 'No release has been cut yet, so nothing above has left the base.\n\n' >> "$BODY"
  fi

  attempts=$(sh "${SCRIPT_DIR}/read-release-history.sh" --attempts --target "$slug" 2>/dev/null || true)
  {
    printf '## Deployment Verification\n\n'
    printf 'Append-only; one block per attempt, written by `record-evidence.sh` — the one\n'
    printf 'writer that also fills the branch story, so the two cannot disagree. Each block\n'
    printf 'names the target, the declared method, the exact check that ran, the observed\n'
    printf 'result, and one of `pass` / `fail` / `not_run` / `bypassed`. A later attempt\n'
    printf 'adds a block and never rewrites an earlier one.\n\n'
  } >> "$BODY"
  if [ -n "$attempts" ]; then
    # Every recorded outcome, in the order it was recorded — `fail`, `not_run` and
    # `bypassed` exactly as visible as `pass`, because a continuity feature that
    # showed only successes would make an unverified release read as a verified one.
    {
      printf 'Recorded against `%s` so far, derived from\n' "$slug"
      printf '`.workaholic/release-notes/%s.md` (its own writer appends there; this is a\n' "$slug"
      printf 'projection and never a second record):\n\n'
    } >> "$BODY"
    printf '%s\n\n' "$attempts" >> "$BODY"
  else
    printf 'No attempt has been recorded against this target — a draft describes a release\n' >> "$BODY"
    printf 'that has not happened.\n\n' >> "$BODY"
  fi
  {
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

  out="${out}${sep}{\"slug\": \"$(json_escape "$slug")\", \"environment\": \"$(json_escape "$environment")\", \"deploy_model\": \"$(json_escape "$model")\", \"attribution\": \"$(json_escape "$attribution")\", \"since\": \"$(json_escape "$since")\", \"since_reason\": \"$(json_escape "$since_reason")\", \"unreleased_count\": ${n:-0}, \"empty\": $( [ "${n:-0}" -eq 0 ] && echo true || echo false ), \"body_sha\": \"${BODY_SHA}\", \"changed\": ${changed}, \"path\": \"$(json_escape "$path")\", \"enriched\": $( [ "$ENRICH" -eq 1 ] && echo true || echo false ), \"plan\": ${PLAN_JSON}, \"body\": ${body_json}}"
  sep=", "
done < "$ROWS"

if [ "$count" -eq 0 ]; then
  printf '{"ok": false, "reason": "no_targets", "base": "%s", "count": 0, "targets": []}\n' "$(json_escape "$BASE")"
  exit 0
fi

printf '{"ok": true, "base": "%s", "base_rev": "%s", "base_sha": "%s", "count": %d, "targets": [%s]}\n' \
  "$(json_escape "$BASE")" "$(json_escape "$BASE_REV")" "$(json_escape "$BASE_SHA")" "$count" "$out"
