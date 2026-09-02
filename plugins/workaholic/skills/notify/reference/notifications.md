# Notification reference — post shapes, session URL, disclosure terms

Companion to `SKILL.md` (*One thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*). The standing rules live in the SKILL; this file carries the exact shapes and the recorded decisions behind them.

## The shapes of the runner's posts

A **command** names its postable events and defers the line formats here. This file is the **catalog** a command draws from when it explicitly names an event — never blanket authorization: a shape's presence here does not permit a session to emit it unprompted (SKILL, *The command is the ceiling — no self-authorized shapes*). Since 2026-09-01 the mirror copies live in `plugins/workaholic/commands/*.md`, not in the routine templates: a routine prompt names the command and nothing else, so the wire format is versioned with the plugin rather than re-pasted into every account's routine record. `<@U…>` follows the SKILL's mention rule; `<repo>` is the repository the session is running in, which it derives itself rather than being told. **The English in every fenced block below is the instruction, never the wire text**: a slot like `<one sentence, max 25 words, …>` is filled in the reader's language, which for this loop is **Japanese**, while the shape's own label and every machine word in it are never translated (`rules/interaction.md`, *The language of a post is the language its readers use*). Two events (`/specificate` finish, `/implement` unit finish) carry the **sole sanctioned** wording — the literal templates from issue #300, reconciled below with the shapes that predate them (P10, 2026-08-07), aligned against the developer's dictated wording in issue #333, and **narrowed to the finish alone on 2026-08-11** (issue #351 / mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`): the start shapes `📐 Proposing` and `🟠 Implementing` are **retired** — a routine posts its finish only, and the live routine records were edited to match the same day. Every other event keeps its pre-existing shape unchanged.

**And that Japanese must be read on first sight, not decoded** — the bar is an outcome, not a style preference: *a channel reader must understand what is being asked without opening the English record behind the link.* An established technical term keeps its ordinary katakana or English form (ビルド, CI, デプロイ, PR, and the repository's own `terms/` entries); the **meaning** of a title is translated, never its words; a title that resists translation is **paraphrased** in plain Japanese rather than transliterated. Measured: 「組み立てを止める」 for *fail the build* belongs as 「ビルドが落ちる」, a bare 「形」 for *shape* as 「投稿の型」, 「示せるという判定」 for *demonstrable verdict* as 「実証できたかどうかの判定」.

### A post never mentions the identity it is posted as

**A self-mention notifies nobody, so it is not a mention — it is decoration** (2026-08-23, the developer's instruction). Every routine post reaches Slack **as the developer's own account** (connector primary, or the tokened fallback bound to the same person), so a `<@U…>` resolving to that same account produces no notification, no badge and no unread: Slack does not notify you of your own message. The attribution line `by [web routine](<session URL>) of <@U…>` had carried that token on every `🔵 Proposed` and `🟢 Implemented` since the shapes were written, and `🟡 Handoff <@U…>` named the runner the same way. All three drop it. **The session URL stays** — it is the whole point of the line, and the surface the developer opens to answer.

The rule generalises rather than enumerating three shapes: **resolve the mention target and the posting identity, and emit no `<@U…>` when they are the same.** Mentioning *someone else* is untouched and is exactly what a mention is for — which is why `🙋 <@U…>`, the maintenance tick's question, keeps its token unconditionally: it addresses a named assignee, it is the one post whose entire purpose is to reach a person, and a loop whose blockers reach nobody is the defect that produced issue #584. Nothing else in the catalog mentions anyone: the `📝 FB` description root, `🚀 Auto Merge`, `🔴 Blocked`, `⚪ Paused` and `📣 Standup` carry no token by their own prior rules, and this change does not give them one.

**And a mention that resolves to the poster is repaired by changing the poster, not the mention** (2026-08-31, mission `notify-the-person-a-directed-question-addresses`). The rule above drops a self-resolving token because it notifies nobody — right for the shapes that *record* something, and no answer at all for the two whose purpose is to **reach** a person, which keep their token unconditionally and, in the single-developer configuration, page nobody with it. Those two — `🙋` and the `🟡 Handoff` ask — take the **bot identity** when the addressee resolves to the posting identity, so the same `<@U…>` becomes a real mention: a different account is speaking. Which transport carries which shape is stated **once**, in SKILL, *Which transport carries which shape, and why*, with the directed set enumerated there and nowhere else; this catalog names post **shapes** and never re-derives the carrier. Everything in the rule above is unchanged: a self-resolving token is still emitted by nothing, and no shape in this catalog gains one.

The measured cost, stated rather than hidden: a reader can no longer tell from the finish line alone *which* account's routine posted it in a channel several people's routines post into. That was already only readable as the mention, which rendered as the reader's own name and read as self-addressed; the account is the message's own author, which Slack shows, and the run report names it in words.

### `/specificate` — the finish, plus a description root when no thread was found

```
🔵 Proposed [#123 [Proposal] PR Title](<repo-url>/pull/123)
One sentence, max 30 words, what this proposal queues.
by [web routine](<session URL>)
```

`🔵 Proposed` keeps its name. **The separator after the emoji is gone** (2026-09-02, the developer's instruction), on every shape in this catalog: `🔵 Proposed [#123 …]` rather than `🔵 Proposed - [#123 …]` — the emoji already separates, and a dash between a status word and a link is furniture. **And the attribution reads `by [web routine](<session URL>)`** — *the routine* named a thing the reader has no handle on, where *web routine* names what actually ran and matches the surface the URL opens. It retires the earlier `🟢 Proposed to <@U…> - ...` shape. Since 2026-08-14 it is a **reply** in every connector case — into the thread the stateless lookup found, or into the description root below when it found none. It is a top-level line only on the tokened fallback, which cannot search and is therefore reached with no resolved thread; there it carries the **record's URL** (`<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md`) rather than a bare key — the same identifier, in the one form that is also readable, so the fallback post stays attributable without printing a machine token at a person (2026-08-22). The retired `📐 Proposing` start once preceded it; nothing replaces it.

#### The description root — every case 4

The root the run posts **before** the finish line when the lookup found no thread (SKILL, *One thread per feedback item* case 4, *The description root*). **`/implement` posts it too, since 2026-08-22** — the shipped alternative was a top-level line opening with a status emoji and a pull request number and ending in a bare machine key, which the developer ruled unusable on sight. Byte-identical in `commands/specificate.md` and `commands/implement.md`; a diff between the copies is a drift to fix, never a second wording:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
<session URL>
```

Then the run's finish line — `🔵 Proposed` for `/specificate`, `🟢`/`🚀`/`🟡`/`🔴` for `/implement` — as a reply whose `thread_ts` is this message's timestamp. **Neither carries a printed key** (2026-08-22): case 2 searches `` <stem>.md ``, which the root carries inside the URL it links, so the identifier a machine needs is already there and does not have to be shown to a person twice. **No mention token of any kind appears on the root**: a `<@U…>` resolving to the Claude app would re-trigger the Slack app on the routine's own post, and a person's mention belongs on the reply that names them. The title and the sentence come from the feedback record the run just wrote; nothing is invented for the post.

**Why the root links the record and not an auto-filed issue** (the ticket's Open Decision, ruled 2026-08-14 — issue #443). The report's title asked for a short `[FB]` issue to be filed so the root had a URL to point at; the record's own file URL answers the same need without either of that option's costs. An issue filed **assigned** is re-discovered as an inbound ask by `/specificate`'s clock-fired discovery on the next tick and **cannot be excluded** — `list-inbound-issues.sh` subtracts issues a feedback record already names, and the record naming this one was written *before* it, immutably; an **unassigned** issue is never discovered, which makes it safe and also makes it a page nobody is asked to act on. Opening an issue on this repository unattended would additionally be a new class of write: the confinement rule reserves issue-opening for `/fb`'s cross-repository mode behind a verbatim human confirmation. The accepted cost of linking the record instead: the `main` blob URL 404s until the proposal's pull request merges — which it does on opening, so the window is seconds, except when a scan finding holds the PR open, and then the run reports the link as pending rather than claiming it resolves.

**Why two messages do not breach the event bar.** *The event bar's two precedents* below and the SKILL's bright line both hold: the proposal is still **one** event. The root is not a second announcement — it is the same announcement's readable header, split off so the thread opens with something a human can answer instead of a status line. A found thread still receives exactly one message.

### `/implement` — a unit's finish only

```
🟢 Implemented [#123 Title](<repo-url>/pull/123)
One sentence, max 30 words, what the unit changed.
by [web routine](<session URL>)
```

**The authorship line is retired from the post; the fact stays in the run report** (2026-08-21, the developer's instruction). Between 2026-08-14 and this change a unit whose tickets were not the runner's appended one body line — `tickets authored by <identity>`, or `ticket authorship unresolved` — to its finish post. It is gone from every finish shape. Two reasons, and the second is the stronger one:

- **It was noise on a post this repository spends effort keeping short.** The finish line exists so a human can see one event at a glance; a second line about provenance is not that event, and Slack renders a bare email as a `mailto:` link, so the disclosure arrived as link furniture rather than as a sentence.
- **It printed a value that meant its own absence.** A cloud container whose `.claude/git-identities` mapping is missing keeps `noreply@anthropic.com`, so the line read `tickets authored by noreply@anthropic.com` — a placeholder rendered as an author. `unresolved` existed to keep "could not tell" distinct from "mine", and the post said the opposite of what the runner knew (issue #547).

**What did not change**: `unit-authors.sh` still returns `foreign` / `unresolved` / `mine`, and `/implement`'s per-unit run report still names the authors — the surface a person reads when they want the provenance. Disclosure moved to where it is read on purpose; it was not dropped.

**Both status shapes carry a sentence** (2026-09-02, the developer's instruction). `🔵 Proposed` and `🟢 Implemented` were the only two lines in this catalog that were a title and nothing else — every other shape here already says what happened in its own words, and these two made the reader open a pull request to learn whether it concerned them. The sentence is the same one the other shapes take: one line, max 30 words, what the proposal queues or what the unit changed, drawn from the artifact the run just wrote and never invented for the post. It goes **between** the title line and the attribution, so the link stays first and the session URL stays last.

`🟢 Implemented` is the finish shape for the **ordinary** case: the unit's pull request opened and merged (the immediate-merge route; a scan finding that held the merge still finishes with this line, the open PR URL saying the rest) — it retires the earlier `🟢 Merge Requested for <@U…> - ...` shape, which announced exactly the same event in more words, and the `🟠 Implementing` start post (with the older `🟠 drive started - <unit-id>` it had itself retired); nothing replaces the start. Three outcomes keep their own finish shape rather than collapsing into `🟢 Implemented`, because each carries information the generic line would lose — whether an unattended merge happened, whether the unit is genuinely unfinished, or what named blocker stopped it (the bright line in the SKILL: *an event earns its post*):

```
🚀 Auto Merge [#123 Title](<repo-url>/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

🟡 Handoff <@U…> [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>

🔴 Blocked - `<signature>`
One sentence, max 25 words, what failed and what a human must do.
```

**A `🔴 Blocked` root re-posted when the cool-down expires names the duration** (2026-08-23):

```
🔴 Blocked - `<signature>`, failing since <time>, <N> ticks
One sentence, max 25 words, what failed and what a human must do.
```

The first report keeps the shape above, unchanged. This second form exists only at expiry, because
by then the news is **how long** it has been failing — a root identical to yesterday's is the
restatement this repository retires posts for. When the cool-down expires is the SKILL's rule
(*Post shapes, mentions, and the red-alert dedup*): the earlier of 24 hours after the first report
and the start of the next working day, composed from the check-in gate's own `WORKAHOLIC_WORK_DAYS`,
`WORKAHOLIC_QUIET_HOURS` and `WORKAHOLIC_QUIET_TZ` rather than a second definition. The
`↳ still failing` reply, its exemption from rate-limiting, the first-report rule and the
unreadable-history rule are all untouched.

`🚀 Auto Merge` names no person and carries no mention token — a developer scanning the thread must be able to tell what merged without approval from what a person approved. It keeps the pre-existing merge shape's `from-branch → to-branch` body line verbatim; only the base template it extends moved from `🟢 Merge Requested` to `🟢 Implemented`'s simpler two-line form. `🔴 Blocked` is unchanged from the shape that predates this reconciliation.

**`🟡 Handoff` names the person who must act, and 2026-08-23 was right to remove what it named before** (2026-08-31, mission `notify-the-person-a-directed-question-addresses`). The token it carried then named the **runner** — the account making the post — so it was decoration, and dropping it was correct. But the line was left naming **nobody**, which is the one thing this shape cannot afford: a handoff unit is *by definition* waiting on one person's act, and `drive/reference/routing.md`'s own route table has said `🟡 Handoff` **naming the assignee** since 2026-08-14. Measured: three units waiting on operator input since 2026-08-18, 2026-08-19 and 2026-08-26, found only when the operator asked a session directly.

The token is **the unit's own addressee, never the runner** — resolved from the unit's `assignees` through `gather/scripts/identity.sh`, exactly as every other addressee in this loop is. It is **omitted when the address does not resolve**, and reported as unaddressed rather than stamped with one nobody verified: the identity reader answers `resolved: false` and echoes its input, and a guess here would page the wrong person about somebody else's blocked work. The rule above is therefore **satisfied rather than excepted** — the mention resolves to somebody other than the poster, which is what a mention is — and it takes the **bot** carrier when the addressee *is* the poster, per SKILL, *Which transport carries which shape, and why*. Everything else in the line is verbatim: the body sentence, the session URL, the `## Handoff` section's verbatim quoting of the declared reason, and the rule that this 🟡 **is** the unit's one finish post rather than a third.

**A human merge is not announced by `/implement` at all** — that was `[Consent]`'s job, and `[Consent]` is retired (`workaholic:workaholify`, *Routines*): "a human-merged pull request is now announced by nobody." The `Merged by <@U…>` purple-circle shape this section once documented erased with it (2026-08-09, qmu/workaholic#317) rather than being reassigned — nothing in the current system posts a human-merge finish line, so keeping the shape on the books described a post nobody makes. The auto/human distinction the shape used to carry survives anyway, in the silence itself: `🚀 Auto Merge` is the only merge line `/implement` ever posts, so its presence in a thread means the run shipped the unit unattended; a `review` unit's thread ends at `🟢 Implemented` and stays there even after a human merges the PR later, and the merge itself is always readable on GitHub regardless. A developer telling the two apart reads the thread, not a second emoji.

Exactly one finish per thread stays the rule (SKILL, *Which thread an `/implement` unit's posts land in*): a unit posts `🟢 Implemented` **or** one of the three outcome shapes above, never both — `handoff` is the finish, never a third post, and the same holds for a blocked or merged unit.

### `/propose` — the Slack turn's reply: a question answered in its own thread, within five minutes

**The loop is a bot a person can talk to, at a five-minute latency** (2026-09-02, the developer's instruction). The loop now turns locally every five minutes (`workaholic:loops`), and the first thing `/propose` does each turn is read the inbound channel for what moved since the last turn. A person's **question** — what a command does, where something stands, why a run did what it did — gets one reply in its own thread; an **ask** is the inbound sweep's and gets the `📥 受理` receipt below; anything else a person wrote gets `:eyes:` on the message. Not the Claude Tag's instant reply, and the developer ruled that a reply inside five minutes is enough.

```
💬 [<the question, one line>]
<the answer, max 80 words, in plain Japanese, what the repository says and where>
<session URL>
```

**Read the thread first, and post nothing if it already carries a reply of ours after the message** — the dedup is the thread itself, not a marker, because a reply is not a filing and writes no `slack-ref`. **No mention token**, by the standing rule; **no question back**, because a run that asks is a run that waits; **no promise of an act** — an act is the sweep's issue or nothing. The window is `WORKAHOLIC_SLACK_TURN_WINDOW_MINUTES` (default 10) so consecutive turns overlap. A failed read or post is `slack_turn_failed: <reason>` and never blocks the sweep.

### `/propose` — the inbound sweep's receipt: a reply in the swept message's thread, a reaction on the message

**A capture the channel cannot see did not happen, as far as the person who wrote it is concerned** (2026-08-26, the developer's instruction). The sweep filed the `[FB]` issue and left **nothing** on the message it filed — so from `#dev-<repo>` a message that became an issue and a message nobody read are byte-identical. Measured the same day: two asks written at 18:56 and 19:20 JST were both captured as issues #620 and #621 within the hour, and the developer, seeing no trace in the channel, asked why neither had been treated as feedback. The capture worked; only its receipt was missing.

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<session URL>
```

**One reply per filed issue, into the swept message's own thread** — `thread_ts` is the `ts` half of the `slack-ref` the run just wrote into the issue body, so the coordinates are already in hand and **no lookup runs**: this is the model's case 1 (SKILL, *One thread per feedback item*), not a search, and the two-query bound is untouched because no query is made. A message with no thread gets one, rooted on itself, which is exactly where a person looking at that message will find it.

**It carries no mention token**, by the standing rule: the reply reaches Slack as the developer's own account and the person it would name is normally the message's own author, so a `<@U…>` there notifies nobody. Slack's own thread-participation notice reaches the author, which is the whole mechanism this receipt relies on.

**And a reaction on the message itself: `:inbox_tray:`** (2026-08-26). A reply lives *inside* a thread, so from a channel scroll a captured ask and an ignored one still look identical — a person has to open the thread to find out which happened. The reaction is the same receipt at a glance, in the one place someone scrolling the channel is already looking. It is the emoji the reply already speaks with (`📥`), so one event keeps one vocabulary, and **this line is the single source for the name**: `/propose` and the drift pin read it from here rather than restating it.

It rides the same coordinate and the same bounds as the reply — `<channel>:<ts>` from the `slack-ref` the run just wrote, so still **no lookup and no second query**; **only a message this run filed**, so an already-swept one gets neither reply nor reaction; and **never load-bearing**, reported per message as `ack_failed: <reason>` beside the reply's own outcome, so a landed reaction and a failed one are two facts exactly as a landed reply and a failed one are. It is a **second signal for a second audience**, never a substitute for the reply: a reaction carries no link and is invisible to anyone reading the issue rather than the channel.

**Only a message this run actually filed.** A message excluded as already swept gets **nothing** — the receipt is on the issue that already exists, posted by the run that filed it, and a second one an hour later would be the hourly restatement this catalog retires posts for. Nor does an exclusion, a degradation or the strategy half of the tick ever post: `no_slack_transport`, `channel_unreadable` and `sweep_dedup_unreadable` are reported in the run report and said nowhere else.

**The receipt never gates the capture.** The issue is already open when the reply is attempted; a reply that fails is reported as `ack_failed: <reason>` per message and changes nothing about the filing, the dedup marker, or what `/specificate` ingests next. A capture that landed and a receipt that did not are two facts, and the run states both.

### `/prepare-release` — retired, and nothing replaced it

**The `📦 Release Preparation` root is gone** (2026-08-19, the developer's instruction). The
`[Prepare Release]` routine was merged into the maintenance tick as two of its steps, and the
post did not come with it. What it said — how many commits are waiting on which target — is a
**status line addressed to nobody**, and the channel measured what that produces: ten `📦` lines
in ten consecutive hours on 2026-08-19 for one unchanged request, the count rising 10 → 12 → 14
→ 16 → 18 → 22 → 30, none of them answered. The `deploy:<digest>` and `deploy-day:<day_token>`
gates worked exactly as designed and were beside the point; a post nobody is asked to act on is
noise at any frequency.

The state itself did not stop being worth knowing. It is read every tick by
`step-release-status.sh` and `step-note-cadence.sh`, written to the tick log, and — when it
genuinely needs a person — turned into a `🙋 Question` addressed to somebody with the options
named. `/prepare-release` survives as a command a human runs on demand; it posts nothing.

### `/standup` — the daily per-strategy digest

**Retired 2026-08-24** (the developer's ruling: the standup is integrated into the moderation
tick, and the separate `[Standup]` routine they had already deleted was mistakenly re-created
that day). The per-strategy digest now rides the **morning `🔎 Moderation` root** — once per
Asia/Tokyo day, on the first tick at or after 09:00, rendered by `/moderate`'s
`strategy-digest` step in the numbered form above the change lines. `/standup` survives as a
command a human runs on demand; no routine posts a `📣 Standup` root any more.

**The units are named because the old ones were asked about** (2026-08-24, the developer's
question the same morning the first digest posted): `<M>` is the repository's **commit count**
in the window (`git log --since`, the digest's `commit_count`), not the artifact count the
line used to carry as a bare "moved"; strategies are **numbered, their titles bold, the title
on its own line**; and the honesty line names *what* it counts (tickets) and *when* (changed
in the window / queued now) instead of "item(s)".

**A top-level keyed root, never a reply**, and **no mention token of any kind** — the same two reasons the moderator's `🔎 Moderation` root carries none: no feedback item said anything, and the line names the repository's state rather than a person's work.

**One strategy line each, in the digest's own order, capped.** A quiet strategy gets the explicit `no activity` line rather than being dropped — a strategy missing from the digest reads as a strategy nobody is working on, which is a different claim. `strategies_omitted` above the cap is stated as a trailing count, never silently cut. The final `not attributable` line is a **count** and rides only when it is non-zero; enumerating it would make this a repository changelog, which is `/catch`'s job.

**And each strategy's missions nest under it, with the repository's total queued on the honesty line** (2026-09-01, mission `report-where-the-work-stands-not-only-what-is-wrong`). The operator asked mid-session how many todos were left and no post the loop makes carried the answer: every surface here reports what has gone *wrong*, so the ordinary question — where does the work stand — had to be put to a person, who then read it out of the bundle by hand. Under each numbered strategy, one line per mission from `digest.sh`'s `missions[]`: its title, its acceptance **done/total** and how many tickets are **queued** under it; and the honesty line, which already names tickets and the window, also names `queued_total`. The caps are the ones already stated — `missions_omitted` above `STANDUP_MAX_ITEMS` is a trailing count like every other cut — and a mission grain the reader could not complete renders **by its reason with no numbers**, never as `0/0` with nothing queued, which is the answer "this mission is finished".

**It is the daily digest that gains the shape, not a new hourly line** — the request was for it on the ordinary tick, and the answer is the two roots this catalog has already retired. `📦 Release Preparation` was withdrawn for restating an unchanged answer ten hours running, and `🔧 Needs a decision` for the same shape; the plan's shape is an *unchanged answer* on most hours, so an hourly copy of it is that post returning under a new name. Once per Asia/Tokyo day, on the morning root, is where an unasked-for status statement is admissible here, and it is admissible there because the developer asked for the morning to open with it.

**Keyed on the date, not on the content.** A daily digest speaks for today even when today resembles yesterday; what the key prevents is two posts for one morning. Search the token exactly once (private-inclusive, `include_bots: true`): found ⇒ post nothing. `noop: true` from the digest posts nothing either, whatever the date says.

### `/moderate` — the moderator's hourly thread: one root, its questions inside it

**One thread per day, and two speech acts told apart by position** (2026-08-21, the developer's design; one thread per *tick* until 2026-09-01). The day's first speaking tick posts a **root** carrying what changed; every later speaking tick that day replies its hour's change lines into that same thread, with no restated head. Every question any of them has goes out as a **mentioned reply inside that root's thread**. The root is orientation and is addressed to nobody; the replies are directed and carry a name. Two kinds of speech, one place to look, no second routine.

**What moved on 2026-09-01, and what did not** (mission `let-the-tick-add-to-a-standing-thread-instead-of-restating-itself`). The root was keyed `` `tick:<tick-id>` ``, and the id is that tick's own timestamp — so the exact string this hour searched for is one no earlier message could contain, and the lookup could not match the previous hour *by construction*. Measured: **14 roots in one window, 12 of them carrying no question at all**. The key's derivation moved to the UTC day inside the same id (`` `tick-day:<YYYYMMDD>` ``), and the posting rule moved with it: found ⇒ reply the delta, not found ⇒ post the root. **The 2026-08-05 misfire and the prohibition it produced are untouched** — the tick still searches one exact string it derives, still posts a root rather than picking the closest thread when nothing matches, and still chooses no thread for looking related or for being recent. What changed is one key's derivation; the search is the same search.

**The delta reply carries no mention token either.** A change line names a repository event and asks nobody for anything; the mention belongs on the question, which now sits in the same thread — so an hour with something a person must do already reaches them there. Adding one to the delta would wake the channel for orientation, which is what `📦 Release Preparation` was retired for.

```
🔎 Moderation - <N> change(s), <M> question(s)
<on the morning tick only, first: the per-strategy digest — numbered strategies, bold title on its own line, each strategy's missions nested under it with acceptance done/total and queued count, headline commits since yesterday, honesty line naming tickets, the total queued and the window>
<what happened to the repository, one line per changed step that has an event>
<one line per reading the tick could not make, after the event lines: ⚠️ <that step's own summary — a sentence saying what could not be read and what follows from it>, at most 5 then "and <K> more">
<session URL>
```

**And every root names the steps that could not read** (2026-08-31, mission
`name-the-steps-a-tick-could-not-read`). A degraded step normally supplies no `event`, and *a step
with no event renders no line* — so a tick where six steps saw nothing rendered identically to one
where everything was read and everything was fine; measured, 24 of 25 ticks in that state, found
four days later by asking. The count rides the head, the names and reasons ride the body after the
event lines, and both are omitted entirely when nothing was impaired, so a healthy root is
byte-identical to what it always was. `skipped` is **not** impairment (a step declining to run for
a stated, healthy reason did not fail to see) and `blocked` renders beside `degraded` under one
clause, because they differ in cause and are identical in consequence to the reader.

**It rides outside the diff and earns no post.** A step degraded the same way for twenty-four ticks
has an unchanged summary, so the diff would call it unchanged and the impairment would be said once
and then vanish — the defect rather than the fix. And it adds a clause to a root that was *already*
being posted for a question, a digest or a delivery failure, so a tick that would have been silent
stays silent: this is not `📦 Release Preparation` returning, which earned a post with an unchanged
answer. The list is bounded (5 by default) with the remainder counted rather than cut, and it
carries no dedup key, no mention token and no session URL of its own.

**Each line names a repository event, not the tick's bookkeeping** (2026-08-23). A line used to be
the step's own **log** summary rendered verbatim — an audit trail written for a maintainer
diagnosing the tick, and it read like one: `1 to judge`, `0 already captured`, `0 finding(s)
already filed by an earlier tick`, and `no new documentation drift` reporting that *nothing
happened* while being rendered as a change. The audit trail is not the wrong artifact; it is the
wrong audience. Each step now supplies a second field, `event`, beside `summary`: the step knows
what its finding means and the renderer does not, and **the log keeps its summaries unchanged** —
it loses nothing. **A step with no event renders no line**, which is the independent guard against
a "nothing happened" line reaching the root even if the change diff calls it changed. The diff
still reads `summary`, because that is what tells this hour from the last one.


```
🙋 <@U…> - <what this tick could not decide>
One sentence, max 25 words, the question itself, with the two options when there are two.
```

**What that sentence must contain — the composition contract** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). The shape above fixes the
*form* and said nothing about the *content*, so each step composed its own wording from whatever
identifier it happened to hold and a question opened with a unit id, an artifact path, a claim
verdict or a strategy slug. The operator reads it on Slack with nothing else in front of them:
a heading that opens with `batch-20260818215156` or
`.workaholic/tickets/todo/20260819103855-….md` tells them neither what happened nor what they
are being asked to do. **This is the one home for the rule; every step reads it from here.**

1. **The heading leads with what happened**, in words a reader outside the repository
   understands — a plain clause naming *what happened to what*, never an identifier, a verdict
   word, a dedup key or a step id.
2. **The identifier comes after it, never before.** The unit, the path, the number or the slug
   is how the reader finds the thing once they already know what it is about; leading with it
   makes them decode before they can read.
3. **A verdict word, a key or a step id never appears alone.** `report_undelivered`,
   `content_conflict`, `awaiting_verification`, `superseded` are this repository's vocabulary,
   not the reader's: where one is worth carrying, carry it **beside** the plain fact it stands
   for, never in place of it.
4. **The body names the one act asked of the addressee** — the single thing they are being asked
   to do or decide, in the second person. Where the question genuinely has two options, both are
   named; that clause of the shape is unchanged.
5. **The named details that already ride the heading keep riding it** — a direction's declared
   stage and its leaving, the days left and the date, the branch a retirement could not delete,
   the files a conflict collided on, how long the subject has been asked about. The body's one
   sentence is reserved for the act.

**The ≤25-word body is a ceiling, not a target.** A question that will not fit is a question
aimed at the wrong reader or standing for a finding nobody can act on, and the repair is
self-containment rather than more text: name the act, drop the mechanism. A step whose finding
genuinely cannot be said in one sentence names that in its own section rather than lengthening
the post.

**Nothing mechanical moves with the wording.** `ask-question.sh`, every question key, the
per-tick cap, the daily bound, the quiet-hours window, the working-day gate and each question's
addressee are untouched by this rule, and **changing a body never re-asks a question** —
`already_asked` keys on the step id `lib/question-id.sh` derives from the key, never on the text.
That is what makes a sweep of every question's wording safe to make in one change.

And a previously asked question whose subject settled this tick is confirmed **once**, as a reply
into the thread that asked it — no mention token, because it closes a loop rather than demanding
attention (2026-08-24, the developer's instruction; the rules — `asked`-not-`answered` only, the
exact-string thread lookup, `human-checkin-confirmed-<slug>`, the off-day and quiet-hours holds —
live in `workaholic:moderate`'s workflow reference):

```
✅ 解消を確認 - <the question's subject, one line>
One sentence: what the tick measured that says it settled.
```

**The root is rendered, never composed freehand** — `moderate/scripts/render-tick-post.sh` emits `root_text`, and the session posts that. The session URL rides the root only; a reply inside a thread whose root already carries it would be the same link twice.

**A change is a step whose summary differs from the same step's summary in the previous tick** — nothing else, no field added to any step, and no cursor stored, because the previous tick is already in the log this tick keeps. That derivation is the reason an hourly root is admissible at all: `📦 Release Preparation` was retired for restating an unchanged answer ten hours running, and a diff against the last tick cannot do that by construction.

**One gate, two narrow exceptions, and an idle hour is silent.** The root posts when there is **at least one question** — the changed-step half was retired on 2026-08-22 (issue #569), because with `0 question(s)` the root is exactly the status line addressed to nobody that `🔧 Needs a decision` and `📦 Release Preparation` were retired for. Two conditions sit beside that untouched expression: the **morning digest** (2026-08-24, the day's opening statement) and, since 2026-08-28, a **check-in that reached nobody** — a tick holding candidates that delivered none supplies its own event, because with no question its silence is byte-identical to a quiet hour, which is the one thing a delivery failure must not look like. It fires only on a *changed* reading, so it is said once and stops entirely once the channel is delivering. `idle` posts nothing; so do `no_question`, `no_previous_tick` (everything would read as changed, the loudest and least informative first impression) and `no_log` — a mechanism that could not read must never announce quiet.

**What was retired to get here.** The tick used to reply its one question into the thread of the **item** it concerned, with no root of its own; before that it emitted two status roots, `🔧 Needs a decision` and `📦 Release Preparation`, both retired on 2026-08-19 because a status line addressed to nobody is noise whatever its dedup key (measured on `#dev-workaholic`: ten `📦` lines in ten consecutive hours for one unchanged request, none answered). That measurement stands and this root does not reverse it — **this root is not addressed to nobody in the same sense**: it exists to carry the questions under it, and it never posts on an hour with neither a question nor a change. The cost that was paid is stated rather than hidden: a person following one item's own thread no longer sees the tick's question there, so every root line links the item it is about.

**Asked once, never re-asked**, and **the ledger is the tick log, never the post** (the `` `ask:<key>` `` line was printed at the reader until 2026-08-22 and searched by nothing — `ask-question.sh` matches the step id derived from the key, in `.workaholic/moderations/`, and has read Slack at no point). An unanswered question is not re-posted next hour: a question is a demand on a person's attention, and repeating it turns asking into nagging. Silence is never read as an answer — the unanswered set stays visible in the tick log. `ask-question.sh` holds the per-tick cap, the daily bound, **the working-day gate and the quiet-hours window**; a question it suppresses is recorded as held and handed back on the next eligible tick, which is what makes suppression a delay rather than a loss.

**Working days, not only working hours** (2026-08-21). The gate checked the clock alone, so a question found at 10:00 on a Sunday was posted into a channel nobody was reading — and its own asked-once gate then guaranteed it was never posted again on a day somebody was. `WORKAHOLIC_WORK_DAYS` (default `1-5`) holds the weekend, and held is not dropped: the finding waits for Monday.

**And an answer the tick read is stamped where it was written: `:ballot_box_with_check:`, a reaction and nothing else** (2026-08-28, mission `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`). A person who answers in the question's thread has no way to tell whether the loop read them. The stamp is a **reaction on the answer message** — **no reply is posted for this event, in any thread** — because a reply into a thread the person is already reading is the hourly restatement this catalog has retired posts for twice, while a reaction says *received* at a glance in the one place they are already looking. **This line is the single source for the name**: `/moderate` and the drift pin read it from here rather than restating it, and it is deliberately **not** the receipt's `:inbox_tray:` — capturing a channel message and reading an answer to our own question are two different events, and one emoji answering both is how a reader stops being able to tell them apart.

It rides the **coordinate already in hand** — the `(channel, ts)` of the message the tick just read, on the thread coordinate `ask-question.sh --record-ask` recorded when the question was posted — so there is **no lookup and no second query**, the same case-1 property the inbound sweep's receipt relies on. **Only an answer this run actually recorded** is stamped: one an earlier tick recorded already carries that tick's stamp, and a second an hour later is exactly the restatement above; a candidate the run did not record gets nothing. And it is **never load-bearing** — the answer is recorded and any issue filed *before* the stamp is attempted, so a failure is reported as `ack_failed: <reason>` and changes nothing about the recording, the question's state, or the filing.

**Two audiences, and this serves one of them.** A reaction carries no link and is invisible to anyone reading the issue rather than the thread. That is accepted: the person who wrote the answer is reading the thread, and where the answer produced an issue, that issue is assigned and GitHub notifies — a reply carrying its link would be the same noise twice, which is the argument that shaped this whole catalog.

**And once the loop has ACTED on that answer, one reply says what came of it** (2026-08-31, mission `make-the-tick-s-questions-readable-and-close-them-in-the-thread`). The reaction says *received*, which is not *acted on*, and nothing said the second thing at all: from the thread, an answer that became a merged mission and one that was read and dropped looked identical. No mention token — it closes a loop rather than demanding attention, exactly as `✅ 解消を確認` does:

```
🧾 対応結果 - <the question's subject, one line>
One sentence: the answer as recorded, and what came of it.
```

**This narrows the no-reply rule above; it does not drop it, and the bounds are the narrowing.** That rule was written against a **restatement** — a reply into a thread the person is already reading, saying what they already know — and it is right for the moment of recording, when nothing has happened yet. It is wrong once something has. So the reply is posted **once, ever, per question**; **after the act**, never before; and it carries **facts the thread does not already have**. It never restates the question, never re-asks, never confirms, and never fires while the outcome is still unknown.

**When the outcome is known is a reading, not a guess**: `moderate/scripts/answer-outcome.sh` answers `settled:nothing_filed` / `settled:issue_closed` / `pending` / `unreadable:<reason>` per answered question, and **only a `settled:` reading posts**. `pending` and `unreadable:<reason>` post nothing and are reported by name — an unread outcome rendered as a settled one would tell somebody their answer was acted on when nobody knows. Every value is a **judgement** (`workaholic:drive`'s `reference/claims.md`, *Whether a recorded answer has been acted on*): nothing may merge, close, gate, hold work or re-ask on it.

**The two events keep their own emoji, and that is load-bearing.** `:ballot_box_with_check:` stamps *received* at recording time and its rule above is untouched; `🧾` says *acted on* afterwards. One symbol answering both is how a reader stops being able to tell them apart — the same reason the stamp is deliberately not the sweep's `:inbox_tray:`. Two replies were considered and refused: a second post at recording time would carry nothing the reaction does not already say.

**It is never load-bearing.** The answer is recorded, any issue filed, and the reaction stamped long before this is attempted, so a failure is reported as `outcome_post_failed: <reason>` and changes nothing about the recording, the filing, the question's state or the reading. The dedup is the ledger line `human-checkin-outcome-<slug>` plus the `settled:` reading, not a cursor: a question whose outcome is not yet known is simply a candidate again next tick.

**And a thread whose last word is false is corrected in that thread, once** (2026-08-28, mission `reconcile-a-stale-thread-with-the-unit-s-real-state`). A finish line is posted by the run that **finishes** a unit (SKILL, *Which thread an `/implement` unit's posts land in*), so a pull request a person merges or closes by hand gets its finish posted by nobody: the item's thread keeps `🔵 Proposed` or `🟡 Handoff` as its last word while the work is long merged. The merged form **reuses `🟢 Implemented`** and is marked by its sentence rather than by a new colour — the reader's question is *did this finish*, and a fifth finish emoji would make one event two vocabularies:

```
🟢 Implemented [#123 Title](<repo-url>/pull/123)
Merged outside the loop by <who> on <when> — no run posted this item's finish.
```

A pull request that was **closed without merging** has no shape at all in this catalog, and needs one: *closed* and *merged* ask a reader for different things. It is as quiet as the rest — one line, the pull request link, no mention token:

```
⚫ Closed [#123 Title](<repo-url>/pull/123)
Closed without merging outside the loop on <when> — no run posted this item's finish.
```

**Why this earns a post against the bright line.** It does not announce an event; it **corrects a false last word** in the item's own thread, addressed to whoever follows that item, exactly once. The precedent is `/propose`'s inbound receipt — a post addressed to the one person already reading that thread — and emphatically **not** `🔧 Needs a decision`, which was a status line addressed to nobody. `<who>` and `<when>` come from the merge itself; an unresolved one is **stated as unresolved**, never omitted silently and never guessed.

**`[Consent]`'s retirement is answered by name, not worked around.** That routine was retired on 2026-08-06 and this catalog records the consequence — *"a human-merged pull request is announced by nobody"* — with the purple-circle `Merged by <@U…>` shape erased with it (qmu/workaholic#317). **This does not reverse that.** `[Consent]` announced **every** human merge as its own event, on every thread, forever; this corrects only a thread that is **still calling the unit in flight**. The narrowing is what keeps the two apart and it is checkable: **only a thread whose last status reply is `🔵 Proposed` or `🟡 Handoff` is a candidate.** A `review` unit's thread ending at `🟢 Implemented` after a later human merge is **correct and is never touched**, which is this catalog's own standing sentence unchanged.

**And a merged `🔵 Proposed` is not a finish at all** (2026-09-01, issue #787). Measured: an operator's thread ran `📥 受理` → `🔵 Proposed` → `🟢 Implemented`, and the operator read the green circle as their ask being done. The pull request was a **proposal** — three files, all under `.workaholic/`, `+200 −0`, no product code — and the ticket it queued was still in `todo/`; the thing the operator had complained about was byte-identical. Merging a proposal lands a feedback record and a ticket set: it is the moment the work becomes **queued**, the START of the item. So there are exactly **three** pairs and only two of them post: `🟡 Handoff` + merged → `🟢 Implemented`; `🔵 Proposed` + closed-unmerged → `⚫ Closed`; **`🔵 Proposed` + merged → nothing**, reported `proposal_merged_is_not_a_finish`. Saying nothing is strictly better than saying the opposite — the thread keeps its last true status and the real `🟢 Implemented` arrives when the work is driven — and telling the two apart needs no new state, because the latest status reply is already read.

### `[Workaholic]` — retired, and nothing replaced it

**The routine is gone** (2026-08-22, issue #557), and with it the `user` scope and `/setup-user-routines`. It held no Slack connector and posted nothing, so no shape leaves this catalog; what leaves is the entry describing why it was silent.

The reasoning that kept it silent is still the right reasoning and is kept for the shapes that still rely on it: an account-level routine acting on the operator's **own** account has an audience of exactly one person — the only person who could act on a refusal it reported — and a channel of colleagues is the wrong room for that. Its result reached that person as a Claude notification (`notifications: push`) instead.

What retired the routine is the other half of the same rule. Its only possible hourly output was *"could not read your routines, converged nothing"* — a status line addressed to nobody, with no dedup key at all — and it was measurably the only output it could ever produce: no `RemoteTrigger`-family tool is exposed to a clock-fired container, so it converged zero routines on every tick of its life. `notifications: push` survives as a template field and `[Propose]` is now its **only** declarer.

### Precondition-stop — calm first, escalate on persistence

A **first** report of a signature in the precondition-stop class (SKILL, *Post shapes, mentions, and the red-alert dedup* — `no_plugin_source`; `unbound_in_claude_session` and `loaded_version_behind_registry` left the class on 2026-08-12 by ceasing to be stops) posts calm rather than alarming, since the run stopped before it ever reached a unit:

```
⚪ Paused - `<signature>`
One sentence, max 25 words, what the run stopped on and that the next tick retries automatically.
<session URL>
```

This is a top-level root, not a threaded reply — it needs one to thread onto if the signature persists. **Escalation**: when the dedup's own recent-history read (~50 messages) finds the same signature already posted, this tick's report is the ordinary `🔴 Blocked` red alert instead of a second `⚪ Paused` — from there the standing cool-down and `↳ still failing` threaded-reply rules apply exactly as for any other red alert. A signature outside the precondition-stop class never posts `⚪ Paused`; it is a red alert from its first report, unchanged.

## The session URL

Every post carries the Claude Code Web session URL that did the work — the same URL the harness gives the session for its `Claude-Session:` commit trailer. It is what turns "merged by Claude" into something a developer can audit. If the URL is not discoverable in a given session, post without it: a notification missing one line beats a notification that did not happen.

## Mention resolution — how a session resolves a person

Look the person up through the Slack connector the routine already loads — `slack_search_users` on the identity in hand, `slack_read_user_profile` to confirm the match; a display-name search is the last resort, and a match that cannot be confirmed is not a match. When a session holds only a GitHub login, resolve through the email git records for the person (the merge or claim commit's author) and search on that. Which identity each routine starts from: `[Implement]`'s merge lines hold the merging user, `[Specificate]` holds the repository's developer, and the handoff line names whoever the unit is handed to. Nothing about resolution may block, delay, or retry-loop a post.

## Red-alert dedup — history and rejected alternatives

The rule itself is in the SKILL. Its history: the hourly runner produced one near-identical red post per hour for two days (2026-08-02〜04) from a single root cause — a repeated alert with no new information trains the operator to ignore alerts. Each tick is a fresh container, so no local state survives, but the Slack channel itself does, and the routine already reads and writes it — which is why the throttle is a read-before-post rule rather than a stored counter.

The threaded reply was added 2026-08-05, after a failure that *persisted* rather than repeated: four consecutive hourly ticks stopped at the superseded-plugin gate whose alert had been posted once at 08:01, producing nothing, while the channel was indistinguishable from a working fleet with nothing to do. A monitoring signal that cannot tell *healthy* from *broken and already reported* is not a monitoring signal (`workaholic:implementation` / `observability`). Rejected alternative: an exponential backoff on the reply (reply on the 1st, 2nd, 4th, 8th tick) — it reintroduces one level down the exact "no line means suppressed or dead?" ambiguity the reply exists to remove, while being harder to state and to check. Because the reply carries elapsed time and a tick count, each one carries information the previous did not. A reply that cannot be posted is not an error — Slack is never load-bearing here either.

## What a template can and cannot switch off

A live routine record carries `name`, `trigger`, `schedule`, `target repository`, `model`, `enabled` and its MCP connections — and no notification field of any kind. So the duplicate mobile push is not routine configuration: it is the Claude app's account-level notification for a routine session completing, which no template, script or report can touch. Turning it off is a developer act in the app's own settings, surfaced by `/setup-dev-routines` and stated there — a truthful "cannot" beats a claimed "did".

## The event bar's two precedents

The "an event earns its post" line reuses two precedents from this repository rather than inventing a bar: drop the low tier by default (the branch story keeps every concern; the PR body renders it without the `low` ones — `story/scripts/filter-low-concerns.sh`), and dedupe a repeat by its signature (red alerts only; announcements of events the session itself produced are new by construction). When an event is genuinely borderline, the tie goes to silence: an unread post costs attention every time it is scrolled past, while a missing one costs a question the session log answers.

## The carried-target disclosure (P9) — WITHDRAWN (2026-08-07)

**Withdrawn, not deleted.** P9 (2026-08-06) accepted a risk: the routine chain carried its notification target as a Slack thread URL in a pull-request body (P4's labelled line), and expected one in the Issue that starts the chain — on a public repository both are world-readable. Q1 retired the propagation the same week: the reply thread is now **found** by the stateless exact-token lookup (the SKILL's *One thread per feedback item*), so **the URL no longer reaches a public body at all** and there is nothing left to accept. The reasoning is kept because it is what a future "let's carry the URL again" proposal must answer: what the URL disclosed was the workspace subdomain (already inferable from the GitHub org), the channel id, and the message timestamp to the microsecond — no credential, no read or write for an outsider, but public issue and PR bodies are permanently archived and scraped, so the exposure was **not retractable**, which is what made it a decision rather than a detail. The adjacent risk was never accepted and **survives the withdrawal unchanged**: a routine feeds an Issue or pull-request body to an unattended agent, so on a public repository the **`Collaborators only` precondition stays required** (`workaholic:workaholify`, *Preconditions*) — it was never about the URL. The withdrawal's own cost is P4's benefit given up: when nobody pasted the Issue link into Slack, no exact token connects the pre-Issue conversation to the artifact and the routine starts a new root; the mitigation is a convention, not code — paste the Issue link into the thread you filed it from.

## Finding the thread — history

The lookup's normative statement lives in the SKILL (*One thread per feedback item*); this is how it got its shape. Re-deriving the thread by search put a reply in the wrong place on 2026-08-05: the search was a *guess*, and a guess in a notification path produces a message that looks right and is unrelated to the event. P4 (2026-08-06) removed the guess by **carrying** the answer — a labelled line in the pull-request body, written by `/specificate` and read back by `/implement`. Q1 (2026-08-07, developer's ruling) reversed the direction while keeping what P4 taught: statelessness removes the guess **by defining the search so that it cannot guess** — ordered exact-string searches only, a prohibition on fuzzy/recency matching by name, a written query bound, and a not-found branch that posts a new keyed root instead of picking the closest thing. Two of propagation's benefits were given up knowingly: no target is carried between routines (each pays its own bounded lookup), and the thread URL left the public bodies (the withdrawal above).

**Ticket `20260810163359` (2026-08-11) found the actual defect was never the design above — it was one unwritten detail underneath it.** Issue #360 kept reporting the same symptom Q1 was supposed to have fixed: a lookup that found nothing and posted a new root. FB `20260811084546` measured why, live: `dev-<repo>` is a **private** Slack channel, and `slack_search_public` — the connector's default, consent-free search tool — covers public channels only, so an exact `` `fb:<stem>` `` query against it returns zero results **by construction**, regardless of how faithfully the root carries the key (verified: the same query returned 0 via `slack_search_public` and an instant exact hit via `slack_search_public_and_private`). Q1 pinned the query shape — ordered, exact-string, bounded, no fuzzy matching — but never pinned the search *surface*, and the gap read as "search is unreliable" when it was "search never looked here." The fix is a one-line specification, not a mechanism change: cases 2 and 3 now name `slack_search_public_and_private` with `include_bots: true` explicitly, carried as a standing developer consent rather than re-asked per run (an unattended routine has no one to ask). A **persisted-key mechanism was drafted first** — a `thread_ref` field committed to the feedback record, checked before any search ran — and was independently ruled out by the developer the same day, before it shipped (FB `20260811084130`): a Slack thread coordinate committed to this **public** repository is exactly the exposure the P9 withdrawal (above) already found irretractable, under a new name. Both correction commits landed on `main` while a first implementation attempt of the persisted-key design was already in flight on an open pull request; that PR was closed unmerged rather than shipping a barred design once the correction was found. The scope-corrected search is the whole fix unless it is measured to still miss — and only then does a persisted key reopen as a question, constrained from the start to a store outside the repository (SKILL, above).

**Ticket `20260818062653` (2026-08-18) added the query-source clause to case 3 — the same shape of defect as the entry above: the run looked in the wrong place.** An `/implement` run merged PR #484 and posted its `🟢 Implemented` line top-level, mentioning the developer, while a live thread for the same feedback item already existed (`p1786960288121629`). Both searches missed for reasons the design permitted: case 2's `` `fb:<stem>` `` could not match because that thread's root is a **human** message written before the record existed, so it carries no key; and case 3 searched the URL of **the pull request the run had just opened**, a string no message in Slack could have contained, because it did not exist until minutes earlier. The `/specificate` run that wrote the ticket corroborated it from the other side — its own case 3 found the developer's existing thread by searching the **originating issue** URL, which existed before the run. The correction is a **query-source specification, not a mechanism change**: case 3 now says the URL it searches is one that pre-existed the run and that a self-created URL is never a query. The lookup's other constraints are deliberately untouched — the two-query bound, the private-inclusive surface, the fuzzy-matching prohibition, and case 4's keyed root — and this makes the failing case *less* likely rather than impossible: a human-rooted thread with no issue link pasted into it stays unfindable. Two reversals the ask also raised (lifting the effort ceiling, and letting `/specificate`'s reply carry the `` `fb:<stem>` `` key into a root it did not write) each reverse something written deliberately (Q1, 2026-08-07; FB `20260811084130`) and were left to the operator, unresolved by the run that made this change.
