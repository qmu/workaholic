---
type: Feedback
title: Propose's thread lookup searched an issue reference form that exists nowhere
kind: instruction
source: discussion
created_at: 2026-08-13T12:16:47+00:00
author: a@qmu.jp
supersedes: 
---

# Propose's thread lookup searched an issue reference form that exists nowhere

A `[Propose]` tick posted its `🔵 Proposed` finish line as a new top-level root in `#dev-workaholic` instead of replying in the feedback item's existing thread, and the developer asked why (2026-08-13, PR #437 for issue #436).

The thread existed and was findable. Its parent is the developer's own `FB :` message (`1786619177.802719`) and its one reply is the crossing bot's `Filed: #436` line, which carries the issue URL verbatim. `workaholic:notify`'s lookup should have landed there at case 3 — "search the Issue or pull-request URL". What the session actually searched was `"qmu/workaholic#436"`, a third form that is neither the URL it held in hand nor the `#<number>` reference the skill names as the no-URL substitute, and which appears in no Slack message; it returned zero, so the run fell through to case 4 and posted a keyed root. Measured immediately afterwards in the same session: the same private-inclusive, `include_bots: true` search with the query `"https://github.com/qmu/workaholic/issues/436"` returns exactly one message — the bot reply at `1786619413.956129`, `thread_ts=1786619177.802719`. Case 2 (`fb:<stem>`) correctly returned nothing, since the record had just been written and no root carried its key yet.

The asymmetry that allowed it: case 2's query is pinned to an exact literal (`` `fb:<stem>` ``) and has not been observed to fail, while case 3 names only the *source* of its query — "the Issue or pull-request URL" — and leaves the model to compose the string, so a plausible-looking `owner/repo#N` form can be substituted for the URL that was already in hand (`list-inbound-issues.sh` returns it, and the run had written it into the record's own `Source:` line). The failure also matters more than it did when the lookup was written: under clock-fired discovery the session receives no trigger message, so case 1 never applies and case 3 is the only path back to the human's thread. Two candidate fixes: state in the skill that case 3's query is the issue URL verbatim as the reader returned it and that an `owner/repo#N` form is not a sanctioned substitute; or remove the composition step entirely by having the script that supplies the stem and the URL supply the query strings too.
