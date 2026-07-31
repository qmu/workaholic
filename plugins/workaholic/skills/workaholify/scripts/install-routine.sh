#!/bin/sh -eu
# Install ONE declared routine into the invoking user's crontab. Idempotent.
#
#   install-routine.sh <routine-name> [repo-root]
#
# Output (one JSON line):
#   {"installed": true, "routine": "<name>", "line": "<crontab line>", "changed": true|false}
#   {"installed": false, "reason": "not_interactive"|"no_declaration"|"incomplete_declaration"
#                                 |"crontab_write_failed", ...}
#
# ============================ THE REFUSAL IS THE POINT ============================
#
# Both loop runbooks say, verbatim: "do not install the crontab from an agent session —
# applying a standing schedule is a durable outward action". That rule is NOT weakened
# here. It is aimed at the UNATTENDED case, and this script enforces exactly that
# boundary by refusing whenever stdin is not a terminal:
#
#   - a developer who typed /workaholify is present, and installing the routine they just
#     asked for is the same class of act as anything else they typed;
#   - a cron tick, a /drive run, a CI job, or any headless session has nobody to ask, and
#     a standing schedule installed by one is a commitment nobody made.
#
# THE CHECK LIVES IN THE SCRIPT, NOT ONLY IN PROSE, and that placement is deliberate.
# Someone will eventually want /drive to self-heal its own routine; a prohibition written
# only in a SKILL.md is text an agent can talk itself past, while this refusal has to be
# deleted — with its test — by somebody who then owns the decision.
#
# WHAT THE CALLER STILL OWES. This script does not confirm anything: it renders and
# applies. Showing the developer the exact line and getting an explicit yes is the
# COMMAND's job (main-agent level, like /request's body confirmation), because a standing
# schedule is an outward durable commitment no matcher can judge on the developer's
# behalf. `--dry-run` renders without applying so the caller can show the real line.
#
# IDEMPOTENCE: an already-correct entry is left byte-identical and reported
# `changed: false`. A drifted entry for the same repo+command is REPLACED, not appended —
# two entries for one routine would fire it twice.

set -eu

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then DRY_RUN=true; shift; fi

NAME="${1:-}"
ROOT="${2:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

[ -n "$NAME" ] || { echo '{"installed": false, "reason": "no_routine_name"}'; exit 1; }

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

DECL="${ROOT}/.workaholic/routines/${NAME}.md"
if [ ! -f "$DECL" ]; then
  printf '{"installed": false, "reason": "no_declaration", "routine": "%s", "expected": "%s"}\n' \
    "$(json_escape "$NAME")" "$(json_escape "$DECL")"
  exit 1
fi

fm_field() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm {
      idx = index($0, ":")
      if (idx > 0 && substr($0, 1, idx - 1) == key) {
        v = substr($0, idx + 1)
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        # Strip one layer of surrounding quotes: a cron schedule must be quoted in YAML
        # (it starts with *), and an unstripped quote would be compared against a crontab
        # line that has none, so every routine would read as schedule_drift forever.
        if (v ~ /^".*"$/ || v ~ /^'"'"'.*'"'"'$/) { v = substr(v, 2, length(v) - 2) }
        print v; exit
      }
    }
  ' "$1"
}

schedule=$(fm_field "$DECL" schedule)
command=$(fm_field "$DECL" command)
env_file=$(fm_field "$DECL" env_file)
log_file=$(fm_field "$DECL" log_file)

if [ -z "$schedule" ] || [ -z "$command" ]; then
  printf '{"installed": false, "reason": "incomplete_declaration", "routine": "%s", "detail": "schedule and command are both required"}\n' \
    "$(json_escape "$NAME")"
  exit 1
fi

# Render the line. The env file is SOURCED by the line rather than expanded into it —
# a secret belongs in a file with its own permissions, never in a crontab every process
# on the box can read (`crontab -l` is not privileged).
line="$schedule cd $ROOT && "
if [ -n "$env_file" ]; then
  case "$env_file" in
    /*) line="${line}. ${env_file} && " ;;
    *)  line="${line}. \$HOME/${env_file} && " ;;
  esac
fi
line="${line}${command}"
if [ -n "$log_file" ]; then
  line="${line} >> ${log_file} 2>&1"
fi

if [ "$DRY_RUN" = "true" ]; then
  printf '{"installed": false, "reason": "dry_run", "routine": "%s", "line": "%s"}\n' \
    "$(json_escape "$NAME")" "$(json_escape "$line")"
  exit 0
fi

# ---- The refusal ----
if [ ! -t 0 ]; then
  printf '{"installed": false, "reason": "not_interactive", "routine": "%s", "line": "%s", "detail": "a standing schedule is a durable outward action; install it from an interactive /workaholify, never from an unattended run"}\n' \
    "$(json_escape "$NAME")" "$(json_escape "$line")"
  exit 1
fi

existing=$(crontab -l 2>/dev/null || true)

if printf '%s\n' "$existing" | grep -Fxq "$line"; then
  printf '{"installed": true, "routine": "%s", "line": "%s", "changed": false}\n' \
    "$(json_escape "$NAME")" "$(json_escape "$line")"
  exit 0
fi

# Drop any prior entry for this repo+command before appending, so a drifted schedule is
# replaced rather than duplicated.
kept=$(printf '%s\n' "$existing" | grep -Fv "$ROOT" 2>/dev/null || true)
dropped=$(printf '%s\n' "$existing" | grep -F "$ROOT" 2>/dev/null | grep -Fv "$command" 2>/dev/null || true)

new_cron=""
[ -z "$kept" ] || new_cron="$kept"
if [ -n "$dropped" ]; then
  [ -z "$new_cron" ] && new_cron="$dropped" || new_cron="${new_cron}
${dropped}"
fi
[ -z "$new_cron" ] && new_cron="$line" || new_cron="${new_cron}
${line}"

if printf '%s\n' "$new_cron" | crontab - 2>/dev/null; then
  printf '{"installed": true, "routine": "%s", "line": "%s", "changed": true}\n' \
    "$(json_escape "$NAME")" "$(json_escape "$line")"
else
  printf '{"installed": false, "reason": "crontab_write_failed", "routine": "%s", "line": "%s"}\n' \
    "$(json_escape "$NAME")" "$(json_escape "$line")"
  exit 1
fi
