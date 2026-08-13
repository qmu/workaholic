#!/bin/sh -eu
# Draft (or refresh) the `## Deployment Plan` section of a Release Note.
#
#   draft-deploy-plan.sh <note-path> [base]     # base defaults to main
#
# Output: JSON
#   {"ok": true, "path": "...", "targets": N, "changed": <bool>,
#    "base_rev": "origin/main", "base_sha": "abcd1234"}
#   {"ok": false, "reason": "...", "written": false}
#   reason: usage | no_note | base_unresolvable | not_a_git_repo | write_failed
#
# THE PLAN IS PROSPECTIVE AND THE NOTE IS RETROSPECTIVE, in one document. The
# note's Summary/Changes describe what a branch DID; this section describes what
# is waiting to deploy and how it would be verified. The section's own opening
# line says which it is, because a reader who cannot tell "this shipped" from
# "this is proposed to ship" is worse off than one with no plan at all.
#
# EVERY FIELD IS TRACEABLE. The section carries nothing this script invented:
# each line is a value `read-deploy-state.sh --rows` returned, and the procedure
# and the verification are REFERENCED by their record path and section rather
# than pasted, so the plan cannot drift from the contract `/ship` actually runs.
# The commit list is deliberately not pasted either: `unreleased_count` plus the
# range boundary is what a reader checks against `git log`.
#
# IDEMPOTENCE IS THE CONTRACT, NOT A NICETY (a periodic caller runs this). The
# section carries NO clock: its datum is the base's commit sha, so re-running
# against an unchanged base rewrites byte-identical bytes and `changed` is
# false. Anything time-stamped here would make an hourly agent a commit machine.
#
# A DEGRADED READ WRITES NOTHING. `read-deploy-state.sh --rows` exits 3 with the
# reason on stderr when the base cannot be resolved; this script reports that
# reason and leaves the note untouched. A half-written plan is worse than none.
#
# Zero targets is NOT degradation: the section is written and says plainly that
# the repository declares no deployment targets. Silence there would read as
# "nothing to deploy" when the truth is "nothing was ever declared".

set -eu

NOTE="${1:-}"
BASE="${2:-main}"
[ -n "$NOTE" ] || { echo '{"ok": false, "reason": "usage", "written": false}' >&2; exit 1; }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

fail() {
  printf '{"ok": false, "reason": "%s", "written": false}\n' "$1"
  exit 0
}

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo '{"ok": false, "reason": "not_a_git_repo", "written": false}' >&2
  exit 1
fi

case "$NOTE" in
  /*) NOTE_PATH="$NOTE" ;;
  *) NOTE_PATH="${ROOT}/${NOTE}" ;;
esac
REL=${NOTE_PATH#"${ROOT}/"}

[ -f "$NOTE_PATH" ] || fail no_note

# --- read the consolidation --------------------------------------------------
STATE="${TMPDIR:-/tmp}/wh-deploy-rows.$$"
ERRS="${TMPDIR:-/tmp}/wh-deploy-err.$$"
trap 'rm -f "$STATE" "$ERRS" "${STATE}.plan" "${STATE}.new"' EXIT INT TERM

if ! sh "${SCRIPT_DIR}/read-deploy-state.sh" --rows --exclude-note "$NOTE_PATH" "$BASE" >"$STATE" 2>"$ERRS"; then
  reason=$(head -n 1 "$ERRS" | tr -d '\n')
  [ -n "$reason" ] || reason=base_unresolvable
  fail "$reason"
fi

BASE_LINE=$(sh "${SCRIPT_DIR}/read-deploy-state.sh" --base-rev "$BASE")
US=$(printf '\037')
BASE_REV=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f1)
BASE_SHA=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f2)

# --- render the section ------------------------------------------------------
PLAN="${STATE}.plan"
COUNT=0
SLUGS=""

{
  printf '## Deployment Plan\n\n'
  printf -- '**Draft — prospective. Nothing in this section has been deployed.** Measured\n'
  printf -- 'against `%s` at `%s`; the rest of this note is the retrospective record of\n' "$BASE_REV" "$BASE_SHA"
  printf -- 'what the branch changed.\n'
} > "$PLAN"

# IFS is \037, never tab: tab is IFS whitespace, so adjacent empty fields (an
# unresolvable `since`, an absent `command`) would collapse and shift the parse.
while IFS="$US" read -r slug title environment model model_reason \
  conf_method conf_command has_conf attribution since since_reason n note_path note_match; do
  [ -n "$slug" ] || continue
  COUNT=$((COUNT + 1))
  SLUGS="${SLUGS}${SLUGS:+, }${slug}"

  since_display="$since"
  [ -n "$since_display" ] || since_display="(no boundary)"
  [ "$since_display" = "(no boundary)" ] || since_display=$(printf '%s' "$since_display" | cut -c1-8)

  {
    printf '\n### %s (`%s`)\n\n' "${title:-$slug}" "$slug"
    printf -- '- **Environment:** %s\n' "${environment:-unstated}"
    printf -- '- **Deploy model:** %s (`%s`)\n' "${model:-unresolved}" "${model_reason:-unresolved}"
    printf -- '- **Waiting to deploy:** %s commit(s) since `%s` — `since_reason: %s`, attribution `%s`\n' \
      "$n" "$since_display" "$since_reason" "$attribution"
    printf -- '- **Procedure:** `.workaholic/deployments/%s.md` § Procedure\n' "$slug"
    if [ "$has_conf" = true ]; then
      if [ -n "$conf_command" ]; then
        printf -- '- **Verification required:** `%s` — `%s` (`.workaholic/deployments/%s.md` § Confirmation)\n' \
          "$conf_method" "$conf_command" "$slug"
      else
        printf -- '- **Verification required:** `%s` (`.workaholic/deployments/%s.md` § Confirmation)\n' \
          "$conf_method" "$slug"
      fi
    else
      printf -- '- **Verification required:** none declared — `/ship` halts on this target (§1-4).\n'
    fi
    if [ -n "$note_path" ]; then
      printf -- '- **Latest note for this target:** `%s` (matched by %s)\n' "$note_path" "$note_match"
    else
      printf -- '- **Latest note for this target:** none yet\n'
    fi
    if [ "$model" = "deploy-on-merge" ]; then
      printf -- '- **Note:** the merge is this target'"'"'s deployment; what is pending here is the\n'
      printf -- '  release publish for the version above, not the commits themselves.\n'
    fi
  } >> "$PLAN"
done < "$STATE"

if [ "$COUNT" -eq 0 ]; then
  printf '\nNo deployment targets are declared in `.workaholic/deployments/`, so there is\nnothing to plan. This is a declaration gap, not an empty release.\n' >> "$PLAN"
fi

# --- splice it into the note -------------------------------------------------
NEW="${STATE}.new"

# 1. Drop any existing section (heading through the next `## `), 2. squeeze the
# trailing blank lines the drop may leave, 3. re-insert before `## Links` when
# the note has one, else at the end. The two shapes are what make a re-run
# byte-identical.
awk '
  /^## Deployment Plan$/ { drop = 1; next }
  /^## / && drop { drop = 0 }
  !drop { print }
' "$NOTE_PATH" \
  | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] == "") last--; for (i = 1; i <= last; i++) print lines[i] }' \
  > "$NEW"

if grep -q '^## Links$' "$NEW"; then
  awk -v planfile="$PLAN" '
    /^## Links$/ && !done {
      while ((getline line < planfile) > 0) print line
      print ""
      done = 1
    }
    { print }
  ' "$NEW" > "${NEW}.spliced"
  mv "${NEW}.spliced" "$NEW"
else
  printf '\n' >> "$NEW"
  cat "$PLAN" >> "$NEW"
fi

# --- stamp `targets:` so the note/target join stops depending on recency ------
if [ "$COUNT" -gt 0 ]; then
  awk -v val="targets: [${SLUGS}]" '
    /^---$/ { c++ }
    c == 1 && /^targets:/ { if (!seen) { print val; seen = 1 } next }
    c == 2 && !stamped { if (!seen) print val; stamped = 1 }
    { print }
  ' "$NEW" > "${NEW}.fm"
  mv "${NEW}.fm" "$NEW"
fi

CHANGED=true
if cmp -s "$NEW" "$NOTE_PATH"; then
  CHANGED=false
else
  cp "$NEW" "$NOTE_PATH" || fail write_failed
fi

printf '{"ok": true, "path": "%s", "targets": %d, "changed": %s, "base_rev": "%s", "base_sha": "%s"}\n' \
  "$REL" "$COUNT" "$CHANGED" "$BASE_REV" "$BASE_SHA"
