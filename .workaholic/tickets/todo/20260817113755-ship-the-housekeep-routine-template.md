---
created_at: 2026-08-17T11:37:55+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817113750-add-the-housekeep-command-and-skill.md
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Ship the Housekeep routine template

## Overview

The last step: make `/housekeep` an actual hourly routine. A Claude Code Web routine comes
from a template under `skills/workaholify/routines/`, and the template declares its own
`scope:` — the field that decides how many copies the team should end up with and which
setup command configures it. The ask says `/setup-dev-routines`, which means
`scope: developer`; the Open Decision below is whether that survives contact with steps 5,
6 and 7.

The template is a **thin pointer**: the prompt carries only the command, the post formats
it authorizes, and the environment. Every rule stays in the skill that owns it. A post shape
not named in the prompt may not be emitted, however well documented it is elsewhere.

## Policies

- `workaholic:operation` / `policies/delivery.md` — a routine is a standing process, not a script run
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the setup command reports what it converged, by name

## Key Files

- `plugins/workaholic/skills/workaholify/routines/housekeep.md` — new. Model on `fb.md`
  (developer scope) or `release-status.md` (repository scope) per the Open Decision.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` and
  `render-setup-sheet.sh` — both filter on `scope:`; the template set is discovered by
  scanning the directory, so a new template needs no registration in either command's body.
- `plugins/workaholic/skills/workaholify/SKILL.md` §5, *Two scopes, two commands* — the
  scope contract and the plainly stated fact that the repository scope is a convention the
  plugin cannot enforce.
- `plugins/workaholic/skills/notify/reference/notifications.md` — any post shape the prompt
  names must be **byte-identical** to its copy here; `scripts/test-workflow-scripts.mjs`
  pins the two against drift.
- `CLAUDE.md` — the routines table (template / routine / scope / cron / configured by).
- `scripts/e2e/loop-drill.sh` — the operator's on-demand drill; a new routine earns a verb.

## Implementation Steps

1. Resolve the scope Open Decision — it selects the template's `scope:`, which selects the
   setup command, the setup sheet, and the paragraph in `CLAUDE.md`.
2. Write the template: `type: Routine Template`, `id: housekeep`, `name`, `scope`,
   `trigger: schedule-hourly`, `cron_expression`, `autofix_on_pr_create`, `model`,
   `allowed_tools`, `mcp: [Slack]`.
   - **Cron minute**: the API's minimum interval is one hour and a bare `:00` is rewritten
     to server jitter, so pick an explicit non-zero minute that does not collide with `15`
     (`[Propose]`), `30` (`[Implement]`) or `45` (`[Release Status]`).
   - **`autofix_on_pr_create`**: `true` only if the routine opens pull requests — step 8
     does, if it survives its own Open Decision. Stored at
     `job_config.ccr.session_context.autofix_on_pr_create`.
   - **`allowed_tools`**: the smallest set the built steps need. `[Release Status]` carries
     no `Write`/`Edit` precisely because it writes nothing; `/housekeep` writes its log, so
     it needs them — state that in the template's prose so the grant is justified, not
     inherited.
3. Name **every** post shape the routine may emit, verbatim, and mirror each in
   `notify/reference/notifications.md`.
4. Update `CLAUDE.md`'s routines table and the `/setup-*-routines` command row; update
   `README.md`.
5. Add a `verify-housekeep` verb to `scripts/e2e/loop-drill.sh` and document it in
   `docs/loop-drill-runbook.md`, so the routine is drillable on demand rather than verified
   by waiting an hour.
6. Regenerate the bundle and run the full local verification set.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `list-routine-templates.sh <scope>` returns the new template for exactly one scope, and
  the other setup command never sees it.
- `render-setup-sheet.sh housekeep <repo-url>` renders a complete sheet with the prompt
  verbatim.
- Every post shape in the prompt is byte-identical to its `notifications.md` copy.
- The cron minute collides with no existing routine.
- `CLAUDE.md`'s routines table matches the template's frontmatter exactly.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — includes the template-drift pin.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- `sh scripts/e2e/loop-drill.sh verify-housekeep`

**Gate** — what must pass before approval:

- The scope Open Decision resolved and recorded in the Final Report; CI green.

## Open Decisions

1. **`developer` or `repository` scope?** The ask says "part of `/setup-dev-routines`",
   which is `developer` — one copy per developer. But four of the nine steps read the
   *repository*, not the developer: issue triage (5), auto-merge reminders (6) and
   documentation drift (7) produce the same findings from every copy, and step 8 would have
   N runners racing to propose the same direction. N copies firing hourly is the exact
   failure the `repository` scope was introduced for on 2026-08-14 (issue #451), and the
   plugin **cannot detect it** — a routine is an account-level record no other account can
   list. Three options: (a) `developer` as asked, accepting N× duplicate triage and posts;
   (b) `repository`, one copy for the team, contradicting the ask's own sentence; (c) split
   the nine steps into a developer-scoped routine and a repository-scoped one, which is the
   most faithful to both and the most work. This session cannot recommend one — the ask is
   explicit and the measured failure is real.

## Considerations

- Whichever scope wins, the setup command reports what it converged **by name**; it cannot
  detect a colleague's duplicate and must not claim to.
- If step 8 is dropped at its own Open Decision, `autofix_on_pr_create` should be `false`
  and the `[Housekeep]` routine becomes a near-reader — much cheaper to trust.
- The routine cannot subscribe to a repository event: the API's trigger surface is
  `cron_expression` / `run_once_at` / API token only. Everything reactive in the ask has to
  be discovered by the tick itself, as `[Propose]`'s clock-fired discovery already is.
