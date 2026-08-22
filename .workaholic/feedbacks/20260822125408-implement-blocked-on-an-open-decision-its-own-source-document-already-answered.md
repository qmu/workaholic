---
type: Feedback
title: /implement blocked on an Open Decision its own source document already answered
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-22T12:54:08+09:00
author: a@qmu.jp
supersedes: 
---

# /implement blocked on an Open Decision its own source document already answered

An `/implement` tick claimed a single-ticket unit whose `## Open Decisions` said the choice belonged to the business owner and that the driving session must not decide it. The run honored that, recorded the unit `blocked` without an attempt, posted the red finish line, and ended `pending`.

The question was not open. The design page the ticket was about states, roughly fifty lines below the table carrying the "not decided" cells, exactly what each of the two components holds — the same page answers itself. Nothing was missing; the run had not read the whole page before accepting the ticket's framing.

Two seams produced this together. `/specificate` wrote an Open Decision that named an authority and declared itself unresolvable, and `/implement` treated that declaration as evidence rather than as a claim to check. The failure contract already says the opposite — "Decide it from the evidence and the stated intent" — but a session can name an authority and satisfy that test while never having looked for the answer.

What should change: before a run may honor a written Open Decision as a blocker, require it to read the sources the item is about and state in the report what it found there. An Open Decision authored by an earlier automated seam must not be self-certifying: it is a question to answer, not a ruling that the question is unanswerable. The developer's words were that stopping like this is the bigger problem — the reason the loop stalls needs fixing more than the page did.

Source: https://github.com/qmu/workaholic/issues/561
