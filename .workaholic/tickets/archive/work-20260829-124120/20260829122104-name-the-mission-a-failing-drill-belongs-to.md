---
created_at: 2026-08-29T12:21:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Name the mission a failing drill belongs to

## Overview

Make a failing drill name the **mission that shipped it**, so a red merge says which
earlier turn it broke rather than only which script. Every drill was added by one mission
and the tree already records the link three times over — the commit that added
`cmd_verify_<x>()`, the ticket archived under that mission, and the runbook paragraph
naming the mission by slug (for example `verify-arrival` → `say-when-a-direction-has-arrived`,
`verify-catch-up` → `land-the-loop-s-own-work-when-the-base-moves-under-it`). Resolve it
from what exists; **add no field to any artifact**.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — derive, never duplicate
- `workaholic:operation` / `policies/observability.md` — a failure that names its origin

## Key Files

- `docs/loop-drill-runbook.md` — already names the shipping mission in most per-drill
  paragraphs; the cheapest resolvable source
- `scripts/e2e/loop-drill.sh` — several `cmd_verify_*` headers name their mission in prose
- `.workaholic/missions/` — the archive the resolved slug is checked against

## Implementation Steps

1. Choose the resolution source and state why: the runbook's per-drill prose (one place, a
   human keeps it current, ticket 8 can pin it) against `git log -S 'cmd_verify_<x>()'` →
   the adding commit → its ticket → its `mission:` relation (fully derived, no prose to
   drift, but slow and defeated by a rename). Prefer the runbook, pinned.
2. Resolve each drill to a mission slug and validate it against `.workaholic/missions/`
   (active or archive) — an unresolvable slug is reported as `mission_unresolved`, never
   guessed and never omitted.
3. Have ticket 2's verdict document carry the mission slug per drill, and ticket 4's job
   log print it beside a failing drill's name.
4. Read the mission relation through the readers that already exist — never a second
   parser of `mission:` (`mission/scripts/read-relation.sh` is the one reader).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every drill resolves to a mission slug, or is reported `mission_unresolved` by name.
- A resolved slug names a mission that actually exists in the tree.
- A failing drill's report and the CI log both carry the slug.
- No artifact gained a field, and no second parser of `mission:` was written.

**Verification method** — the commands/tests/probes that prove them:

- The verdict document over the whole set, read for the slug per drill.
- A deliberately broken drill, proving its CI failure line names the mission.
- A drill with a deliberately unresolvable mapping, proving `mission_unresolved`.

**Gate** — what must pass before approval:

- Every slug resolves against the tree or is named unresolved, and the diff adds no
  frontmatter field anywhere.

## Considerations

- A mission slug can be renamed or a mission archived; validation against the tree is what
  turns that into a named `mission_unresolved` rather than a false attribution.
- One drill can legitimately cover a mechanism several missions touched. Name the mission
  that **shipped the drill**, which is a single fact, rather than trying to name every
  mission the mechanism belongs to.

## Final Report

Development completed as planned.

**The resolution source is the runbook's register**, pinned — the ticket's preferred fork.
Each of the thirty rows was resolved by the derived route it names (`git log -S
'cmd_verify_<x>()' -- scripts/e2e/loop-drill.sh` → the adding commit → the tickets that
commit's branch archived → their `mission:` relation, read through
`mission/scripts/read-relation.sh`), and the result recorded in one place a human keeps
current. Reading `git log -S` at question time was refused for the reason the ticket
states: it is slow, and it is **defeated by a rename** — which happened twice here
(`verify-propose` → `verify-specificate` and `verify-housekeep` → `verify-moderate`,
2026-08-19), so the derivation lands on the rename commit rather than on the drill's
origin.

Every resolved slug is **validated against `.workaholic/missions/`** (active and archive)
by `drill-register.sh`, so a renamed or deleted mission answers `mission_resolved: false`
rather than being reported as a false attribution. `verify-all` carries `mission` and
`mission_resolved` on every drill's verdict row, and the `/moderate` question and the
archive gate both name the mission from the same reader.

**No artifact gained a field and no second parser of `mission:` was written**: the slug
lives in the register and nowhere else, and the relation was read at resolution time
through the one reader that already owns it.

**Two rows are unresolved on purpose**, each with its reason written down: `verify-propose`
(added by a hand-typed commit on a branch that archived no ticket, so there is no relation
to read — recorded as unresolved rather than attributed to whichever mission happened to be
in flight that day) and, hand-corrected with its evidence, `verify-moderate` (the
derivation stops at the 2026-08-19 rename, and its origin is the mission that shipped the
maintenance tick).

### Discovered Insights

- **Insight**: `git log -S` on a function name resolves the commit that most recently
  **introduced that string**, which for a renamed drill is the rename, not the origin. Two
  of the thirty rows land there, and both were silently plausible — the rename commit is a
  real commit with real tickets on its branch.
  **Context**: It is the concrete form of the ticket's warning that the derived route is
  "defeated by a rename", and the reason a register a person maintains beats a derivation
  run at question time: a wrong attribution is worse than a named absence.
