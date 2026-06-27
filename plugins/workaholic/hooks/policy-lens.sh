#!/bin/sh -eu
# UserPromptSubmit hook: the always-on engineering-policy LENS for the Workaholic
# workflow commands (/ticket, /report, /ship, /trip, /drive).
#
# This is a *referring* mechanism, not a safeguard: it injects a context block
# pointing the agent at the project's policy skills and never blocks or rejects
# the prompt (always exit 0). The counterpart hook validate-ticket.sh is the
# blocking safeguard; this one only adds context.
#
# Trigger: UserPromptSubmit fires AFTER slash-command expansion, so the payload's
# .prompt carries the *expanded command body*, not the literal "/ticket" the user
# typed. The workflow commands therefore opt in by carrying the stable sentinel
# `workaholic:policy-lens` in their markdown; we match on that marker
# (deterministic, scoped to exactly the tagged commands) rather than on slash
# tokens (which every command body cross-references and would over-trigger).
# Because the sentinel rides in the expanded command body, the lens fires once
# per workflow invocation — so the index below loads at the start of the workflow
# and stays in accumulated context, not re-injected on every follow-up turn.
#
# Refer for bodies, embed only the index: the injected pointer never restates a
# policy's RULES — the qmu.co.jp-synced hard copies under skills/*/policies/ stay
# the single source of truth, read on demand. The one bounded exception is the
# generated policy INDEX (hooks/policy-index.md): a table of contents (per-policy
# heading + one-line summary) is appended so the agent always sees what policies
# exist. Headings are an index, not the policy text — the bodies remain on-demand.

set -eu

input=$(cat)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
INDEX_FILE="${SCRIPT_DIR}/policy-index.md"

# Guard the parse: a non-JSON prompt must degrade to "no sentinel" (exit 0),
# never trip set -e.
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)

# No sentinel -> not a tagged workflow command -> silent no-op.
case "$prompt" in
  *workaholic:policy-lens*) ;;
  *) exit 0 ;;
esac

context='[Workaholic engineering-policy lens] You are running a Workaholic workflow command (ticket / report / ship / trip / drive). Apply the project'"'"'s engineering policies as your judging lens before you scope, judge, or ship.

Load and apply the relevant policy index skills — workaholic:planning, workaholic:design, workaholic:implementation, workaholic:operation — which index the canonical qmu.co.jp policies (English hard copies under each skill'"'"'s policies/ directory). Apply the ones the change touches.

Two policies are always-apply for any code or new-project work:
- implementation/directory-structure — enforce the conventional project layout (especially when scaffolding a new project).
- implementation/coding-standards — follow the TypeScript/style conventions.

Read the policy files for the actual rules; do not assume them. This is a lens, not a gate — it constrains nothing and blocks nothing.

The always-loaded policy index (table of contents) follows. Open a policy'"'"'s linked file only when your change touches it.'

# Append the generated policy index (the bounded embed: headings only, no bodies).
# Degrade gracefully — if the generated file is absent, fall back to pointer-only.
if [ -f "$INDEX_FILE" ]; then
  context="${context}

$(cat "$INDEX_FILE")"
fi

jq -n --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}' || true

exit 0
