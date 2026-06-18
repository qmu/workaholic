#!/bin/bash
# UserPromptSubmit hook: the always-on engineering-policy LENS for the Workaholic
# workflow commands (/ticket, /report, /ship, /trip).
#
# This is a *referring* mechanism, not a safeguard: it injects a short context
# block pointing the agent at the project's policy skills and never blocks or
# rejects the prompt (always exit 0). The counterpart hook validate-ticket.sh is
# the blocking safeguard; this one only adds context.
#
# Trigger: UserPromptSubmit fires AFTER slash-command expansion, so the payload's
# .prompt carries the *expanded command body*, not the literal "/ticket" the user
# typed. The four workflow commands therefore opt in by carrying the stable
# sentinel `workaholic:policy-lens` in their markdown; we match on that marker
# (deterministic, scoped to exactly the tagged commands) rather than on slash
# tokens (which every command body cross-references and would over-trigger).
#
# Refer, never embed: the injected text only points at policy skills/paths — it
# never restates a policy's rules — so the qmu.co.jp-synced hard copies under
# skills/*/policies/ remain the single source of truth.

input=$(cat)

prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)

# No sentinel -> not a tagged workflow command -> silent no-op.
case "$prompt" in
  *workaholic:policy-lens*) ;;
  *) exit 0 ;;
esac

context='[Workaholic engineering-policy lens] You are running a Workaholic workflow command (ticket / report / ship / trip). Apply the project'"'"'s engineering policies as your judging lens before you scope, judge, or ship.

Load and apply the relevant policy index skills — workaholic:planning, workaholic:design, workaholic:implementation, workaholic:operation — which index the canonical qmu.co.jp policies (English hard copies under each skill'"'"'s policies/ directory). Apply the ones the change touches.

Two policies are always-apply for any code or new-project work:
- implementation/directory-structure — enforce the conventional project layout (especially when scaffolding a new project).
- implementation/coding-standards — follow the TypeScript/style conventions.

Read the policy files for the actual rules; do not assume them. This is a lens, not a gate — it constrains nothing and blocks nothing.'

jq -n --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'

exit 0
