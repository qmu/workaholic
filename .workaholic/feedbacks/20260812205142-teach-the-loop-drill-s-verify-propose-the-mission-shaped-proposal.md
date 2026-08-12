---
type: Feedback
title: Teach the loop drill's verify-propose the mission-shaped proposal
kind: instruction
source: discussion
created_at: 2026-08-12T20:51:42+00:00
author: a@qmu.jp
supersedes: 
---

# Teach the loop drill's verify-propose the mission-shaped proposal

Source: https://github.com/qmu/workaholic/issues/409 (filed from the first live loop drill, 20260812T204551Z)

Measured 2026-08-12 20:47 UTC, first live run of `scripts/e2e/loop-drill.sh verify-propose`
(issue #406): the proposal PR #407 emitted the **mission form** — the record, a mission whose
frontmatter names the record in `feedback:`, and two tickets carrying `mission: <slug>` — and
the verifier still reported `ticket_feedback_ref` and `ticket_assignee` as failed load-bearing
rows, verdict `fail`.

The rows assume the **loose-ticket shape only**: a ticket under `.workaholic/tickets/` naming
the record stem in `feedback:`. A mission-shaped proposal satisfies the same chain indirectly
(record → `mission.feedback` → `ticket.mission`), so the verdict called a passing stage broken.

Reproduce first: run `verify-propose 406` against `main` as of `ccb043c` or later and observe
the two false rows while PR #407 shows the mission, its two tickets, and the merged
`Closes #406`.

Then make `verify-propose` accept both emission forms: when no loose ticket names the stem,
look for an active mission whose `feedback:` names the record, and follow it to tickets
carrying `mission: <slug>`; the assignee row then checks those tickets. A record-alone
judgment should stay a distinct row (`proposal_form: record_alone`) rather than a failure,
since the judgment bar legitimately selects it. Keep the hermetic row-shape tests in
`scripts/test-workflow-scripts.mjs` in step.
