---
created_at: 2026-08-14T10:38:11+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-apply-the-standards-not-report-them
merge_policy:
verification_handoff: 
---

# Configure routines instead of rendering sheets

## Overview

PROPOSED. The routines half of the ask, and the one place where `/workaholify`
has actually fallen behind a sibling command rather than never having caught up.

`/setup-routines` was changed to **configure** the routines every time through a
`RemoteTrigger`-family tool, with `no_transport` as its one named refusal and the
copy-paste setup sheets as that refusal's recovery path — the defect report was
precisely that a session describing its success as luck tells the developer the
command's purpose is contingent (issue #408, FB `20260812204800`). But
`commands/workaholify.md` still says "render the routine setup sheets and probe
the channel (§5, `render-setup-sheet.sh --all <repo-url>`)". So the preparation
command still hands over a sheet where the dedicated command applies.

Feedback `20260813205116` records the same gap. This ticket makes §5 delegate to
the configuration `/setup-routines` performs, with the sheets kept exactly where
they belong: the recovery path for a named refusal.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/workaholify.md` — §5's "render the routine setup
  sheets" is the sentence this ticket replaces.
- `plugins/workaholic/skills/workaholify/SKILL.md` §5 and the
  *Configuring the routines is the job; `no_transport` is its one refusal*
  section — the contract already written, not yet reached from §5.
- `plugins/workaholic/skills/setup-routines/` — the configuring behavior to
  delegate to; do not reimplement it here (one behaviour per job).
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — kept,
  demoted to the refusal's recovery path.
- `plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh` — the
  channel probe; `checked: false` is never "does not exist".
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `implement.md` — the
  templates a configuration run converges each routine against.
- `plugins/workaholic/skills/workaholify/reference/routines.md` — session-class
  scoping; the transport is present for some session classes and not others.
- `scripts/test-workflow-scripts.mjs`, `CLAUDE.md`.

## Implementation Steps

1. **Reproduce and localize first.** Run `/workaholify`'s §5 as written and
   record what it produces today — sheets plus a channel probe — and compare it
   against what `/setup-routines` produces in the same session. Confirm the two
   commands genuinely diverge before changing either.
2. Read the SKILL's *Configuring the routines is the job* section before editing:
   one job, one named failure mode, never framed as luck, and the account-
   management surface stays retired. §5 must adopt that contract verbatim rather
   than growing a second, softer version of it.
3. Make §5 **delegate** to the configuration `/setup-routines` performs — list
   the account's routines, diff each against its template, apply create/update to
   converge, report per-routine changes. Do not duplicate the logic; a second
   implementation is a second thing to keep in sync with the templates.
4. Keep `no_transport: RemoteTrigger-family tool` as the single named refusal,
   and render the sheets **as that refusal's recovery path** — with the
   preconditions and what could not be verified, exactly as `/setup-routines`
   reports them.
5. Keep the channel probe where it is and keep its honesty: `checked: false` is
   reported as unverified, never as "the channel does not exist".
6. Update `commands/workaholify.md` §5 and the SKILL section so the described
   flow matches the performed one.
7. Add hermetic coverage in `scripts/test-workflow-scripts.mjs` for the delegation
   and for the refusal path rendering sheets; keep whatever pins the routine
   templates against drift passing.
8. Update the `/workaholify` row in `CLAUDE.md` in the same commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `/workaholify` §5 attempts the routine configuration itself, reporting
  per-routine changes, and does not render sheets on the ordinary path.
- With no reachable transport it reports `no_transport: RemoteTrigger-family
  tool` and renders the sheets as that refusal's recovery path.
- The configuration logic lives in one place; §5 delegates rather than duplicates.
- `commands/workaholify.md` and the SKILL describe what the command does.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (delegation and refusal-path cases,
  routine-template pins still green).
- Replay of step 1's side-by-side comparison after the change.

**Gate** — what must pass before approval:

- Smoke suite green; command file, SKILL §5 and the `CLAUDE.md` row updated in
  the same commit as the behavior.

## Considerations

- **The transport is session-class dependent** and that is not a defect to code
  around: no `RemoteTrigger`-family tool is exposed to the unattended,
  routine-fired class at all, while an interactive session can carry one
  (`reference/routines.md`). §5 must report the refusal by name in the classes
  that cannot reach it, never retry into a different mechanism —
  `CronCreate`/`CronList` are a session-only, unrelated surface.
- **Do not reintroduce the retired account-management surface** (digest gate,
  drift/fleet reports) through this door.
- Changing a template makes every live routine drift by construction, and the
  fleet is refreshed one routine at a time, confirmed verbatim. This ticket
  changes no template; if the driving session finds it must, that is a separate
  change, not a step here.
- The commit-versus-stage ruling in the sibling ticket's `## Open Decisions`
  governs this step too — configuring routines is an account-side write, not a
  repository one, so record how the two are reported together.
