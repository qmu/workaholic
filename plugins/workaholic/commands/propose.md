---
name: propose
description: Read your own active strategies, judge the one evolutionary move that brings the nearest one closer to its aim, and open it as a GitHub issue the next /specificate tick ingests. Reads this repository and writes nothing into it.
skills:
  - workaholic:propose
  - workaholic:strategy
---

# Propose

Run the preloaded `workaholic:propose` skill end to end — its `reference/loop.md` carries the
five steps. Survey the strategies (`survey-strategies.sh`), read the selected direction and
what has landed against it, choose **one** move (`depth`, `breadth` or `contraction`), and open
it with `open-proposal.sh`.

**It writes nothing into this repository** — no file, no commit, no branch, no pull request, no
merge, no deployment — and it never issues `AskUserQuestion`. Its only write is the GitHub
issue, assigned to the running identity so `/specificate`'s discovery ingests it.

**It is not housekeeping, and it is not a document about the aim.** A drifted document, a
missing test, an inconsistent name are `/moderate`'s work. A proposal must commit to the
strategy: it names what it is chosen against, or it is not emitted. A tick that cannot name one
of the three moves reports `no_evolutionary_move` and opens nothing — a real answer, not a
failure. **A move that would produce documentation *about* an Aim whose subject is to build
something is refused as `describing_move`** — a page about the aim is a perfect `depth` move and
would otherwise repeat forever; a strategy whose Aim is itself documentation is unaffected.

Every refusal is reported by name and every gate is mechanical: a strategy that is closed, not
yours, past its date, citing no feedback record, already carrying queued work, already carrying
an open proposal, or beyond this tick's cap is skipped with that reason stated. A tick that
cannot read its own open proposals proposes nothing at all.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
