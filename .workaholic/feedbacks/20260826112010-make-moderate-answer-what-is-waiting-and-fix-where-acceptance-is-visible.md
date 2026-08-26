---
type: Feedback
title: Make /moderate answer what is waiting, and fix where acceptance is visible
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-08-26T11:20:10+00:00
author: a@qmu.jp
supersedes: 
---

# Make /moderate answer what is waiting, and fix where acceptance is visible

Source: https://github.com/qmu/workaholic/issues/620
Slack: https://qmu.slack.com/archives/C0BLL9J7FMY/p1787738217844439

Three things, from one message on `#dev-workaholic`.

**1. `/moderate` should react to what is waiting on a person, mention or no mention.**
Its role today is bounded by what its own steps found this tick. Add to it: unanswered
questions, unanswered requests, and unanswered opinions — reacted to whether or not anyone
mentioned the routine. The tick already has the surface (the `🙋` replies inside its root)
and the ledger (`.workaholic/moderations/`); what it lacks is the reading that something
has been sitting unanswered.

**2. A language rule, written into `CLAUDE.md`.**

- Reasoning on the `#dev-workaholic` channel and in Claude Code Web routines: **Japanese**.
- GitHub artifacts and `.workaholic/` artifacts: **English**.

**3. `/propose`'s inbound Slack sweep should mark the message it accepted.**
It files the ask as an issue and (since 2026-08-26) replies into the message's own thread,
but leaves no mark on the message itself — so from a channel scroll it is still not visible
whether a message was received as feedback or ignored. The source message should get a
**reaction stamp** when it is turned into an issue, so acceptance is legible where the
message is.

## Why it was filed by hand

The `[Moderate]` tick `20260826-101802` (19:18 JST) found this message in its inbound sweep
and filed nothing, deferring it to the `[Propose]` sweep at `:40`. The developer asked, in
session, why it had not been handled. Item 1 describes that exact failure: the message was
seen, nobody was told, and the tick's own root did not post because it had no question to
carry.
