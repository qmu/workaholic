---
type: Feedback
title: A permission prompt in a routine container is a silent stall
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-26T10:34:45+00:00
author: a@qmu.jp
supersedes: 
---

# A permission prompt in a routine container is a silent stall

The developer, watching a routine-fired `/moderate` tick, saw it stop on a tool permission prompt: 「いやいやこんなパーミッション要求されてもルーティンなんだから気付きませんよ」 — a routine has nobody at the terminal, so a permission request is not a question, it is a silent stall.

## What it costs

A blocked tool call in an unattended container produces no Slack post, no log line, and no run report: the tick simply does not finish. Every gate this repository built against silence — the per-step `degraded` reasons, the 'a step going quiet is the failure that matters' rule in `run.sh`'s own header, the red-alert cool-down — sits *inside* the run and cannot fire when the run never reaches them.

## What made this tick reach for an unusual command at all

Measured in the same session: `run.sh` emitted each step's `needs_agent` as a **count** rather than the array its own contract documents, so the agent could not see what the tick had found and re-invoked every step and read the step scripts to recover it. The permission prompt landed on one of those recovery commands. The report shape and the stall are the same defect seen from two ends — fixed in PR #622, which is the narrow half.

## The open half

Nothing yet bounds what an unattended tick may need to run. Two directions, neither ruled on here:

- **Keep the flow inside what a routine template already grants.** The tick's steps are scripts named by the skill; if the agent never needs an ad-hoc command, no prompt can appear. This is the cheaper half and PR #622 is most of it.
- **Make the stall visible.** A routine that dies on a prompt should still be legible afterwards — the tick log is committed as the closing act, so a tick that never reaches the closing act leaves no trace at all, and the next tick cannot tell 'nothing happened' from 'the last one was killed'.

Filed as an observation, not a design: the second half needs the operator's ruling on where a routine's silence should be detected.
