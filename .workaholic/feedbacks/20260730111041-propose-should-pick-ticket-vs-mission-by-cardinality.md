---
type: Feedback
title: /propose should pick ticket vs mission by cardinality
kind: instruction
source: slack
created_at: 2026-07-30T11:10:41+00:00
author: noreply@anthropic.com
supersedes: 
---

# /propose should pick ticket vs mission by cardinality

Reported by tamura_yoshiya in Slack (#dev-workaholic), filed as
[qmu/workaholic#114](https://github.com/qmu/workaholic/issues/114). Recorded in the
reporter's own words.

## The instruction

/propose currently emits missions that are not mission-shaped. Ticket-less missions and single-ticket missions both occur, and both are wrong for the same reason: a mission is the container for several related units of work, so with zero tickets it carries no plan and with one ticket it adds a layer of indirection over what is simply a ticket.

The expected behaviour is that /propose decides the form from the work itself — if the requirement is atomic and can be satisfied by one unit, it emits a ticket; if it decomposes into two or more units that are genuinely related, it emits a mission carrying that ticket set; and it never emits a mission whose ticket count is below two.

The recent releases show the downstream cost of not enforcing this: v1.0.111 had to add a queue-size floor so /drive would stop offering an approved `merge_policy: auto` mission with `tickets: []` and a provisional acceptance sketch, and `approve.sh` now refuses a mission no ticket names — those are guards at the consumption end for a defect introduced at the production end. Enforcing the shape in /propose is the upstream fix, with the ticket-count floor applying at emission rather than only at approval and survey.

## The open question the reporter left

What /propose should do when a batch looks related but yields exactly one unit — emit the single ticket and drop the mission framing, or record the relation somewhere so a later unit can join it.
