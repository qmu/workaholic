---
created_at: 2026-08-21T15:15:50+09:00
status: done
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


## Final Report

### The enumeration, from reading the callers (step 1)

Eight call sites, not the two the report named. Seven already satisfy the rule, each for its own
reason, and the eighth is the gap:

| Call site | Why it is safe, or not |
| --- | --- |
| `branching/scripts/publish-tree-commit.sh` | forwards its caller's `"$@"`; the caller names the paths (`persist-log.sh` passes the log and each record) |
| `branching/scripts/publish-tree-pr.sh` | same forwarding shape |
| `drive/scripts/claim.sh` (claim commit) | forwards `"$@"`; its stamp edits a tracked `mission.md` |
| `drive/scripts/claim.sh` (resume) | `--allow-empty` marker commit |
| `drive/scripts/heartbeat.sh` | `--allow-empty`, an empty commit by construction |
| `drive/scripts/archive.sh` | `--skip-staging` after its own `git add -A`, which takes untracked |
| `ship/scripts/record-release-cut.sh`, `confirm-release.sh` | `--skip-staging` after an explicit `git add "$FILE"` |
| `feedback/SKILL.md`'s capture workflow | `create.sh` git-stages the record it writes |
| **`story` Phase 4** | **writes `.workaholic/stories/<branch>.md` — new — then commits bare.** The gap. |

`/drive` §5 is the same gap seen from the other side: it delegates the story to `/story`, so it
gains a one-sentence reference rather than a second rule.

**Three shapes satisfy the rule without `files...`** and are named in the skill so a later reader
does not "fix" them: a caller that staged the file itself and passes `--skip-staging`, one that
passes `--allow-empty`, and a wrapper forwarding its caller's `"$@"`.

### The rule, stated once

`workaholic:commit` now carries it beside the `files...` contract: **a caller that has just written
a NEW file passes it in `files...`**, because default staging is `git add -u` and by its own
semantics cannot pick up a file that did not exist. `/story` Phase 4 and `/drive` §5 **reference**
it with one sentence each saying why, so the next editor does not simplify the name back out.

### It does not replace the sibling, and the sibling does not replace it

A rule holds where somebody follows it; a refusal holds everywhere. With the sibling landed, a seam
that forgets the name now **fails loudly** instead of silently — which is exactly the ordering the
Considerations asked for, and it is how this ticket got cheap to verify.

**Verification**: every `commit.sh` call site grepped and checked against the enumeration above;
`node scripts/test-workflow-scripts.mjs` — 3408 passed, 0 failed; `build.mjs` + `verify.mjs` clean.
