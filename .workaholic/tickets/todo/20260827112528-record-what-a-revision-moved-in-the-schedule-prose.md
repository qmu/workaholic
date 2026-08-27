---
created_at: 2026-08-27T11:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Record what a revision moved in the Schedule prose

## Overview

PROPOSED. A revised direction should say on its own face that it was revised — otherwise
a reader sees only the current values and cannot tell a direction that has always said
this from one re-dated twice. `## Schedule` already carries "the shape around the date (a
start, milestones, a cadence) in prose", so the history goes where the history already
lives: an appended line per revision. **No frontmatter key, no second artifact, no
changelog area** — a strategy is small enough that its whole history is the file.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/amend.sh` — the appender; the same single
  writer, not a second one.
- `plugins/workaholic/skills/strategy/SKILL.md` — *The model*, where `## Schedule`'s
  contents are defined; the appended line is part of that definition now.
- `plugins/workaholic/hooks/validate-strategy.sh` — the non-empty `## Schedule` floor the
  append must keep satisfied.

## Implementation Steps

1. On a successful revision, append **one line** to `## Schedule` naming what moved and
   when — the date, in the artifact's own `YYYY-MM-DD` vocabulary, and the parts revised.
2. Append-only: never rewrite a previous line, and never reorder. A reader scanning down
   the section reads the direction's history in order.
3. Keep it inside the artifact's ceiling sensibility — one short line, not a diff. The
   file is meant to be read whole.
4. Make it idempotent with the revision itself: an amendment that changes nothing (the
   `already` case) appends nothing. A no-op that grew the file would make the file grow
   on every tick that re-ran the same ask.
5. When the revision touched the Schedule prose itself, the appended line goes **after**
   the operator's new prose, so their words lead and the machine's follow.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A revision appends exactly one line naming what moved and when.
- A no-op revision appends nothing and leaves the file byte-identical.
- Two successive revisions leave two lines in order, the first unrewritten.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Hermetic exercise: amend, re-amend identically, amend differently; assert the section.

**Gate** — what must pass before approval:

- The suite is green and the append-only property is asserted, not assumed.

## Considerations

- A `revised_at:` frontmatter key is the obvious alternative and is refused here: it is a
  field on an artifact whose model is deliberately small, it would need a reader, and the
  prose section already exists to carry exactly this.
- The line is written by `amend.sh` and by nothing else — a second appender would be the
  fourth writer this mission is careful not to create.
