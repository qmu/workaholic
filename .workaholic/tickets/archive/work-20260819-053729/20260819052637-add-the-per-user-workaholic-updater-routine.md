---
created_at: 2026-08-19T05:26:37+00:00
status: done
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

## Final Report

Development completed as planned. A `user`-scoped template (`routines/workaholic.md`), a third
setup command (`/setup-user-routines`), the scope vocabulary in `list-routine-templates.sh` and
`render-setup-sheet.sh`, one authorized post shape mirrored byte-identically in
`notify/reference/notifications.md`, and the documentation in `workaholify/SKILL.md`,
`CLAUDE.md` and `README.md`. Both other scopes are byte-unchanged in what they list and render.

### Step 1 — the transport, measured

**Measured from this container, which is a routine-fired `[Implement]` session — the same
session class `[Workaholic]` would run in** (2026-08-19):

- `ToolSearch` over the full tool surface for a `RemoteTrigger`-family tool (list/get/create/
  update/run over **account** routines): **nothing**. Two queries, one by capability
  (`RemoteTrigger routine account schedule list update`) and one name-anchored
  (`+trigger remote create routine`); the matches returned were `TaskUpdate`,
  `CronList`, `ListConnectors`, `ListPlugins`, `ListSkills`, `TaskList`, GitHub Actions tools
  and `Monitor` — nothing that reaches a claude.ai account routine.
- `CronCreate` / `CronList` / `CronDelete` are present, and are the **session-only, in-memory**
  scheduler this repository has documented as unrelated to account routines since 2026-08-10.
- The `claude` CLI is on PATH and exposes **no** routine/trigger/schedule/cron subcommand.

So in the routine-fired class this routine **cannot converge anything**, which is the answer
the ticket said the rest of its shape depends on. That answer did not make the routine
pointless — an interactive session may carry the tool (FB `20260810214929`), and both existing
setup commands are built on exactly that "attempt every time, name the refusal when it fails"
shape — but it did decide two things: the honest degradation is a **named refusal that says it
converged nothing**, not silence, and the routine gets **one** authorized post so a permanently
refused routine says so once instead of firing on time and reading as healthy every hour.

**On `verification_handoff:`** — the ticket's Considerations asked the driving session to say so
if step 1 established the constraint. It did, partially, and this is stated for the operator to
rule on rather than acted on: the **converging** half can only be observed against a real
account's routine list, which no session of this class can reach. Everything this ticket
actually ships — the template, the scope, the command, the sheet, the refusal path — is fully
verifiable here and was verified. This run does **not** declare `verification_handoff:` for its
own unit; a run declaring it for itself is what turns `handoff` into a soft landing, and the
declaration belongs on the artifact at creation.

### Open Decisions — resolved

1. **Which command configures a `user`-scoped routine? — A third command,
   `/setup-user-routines`.** The existing shape is one command per scope, with the scope read
   from the template by both commands and every sheet; a third scope with no command of its own
   would be unreachable. Widening `/setup-dev-routines` was rejected on two grounds beyond
   *One behaviour per command*: the counting questions genuinely differ (`developer` multiplies
   by developers **and** by repositories, `user` by neither), and a widened command run in a
   second repository would re-converge an account-wide routine the first repository's run
   already created — idempotent, but it makes the report unable to answer the one question the
   scope field exists to answer. The cost is one more setup step, paid **once per account**
   rather than once per repository, and the sheet's own header states that before a reader
   repeats it.
2. **How does the routine enumerate "all of that user's repos"? — The account's own routine
   list.** Each routine names the repository it runs against, so the set of routines *is* the
   domain to converge, and it needs precisely the transport the converging half already needs —
   a session missing it is missing both halves together and reports **one** refusal. The two
   alternatives were rejected with their reasons recorded: a GitHub repository listing
   enumerates repositories that have no routine at all and cannot say which of them should have
   one, and an operator-maintained list is a second source of truth that drifts silently — the
   failure `list-routine-templates.sh`'s own header already argues against. The limit this
   accepts is stated rather than glossed: **a repository the account never created a routine on
   is invisible**, and the run reports that instead of implying coverage.
3. **What counts as "an update to the routine definitions"? — The rendered diff per routine**
   (name / prompt / model / `cron_expression` / `autofix_on_pr_create` / connectors), with a
   plugin version bump usable as a cheap pre-filter that never gates. It is the only one of the
   three that catches a template edit which did not bump a version, and this repository ships
   those routinely — both halves of the rename in this same mission did. It is also not a new
   mechanism: it is exactly the diff `/setup-dev-routines` step 2 already computes, so the
   updater runs the existing comparison over more records rather than inventing a second notion
   of drift. It needs the transport to read the live routine, which is the same requirement
   everything else here has, so it costs nothing extra.

### Discovered Insights

- **Insight**: the fleet-safety concern ("a routine that updates other routines can take the
  whole fleet down in one tick") has a cheap structural answer that costs no mechanism: the
  updater **excludes its own record** from what it converges.
  **Context**: without it, a bad definition propagates to the updater too and there is no tick
  left that can repair the rest — the failure mode is unrecoverable rather than merely wide.
  With it, whatever happens to the fleet, the one routine that can fix it is untouched, and its
  own definition moves only when a person runs the command. The same reasoning is why
  `/setup-repo-routines` is never run by a tick.
- **Insight**: a routine whose entire job may be permanently unreachable is the one case where
  "posts nothing when idle" is the wrong default.
  **Context**: every other tick in this catalog is silent when idle, and that is right because
  idle means *nothing to do*. Here idle and *cannot do anything* are indistinguishable from
  outside, which is the "firing on time, doing nothing, and reading as healthy" failure
  `workaholic:workaholify` §4 names about the web bootstrap. One keyed root (`fleet:<digest>`)
  says the refusal once and stays silent thereafter, which is `[Prepare Release]`'s own
  precedent applied to a state rather than to a count.
- **Insight**: the name collides with the plugin, the repository and the marketplace entry, as
  the ticket warned, and the collision is now four-way.
  **Context**: it was kept because the ask names the routine `[Workaholic]` explicitly and a
  routine name is operator-facing text an implementer should not quietly redesign. The cost is
  real and lands on `grep`: `workaholic.md` under `routines/` is the routine, `plugins/
  workaholic/` is the plugin, `qmu/workaholic` is the repository. Anything searching for the
  routine should search the bracketed form `[Workaholic]`, which is unambiguous.
