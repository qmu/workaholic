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

## One PR-unit, then end

**An `/implement` run claims ONE PR-unit, drives it to its routed end, reports, and ends** (2026-09-03,
mission `stop-a-finished-subagent-and-take-the-loop-s-clock-off-it`). It does not survey again for a
second unit. If the offer still holds work, that is the **next tick's** run, on a fresh context.

**Why, measured**: one `implement` agent lived one hour thirty minutes, landed a mission of eight
tickets, then claimed and began a **second, unrelated** mission and planned it inside a context still
carrying the whole of the first. The concurrency rule permits one runner and nothing bounded what
that runner did inside its own context — this is the case the fresh-context intention exists to
prevent and the only one the other rules cannot reach.

**What it costs, stated**: the loop lands one unit per tick rather than as many as one context can
hold, so a full queue drains over more ticks. That is the trade the operator asked for — a plan made
inside a context carrying an unrelated mission is worse than a plan made an hour later on a clean
one.

**The terminal token does not move.** A run that drove its one unit cleanly and leaves a claimable
offer behind still reports `pending` by §7's survey row, exactly as it always did: the queue is not
empty, and the token says so. `ok` still means *nothing claimable remains*.

**Everything before the claim is unchanged** — the freshen, the survey, the once-per-run readings and
every act on another unit's claim (a catch-up, a delivery retry, a stranded publication) still run,
because none of them claims a unit or drives a ticket. The bound is on **claiming a second unit**,
not on the run's other work.

## What this run reports about the base

**The base's health is read once per run, and a suite that never ran is named beside the colour** (2026-09-03, mission `make-a-red-base-impossible-for-the-loop-to-miss`). `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/read-base-checks.sh <tip> --declared` answers `green` / `red` / `unanswerable` **and** `unverified[]`, the declared workflows with no run on that commit. Report both: a degraded read is reported as degraded and **never as green**, a degraded declared-read (`unverified_readable: false`) is named by its reason and **never as *every declared suite ran***, and an unverified suite **moves no token** — it is a fact about the repository rather than about the unit this run drove.

## What this run's own merges carry

**The squash title and body are read, never spelled** (2026-09-03, mission `compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk`). Two merges in this run are made by the agent rather than by a script — the `review` route's REST merge and the one `mcp__github__merge_pull_request` retry that a `session_type_cannot_merge` refusal licenses — and a squash merge whose call carries no `commit_message` gets the forge's own default: the concatenation of every commit message on the branch, so the claim stamp, the heartbeats and the index refreshes land on the trunk inside the squash body. Measured on this repository: 48 commits on `main` whose body carries `Refresh heartbeat`, every one a squash body, the longest 11,515 lines.

Before either merge, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/merge-commit-body.sh <pull-request-number>` and pass its `title` and `body` through as `-f commit_title=` and `-f commit_message=` (REST) or as the connector's commit title and message. The values are **never composed here** — that derivation is the script's, exactly as `gather/scripts/merge-method.sh` owns the method. A composer answering `unreadable:<reason>` still yields a body (the story description when one was read, the fallback line otherwise), so the **merge is never held on it**; report the `source` (`story` / `fallback` / `unreadable:<reason>`) beside the unit's merge outcome, as evidence that moves no token.

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

Post one finish line per claimed PR-unit into its reply thread (the `workaholic:notify` lookup) — one line per unit, never one per feedback stem:

```
🟢 Implemented [#123 Title](<repo-url>/pull/123)
One sentence, max 30 words, what the unit changed.
by [web routine](<session URL>)
```

When a unit ends in **handoff** its finish line is this one instead — never `🟢 Implemented`, and never a second post beside it — naming the person who must run what this environment could not:

```
🟡 Handoff <@U…> [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>
```

The `<@U…>` names the **unit's own assignee, never you**: resolve it from the unit's `assignees` and, when it does not resolve, post the line with **no token at all** rather than a guessed one, and report it as unaddressed. Post that line through the **tokened transport** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/notify-slack.sh --thread-ts <the thread's ts> "<the line>"` — whenever `SLACK_BOT_TOKEN` is set, so a bot speaks it and the mention notifies that person even when they are the account this session posts as. That script is `workaholic:notify`'s **fallback** transport, and it is selected here for its **identity** rather than for its availability: this one line is a directed post, which is the only case where which account speaks matters. The connector resolved the thread, so hand its `ts` straight through and never search for one. With no token, post it through the connector exactly as you post `🟢 Implemented`. Report per unit which surface carried it and whom it named. **`🟢 Implemented`, the `📝 FB` root and the precondition-stop shape always ride the connector**, unchanged.

If that lookup finds no thread, post this description root first and the finish line above as a reply into it — no mention token of any kind on the root:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
<session URL>
```

If the run stops before claiming anything, post `workaholic:notify`'s precondition-stop shape instead. An attended `/drive` run posts none of this.

**A refused call and an absent surface are different outcomes.** `post_refused` is one call a transport that exists declined — the surface answered no, so the line is still sendable and the run carries it. `no_slack_transport` is this session holding no surface at all, which nothing inside the run can change. A refusal is per call; an absence is per session, and reporting the first as the second is what made a run whose every call was denied say the post did not exist.

**A directed post carrying no mention token says so in its own line** — `(メンション先未解決: 誰にも通知していません)` — because a `🙋` or `🟡 Handoff` whose token was omitted reached the channel and paged nobody, and an unanswered thread must never be read as silence from the person. **With no `SLACK_BOT_TOKEN` this deployment's two-transport model is one transport**: every post is made as the operator's own account, so a directed shape whose addressee *is* that account loses its token by *Never mention the identity you are posting as* and provably reaches nobody.

**A line this run could not send is carried on the unit's own story, and a later tick sends it once.** Where the finish line does not post, record it before the run ends — `bash ${CLAUDE_PLUGIN_ROOT}/skills/story/scripts/record-unposted-line.sh <story-file> "<shape>" "<reason>" "<the line>"` from inside the worktree, then commit and push, exactly as a refused merge outcome is recorded. At the head of a later run, read `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-unposted-lines.sh`, send each candidate **once** through the transport this section already selects, and on a send that landed run `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/clear-unposted-line.sh <unit-id>`. A send refused again leaves the record standing and is reported in the same vocabulary the first attempt used; a candidate named with no outcome reported is non-conformant on its face. **A unit that merged has no branch left to carry the record**, so its refused line is reported by the run that lost it and carried by nobody.


Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
