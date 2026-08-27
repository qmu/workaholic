#!/bin/sh -eu
# Repair the web bootstrap `check-bootstrap.sh` reports on — install the canonical
# SessionStart hook and register it correctly in .claude/settings.json.
#
# WHY IT EXISTS: /workaholify is the preparation command, not an audit (the
# developer's ruling, 2026-08-14, issue #445). check-bootstrap.sh names every
# problem separately precisely because each needs a different fix; until this
# script every one of those fixes was a manual follow-up. An unbootstrapped
# repository schedules its routines, fires them on time, and does nothing — the
# failure mode that reads as healthy — so leaving the repair to a runbook is what
# the ruling ends.
#
# ONE REPAIR PER NAMED PROBLEM, mapped one-to-one onto the check's vocabulary:
#
#   hook_missing / hook_stale  install (or refresh) the canonical copy of
#                              bootstrap/session-start.sh at .claude/hooks/.
#   not_registered             add the SessionStart entry that runs it.
#   matcher                    correct the matcher to `startup` (the event also
#                              fires on resume/clear/compact).
#   timeout                    raise the timeout to 120 (a marketplace clone plus
#                              install can exceed the default).
#   enabled_plugin             add workaholic@workaholic to enabledPlugins.
#   marketplace                add workaholic to extraKnownMarketplaces.
#   identity_map_missing       scaffold .claude/git-identities — the comment header and
#                              NO entries. The file's absence makes the hook's identity
#                              step a permanent no-op; its CONTENTS are the operator's.
#   identity_map_uncovered     append the proposed line for each uncovered address, as a
#                              COMMENT the operator uncompletes and uncomments. Which
#                              GitHub account an address belongs to is a fact only a human
#                              has, so this repair proposes and never decides — the same
#                              line the check already reports, put where the fix is made.
#
# THE MAPPING REPAIR NEVER WRITES AN ENTRY UNAIDED. A commented proposal is not an entry:
# `identity.sh` skips comments, so a repository that runs this apply and never edits the
# file behaves exactly as it did before. Inventing `<login>` would be the guess the whole
# identity change exists to remove — a wrong entry silently makes one person's work
# another's, while an uncovered address is merely still uncovered.
#
# A hook that already `matches_canonical` reports no problem, so it is never
# touched: the installed file is only ever overwritten when the check said it
# differs from the plugin's copy.
#
# IT REFUSES RATHER THAN HALF-WRITES. Settings are read with python3 and rewritten
# from the parsed object (parse-don't-regex — a SessionStart entry nests several
# ways and a sed would corrupt a file it did not understand). An existing
# .claude/settings.json that does not parse is `refused: settings_unparseable`
# with NOTHING written at all — not the hook either, because a half-bootstrapped
# repository is worse than an unbootstrapped one: the hook would sit installed and
# unregistered, and the next check would report a state this run created. The
# operator's recovery path is the report.
#
# IDEMPOTENT: a bootstrapped repository is `{"changed": false, "applied": []}` and
# no byte moves, so the step is safe on every run.
#
# Usage: apply-bootstrap.sh [repo-root]
# Output: JSON {changed, applied:[...], refused, ok, problems_before, problems_after}
#   refused: "" | settings_unparseable | hook_source_missing | unwritable
#            `unwritable` covers an unwritable mapping too: nothing is written at all,
#            the hook included, exactly as the other refusals do.

set -eu

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CANON="${SCRIPT_DIR}/../bootstrap/session-start.sh"

HOOK_REL=".claude/hooks/session-start.sh"
HOOK="${ROOT}/${HOOK_REL}"
SETTINGS="${ROOT}/.claude/settings.json"

before=$(sh "${SCRIPT_DIR}/check-bootstrap.sh" "$ROOT")

emit_refusal() {
  # $1 refusal id
  printf '{"changed": false, "applied": [], "refused": "%s", "ok": false, "problems_before": %s, "problems_after": %s}\n' \
    "$1" \
    "$(printf '%s' "$before" | sed -n 's/.*"problems": *\(\[.*\]\).*/\1/p')" \
    "$(printf '%s' "$before" | sed -n 's/.*"problems": *\(\[.*\]\).*/\1/p')"
}

if [ ! -f "$CANON" ]; then
  emit_refusal hook_source_missing
  exit 0
fi

# Refuse BEFORE anything is written: an unparseable settings file means this run
# cannot register the hook, and installing it alone would leave a state nobody
# asked for. The check is exactly the one check-bootstrap.sh makes.
if [ -f "$SETTINGS" ] && ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$SETTINGS" 2>/dev/null; then
  emit_refusal settings_unparseable
  exit 0
fi

if [ ! -w "$ROOT" ]; then
  emit_refusal unwritable
  exit 0
fi

# An existing mapping this run cannot write to is refused BEFORE anything moves, on the
# same principle as `settings_unparseable`: a half-applied bootstrap is worse than an
# unapplied one, and the operator's recovery path is the report.
IDMAP_REL=".claude/git-identities"
IDMAP="${ROOT}/${IDMAP_REL}"
if [ -f "$IDMAP" ] && [ ! -w "$IDMAP" ]; then
  emit_refusal unwritable
  exit 0
fi

applied=''
add_applied() {
  if [ -n "$applied" ]; then
    applied="${applied}, \"$1\""
  else
    applied="\"$1\""
  fi
}

problems=$(printf '%s' "$before" | sed -n 's/.*"problems": *\[\(.*\)\].*/\1/p')

has_problem() {
  printf '%s' "$problems" | grep -q "\"$1" 2>/dev/null
}

# The identity mapping's problems are ADVISORIES on the check (they do not gate `ok` — see
# that script's note), so they are read from their own field rather than from `problems`.
advisories=$(printf '%s' "$before" | sed -n 's/.*"advisories": *\[\(.*\)\].*/\1/p')

has_advisory() {
  printf '%s' "$advisories" | grep -q "\"$1" 2>/dev/null
}

# --- the hook file ------------------------------------------------------------
if has_problem hook_missing || has_problem hook_stale; then
  mkdir -p "${ROOT}/.claude/hooks"
  cp "$CANON" "$HOOK"
  chmod 0755 "$HOOK"
  if has_problem hook_missing; then add_applied hook_missing; else add_applied hook_stale; fi
fi

# --- the settings entries -----------------------------------------------------
if has_problem not_registered || has_problem matcher || has_problem timeout \
  || has_problem enabled_plugin || has_problem marketplace; then
  mkdir -p "${ROOT}/.claude"
  python3 - "$SETTINGS" <<'PY'
import json, os, sys

path = sys.argv[1]
data = {}
if os.path.isfile(path):
    with open(path) as fh:
        data = json.load(fh)

COMMAND = '"$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh'

hooks = data.setdefault("hooks", {})
groups = hooks.setdefault("SessionStart", [])

# Correct the group that already runs the hook, rather than appending a second one:
# two entries would run the bootstrap twice per session and disagree about matcher.
found = None
for group in groups:
    for h in group.get("hooks") or []:
        if "session-start.sh" in (h.get("command") or ""):
            found = (group, h)
            break
    if found:
        break

if found is None:
    groups.append({
        "matcher": "startup",
        "hooks": [{"type": "command", "command": COMMAND, "timeout": 120}],
    })
else:
    group, entry = found
    group["matcher"] = "startup"
    if (entry.get("timeout") or 0) < 120:
        entry["timeout"] = 120
    entry.setdefault("type", "command")

data.setdefault("enabledPlugins", {})["workaholic@workaholic"] = True
data.setdefault("extraKnownMarketplaces", {}).setdefault(
    "workaholic", {"source": {"source": "github", "repo": "qmu/workaholic"}}
)

with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
  for p in not_registered matcher timeout enabled_plugin marketplace; do
    if has_problem "$p"; then add_applied "$p"; fi
  done
fi

# --- the identity mapping -----------------------------------------------------
# Scaffold it when absent (header only, no entries), and append each uncovered address as
# a COMMENTED proposal. Neither writes an entry: which account an address belongs to is a
# human's ruling, and the repair's whole job is to put the line where the fix is made.
if has_advisory identity_map_missing; then
  mkdir -p "${ROOT}/.claude"
  {
    printf '# <github-login>=<canonical-email>[,<alias-email>...], one per line: the web bootstrap
'
    printf '# (.claude/hooks/session-start.sh) maps the session GitHub login to the developer git
'
    printf '# identity so personally-assigned tickets are claimable; committed because these emails
'
    printf '# are already public in git history.
'
    printf '# The FIRST address is canonical; every address after it is another address of the SAME
'
    printf '# person. Read it through gather/scripts/identity.sh — never by hand.
'
  } > "$IDMAP"
  add_applied identity_map_missing
fi

if has_advisory identity_map_uncovered; then
  audit=$(sh "${SCRIPT_DIR}/audit-identity-coverage.sh" "$ROOT" 2>/dev/null || printf '{"uncovered": []}')
  proposed=0
  for line in $(printf '%s' "$audit" | tr ',' '\n' | sed -n 's/.*"line": "\([^"]*\)".*/\1/p'); do
    # Idempotent: a proposal already in the file is never repeated.
    if ! grep -qF "proposed: ${line}" "$IDMAP" 2>/dev/null; then
      printf '# proposed: %s  (fill in the GitHub login and uncomment; a commented line is not an entry)\n' \
        "$line" >> "$IDMAP"
      proposed=$((proposed + 1))
    fi
  done
  [ "$proposed" -gt 0 ] && add_applied identity_map_uncovered
fi

after=$(sh "${SCRIPT_DIR}/check-bootstrap.sh" "$ROOT")
ok=$(printf '%s' "$after" | sed -n 's/.*"ok": *\([a-z]*\).*/\1/p')
[ -n "$ok" ] || ok=false

changed=false
[ -n "$applied" ] && changed=true

printf '{"changed": %s, "applied": [%s], "refused": "", "ok": %s, "problems_before": %s, "problems_after": %s}\n' \
  "$changed" "$applied" "$ok" \
  "$(printf '%s' "$before" | sed -n 's/.*"problems": *\(\[.*\]\).*/\1/p')" \
  "$(printf '%s' "$after" | sed -n 's/.*"problems": *\(\[.*\]\).*/\1/p')"
