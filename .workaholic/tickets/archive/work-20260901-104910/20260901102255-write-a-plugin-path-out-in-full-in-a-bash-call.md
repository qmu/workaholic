---
created_at: 2026-09-01T10:22:55+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-an-unattended-run-s-shell-so-an-allowlist-can-name-it
merge_policy:
verification_handoff: 
---

# Write a plugin path out in full in a Bash call

## Overview

PROPOSED. A `/moderate` tick on a consuming repository stalled on a read of a skill's own
documentation, composed as `export CLAUDE_PLUGIN_ROOT=<root>; sed -n '…' $CLAUDE_PLUGIN_ROOT/skills/notify/SKILL.md | head -80`.
Permission rules match on the command, and that command's first token is `export` — so
`Bash(sed:*)`, `Bash(bash:*)` and every other per-tool rule miss it, and the only rule that
would match is `Bash(export:*)`, which permits whatever follows the semicolon. An operator is
then choosing between a routine that stalls and an allowlist that permits anything.

The cause is upstream of the composition: the skills document their commands as
`bash ${CLAUDE_PLUGIN_ROOT}/skills/<area>/scripts/<script>.sh` — correct for the markdown —
and that variable is not set in the Bash tool's environment, so a session has two ways to
name the path and reaches for the export.

This ticket states the rule: **a plugin path is written out in full in a Bash call — one
command per call, the reader or interpreter as the first token, no assignment prefix.**

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/shell.md` — the home. Its
  *Reading a plugin script: a read tool, never a Bash text pipeline* section (2026-08-31) is
  the same measured failure family and the new clause belongs beside it.

## Implementation Steps

Diagnosis first — the ask is a failure report, so reproduce and localize before writing.

1. **Reproduce the shape.** Confirm from this repository's own history that the documented
   invocation is `bash ${CLAUDE_PLUGIN_ROOT}/skills/…` and that nothing sets that variable in
   the Bash tool's environment, so a session must either expand it or export it. This
   proposal's own run reproduced it: its first two Bash calls were
   `export CLAUDE_PLUGIN_ROOT=…; bash …`, composed from the documented notation with no
   instruction to the contrary.
2. **Localize.** Read the whole of `rules/shell.md`'s read-tool section. It names the
   *pipeline* half of the failure and says nothing about the assignment prefix — so a session
   that obeyed it in full could still compose `export VAR=…; <reader>` and stall.
3. **Write the clause** into `rules/shell.md`, beside that section: a plugin path is written
   out in full in a Bash call; one command per call; the reader or interpreter is the first
   token; no `VAR=…;` prefix and no `env VAR=… <cmd>` form, which moves the problem rather
   than removing it. State that `${CLAUDE_PLUGIN_ROOT}` stays the correct notation in
   markdown — what changes is only how a session spells the call it actually runs.
4. **Carry the evidence**, as the sibling section does: the measured stall, and why no
   allowlist covers the exported form (`Bash(export:*)` is the only matching rule and it
   permits everything after the semicolon).
5. **Say what enforcement there is.** This is prose read by a session, like its sibling; a
   mechanical row over the plugin's markdown would find nothing, because the markdown never
   showed the export — the composition happens at run time. Do not dress it as a check.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `rules/shell.md` states the full-path, first-token, no-assignment-prefix rule for a Bash
  call naming a plugin path, with the measured stall and the allowlist reasoning
- The clause says `${CLAUDE_PLUGIN_ROOT}` remains correct in markdown, so nothing reads it as
  a licence to inline absolute paths into skill documentation
- The `env VAR=… <cmd>` form is named and refused for the same reason

**Verification method** — the commands/tests/probes that prove them:

- Read the section back and check each criterion against its text
- `node scripts/test-workflow-scripts.mjs` and `node scripts/build-plugins/verify.mjs` pass

**Gate** — what must pass before approval:

- The two commands above pass and the section reads as one rule with its sibling, not as a
  second, competing statement of the same failure

## Considerations

- The sibling rule deliberately declined a mechanical check, with its reasons written out.
  The same reasons hold here and more strongly; adding a grep would be a regression in
  honesty, not an improvement.
- The operator-facing half — which tool an allowlist should then name — is a configuration
  question `workaholic:workaholify` already owns. Out of scope here; note it rather than
  widen this ticket.
- **Some seams are documented with an env-var prefix and have no other form**, e.g.
  `WORKAHOLIC_AUTO_MERGE=1 WORKAHOLIC_PR_TITLE="…" bash …/publish-tree-pr.sh …`
  (`specificate/reference/workflow.md` step 10). A one-command `VAR=value <reader>` prefix has
  the same first token problem as `export …;`, and this proposal's own publish had to use it
  because shell state does not persist between tool calls. So the clause must say what such a
  seam does instead — carry the values as flags, or state the prefix as a named exception with
  its allowlist cost — rather than forbidding a shape the loop still has to run.

## Final Report

Development completed as planned.

The clause landed in `plugins/workaholic/rules/shell.md` as its own section,
*Composing the call: the path in full, the reader first, no assignment prefix*, placed
between the read-tool section it extends and the GitHub-transport section. It carries the
measured stall verbatim, the allowlist reasoning (`Bash(export:*)` is the only matching rule
and it permits everything after the semicolon), the statement that `${CLAUDE_PLUGIN_ROOT}`
remains correct in markdown, the refusal of `env VAR=… <cmd>` on the same first-token
grounds, and the named exception for the seams documented with a one-command `VAR=value`
prefix. Enforcement is stated as prose a human reads, with the reason a mechanical row would
find nothing: the composition happens at run time and never appears in this tree's markdown.

### Discovered Insights

- **Insight**: the export is not only unallowlistable, it buys nothing — shell state does not
  persist between Bash tool calls, so an exported variable is never carried forward to a later
  call.
  **Context**: the rule reads as a pure cost with no benefit to trade against, which is why it
  can be stated absolutely rather than as a preference. The one genuine counter-case (a seam
  whose script takes its inputs only as environment variables) is a *one-command* prefix, not
  an export, and is handled as a named exception.
- **Insight**: `rules/shell.md`'s sibling read-tool section had already written down why a
  mechanical check cannot carry here, and the reasoning transfers exactly.
  **Context**: a later session tempted to add a grep should read that paragraph first — a row
  keying on `export` would fire on this very section's own prose.
