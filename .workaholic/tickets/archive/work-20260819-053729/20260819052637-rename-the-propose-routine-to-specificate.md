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

# Rename the Propose routine to Specificate

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #526, first half of the swap: the routine today named `[Propose] {repo_name}`
becomes `[Specificate] {repo_name}`. Behaviour and logic do not move — the template
still points at `/propose`, keeps its `15 * * * *` cron, its two authorized post
formats and its `autofix_on_pr_create: true`. **This ticket lands first**, because
the second half reuses the name `Propose` for a different routine and cannot take
it while this one still holds it.

**The rename owes the operator one manual act, and the mechanism for that already
exists.** Convergence matches an account's routines by rendered `name`, so a
template whose `name:` moved creates a *second* routine beside the old one, and no
other account can delete it (`workaholic:workaholify`, *A renamed template is the
one convergence that cannot finish itself*). `[Prepare Release]` carries exactly
this migration today; copy it rather than inventing a second mechanism.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a routine record is operator-facing configuration; a rename is a migration

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — the template; its
  `name:` is the one line that must move, plus a `renamed_from:` recording the old
  name.
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — already
  renders `renamed_from:` as the sheet's first note; verify, do not re-implement.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` — reads
  `name_pattern` and `scope` from the template; nothing here should need editing.
- `plugins/workaholic/commands/setup-dev-routines.md` and
  `plugins/workaholic/skills/workaholify/SKILL.md` — the report must state the
  cutover by name.
- `plugins/workaholic/skills/notify/reference/notifications.md` — names `[Propose]`
  as the poster of the `🔵 Proposed` finish line and the description root.
- `CLAUDE.md` — the Routines table row and every prose mention of `[Propose]` as a
  routine (distinct from the `/propose` command, which this ticket does not move).
- `scripts/e2e/loop-drill.sh`, `docs/loop-drill-runbook.md` — the drill names the
  routine it verifies.
- `scripts/test-workflow-scripts.mjs` — pins the template prompts against
  `notify/reference/notifications.md`; run it after the edit.

## Implementation Steps

1. Enumerate the references first: `grep -rn "\[Propose\]" plugins/ docs/ scripts/ CLAUDE.md`.
   Separate routine-name mentions from `/propose` command mentions — only the
   former moves in this ticket, and the ask's own note warns that "Propose" means
   two different things across these two tickets.
2. Move `name:` in `routines/fb.md` to `"[Specificate] {repo_name}"` and add
   `renamed_from: "[Propose] {repo_name}"`. Leave `id`, `scope`, `cron_expression`,
   `model`, `allowed_tools`, `mcp` and the whole `## Prompt` body untouched.
3. Update the template's own prose and `workaholify/SKILL.md` so the migration
   reads as one instruction, not two half-descriptions.
4. Update `CLAUDE.md`'s Routines table and the prose around it in the same commit;
   state the cutover act (rename in the web UI, do not create a second) exactly as
   the `[Prepare Release]` migration states it.
5. Verify the sheet renders the note: `bash plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh --all <repo-url> developer`.
6. `node scripts/test-workflow-scripts.mjs`, then `node scripts/build-plugins/build.mjs`
   and `verify.mjs` to regenerate `outputs/`.

## Open Decisions

<!-- Recorded verbatim rather than resolved: /propose cannot ask the developer. -->

1. **Does the command rename too?** The ask says the name changes and behaviour
   does not, which leaves `[Specificate]` running `/propose`. That is exactly what
   was asked and it will read as a defect to the next person who greps for either
   word. Fork: (a) routine name only, as written; (b) rename the command and skill
   with it, which is a much larger change the ask did not request.
2. **Does the scope move?** The ask calls the three routines "per-repo"; this one
   is `scope: developer` today, by a measured decision (issue #451) and because
   `/propose` acts only on issues assigned to the running identity. One copy for
   the repository would route every developer's assigned issues through whichever
   account created it. Confirm whether "per-repo" means the `repository` scope or
   just "named per repository", which the template already is.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `routines/fb.md` renders as `[Specificate] <repo>` and declares
  `renamed_from: "[Propose] {repo_name}"`.
- `/setup-dev-routines`' report and the rendered setup sheet both state the manual
  rename, in the `[Prepare Release]` migration's own words.
- No document still calls the `/propose` routine `[Propose]`, and no `/propose`
  *command* mention was renamed by mistake.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh developer`
- `bash plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh --all <repo-url> developer`
- `grep -rn "\[Propose\]" plugins/ docs/ scripts/ CLAUDE.md` returns only what
  ticket 2 will claim.
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- Both Open Decisions resolved explicitly in the Final Report.
- This ticket merged before `rename-the-housekeep-routine-to-propose` starts.

## Considerations

- `renamed_from:` describes a migration, not a routine: it is deleted from the
  template once the fleet has cut over. Do not leave two of them accumulating.
- The template's `id` (`fb`) is already out of step with its name and stays that
  way here; changing it would move every `list-routine-templates.sh` consumer for
  no behaviour.

## Final Report

Development completed as planned. `routines/fb.md` renders as `[Specificate] <repo>` and
declares `renamed_from: "[Propose] {repo_name}"`; `id`, `scope`, `cron_expression`, `model`,
`allowed_tools`, `mcp` and the whole `## Prompt` body are byte-identical to before. Every
routine-name mention of `[Propose]` across `plugins/`, `docs/`, `scripts/`, `CLAUDE.md` and
`README.md` moved to `[Specificate]` (31 files); no `/propose` *command* mention moved, and
the retired `[Propose Batch]` design keeps its name because it is a different routine.

### Open Decisions — resolved

1. **Does the command rename too? — No (fork (a): routine name only).** The ask states the
   name changes and behaviour does not, twice and explicitly. Renaming `/propose` would move
   the command, the skill namespace, every `workaholic:propose` reference, the ticket-spine
   prose and the drill's stage names — a change an order of magnitude larger than what was
   asked. It would also collide mid-migration: the second half of the swap gives the *tick*
   the name `Propose`, so renaming the command at the same time would leave `/propose`
   ambiguous between the two halves for the length of the change. The stated cost stands and
   is recorded rather than glossed: `[Specificate]` runs `/propose`, which reads as a defect
   to someone greping for either word, so `CLAUDE.md` says in as many words that the routine
   and the command carry different names on purpose.
2. **Does the scope move? — No, it stays `developer`.** "Per-repo" in the ask is read as
   *named per repository*, which the template already is (`{repo_name}` in `name:`). The
   substantive reading is refused on measured grounds: `/propose` acts only on issues
   assigned to the running identity (`not_mine` at its input), so one repository-wide copy
   would route every developer's assigned issues through whichever account created it. That
   is the 2026-08-14 decision (issue #451) and nothing in this ask reopens it — the ask's own
   sentence is "behavior and logic stay as-is, only the name changes", and the scope is
   behaviour.

### Discovered Insights

- **Insight**: `renamed_from:` was written for a *single* rename and needs one more thing
  when the rename is half of a swap — the **order**. The sheet's derived note says "rename,
  do not create a second", which is sufficient when the freed name goes nowhere; here the
  freed name is claimed by another template, so an account converging in the wrong order ends
  up with two routines carrying one rendered name and convergence cannot tell them apart.
  **Context**: the ordering is now stated in both setup commands and pinned by a test that
  fires only while a `renamed_from:` value collides with some live template's `name:` — so it
  asserts nothing once the swap's fields are deleted, which is the intended end state.
- **Insight**: `sed` over the literal `[Propose]` reaches prose but not a JavaScript regex
  literal, where the same token is written `\[Propose\]`.
  **Context**: `test-workflow-scripts.mjs` pins several skill sentences by regex; a rename
  sweep that only greps the plain token leaves those pins matching a string the sweep already
  moved, and the suite fails on the *assertion text* rather than on the behaviour. Grep for
  the escaped form too when renaming any bracketed identifier.
