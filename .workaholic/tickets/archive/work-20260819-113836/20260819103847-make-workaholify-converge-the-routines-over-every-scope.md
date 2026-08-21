---
created_at: 2026-08-19T10:38:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-converge-the-account-s-routines
merge_policy:
verification_handoff: A RemoteTrigger-family tool over account routines — absent from the routine-fired session class, present interactively (the ask measured both)
---

# Make /workaholify converge the routines over every scope

## Overview

PROPOSED. `/workaholify` §5 renders setup sheets and stops. Every other subject
of the command converges — §3 (`apply-claude-md-reference.sh`), §3a
(`converge-layout.sh`), §4 (`apply-bootstrap.sh`) — so a run leaves a repository
prepared in three of four respects and merely *described* in the fourth. The
measured cost (2026-08-19, this repository, interactive session): the run
reported the routines as unanswerable and rendered sheets while 2 routines
existed against 6 templates, both disabled since 2026-08-12, both carrying
prompts from 2026-08-07 — with a `RemoteTrigger`-family tool exposed to that
very session.

This ticket gives §5 the same list/diff/apply flow the three setup commands
already run, over **every** scope (`/workaholify` is scope-agnostic by nature —
it prepares a repository, not one counting class), with
`no_transport: RemoteTrigger-family tool` as its one named refusal and the
sheets as that refusal's recovery path.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/workaholify.md` — the one line that makes §5 a
  renderer: "render the routine setup sheets and probe the channel (§5,
  `render-setup-sheet.sh --all <repo-url>` + `check-slack-channel.sh`)". No
  convergence attempt, no `no_transport` refusal.
- `plugins/workaholic/skills/workaholify/SKILL.md` — §5's *Configuring the
  routines is the job; `no_transport` is its one refusal* and *What the commands
  do with all this* name only the three setup commands; `/workaholify` is absent
  from both, which is why the command body could stay a renderer without
  contradicting the skill.
- `plugins/workaholic/commands/setup-{dev,repo,user}-routines.md` — the three
  bodies that already carry the flow; the reference shape to converge toward,
  and the place a scope-agnostic caller must not duplicate.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh`,
  `render-routine.sh`, `render-setup-sheet.sh` — all three already take an
  **optional** scope; an omitted scope is the all-scopes read `/workaholify`
  needs, so no script signature has to move.
- `CLAUDE.md` (`/workaholify` row), `README.md` — the contract tables that state
  "survey routines"; a converging §5 makes both wrong in the same commit.

## Implementation Steps

1. **Confirm the localization before changing anything.** Read
   `commands/workaholify.md` line 10 and `skills/workaholify/SKILL.md` §5's two
   flow sections, and record which of the two is the actual gap: the command
   body says "render", and the skill section the body defers to enumerates the
   three setup commands by name. Confirm `list-routine-templates.sh` with no
   argument returns all six templates across all three scopes (it is the
   all-scopes read this ticket depends on) — if it does not, that is a second
   defect and belongs in its own ticket rather than being fixed inline.
2. **Widen SKILL.md §5's convergence flow to name `/workaholify` as a fourth
   caller**, scope-agnostic: same four numbered steps (attempt the transport;
   converge one routine at a time; `no_transport` then the sheet; no
   `AskUserQuestion`), differing only in that it passes no scope filter. State
   *why* the scope is omitted rather than leaving it to be inferred — the three
   setup commands exist to answer "how many copies should exist", and
   `/workaholify` answers "is this repository prepared", which needs all of them.
3. **Rewrite `commands/workaholify.md`'s §5 clause** to attempt the
   configuration and report per routine what changed, with the sheets rendered
   only under the named refusal. Keep the *What may be applied unattended* rule
   intact: `/workaholify` is reachable only through a human's own invocation (no
   routine prompt names it), so this adds no unattended mutation class — say so
   in the body rather than adding a gate.
4. **Keep the `AskUserQuestion` count at two.** The command's own body states the
   two applies (§3, §4) are "the only questions this command asks"; converging a
   routine to the developer's already-declared template fails the
   Recommended-label test (`rules/interaction.md`), so §5 adds no third
   confirmation. Update the sentence only if the count actually changes.
5. **Report the overlap with the three setup commands honestly.** A repository
   whose developer runs `/workaholify` and then `/setup-dev-routines` converges
   the developer templates twice — idempotent, so harmless, but the report should
   not read as if the two commands cover disjoint sets.
6. **Update the documentation in the same change**: `CLAUDE.md`'s `/workaholify`
   row ("survey routines" → converges them, with the one refusal), `README.md`'s
   command roster, and `skills/workaholify/reference/routines.md` where it scopes
   the direct-apply path to the setup commands.
7. **Verify.** `node scripts/build-plugins/build.mjs`, `verify.mjs`,
   `validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`, and
   `bash plugins/workaholic/hooks/layout-doctor.sh .`. Then the part an
   unattended run cannot do — see Considerations.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `commands/workaholify.md` §5 instructs an attempt at convergence over every
  scope, and names `no_transport: RemoteTrigger-family tool` as the one refusal
  that falls back to the sheets.
- `skills/workaholify/SKILL.md` §5's convergence flow names `/workaholify` as a
  caller and states why it passes no scope filter.
- `CLAUDE.md` and `README.md` describe §5 as converging, not surveying.
- The command still asks exactly two `AskUserQuestion`s (§3 and §4).

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs
  && node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `bash plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh`
  with no argument returns all six templates.
- **Handoff (see frontmatter):** an interactive session carrying a
  `RemoteTrigger`-family tool runs `/workaholify` on this repository and confirms
  it lists, diffs and converges the account's routines, reporting each by name.

**Gate** — what must pass before approval:

- All four script checks above pass, and the documentation trio is updated in the
  same commit (this repository's own rule: outdated documentation is a defect).

## Considerations

- **This unit carries `verification_handoff:` and the ask is what states it.**
  The complaint being answered is precisely a report that said "prepared"
  without the convergence having happened. An unattended run can verify the
  prose, the scripts and the `no_transport` path; it cannot verify the
  convergence itself, because the routine-fired session class carries no
  `RemoteTrigger`-family tool (measured 2026-08-19, recorded in `CLAUDE.md`).
  Shipping this auto-merged with a self-declared "verified" would repeat the
  defect, so the unit hands off to a person with the transport.
- **Scope-agnostic is a choice, not an oversight.** `/workaholify` prepares a
  *repository*; the three setup commands answer *how many copies of a routine
  should exist*. Narrowing §5 to one scope would leave the same hole the ask
  measured. The cost is that a `/workaholify` run touches `user`-scoped records
  that are not repository-specific — state that in its report.
- **`/workaholify` must not become a fourth place the flow is written down.**
  Three command bodies already carry it; adding a fourth copy is the drift this
  repository refuses elsewhere. The flow belongs in SKILL.md §5, with all four
  commands deferring to it.
- **Ticket 3 of this mission may narrow step 2's wording.** If convergence can
  rename in place, the `renamed_from:` cutover note this flow renders becomes a
  no-transport fallback rather than a standing obligation. Do not pre-empt that
  ruling here; write step 2 so it survives either answer.
