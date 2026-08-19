---
created_at: 2026-08-19T05:26:37+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260819052637-rename-the-propose-routine-to-specificate.md
mission: rename-the-routine-pair-and-add-a-per-user-updater
merge_policy:
verification_handoff: 
---

# Rename the Housekeep routine to Propose

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #526, second half of the swap: the routine today named `[Housekeep] {repo_name}`
becomes `[Propose] {repo_name}`. Behaviour and logic do not move — the template
still points at `/housekeep`, keeps its `50 * * * *` cron, its two authorized post
formats and its `repository` scope.

**This half is not symmetric with the first, and the difference is the whole
risk.** It takes a name that is *live* today: an account that has not yet renamed
its `[Propose] <repo>` routine to `[Specificate] <repo>` would end up with two
routines called `[Propose] <repo>` — one firing `/propose` at `:15` and one firing
`/housekeep` at `:50` — and convergence, which matches by rendered name, cannot
tell them apart. The ask itself flags the swap as the thing implementers will get
wrong. `depends_on` therefore names the first rename, and the cutover instruction
must say **rename the old one first**, not merely "rename, do not create a second".

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a routine record is operator-facing configuration; a rename is a migration

## Key Files

- `plugins/workaholic/skills/workaholify/routines/housekeep.md` — the template;
  `name:` moves and `renamed_from: "[Housekeep] {repo_name}"` is added.
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — renders
  the note; check that two templates carrying `renamed_from:` at once read
  correctly on one sheet.
- `plugins/workaholic/commands/setup-repo-routines.md`,
  `plugins/workaholic/skills/workaholify/SKILL.md` — the report names what it
  converged; here it must also name the ordering.
- `plugins/workaholic/skills/housekeep/SKILL.md`,
  `plugins/workaholic/skills/notify/reference/notifications.md` — both describe the
  tick by its routine name.
- `CLAUDE.md` — the Routines table and the `[Housekeep]` prose block.
- `scripts/e2e/loop-drill.sh`, `docs/loop-drill-runbook.md` — `verify-housekeep`
  and `verify-propose` name routines that are about to swap.
- `scripts/test-workflow-scripts.mjs` — the prompt pin.

## Implementation Steps

1. Confirm the first rename has merged (`grep -n "^name:" plugins/workaholic/skills/workaholify/routines/fb.md`
   reads `[Specificate] …`). If it has not, stop: this ticket cannot land safely
   first, and that is what `depends_on` records.
2. `grep -rn "\[Housekeep\]" plugins/ docs/ scripts/ CLAUDE.md` and separate
   routine-name mentions from `/housekeep` command mentions.
3. Move `name:` in `routines/housekeep.md` to `"[Propose] {repo_name}"` and add
   `renamed_from: "[Housekeep] {repo_name}"`. Leave `id`, `scope`,
   `cron_expression`, `allowed_tools`, `mcp` and the `## Prompt` body untouched.
4. Make the cutover instruction ordered: the sheet and the report must say to
   rename the old `[Propose]` **before** this one, so the account never holds two
   routines with the same rendered name.
5. Update `CLAUDE.md`, `housekeep/SKILL.md` and the notify reference in the same
   commit.
6. `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs`,
   `verify.mjs`.

## Open Decisions

1. **Which routine does issue #525 then describe?** #525 asks that the routine
   filing `[FB]` issues stop posting PR-status notices and that such messaging be
   handled by "the Propose routine". After this rename the tick posting them *is*
   `[Propose]`, so the two asks read as either satisfied-by-doing-nothing or
   directly contradictory. The queued ticket
   `stop-the-housekeep-tick-posting-pr-status-notices` carries the same decision;
   resolve them together, not twice.
2. **Does the command rename too** (`/housekeep` → `/propose`)? The ask says name
   only, which leaves `[Propose]` running `/housekeep` and `[Specificate]` running
   `/propose`. Same fork as the first ticket, and it should get the same answer.
3. **Does "exactly 3 per repository" retire `[Prepare Release]` and `[Standup]`?**
   The ask enumerates three per-repository routines and both of those exist today,
   repository-scoped. Retiring them is a much larger act than a rename and is not
   assumed here.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `routines/housekeep.md` renders as `[Propose] <repo>` and declares
  `renamed_from: "[Housekeep] {repo_name}"`.
- The setup sheet and `/setup-repo-routines`' report state the **ordered** cutover:
  rename the old `[Propose]` first.
- No document still calls the maintenance tick's routine `[Housekeep]`, and no
  `/housekeep` command mention was renamed by mistake.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh repository`
- `bash plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh --all <repo-url> repository`
- `grep -rn "\[Housekeep\]" plugins/ docs/ scripts/ CLAUDE.md` returns nothing but
  migration notes.
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The first rename is merged.
- All three Open Decisions resolved explicitly in the Final Report.

## Considerations

- Two templates carrying `renamed_from:` simultaneously is a first; the field is
  deleted from each once its fleet has cut over, and leaving them is how a
  migration note becomes permanent prose.
- Nothing searches a routine's name for dedup — the Slack keys are
  `` `fb:<stem>` ``, `` `stuck:<digest>` ``, `` `deploy:<digest>` `` and
  `` `standup:<date>` `` — so no post is deduped differently by this rename. Say so
  in the story rather than leaving it to be re-derived.

## Final Report

Development completed as planned, in the same PR-unit as the first rename and after it —
which is what `depends_on` records. Step 1's precondition was checked against the tree the
rename lands on: `routines/fb.md` reads `name: "[Specificate] {repo_name}"` before this
ticket's first edit. The wording "confirm the first rename has **merged**" is satisfied here
by same-unit ordering rather than by a separate merge: both tickets ride one branch and one
pull request, so there is no window in which the second is on `main` without the first.

`routines/housekeep.md` renders as `[Propose] <repo>` and declares
`renamed_from: "[Housekeep] {repo_name}"`; `id` (`housekeep`), `scope`, `cron_expression`,
`allowed_tools`, `mcp` and the whole `## Prompt` body are byte-identical to before. Every
routine-name mention of `[Housekeep]` moved; no `/housekeep` *command* mention moved, and the
two deliberate survivors are migration notes naming the old name on purpose (this template's
own `renamed_from:` prose and `fb.md`'s statement of the swap).

**The ordered cutover is derived, not written into prose.** `render-setup-sheet.sh` now
compares each template's `renamed_from:` against every other template's `name:`, in both
directions, and renders one extra line per side when they collide: the vacating routine's
sheet says *do this one FIRST*, and the routine taking the name says *rename X to Y BEFORE
creating this one*. An ordinary rename whose freed name nobody claims renders neither line —
verified against `[Prepare Release]`, which is unchanged. Both setup commands state the same
ordering in their report paths, and `test-workflow-scripts.mjs` pins all four properties;
the swap assertions stop asserting the moment the fields are deleted, which is the intended
end state.

### Open Decisions — resolved

1. **Which routine does issue #525 describe? — The one running `/propose` (today
   `[Specificate]`), because #525 was filed before the swap.** #525 asks that the routine
   filing `[FB]` issues stop posting PR-status notices and that such messaging be handled by
   "the Propose routine". Read after this rename it looks satisfied by doing nothing, since
   the tick posting those notices is now itself called `[Propose]` — that is the trap the
   swap creates, and the resolution is to **read #525 by behaviour, not by name**: the tick
   it constrains is the `/housekeep` one, and the routine it points work at is the `/propose`
   one. Nothing about that changed; only the labels did. The decision is recorded here and in
   `CLAUDE.md`, and the **behaviour change stays with the queued ticket**
   `20260819052241-stop-the-housekeep-tick-posting-pr-status-notices`, which is a separate
   unit — resolved together, as the ticket asked, means one ruling read by both, not the same
   edit made twice.
2. **Does the command rename too (`/housekeep` → `/propose`)? — No.** Same answer as the
   first ticket, and stronger here: `/propose` is a **live command name**. Renaming
   `/housekeep` onto it would collide head-on with an existing command rather than merely
   reading oddly, and the ask says name only. The drill stages were checked for the same
   reason and deliberately left alone — `verify-housekeep` and `verify-propose` name the
   commands they run, not the routines that schedule them, and the runbook now says so in as
   many words so a later reader does not re-derive it from the mismatch.
3. **Does "exactly 3 per repository" retire `[Prepare Release]` and `[Standup]`? — No, and
   nothing here assumes it.** The ask enumerates three routines in the course of describing a
   rename; retiring two working, repository-scoped routines is a far larger act it never
   states. The counts are unchanged: three repository-scoped templates (`[Prepare Release]`,
   `[Standup]`, `[Propose]`) and two developer-scoped ones (`[Specificate]`, `[Implement]`).
   The ask's enumeration is read as *which routines exist*, not as a scope assignment, on the
   same ground the first ticket used — the ask says behaviour does not move, and scope is
   behaviour.

### Discovered Insights

- **Insight**: the two halves of a swap are asymmetric in what their sheets must say, and the
  two statements are derived from opposite directions of the same comparison — one template's
  `renamed_from:` against another's `name:`. The routine **vacating** the name needs "go
  first"; the routine **taking** it needs "rename that one before creating this".
  **Context**: a single shared warning would be wrong for one side or the other, and hand-
  writing either into prose would outlive the migration. Both are now computed from the
  template set, so deleting the `renamed_from:` fields at cutover removes the ordering notes
  and their tests together.
- **Insight**: nothing in the loop deduplicates, threads or searches on a routine's name —
  the Slack keys are `fb:<stem>`, `stuck:<digest>`, `deploy:<digest>` and `standup:<date>`.
  **Context**: this is the second time in three days the question has come up (the
  2026-08-17 release-tick rename was reversed the next day on the mistaken assumption that
  something searched the heading). It is now stated in the template and in `CLAUDE.md` so the
  next rename costs nothing to reason about.
