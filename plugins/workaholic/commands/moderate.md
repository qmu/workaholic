---
name: moderate
description: The hourly maintenance tick — find what has gone stale, stuck or drifted around the loop, file it through the existing seams, and say what needs a human. Never prompts; never merges; never rewrites another runner's branch.
skills:
  - workaholic:moderate
  - workaholic:notify
---

# Moderate

Run the preloaded `workaholic:moderate` skill's **The run** section end to end: one tick — `run.sh` over the steps `STEPS` registers, in order, one log line per step in `.workaholic/moderations/<UTC-day>.md`, then act on every `needs_agent` entry through the seam that step's section names, recording each as `<step>-filed`. The run's **closing act** puts that log on the base through the publish tree (`persist-log.sh`) — a routine's container is discarded, so a log left in the checkout blinds every dedup and leaves the tick with no audit trail. Finish with one report line per step, the persist's own outcome **by name**, and the counts.

**Unattended by contract**, exactly as `/implement` and `/specificate` are: **no `AskUserQuestion` at any step**. The check-in step — the last one — asks humans things and asks them in Slack — a routine-fired session has no question mechanism, and "ask a human" is not "prompt the operator".

**It files; it does not decide on anyone's behalf.** A finding becomes a feedback record, work becomes a ticket or a mission through the seams that already publish them, a question becomes a Slack post. It **never merges a pull request**, never pushes into a branch the claim protocol owns, and never edits a live strategy; the one thing it commits to the base is its own append-only tick log. A degraded read — an absent connector, an unreadable inbox, a 403 — is reported **by name**, never rendered as a step that ran and found nothing.

## What this run reads and posts

The notification surface is **this command's**, not the routine's — a routine prompt names the command and nothing else, so a shape that changes here reaches every account's routine on the next run with no routine edit (`workaholic:notify`, *The command is the ceiling*). Post shapes are byte-identical to `workaholic:notify`'s catalog; a diff between the two is a drift to fix, never a second wording.

**Every skill section, reference file or command body this run consults is read with the **Read tool**, never with `sed`, `grep`, `cat` or `head`** (2026-09-02, issue #865): a shell read under the plugin cache is a permission prompt an unattended run cannot answer, and the Read tool is the same bytes with no prompt. A reference such as *see `workaholic:notify`, One thread per feedback item* names a section to open with Read, not a line to grep for.

**Every free-text slot below is written in Japanese, and so is this run's own reasoning and report** — the shape's label, step ids, status and reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated, and a GitHub artifact stays English (`rules/interaction.md`, *The language of a post is the language its readers use*).

**And that Japanese must be read on first sight, not decoded** — the bar is an outcome, not a style preference: *a channel reader must understand what is being asked without opening the English record behind the link.* An established technical term keeps its ordinary katakana or English form (ビルド, CI, デプロイ, PR, and the repository's own `terms/` entries); the **meaning** of a title is translated, never its words; a title that resists translation is **paraphrased** in plain Japanese rather than transliterated. Measured: 「組み立てを止める」 for *fail the build* belongs as 「ビルドが落ちる」, a bare 「形」 for *shape* as 「投稿の型」, 「示せるという判定」 for *demonstrable verdict* as 「実証できたかどうかの判定」.

Read Slack only through the Slack connector, and only as a step asks: the `unanswered-asks` step names one channel and one window and hands that read back to you — no mention of any bot is required for a message to count, and you never reply to, react to, or capture a message you read there. Emit only the shapes below.

The `question-answers` step names one thread per outstanding question, each on a coordinate it already holds: read exactly those threads, one read each, and never search Slack or read channel history for one. Record each person's answer through `record-answer.sh`, or name why you did not — a machine's own post is never an answer. React `:ballot_box_with_check:` on an answer message you actually recorded this tick, and post **no reply** for that event, in any thread — the outcome reply below is a different event, posted only once the loop has acted on the answer.

When the tick's rendered post says to post, **resolve the day's standing root first** by the stateless exact-string lookup in `workaholic:notify`, searching the rendered `token` (`tick-day:<YYYYMMDD>`) and nothing else. It names the **day**, not the tick, so every speaking tick of one day resolves one thread.

- **A thread was found** — post the rendered `reply_text` as a reply into it, and post no root. That text is this hour's change and impairment lines with **no head**: the head restates the day, and a reader following one thread has already read it.
- **No thread was found** — the day's first speaking tick, or a channel whose history the search cannot reach — post the rendered `root_text` as a new top-level message. This is the ordinary once-a-day case, not a failure.
- **The `token` came back empty** (an unreadable tick id, named in `token_reason`) — post the root, unthreaded. A key derived from a date the tick could not read would thread an hour into the wrong day.

Report per tick which it did — `root` or `reply` — and the surface that carried it, so a tick that fell back to a root is visible in the run report rather than inferred from the channel. Every gate above this is untouched: the speaking window still holds the post, the question gate still decides whether there is anything to say, and a tick with nothing to add posts **neither** a root nor a reply.

The reply carries **no mention token**, exactly as the root does not. A change line names a repository event and asks nobody for anything; the mention belongs on the question below, which now sits in the same thread — so an hour with something a person must do already reaches them there. Adding one to the delta would wake the channel for orientation, which is what `📦 Release Preparation` was retired for.

The root's shape — no mention token of any kind:

```
🔎 Moderation - <N> change(s), <M> question(s)
<on the morning tick only, first: the per-strategy digest — numbered strategies, bold title on its own line, each strategy's missions nested under it with acceptance done/total and queued count, headline commits since yesterday, honesty line naming tickets, the total queued and the window>
<what happened to the repository, one line per changed step that has an event>
<when the plan moved since the last tick that spoke: 📋 <N> direction(s) advancing, <M> held; and, when the repository's own limit is holding new work, the missions in flight and the limit — counts only, never a slug>
<one line per reading the tick could not make, after the event lines: ⚠️ <that step's own summary — a sentence saying what could not be read and what follows from it>, at most 5 then "and <K> more">
<session URL>
```

**Nothing the tick knows about itself reaches a rendered post** (2026-09-03, mission `make-the-maintenance-tick-s-channel-presence-help-the-work-along`). `render-tick-post.sh` prints none of it — its own header records that the dedup token is derived and never rendered — so the internals enter **here**, at the composing surface, where this command turns a step's payload into a message. Measured on one morning's root: a printed `tick-day:20260903`, and a sentence explaining which internal step would have handled a thing the tick decided not to say.

So a rendered post carries **none** of the following, on the root, on a question, on a confirmation or on a reconciliation reply alike:

- **a dedup key or a search token** — `tick-day:<YYYYMMDD>`, `fb:<stem>`, a question id or a step id. They are strings a machine searches for; a reader has no use for one, and the root's own link already carries what a machine needs.
- **a step id or a step name** — `base-health`, `direction-health`, `human-checkin`. A reader of the channel has no model of *steps*, which are this loop's own machinery.
- **a counter about the tick** — how many candidates it held, how many it delivered, how many it will leave, what its counters would read afterwards. What happened in the repository is news; what the tick's bookkeeping now holds is not.
- **a sentence about a step's own reasoning** — which internal step would have handled something, why one was skipped, what the tick decided not to say. Say the thing or do not; explaining the omission is the machinery talking about itself.
- **a promise no step must keep** — *the loop will follow up*, *this will be re-checked next hour*. No step is bound by it, so it is a commitment nobody made.

What a post carries instead is the repository's own facts and the act being asked for. The step payloads are already composed to that rule — `heading`, `body`, `event`, `summary` — so the composition here is a rendering, never a re-invention: adding a fact of your own at this surface is exactly how the internals got out.

Then post each question the check-in step cleared as a reply into that root, addressed to the resolved person. **A step that hands back `groups` asks one question per group, naming every subject it holds** — three arrived directions cost one reply, not three near-identical ones (the same mission; `lib/question-id.sh` keys on the group's own key, so the asked-once gate is unchanged):

```
🙋 <@U…> - <what this tick could not decide>
One sentence, max 25 words, the question itself, with the two options when there are two.
```

Post that reply through the **tokened transport** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/notify-slack.sh --thread-ts <the root's ts> "<the reply text>"` — whenever `SLACK_BOT_TOKEN` is set, so a bot speaks it and its `<@U…>` notifies the person even when that person is the account this session posts as. That script is `workaholic:notify`'s **fallback** transport, and it is selected here for its **identity** rather than for its availability: this one reply is a directed post, which is the only case where which account speaks matters. The connector returns the root's `ts` when it posts the root, so hand that same value straight through: never search for it. With no token, post the reply through the connector exactly as you post the root. Report per question which surface carried it — `bot`, `connector`, or the transport's own refusal word — and never retry a refusal. **The root, the `✅` confirmation and the `🟢`/`⚫` reconciliation replies always ride the connector**, unchanged.

For each previously asked question whose subject the check-in read as settled this tick, post one confirmation as a reply into the thread where it was asked — no mention token, once ever per question:

```
✅ 解消を確認 - <the question's subject, one line>
One sentence: what the tick measured that says it settled.
```

For each candidate the `question-answers` step hands back under its settled outcomes, post one reply into that question's own thread, on the coordinate it gives — no mention token, once ever per question, and only after the loop has acted:

```
🧾 対応結果 - <the question's subject, one line>
One sentence: the answer as recorded, and what came of it.
```

For each candidate the `thread-reconcile` step hands back, find the item's thread through the stateless lookup, **read it first**, and post one reply only for these **two** pairs of (last status reply, pull-request state). A thread already carrying its finish is never touched, and no thread found means nothing to correct — post nothing and report it.

**A merged `🔵 Proposed` posts nothing** (2026-09-01, issue #787): merging a proposal lands a feedback record and a ticket set, which is the moment the work becomes **queued** — the start of the item, not its finish. `🟢 Implemented` there asserts the opposite of what happened, and its second line explains away its own lateness, which makes a reader believe it rather than question it. Report the candidate as `proposal_merged_is_not_a_finish`; the thread keeps its last true status and the real `🟢 Implemented` arrives when the work is driven.

**`🟡 Handoff` + merged** — the work is done and a run failed to say so:

```
🟢 Implemented [#123 Title](<repo-url>/pull/123)
Merged outside the loop by <who> on <when> — no run posted this item's finish.
```

```
⚫ Closed [#123 Title](<repo-url>/pull/123)
Closed without merging outside the loop on <when> — no run posted this item's finish.
```

If the rendered post says not to post, post nothing at all — no root, no question, ever. An hour with nothing changed and nothing to ask is silent.

**A root the tick could not deliver is filed, not lost** (2026-09-01, issue #806). When the rendered post says to post and **no transport reaches the channel** — the connector answers `channel_not_found` or resolves no matching channel, and `notify-slack.sh` answers `no_token` — file the rendered root as **one** `[FB]` issue through `file-inbound-ask.sh`, the same filer every other finding uses, carrying the root text verbatim, the counts it names and the reason each transport was out. Measured: a tick rendered `post: true` with 7 change lines and 2 impairment lines, held 18 questions including a stranded claim and three blocked retirements, and every one of them existed only in a tick log inside a container that was then discarded.

**One issue for the hour, not one per line**, and **the ledger is untouched**: a question that reached nobody is never recorded as asked, so every held question stays held and is offered again the moment a transport returns. Restoring the transport is **provisioning, not code** — re-authorize the connector against the workspace holding the channel, or set `SLACK_BOT_TOKEN` and `WORKAHOLIC_SLACK_CHANNEL` on the cloud environment the routines select — so the issue names it and asks for it rather than pretending the tick can fix it.

**A refused call and an absent surface are different outcomes.** `post_refused` is one call a transport that exists declined — the surface answered no, so the line is still sendable and the run carries it. `no_slack_transport` is this session holding no surface at all, which nothing inside the run can change. A refusal is per call; an absence is per session, and reporting the first as the second is what made a run whose every call was denied say the post did not exist.

**A directed post carrying no mention token says so in its own line** — `(メンション先未解決: 誰にも通知していません)` — because a `🙋` or `🟡 Handoff` whose token was omitted reached the channel and paged nobody, and an unanswered thread must never be read as silence from the person. **With no `SLACK_BOT_TOKEN` this deployment's two-transport model is one transport**: every post is made as the operator's own account, so a directed shape whose addressee *is* that account loses its token by *Never mention the identity you are posting as* and provably reaches nobody.

Adding that clause changes the question's **text** and nothing else: `already_asked` keys on the step id `lib/question-id.sh` derives from the key, never on the text, so no question is re-asked by it.


Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
