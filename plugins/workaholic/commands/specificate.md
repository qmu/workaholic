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

## What this run posts

The notification surface is **this command's**, not the routine's — a routine prompt names the command and nothing else, so a shape that changes here reaches every account's routine on the next run with no routine edit (`workaholic:notify`, *The command is the ceiling*). Post shapes are byte-identical to `workaholic:notify`'s catalog; a diff between the two is a drift to fix, never a second wording.

**Every free-text slot below is written in Japanese, and so is this run's own reasoning and report** — the shape's label, step ids, status and reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated, and a GitHub artifact stays English (`rules/interaction.md`, *The language of a post is the language its readers use*).

When the run finds an ask in hand, post one finish line into its reply thread (the `workaholic:notify` lookup):

```
🔵 Proposed - [#123 [Proposal] PR Title](<repo-url>/pull/123)
by the [routine](<session URL>)
```

If that lookup finds no thread, post this description root first and the finish line above as a reply into it — no mention token of any kind on the root:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
<session URL>
```

Post nothing else. An attended session running this command by hand posts nothing at all.


Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
