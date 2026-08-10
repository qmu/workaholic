---
type: Feedback
title: "No RemoteTrigger tool exposed" claim is session-class-dependent — and reveals real cron/prompt drift on the live routines
kind: instruction
source: slack
created_at: 2026-08-10T10:45:20+00:00
author: a@qmu.jp
supersedes: 
---

# "No RemoteTrigger tool exposed" claim is session-class-dependent — and reveals real cron/prompt drift on the live routines

# "No RemoteTrigger tool exposed" claim is session-class-dependent — and reveals real cron/prompt drift on the live routines

Ticket `20260810085351` (baked into `workaholic:workaholify` §5 and `/setup-routines`) claims no `RemoteTrigger`-family tool is exposed to a session, so a routine's trigger wiring can be neither read, written nor verified from a session. Measured live in a local attended session, this does not hold universally: the tool surface included `RemoteTrigger` with actions `list`/`get`/`create`/`update`/`run`/`create_webhook_trigger`, and `list` returned both live routines (`[Propose] workaholic`, `[Implement] workaholic`) with their full records — prompt, model, repository, connectors, `cron_expression`; `create_webhook_trigger` claims to attach a GitHub event source to an existing routine, the half previously believed UI-only. The original finding was made in a routine-fired *unattended* session; this measurement was in a *local attended* session — both may hold simultaneously, i.e. the tool's exposure is session-class-dependent, and the skill/docs that state the absence should say so rather than stating it unconditionally. The same measurement also surfaced real drift: both routine records carry `cron_expression: ""` — the designed `0,30 * * * *` schedule is not actually set on either — and both prompts differ from the current committed templates (`{repo}` placeholders, older wording, `next_run_at` unset).
