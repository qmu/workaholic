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

# Put the shell rule where every session loads it

## Overview

PROPOSED. The rule that would have stopped the measured stall already existed —
`rules/shell.md`, *Reading a plugin script: a read tool, never a Bash text pipeline*, written
2026-08-31 against the same class of failure. It did not reach the session that stalled, and
the reason is mechanical: `rules/shell.md` carries `paths: ['**/*.sh']`, so it loads only when
a `.sh` file is in context. The tick that stalled was reading `skills/notify/SKILL.md` — a
markdown file — and had no `.sh` file in hand, so the rule was not in its context at all.

`rules/general.md` and `rules/interaction.md` both carry `paths: ['**/*']` and are always
loaded. A rule about how a session composes a Bash call is a rule about the session, not about
`.sh` files, so its reach must not depend on which file the session happens to be reading.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/general.md` — `paths: ['**/*']`, always loaded; the home for the
  one-line ceiling and the `${CLAUDE_PLUGIN_ROOT}` spelling note.
- `plugins/workaholic/rules/shell.md` — `paths: ['**/*.sh']`; keeps the full rule and its
  evidence, and is what the ceiling points at.
- `CLAUDE.md` — the *Design principles* bullet
  *`${CLAUDE_PLUGIN_ROOT}` for every skill script reference* is where this repository's own
  readers meet the notation.

## Implementation Steps

Diagnosis first — this ticket exists because an existing rule did not reach its reader.

1. **Reproduce the gap.** Read the frontmatter of all three rule files and confirm the split:
   `shell.md` is `'**/*.sh'`, `general.md` and `interaction.md` are `'**/*'`. Confirm that the
   stalled tick's working set (a `SKILL.md`) contains no `.sh` file.
2. **Localize the boundary.** The shell conventions themselves (POSIX sh, shebangs, the jq
   fallback rule) are correctly scoped to `.sh` files. Only the rules about *how a session
   composes a Bash call* are mis-scoped. Decide the split on that line and write it down —
   do not move the whole file.
3. **Add the ceiling to `rules/general.md`**: one bullet stating that a Bash call naming a
   plugin path writes the path out in full, one command per call, reader first, no assignment
   prefix — pointing at `rules/shell.md` for the evidence and the full statement. A ceiling,
   not a copy: the story stays in one place.
4. **Add the spelling note beside the notation**, in `CLAUDE.md`'s `${CLAUDE_PLUGIN_ROOT}`
   design-principle bullet: the variable is the plugin boundary's notation for markdown, and a
   session expands it when it composes the actual call.
5. **Check the rest of the reach.** Look for any other always-on rule this belongs beside, and
   for any command or routine markdown that models the exported form; report what was found
   rather than silently widening the change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A session with no `.sh` file in context reads the plugin-path Bash-call rule from an
  always-on rule file
- `rules/shell.md` keeps the full statement and its evidence; the always-on copy is a ceiling
  pointing at it, not a duplicate of the reasoning
- The `${CLAUDE_PLUGIN_ROOT}` design principle says the notation is expanded by the session at
  call time, and is not itself changed

**Verification method** — the commands/tests/probes that prove them:

- Read each edited file back and check its `paths:` frontmatter against the criterion
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` —
  `outputs/` regenerated and self-contained
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The three commands above pass with `outputs/` regenerated and committed

## Considerations

- The always-on rule files are read on every turn of every session; a long addition there is a
  standing cost. Keep the ceiling to a bullet.
- Widening `rules/shell.md`'s own `paths:` to `'**/*'` was the obvious alternative and is
  worse: it would load the POSIX shebang conventions and the jq-fallback rule into every
  markdown session too. The split above is the narrower repair.
- This ticket depends on the wording landed by *Write a plugin path out in full in a Bash
  call*; drive it after that one.

## Final Report

Development completed as planned.

**Reproduced the gap** (step 1): `rules/shell.md` carries `paths: ['**/*.sh']`; `rules/general.md`
and `rules/interaction.md` carry `paths: ['**/*']`; `diagrams.md` is `'**/*.md'`, `typescript.md`
is `'**/*.ts(x)'`, `workaholic.md` is `'.workaholic/**/*'`. So the two always-on files are
`general.md` and `interaction.md`, and a session whose working set is a `SKILL.md` loads neither
`shell.md` nor any other file carrying the rule.

**Localized the boundary** (step 2): the POSIX conventions, the shebang rule and the jq-fallback
rule are about `.sh` files and stay scoped to them. Only the two rules about *how a session
composes a Bash call* — the read-tool rule and the new plugin-path rule — are mis-scoped, and
only the second is lifted here as a ceiling; the read-tool rule is reached through the no-prompt
clause the sibling ticket writes into `rules/interaction.md`.

**Checked the rest of the reach** (step 5): a sweep of `plugins/`, `.claude/` and `docs/` for
`export CLAUDE_PLUGIN_ROOT`, `env CLAUDE_PLUGIN_ROOT` and any `CLAUDE_PLUGIN_ROOT=` assignment
found **no occurrence outside `rules/shell.md`'s own prose** — confirming the diagnosis that the
markdown never modelled the export and the composition happens at run time. A sweep for a
documented `VAR=value bash …` invocation found exactly one live seam,
`specificate/reference/workflow.md` step 10's `publish-tree-pr.sh` call, which is the named
exception `rules/shell.md` already records. Nothing was silently widened.

### Discovered Insights

- **Insight**: `rules/general.md` is where a rule about the *session* belongs, and
  `rules/shell.md` is where a rule about *shell files* belongs — the split is by subject, not by
  topic, and `paths:` is what makes that split load-bearing rather than editorial.
  **Context**: a future rule about how an agent composes a command (a tool choice, a quoting
  convention, an invocation shape) faces the same question and has the same answer. Widening
  `shell.md`'s own `paths:` to `'**/*'` was the obvious alternative and is worse: it would load
  the POSIX shebang conventions and the jq-fallback rule into every markdown session too.
- **Insight**: the always-on rule files are read on every turn of every session, so their cost is
  paid continuously.
  **Context**: that is why the addition here is one bullet pointing at the full statement rather
  than a copy of it — the story stays in one place and only the ceiling is paid for hourly.
