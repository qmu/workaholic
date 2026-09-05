---
created_at: 2026-09-06T02:29:07+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: The ask requires a live run in the operator's own originating Codex chat: start work there, keep a delegated task running past ten minutes, and record at least two successive five-minute status reports arriving unprompted, then the completion report. An unattended run has no access to that chat, that account or that app, and the ask names shell stubs, passing tests, status.json, worker transcripts and Slack delivery as insufficient.
---

# Prove the behaviour in the operator's own Codex chat

## Overview

The operator's acceptance, stated in issue #989 and the reason this mission exists rather than
another cadence-only repair: **an actual run in the originating Codex chat**. Two previous
attempts reported success without it — PR #987 verified against a stub for `codex exec` and
explicitly left live CLI behaviour unverified, and the session that followed presented a
successful startup while telling the operator this chat would receive nothing.

This ticket is that run and its evidence. It implements nothing.

**It declares `verification_handoff:`** because the run requires the operator's own chat,
account and application, which an unattended run does not have. The unit therefore takes the
handoff route: the pull request opens and stays open, and the operator's own verification is
what closes it.

## Policies

- `workaholic:operation` — how a running system's behaviour is confirmed in the environment it
  actually runs in

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — the branch being exercised.
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the measurement, its
  environment and its version are recorded once it exists.
- `plugins/workaholic/commands/infinite-development.md` — the tick whose reports are what must
  be seen arriving.

## Implementation Steps

1. Start the loop in the originating Codex chat and record the **startup report**: the branch
   selected and the capability answers it was chosen on.
2. Keep a delegated task running for **more than ten minutes**.
3. Record at least **two successive five-minute status reports** arriving visibly in that same
   conversation, with **no further operator input** between them — no status request, no log
   file opened, no move to Slack. Record the timestamp of each.
4. Let the task finish and record its **completion report arriving there automatically**.
5. During a wait, **inject a user status question** and record that it is answered without
   cancelling the loop and without resetting the anchor — the following boundary lands where
   the original anchor puts it.
6. Record that a **still-running role is not dispatched again** — the observed refusal, with the
   role named.
7. Record the **tested environment and version** beside the timestamps, and write the result
   into `other-agents.md` as a dated measurement.
8. If the run cannot be completed because the harness lacks the required mechanism, record
   **that specific limitation** and leave the requirement explicitly unresolved. Do not
   substitute an external supervisor's output, and do not report the mission as implemented.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two successive five-minute status reports are shown arriving in the originating conversation
  with no operator input between them, each with a timestamp.
- A delegated task ran longer than ten minutes across those reports.
- Its completion report is shown arriving in that same conversation automatically.
- A status question asked mid-wait was answered without cancelling the loop or moving the anchor.
- A still-running role was not dispatched a second time.
- The environment and version are recorded.

**Verification method** — the commands/tests/probes that prove them:

- The recorded conversation itself, with timestamps.

**Gate** — what must pass before approval:

- Shell stubs, passing tests, `status.json`, worker transcripts, Slack delivery and
  instructions for creating a schedule by hand are **not** accepted as evidence for any
  criterion above. A documented tool capability is an implementation lead, never a substitute
  for this run.

## Considerations

- The short 15- and 20-second waits already observed in the reporting session are evidence the
  branch is reachable and are explicitly **not** this acceptance run.
