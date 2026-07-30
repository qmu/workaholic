---
type: Feedback
title: A ticket-count floor at emission has nothing to count
kind: concern
source: discussion
created_at: 2026-07-30T11:11:01+00:00
author: noreply@anthropic.com
supersedes: 
---

# A ticket-count floor at emission has nothing to count

## Description

Verified while registering the cardinality instruction from [#114](https://github.com/qmu/workaholic/issues/114). The instruction asks for "the ticket-count floor applying at emission rather than only at approval and survey". At emission there is nothing to count.

`skills/propose/scripts/scaffold-draft.sh` line 72 writes `tickets: []` unconditionally — a draft mission is emitted ticket-less by construction, and the batch has no ticket writer. Tickets appear later: `/mission approve <slug>` interrogates the draft to drive-ready, and that interrogation is what emits the set. So on the current pipeline the count at emission is always zero, and a literal ≥2 floor there would refuse every proposal the batch can make.

The floors the instruction correctly identifies as downstream are also ≥1, not ≥2. `skills/mission/scripts/approve.sh` refuses `no_tickets` on `QUEUE_TOTAL -eq 0`, and `skills/drive/scripts/plan-units.sh` excludes a mission `no_tickets` on the same condition; both read the single counter `mission/scripts/queue-size.sh`. So a single-ticket mission — half of what the instruction objects to — passes both guards today.

## How to Fix

Nothing yet; the open question in #114 is unanswered and this record only narrows it. What the instruction is really asking for is not a counter at emission but a **form decision plus a named decomposition**: the batch judges whether the work is atomic, and for a mission it names the ticket set it believes the work decomposes into — which is the thing a count can then be taken over, and which the approval interrogation would refine rather than originate. That is a larger change than a floor, because it moves the first decomposition from the human approval step into the headless batch, and the batch's own bar is written to prefer silence when unsure.

Two smaller things are separable from that question and would stand on their own. The ticket form has no producer in the batch at all — `/propose` can only make missions, so "emit a ticket instead" needs the batch wired to the ticket writer before any cardinality rule can route to it. And if single-ticket missions are genuinely unwanted, the existing `-eq 0` floors in `approve.sh` and `plan-units.sh` are the one-line place that belief becomes enforceable, independently of anything upstream.
