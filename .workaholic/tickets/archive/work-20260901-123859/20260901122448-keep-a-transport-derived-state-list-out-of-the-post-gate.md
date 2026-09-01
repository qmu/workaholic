---
created_at: 2026-09-01T12:24:48+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Keep a transport-derived state list out of the post gate

## Overview

PROPOSED. The post gate is a `cmp` of `(step, status, stabilized summary)` against the previous
tick's, and `stabilize()` strips only ISO timestamps, bare hex object names and clock times.
`step-stuck-prs.sh` puts a per-pull `number:blocked_by` list into its summary, and `blocked_by`
carries GitHub's lazy mergeability answer — measured across nine consecutive ticks it read
`(403:unknown 407:unknown 409:unknown)` four times, then four pull requests, then one
conflicting, then five, then one with a failing check, while the repository did not move. That
is exactly the class of value the stabilizer exists to strip, so the gate built to stop hourly
noise is what produces it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — `stabilize()` and both `cmp` comparisons (the change diff and the impairment diff).
- `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh` — composes `$pairs` (`<number>:<blocked_by>`) into its summary and its headline.
- `plugins/workaholic/skills/moderate/scripts/pulls-state.sh` — where `blocked_by` is derived.

## Implementation Steps

1. **Reproduce before changing anything.** Take two `step-stuck-prs.sh` summaries that differ
   only in a `blocked_by` value and show the gate opens a root for the pair. Keep that as the
   failing case.
2. **Localize the volatility**: confirm the churn is in `blocked_by` values that GitHub
   recomputes (`unknown` above all), not in the set of pull requests. The distinction matters —
   a pull request appearing or disappearing **is** a repository change and must keep earning a
   root.
3. Fix it at the **summary**, not by widening `stabilize()`. A general scrub would hide real
   changes, which is the opposite defect and is why that function is a short named list. The
   summary should carry what moved in the repository — how many are stuck, and by what class —
   and leave the per-pull state list to the `headline` and `needs_agent`, which drive the
   questions and are not compared.
4. Keep the **question** side byte-identical: `ask_key`, `headline` and `needs_agent` still
   carry each pull request and its `blocked_by`, so nothing a person is asked loses detail.
5. Show the failing case from step 1 now posts nothing, and that a pull request entering or
   leaving the stuck set still opens a root.
6. Pin both directions in `scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two ticks differing only in a `blocked_by` value produce no root.
- A pull request entering or leaving the stuck set produces a root.
- The question this step asks still names each pull request and why it is stuck.
- `stabilize()` is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the two rows above.
- `step-stuck-prs.sh` run against fixtures for both cases.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **Do not widen `stabilize()`** to strip the pair list. That function's own header says the
  list is short and named on purpose; a regex broad enough to catch `403:unknown` would also
  catch counts and identifiers that are real news. The volatility belongs to one step's
  summary and is fixed there.
- The related, already-achieved mission
  `settle-a-mergeability-reading-before-it-becomes-a-question` re-reads an `unknown` before
  reporting it, which removes the loudest source of this churn but not the class: `behind`,
  `conflict` and `checks` still flip between reads without the repository moving. Verify what
  that mission landed before assuming the measurement still reproduces exactly, and report
  what it actually reproduces.
- Coarsening the summary loses per-pull detail **from the gate only**; if a reviewer wants
  that detail in the root, the answer is the delta reply's body, not the compared string.
