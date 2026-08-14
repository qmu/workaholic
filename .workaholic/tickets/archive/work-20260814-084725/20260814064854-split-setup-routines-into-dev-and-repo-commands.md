---
created_at: 2026-08-14T06:48:54+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: split-routine-setup-into-developer-and-repository-scopes
merge_policy:
---

# Split /setup-routines into dev and repo commands

## Overview

PROPOSED. `/setup-routines` today converges the account's routines against the two
templates in `skills/workaholify/routines/` (`fb.md`, `implement.md`), both of which
every developer needs their own copy of. The ask splits the command in two along
scope: `/setup-dev-routines` keeps exactly today's behaviour, and
`/setup-repo-routines` configures routines the repository needs **one** copy of,
run by a single designated person or service account. The templates themselves carry
no scope today, so the split has to start there rather than in the commands.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/setup-routines.md` — the command being split; its `no_transport` refusal and setup-sheet recovery path must survive intact in the dev command.
- `plugins/workaholic/skills/workaholify/SKILL.md` §5 *Scheduled routines* — the flow both commands run; the scope filter belongs here, not in the command bodies.
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `implement.md` — the two developer-scoped templates; they gain a scope marker.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` / `render-routine.sh` / `render-setup-sheet.sh` — enumeration and rendering; each needs to filter by scope.
- `CLAUDE.md` (Commands table, *Routines*) and `README.md` — the command roster and the two-routines-per-repository statement both move.

## Implementation Steps

1. Add a **scope** field to the routine templates (`developer` | `repository`) and make `list-routine-templates.sh` report it — the split is a property of the template, so both commands and the setup sheets read one source.
2. Rename/replace `/setup-routines` with `/setup-dev-routines`, scoped to `developer` templates and otherwise byte-for-byte the same contract, including `no_transport: RemoteTrigger-family tool` and the sheet recovery path.
3. Add `/setup-repo-routines`, scoped to `repository` templates, and state in the command body that it is run by **one** account for the repository — the honest failure it prevents is N copies of one repository routine all firing hourly.
4. Decide and write down what happens when the wrong person runs the repo command. There is no ownership signal to check against, so the realistic answer is a stated convention plus a report of what was converged; do not invent an authorization mechanism the API cannot enforce.
5. Extend `render-setup-sheet.sh --all` to render per scope, so the copy-paste recovery path stays usable for both.
6. Update `CLAUDE.md`, `README.md` and `docs/` in the same commit — including the "Two Claude Code Web routines per repository" sentence, which stops being true.
7. Regenerate `outputs/` and run the local verification set.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every routine template declares a scope, and `list-routine-templates.sh` reports it.
- `/setup-dev-routines` converges only developer-scoped routines and keeps the `no_transport` refusal plus its setup-sheet recovery path.
- `/setup-repo-routines` converges only repository-scoped routines and states the one-account convention in its own body.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && git diff --exit-code outputs/`
- `bash plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` reports a scope for every template.

**Gate** — what must pass before approval:

- The commands above pass and no consuming repository is left with a command name that no longer exists without the rename being documented.

## Considerations

- `/setup-routines` disappearing is a breaking change for anyone with it in a runbook. Decide whether the old name stays as an alias for one release or is removed outright, and say which in the story.
- One behaviour per command still holds: these are two commands with two jobs, not one command switching on its first argument.
- The repository-scope idea only pays off if the second ticket's routine exists; a `/setup-repo-routines` that configures an empty set is a command with nothing to do.

## Final Report

Development completed as planned.

**The one Consideration that needed a ruling — the old command name — is resolved as
`/setup-routines` removed outright, not kept as an alias.** One behaviour per command is the
standing rule and an alias would have to pick a scope: aliasing to the developer half would
silently converge only two of the three routines while reporting success, which is the
"configured but not working" failure this repository already chased once through the web
bootstrap. A name that is plainly gone fails visibly and recoverably on a runbook's next use,
and the rename is stated in `CLAUDE.md`, `README.md`, the workaholify SKILL, and both loop
runbooks.

The scope filter is a **template field**, not a list in either command body — the same reason
the template set is discovered by scanning the directory rather than enumerated in code. Two
commands each carrying their own ids would be one list written twice, and the drift between
them would be invisible exactly the way live-routine drift was.

### Discovered Insights

- **Insight**: the repository-scope guarantee is unenforceable by construction, and the honest
  move is to say so in the command body rather than build a gate.
  **Context**: a Claude Code Web routine is an **account-level** record; no account can list
  another's. So nothing in this plugin — or in the product — can detect the failure the scope
  exists to prevent (six developers each converging the repository's single routine, six copies
  firing every hour). `/setup-repo-routines` therefore states the single-owner convention and
  reports exactly which routines it converged, by name, so a second person sees their own
  duplicate in their own report. Any authorization mechanism invented here would have looked
  stronger than the API can actually carry.

- **Insight**: `render-setup-sheet.sh`'s `--all` loop had to filter *before* calling `sheet()`,
  not inside it.
  **Context**: the script runs under `set -eu`, so a `return 1` from `sheet()` inside the `--all`
  loop would abort the whole render. A scope that simply does not apply to a template is a
  **skip**; a scope mismatch on an explicitly named template id is a **refusal**. Same field,
  two different meanings depending on how the caller asked.
