---
created_at: 2026-08-29T19:21:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Ask the person who must act on an unanswered pull request

## Overview

PROPOSED. One `/moderate` step that hands every **un-acted operator-facing pull request**
to the check-in as a question addressed to the person the publication waits on, keyed so
it is asked exactly once, naming the pull request, its age and what merging it would
unblock. It **asks and nothing else**.

Measured 2026-08-29: #694 sat 18 hours unanswered, holding the `undrivable-unit:`
questions for the very addresses it names, while `plan-units.sh` offered nothing over a
backlog of 10. `stuck-prs` and `merge-conflicts` see the pull request and ask nobody;
every claim-side verdict is bounded to a claim and these publications carry none.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a finding reaches a named person
- `workaholic:design` / `policies/interaction-design.md` — one question, one act, asked once

## Key Files

- `plugins/workaholic/skills/moderate/scripts/run.sh` — the `STEPS` list the new step id
  joins; placement beside `undelivered-units` / `handoff-units`, the two steps this most
  resembles.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the closest
  precedent: a reading its step cannot act on, handed to the check-in per candidate.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate; the key, the
  per-tick cap, the day cap, the quiet hours and the working-day hold all apply unchanged.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the closed table
  classifying which findings `file-findings` may file; a new step id reads `needs_ruling`
  until classified deliberately.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post shapes.

## Implementation Steps

1. Write `moderate/scripts/step-<id>.sh` composing ticket 2's derivation for candidates
   and ticket 1's reader for each candidate's effect. It reads; it never merges, closes,
   comments on or gates anything.
2. Candidates are the operator-facing pull requests reading `open:<age>`. `merged` and
   `closed` are settled and draw nothing; `unreadable` **draws no question** and is named
   in the summary — `strategy-pace`'s rule that a person's attention is not spent on our
   own degradation.
3. Key each question `<step-id>:<pull-request number>` so one pull request costs exactly
   one question however many ticks see it, and address it to **the person the publication
   waits on** — resolved to an address through `gather/scripts/identity.sh`, with an
   unmapped login leaving it addressed to nobody rather than stamping an address nobody
   verified (`base-health`'s rule).
4. Supply an `event` only when there is a candidate, so a healthy hour renders no root
   line; the log-facing `summary` carries the per-row detail.
5. **Never reach `plan-units.sh`** — that survey stages what its living migrations
   converge, and this step writes nothing but its own log line (`run.sh` writes that).
6. Register the step id in `moderate/reference/workflow.md`'s classification table
   deliberately, and update `CLAUDE.md`'s step count and `/moderate` row in the same
   change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One question per un-acted operator-facing pull request, asked exactly once across ticks.
- Nothing is merged, closed, commented on, held or gated by the step.
- An `unreadable` reading asks nobody and is counted in the summary.
- A tick with no candidate supplies no `event` and renders no root line.
- The step reaches `plan-units.sh` nowhere.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Ticket 7's drill, over two ticks, showing the second asks nothing.
- `grep -n 'plan-units' plugins/workaholic/skills/moderate/scripts/step-<id>.sh` empty.

**Gate** — what must pass before approval:

- The suite passes, the step count in `CLAUDE.md` matches `run.sh`'s `STEPS`, and the
  classification table names the new step id.

## Considerations

- The rival design — one unified *what the loop is blocked on* report across the
  vocabularies — is refused by name in this repository twice over: a report addressed to
  nobody is what `🔧 Needs a decision` and `📦 Release Preparation` were retired for.
- The step must not double-ask a subject `standing-rulings` already covers; ticket 4 owns
  the interaction between this question and `ruling-suppression.sh`.
