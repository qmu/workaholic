---
created_at: 2026-08-17T11:37:50+00:00
status: done
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

## Final Report

Development completed as planned. The spine is in place: `/housekeep` runs end to end with
eight of nine steps stubbed, writes exactly one log section with one line per step, and
reports one row per step. The step list lives in `run.sh`, the per-step contract in
`reference/workflow.md`, and each stub names the ticket that fills it in.

Two design points worth stating, because the later tickets build on them:

1. **`run.sh` is the tick's only log writer.** Step scripts print a verdict and write
   nothing. Two writers would race on the log's `(tick, step)` key and turn its idempotence
   into a property of caller discipline rather than of the code.
2. **`needs_agent` is the seam between script and model.** A step script is non-interactive
   and composes no prose: it probes, decides, and files where the action is mechanical.
   Anything needing composition (an issue body, a question, a proposal) or a human surface
   (Slack) comes back in `needs_agent`, and what the agent then did is recorded under the
   distinct log key `<step>-filed` — a different fact from what the probe found, and one the
   log's per-(tick, step) idempotence keeps from overwriting it.

The five collisions the ask makes with standing decisions are carried into the skill rather
than resolved here — each is named in `SKILL.md`'s last section and ruled on in the ticket
that owns the step.

### Discovered Insights

- **Insight**: `DEFAULT_TARGETS` in `build.mjs` is an explicit list, and `propose` is not in
  it either — routine-facing skills that depend on connectors and Slack stay Claude-only,
  while the portable bundle carries the workflow skills.
  **Context**: `housekeep` follows `propose`'s precedent rather than being an oversight; a
  future decision to export it would need the connector-shaped steps to degrade cleanly on
  an agent that has none, which is a different piece of work from writing the steps.

- **Insight**: The failure mode an hourly unattended tick actually dies of is a step going
  *quiet*, not a step going wrong — so `run.sh` treats "missing script", "non-zero exit",
  "printed nothing" and "status outside the log vocabulary" as four separately-named
  degradations and still emits the row.
  **Context**: This is why the step list is in the script rather than in prose. Prose that
  says "run the nine steps" cannot notice that only eight ran; a fixed list that emits a row
  per entry can, and the tests pin exactly those four silences.

- **Insight**: A step that ran out of the tick's `--deadline-seconds` budget is logged
  `skipped` with reason `budget`, by name.
  **Context**: The ticket's Consideration asked for this explicitly, and it is the same
  distinction as `not_implemented` versus "found nothing": an hourly report that omits what
  it never reached reads as coverage it does not have.
