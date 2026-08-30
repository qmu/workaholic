---
created_at: 2026-08-30T04:28:03+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Read which reported claims are catchable

## Overview

PROPOSED. `catch-up-claim.sh` carries no delivery-verdict gate of its own; the only
reason it never sees a `queue_drained` claim is that its one caller is `/implement`'s
`undelivered[]` loop. This ticket supplies the reader that widens the candidate set
without touching the writer.

It **composes `list-claims.sh`** — one walk of the refs, never a second oracle. A
reader that re-derived `mergeability` or re-scanned the refs would be the second
derivation the claim protocol refuses by name everywhere else, and the two answers
would drift the first time either changed.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` — new
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the shape to
  follow: composes `list-claims.sh`, resolves through the live-row rule, yields no
  candidates **and its reason** on a degraded scan
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_unit_resolution`
  / `claims_unit_row`, the live-row rule
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the one oracle

## Implementation Steps

1. Write `list-catchable-claims.sh` composing `list-claims.sh`: answer this
   identity's **reported** claims (`report_undelivered` **or** `queue_drained`) whose
   `mergeability` is **`mechanical`** and whose pull request is open.
2. Resolve each unit through `lib/claims.sh`'s **live-row rule**, never first-match —
   a unit held by a superseded branch and a live one must resolve to the live one.
3. A **degraded** scan yields **no candidates and its reason**, with null counts —
   never a bare empty set, which is byte-identical to a healthy quiet run.
4. Pure read: no branch, no worktree, no claim touched, no write anywhere; exit 0 on
   every path.
5. Do not re-derive `mergeability`, the resume reason, or the refs walk. Everything
   comes off the row `list-claims.sh` already renders.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `queue_drained` + `mechanical` claim of this identity is a candidate
- A `content`, `clean`, `unanswerable`, foreign or non-reported claim is not
- A degraded scan yields no candidates, a named reason and null counts
- The script writes nothing and exits 0 on every path

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` against the
  fixture the mission's drill ticket builds
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `list-claims.sh`, `claim-mergeability.sh` and `lib/claims.sh` byte-identical

## Considerations

- A `clean` claim is deliberately **not** a candidate: there is nothing to catch up,
  and `catch-up-claim.sh` would report `already_current`. Filtering here keeps the
  run from spending a worktree per tick to learn nothing.
- Whether the open-pull-request term costs a lookup per candidate is worth measuring:
  if the row already carries enough to answer it, read it there rather than adding a
  call the retirement reader had to bound.
