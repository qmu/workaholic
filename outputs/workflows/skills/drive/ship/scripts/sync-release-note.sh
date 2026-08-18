#!/bin/sh -eu
# SYNC THE TWO COPIES OF A TARGET'S RELEASE NOTE — the GitHub side and the
# `.workaholic` side — and report every divergence by name before writing.
#
#   sync-release-note.sh [--target <slug>] [--dry-run] [base]
#
# Output (one JSON line):
#   {"ok": true, "authoritative": "derived", "count": N,
#    "targets": [{"slug","tag","github_state":"draft"|"published"|"absent"|"unreadable",
#                 "workaholic_path":"..."|"", "changed":<bool>, "written":<bool>,
#                 "reason":"...", "divergences":[{"section","side","detail"}]}]}
#   {"ok": false, "reason": "gh_unavailable"|"no_targets"|...}
#
# ── WHICH COPY IS THE SOURCE OF TRUTH (the Open Decision, ruled 2026-08-17) ──
#
# NEITHER STORE IS. The authority is the DERIVATION: `draft-release-note.sh`
# rendering the base state. Both stores are projections of it, which is how
# "always identical" is guaranteed by construction rather than by copying — one
# renderer, one input, so wherever both copies exist they are byte-identical.
#
# Of the three candidates the ticket named:
#   (a) `.workaholic` authoritative, GitHub projected — refused on the measured
#       number. `paths:` is declared on 0 of 1 targets here, so under
#       `attribution: whole_range` a note commit is 100% self-counted and a daily
#       writer is +365 commits/year on `main`, each invalidating the next. That is
#       the treadmill `workaholic:ship` §7 refused, and daily does not dissolve it.
#   (c) both authoritative for different sections — the most honest description of
#       what will happen and the hardest to keep coherent; it makes "which side is
#       wrong" unanswerable, which is the failure the ask is trying to avoid.
#   (b) GitHub authoritative while drafting — CHOSEN, in the sharpened form above.
#       A GitHub DRAFT release is invisible to consumers and free to rewrite, which
#       makes it the natural home for a daily-regenerated document, and it costs no
#       commit at all. The ticket's objection was that (b) weakens "always
#       identical" to "identical once released"; naming the DERIVATION as the
#       authority answers it — the `.workaholic` copy is written at release time by
#       the existing `commit-release-note.sh` from the same renderer, so it is
#       identical the moment it exists rather than merely eventually.
#
# THE WRITER IS A PROJECTION AND NEVER A MERGE. It renders the authoritative
# content and overwrites the draft release's body with it. It never combines the
# two sides, because merging would create content neither the base nor a human
# authored. A human's edit on the GitHub side is therefore a DIVERGENCE — reported
# by target and section, never silently repaired and never silently kept.
#
# THIS SCRIPT WRITES NOTHING INTO GIT. No file, no commit, no branch. The only
# write it makes is to a GitHub DRAFT release through `gh release` (REST-backed and
# explicitly sanctioned by `rules/shell.md`; `gh pr`/`gh issue`/`gh repo` stay
# refused). The `.workaholic` copy is written at release time by the existing
# writer — this script only reads and compares it.
#
# A PUBLISHED RELEASE IS NEVER OVERWRITTEN FROM A DRAFT. Checked before any write
# and reported as `published_release`. `.github/workflows/release.yml` publishes
# `v<version>` on a version bump pushed to `main`, so the GitHub side has a second
# writer this sync must not fight: the draft's tag is `draft/<slug>`, which cannot
# collide with a `v*` tag, and a release found not to be a draft is left alone
# whatever its tag.
#
# IT IS IDEMPOTENT. The body is compared before it is sent; equal bodies make no
# API call at all and report `changed: false`.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

WANT_TARGET=""
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) WANT_TARGET="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
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

TMP="${TMPDIR:-/tmp}/wh-sync-note.$$"
DERIVED="${TMP}.derived"
REMOTE="${TMP}.remote"
LOCAL="${TMP}.local"
SECA="${TMP}.seca"
SECB="${TMP}.secb"
trap 'rm -f "$DERIVED" "$REMOTE" "$LOCAL" "$SECA" "$SECB"' EXIT INT TERM

# Section-level comparison. A note's sections are its `## ` headings; comparing
# whole bodies would only ever say "they differ", and the point of this report is
# to say WHERE, so a human can tell an edit from a stale render.
section_names() {
  awk '/^## / { sub(/^## /, ""); print }' "$1"
}
section_body() {
  awk -v want="## $2" '
    $0 == want { insec = 1; next }
    /^## / && insec { insec = 0 }
    insec { print }
  ' "$1"
}

# Read one top-level string/bool out of a JSON object on stdin. One helper, so a
# spacing difference between producers cannot silently change a decision: an
# earlier version matched `"isDraft":true` with a sed pattern that allowed no
# space after the colon, and a producer that emitted one made every draft read as
# PUBLISHED — which would have turned "never overwrite a published release" into
# "never write anything at all", a refusal that looks like success.
json_field() {
  python3 -c 'import json,sys
d = json.load(sys.stdin)
v = d.get(sys.argv[1], "")
sys.stdout.write(v if isinstance(v, str) else ("true" if v is True else "false" if v is False else str(v)))' "$1" 2>/dev/null \
    || node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const v=(JSON.parse(s)||{})[process.argv[1]];process.stdout.write(typeof v==="string"?v:String(v===undefined?"":v))})' "$1" 2>/dev/null \
    || printf ''
}

if ! command -v gh >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "gh_unavailable", "authoritative": "derived"}\n'
  exit 0
fi

DRAFT_JSON=$(sh "${SCRIPT_DIR}/draft-release-note.sh" ${WANT_TARGET:+--target "$WANT_TARGET"} "$BASE")
if ! printf '%s' "$DRAFT_JSON" | grep -q '"ok": true'; then
  reason=$(printf '%s' "$DRAFT_JSON" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
  printf '{"ok": false, "reason": "%s", "authoritative": "derived"}\n' "$(json_escape "${reason:-draft_failed}")"
  exit 0
fi

SLUGS=$(printf '%s' "$DRAFT_JSON" | tr ',' '\n' | sed -n 's/.*"slug": "\([^"]*\)".*/\1/p')

out=""
sep=""
count=0

for slug in $SLUGS; do
  count=$((count + 1))
  tag="draft/${slug}"

  # The authoritative content: rendered fresh, never read back from a store.
  sh "${SCRIPT_DIR}/draft-release-note.sh" --target "$slug" "$BASE" \
    | (python3 -c 'import json,sys; sys.stdout.write(json.load(sys.stdin)["targets"][0]["body"])' 2>/dev/null \
       || node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).targets[0].body))' 2>/dev/null) \
    > "$DERIVED"

  # --- the GitHub side ------------------------------------------------------
  github_state=absent
  : > "$REMOTE"
  if view=$(gh release view "$tag" --json isDraft,body 2>/dev/null); then
    is_draft=$(printf '%s' "$view" | json_field isDraft)
    printf '%s' "$view" | json_field body > "$REMOTE" || : > "$REMOTE"
    if [ "$is_draft" = true ]; then github_state=draft; else github_state=published; fi
  fi

  # --- the .workaholic side (read only; written at release time) -------------
  wh_path=""
  : > "$LOCAL"
  candidate="${ROOT}/.workaholic/release-notes/${slug}.md"
  if [ -f "$candidate" ]; then
    wh_path=".workaholic/release-notes/${slug}.md"
    cp "$candidate" "$LOCAL"
  fi

  # --- divergences, per section, BEFORE anything is written ------------------
  divs=""
  dsep=""
  for store in github workaholic; do
    case "$store" in
      github) other="$REMOTE"; present=$( [ "$github_state" = absent ] && echo 0 || echo 1 ) ;;
      workaholic) other="$LOCAL"; present=$( [ -n "$wh_path" ] && echo 1 || echo 0 ) ;;
    esac
    [ "$present" -eq 1 ] || continue

    section_names "$DERIVED" > "$SECA"
    section_names "$other" > "$SECB"

    for name in $(cat "$SECA" "$SECB" | sort -u | tr ' ' '\036'); do
      name=$(printf '%s' "$name" | tr '\036' ' ')
      in_a=$(grep -cxF "$name" "$SECA" || true)
      in_b=$(grep -cxF "$name" "$SECB" || true)
      if [ "$in_a" -gt 0 ] && [ "$in_b" -eq 0 ]; then
        divs="${divs}${dsep}{\"section\": \"$(json_escape "$name")\", \"side\": \"$store\", \"detail\": \"missing from the ${store} copy\"}"
        dsep=", "
      elif [ "$in_a" -eq 0 ] && [ "$in_b" -gt 0 ]; then
        divs="${divs}${dsep}{\"section\": \"$(json_escape "$name")\", \"side\": \"$store\", \"detail\": \"present only in the ${store} copy - an edit made outside the renderer\"}"
        dsep=", "
      else
        a=$(section_body "$DERIVED" "$name" | git hash-object --stdin)
        b=$(section_body "$other" "$name" | git hash-object --stdin)
        if [ "$a" != "$b" ]; then
          divs="${divs}${dsep}{\"section\": \"$(json_escape "$name")\", \"side\": \"$store\", \"detail\": \"content differs from the derived note\"}"
          dsep=", "
        fi
      fi
    done
  done

  # --- write the projection -------------------------------------------------
  changed=false
  written=false
  reason=""

  if [ "$github_state" = published ]; then
    # The one refusal that is never overridden here: a published release is
    # visible to consumers and is a record, not a draft. `release.yml` owns it.
    reason=published_release
  elif [ "$github_state" = draft ] && cmp -s "$DERIVED" "$REMOTE"; then
    reason=up_to_date
  elif [ "$DRY_RUN" -eq 1 ]; then
    changed=true
    reason=dry_run
  elif [ "$github_state" = draft ]; then
    if gh release edit "$tag" --notes-file "$DERIVED" >/dev/null 2>&1; then
      changed=true; written=true; reason=draft_updated
    else
      reason=gh_edit_failed
    fi
  else
    if gh release create "$tag" --draft --title "Unreleased — ${slug}" --notes-file "$DERIVED" >/dev/null 2>&1; then
      changed=true; written=true; reason=draft_created
    else
      reason=gh_create_failed
    fi
  fi

  out="${out}${sep}{\"slug\": \"$(json_escape "$slug")\", \"tag\": \"$(json_escape "$tag")\", \"github_state\": \"${github_state}\", \"workaholic_path\": \"$(json_escape "$wh_path")\", \"changed\": ${changed}, \"written\": ${written}, \"reason\": \"${reason}\", \"divergences\": [${divs}]}"
  sep=", "
done

if [ "$count" -eq 0 ]; then
  printf '{"ok": false, "reason": "no_targets", "authoritative": "derived", "count": 0, "targets": []}\n'
  exit 0
fi

printf '{"ok": true, "authoritative": "derived", "base": "%s", "count": %d, "targets": [%s]}\n' \
  "$(json_escape "$BASE")" "$count" "$out"
