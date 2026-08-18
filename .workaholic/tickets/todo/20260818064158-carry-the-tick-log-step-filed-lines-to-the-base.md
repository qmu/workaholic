---
created_at: 2026-08-18T06:41:58+00:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [20260818064140-the-tick-log-s-step-filed-lines-can-never-reach-the-base]
merge_policy:
verification_handoff: 
---

# Carry the tick log step-filed lines to the base

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`workaholic:housekeep` requires the agent to record what it filed under a second, distinct
step id — `<step>-filed` — and names `log-read.sh` as the reader a later tick consults to
answer *"did an earlier tick already file this?"*. **Those lines cannot reach the base**, so
in a routine-fired container that memory is permanently empty.

Measured on tick `20260818-063819`: `run.sh` runs `persist-log.sh` as its closing act, after
the ninth step. The agent acts on `needs_agent` only *after* `run.sh` returns, so every
`<step>-filed` line is appended to the checkout **after** the persist ran. A second,
hand-run `persist-log.sh` does not carry them either — the union is **by section**, adding
only the `## <tick-id>` sections the base is missing, so it returned `already_current` /
`sections: 0` / `changed: false`. Correct by its own rule, and structurally unable to update
a section that has already landed.

A hand-run never sees this because its checkout survives. An hourly routine is cloned fresh
from the base, so it reads a log carrying probe lines and nothing else, and three dedups the
design leans on are inert: `doc-drift` re-reports `.workaholic/terms/retired-terms.md` every
hour forever (the exact case its own section says dedup exists for), `inbound-sweep` cannot
skip an item an earlier tick filed, and `human-checkin`'s `already_asked` gate and its
`human-checkin-held-<slug>` carry-forward are written after the persist too.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — an unattended run's audit trail is its only evidence
- `workaholic:implementation` / `policies/test.md` — the regression must fail before the fix and pass after

## Key Files

- `plugins/workaholic/skills/housekeep/scripts/persist-log.sh` — the union-by-section rule and
  the retry loop; its header carries the concurrency reasoning any change must answer to.
- `plugins/workaholic/skills/housekeep/scripts/run.sh` — owns the closing act's position in the run.
- `plugins/workaholic/skills/housekeep/scripts/log-read.sh` — the dedup reader whose answers this fixes.
- `plugins/workaholic/skills/housekeep/SKILL.md` and `reference/workflow.md` — state the contract
  that is currently unmet; both are updated in the same change.
- `plugins/workaholic/rules/workaholic.md` and `CLAUDE.md` — describe the closing act.
- `scripts/test-workflow-scripts.mjs` — where the regression test lands.

## Implementation Steps

1. **Reproduce first.** In a throwaway repo with an origin: run a tick, append a
   `<step>-filed` line, re-run `persist-log.sh`, and assert the base's section still lacks
   that line. That failing assertion is the deliverable of this step.
2. **Choose the fork** from the feedback record's three (see Considerations) and record the
   choice and its reasoning in the script header beside the existing concurrency rationale.
3. **Implement it**, keeping every property the current design bought: the caller's checkout
   byte-identical, no `work-*` branch, no `publish-main` ref on origin, no merge, and
   append-only conflict resolution between two containers ticking on the same UTC day.
4. **Prove the concurrency property still holds** — two checkouts appending different
   sections *and* different lines within a shared section both land, with neither lost.
5. **Update the documentation in the same commit** — `SKILL.md`, `reference/workflow.md`,
   `rules/workaholic.md`, `CLAUDE.md` — so the described closing act matches the built one.
6. **Regenerate `outputs/`** (`node scripts/build-plugins/build.mjs`) — housekeep scripts are
   in the portable bundle's closure.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `<step>-filed` line appended after `run.sh` returns reaches the base within the same tick.
- Two containers appending to the same UTC day both land — sections *and* lines within a
  shared section — with nothing lost and no rebase involved.
- The caller's checkout is byte-identical after the run, no `work-*` branch is created, and
  no `publish-main` ref reaches origin.
- A persist that does not reach the base is still reported `degraded` by name, with the log
  left in the checkout for the next tick.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — carrying the new hermetic case from step 1 and
  the two-checkout concurrency case from step 4.
- `sh scripts/e2e/loop-drill.sh verify-housekeep` — the end-to-end drill.
- `git status --porcelain` empty and `git branch -a` unchanged after a tick.

**Gate** — what must pass before approval:

- The step-1 assertion fails before the change and passes after it.
- `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` pass; `outputs/` has no diff.
- The chosen fork's reasoning is written into `persist-log.sh`'s header, answering the
  rejected alternatives rather than dropping them.

## Considerations

- **The fork is open and belongs to the operator.** The feedback record names three, and
  none is obviously right: (1) persist twice, which needs the union to update an existing
  section; (2) union by `(tick, step)` rather than by `(tick)` — strictly more correct,
  strictly more code, and it does not reintroduce the refused rebase; (3) move the agent's
  filing before the persist, which restructures the run contract so `run.sh` no longer owns
  its own closing act. Whoever drives this states the choice before writing it.
- **The concurrency rule is load-bearing.** `persist-log.sh`'s header records why the union
  is a union and not a rebase, and why a pull-request-per-tick was refused. A change that
  quietly reverts either is worse than the defect.
- **The defect is invisible to a hand-run**, so the regression test must be hermetic and must
  model the discard: assert against the *base*, never against the checkout.
- **Adjacent, smaller, and in scope if it is cheap**: `feedback/scripts/create.sh`'s usage
  header lists `development` as a valid `source` while the validator accepts only
  `meeting|slack|discussion`. Found while filing the record above, which had to be filed as
  `discussion`. Header and `case` are one file apart and disagree.
