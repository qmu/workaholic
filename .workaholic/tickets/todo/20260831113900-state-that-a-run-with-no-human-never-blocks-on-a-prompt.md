---
created_at: 2026-08-31T11:39:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# State that a run with no human never blocks on a prompt

## Overview

`rules/interaction.md` governs whether to raise an `AskUserQuestion`, and every command
contract repeats *no `AskUserQuestion` anywhere* for its own unattended entrance. Neither
covers a **permission prompt**, which is the same act by a different mechanism: the run
stops until somebody attends to it. Three consecutive ticks sat at `requires_action` for
exactly that reason, and approving one produced another, because nothing bounds how many
a run can raise. State the policy once, for every unattended run, rather than per
command.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/interaction.md` — where *whether to ask* already lives; the
  natural home, since this is the same question one mechanism wider.
- `plugins/workaholic/rules/general.md` — the ground rules an unattended run answers to.
- `plugins/workaholic/skills/drive/SKILL.md` and `skills/moderate/SKILL.md` — the two
  unattended contracts that currently name only `AskUserQuestion`.
- `CLAUDE.md` — the command table's unattended clauses.


## Implementation Steps

1. Write the policy once: **a run with no human present never blocks on a prompt of any
   kind.** Name the two admitted outcomes and say that waiting is neither — proceed under
   a declared policy, or refuse the single action and carry on with the rest of the run,
   recording what was refused and why.
2. Say why waiting is the worst of the three, in the operator's own terms: it produces no
   record at all, because the step that would write one is the step the waiting prevents.
3. Draw the distinction the ask draws, because it is the one a reader will otherwise
   collapse: a **notification** tells someone what happened and they read it when they
   choose; a **prompt** stops the run until someone attends to it, which makes an hourly
   cadence depend on a person being awake. That a notification can reach a person is not
   a licence to ask them.
4. Widen the existing unattended clauses from `AskUserQuestion` to *any prompt*, in one
   sentence each, referring to the policy rather than restating it.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The policy is stated once, with its two admitted outcomes and the reason waiting is
  neither, and the notification/prompt distinction is written down.
- Every unattended contract that names `AskUserQuestion` refers to the policy rather than
  implying a prompt is a different question.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The policy is in one place; no second wording of it exists to drift.


## Considerations

- This is prose, and prose alone is what this repository already calls a rule whose
  enforcement is a human reading it. The mechanical half is the configuration the next
  ticket establishes: a policy nothing configures is a policy each run re-decides.
- The sibling ticket about reading a plugin script without a Bash text pipeline stays —
  the operator's own words are that the misclassification is real and is not the defect.

