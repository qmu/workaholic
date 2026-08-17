---
created_at: 2026-08-17T11:37:50+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817113749-register-the-housekeep-log-area.md
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Add the /housekeep command and skill

## Overview

The spine the other step tickets hang off: a thin `/housekeep` command and the
`workaholic:housekeep` skill that owns the run contract — the nine steps in order, what
each is allowed to write, and what each reports. This ticket builds the orchestration and
the per-step no-ops; each later ticket fills in its own steps' behaviour behind the
contract this one states.

The command is **unattended by contract**, exactly as `/implement` and `/propose` are: no
`AskUserQuestion` at any step (step 9's questions go to Slack — its own ticket), every
abort a machine-readable reason, and one report line at the end naming what each step did,
skipped, or could not read. A degraded read is reported and skipped, never half-applied.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/observability.md` — an unattended tick is only trustworthy if it says what it did

## Key Files

- `plugins/workaholic/commands/housekeep.md` — new. Thin by design principle: a few lines
  naming the skill, the section, and the entry-point contract. Model it on
  `commands/release-status.md`, the closest existing unattended reader.
- `plugins/workaholic/skills/housekeep/SKILL.md` — new. ~50–150 lines; overflow to
  `reference/`. Carries `metadata.internal: true` because it will bear scripts.
- `plugins/workaholic/skills/housekeep/reference/workflow.md` — new. The ordered step
  contract, in the shape of `propose/reference/workflow.md`.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the only sanctioned GitHub
  transport. `gh issue …`/`gh pr …`/`gh repo …` are GraphQL-backed, a web session may 403
  mid-run, and `test-workflow-scripts.mjs` fails the build on any such call under `skills/`.
- `plugins/workaholic/rules/shell.md`, `rules/general.md` — the standing rules a new skill
  inherits (no complex inline shell in command markdown; `${CLAUDE_PLUGIN_ROOT}` on every
  script reference).
- `CLAUDE.md`, `README.md` — the commands table and the project structure listing.

## Implementation Steps

1. Write the skill first, the command second — the command is a pointer, so it cannot be
   written before the section it points at exists.
2. State the run contract in `reference/workflow.md`: the nine steps in order, each with
   its script, its abort reason, and its "what this step may write" line. A step that
   cannot run (missing connector, unreadable inbox) is **reported by name**, never rendered
   as a step that found nothing — the distinction `list-inbound-issues.sh` already makes.
3. Implement the orchestration and the per-tick log entry (the area from the previous
   ticket): open the log, run each step, record its outcome, close it.
4. Stub each step behind a named function/script the later tickets replace, so the mission
   can land incrementally and a half-built routine reports `not_implemented` rather than
   silently skipping.
5. Register in `CLAUDE.md`'s commands table and `README.md`; regenerate the bundle.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/housekeep` runs end to end with every step stubbed, writes exactly one log entry, and
  reports one line per step.
- No `AskUserQuestion` anywhere in the command or skill.
- Every GitHub read goes through `gh-rest.sh`; no `gh issue|pr|repo <verb>` under `skills/`.
- The skill carries `metadata.internal: true` and every script reference uses
  `${CLAUDE_PLUGIN_ROOT}`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — includes the `gh` transport assertion.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- A dry run of `/housekeep` in a throwaway checkout: one log entry, nine reported steps.

**Gate** — what must pass before approval:

- `Validate Plugins` and `Outputs Freshness` CI green.

## Considerations

- **Nine steps in one hourly tick is a long run.** Order them cheapest-first and make each
  independently skippable, so a slow or failing step cannot starve the rest. The report
  should name the steps that did not run for lack of time as clearly as the ones that
  failed.
- The routine's `allowed_tools` is decided in the template ticket, but the skill should
  work with the smallest set: several steps only read.
