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

**It posts exactly one Slack shape and no other.** For each ask the sweep **files this run**, it
replies `📥 受理` into that message's own thread, so the channel shows what was received — the
`slack-ref` just written is the thread coordinate, so no lookup runs. An already-swept message,
an exclusion, a degradation, the proposal itself and an idle tick all post nothing. A failed
receipt is reported as `ack_failed` and never blocks the capture.

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

Every refusal is reported by name and every gate is mechanical: a strategy that is closed, not
yours, past its date, citing no feedback record, already carrying queued work, already carrying
an open proposal, or under-planned is skipped with that reason stated. A tick that
cannot read its own open proposals proposes nothing at all.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
