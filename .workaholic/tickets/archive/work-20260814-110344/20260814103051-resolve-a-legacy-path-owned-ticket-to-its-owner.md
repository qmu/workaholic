---
created_at: 2026-08-14T10:30:51+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-the-runner-from-taking-path-owned-legacy-tickets
merge_policy:
verification_handoff: 
---

# Resolve a legacy path-owned ticket to its owner

## Overview

PROPOSED. Close the tolerance gap P2 left open. `drive/scripts/list-todo.sh`
deliberately reads both layouts (`-maxdepth 2`), so a ticket still sitting at
`.workaholic/tickets/todo/<user-slug>/X.md` with no `assignees:` frontmatter is
surveyed — and `gather/scripts/owners.sh` has exactly two resolution tiers
(plural `assignees:`, then legacy singular `assignee:`), so it emits nothing and
`owns.sh` answers `unowned`. Unowned means team-owned, claimable by anyone, and
`plan-units.sh` offers the ticket to every runner. The directory that used to BE
the ownership record is silently reinterpreted as its absence, which is the exact
inverse of the `owned_by_other` exclusion the survey promises.

The fix this proposal recommends is a **third resolution tier on the one oracle**,
not an exclusion rule in the survey: `owners.sh` is where every consumer already
reads ownership from, comparison is already by slug (`user-slug.sh`) precisely so
a migration-stamped `a-qmu-jp` matches `a@qmu.jp`, and a tier keeps the runner's
OWN legacy tickets answering `mine` instead of disappearing with everyone else's.
The alternative the reporter also offered is recorded under Considerations.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/owners.sh` — the one ownership oracle;
  its documented resolution order is the thing being extended.
- `plugins/workaholic/skills/gather/scripts/owns.sh` — turns owners into
  `mine`/`unowned`/`other`/`unresolved`; must keep `unresolved` distinct.
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` — the slug comparison a
  directory-derived owner has to survive.
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` — the reader that surfaces
  both layouts; confirms which paths reach the oracle.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the consumer that
  turns `other` into the `owned_by_other` exclusion.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for the new tier.
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md` — the Ownership paragraph
  states "the `assignees:` field alone"; it must state the tolerance tier too.

## Implementation Steps

1. **Reproduce and localize first.** In a throwaway repository, write a ticket at
   `todo/<some-other-slug>/X.md` with no `assignees:`, then run `list-todo.sh`,
   `owners.sh`, `owns.sh` and `plan-units.sh` over it under a different
   `git config user.email`. Record the actual answers — the expected finding is
   `unowned` and an offered unit, but measure it rather than assume the report.
2. Read `owners.sh`'s header before touching it: the resolution order, the
   deliberately-absent `author:` tier, and the retired strategy hop are all
   reasoned there, and the new tier has to be written in the same terms.
3. Add the **third tier** to `owners.sh`: when tiers 1 and 2 are empty AND the
   artifact's path is `.workaholic/tickets/todo/<segment>/<file>.md`, resolve the
   owner to `<segment>`. Only that shape — a ticket directly in `todo/` keeps
   answering empty (genuinely team-owned), and no other artifact kind gains a
   path tier.
4. Confirm `owns.sh` needs no change: the slug comparison already normalizes a
   directory-shaped owner (`a-qmu-jp`) against an email identity (`a@qmu.jp`).
   If it does not, fix it in `user-slug.sh`, not by string-comparing here.
5. Verify the consumer end-to-end: `plan-units.sh` now excludes a colleague's
   legacy ticket as `owned_by_other`, and still offers the runner's own.
6. Add hermetic cases to `scripts/test-workflow-scripts.mjs` covering all three:
   colleague's legacy ticket excluded, own legacy ticket offered, flat unowned
   ticket still team-owned.
7. Update the Ownership paragraph in `CLAUDE.md` and `rules/workaholic.md` in the
   same change — a tolerance nobody documented is how this defect survived P2.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A ticket at `todo/<other-slug>/X.md` with no `assignees:` answers `other` from
  `owns.sh` and is excluded by `plan-units.sh` as `owned_by_other`.
- The same ticket under the runner's own slug answers `mine` and stays offered.
- A ticket directly in `todo/` with no `assignees:` still answers `unowned`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new hermetic cases for all three).
- Manual replay of step 1's reproduction against the patched oracle.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green, and the Ownership paragraph in
  `CLAUDE.md` and `rules/workaholic.md` updated in the same commit.

## Considerations

- **The alternative the reporter also offered** — excluding legacy-layout tickets
  in the survey instead of resolving them in the oracle — is recorded as a
  hypothesis, not the design. It would exclude the runner's OWN legacy tickets
  too, hiding a whole queue from its owner, and it would put a second ownership
  resolution path next to the one `owners.sh` exists to be.
- This tier is a **tolerance, not a model change**: it exists only while the
  legacy layout does. Write it so it can be deleted when the layout is gone —
  the sibling ticket in this mission is what makes queues actually drain.
- `author:` stays out of ownership. The path tier reads the directory, which was
  the old owner field; it must not be widened into reading `author:`.

## Final Report

Development completed as planned. Step 1's reproduction confirmed the report rather
than assuming it: in a throwaway repository under a different `git config user.email`,
`list-todo.sh` surfaced all three fixtures, and a colleague's `todo/colleague-example-com/…`
ticket with no `assignees:` answered `owners=[]` / `owns=unowned` — offered to every
runner. `owners.sh` gained the third tier; `owns.sh` and `user-slug.sh` needed no change
(step 4's contingency did not fire — a directory-shaped owner already normalizes against
an email identity). `plan-units.sh` now excludes the colleague's ticket as
`owned_by_other` while still offering the runner's own and the flat unowned one.

### Discovered Insights

- **Insight**: The tier's path match has to be anchored at both ends —
  `parent = todo` **and** `grandparent = tickets`.
  **Context**: Anchoring only on `parent = todo` would make a flat
  `todo/X.md` resolve its owner to the literal string `todo` (its own directory), turning
  every genuinely team-owned ticket into one owned by nobody real. The two-segment match
  is what keeps "a ticket directly in `todo/`" answering `unowned`, which is the state the
  whole ownership model rests on.

- **Insight**: The legacy `assignee:` tier had to be restructured from a bare `awk` at the
  end of the file into a captured value with an explicit `exit 0`.
  **Context**: It was previously the last statement, so "no output" and "fall through"
  were the same thing. Adding a tier after it meant the singular field's silence had to
  become a decision — otherwise a ticket carrying `assignee: someone@x` in a legacy
  directory would have emitted both owners.

- **Insight**: The tolerance is deletable by construction, and the sibling ticket is what
  makes deleting it possible.
  **Context**: The tier fires only for one path shape and only after both field tiers are
  silent, so removing it is a single block deletion. It stays only while the layout does —
  and `archive.sh` now converges every queue it touches, so the layout actually drains
  through ordinary use rather than waiting for someone to run `/workaholify`.
