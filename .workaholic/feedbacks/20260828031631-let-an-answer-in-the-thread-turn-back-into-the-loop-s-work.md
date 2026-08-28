---
type: Feedback
title: Let an answer in the thread turn back into the loop's work
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T03:16:31+00:00
author: a@qmu.jp
supersedes: 
---

# Let an answer in the thread turn back into the loop's work

The [Propose] routine asks that the loop's **return path** be built: a person answers the
`🔎 Moderation` tick's question **where it was asked** — as a reply in that thread — and the
loop acts on it, with no new store and no second inbox.

Source: https://github.com/qmu/workaholic/issues/673

## What is broken today

`record-answer.sh` exists (2026-08-23, issue #584) and its documented flow is that the developer
opens the session link on the question and answers *inside the moderator's own session*. An
answer typed into the Slack thread the question was posted into reaches **nothing at all**: it is
not a channel message, so `step-unanswered-asks.sh` and the `:40` inbound sweep never see it, and
the sweep excludes answers to the tick's own questions by rule anyway. Even a recorded answer
changes nothing but a gate — the only reader of `question-state.sh` in the plugin is
`ask-question.sh`, which uses `answered` to *stop asking*. The words survive and are found;
nothing acts on them.

## What is asked for

An ordered plan of eight tickets: pin the dead return path with a hermetic test; record the
coordinate a question was posted at on the `human-checkin-ask-` line `ask-question.sh` already
writes; read the answer in a question's own thread (one `slack_read_thread` per outstanding
question on a **known** coordinate, handed back in `needs_agent`); record it through
`record-answer.sh`, still the one writer; turn an answer that asks for work into an `[FB]` issue
through `file-inbound-ask.sh`, the writer the sweep already uses; stamp the answer where it was
written with the catalog's reaction, never a reply; drill the path with no network; and write it
into the documents in the same change.

## The constraints the ask states

No field on any artifact — the coordinate rides the existing log line, the answer rides the
existing answered line, the work rides the existing issue ledger. No second inbox. No second
writer of the answered line and no second reader of the log. The tick still never merges, never
prompts, and writes nothing but its own log.

## Why now

Fifteen achieved missions closed the hole at the *asking* end of this direction; the survey reads
it `quiescent`. A second human-shaped hole is open at the other end: the tick asks eight kinds of
question an hour and the only way for an answer to become anything is for the developer to open a
session, or to restate in the inbound vocabulary what they just said in the thread — the
developer's work moving back **down** a layer, in the one direction whose Aim is that it moves
up. This repository is standing in it: two stalled claims, seven queued units owned by unmapped
addresses, and a handoff waiting on a person are all outstanding questions whose answers, given
where they were asked, would reach nobody.

The rival the routine chose against — "Act on the residue this direction cannot see" — loses now
because it is one more outbound question into the same dead end.
