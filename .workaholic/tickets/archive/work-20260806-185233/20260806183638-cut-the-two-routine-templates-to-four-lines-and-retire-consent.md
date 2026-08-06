---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on: 20260806184521-carry-ownership-as-a-field-not-as-a-directory.md
mission: reduce-the-loop-to-two-routines-and-one-behaviour-per-command
merge_policy:
---

# Cut the two routine templates to four lines and retire Consent

## Overview

PROPOSED. A developer configures these by hand, once per project, so every field is a cost
that multiplies by the number of projects. Cut each prompt to four lines — read the target
and payload out of the triggering artifact, say in the payload's own language that work has
started, run the one command, post the result in the given format — and retire `[Consent]`,
leaving exactly two templates. Everything else the prompts carry is already owned by a
skill the session loads.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` → the Propose template
- `plugins/workaholic/skills/workaholify/routines/drive.md` → the Implement template
- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` — deleted with `[Consent]`
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — the sheets
- `plugins/workaholic/skills/workaholify/SKILL.md` — the template set and post shapes

## Implementation Steps

1. Rewrite both prompts to the four-line shape, with the post format inline (that is what a
   routine cannot defer: the channel and the shape are its whole output contract).
2. Retire `merged-pr.md` and every reference to `[Consent]`, recording what the merge
   announcement cost and why it is not worth a third standing process.
3. Re-render the setup sheets and confirm each fits on one screen.
4. Update `CLAUDE.md`, the SKILL and both runbooks.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Exactly two templates ship, each prompt four lines, each naming only the command and the
  channel + format.
- The setup sheet for either routine fits what a developer can act on without scrolling.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (template count, prompt pins)
- `render-setup-sheet.sh --all` read end to end

**Gate** — what must pass before approval:

- Nothing a skill already owns is restated in a prompt.

## Considerations

- Retiring `[Consent]` is **approved** (developer, 2026-08-06): a human-merged pull request
  is then announced by nobody, since `/implement` posts only for units it ran. That is the
  accepted cost of one fewer standing process per project, and it should be stated where a
  developer will meet it.
- **The identity line is not kept — it is designed away.** An earlier draft of this ticket
  proposed keeping `git config user.email` in the prompt, because without it the run
  resolves no `todo/<user>/` and reports an empty queue as a healthy tick. The developer
  rejected the patch and the flaw behind it: ownership belongs in a field, not a directory
  (`20260806184521-carry-ownership-as-a-field-not-as-a-directory.md`). **This ticket depends
  on that one** and the prompt drops to four lines only after it lands.

## Final Report

Development completed as planned. Two templates ship (`fb` = `[Propose]`,
`implement` = `[Implement]`), each prompt is exactly four lines, and `[Consent]` is
retired with its cost written where a developer meets it.

### Discovered Insights

- **Insight**: The four-line rule needed a stated *boundary*, not just a length.
  "Nothing a skill already owns is restated in a prompt" is the gate, but a
  routine's **channel and post shape** are owned by nothing else — they are the
  routine's entire output contract, and no skill can state them because they are
  per-repository. So the rule became: four lines carrying the environment, the
  payload, the one command, and the channel + shape; everything else defers.
  **Context**: Without naming the exception, the next slimming would delete the
  post format as "restated" and the routine would run and announce nothing.
- **Insight**: `{repo}` is only demanded by the post-shape line. Cutting the
  prompts removed the last `{repo}/pull/<number>` reference, which would have
  made the SKILL's "three substitutions, each demanded by the live routines"
  claim false and left the link form for a session to invent. The link form is
  now inside the shape line, which is where it belongs anyway.
  **Context**: `testWorkaholifyRoutines` pins that `{repo}` still renders.
- **Insight**: Both renderer scripts (`list-routine-templates.sh`,
  `render-setup-sheet.sh`) discover the template set by scanning the directory,
  so retiring a template and renaming one needed no script change at all — only
  the tests and the prose enumerate ids.
  **Context**: This is the property that made `[Propose Batch]`'s addition and
  same-day retirement cheap, and it held again here.
