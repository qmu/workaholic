---
created_at: 2026-08-19T05:26:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: rename-the-routine-pair-and-add-a-per-user-updater
merge_policy:
verification_handoff: 
---

# Add the per-user Workaholic updater routine

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #526 asks for a fourth routine, `[Workaholic]`, with a scope no template has
today: **one instance per user**, not one per user per repository. It runs hourly,
checks this repository for changes to the routine definitions, and converges that
user's workaholic routines across all their repositories to the new versions.

**What already exists and must be reused**: `list-routine-templates.sh` reads a
template's own `scope:` and reports an unknown one as empty rather than folding it
into a bucket, `render-setup-sheet.sh` takes the scope as an argument, and
`/setup-dev-routines` / `/setup-repo-routines` differ only in which scope they
converge. Adding a `user` scope is therefore a template field plus a caller, not a
new mechanism.

**What is genuinely unproven is the transport.** Both setup commands already
report `no_transport: RemoteTrigger-family tool` as a named refusal in sessions
that carry none — the session-only `CronCreate` family cannot touch an account
routine. If a routine's own container is in that class, `[Workaholic]` cannot do
the converging half of its job at all, and the honest shape is a routine that
**reports the drift by name** rather than one that silently does nothing. Find out
before designing around either answer.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — an unattended routine that cannot perform an act must report the refusal by name

## Key Files

- `plugins/workaholic/skills/workaholify/routines/` — the new template lives here;
  every existing one is the format reference.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` — the
  scope filter; a third value must be documented in its header, which is the one
  place the scope vocabulary is written down.
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — renders
  a sheet per scope, including the "how many of these should exist" header.
- `plugins/workaholic/commands/setup-dev-routines.md`,
  `plugins/workaholic/commands/setup-repo-routines.md` — the two existing callers,
  and the precedent for whichever way the third is reached.
- `plugins/workaholic/skills/workaholify/SKILL.md` — the scope vocabulary and the
  `no_transport` refusal's wording.
- `CLAUDE.md` — the Routines table gains a row and the scope paragraph a third
  value.

## Implementation Steps

1. **Establish the transport first, and record what you measured.** From a session
   of the same class the routine will run in, determine whether any available tool
   can list and update an *account* routine. Report the answer in the Final Report
   whichever way it goes — the rest of this ticket's shape depends on it.
2. Add `scope: user` to the vocabulary in `list-routine-templates.sh`'s header and
   in `workaholify/SKILL.md`, keeping the existing rule that an unknown scope is
   reported empty rather than defaulted.
3. Write `routines/workaholic.md`: hourly cron on a free non-zero minute (`:15`,
   `:30`, `:45`, `:50` and `0 0` are taken or rewritten by server jitter), the
   command it runs, its authorized post formats — if any; a routine that posts
   nothing is the quieter default and this one has no feedback item to thread into
   — and the environment it needs.
4. Decide and implement how the sheet and the configuration are reached (Open
   Decision 1), and make the sheet's header state the count: **one for the account,
   regardless of how many repositories are set up.**
5. Make the degradation honest: when the transport cannot converge, the run reports
   what drifted, by routine name and repository, and says it did not apply it —
   never a silent success and never a claim it converged.
6. Update `CLAUDE.md` and the workaholify skill in the same commit; regenerate
   `outputs/` with `build.mjs` and run `verify.mjs` and
   `node scripts/test-workflow-scripts.mjs`.

## Open Decisions

1. **Which command configures a `user`-scoped routine?** A third command
   (`/setup-user-routines`) matches the existing one-command-per-scope shape; a
   widened `/setup-dev-routines` avoids a third setup step but gives one command
   two jobs, which `CLAUDE.md`'s *One behaviour per command* rule pushes against.
   Not resolvable from the ask, which names `/workaholify` and
   `/setup-dev-routines` without distinguishing them.
2. **How does the routine enumerate "all of that user's repos"?** Nothing in the
   loop holds that list today. Options the ask does not choose between: the
   account's own routines (each names its repository), the user's GitHub
   repositories, or an explicit list the operator maintains. Repository
   confinement is untouched either way — configuring a routine is an API act, not
   a write into another checkout — but the enumeration source decides what the
   routine can honestly claim to cover.
3. **What counts as "an update to the routine definitions"?** A plugin version
   bump, a change under `skills/workaholify/routines/`, or a rendered-prompt diff
   per routine. The last is the only one that detects a template edit that did not
   bump a version, and it is also the only one that needs the transport to read
   the live routine.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `user`-scoped template exists, is listed by
  `list-routine-templates.sh user`, and is absent from both the `developer` and
  `repository` listings.
- The rendered `user` sheet states that exactly one exists per account, regardless
  of repository count.
- A run with no reachable transport reports the drift and the named refusal, and
  claims no convergence it did not perform.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh user`
  and the same for `developer` / `repository`.
- `bash plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh --all <repo-url> user`
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- Step 1's transport measurement is in the Final Report.
- All three Open Decisions resolved explicitly.

## Considerations

- **`verification_handoff` is deliberately left empty**, though the converging half
  can only be observed on a real account's routine list. The proposer may declare
  that field only when the ask itself states the constraint, and this ask does not
  — a run declaring it for its own unit is what turns `handoff` into a soft
  landing. If step 1's measurement establishes the constraint, the driving session
  says so in its Final Report and the operator decides.
- A routine that updates other routines can take the whole fleet down in one tick.
  Whatever step 5 lands on, the failure mode worth designing for is a bad
  definition propagating everywhere at once, not a missed update.
- The name collides with the plugin, the repository and the marketplace entry.
  Everything in the loop already reads `workaholic` as one of those three; a
  routine with the same name is one more meaning to disambiguate in every grep.
