---
type: Feedback
title: Reopen the thread lookup: it bounds the search, when only the acceptance needs bounding
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-18T06:26:39+00:00
author: a@qmu.jp
supersedes: 
---

# Reopen the thread lookup: it bounds the search, when only the acceptance needs bounding

# Reopen the thread lookup: it bounds the search, when only the acceptance needs bounding

Reported through GitHub issue #486, whose body the reporter states was rewritten after the
developer rejected its first framing (the first version reported two holes *inside* the
current lookup and proposed patches that kept it).

Source: https://github.com/qmu/workaholic/issues/486

## The trigger

An `/implement` run merged PR #484 and posted its `🟢 Implemented` finish line as a
**top-level message** in `#dev-workaholic`, mentioning the developer, while a thread for that
feedback item already existed — the developer's own request (`p1786960288121629`), already
carrying the FB-issue notice and the `🔵 Proposed - #474` reply. The run reached case 4 of
`workaholic:notify`'s lookup after two exact-string queries missed: the `fb:<stem>` key (the
thread's root is a human message written before the record, so it cannot carry the key) and a
pull-request URL — the run searched the URL of the PR it had **just created**, a string that
cannot exist in Slack by construction, rather than the originating issue.

## Why the two obvious fixes are both wrong, per the ask

- **"Feed case 3 its query from a script."** That keeps the two-query bound and makes the run
  better at living inside it. It treats a self-imposed limit as a law of nature.
- **"Persist the thread coordinate in the repository."** The design the developer already
  barred on 2026-08-11 (FB `20260811084130`), with an implementation closed unmerged: a Slack
  thread coordinate committed to a public repository is the same irretractable exposure the P9
  withdrawal had already found.

## The structural claim

Q1 (2026-08-07) removed the guess by "defining the search so that it cannot guess". It did so
by constraining two different things at once:

- **how hard the run may look** — at most two queries, no channel history, one search surface
- **what the run may accept as a match** — exact strings only, fuzzy and recency matching
  prohibited by name

Only the second prevents a wrong reply. The first prevents nothing the second does not already
prevent, and it is what produced this failure: one misaimed query and the run had no second
attempt and no permission to look harder. The supposedly safe branch — post a new keyed root —
is what pinged the developer at channel level, so the conservative fallback produced the
loudest wrong outcome.

**Search widely, accept narrowly.** The prohibition on fuzzy matching should stand exactly as
written; the ceiling on effort and surface has no separate justification.

The ask notes this is the same class as the finding of 2026-08-11 (ticket `20260810163359`):
the defect then was **not** that search is unreliable, it was that `slack_search_public` never
looked at a private channel. Twice the diagnosis has been "the run looked in the wrong place",
never "looking is hard".

## The record already set today's reopening condition

`notify/reference/notifications.md` states, of the persisted key:

> The scope-corrected search is the whole fix unless it is measured to still miss — and only
> then does a persisted key reopen as a question, constrained from the start to a store
> outside the repository.

It missed. The ask reopens the question on the terms the record itself wrote, and carries the
constraint with it: **outside the repository**. Under that constraint the ask's strongest
candidate is not a new store at all — **make the thread carry its own key**: when `/propose`
replies into a root it did not write (lookup cases 1-3), its finish line carries the
`fb:<stem>` line that today only case-4 roots carry. Nothing is committed to git, nothing is
carried between routines, and from that moment the thread is findable by exact search for the
item's whole life. The present rule — "the root carries the key ... and the reply does not
repeat it" — was written for case 4, where the loop wrote the root itself; it leaves every
human-rooted thread permanently unfindable, which is precisely the thread this run missed.

## What needs the operator's ruling, and what does not

The ask names two decisions as **not a run's to make**, because each reverses something
written deliberately:

1. **Lift the effort ceiling** — the two-query bound, the no-history rule, and the single
   surface — while keeping the exact-match acceptance rule and the fuzzy-matching prohibition
   untouched.
2. **Let a thread carry its own key** — reopening the persisted-key question in the one form
   the repository's own constraint permits.

One thing needs no ruling and should be stated whatever is decided above: **a URL this session
created is never a lookup query, because it cannot pre-exist the run that made it.**

## Not proposed, per the ask

A rule against mentions. The mention is the finish line's own format and a person mention is
explicitly kept; the defect is the missed thread. Adding a mention rule would leave the actual
mechanism in place and make the notification model longer without making it right.

## What this capture session measured, live

This `/propose` run's own lookup for the adjacent ask (issue #485) corroborates the ask's
third point from the other side: case 2 (`fb:<stem>`) returned nothing, and case 3 found the
developer's existing thread by searching the **originating issue URL**
(`https://github.com/qmu/workaholic/issues/485`) — a string that existed before the run. Had
it searched the pull request it had just opened, it would have reached case 4 and posted a new
root beside a live thread, exactly as PR #484's run did.
