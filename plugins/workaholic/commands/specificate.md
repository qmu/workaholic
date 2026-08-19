---
name: specificate
description: Judge the ask in hand and emit, in one publish-tree pull request, the feedback record together with whatever it warrants — a mission with its ticket set, a loose ticket, or the record alone.
skills:
  - workaholic:specificate
  - workaholic:feedback
  - workaholic:mission
  - workaholic:gather
  - workaholic:commit
---

# Specificate

Run the preloaded `workaholic:specificate` skill's **Workflow** end to end (its `reference/workflow.md` carries every step). It acts on the ask **in hand** — this command's argument, a feedback record this session just wrote, or a record the caller named; with none of those it **discovers the inbound issues first** (the skill's *Clock-fired discovery*: the open GitHub issues assigned to this session's own identity, each taken as an ask through the full run), and only when that too returns nothing does it report `{"proposed": 0, "reason": "nothing_in_hand"}` and stop. It is unattended by contract: it never issues `AskUserQuestion`, and every abort reports a machine-readable reason.

Two rulings the skill owns, applied here: an ask from a GitHub issue assigned to someone else is `not_mine` (*Act only on an ask that is yours*); otherwise the triggering issue's assignee rides both scaffolds — `scaffold-draft.sh --assignee <email>` and `scaffold-proposed-ticket.sh --assignee <email>` — and `--assignee` is omitted when nobody was assigned, never filled from the running identity.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
