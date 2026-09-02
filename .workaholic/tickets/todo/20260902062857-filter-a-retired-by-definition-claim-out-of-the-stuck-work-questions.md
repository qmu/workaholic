---
created_at: 2026-09-02T06:28:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: retire-a-claim-whose-work-is-finished-or-abandoned
merge_policy:
verification_handoff: 
---

# Filter a retired-by-definition claim out of the stuck-work questions

## Overview

PROPOSED. The measured defect: the branch behind a closed pull request was reported as
stuck work every hour until a person deleted it. `step-stalled-units.sh` filters exactly
two verdicts — `superseded` and `awaiting_verification` — and a claim the retirement path
already owns is not one of them, so the tick asks a person about work it is itself
retiring. Filter and count it, exactly as those two are filtered and counted.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — the filter and the
  summary that counts what it filtered.
- `plugins/workaholic/skills/moderate/scripts/step-catchup-blocked.sh` — the same question
  on a `content` conflict; a retired-by-definition claim must not reach it either.
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the reader that says
  which claims the retirement path owns; composed, never re-derived.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — each step's own spec.
- `CLAUDE.md` — the *one step asks and the other filters* rule, which this extends.

## Implementation Steps

1. **Reproduce and localize first.** Take the measured case — a claim whose pull request is
   closed unmerged — and show which step composed the question, from which rows, and that no
   expression subtracted it. Name the two verdicts that are subtracted today.
2. Subtract, in the same expression the existing two use: a candidate the retirement reader
   names is not a stuck-work candidate. Compose `list-retirable-claims.sh` rather than
   re-deriving the closed / merged / mission-not-active terms in the step.
3. Count what was subtracted in the step's own `summary`, beside the existing
   `n_finished` / `n_declared` counts — filtered is never dropped, and the count is how a
   reader sees it happened.
4. Apply the same subtraction in `step-catchup-blocked.sh`: a conflict on a claim that is
   being retired is not a person's to resolve.
5. **An unreadable retirement read filters nothing.** A gate that cannot be read is not a
   gate, so the question still fires and the step reports the degraded read by name — an
   over-eager question beats a silently dropped one.
6. Rewrite both steps' specs in `moderate/reference/workflow.md`, and state the widened rule
   in `CLAUDE.md`, in the same commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A claim named by the retirement reader raises no `stalled-unit` and no
  `catchup-blocked` question, and is counted in that step's summary instead.
- A stale claim the retirement reader does not name still raises its question, unchanged.
- An unreadable retirement read leaves every question standing and is reported by name.
- The step's summary carries no age and no timestamp.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic cases in `scripts/test-workflow-scripts.mjs`, one per criterion.
- The offline drill for the moderation steps, extended to cover the filtered case.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

## Considerations

- The operator also asks that a question asking a person to do the tick's own job never be
  posted. The conflict half of that is already queued on
  `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`; this ticket covers only the
  claims that are retired by definition, and must not re-implement that one.
- Filtering is not silence: every subtraction is counted where the step already reports.
