---
created_at: 2026-09-21T18:04:18+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
mission: hold-operator-deferred-tickets-out-of-the-offer-and-say-so
depends_on: [20260921180418-declare-an-operator-deferral-on-a-queued-ticket.md]
feedback: []
merge_policy:
verification_handoff: 
---

# Name a deferred ticket in the survey exclusions

## Overview

Make the survey hold the ticket and **say** it is holding it. This is the half the existing
`icebox` mechanism structurally cannot do, and the reason the ask exists.

**Measured, and it decides where the change goes.** `drive/scripts/list-todo.sh` filters
`done | abandoned | icebox` out of the queue walk itself, so such a ticket never reaches
`plan-units.sh`: it is never counted in `backlog_size`, never appears in `excluded[]`, and
`backlog_all_excluded` reads `excluded: false` because nothing was excluded. A queue emptied by
deferral is byte-identical to an empty queue — the exact collapse `backlog_all_excluded` was
built to end and `placeholder_identity` was added for a second time. So the deferral must be
read **at `plan-units.sh`'s exclusion seam**, where every other held artifact is already named,
and **not** in `list-todo.sh`'s filter, which is where invisibility comes from.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a held queue is named, never silent
- `workaholic:implementation` / `policies/error-handling.md` — a refusal is named, never silent

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey. The exclusion seam
  (`exclude ticket "$t" "<reason>"`) and the `backlog_all_excluded` derivation live here; its
  header states the rule that `excluded[]` names what the survey saw and dropped.
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` — the queue walk. Its end-state filter
  is where deferral must **not** go; read its header before touching it.
- The one reader added by the previous ticket — the only permitted parser of the declaration.
- `plugins/workaholic/skills/drive/SKILL.md` and `reference/routing.md` — the survey's contract
  and vocabulary.
- `CLAUDE.md` (*One executor, two commands*) — states the survey's exclusion vocabulary; update
  in the same change.

## Implementation Steps

1. **Reproduce the invisibility first.** In a throwaway tree, stamp a queued ticket
   `status: icebox` and run `plan-units.sh`; record that `backlog_size` does not count it, no
   `excluded[]` row names it, and `backlog_all_excluded` reads `excluded: false`. That reading
   is the defect and belongs in the branch story.
2. **Read the declaration at the exclusion seam**, through the previous ticket's one reader —
   never a second parse and never a filter inside `list-todo.sh`. The ticket is queued, so the
   walk must keep returning it.
3. **Give it its own exclusion reason.** A word of its own, not folded into an existing one:
   `excluded[]` reasons are read straight out of cron logs and collapsing two answers is what
   that vocabulary's header already forbids. Register the word wherever the survey's reasons are
   enumerated.
4. **Make `backlog_all_excluded` carry it.** Its `reasons[]` already counts per reason, so a
   queue held entirely by deferral must report `excluded: true` with that reason and its count —
   distinguishable from a queue emptied by claims and from one emptied by ownership.
5. **An unreadable declaration is not a deferral and not a pass.** Decide and state which of the
   survey's existing degraded readings it takes; it may not silently become *not deferred*.
6. **Removal is the only re-offer path.** Prove that a ticket whose declaration is removed is
   offered again on the next survey with no other act — no promotion script, no flag, no stored
   cursor. Prove also that nothing in the loop removes the declaration itself.
7. Update `SKILL.md`, `reference/routing.md` and `CLAUDE.md` in the same commit, and run the
   local proof set.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A queued, declared ticket is counted in `backlog_size`, absent from `backlog[]`, and present
  in `excluded[]` with its own reason.
- `backlog_all_excluded` reports `excluded: true` with that reason and its count when the whole
  queue is deferred.
- Removing the declaration makes the ticket claimable again on the next survey, with no other
  act; nothing in the loop removes it.
- `list-todo.sh`'s end-state filter is byte-identical, and a ticket carrying no declaration
  produces a byte-identical survey.
- The declaration is parsed at exactly one site.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node --test scripts/tests/agentic-loop/*.test.mjs`
- a throwaway-tree fixture asserting the four survey readings above, including the
  non-empty `reasons[]` row (an empty expected set proves nothing)
- `bash plugins/workaholic/skills/branching/scripts/local-proof.sh`

**Gate** — what must pass before approval:

- The local proof set reports `ok: true` with every `not_run` row named.
- The step 1 before/after survey readings appear in the branch story.

## Considerations

- **The reason word is a public vocabulary.** It is read from cron logs and from
  `backlog_all_excluded`'s counts, so it is chosen once and not renamed later.
- **`icebox` is deliberately not migrated here.** Whether existing `icebox` tickets should
  become deferrals is a separate judgement about parked history; this ticket changes the
  behaviour of the new key only and leaves the old one byte-identical.
- **Do not let this ticket also change allocation.** A deferred ticket being excluded and a
  deferred-only queue not consuming a runner are two readings at two layers; the second is the
  next ticket's, and folding them makes one change nobody can bisect.

## Final Report

Development completed as planned. `plan-units.sh` reads the declaration at the **exclusion seam** through
the previous ticket's one reader and excludes such a ticket `operator_deferred`; a declaration that reader
could not read is excluded `deferral_unreadable`. `list-todo.sh` is byte-identical.

Step 1's before/after, measured in a throwaway tree (`git init`, two queued tickets, no origin):

- **Before** — one free ticket and one carrying `status: icebox`:
  `{"backlog_size":1,"backlog":[".../20260921000001-free.md"],"excluded":[],"backlog_all_excluded":{"excluded":false,"backlog_size":1,"reasons":[]}}`
  The iceboxed ticket is not counted, no row names it, and the reading is byte-identical to a queue that
  simply holds one ticket. That is the defect, and it is why the change went to `plan-units.sh` rather
  than to `list-todo.sh`'s filter.
- **After** — the same tree plus one ticket carrying `deferred: 顧客の確認が返るまで着手しない`:
  `{"backlog_size":2,"backlog":[".../20260921000001-free.md"],"excluded":[{"kind":"ticket","id":".../20260921000003-deferred.md","reason":"operator_deferred"}]}`
  Counted, offered to nobody, named.
- **A deferred-only queue**:
  `backlog: []` with `backlog_all_excluded: {"excluded":true,"backlog_size":2,"reasons":[{"reason":"operator_deferred","count":2}]}`.
- **An unreadable declaration** (a bare `deferred:` planted by hand) joins as
  `{"reason":"deferral_unreadable","count":1}` beside it, never as `operator_deferred`.
- **Removal re-offers** with no other act: deleting the line returned the ticket to `backlog[]` on the
  very next survey, with `excluded[]` empty.

Step 5's decision, stated rather than left implicit: an unreadable declaration takes the survey's existing
**degraded** reading one layer up — `claimable-units.sh` answers `readable: false`, which falls back to one
runner. It sets no top-level trustworthiness field, so it does not forbid `ok` by itself; that table is
`drive/SKILL.md` §7's and belongs to one mission at a time. The cost is stated in the script header and in
`reference/survey.md`: such a ticket is named in every survey until it is repaired.

### Discovered Insights

- **Insight**: `backlog_all_excluded`'s per-reason counts are derived from whatever `excluded[]` carries,
  so a new exclusion reason is counted by construction and needs no edit there.
  **Context**: The genericity is deliberate (recorded in the script when `claimed_undelivered` was added);
  this ticket needed no change to that derivation at all, only a proof that it fires.
- **Insight**: The deferral check has to sit **after** the `mission_member` branch, not before it.
  **Context**: A mission member is driven inside its mission's unit, which `plan-units.sh` does not
  partition — reporting it `operator_deferred` would claim a hold the run does not honour. The
  consequence is stated as a limit in three places rather than hidden: a mission member's deferral is
  not read, and holding one member of a unit is `verification_handoff:`'s shape.
