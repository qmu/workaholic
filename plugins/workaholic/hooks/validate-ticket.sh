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
case "$file_path" in
  *.workaholic/*)
    case "$file_path" in
      *.workaholic/tickets/*) : ;;
      *)
        if printf '%s' "$filename" | grep -qE '^[0-9]{14}-.*\.md$'; then
          echo "Error: Ticket files must be under .workaholic/tickets/ (todo/<user>/, icebox/, or archive/<branch>/)" >&2
          echo "Got: $file_path" >&2
          print_skill_reference
          exit 2
        fi
        ;;
    esac
    ;;
esac

# --- Canonical .workaholic/ layout gate -------------------------------------
# Reject (strict) or warn about a file written into an undesignated .workaholic/
# subdirectory. The allowed top-level set is the single source of truth in
# hooks/workaholic-layout-allowlist.txt (kept in lockstep with rules/workaholic.md).
# Default is non-blocking (warn -> exit 0); strict blocking (exit 2) is opt-in per
# repo via the WORKAHOLIC_STRICT_LAYOUT env var or a committed
# .workaholic/.strict-layout marker. The ticket-shape (above) and ticket-location
# (below) rules stay hard-blocking regardless of this toggle. If the allowlist
# file is missing, the gate is skipped (we never enforce a list we cannot read).
hook_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
allowlist_file="${hook_dir}/workaholic-layout-allowlist.txt"
case "$file_path" in
  *.workaholic/*)
    if [ -f "$allowlist_file" ]; then
      wh_root="${file_path%%.workaholic/*}.workaholic"
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
          # A root-level file: only README.md / README_ja.md and index.md (the OKF
          # bundle entry point, maintained by okf/refresh-index.sh) are allowed.
          case "$first_seg" in
            README.md|README_ja.md|index.md) : ;;
            *)
              layout_ok=false
              layout_reason="root-level file (only README.md and index.md are allowed at the .workaholic/ root)"
              ;;
          esac
          ;;
      esac

      if [ "$layout_ok" = false ]; then
        strict=false
        if [ -n "${WORKAHOLIC_STRICT_LAYOUT:-}" ] || [ -f "${wh_root}/.strict-layout" ]; then
          strict=true
        fi
        allowed_list="$(grep -vE '^[[:space:]]*(#|$)' "$allowlist_file" | paste -sd' ' - || true)"
        {
          echo "Workaholic layout: ${layout_reason}."
          echo "Got: $file_path"
          echo "Allowed .workaholic/ subdirectories: ${allowed_list} (plus README.md and index.md at the root)."
          echo "If you meant a ticket, write it under .workaholic/tickets/todo/<user>/."
        } >&2
        print_skill_reference
        if [ "$strict" = true ]; then
          echo "(strict layout enforcement is ON — blocking this write)" >&2
          exit 2
        fi
        echo "(layout enforcement is in warn mode — allowing; set WORKAHOLIC_STRICT_LAYOUT=1 or add .workaholic/.strict-layout to block)" >&2
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

# Validate location: must be in todo/<user>/ (the per-user subdir is MANDATORY —
# the flat todo/ root is never a write target; strays are swept into
# todo/<user>/ by create-ticket/drive), icebox/ (flat), abandoned/ (flat, where
# drive parks failed tickets), or archive/<branch>/. The trailing [^/]+$ anchors
# reject deeper nesting (e.g. todo/<user>/archive/...), and any other top-level
# dir (an invented done/, root-level todo/ stray) falls through to the error.
if printf '%s' "$tickets_path" | grep -qE '^todo/[^/]+/[^/]+$'; then
  : # Valid (todo/<user>/<ticket>.md)
elif printf '%s' "$tickets_path" | grep -qE '^icebox/[^/]+$'; then
  : # Valid (icebox stays flat)
elif printf '%s' "$tickets_path" | grep -qE '^abandoned/[^/]+$'; then
  : # Valid (abandoned stays flat)
elif printf '%s' "$tickets_path" | grep -qE '^archive/[^/]+/'; then
  : # Valid (archive/<branch>/)
else
  echo "Error: Ticket must be in todo/<user>/, icebox/, abandoned/, or archive/<branch>/" >&2
  echo "Got: $tickets_path" >&2
  echo "(non-canonical subdirs such as done/ and root-level todo/ strays are not allowed)" >&2
  print_skill_reference
  exit 2
fi

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
# Reject anthropic.com emails - Claude must use actual user's git email
case "$author" in
  *@anthropic.com)
    echo "Error: author must be your actual email from 'git config user.email'" >&2
    echo "Rejected: $author (run 'git config user.email' and use that value)" >&2
    print_skill_reference
    exit 2
    ;;
esac

# type: one of enhancement, bugfix, refactoring, housekeeping
type=$(validate_field "type")
if [ -z "$type" ]; then
  echo "Error: type field is required" >&2
  print_skill_reference
  exit 2
fi
case "$type" in
  enhancement|bugfix|refactoring|housekeeping) : ;;
  *)
    echo "Error: type must be one of: enhancement, bugfix, refactoring, housekeeping" >&2
    echo "Got: $type" >&2
    print_skill_reference
    exit 2
    ;;
esac

# layer: YAML array with valid values
layer_line=$(printf '%s\n' "$frontmatter" | grep "^layer:" || true)
if [ -z "$layer_line" ]; then
  echo "Error: layer field is required" >&2
  print_skill_reference
  exit 2
fi
# Extract array values (handles [UX, Domain] format)
layer_values=$(printf '%s\n' "$layer_line" | sed 's/^layer:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
if [ -z "$layer_values" ]; then
  echo "Error: layer must contain at least one value" >&2
  print_skill_reference
  exit 2
fi
# Find the first non-empty value that is not an allowed layer (no subshell exit:
# grep surfaces the offender, the test runs in the current shell).
invalid_layer=$(printf '%s\n' "$layer_values" | grep -v '^$' | grep -vE '^(UX|Domain|Infrastructure|DB|Config)$' | head -n 1 || true)
if [ -n "$invalid_layer" ]; then
  echo "Error: layer values must be one of: UX, Domain, Infrastructure, DB, Config" >&2
  echo "Got: $invalid_layer" >&2
  print_skill_reference
  exit 2
fi

# effort: empty or valid format (0.1h, 0.25h, 0.5h, 1h, 2h, 4h)
effort=$(validate_field "effort")
if [ -n "$effort" ]; then
  case "$effort" in
    0.1h|0.25h|0.5h|1h|2h|4h) : ;;
    *)
      echo "Error: effort must be one of: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h (or empty)" >&2
      echo "Got: $effort" >&2
      print_skill_reference
      exit 2
      ;;
  esac
fi

# commit_hash: empty or short git hash format (7-40 hex chars)
commit_hash=$(validate_field "commit_hash")
if [ -n "$commit_hash" ]; then
  if ! printf '%s' "$commit_hash" | grep -qE '^[0-9a-f]{7,40}$'; then
    echo "Error: commit_hash must be a valid short git hash (7-40 hex characters)" >&2
    echo "Got: $commit_hash" >&2
    print_skill_reference
    exit 2
  fi
fi

# category: empty or one of Added, Changed, Removed
category=$(validate_field "category")
if [ -n "$category" ]; then
  case "$category" in
    Added|Changed|Removed) : ;;
    *)
      echo "Error: category must be one of: Added, Changed, Removed (or empty)" >&2
      echo "Got: $category" >&2
      print_skill_reference
      exit 2
      ;;
  esac
fi

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

# --- Mandatory body sections (todo/<user>/ only) -----------------------------
# create-ticket/SKILL.md makes two body sections mandatory and never-empty:
# `## Policies` (l.310, the recorded policy list /drive and /trip open before writing
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
# SCOPED TO todo/<user>/ DELIBERATELY -- it is the finished location, where a ticket
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

if printf '%s' "$tickets_path" | grep -qE '^todo/[^/]+/[^/]+$'; then
  if ! has_section_body "Policies"; then
    echo "Error: ## Policies section is required and must not be empty" >&2
    echo "Got: $tickets_path" >&2
    echo "(list the policy hard copies this ticket answers to -- /drive and /trip read this section before writing code)" >&2
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

  # --- mission: relation must resolve (todo/<user>/ only) --------------------
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
      . "$resolve_lib"
      for mission_slug in $mission_slugs; do
        mission_file=$(mission_resolve "$mission_slug")
        if [ ! -f "$mission_file" ]; then
          echo "Error: mission relation does not resolve: '$mission_slug'" >&2
          echo "Got: $tickets_path" >&2
          echo "(no .workaholic/missions/{active,archive}/${mission_slug}/mission.md exists -- a typo here detaches the ticket from its mission's gates, or borrows another mission's drive authorization)" >&2
          print_skill_reference
          exit 2
        fi
      done
    fi
  fi

  # --- resumption tickets list REMAINING work only (todo/<user>/ only) -------
  # A /carry resumption ticket's ## Implementation Steps drive verbatim: /drive
  # has no notion of "already done", so a completed step left in the list is
  # re-run -- and on a mission-authorized queue no human gate remains to catch
  # it. The prose rule (carry/SKILL.md: "only remaining work -- never re-list
  # completed steps") gets the machine-checkable floor here: no checked
  # checkboxes and no struck-through steps inside Implementation Steps.
  # Completed work belongs in ## Overview, marked do-not-redo.
  case "$filename" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-resume-*.md)
      done_step=$(printf '%s\n' "$content" | awk '
        /^## / { in_s = ($0 ~ /^##[ \t]+Implementation Steps[ \t]*$/); next }
        in_s && (/^[ \t]*-[ \t]+\[(x|X)\]/ || /~~/) { print; exit }
      ')
      if [ -n "$done_step" ]; then
        echo "Error: a resumption ticket's ## Implementation Steps must list REMAINING work only" >&2
        echo "Got: $done_step" >&2
        echo "(a checked/struck-through step would be re-run by /drive -- record completed work in ## Overview as do-not-redo context instead; see carry/SKILL.md)" >&2
        print_skill_reference
        exit 2
      fi
      ;;
  esac
fi

# All validations passed
exit 0
