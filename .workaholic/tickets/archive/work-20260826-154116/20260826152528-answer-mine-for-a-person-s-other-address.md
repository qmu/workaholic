---
created_at: 2026-08-26T15:25:28+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826152528-read-a-person-s-addresses-through-one-script.md
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Answer mine for a person's other address

## Overview

PROPOSED. `owns.sh` compares the runner's identity against each owner **by slug**
(`user-slug.sh`), which makes `A@Qmu.jp` and `a@qmu.jp` one person and makes a migration's
derived slug match its email. It does not make `a@qmu.jp` and `tamura.yoshiya@gmail.com` one
person, because nothing tells it they are — until ticket 1, nothing could.

This is the **reader's** half, and the ask names it as the contestable one. It recovers a
person's existing work; ticket 2 prevents the next strand. Taken in that order of caution
deliberately.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/owns.sh` — the three-way ownership oracle; the
  comparison loop at its foot is the only thing that moves.
- `plugins/workaholic/skills/gather/scripts/identity.sh` — ticket 1's reader.
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` — the existing comparison; it stays,
  and resolution happens **before** it.
- `.workaholic/missions/active/refuse-ok-under-a-placeholder-identity/mission.md` — its
  `## Scope` reads "Not `owns.sh`'s comparison, which is correct." Read the whole file before
  writing the header note in step 4.

## Implementation Steps

1. Reproduce: with the committed mapping in place, assert that `owns.sh` answers `other` for an
   artifact owned by a mapped alias of the runner's own address. That is the defect, and it is
   one line of output.
2. Resolve **both sides through `identity.sh`** before the existing slug comparison — the
   runner's identity and each owner. A mapped alias then resolves to the same canonical address
   and the existing comparison answers `mine` unchanged.
3. Keep every other answer exactly where it is. An address the mapping does not name still
   answers `other`; `unowned` (no owner named) and `unresolved` (no identity to compare
   against) are untouched; the ticket-only `todo/<user-slug>/` tolerance tier is untouched.
   An absent mapping file must leave every answer byte-identical to today's.
4. Record in `owns.sh`'s header **why this is not the change `refuse-ok-under-a-placeholder-identity`
   scoped out**. That mission is right about its case — a container holding
   `noreply@anthropic.com`, a placeholder, against which no comparison should answer `mine`.
   This is a different case: a real identity, a present mapping, and a second address of the
   same person. Say so out loud; a later reader finding the two statements must not have to
   guess which one is stale.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An artifact owned by a mapped alias of the runner's address answers `mine`.
- An artifact owned by an address the mapping does not name answers `other`.
- `unowned`, `unresolved` and the `todo/<user-slug>/` tolerance tier answer exactly as today.
- With no mapping file present, every answer is byte-identical to today's.
- A placeholder identity (`noreply@anthropic.com`) gains no new way to answer `mine`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case per criterion, including the
  no-mapping-file byte-identity case and the placeholder case.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The header note naming the `refuse-ok-under-a-placeholder-identity` boundary is present.

## Considerations

- **This is the ticket that could loosen the 2026-08-14 strictness, and it must not.** That
  incident — ~10 PR-units driven out of colleagues' queues — is why `other` is conservative.
  The loosening here is bounded by the committed mapping: only addresses one entry names for
  one login become one person, and a colleague's address appears in no entry of the runner's.
  Prove the negative case (an unknown address still `other`) as explicitly as the positive one.
- A mapping entry is a claim that two addresses are one person, and anyone who can commit can
  make it. That is the same trust boundary the file already carries for `<login>=<email>`, so
  the change adds no new authority — worth stating in the header rather than discovering later.

## Final Report

Development completed as planned.

**Reproduced first**: with the committed mapping in place, `owns.sh` answered `other` for an
artifact owned by a mapped alias of the runner's own address — one line of output, and the
whole defect.

Both sides are now canonicalised through `identity.sh` before the existing slug comparison,
which is the smallest change that could work: the comparison itself did not move, so every
other answer is exactly where it was. The negative cases are pinned as explicitly as the
positive one — an address the mapping does not name still answers `other`, `unowned` and
`unresolved` are untouched, the ticket-only `todo/<user-slug>/` tolerance tier is untouched,
and with **no mapping file present** every answer is byte-identical to what it was, because
`identity.sh` is the identity function there.

Step 4's header note is in place. `refuse-ok-under-a-placeholder-identity`'s `## Scope` was
read whole first: it is right about its own case — a container holding `noreply@anthropic.com`,
a placeholder, against which no comparison should answer `mine` — and this is a different case,
a real identity with a present mapping entry and a second address of the same person. A
placeholder gains no new way to answer `mine` here, because a placeholder appears in no entry,
and that is asserted rather than argued.

### Discovered Insights

- **Insight**: the loosening is bounded by the committed file rather than by a rule, which is
  what keeps the 2026-08-14 strictness intact. Only addresses **one entry** names for **one
  login** become one person, and a colleague's address appears in no entry of the runner's.
  **Context**: this is the ticket that could have re-opened the incident where ~10 PR-units
  were driven out of colleagues' queues. It cannot, because the widening is per-entry data a
  human commits rather than a heuristic the oracle applies.

- **Insight**: a mapping entry is a claim that two addresses are one person, and anyone who can
  commit can make it — the same trust boundary the file already carried for `<login>=<email>`.
  **Context**: the second field widens what one entry can *say*, not who may say it, which is
  why it needed no new authorization anywhere and is worth stating in the header rather than
  being rediscovered as a question later.
