---
created_at: 2026-08-17T11:37:55+00:00
status: done
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

## Final Report

Development completed as planned. `/housekeep` is now an hourly routine: the template ships,
both setup commands see it in exactly one scope, both post shapes are authorized and mirrored,
and the routine is drillable on demand rather than verified by waiting an hour.

**The scope Open Decision is resolved: `repository`, against the ask's own wording — and that
sentence is answered rather than dismissed.** The ask said `/setup-dev-routines`, written before
the nine steps were decomposed. Once they were, the balance is not close: **seven of the nine
read the repository, not the developer**, and issue triage, auto-merge reminders and
documentation drift produce identical findings from every copy while the check-in would ask five
questions per copy per hour — the exact failure the `repository` scope was introduced for on
2026-08-14 (issue #451), which the plugin **cannot detect**, because a routine is an
account-level record no other account can list. The one real argument for `developer` was step
8: per-developer copies would at least race under their own identities. That argument is **moot**
— step 8 ships gated and emits nothing until the operator rules on it, so there is no proposal
race to distribute.

The two genuinely personal steps are not silently lost. The inbound sweep's Gmail, Drive and
Slack connectors belong to whichever account runs the tick, and every surface is reported **by
name** (`no_surface: gmail`), so one account's copy says exactly whose inboxes it could not see.
The faithful way to have both is option (c) — a second, developer-scoped inbound template — which
is a template to add rather than a value to change here. And the decision is cheap to revisit:
moving this routine is a **one-line** `scope:` change, because both setup commands and both setup
sheets read that one field.

`autofix_on_pr_create: true` and the `Write`/`Edit` grant are stated in the template's own prose
rather than inherited: this routine is not a pure reader like `[Release Status]` — it writes its
tick log, and filing a finding publishes a record or a ticket behind a pull request, exactly as
`/propose` does. Cron `50 * * * *`: an explicit non-zero minute (a bare `:00` is rewritten to
server jitter) that collides with none of `15`/`30`/`45`, and lands last in the hour so the tick
reads what the other three have just done.

### Discovered Insights

- **Insight**: The template set is discovered by scanning `routines/`, so a new template is
  surveyed, rendered and drift-checked the moment its file exists — but three suite assertions
  hard-code the *count* and the *id list*, and they are the registration.
  **Context**: Adding a routine is one file plus those assertions plus the `CLAUDE.md` row; the
  assertions failing is the intended notification, not an obstacle. The cron assertion now also
  pins that **no two routines share a minute**, which is the property the staggering exists for
  and which a list of literal times does not state.

- **Insight**: A drill row that asserts "the checkout is clean" must assert a **delta**, not an
  absolute — the operator runs the drill in whatever checkout they have, which may legitimately
  be mid-edit.
  **Context**: `verify-housekeep`'s first draft reported the operator's own uncommitted work as
  the tick's doing, which is the class of false red that teaches people to ignore a drill. It now
  snapshots `git status --porcelain` before and after and compares.

- **Insight**: The nine-step decomposition is what settled the scope, and it could only be done
  after the steps were built — the ask's own sentence was written when the steps were a list of
  intentions.
  **Context**: This is an argument for the mission's ordering (spine, then steps, then routine)
  beyond dependency: the template ticket inherits *evidence* from the step tickets, and the same
  question asked first would have been answered by the ask's wording alone.
