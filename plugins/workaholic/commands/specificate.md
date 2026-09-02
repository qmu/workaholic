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

**Every skill section, reference file or command body this run consults is read with the **Read tool**, never with `sed`, `grep`, `cat` or `head`** (2026-09-02, issue #865): a shell read under the plugin cache is a permission prompt an unattended run cannot answer, and the Read tool is the same bytes with no prompt. A reference such as *see `workaholic:notify`, One thread per feedback item* names a section to open with Read, not a line to grep for.

**Every free-text slot below is written in Japanese, and so is this run's own reasoning and report** — the shape's label, step ids, status and reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated, and a GitHub artifact stays English (`rules/interaction.md`, *The language of a post is the language its readers use*).

**And that Japanese must be read on first sight, not decoded** — the bar is an outcome, not a style preference: *a channel reader must understand what is being asked without opening the English record behind the link.* An established technical term keeps its ordinary katakana or English form (ビルド, CI, デプロイ, PR, and the repository's own `terms/` entries); the **meaning** of a title is translated, never its words; a title that resists translation is **paraphrased** in plain Japanese rather than transliterated. Measured: 「組み立てを止める」 for *fail the build* belongs as 「ビルドが落ちる」, a bare 「形」 for *shape* as 「投稿の型」, 「示せるという判定」 for *demonstrable verdict* as 「実証できたかどうかの判定」.

**The lookup this run performs is carried here, not named** (2026-09-02, ticket `20260902043747`). A command that names a section hands a routine session a lookup to perform, and resolving a name at run time is exactly what parks an unattended run. The paragraphs below are **byte-identical** to `workaholic:notify`, *One thread per feedback item*, and the suite pins the pair — a diff between them is a drift to fix, never a second rule.

Finding the thread is **stateless** (Q1, 2026-08-07 — nothing carries a target between routines; the search is defined so it cannot guess). Ordered cases, take the first that applies — every search an **exact-string** Slack search, never a similarity or content match:

1. The session's own trigger message — reply there; that message is the item's thread. Not a search, and not reducible to one: a hand-off knows its target at write time, and a message written before the record existed can never carry the key.
2. Search `` <stem>.md `` — the record's own filename, which a thread root carries inside the URL it links, derived from the repository, never from Slack. (It was `` `fb:<stem>` `` on a line of its own until 2026-08-22; the line is gone from every rendered post and the URL answers the same query.) (`drive/scripts/unit-feedback-stems.sh` for `/implement`; the record `/specificate` just wrote for its finish post).
3. Search the **originating** Issue or pull-request URL — the one the ask arrived on, a string that existed *before this run began*, and **never a URL this run itself created** (the pull request it just opened, the branch it just pushed), because such a string cannot pre-exist the run that made it and the query is guaranteed to return nothing — or its `#<number>` reference when no URL is in hand, a substitute and never an extra query — which finds the originating human thread when somebody pasted the link into Slack.
4. No exact match → post a **new root** carrying `fb:<stem>` — never a keyless top-level line (two roots with one key is repairable; a keyless post is not attributable to anything). That root is a **description root**, and the finish line is a reply into it (*The description root*, below) — for `/specificate` and for `/implement` alike. Only a caller with no connector falls back to a keyed top-level finish line, because the tokened script cannot **search** — with no connector the lookup never ran at all, so nothing resolved a thread for it to reply into.

**Every search in cases 2 and 3 runs private-inclusive** (`slack_search_public_and_private`, `include_bots: true`), never the default `slack_search_public` (ticket `20260810163359`, measured root cause of issue #360's misses — [reference/notifications.md](reference/notifications.md)). The repository's channel is typically **private**, so the connector's default public-only search returns zero results for the record's filename by construction, however faithfully a root carries the key — not because the search is unreliable, but because it never looked. This is a **standing, one-time developer consent** to read the repository's own channel, carried by this skill and by the commands that defer to it; a routine posting into that same channel needs no further, per-run consent to search it. Reading `include_bots: true` matters the same way: a routine's own prior posts are bots, and a search that silently excludes them can miss its own root.

**Fuzzy matching is prohibited by name**: never a similarity match, never "the most recent thread that looks related", never recency — it is what put a reply in the wrong place on 2026-08-05, and a guess in a notification path is a message that looks right and is unrelated to the event. The not-found branch is what makes the search safe: a lookup that cannot find the thread **says so** by starting one. **The bound is a written number**: **at most two search queries per lookup** (cases 2 and 3, one each), results capped to the top few matches, and **no full-channel read at any point** — search returns matches; channel history returns everything and is never the instrument. **Resolve once per run and reuse it**: a unit's start and finish go to the same thread — statelessness is between runs, never within one. (History and the withdrawn disclosure: [reference/notifications.md](reference/notifications.md).)

When the run finds an ask in hand, post one finish line into its reply thread (the `workaholic:notify` lookup):

```
🔵 Proposed [#123 [Proposal] PR Title](<repo-url>/pull/123)
One sentence, max 30 words, what this proposal queues.
by [web routine](<session URL>)
```

If that lookup finds no thread, post this description root first and the finish line above as a reply into it — no mention token of any kind on the root:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
<session URL>
```

Post nothing else. An attended session running this command by hand posts nothing at all.


Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
