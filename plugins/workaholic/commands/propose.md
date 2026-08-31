---
name: propose
description: Read your own active strategies, plan the one mission whose evolutionary move brings the nearest one closer to its aim, and open that plan as a GitHub issue the next /specificate tick ingests. Reads this repository and writes nothing into it.
skills:
  - workaholic:propose
  - workaholic:strategy
---

# Propose

Run the preloaded `workaholic:propose` skill end to end — its `reference/loop.md` carries the
five steps. Survey the strategies (`survey-strategies.sh`), read the selected direction and
what has landed against it, choose **one** move (`depth`, `breadth` or `contraction`), and open
it with `open-proposal.sh`.

**The unit is a mission, not a change.** The issue names a mission title, the experience it
demands, and its ordered ticket set — roughly 7–8 tickets, the ruled scale. `open-proposal.sh`
floors it: the body carries `## Experience` and `## Tickets` beside the three commitment
sections, and fewer than two tickets is refused `under_planned` with the alternative named.
The ceiling stays this run's judgement. `/propose` plans; `/specificate` writes.

**It writes nothing into this repository** — no file, no commit, no branch, no pull request, no
merge, no deployment — and it never issues `AskUserQuestion`. Its only write is the GitHub
issue, assigned to the running identity so `/specificate`'s discovery ingests it.

**It posts exactly one Slack shape and no other**, and the shape lives here — a routine prompt
names this command and nothing else, so a change to the wire format reaches every account's
routine on the next run with no routine edit (`workaholic:notify`, *The command is the ceiling*).

**Every free-text slot below is written in Japanese, and so is this run's own reasoning and report** — the shape's label, step ids, status and reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated, and a GitHub artifact stays English (`rules/interaction.md`, *The language of a post is the language its readers use*).

Read Slack only through the Slack connector; the inbound sweep needs no mention to capture an ask.

For each ask the sweep files **in this run**, post one reply into that message's own thread — its
`thread_ts` is the `ts` half of the `slack-ref` just written, so run no lookup and no search:

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<session URL>
```

Then add the reaction `:inbox_tray:` to that same message, on the same coordinate — again no lookup and no search.

Post nothing else to Slack and add no other reaction: not for an already-swept message, not for
an exclusion, not for a degradation, not for the proposal, and not on an idle tick. A reply or a
reaction that fails is reported as `ack_failed` and never blocks the capture.

Report each swept ask's issue URL and whether its receipt landed — the reply and the reaction
each — or its named exclusion, then the proposal's issue URL and its move, or the named reason
nothing was proposed.

**It is not housekeeping, and it is not a document about the aim.** A drifted document, a
missing test, an inconsistent name are `/moderate`'s work. A proposal must commit to the
strategy: it names what it is chosen against, or it is not emitted. A tick that cannot name one
of the three moves reports `no_evolutionary_move` and opens nothing — a real answer, not a
failure. **A move that would produce documentation *about* an Aim whose subject is to build
something is refused as `describing_move`** — a page about the aim is a perfect `depth` move and
would otherwise repeat forever; a strategy whose Aim is itself documentation is unaffected.

**The inbound sweep names the direction each ask answers.** A swept message naming an explicit
strategy slug is attributed to it; one naming none is judged against the `active` set; one
answering no live direction is `unattributed`. The strategy's own `feedback:` refs ride the filed
issue through `file-inbound-ask.sh --feedback`, and the run report carries `direction:<slug>` or
`direction:unattributed` per filed issue. An unreadable strategy set is named, never read as "no
direction".

**An `arrived` reading is reported with what it could not see.** When the strategy a proposal
was made against reads `quiescent: true`, the run report names `arrived` beside that proposal as
evidence — and beside it the **residue**: the active missions and queued tickets no direction
claims, by slug and count. A degraded residue read is reported as degraded, never as an empty
one. It changes nothing: no gate, no sort, no `selected` and no token reads the residue, and an
arrived direction stays eligible.

**An `expiring` reading is reported the same way, and gates nothing either.** When the strategy a
proposal was made against reads `expiring: true` — its date inside the survey's own window — the
run report names `expiring` beside that proposal as evidence. It does not silence, reorder, hold
or accelerate the proposal: making the one routine that originates work a function of a clock is
what `pace` already refuses. The person who must decide to re-date the direction or end it is
reached by `/moderate`'s `direction-expiring:<slug>` question, not by this line.

Every refusal is reported by name and every gate is mechanical: a strategy that is closed, not
yours, past its date, citing no feedback record, already carrying queued work, already carrying
an open proposal, or under-planned is skipped with that reason stated. A tick that
cannot read its own open proposals proposes nothing at all.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
