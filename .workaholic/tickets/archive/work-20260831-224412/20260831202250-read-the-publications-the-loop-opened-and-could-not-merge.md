---
created_at: 2026-08-31T20:22:50+00:00
status: done
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

## Final Report

Development completed as planned. `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh`
is the reader, and it acts on nothing, decides nothing and writes nothing.

**Membership is three derived terms**, each read from the tree or the pull request and never
from a title: the head branch is a `work-YYYYMMDD-HHMMSS` branch; the claim oracle names no
claim on it (**composed** from `list-claims.sh`, never a second reading of the claim commit);
and the publish seam's own refusal word is empty. The third term is the boundary the ticket
asked to be decided here rather than by the acting ticket: a `strategy_touching` or
`ruling_touching` publication is open **on purpose** and is `list-operator-facing-pulls.sh`'s
subject, so reporting it here would ask two people about one pull request. The adapter that
normalises `GET /pulls/{n}/files` into what `publication-refusal.sh` reads is kept identical to
that script's, deliberately — one rule, two readings of it.

**Nothing is re-derived.** The mergeability verdict, its reason and its
`mergeability_content_files` are `claim-mergeability.sh`'s own words, carried through
unchanged; the gate refusing a second mergeability derivation holds.

**Degradation is by name with a null count** (`jq_unavailable`, `no_refusal_rule`,
`no_claim_reader`, `claim_scan_unreadable`, `shallow_history`, `gh_unavailable`,
`list_failed`, `no_base`), and `ok: false` carries **no `publications` key at all** rather than
an empty one. A shallow scan is its own refusal: across a graft boundary a claim branch is
indistinguishable from a publication, so a truncated history would silently promote somebody's
claim into a list handed to an act that must never touch one. Exit 0 on every path.

The cap is spent on **candidates** rather than on every open pull request — the per-pull read
is what costs — and `truncated` is reported against the candidate count, so a busy repository
is never silently half-read.

**Verified**: `node scripts/test-workflow-scripts.mjs`, whose new hermetic row
(`branching/list-stranded-publications.sh: what the loop opened and could not merge`) drives
four pull requests through the reader — a stranded publication, a claim, an operator-facing
publication and a non-`work-*` head — and asserts the mergeability matches what
`claim-mergeability.sh` answers for the same branch, that a degraded read carries its reason
and a null count, and that the checkout is byte-identical afterwards.

### Discovered Insights

- **Insight**: `list-operator-facing-pulls.sh` and `list-open-rulings.sh` derive membership
  differently **on purpose** — the seam's refusal word for a reading, the title for a brake —
  and each header says why.
  **Context**: a new reader has to pick one and say which. This is a reading, so it follows
  the first; a title-keyed membership here would have lost every proposal a person retitled
  and gained every one that merely looks like a proposal.
- **Insight**: composing `list-claims.sh` for the "is this a claim?" term costs nothing extra
  and buys the shallow-history refusal for free.
  **Context**: the alternative — re-reading the claim commit subject here — would have been
  two lines of `git log` and a second copy of the two accepted claim-commit forms, which is
  exactly the drift `lib/claims.sh` exists to prevent.
