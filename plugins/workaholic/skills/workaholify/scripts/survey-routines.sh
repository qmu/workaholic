#!/bin/sh -eu
# Report, for every routine this repository DECLARES, whether it is installed for the
# invoking user on this machine. Pure read — safe from any context, interactive or not.
#
#   survey-routines.sh [repo-root]
#
# Output (one JSON line):
#   {"repo": "<abs>", "user": "<name>", "crontab": true|false, "count": N, "drift": N,
#    "routines": [{"name","schedule","command","env_file","declared","installed",
#                  "matches","drift_reason"}]}
#
# THE SPLIT THIS IMPLEMENTS. The repository declares WHICH routines it wants
# (`.workaholic/routines/*.md`, committed and reviewable in a PR); the developer's
# machine holds WHETHER they are installed (the crontab, read back here). A committed
# declaration cannot carry a machine's paths or secrets, and a crontab cannot be reviewed
# in a pull request — so neither one alone can answer "what runs against this repo".
#
# EVERY "NOT SET UP" IS NAMED, never collapsed. `drift_reason` distinguishes:
#   incomplete_declaration — the committed declaration lacks a schedule or a command,
#                    so the problem is in the repository, not on this machine
#   not_installed  — no crontab entry mentions this repo and this routine
#   schedule_drift — an entry exists but its schedule differs from the declaration
#   missing_env    — the entry exists and matches, but the env file it sources is absent
# A developer told only "not set up" has to re-derive which of the three it is, and the
# third one is invisible to `crontab -l` alone: the routine is scheduled, it fires, and
# it fails silently every tick.
#
# IT READS ONLY THE INVOKING USER'S CRONTAB, and says so. A routine installed under a
# different account is invisible here — which is why `installed` means "installed for
# this user", and the report carries `user` so the distinction is legible rather than a
# footnote somebody has to know.
#
# NO WRITE PATH EXISTS IN THIS SCRIPT. Provisioning is `install-routine.sh`, which
# refuses a non-interactive context; keeping the read and the write in separate files is
# what lets this one be called from anywhere, including the nudge hook.

set -eu

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

ROUTINE_DIR="${ROOT}/.workaholic/routines"
user=$(id -un 2>/dev/null || echo "unknown")

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

fm_field() {
  # First frontmatter value for a key, trimmed. Frontmatter only: stop at the closing ---.
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

# One read of the crontab for the whole survey. A missing crontab is a normal state on a
# fresh machine, not an error — `crontab: false` says so and every routine reports
# not_installed rather than the run failing.
crontab_present=false
CRON=""
if CRON=$(crontab -l 2>/dev/null); then
  crontab_present=true
else
  CRON=""
fi

entries=""
sep=""
count=0
drift=0

if [ -d "$ROUTINE_DIR" ]; then
  for f in "$ROUTINE_DIR"/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f" .md)
    [ "$base" != "index" ] || continue

    name=$(fm_field "$f" name)
    [ -n "$name" ] || name="$base"
    schedule=$(fm_field "$f" schedule)
    command=$(fm_field "$f" command)
    env_file=$(fm_field "$f" env_file)

    installed=false
    matches=false
    reason="not_installed"

    # A declaration missing its schedule or command is broken on the REPOSITORY side, and
    # saying `not_installed` would point the developer at their machine for a problem that
    # is in a committed file. Same principle as the rest of this survey: name which thing
    # is wrong, never collapse it into "not set up".
    if [ -z "$schedule" ] || [ -z "$command" ]; then
      drift=$((drift + 1))
      count=$((count + 1))
      entries="${entries}${sep}{\"name\": \"$(json_escape "$name")\", \"schedule\": \"$(json_escape "$schedule")\", \"command\": \"$(json_escape "$command")\", \"env_file\": \"$(json_escape "$env_file")\", \"declared\": true, \"installed\": false, \"matches\": false, \"drift_reason\": \"incomplete_declaration\"}"
      sep=", "
      continue
    fi

    # An entry belongs to THIS repo and THIS routine when its line mentions both the repo
    # path and the routine's command. Matching on the command alone would credit another
    # repository's identical routine to this one.
    line=$(printf '%s\n' "$CRON" | grep -F "$ROOT" 2>/dev/null | grep -F "$command" 2>/dev/null | head -1 || true)
    if [ -n "$line" ]; then
      installed=true
      case "$line" in
        "$schedule"*) matches=true; reason="" ;;
        *) reason="schedule_drift" ;;
      esac
      if [ "$matches" = "true" ] && [ -n "$env_file" ]; then
        # A relative env_file is resolved against the developer's HOME: it holds machine
        # secrets and therefore never lives in the repository.
        case "$env_file" in
          /*) env_path="$env_file" ;;
          *)  env_path="${HOME}/${env_file}" ;;
        esac
        if [ ! -f "$env_path" ]; then
          matches=false
          reason="missing_env"
        fi
      fi
    fi

    [ "$matches" = "true" ] || drift=$((drift + 1))
    count=$((count + 1))

    entries="${entries}${sep}{\"name\": \"$(json_escape "$name")\", \"schedule\": \"$(json_escape "$schedule")\", \"command\": \"$(json_escape "$command")\", \"env_file\": \"$(json_escape "$env_file")\", \"declared\": true, \"installed\": ${installed}, \"matches\": ${matches}, \"drift_reason\": \"${reason}\"}"
    sep=", "
  done
fi

printf '{"repo": "%s", "user": "%s", "crontab": %s, "count": %s, "drift": %s, "routines": [%s]}\n' \
  "$(json_escape "$ROOT")" "$(json_escape "$user")" "$crontab_present" "$count" "$drift" "$entries"
