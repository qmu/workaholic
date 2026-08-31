---
created_at: 2026-08-31T20:22:50+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: repair-a-mechanically-resolvable-conflict-instead-of-reporting-it
merge_policy:
verification_handoff: 
---

# Read the publications the loop opened and could not merge

## Overview

PROPOSED. A publish-tree publication is not a claim: it has no claim commit, no worktree
and no heartbeat, so `list-claims.sh` gives it no resume verdict and
`list-catchable-claims.sh` — whose candidates are `report_undelivered` or `queue_drained`
claims — can never offer it. A proposal whose auto-merge was refused therefore has no reader
anywhere in the loop, which is why the measured three sat open. This ticket adds the reader
and nothing else: it acts on nothing, decides nothing and writes nothing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/` — where the reader belongs, beside the seam
  that opens the publication (`publish-tree-pr.sh`) and `publication-effect.sh`, which already
  reads a publication back.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — composed, never re-derived;
  a second mergeability derivation is what the claim protocol refuses by name.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport.

## Implementation Steps

1. Take the seam this ticket's predecessor localized. Add one reader — name it for what it
   answers, e.g. `list-stranded-publications.sh` — returning one row per open pull request
   the loop opened on a `work-*` branch that carries no claim commit: the number, the branch,
   the age, and the `mergeability` read **through `claim-mergeability.sh`**, verbatim.
2. Compose, never re-derive: the mergeability verdict, its reason and its
   `mergeability_content_files` are that script's words, carried through unchanged.
3. Degrade by name, never into an empty set: `{"ok": false, "reason": ...}` with **null**
   counts for an unreadable remote, an unavailable transport or a shallow scan — a quiet
   healthy read and a scan that reached nothing must not be byte-identical.
4. Exit 0 in every case. It is a pure read: no ref, no worktree, no index, no write.
5. Keep it out of the claim vocabulary. It emits no claim verdict word and adds no row to
   `drive/reference/claims.md`, because a publication is not a claim and one vocabulary
   answering two questions is how the two drift.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader returns a publication the loop opened and could not merge, with a mergeability
  verdict identical to what `claim-mergeability.sh` answers for the same branch.
- A branch holding a claim commit is never returned.
- A degraded read answers `ok: false` with its reason and null counts.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic row in `scripts/test-workflow-scripts.mjs` over a throwaway repository.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No second mergeability derivation anywhere in the diff.
- The reader writes nothing and calls no acting script.

## Considerations

- Membership must be derived from the tree and the pull request, never from a title: the
  title-keyed brake in `list-open-rulings.sh` is deliberate and local to it, while
  `list-operator-facing-pulls.sh` derives membership from the seam's own refusal word. Follow
  the second; a proposal title is prose.
- An operator-facing publication (`strategy_touching`, `ruling_touching`) is left open on
  purpose and must not be reported as stranded. Decide the boundary here and state it in the
  header, so the acting ticket inherits it rather than re-deciding it.
