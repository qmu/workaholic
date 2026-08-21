---
name: implement
description: Unattended executor - survey the claimable missions and unclaimed backlog, claim each PR-unit, implement it, and route it by merge policy, with no prompt at any step.
skills:
  - workaholic:drive
  - workaholic:story
  - workaholic:ship
---

# Implement

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end. This is the **unattended** entry point — the one the `[Implement]` routine and every caller-side loop invoke: **no `AskUserQuestion` anywhere, at any step**; a decision the run cannot make is deferred and recorded in the final report, never asked. It **never overrides a gate** (a `secret` hard-stops; a `size`/`leak` block or a missing confirmation method demotes to the PR path, reported with the gate that caused it) and never calls `land-unit.sh`. `$ARGUMENTS`, when present, names one unit (a mission slug or a ticket path) — a scope, not a mode. End with the reconciliation line and the terminal token derived from the skill's §7 table — the `/goal /implement ok` caller contract, never self-graded.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
