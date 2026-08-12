---
created_at: 2026-08-12T18:47:34+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
merge_policy:
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
