---
type: Feedback
title: The Propose tick parks on a permission prompt every hour
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-09-02T04:30:38+00:00
author: a@qmu.jp
supersedes: 
---

# The Propose tick parks on a permission prompt every hour

Source: https://github.com/qmu/workaholic/issues/863

The operator reports that the hourly `[Propose]` routine is once again sitting at
`requires_action`, waiting on a permission prompt nobody unattended can answer — the same
class already measured and recorded for the `[Moderate]` tick (three consecutive ticks
parked on a prompt raised by two reads; `workaholic:workaholify`, *Where an unattended
run's prompt policy is configured*).

The routines were recreated fresh on 2026-09-01 and the recurrence is on the new records,
so this is not stale wiring: something the `/propose` run does still raises a prompt in the
routine container, and every tick it fires it silently produces nothing while reading as
scheduled and healthy.

The instruction: find what raises the prompt in the Propose tick and remove it at the
source — restructure the command's own reads and acts so no prompt is ever raised, or rule
on the specific allow entry a person can approve — rather than leaving the tick to park
hourly.

An unattended routine that waits on a person is worse than one that fails: it spends its
fire, reports nothing, and blocks the one routine that originates the loop's work.
