---
created_at: 2026-08-12T18:47:34+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
merge_policy:
claim: work-20260812-193239
---

# Validate the archive subject before moving the ticket

## Overview

<!-- MINTED MID-RUN by /implement while driving
     20260812155908-refuse-the-bare-repo-name-only-where-it-reads-as-a-reference.md.
     Observed, not speculated: the run hit it and had to recover by hand. -->

`archive.sh` moves the ticket into `archive/<branch>/` and only afterwards calls `commit.sh`,
which runs the commit-subject gate. When the subject is off-policy the commit is refused but
the move has already happened, so the working tree is left half-archived: the ticket is staged
as a rename into `archive/`, no commit exists, and **re-running the same command fails** with
`Error: Ticket not found` because the path it was given no longer holds a file. The obvious
retry — the one a driving run reaches for — is the one that cannot work.

Measured 2026-08-12 on branch `work-20260812-183726`. The ticket's H1 was passed through as the
commit subject at 60 characters (limit 50); `commit.sh` printed the subject policy and exited,
after `archive.sh` had already reported `==> Archiving ticket...` and the new path. Recovery
was a hand-written `git mv` back to `todo/` followed by a re-run with a shortened subject — a
destructive-looking manual step in exactly the seam the drive workflow says must never be done
by hand (`NEVER manually archive`, `skills/drive/reference/ticket-workflow.md`).

The cost is not theoretical for an unattended run: `/implement` has no human to notice the
half-archived state, and the failure contract's honest outcomes (`failed`, `blocked`) all
assume the tree is left in a state a later run can read. A staged-but-uncommitted rename is
not that state.

The subject is knowable before anything moves. `check-subject.sh` is already the canonical
validator and is already called by `commit.sh`, by `guard-git-commit.sh`, and by the git-native
`commit-msg` hook — the point of that design is that the same rule can be asked anywhere.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`, no bashisms
  (`plugins/workaholic/rules/shell.md`); the script runs under `set -eu`.
- `workaholic:implementation` / `policies/observability.md` — a step that cannot complete must
  fail before it has changed anything, and say what to do.
- `workaholic:operation` — the seam runs unattended; a partial state that no later run can read
  or repair is the failure mode to design out.

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — `echo "==> Archiving ticket..."` /
  `mkdir -p "$ARCHIVE_DIR"` / `mv "$TICKET" "$ARCHIVE_DIR/"` (~L57-L60) run before the
  `commit.sh` call further down. `COMMIT_MSG` is `$2`, available from the first line.
- `plugins/workaholic/skills/commit/scripts/check-subject.sh` — the canonical validator, and
  the thing to call. Confirm its argument and exit-code contract rather than assuming it.
- `plugins/workaholic/skills/commit/scripts/commit.sh` — where the gate fires today; it must
  keep firing there (the pre-flight is an addition, never a replacement).
- `scripts/test-workflow-scripts.mjs` — the drive/archive block builds throwaway repositories
  and is where the regression pin goes.
- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` — documents the archive seam
  and the `NEVER manually archive` rule; if the recovery story changes, it changes here.

## Implementation Steps

1. **Reproduce first.** In a throwaway repository, call `archive.sh` with a subject over 50
   characters and record: the exit status, the stdout, and `git status --short` afterwards.
   Confirm the rename is staged with no commit, and confirm the identical re-run reports
   `Ticket not found`. Do not proceed on this ticket's description alone.
2. **Localize.** Establish that the refusal comes from the subject gate and not from another
   `commit.sh` precondition, by its emitted message.
3. **Validate before moving.** Call `check-subject.sh` on `$COMMIT_MSG` at the top of
   `archive.sh`, before `mkdir`/`mv`, and exit non-zero with the validator's own message when
   it refuses. Nothing on disk changes on that path.
4. **Do not weaken the gate and do not auto-shorten the subject.** Truncating a subject to fit
   would put a machine-invented sentence into permanent history; the caller passes a shorter
   one. `commit.sh` keeps its own check — one rule source, layers that cannot drift.
5. **Audit the rest of the seam for the same shape.** Any other step in `archive.sh` that
   mutates the tree before a check that can refuse is the same defect; record what was found
   in the Final Report even if the answer is "nothing else".
6. **Pin the regression**: an off-policy subject leaves the ticket in `todo/`, exits non-zero,
   names the limit, and the tree is byte-identical to before the call.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `archive.sh` with an off-policy subject exits non-zero, prints the subject policy, and leaves
  the ticket in `todo/` with nothing staged.
- Re-running the same command with a conformant subject then succeeds, with no manual `git mv`
  in between.
- A conformant subject archives exactly as today — same move, same commit, same push.
- The subject rule itself is unchanged, and `commit.sh` still enforces it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new pin plus the existing archive assertions,
  green.
- The step-1 reproduction re-run against the fixed script, with `git status --short` before and
  after, in the Final Report.

**Gate** — what must pass before approval:

- The reproduction is recorded before the fix, per the diagnosis-first rule.
- The Final Report states the audit result from step 5.

## Considerations

- The pre-flight duplicates a check `commit.sh` already runs. That is deliberate and is the
  same shape the repository already uses for this exact rule across three layers; the
  duplication is a *call to one validator*, not a second copy of the rule.
- A half-archived tree is recoverable by hand today only because a human read the output. The
  value here is for `/implement`, where nobody does.
- Whether the failed path should also leave a breadcrumb (a reported reason a later run can
  read) is worth one thought, but the smaller fix — never enter the bad state — is the one
  this ticket asks for.

## Final Report

Development completed as planned.

### Reproduction, before the fix (step 1)

Throwaway repository, one ticket in `todo/`, clean tree, `archive.sh` called with a
60-character subject:

```
$ git status --short          # (empty — clean)
$ sh archive.sh …/todo/20260101000000-demo.md "Refuse the bare repo name only where it reads as a reference" …
exit=1
$ git status --short
A  .workaholic/index.md
R  .workaholic/tickets/todo/20260101000000-demo.md -> .workaholic/tickets/archive/work-20260101-000000/20260101000000-demo.md
$ <identical re-run>
Error: Ticket not found: .workaholic/tickets/todo/20260101000000-demo.md
```

The rename staged, no commit, and the obvious retry impossible — exactly as reported.

### Localization (step 2)

By the **emitted message**, not by inspection. The refusal is the subject gate:

```
==> Staging changes...
Error: rejected off-policy subject (subject is 60 characters (limit 50)).
```

printed *after* `==> Archiving ticket...` and the move. A conformant subject archived
cleanly against the same fixture, confirming nothing else in `commit.sh` was involved.

### The audit (step 5) — is anything else the same shape?

Every step of `archive.sh` that mutates the tree, against every refusal that can follow it:

| refusal in `commit.sh` | reachable after the move? |
| ---------------------- | ------------------------- |
| off-policy subject | **yes** — this defect |
| not on a named branch | no — `archive.sh` checks it itself, before the move |
| a named path cannot be staged | no — unreachable from this caller: `archive.sh` passes `--skip-staging` with no file list |
| flag-parsing errors (`--trailer`, unknown flag) | no — `archive.sh` passes fixed, well-formed flags |

The mission mutators between the move and the commit are explicitly non-blocking and
report rather than fail, so they cannot strand the ticket either. **The subject gate was
the only one.**

### What changed

- `archive.sh` calls `commit/scripts/check-subject.sh` as its first act, before
  `mkdir -p`/`mv`, and exits non-zero with the same message `commit.sh` prints plus one
  line the caller actually needs: *"Nothing was moved and nothing was staged. Re-run with
  a conforming subject."* `SCRIPT_DIR` moved up to the top; the duplicate definition
  further down is gone.
- `commit.sh` keeps its own check — this is a **call to one validator**, not a second copy
  of the rule, so the four layers still cannot drift.
- No auto-shortening (step 4): truncating a subject to fit would put a machine-invented
  sentence into permanent history.
- Ten assertions pin the all-or-nothing property, including that the retry works with no
  manual `git mv` in between — the half-archived state's real cost.
- Prose updated in the same change: `drive/reference/ticket-workflow.md`'s Archive section
  (the recovery story changed) and `CLAUDE.md`'s commit-subject gate line (`archive.sh` is
  now a fourth caller of the canonical validator).

### Verification

- The step-1 reproduction re-run against the fixed script: refused, and `git status` +
  `git rev-parse HEAD` **byte-identical to before the call**; the ticket still in `todo/`,
  nothing in `archive/`.
- The same command with a conforming subject then succeeded, with no manual step between.
- `node scripts/test-workflow-scripts.mjs` → **2327 passed, 0 failed** (from 2317),
  including the ten new assertions.
- `build.mjs` / `verify.mjs` clean.

### Discovered Insights

- **Insight**: this defect was found by *hitting* it while driving an unrelated ticket in
  the same run that later minted this one, and the recovery required the one operation the
  drive workflow explicitly forbids (`NEVER manually archive`).
  **Context**: when a seam's failure mode can only be undone by an action the workflow
  bans, that is the signal to fix the seam rather than to document the recovery. The
  forbidden-recovery smell generalizes to any script that mutates before it validates.
- **Insight**: the fix is one call, but the *audit* is the deliverable — the table above is
  what makes "this cannot happen elsewhere in this seam" a checked claim rather than a
  hope.
  **Context**: `--skip-staging` with no file list is what makes the "named path cannot be
  staged" refusal unreachable here. If a future change gives `archive.sh` an explicit file
  list, that refusal becomes reachable after the move and this audit needs redoing.
