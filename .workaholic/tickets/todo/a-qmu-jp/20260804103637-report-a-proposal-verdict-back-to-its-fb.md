---
created_at: 2026-08-04T10:36:37+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-an-fb-reach-a-reviewable-proposal
merge_policy:
---

# Report a proposal verdict back to its FB

## Overview

Silence is a valid and deliberate outcome of the proposal batch — the
conservative bar exists precisely so a false positive does not spam the
channel. But silence is currently *unattributable*: nothing tells the person
who filed an FB whether it was judged not worth proposing, or simply never
looked at. From outside, "considered and declined" and "the batch never ran"
are the same observation, which is exactly the confusion that let a broken
`/propose` go unnoticed while feedback accumulated.

Close the loop: every FB that enters the window leaves it with a stated
outcome — a proposal pull request, or a recorded reason there was none.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/observability.md` — a process states its own outcome

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — the judgment bar and the
  "silence is valid" contract this ticket qualifies
- `plugins/workaholic/skills/propose/scripts/notify-slack.sh` — the existing
  announcement seam
- `plugins/workaholic/skills/workaholify/routines/propose.md` — the routine
  added by the sibling ticket; the reporting rule belongs in its prompt
- `plugins/workaholic/skills/feedback/SKILL.md` — the stream whose immutability
  constrains where a verdict may be written

## Implementation Steps

1. Decide where a verdict lives, and record the reason. The feedback stream is
   immutable, so a verdict is **not** an edit to the record. The candidates are
   the FB issue (durable, addressable, already the FB's identity) and the Slack
   thread (where the developer is). Prefer the issue as the record and the
   thread as the notification.
2. Define the verdict vocabulary narrowly: `proposed` with its PR link, or
   `declined` with the bar clause that excluded it (already-covered, restates an
   active mission, not actionable, concern-only).
3. Emit the verdict from the batch, once per FB, keyed so a re-run never
   double-reports — the same idempotency the duplicate-firing observation on
   #192 calls for.
4. Keep it non-load-bearing: a failed report must never fail or retry the
   proposal itself, matching how `claim.sh` treats its Slack announcement.
5. State in `propose/SKILL.md` that silence toward the *channel* is still valid
   while silence toward the *FB* is not — they are different audiences.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every FB entering the window leaves with exactly one recorded verdict
- A declined FB names the bar clause that excluded it
- A re-run over the same window emits no second verdict for an FB already
  carrying one
- A failed verdict report leaves the proposal and its PR intact

**Verification method** — the commands/tests/probes that prove them:

- A hermetic test asserting one verdict per FB across two consecutive runs
- A fault-injection case with the notifier failing, asserting the proposal
  still completes
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The chosen verdict location is recorded with its reason, since it determines
  whether the FB lifecycle is addressable later

## Considerations

- This ticket assumes the sibling routine ticket has settled the trigger. If
  the routine is schedule-driven rather than FB-driven, "every FB entering the
  window" needs a definition of which FB a batched proposal answers — possibly
  several, which the verdict format must allow.
- Reporting into the FB issue makes the verdict durable but does not put it
  where the developer is looking; reporting only to Slack inverts that. Doing
  both is the likely answer, but the record should be one of them, not two
  sources that can disagree.
