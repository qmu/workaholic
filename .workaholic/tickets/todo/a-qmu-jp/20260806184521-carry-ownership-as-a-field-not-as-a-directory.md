---
created_at: 2026-08-06T18:45:21+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on: 20260806183638-split-drive-into-an-interactive-drive-and-an-unattended-implement.md
mission: reduce-the-loop-to-two-routines-and-one-behaviour-per-command
feedback: [20260806184651-ownership-is-a-field-not-a-directory.md]
merge_policy:
---

# Carry ownership as a field, not as a directory

## Overview

PROPOSED, and it is the **design fix behind a patch that was nearly shipped**. A ticket's
owner is encoded in its **path** — `.workaholic/tickets/todo/<user-slug>/` — so
`plan-units.sh` resolves the runner's `git config user.email` to a slug and opens only
that directory. With no identity there is no directory to open, so the survey reports an
**empty queue** rather than an unreadable one: "could not read" and "nothing queued" are
the same observation because nothing in the data distinguishes them. The proposed
mitigation was a `git config user.email` line in the routine prompt — an environment
expectation layered over the flaw, and the third patch in that area this week.

Two further costs follow from ownership-as-path. **Reassignment is a file move**, and
following renames is exactly what the claim reader's tree-to-tree rename map plus filename
fallback exist for — both added after real double-pick incidents (2026-07-30, 2026-08-04).
And **two ownership models coexist**: a mission carries plural `assignees` resolved through
one reader (`mission-owners.sh`), with empty meaning team-owned and claimable by anyone,
while a ticket has exactly one owner, expressed as a directory, with no unowned state at
all. The better model already exists and is proven; the worse one is the one the queue uses.

**The deeper point (the developer's, 2026-08-06): "who" should propagate as information.**
The Propose routine fires on an issue *assigned to a person* — the identity is known at the
trigger. It should ride the artifacts from there (issue assignee → proposal `assignees` →
ticket `assignees` → the implementing run) instead of being re-derived from whatever git
config each container happens to carry.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — resolves `user_slug` and reads
  only that directory; the `identity_unresolved` / empty-backlog branch is here
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` — the environment read that stops
  being load-bearing for *reading* the queue
- `plugins/workaholic/skills/mission/scripts/mission-owners.sh` — the proven reader to
  generalize (mission `assignees`, legacy `assignee` fallback, empty = claimable)
- `plugins/workaholic/hooks/validate-ticket.sh` — enforces `todo/<user>/` in prose and code
- `plugins/workaholic/hooks/guard-ticket-structure.sh`,
  `plugins/workaholic/hooks/workaholic-layout-allowlist.txt`,
  `plugins/workaholic/rules/workaholic.md` — the lockstep pair plus the move guard
- `plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh` — sweeps strays *into*
  `todo/<user>/`; its whole reason for existing goes away
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — already assumes filenames are
  unique across `.workaholic/tickets/`, which is what makes flattening safe

## Implementation Steps

1. **Generalize the owner reader.** Lift `mission-owners.sh` to read any artifact's
   `assignees` (plural, empty = team-owned), keeping the legacy singular fallback. One
   reader answers "whose is this?" for every artifact kind.
2. **Flatten the queue and stamp the field.** A living migration (the
   `migrate-strategies.sh` pattern, run from the queue scripts' own seam) moves
   `todo/<slug>/X.md` → `todo/X.md` and writes `assignees: [<email>]` derived from the
   directory it came from. `archive/` is never touched.
3. **Filter by owner, not by path.** `plan-units.sh` reads the whole queue and applies the
   same three-way rule it already applies to missions: mine → claimable, unowned →
   claimable, someone else's → excluded `owned_by_other`.
4. **Report the honest failure.** With no resolvable identity the survey still reads the
   queue: report `owner_unresolved` with the queue size and offer the unowned items. Decide
   and record whether that state may still terminate the run — but it must never render as
   an empty queue again.
5. **Move the location rule in lockstep**: `validate-ticket.sh`, the move guard, the
   allowlist and the `rules/workaholic.md` table, all in the same commit; retire
   `sweep-todo.sh` with them.
6. **Carry `assignees` through the chain**: `/propose` writes the issue's assignee onto
   what it emits, so the identity enters once at the trigger.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A runner with **no** `git config user.email` reads the queue and reports
  `owner_unresolved` with its size — never an empty backlog.
- A ticket's owner is its `assignees` field; changing it is a frontmatter edit, and an
  unowned ticket is claimable by anyone.
- One reader answers ownership for missions and tickets alike.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with a fixture repository whose identity is
  unset, asserting the queue is read and the reason is `owner_unresolved`
- A migration fixture: `todo/<slug>/X.md` → `todo/X.md` carrying the derived `assignees`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- No ticket content is lost or rewritten by the migration beyond the `assignees` stamp.
- The claim protocol's identity use is **unchanged**: claim authorship and resumption still
  key on `git config user.email`, because that asks "is this my own run" and fails loudly.

## Considerations

- **Filename uniqueness is already assumed.** `claims.sh`'s filename fallback is documented
  as unique across `.workaholic/tickets/` by construction; the per-user directory adds
  nothing there, which is what makes flattening safe rather than merely convenient.
- **This unblocks the four-line prompt.** `cut-the-two-routine-templates-…` keeps the
  identity line only until this lands; it is a dependency, not a preference.
- **The queue becomes readable by everyone.** Today a developer sees only their own
  directory by accident of the survey's shape; flattening makes "whose work is queued" a
  question the data answers. That is the intent, but it is a visible change in what a bare
  `/ticket` listing shows.
