---
created_at: 2026-08-21T15:15:50+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: refuse-a-commit-that-splits-a-rename
merge_policy:
verification_handoff: 
---

# Name the files the writing seams must stage

## Overview

PROPOSED, and the cheap half the reporter names third. `commit.sh` takes an optional
`files...` argument. The seams that write **new** files — `/report` Phase 4 writing the story
body, `/drive` §5 after a migration has written into the tree — call it without one and rely on
default staging, which by `git add -u`'s semantics cannot pick up a new file. The story that
was lost was lost exactly this way, and its index entry merged without it.

This is a procedure change. It does not replace the other ticket's mechanical guarantee, and
neither makes the other redundant: a rule holds where somebody follows it, a refusal holds
everywhere.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/story/SKILL.md` — Phase 4, which commits the story it just wrote.
- `plugins/workaholic/skills/drive/SKILL.md` §5 — the drive-side commit seam.
- `plugins/workaholic/skills/commit/SKILL.md` — where the `files...` contract is stated, and where the rule belongs.


## Implementation Steps

1. Enumerate every seam that calls `commit.sh` after writing a file that did not previously
   exist. Do this by reading the callers, not from the report — the report names two and there
   may be more.
2. State the rule once, in `commit.sh`'s own SKILL: a caller that has just written a new file
   passes it in `files...`; default staging is for tracked modifications only.
3. Update each enumerated seam to name its new files explicitly.
4. Say why in one sentence at each site, so the next editor does not simplify it back to a bare
   call.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every seam that writes a new file names it in `commit.sh`'s `files...`.
- The rule is stated once, in the commit skill, and referenced rather than restated.
- The enumeration comes from reading the callers, not from the report.

**Verification method** — the commands/tests/probes that prove them:

- Grep every `commit.sh` call site and check each against the enumeration.
- Run `/story` on a branch and confirm the story body is in the commit.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No seam is left relying on default staging for a file it just created.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` clean.


## Considerations

- If the other ticket lands first, this one gets cheaper to verify: the refusal makes a missed
  seam fail loudly instead of silently. Order them that way if both are driven together.
- Enumerating the seams is the substance here. A rule written in the skill and applied to the
  two sites the report happens to name would leave the next seam to be found by another
  incident.

