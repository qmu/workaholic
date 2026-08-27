---
created_at: 2026-08-27T11:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Write amend.sh, the one writer of a live direction

## Overview

PROPOSED. The strategy artifact has two writers and no third: `create.sh` creates and
`close.sh` ends. Nothing edits a live direction's Aim, Schedule or Assignee, so an
announced *change* is record-only and the operator applies it by hand on `main` — the one
act in this repository that requires a person to edit the base directly. This ticket
writes `strategy/scripts/amend.sh`, the third writer, bounded to the three parts the
model calls revisable.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/amend.sh` — NEW; the third writer.
- `plugins/workaholic/skills/strategy/scripts/create.sh` — the frontmatter and floor
  this must produce identically; the refusal vocabulary to mirror
  (`bad_target_date` / `no_assignees` / `empty_schedule` / `empty_aim`).
- `plugins/workaholic/skills/strategy/scripts/close.sh` — the sibling writer's shape:
  POSIX `#!/bin/sh -eu`, optional trailing `.workaholic` root, one JSON object,
  `reason: already` on a no-op.
- `plugins/workaholic/skills/strategy/scripts/read.sh` — the reader; reuse it rather
  than parsing the file a second time.
- `plugins/workaholic/hooks/validate-strategy.sh` — the write-time floor the output
  must satisfy by construction.
- `scripts/test-workflow-scripts.mjs` — `testDirectionHealthRefusals` asserts
  `writers == ["close.sh", "create.sh"]` by grep over `strategy/scripts/`. This ticket
  is what makes that assertion false.

## Implementation Steps

1. Read `create.sh` and `close.sh` end to end before writing anything — the new writer
   must be indistinguishable from them in shell dialect, argument handling, the trailing
   root argument, and the single-JSON-object output.
2. Write `amend.sh <slug> [--target-date <YYYY-MM-DD>] [--schedule <prose>]
   [--assignees <a>[,<b>...]] [--aim -] [<workaholic-root>]`, Aim prose on stdin when
   `--aim -` is passed. At least one revision must be named, or refuse `no_revision`.
3. Refuse by name and write nothing: `no_slug`, `not_found`, `not_active` (a closed
   strategy is history — `close.sh` stays the only writer of an end state),
   `bad_target_date`, `no_assignees`, `empty_schedule`, `empty_aim`.
4. Touch **only** `## Aim`, `target_date:` / `## Schedule` and `assignees:`. `slug`,
   `type`, `status`, `created_at`, `author` and `feedback:` are rewritten by nothing —
   assert this in the script rather than relying on the caller.
5. Make it idempotent: a revision already applied leaves the file byte-identical and
   reports `reason: already`, exactly as `close.sh` does on a re-close.
6. Stage and never commit (`git add` on the one path), matching `create.sh`.
7. Update `testDirectionHealthRefusals`' writer assertion to
   `["amend.sh", "close.sh", "create.sh"]` **in this same change**, with a comment
   recording that the count moved deliberately and what bounds the third writer — the
   pin exists so a fourth re-decision cannot happen silently, and moving it silently is
   exactly what it was written to catch.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `amend.sh` revises each of the three parts, alone and together, and writes nothing on
  every named refusal.
- A closed strategy is refused `not_active`; an immutable field is unreachable from the
  script's interface.
- Re-running an applied revision leaves the file byte-identical and reports `already`.
- `node scripts/test-workflow-scripts.mjs` passes, with the writer assertion naming
  three writers and its reason recorded beside it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Hermetic exercise over a throwaway `.workaholic` root: create a strategy, amend each
  part, re-amend, close, amend again.

**Gate** — what must pass before approval:

- The suite is green and no assertion was deleted to get there.

## Considerations

- The suite's writer count is a **grep**, so a writer reached indirectly through a helper
  would pass it. Do not add such a helper; keep the write in `amend.sh` itself.
- `validate-strategy.sh` grandfathers git-tracked files, so it will not catch a malformed
  amendment of a committed strategy. The floor must therefore be enforced in the writer,
  which is the next ticket's subject.
