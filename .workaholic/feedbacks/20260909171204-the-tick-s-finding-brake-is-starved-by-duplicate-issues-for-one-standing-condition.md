---
type: Feedback
title: The tick's finding brake is starved by duplicate issues for one standing condition
kind: insight
source: development
subject: observer_ai:moderate
created_at: 2026-09-09T17:12:04+09:00
author: a@qmu.jp
supersedes: 
---

# The tick's finding brake is starved by duplicate issues for one standing condition

Source: the `/moderate` tick `20260909-075432` on this repository, from its own step reports.

## What was measured

`file-findings` reported `brake_held`: *a finding issue is already open (#1114, #1106, #1101,
#1095, #1041); 1 repairable finding(s) held, 5 left to a person*.

Four of those five open issues — #1114, #1106, #1101, #1095 — are the same standing condition,
*the hourly moderation root reached nobody*, filed one per hour on 2026-09-08 by a **different**
seam: `/moderate`'s undelivered-root rule, whose own wording is *one issue for the hour, not one
per line*. That rule has no dedup of its own, so it files a fresh issue every hour the condition
holds. #806 and #939 are earlier instances of the same condition and are also still open, which
makes six.

The consequence is that `file-findings`'s one-in-flight brake is held indefinitely by duplicates
of a condition the loop cannot repair by itself, so the tick's own repairable debt reaches no work
queue for as long as the Slack route is down. This tick held one repairable finding behind it.

`workflow.md` §25 names this outcome as the thing to measure rather than to pre-empt: *One in
flight is deliberately strict; if it measurably starves the queue that is a finding for a later
ask, not a number to raise here.* This record is that measurement.

## Why this is not the provisioning ask #806 already carries

Two standing rulings bound what may be proposed against the Slack route: the operator rejected
provisioning a Slack bot identity, and ruled on #806 that the repair there is theirs. Nothing here
re-proposes either.

What this tick re-derived at the moment of the act is a different fact. The declared binding
(`AGENTS.md`, workspace `qmu`, channel `dev-workaholic`, `declared_digest`
`953c1ab7f2f9ab3c395828af767506b6`) requires `read_channel_delta`, `read_thread`,
`list_thread_changes`, `post_root`, `post_reply` and `add_reaction`. Both describable QFS mounts,
`/slack-cc01-qmu` and `/slack-cdx01-qmu`, verify the channel (`channel_verified: true`,
`C0BLL9J7FMY`) and offer only `read_channel_delta`, `read_thread`, `search_exact`, `post_reply`;
`/slack-clauyo` and `/slack-yodex` answer `channel_unreadable`. `resolve-target.sh` therefore
defers `operations_unsatisfied`, no binding resolves, and `perform.sh` has nothing to perform
against. A route reaches the channel and cannot do what the declaration asks — a code gap, already
queued as the active mission `make-the-declared-slack-route-speak-be-seen-and-be-named`, not a
missing credential.

## The repair this finding names

Either of two, and choosing between them is not this record's call:

1. Give the undelivered-root filing its own dedup, keyed on the standing condition rather than on
   the hour, so one open issue carries it however many hours it holds.
2. Or keep the hourly filing and exclude an issue filed by that seam from
   `list-finding-issues.sh`'s brake ledger, since a preserved root is not a repairable finding the
   loop is driving.

## Non-goals

This proposes no closure, consolidation or deletion of any issue — `issue-triage` proposes and
never performs — no raise of the one-in-flight bound, and no Slack-side credential.
