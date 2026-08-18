---
created_at: 2026-08-17T11:33:23+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260817113249-rename-release-status-to-fullfill-for-the-one-word-command-naming-convention.md]
merge_policy:
verification_handoff: 
claim: work-20260817-180716
---

# Rename /release-status to /fullfill

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from
     a proposal into queued work. -->

The project is standardising on one-word slash-command names, and `/release-status` is
two hyphenated words. Rename the command to `/fullfill`, updating every reference —
command registration, prompts, docs, and internal invocations. **Behaviour does not
change**: `/fullfill` stays the pure reader `workaholic:ship` §7 defines, writing no file
and posting only the gated status line.

The rename's reach is measured: 42 references across 13 hand-maintained files, plus the
generated `outputs/` bundle (rebuilt, never hand-edited). Two of those references are not
prose — the routine record's **name** and the notify **dedup token** — and both are called
out under Open Decisions rather than swept along with the rest.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the status post is an operational signal; a renamed dedup key changes what a reader can find

## Key Files

- `plugins/workaholic/commands/release-status.md` — the command file itself; renamed to
  `fullfill.md`, with its `name:` frontmatter and `# Release Status` heading.
- `plugins/workaholic/skills/workaholify/routines/release-status.md` — the routine
  template. Its `## Prompt` invokes `/release-status` and names the fallback path
  `<src>/commands/release-status.md`; both must follow the rename. Its `id:` and `name:`
  are an Open Decision below.
- `plugins/workaholic/skills/workaholify/reference/routines.md` — the routine table.
- `plugins/workaholic/skills/ship/SKILL.md` — §7 *Release status*, the section the command
  runs; 2 references.
- `plugins/workaholic/skills/notify/SKILL.md` and
  `plugins/workaholic/skills/notify/reference/notifications.md` — the sanctioned post shape
  for this event. `notifications.md`'s copy is pinned byte-identical to the routine
  template's by `scripts/test-workflow-scripts.mjs`, so the two move together or the test
  fails.
- `CLAUDE.md` (7 references: the commands table row, the routines table, the `commands/`
  listing) and `README.md` (3).
- `docs/loop-drill-runbook.md` (4), `docs/drive-loop-runbook.md`, `docs/proposal-loop-runbook.md`.
- `scripts/e2e/loop-drill.sh` — the `verify-status` drill (2 references).
- `scripts/test-workflow-scripts.mjs` — 11 references, including the template-drift pin and
  the routine-id assertions; these are assertions, so they must be updated, not deleted.
- `outputs/workflows/skills/ship/SKILL.md` — generated; regenerate with
  `node scripts/build-plugins/build.mjs`, never hand-edit.

## Implementation Steps

1. Resolve the two Open Decisions below before touching a file — the spelling and the
   routine record's name both change what gets written everywhere else.
2. `git mv plugins/workaholic/commands/release-status.md plugins/workaholic/commands/fullfill.md`
   and update its `name:` frontmatter, its `# ` heading, and its prose.
3. Update the routine template's `## Prompt` (the `/…` invocation and the
   `<src>/commands/….md` fallback path), applying the Open Decision's ruling to `id:` and
   `name:`.
4. Sweep the skill references: `ship/SKILL.md` §7, `notify/SKILL.md`,
   `notify/reference/notifications.md`, `workaholify/reference/routines.md`. Keep the
   notify copy and the template copy byte-identical.
5. Update the documentation in the same change (`CLAUDE.md` commands table and routines
   table, `README.md`, the three `docs/*-runbook.md`) — the repository treats stale docs as
   a defect, not a follow-up.
6. Update `scripts/e2e/loop-drill.sh` and the assertions in
   `scripts/test-workflow-scripts.mjs`.
7. Regenerate the bundle: `node scripts/build-plugins/build.mjs`, then
   `node scripts/build-plugins/verify.mjs`.
8. Grep for survivors (`release-status`, `release_status`, `Release Status`) and confirm
   every remaining hit is deliberate history (a dated decision record naming the old name
   is correct to leave).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/fullfill` is a registered command and `/release-status` no longer resolves.
- No `release-status` reference survives outside deliberate historical prose.
- The routine template's prompt invokes the new name and its fallback path points at the
  renamed command file.
- The command's behaviour is byte-unchanged: still a pure reader, still gated on
  `actionable` and on the digest search.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — clean, no diff.
- `node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs` — including the routine-template drift pin.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `grep -rn "release-status\|Release Status" --include=*.md --include=*.sh --include=*.mjs plugins/ CLAUDE.md README.md docs/ scripts/` — every hit accounted for.

**Gate** — what must pass before approval:

- The two Open Decisions are resolved and the resolution is recorded in the Final Report.
- `Outputs Freshness` and `Validate Plugins` CI are green.

## Open Decisions

<!-- Forks this session cannot recommend one side of. The driving session resolves each
     explicitly and records the resolution in its Final Report — never a silent guess. -->

1. **Spelling: `/fullfill` as given, or `/fulfill`?** The ask names `/fullfill` explicitly.
   The English word is *fulfill* (US) / *fulfil* (UK); `fullfill` doubles the first `l`.
   Following the ask literally and silently correcting the reporter's chosen command name
   are both defensible, and the rename is expensive to redo. Do not pick one silently.
2. **Does the routine record rename with the command?** The command is invoked by the
   `[Release Status]` routine template (`id: release-status`, `scope: repository`,
   `45 * * * *`), and `/setup-repo-routines` converges an account's routines **by name**.
   Renaming the template's `name:` therefore does not rename the operator's existing
   routine — the next convergence **creates a second one** — and a routine is an
   account-level record no other account can list or delete, so the old `[Release Status]`
   keeps firing until its owner removes it by hand. Either rename it and state the manual
   retirement step in the setup sheet, or keep the routine named `[Release Status]` and
   change only the command it invokes.

## Considerations

- **The `deploy:<digest>` token and the `📦 Release status` prefix are the notify lookup's
  exact-string dedup key.** If the prefix changes, the search for an earlier post stops
  matching and exactly one duplicate status line is posted at the cutover. Recommended:
  leave the post shape alone — it is the event's name, not the command's — and note the
  choice in the Final Report. Either way it is a one-time, self-healing cost.
- **The convention is not fully served by this rename.** `/setup-dev-routines`,
  `/setup-repo-routines` and `/mission-close` are also multi-word. The ask's scope note is
  explicit that only `/release-status` is in hand, so the others stay untouched; if the
  convention is meant to reach them, that is a separate ask.
- `/fullfill` reads less obviously than `/release-status` for a reader who does not already
  know the command. The description frontmatter carries the meaning and should stay
  explicit about what it reports.

## Final Report

Development completed as planned. `/release-status` is now `/fullfill`; the command file
moved (`git mv`, so the history follows), its `name:` frontmatter and heading changed, and
every command-level reference followed — the routine template's prompt and its
`<src>/commands/…` fallback path, `ship/SKILL.md` §7, `notify/SKILL.md` and its shape
catalog, `CLAUDE.md` (commands listing and table row), `README.md` (table row and the full
map's node label), `docs/loop-drill-runbook.md`, `scripts/e2e/loop-drill.sh`, and the two
`testReleaseStatusIsAReader` assertions. Behaviour is untouched: still the pure reader
`workaholic:ship` §7 defines, still gated on `actionable` and the digest search.

### The two Open Decisions, resolved

**1. Spelling — `/fullfill`, as the ask names it.** Both the feedback record and the
ticket title carry that string, so it is the operator's chosen identifier rather than a
slip this session observed; a run that silently "corrected" an operator's explicit command
name would be overriding an instruction, which is the more expensive mistake of the two.
It is recorded as a story concern with the exact one-line fix, so ruling the other way
costs a second rename and nothing else. It is deliberately **not** a silent pick.

**2. The routine record keeps its name — only the command moved.**
`/setup-repo-routines` converges an account's routines *by name*, so renaming the
template's `name:` would not rename the operator's existing routine: the next convergence
would create a second one, and a routine is an account-level record no other account can
list or delete, so `[Release Status]` would keep firing hourly beside it until its owner
removed it by hand. A rename whose only effect is a duplicate nobody else can clean up is
not a rename. `id: release-status`, the template filename, and the CLAUDE.md routines-table
row therefore stand. The reasoning is written into the template itself, not only here.

**The `📦 Release status` prefix and the `deploy:<digest>` token are untouched**, per the
ticket's own recommendation: they name the *event*, not the command, and the prefix is the
notify lookup's exact-string dedup key — changing it would post exactly one duplicate line
at the cutover for no gain.

### Discovered Insights

- **Insight**: the rename splits cleanly along one line — a **command** reference renames,
  an **event** or **record** reference does not. Every one of the eight surviving
  `release-status` hits is a template id, a template filename, or a test name derived from
  one, and every one of them is correct to leave.
  **Context**: the same split will decide the other multi-word commands
  (`/setup-dev-routines`, `/setup-repo-routines`, `/mission-close`) if the convention is
  extended, which the ask explicitly scoped out.
