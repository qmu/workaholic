#!/bin/sh -eu
# Validates ticket file format and location after Write/Edit operations
# Exit codes: 0 = success/not a ticket, 2 = validation failed (blocks operation)

# Strict mode (explicit fallback: some environments strip shebang flags).
set -eu

# Print reference to authoritative skill documentation
print_skill_reference() {
  echo "See: plugins/workaholic/skills/create-ticket/SKILL.md" >&2
}

# Read JSON from stdin
input=$(cat)

# Extract file path from tool input
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

# Exit early if no file path
if [ -z "$file_path" ]; then
  exit 0
fi

# Extract filename early so we can detect ticket-shaped files outside tickets/
filename=$(basename "$file_path")

# Reject ticket-shaped files (YYYYMMDDHHmmss-*.md) written under .workaholic/
# but outside .workaholic/tickets/. Catches misplacements like
# .workaholic/RFDs/<ts>-foo.md that would otherwise silently pass.
# feedbacks/ is exempt: feedback records deliberately share the chronological
# <ts>-<slug>.md shape and carry their own write-time floor (validate-feedback.sh).
case "$file_path" in
  *.workaholic/*)
    case "$file_path" in
      *.workaholic/tickets/*) : ;;
      *.workaholic/feedbacks/*) : ;;
      *)
        if printf '%s' "$filename" | grep -qE '^[0-9]{14}-.*\.md$'; then
          echo "Error: Ticket files must be under .workaholic/tickets/ (todo/, icebox/, or archive/<branch>/)" >&2
          echo "Got: $file_path" >&2
          print_skill_reference
          exit 2
        fi
        ;;
    esac
    ;;
esac

# --- Canonical .workaholic/ layout gate -------------------------------------
# Block (exit 2) a file written into an undesignated .workaholic/ subdirectory. The
# allowed top-level set is the single source of truth in
# hooks/workaholic-layout-allowlist.txt (kept in lockstep with rules/workaholic.md).
# Enforcement is unconditional in the plugin code — "plugin installed = gate active",
# with no env-var/marker opt-out. An injectable opt-out fails open exactly when it is
# not set (a fresh clone, another machine, a differently-launched session), which is
# when the gate is needed; the ticket-shape (above) and ticket-location (below) rules
# were always hard blocks, and the layout gate now matches them. If the allowlist file
# is missing, the gate is skipped (we never enforce a list we cannot read — an
# availability safeguard, not an opt-out).
hook_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
allowlist_file="${hook_dir}/workaholic-layout-allowlist.txt"
case "$file_path" in
  *.workaholic/*)
    if [ -f "$allowlist_file" ]; then
      wh_rel="${file_path#*.workaholic/}"
      first_seg="${wh_rel%%/*}"

      layout_ok=true
      layout_reason=""
      case "$wh_rel" in
        */*)
          if ! grep -qxF "$first_seg" "$allowlist_file"; then
            layout_ok=false
            layout_reason="undesignated subdirectory '${first_seg}/'"
          fi
          ;;
        *)
          # A root-level file: README.md / README_ja.md and index.md (the OKF bundle
          # entry point, maintained by okf/refresh-index.sh), plus the release-scan
          # config files scan-branch-safety.sh reads (scan-allow, leak-denylist), are
          # allowed. All are plugin-grounded root files a developer legitimately edits.
          case "$first_seg" in
            README.md|README_ja.md|index.md|scan-allow|leak-denylist) : ;;
            *)
              layout_ok=false
              layout_reason="root-level file (only README.md, index.md, scan-allow, and leak-denylist are allowed at the .workaholic/ root)"
              ;;
          esac
          ;;
      esac

      if [ "$layout_ok" = false ]; then
        allowed_list="$(grep -vE '^[[:space:]]*(#|$)' "$allowlist_file" | paste -sd' ' - || true)"
        {
          echo "Workaholic layout: ${layout_reason}."
          echo "Got: $file_path"
          echo "Allowed .workaholic/ subdirectories: ${allowed_list} (plus README.md, index.md, scan-allow, and leak-denylist at the root)."
          echo "If you meant a ticket, write it under .workaholic/tickets/todo/."
        } >&2
        print_skill_reference
        echo "(the .workaholic/ layout is a closed structure — register a new artifact directory in hooks/workaholic-layout-allowlist.txt and the rules/workaholic.md table before writing to it)" >&2
        exit 2
      fi
    fi
    ;;
esac

# Skip non-ticket paths
case "$file_path" in
  *.workaholic/tickets/*) : ;;
  *) exit 0 ;;
esac

# Extract the path after .workaholic/tickets/
tickets_path="${file_path#*.workaholic/tickets/}"

# Validate location: the tree is TWO-STATE since 2026-08-13 (issue #436) — todo/
# (FLAT: the canonical write target since P2, 2026-08-06, because a ticket's owner
# is its `assignees` field and not its directory) and archive/<branch>/. A ticket's
# STATE is its `status:` frontmatter field, not its path: absent means queued,
# `done | abandoned | icebox` mean archived with that outcome. The retired
# icebox/ and abandoned/ directories are STILL ACCEPTED here, for the same reason
# todo/<user>/ is: the living migration (gather/scripts/migrate-ticket-states.sh)
# converges the tree at the write seams, and a hook that rejected the old shape
# would hard-block an ordinary edit to a ticket a checkout has not migrated yet —
# turning a convergent migration into a gate, which is the class of failure this
# whole change removes. The trailing [^/]+$ anchors reject deeper nesting, and any
# other top-level dir (an invented done/) falls through to the error.
#
# `todo/<user>/<ticket>.md` is STILL ACCEPTED, and deliberately so: the living
# migration (gather/scripts/migrate-todo-owners.sh) converges the tree at the write
# seams, and a hook that rejected the old shape would hard-block an ordinary edit to
# a ticket a checkout has not migrated yet — turning a convergent migration into a
# gate, which is the class of failure this whole change removes. Both forms are
# `is_todo_ticket` below, so every body check fires on both.
if printf '%s' "$tickets_path" | grep -qE '^todo/[^/]+$'; then
  : # Valid (todo/<ticket>.md — canonical)
elif printf '%s' "$tickets_path" | grep -qE '^todo/[^/]+/[^/]+$'; then
  : # Valid (todo/<user>/<ticket>.md — legacy, pending migration)
elif printf '%s' "$tickets_path" | grep -qE '^icebox/[^/]+$'; then
  : # Valid (legacy, pending migration — folds into archive/unbranched/ + status: icebox)
elif printf '%s' "$tickets_path" | grep -qE '^abandoned/[^/]+$'; then
  : # Valid (legacy, pending migration — folds into archive/unbranched/ + status: abandoned)
elif printf '%s' "$tickets_path" | grep -qE '^archive/[^/]+/'; then
  : # Valid (archive/<branch>/, including the synthetic archive/unbranched/)
else
  echo "Error: Ticket must be in todo/ or archive/<branch>/ (the two-state tree)" >&2
  echo "Got: $tickets_path" >&2
  echo "(a ticket's state is its status: frontmatter field — absent means queued;" >&2
  echo " done | abandoned | icebox mean archived with that outcome. Non-canonical" >&2
  echo " subdirs such as done/ are not allowed; the retired icebox/ and abandoned/" >&2
  echo " directories are tolerated only until the living migration converges them.)" >&2
  print_skill_reference
  exit 2
fi

# The queue predicate, defined once. Both the canonical flat form and the legacy
# per-user form are the todo QUEUE, and every gate below is scoped to it — writing
# the two-branch test at each of the four call sites is how one of them ends up
# fixed and the others silently fail open, which is exactly what a `todo/<user>/`
# regex left behind at line 379 would have done.
is_todo_ticket() {
  printf '%s' "$tickets_path" | grep -qE '^todo/[^/]+$|^todo/[^/]+/[^/]+$'
}

# Validate filename format: YYYYMMDDHHmmss-*.md
if ! printf '%s' "$filename" | grep -qE '^[0-9]{14}-.*\.md$'; then
  echo "Error: Ticket filename must match YYYYMMDDHHmmss-*.md pattern" >&2
  echo "Got: $filename" >&2
  print_skill_reference
  exit 2
fi

# Check if file exists (it should after Write/Edit)
if [ ! -f "$file_path" ]; then
  exit 0
fi

# Read file content
content=$(cat "$file_path")

# Check for frontmatter (first line must be the opening ---)
first_line=$(printf '%s\n' "$content" | head -n 1)
case "$first_line" in
  ---) : ;;
  *)
    echo "Error: Ticket must start with YAML frontmatter (---)" >&2
    print_skill_reference
    exit 2
    ;;
esac

# Extract frontmatter (between first two ---)
# Use awk for portability (macOS head doesn't support -n -1)
frontmatter=$(printf '%s\n' "$content" | awk '/^---$/{if(++c==2)exit}c==1')

# Validate required fields. POSIX functions have no `local`; this reads the
# global $frontmatter and echoes the trimmed value of the named field.
validate_field() {
  printf '%s\n' "$frontmatter" | grep "^$1:" | sed "s/^$1:[[:space:]]*//" | sed 's/[[:space:]]*$//'
}

# created_at: ISO 8601 format (YYYY-MM-DDTHH:MM:SS+TZ or YYYY-MM-DDTHH:MM:SS-TZ)
created_at=$(validate_field "created_at")
if [ -z "$created_at" ]; then
  echo "Error: created_at field is required" >&2
  print_skill_reference
  exit 2
fi
if ! printf '%s' "$created_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$'; then
  echo "Error: created_at must be ISO 8601 format (e.g., 2026-01-29T04:19:24+09:00)" >&2
  echo "Got: $created_at" >&2
  print_skill_reference
  exit 2
fi

# author: email format
author=$(validate_field "author")
if [ -z "$author" ]; then
  echo "Error: author field is required" >&2
  print_skill_reference
  exit 2
fi
if ! printf '%s' "$author" | grep -qE '^[^@]+@[^@]+\.[^@]+$'; then
  echo "Error: author must be an email address" >&2
  echo "Got: $author" >&2
  print_skill_reference
  exit 2
fi
# Reject anthropic.com emails - Claude must use actual user's git email.
# Scoped to a NEW ticket (untracked at this path): the field records who created the
# artifact, so on creation it must be the runner's real identity - but an EDIT of a
# tracked ticket (a drive run appending its Final Report to a routine-authored one)
# must not be told to rewrite provenance to satisfy the check (measured 2026-08-07:
# five Final Report appends flagged on a mission whose tickets the cloud routine
# authored as noreply@anthropic.com). Tracked-ness is answered by git; when git
# cannot answer, the strict creation-time behavior is kept.
ticket_is_tracked=false
ticket_dir=$(dirname -- "$file_path")
if git -C "$ticket_dir" ls-files --error-unmatch -- "$filename" >/dev/null 2>&1; then
  ticket_is_tracked=true
fi
if [ "$ticket_is_tracked" = "false" ]; then
  case "$author" in
    *@anthropic.com)
      echo "Error: author must be your actual email from 'git config user.email'" >&2
      echo "Rejected: $author (run 'git config user.email' and use that value)" >&2
      print_skill_reference
      exit 2
      ;;
  esac
fi

# type / layer / effort / commit_hash / category: RETIRED (2026-08-07) and therefore
# tolerated, never validated. New tickets do not carry them; the whole existing corpus
# (todo and archive alike) does, and a hook that rejected — or demanded — a retired
# field would retro-block history on its next ordinary edit. So there is no rule here
# at all: present values of any shape pass, exactly like `claim:` below.

# merge_policy: optional, one of auto | review.
#
# ABSENT MEANS `review` — the conservative default, and the reason this is validated
# only WHEN PRESENT. Every ticket predating the field (the whole archive, plus any
# queue written by an older plugin copy) carries no value, and the one reading that
# must never produce is "merge this without a human looking". So an empty/missing
# field is legal and reads as review at drive time; only a present value is held to
# the enum, because a typo'd `merge_policy: atuo` would otherwise read as review
# while its author believed they had asked for automatic merging.
merge_policy=$(validate_field "merge_policy")
if [ -n "$merge_policy" ]; then
  case "$merge_policy" in
    auto|review) : ;;
    *)
      echo "Error: merge_policy must be one of: auto, review (or empty, which reads as review)" >&2
      echo "Got: $merge_policy" >&2
      print_skill_reference
      exit 2
      ;;
  esac
fi

# claim: optional, and DELIBERATELY UNVALIDATED.
#
# The claim protocol (docs/loop-engineering-workflow.md G3; workaholic:drive's *Claims*)
# stamps `claim: <branch>` into a claimed ticket's frontmatter on the claim branch, so a
# queue ticket legitimately carries this key while its unit is in flight. Nothing here
# checks it, on purpose: the key is BRANCH-LOCAL BY CONVENTION and its truth lives in git,
# not in the file. Whether a stamp is real is answered by drive/scripts/list-claims.sh --
# does an unmerged remote branch of that name still carry this artifact? -- and a hook
# reading one file cannot answer that. A regex here would only assert the shape of a value
# whose meaning it cannot see, and would reject a stamp written by a newer plugin copy.
# So: tolerated, never validated. Do not add a rule.

# depends_on: optional, YAML list of ticket filenames
depends_on_line=$(printf '%s\n' "$frontmatter" | grep "^depends_on:" || true)
if [ -n "$depends_on_line" ]; then
  depends_on_values=$(printf '%s\n' "$depends_on_line" | sed 's/^depends_on:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  # Each non-empty entry must match the ticket filename pattern.
  invalid_dep=$(printf '%s\n' "$depends_on_values" | grep -v '^$' | grep -vE '^[0-9]{14}-.*\.md$' | head -n 1 || true)
  if [ -n "$invalid_dep" ]; then
    echo "Error: depends_on entries must match YYYYMMDDHHmmss-*.md pattern" >&2
    echo "Got: $invalid_dep" >&2
    print_skill_reference
    exit 2
  fi
fi

# --- Mandatory body sections (the todo queue only) ---------------------------
# create-ticket/SKILL.md makes two body sections mandatory and never-empty:
# `## Policies` (l.310, the recorded policy list /drive opens before writing
# code) and `## Quality Gate` (§4b, whose interrogation "always runs -- it is not
# skippable"). Nothing checked either, and the gap was not theoretical: a ticket
# written this week reached the queue carrying neither and passed every gate.
#
# This BLOCKS (exit 2) rather than warns. A warning is what the prose already is, and
# the reason the check exists is that /drive is about to stop asking a human per
# ticket: unattended, the Quality Gate stops being what a developer approves against
# and becomes the only bar the agent holds itself to. An omitted gate would then mean
# a ticket that drives itself unjudged, silently.
#
# SCOPED TO THE TODO QUEUE DELIBERATELY -- it is the finished location, where a ticket
# must be complete before /drive reads it:
#   - archive/<branch>/ is history and is never retro-blocked;
#   - icebox/ and abandoned/ are parking, not a queue, so a ticket already there is
#     not re-judged (it must pass again on its way back into todo/ via promote);
#   - the mid-authoring path stays clear because create-ticket writes a complete
#     ticket in a single Write (SKILL.md l.460), so the sections exist when this fires.
#
# Do NOT grow this toward judging whether a gate is GOOD. "Present and non-empty" is
# syntax, which a hook does well; quality is semantic and belongs to the §4b
# interrogation and the developer. This hook is PostToolUse, so it speaks after the
# file exists: it is a review that rejects loudly, not a guard that prevents.
#
# A heading with nothing under it is the same defect as no heading, so both are
# rejected. "Non-empty" means at least one non-blank line before the next `## `.
has_section_body() {
  printf '%s\n' "$content" | awk -v want="## $1" '
    { line = $0; sub(/[[:space:]]+$/, "", line) }
    line == want { inside = 1; next }
    inside && /^##[[:space:]]/ { exit }
    inside && NF { found = 1; exit }
    END { exit(found ? 0 : 1) }
  '
}

if is_todo_ticket; then
  if ! has_section_body "Policies"; then
    echo "Error: ## Policies section is required and must not be empty" >&2
    echo "Got: $tickets_path" >&2
    echo "(list the policy hard copies this ticket answers to -- /drive reads this section before writing code)" >&2
    print_skill_reference
    exit 2
  fi
  if ! has_section_body "Quality Gate"; then
    echo "Error: ## Quality Gate section is required and must not be empty" >&2
    echo "Got: $tickets_path" >&2
    echo "(record the Step 4b interrogation: acceptance criteria, verification method, and the gate that must pass)" >&2
    print_skill_reference
    exit 2
  fi

  # --- mission: relation must resolve (the todo queue only) -----------------
  # A typo'd slug silently detaches a ticket from its mission's gates -- worse,
  # a wrong-but-resolving slug borrows ANOTHER mission's drive authorization.
  # Read through the mission skill's single reader (never re-parse the shape)
  # and resolve each slug through the mission resolver. Scoped to the todo
  # queue: archive/ is history and is never retro-blocked, and the resolver
  # accepts a mission in either area (an archived mission still resolves --
  # what is rejected is a slug that resolves NOWHERE).
  read_relation="${hook_dir}/../skills/mission/scripts/read-relation.sh"
  resolve_lib="${hook_dir}/../skills/mission/scripts/lib/resolve.sh"
  if [ -f "$read_relation" ] && [ -f "$resolve_lib" ]; then
    mission_slugs=$(sh "$read_relation" "$file_path" 2>/dev/null || true)
    if [ -n "$mission_slugs" ]; then
      # Resolve each slug against the TICKET'S OWN mission tree, derived from the
      # ticket's own path -- never the hook's cwd. The mission layout keeps a
      # mission's mission.md inside its own .worktrees/<slug>/ checkout until that
      # branch merges, so a missioned ticket written into a mission worktree from a
      # main-tree session must resolve against THAT worktree's .workaholic, not the
      # main tree's. missions_root_from_artifact derives that root from file_path
      # (the ${path%%.workaholic/*}.workaholic segment) and mission_resolve returns
      # an absolute path under it -- the root-based API, so there is no cwd
      # dependency and no cd subshell.
      . "$resolve_lib"
      mission_root=$(missions_root_from_artifact "$file_path")
      for mission_slug in $mission_slugs; do
        mission_file=$(mission_resolve "$mission_root" "$mission_slug")
        if [ ! -f "$mission_file" ]; then
          echo "Error: mission relation does not resolve: '$mission_slug'" >&2
          echo "(no .workaholic/missions/{active,archive}/${mission_slug}/mission.md exists in the ticket's own checkout -- a typo here detaches the ticket from its mission's gates, or borrows another mission's drive authorization)" >&2
          print_skill_reference
          exit 2
        fi
      done
    fi
  fi

  # --- resumption tickets list REMAINING work only (the todo queue only) -----
  # A resumption ticket's ## Implementation Steps drive verbatim: /drive has no
  # notion of "already done", so a completed step left in the list is re-run --
  # and the unified run has no human gate left to catch it. The dedicated
  # hand-off command that once wrote these is retired (in-flight state lives on
  # the claim branch now), but a hand-written resume-* ticket is still possible,
  # so the floor stays: no checked checkboxes and no struck-through steps inside
  # Implementation Steps. Completed work belongs in ## Overview, do-not-redo.
  case "$filename" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-resume-*.md)
      done_step=$(printf '%s\n' "$content" | awk '
        /^## / { in_s = ($0 ~ /^##[ \t]+Implementation Steps[ \t]*$/); next }
        in_s && (/^[ \t]*-[ \t]+\[(x|X)\]/ || /~~/) { print; exit }
      ')
      if [ -n "$done_step" ]; then
        echo "Error: a resumption ticket's ## Implementation Steps must list REMAINING work only" >&2
        echo "Got: $done_step" >&2
        echo "(a checked/struck-through step would be re-run by /drive -- record completed work in ## Overview as do-not-redo context instead)" >&2
        print_skill_reference
        exit 2
      fi
      ;;
  esac
fi

# All validations passed
exit 0
