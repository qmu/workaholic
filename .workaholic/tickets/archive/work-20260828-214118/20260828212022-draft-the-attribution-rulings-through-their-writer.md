---
created_at: 2026-08-28T21:20:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Draft the attribution rulings through their writer

## Overview

PROPOSED. Turn each judged attribution into a diff, through the writer that already owns
that line. `carry-attribution.sh` fires today only when the operator announces a pair by
explicit slug through `/specificate`; this reaches the same writer with the same bounds,
and it is still the operator's merge that makes the ruling.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/carry-attribution.sh` — the one writer of a
  mission's carried `feedback:` line; **unchanged by this ticket**
- `plugins/workaholic/skills/branching/scripts/open-publish-tree.sh` — where the drafting
  happens, so the caller's checkout stays byte-identical
- `plugins/workaholic/skills/moderate/scripts/` — the drafting caller (new script, the
  step's act)
- `scripts/test-workflow-scripts.mjs` — pins the writer set and the refusal behaviour

## Implementation Steps

1. Open a publish tree (`open-publish-tree.sh`) and run
   `carry-attribution.sh <strategy> <mission>` **once per judged mission** inside it.
2. **`carry-attribution.sh` is not modified.** It stays the one writer of that line, it
   still appends only refs the named strategy already cites, it removes none, and it never
   touches the strategy file — the artifact keeps its three writers.
3. Honour its refusals exactly as they are today — `strategy_not_found`,
   `mission_not_found`, `not_active`, `no_revision`, `immutable_field` — writing **nothing**
   on any of them, and report each by name.
4. A mission already carrying the ref is left **byte-identical** and reports `already`,
   which is a success and not a refusal.
5. An `undecided` candidate from the previous ticket is **skipped**, never drafted.
6. Cover in the suite: one judged mission drafts one appended ref; a re-run is a
   byte-identical no-op; each refusal leaves the tree untouched.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every attribution draft goes through `carry-attribution.sh` and no other path.
- A refusal writes nothing and is reported by its own name.
- A re-run over an already-carried mission leaves it byte-identical.
- No `undecided` candidate is written.
- The strategy artifact's writer set is unchanged at `create.sh`/`amend.sh`/`close.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `git diff` over the publish tree after a re-run, asserting empty.

**Gate** — what must pass before approval:

- The suite's existing writer-set pin still passes unchanged.

## Considerations

- The drafting caller runs in a publish tree rather than the checkout, exactly as every
  other artifact writer in this repository does: the claim protocol owns `work-*` branches
  and nothing here may push into one.

## Final Report

Development completed as planned.

`moderate/scripts/draft-standing-rulings.sh` opens a publish tree, reads the candidate set
**inside** it (so the rulings are derived from the base the pull request will be opened
against), runs `carry-attribution.sh <strategy> <mission>` once per **judged** mission, and
lands the result through `publish-tree-pr.sh`. `carry-attribution.sh` is unmodified — still
the one writer of that line, still appending only refs the named strategy already cites,
still touching no strategy file. Every one of its refusals is reported by name and writes
nothing; `already` is reported as a success; an `undecided` candidate reaches no writer.
The pull request opens and does not merge — the seam's `ruling_touching`, proved with
`WORKAHOLIC_AUTO_MERGE=1` deliberately set in the fixture.

### Discovered Insights

- **Insight**: `publish-tree-pr.sh` must be invoked from the **caller's** checkout, not from
  inside the publish tree: it resolves `.publish/` from the repository root, and inside that
  tree the root *is* the tree, so it answers `no_publish_tree`. `carry-attribution.sh` is the
  opposite — it `git add`s the mission file, so it must run with the publish tree as cwd.
  **Context**: the two halves of one act have opposite working-directory requirements.
- **Insight**: `carry-attribution.sh`'s header asserted that the seam could not see an
  attribution carry. That is now false and is superseded in place: the seam derives
  `ruling_touching` from the shape of the change, and step 9e's caller-side rule survives as
  a second guard rather than the only one.
  **Context**: three documents carried that same claim; all three moved.
