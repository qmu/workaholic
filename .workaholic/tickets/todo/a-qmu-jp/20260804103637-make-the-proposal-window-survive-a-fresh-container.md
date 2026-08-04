---
created_at: 2026-08-04T10:36:37+00:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-an-fb-reach-a-reviewable-proposal
merge_policy:
---

# Make the proposal window survive a fresh container

## Overview

`/propose` selects its work window from `.workaholic/proposal-cursor`, which is
**runner-local and git-ignored**. `cursor.sh read` bootstraps an absent cursor
to `origin/main` HEAD and reports `initialized: true`, deliberately treating all
pre-existing feedback as already-seen — documented as "a safe cold start".

That is safe on the long-lived server decision C1 assumed. It is fatal on
Claude Code Web routines, where **every session is a fresh container with no
cursor file** (confirmed: none exists in a live routine container). Each run
would bootstrap to HEAD, observe zero new feedback, and stay silent — forever,
and indistinguishably from a healthy quiet tick. The cold start is not a
one-time cost; it is every run.

The window must be derivable from data that survives the container. The
repository already holds it: a mission records the records it grew from in its
`feedback:` frontmatter, so "merged but not yet proposed from" is computable by
difference — which is also how dedup already works.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/resilience.md` — a process that keeps working when its host does not

## Key Files

- `plugins/workaholic/skills/propose/scripts/cursor.sh` — the bootstrap-to-HEAD
  behavior being replaced or demoted
- `plugins/workaholic/skills/propose/scripts/new-feedback.sh` — the window
  reader that consumes the cursor
- `plugins/workaholic/skills/propose/scripts/list-proposed-refs.sh` — already
  reads every mission's `feedback:` refs; the durable half of the answer
- `plugins/workaholic/skills/propose/SKILL.md` — the cursor contract section
- `CLAUDE.md` — the `/propose` row describes the runner-local cursor

## Implementation Steps

1. Reproduce first, so the fix is measured and not assumed: in a checkout with
   no `proposal-cursor`, run the window reader and record that it returns zero
   new records while unproposed feedback demonstrably exists on `main`.
2. Derive the candidate set from the repository instead of local state:
   feedback records on `main` minus those already named by some mission's
   `feedback:` list (`list-proposed-refs.sh`).
3. Keep the cursor only as an optimization if it still earns its place — never
   as the source of truth — and make an absent cursor mean "consider
   everything unproposed", not "consider nothing".
4. Bound the resulting window so a first run does not propose against the
   entire history: cap by age or count, and **report what was excluded and
   why** rather than truncating silently.
5. Update the SKILL.md cursor contract and CLAUDE.md to describe the durable
   rule, including why the old cold start was wrong for ephemeral runners.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With no cursor file present, the batch still sees feedback merged before the
  container existed
- A record already named by a mission's `feedback:` list is not re-proposed
- Any bound applied to the window is reported, not silently applied

**Verification method** — the commands/tests/probes that prove them:

- A hermetic test in `scripts/test-workflow-scripts.mjs` that builds a repo with
  unproposed feedback, deletes any cursor, and asserts the window is non-empty
- A second case asserting an already-referenced record is excluded
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The reproduction in step 1 is recorded with its raw output, so the defect is
  demonstrated rather than argued

## Considerations

- Deriving the window from missions couples proposal selection to mission
  frontmatter. That coupling already exists for dedup, so this concentrates an
  existing dependency rather than adding one — worth stating explicitly.
- A first run against a large backlog is the risky case. Prefer a conservative
  bound plus a report over an unbounded sweep; the judgment bar is what keeps
  the output small, but the bar should not be asked to read 392 records at once.
