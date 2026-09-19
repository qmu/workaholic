---
created_at: 2026-09-19T09:51:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-one-coherent-feedback-batch-one-mission-one-pull-request-one-report
merge_policy:
verification_handoff:
---

# Make a shared feedback thread grounds for one PR-unit

## Overview

Operator's ask: **issue #1110**, items 1 and 7 — *do not equate a ticket boundary with a
pull-request boundary; a bounded PR-unit may contain multiple tickets when they share one review
surface, one feedback thread and one coherent acceptance walk* … *progress posts can still
enumerate each linked issue, but should point to the shared outcome rather than one lifecycle
message per tiny unit.* Measured: nine loose tickets from one thread driven through four separate
implementation pull requests.

**Established in this tree.** `workaholic:drive` §2 already permits grouping: *related backlog
tickets group into one batch unit — conservatively, on a reason statable in one sentence;
`depends_on` alone is grounds.* And `plan-units.sh` deliberately supplies no heuristic, with its
reason in its own header (lines 42-54): *what deserves one merge is judgment … a script that
guessed at relatedness would make the conservative "when unsure, one ticket per unit" bar
unreachable.* That division is right and this ticket does not touch it.

**What is missing is a second statable reason.** `depends_on` is the only named grounds, so a
batch of nine corrections that share a thread and a screen but declare no dependency falls to the
conservative default — one ticket per unit — which is exactly the shape the ask rejects. A shared
`feedback:` ref is a **fact on the artifacts**, not a guess: it is written by one writer
(`feedback/scripts/ask-feedback-line.sh`), read by one reader
(`specificate/scripts/read-feedback-relation.sh`), and already used by `unit-feedback-stems.sh` to
decide which thread a unit's posts land in. So naming it as grounds adds no heuristic and no
inference.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — the partition is reported in full,
  and the grounds each group was formed on are named
- `workaholic:implementation` / `policies/test.md` — the reported grounds are pinned hermetically

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` (§2, *Partition into PR-units*) — the one place the
  grouping bar is stated; the new grounds is named here.
- `plugins/workaholic/skills/drive/reference/routing.md` — the longer form of the same rule,
  including `depends_on`; both must carry one wording.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` (lines 42-54) — the header stating why
  no heuristic lives in the script. It must stay true; read it before touching anything here.
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — already resolves a unit's
  `feedback:` stems; the grouping reads the same relation through the same reader.
- `plugins/workaholic/skills/specificate/scripts/read-feedback-relation.sh` — the one reader of
  the relation. No second parser (its own header forbids it).
- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — the finish-line
  shapes; the ask's item 7 lands here.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Reproduce the bar.** Read `/drive` §2, `reference/routing.md` and `plan-units.sh`'s header in
   full, and record that `depends_on` is the only named grounds today.
2. **Name the second grounds in prose, at the two places the rule lives.** Tickets whose
   `feedback:` refs intersect — read through `read-feedback-relation.sh`, never re-parsed — are
   grounds for one batch unit, exactly as `depends_on` is. State the bound: **an intersection is
   grounds, not an obligation**; the executor may still split on a stated reason, and a batch that
   mixes merge policies is still never grouped to force a route.
3. **Keep the judgement out of the script.** `plan-units.sh` continues to report what is available
   and to name no grouping. If a shared ref must be *visible* to the executor to be usable, surface
   it as an annotation on the backlog rows — a fact, not a grouping — and say in the header that
   it is reported and never applied there.
4. **Report the grounds in the partition.** §2 already requires the partition to be reported in
   full; extend it so each group names the grounds it was formed on (`depends_on`, shared
   `feedback:` ref, or the one-sentence reason). A group with no statable grounds is still one
   ticket per unit.
5. **The notification follows the unit, which is the ask's item 7 and needs no new shape.** Once a
   batch is one unit it has one claim, one pull request and one finish line; confirm that
   `unit-feedback-stems.sh` resolves every member's thread and that the finish line enumerates the
   linked items while pointing at the shared pull request. Change a shape only if that reading
   shows a gap, and say which.
6. **Suite rows**: the two prose homes carry one wording; the partition report names grounds per
   group; `plan-units.sh`'s output for a fixture with intersecting refs is **byte-identical** to
   today's except for any annotation added in step 3; and a fixture whose tickets share no ref
   still partitions one per unit.
7. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A shared `feedback:` ref is named as grounds for one PR-unit in `/drive` §2 and in
  `reference/routing.md`, in one wording.
- `plan-units.sh` performs **no grouping**: its offer and every exclusion reason are unchanged,
  and any new field is an annotation the header names as reported-never-applied.
- The partition report names the grounds for each group.
- A batch mixing merge policies is still never grouped; `depends_on` still stands alone as grounds.
- No second parser of the `feedback:` relation is introduced.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and the new rows fail when reverted.
- `plan-units.sh` over a fixture with intersecting refs produces the same `backlog[]`, `excluded[]`
  and `missions[]` membership as before the change.
- A fixture unit grouped on a shared ref resolves every member's thread through
  `unit-feedback-stems.sh`.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- `plan-units.sh`'s header claim — that no grouping heuristic lives there — is still true after the
  change. A diff that moves judgement into the script does not pass.
- The suite is green and the bundle rebuild is diff-clean.
- POSIX `sh` throughout.

## Considerations

- **Grouping raises the cost of one failure.** A nine-ticket unit that fails late fails as one
  pull request. That is the trade the ask makes knowingly — it asks for the developer's review
  unit over mechanical atomicity — and the existing per-ticket archive and branch story keep the
  granularity available where it is still wanted.
- **An intersection can be coincidental.** Two unrelated tickets can both cite a broad direction's
  ref (the carry-forward puts a strategy's refs on everything it emits). The bound in step 2 is
  what keeps that from forcing a group, and the implementation should say so where the grounds is
  named — a shared *direction* ref is not a shared review batch.
- **Do not make the grounds a gate.** Requiring a group wherever refs intersect would be the
  mirror of the defect being fixed.
