# Notification reference — post shapes, session URL, disclosure terms

Companion to `SKILL.md` (*One thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*). The standing rules live in the SKILL; this file carries the exact shapes and the recorded decisions behind them.

## The shapes of the runner's posts

A template names its postable events and defers the line formats here. This file is the **catalog** a template draws from when it explicitly names an event — never blanket authorization: a shape's presence here does not permit a session to emit it unprompted (SKILL, *The prompt is the ceiling — no self-authorized shapes*). `<@U…>` follows the SKILL's mention rule; `<repo>` is the repository the session is running in, which it derives itself rather than being told. Two events (`/specificate` finish, `/implement` unit finish) carry the **sole sanctioned** wording — the literal templates from issue #300, reconciled below with the shapes that predate them (P10, 2026-08-07), aligned against the developer's dictated wording in issue #333, and **narrowed to the finish alone on 2026-08-11** (issue #351 / mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`): the start shapes `📐 Proposing` and `🟠 Implementing` are **retired** — a routine posts its finish only, and the live routine records were edited to match the same day. Every other event keeps its pre-existing shape unchanged.

### A post never mentions the identity it is posted as

**A self-mention notifies nobody, so it is not a mention — it is decoration** (2026-08-23, the developer's instruction). Every routine post reaches Slack **as the developer's own account** (connector primary, or the tokened fallback bound to the same person), so a `<@U…>` resolving to that same account produces no notification, no badge and no unread: Slack does not notify you of your own message. The attribution line `by the [routine](<session URL>) of <@U…>` had carried that token on every `🔵 Proposed` and `🟢 Implemented` since the shapes were written, and `🟡 Handoff <@U…>` named the runner the same way. All three drop it. **The session URL stays** — it is the whole point of the line, and the surface the developer opens to answer.

The rule generalises rather than enumerating three shapes: **resolve the mention target and the posting identity, and emit no `<@U…>` when they are the same.** Mentioning *someone else* is untouched and is exactly what a mention is for — which is why `🙋 <@U…>`, the maintenance tick's question, keeps its token unconditionally: it addresses a named assignee, it is the one post whose entire purpose is to reach a person, and a loop whose blockers reach nobody is the defect that produced issue #584. Nothing else in the catalog mentions anyone: the `📝 FB` description root, `🚀 Auto Merge`, `🔴 Blocked`, `⚪ Paused` and `📣 Standup` carry no token by their own prior rules, and this change does not give them one.

The measured cost, stated rather than hidden: a reader can no longer tell from the finish line alone *which* account's routine posted it in a channel several people's routines post into. That was already only readable as the mention, which rendered as the reader's own name and read as self-addressed; the account is the message's own author, which Slack shows, and the run report names it in words.

### `/specificate` — the finish, plus a description root when no thread was found

```
🔵 Proposed - [#123 [Proposal] PR Title](<repo-url>/pull/123)
by the [routine](<session URL>)
```

`🔵 Proposed` retires the earlier `🟢 Proposed to <@U…> - ...` shape. Since 2026-08-14 it is a **reply** in every connector case — into the thread the stateless lookup found, or into the description root below when it found none. It is a top-level line only on the tokened fallback, which cannot thread; there it carries the **record's URL** (`<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md`) rather than a bare key — the same identifier, in the one form that is also readable, so the fallback post stays attributable without printing a machine token at a person (2026-08-22). The retired `📐 Proposing` start once preceded it; nothing replaces it.

#### The description root — every case 4

The root the run posts **before** the finish line when the lookup found no thread (SKILL, *One thread per feedback item* case 4, *The description root*). **`/implement` posts it too, since 2026-08-22** — the shipped alternative was a top-level line opening with a status emoji and a pull request number and ending in a bare machine key, which the developer ruled unusable on sight. Byte-identical in `workaholify/routines/specificate.md` and `workaholify/routines/implement.md`; a diff between the copies is a drift to fix, never a second wording:

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
🟢 Implemented - [#123 Title](<repo-url>/pull/123)
by the [routine](<session URL>)
```

**The authorship line is retired from the post; the fact stays in the run report** (2026-08-21, the developer's instruction). Between 2026-08-14 and this change a unit whose tickets were not the runner's appended one body line — `tickets authored by <identity>`, or `ticket authorship unresolved` — to its finish post. It is gone from every finish shape. Two reasons, and the second is the stronger one:

- **It was noise on a post this repository spends effort keeping short.** The finish line exists so a human can see one event at a glance; a second line about provenance is not that event, and Slack renders a bare email as a `mailto:` link, so the disclosure arrived as link furniture rather than as a sentence.
- **It printed a value that meant its own absence.** A cloud container whose `.claude/git-identities` mapping is missing keeps `noreply@anthropic.com`, so the line read `tickets authored by noreply@anthropic.com` — a placeholder rendered as an author. `unresolved` existed to keep "could not tell" distinct from "mine", and the post said the opposite of what the runner knew (issue #547).

**What did not change**: `unit-authors.sh` still returns `foreign` / `unresolved` / `mine`, and `/implement`'s per-unit run report still names the authors — the surface a person reads when they want the provenance. Disclosure moved to where it is read on purpose; it was not dropped.

`🟢 Implemented` is the finish shape for the **ordinary** case: the unit's pull request opened and merged (the immediate-merge route; a scan finding that held the merge still finishes with this line, the open PR URL saying the rest) — it retires the earlier `🟢 Merge Requested for <@U…> - ...` shape, which announced exactly the same event in more words, and the `🟠 Implementing` start post (with the older `🟠 drive started - <unit-id>` it had itself retired); nothing replaces the start. Three outcomes keep their own finish shape rather than collapsing into `🟢 Implemented`, because each carries information the generic line would lose — whether an unattended merge happened, whether the unit is genuinely unfinished, or what named blocker stopped it (the bright line in the SKILL: *an event earns its post*):

```
🚀 Auto Merge - [#123 Title](<repo-url>/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

🟡 Handoff - [#123 Issue Title](<repo-url>/pull/123)
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

`🚀 Auto Merge` names no person and carries no mention token — a developer scanning the thread must be able to tell what merged without approval from what a person approved. It keeps the pre-existing merge shape's `from-branch → to-branch` body line verbatim; only the base template it extends moved from `🟢 Merge Requested` to `🟢 Implemented`'s simpler two-line form. `🟡 Handoff` and `🔴 Blocked` are unchanged from the shapes that predate this reconciliation.

**A human merge is not announced by `/implement` at all** — that was `[Consent]`'s job, and `[Consent]` is retired (`workaholic:workaholify`, *Routines*): "a human-merged pull request is now announced by nobody." The `Merged by <@U…>` purple-circle shape this section once documented erased with it (2026-08-09, qmu/workaholic#317) rather than being reassigned — nothing in the current system posts a human-merge finish line, so keeping the shape on the books described a post nobody makes. The auto/human distinction the shape used to carry survives anyway, in the silence itself: `🚀 Auto Merge` is the only merge line `/implement` ever posts, so its presence in a thread means the run shipped the unit unattended; a `review` unit's thread ends at `🟢 Implemented` and stays there even after a human merges the PR later, and the merge itself is always readable on GitHub regardless. A developer telling the two apart reads the thread, not a second emoji.

Exactly one finish per thread stays the rule (SKILL, *Which thread an `/implement` unit's posts land in*): a unit posts `🟢 Implemented` **or** one of the three outcome shapes above, never both — `handoff` is the finish, never a third post, and the same holds for a blocked or merged unit.

### `/propose` — the inbound sweep's receipt: a reply in the swept message's thread, a reaction on the message

**A capture the channel cannot see did not happen, as far as the person who wrote it is concerned** (2026-08-26, the developer's instruction). The sweep filed the `[FB]` issue and left **nothing** on the message it filed — so from `#dev-<repo>` a message that became an issue and a message nobody read are byte-identical. Measured the same day: two asks written at 18:56 and 19:20 JST were both captured as issues #620 and #621 within the hour, and the developer, seeing no trace in the channel, asked why neither had been treated as feedback. The capture worked; only its receipt was missing.

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<session URL>
```

**One reply per filed issue, into the swept message's own thread** — `thread_ts` is the `ts` half of the `slack-ref` the run just wrote into the issue body, so the coordinates are already in hand and **no lookup runs**: this is the model's case 1 (SKILL, *One thread per feedback item*), not a search, and the two-query bound is untouched because no query is made. A message with no thread gets one, rooted on itself, which is exactly where a person looking at that message will find it.

**It carries no mention token**, by the standing rule: the reply reaches Slack as the developer's own account and the person it would name is normally the message's own author, so a `<@U…>` there notifies nobody. Slack's own thread-participation notice reaches the author, which is the whole mechanism this receipt relies on.

**And a reaction on the message itself: `:inbox_tray:`** (2026-08-26). A reply lives *inside* a thread, so from a channel scroll a captured ask and an ignored one still look identical — a person has to open the thread to find out which happened. The reaction is the same receipt at a glance, in the one place someone scrolling the channel is already looking. It is the emoji the reply already speaks with (`📥`), so one event keeps one vocabulary, and **this line is the single source for the name**: the routine template and the drift pin read it from here rather than restating it.

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

**Keyed on the date, not on the content.** A daily digest speaks for today even when today resembles yesterday; what the key prevents is two posts for one morning. Search the token exactly once (private-inclusive, `include_bots: true`): found ⇒ post nothing. `noop: true` from the digest posts nothing either, whatever the date says.

### `/moderate` — the moderator's hourly thread: one root, its questions inside it

**One thread per tick, and two speech acts told apart by position** (2026-08-21, the developer's design). The tick posts a **root** carrying what changed in the hour, and every question it has goes out as a **mentioned reply inside that root's thread**. The root is orientation and is addressed to nobody; the replies are directed and carry a name. Two kinds of speech, one place to look, no second routine.

```
🔎 Moderation - <N> change(s), <M> question(s)
<on the morning tick only, first: the per-strategy digest — numbered strategies, bold title on its own line, headline commits since yesterday, honesty line naming tickets and the window>
<what happened to the repository, one line per changed step that has an event>
<session URL>
```

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

**Two gates, and an idle hour is silent.** The root posts when there is at least one question **or** at least one changed step. `idle` posts nothing; so do `no_previous_tick` (everything would read as changed, the loudest and least informative first impression) and `no_log` — a mechanism that could not read must never announce quiet.

**What was retired to get here.** The tick used to reply its one question into the thread of the **item** it concerned, with no root of its own; before that it emitted two status roots, `🔧 Needs a decision` and `📦 Release Preparation`, both retired on 2026-08-19 because a status line addressed to nobody is noise whatever its dedup key (measured on `#dev-workaholic`: ten `📦` lines in ten consecutive hours for one unchanged request, none answered). That measurement stands and this root does not reverse it — **this root is not addressed to nobody in the same sense**: it exists to carry the questions under it, and it never posts on an hour with neither a question nor a change. The cost that was paid is stated rather than hidden: a person following one item's own thread no longer sees the tick's question there, so every root line links the item it is about.

**Asked once, never re-asked**, and **the ledger is the tick log, never the post** (the `` `ask:<key>` `` line was printed at the reader until 2026-08-22 and searched by nothing — `ask-question.sh` matches the step id derived from the key, in `.workaholic/moderations/`, and has read Slack at no point). An unanswered question is not re-posted next hour: a question is a demand on a person's attention, and repeating it turns asking into nagging. Silence is never read as an answer — the unanswered set stays visible in the tick log. `ask-question.sh` holds the per-tick cap, the daily bound, **the working-day gate and the quiet-hours window**; a question it suppresses is recorded as held and handed back on the next eligible tick, which is what makes suppression a delay rather than a loss.

**Working days, not only working hours** (2026-08-21). The gate checked the clock alone, so a question found at 10:00 on a Sunday was posted into a channel nobody was reading — and its own asked-once gate then guaranteed it was never posted again on a day somebody was. `WORKAHOLIC_WORK_DAYS` (default `1-5`) holds the weekend, and held is not dropped: the finding waits for Monday.

**And an answer the tick read is stamped where it was written: `:ballot_box_with_check:`, a reaction and nothing else** (2026-08-28, mission `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`). A person who answers in the question's thread has no way to tell whether the loop read them. The stamp is a **reaction on the answer message** — **no reply is posted for this event, in any thread** — because a reply into a thread the person is already reading is the hourly restatement this catalog has retired posts for twice, while a reaction says *received* at a glance in the one place they are already looking. **This line is the single source for the name**: the routine template and the drift pin read it from here rather than restating it, and it is deliberately **not** the receipt's `:inbox_tray:` — capturing a channel message and reading an answer to our own question are two different events, and one emoji answering both is how a reader stops being able to tell them apart.

It rides the **coordinate already in hand** — the `(channel, ts)` of the message the tick just read, on the thread coordinate `ask-question.sh --record-ask` recorded when the question was posted — so there is **no lookup and no second query**, the same case-1 property the inbound sweep's receipt relies on. **Only an answer this run actually recorded** is stamped: one an earlier tick recorded already carries that tick's stamp, and a second an hour later is exactly the restatement above; a candidate the run did not record gets nothing. And it is **never load-bearing** — the answer is recorded and any issue filed *before* the stamp is attempted, so a failure is reported as `ack_failed: <reason>` and changes nothing about the recording, the question's state, or the filing.

**Two audiences, and this serves one of them.** A reaction carries no link and is invisible to anyone reading the issue rather than the thread. That is accepted: the person who wrote the answer is reading the thread, and where the answer produced an issue, that issue is assigned and GitHub notifies — a reply carrying its link would be the same noise twice, which is the argument that shaped this whole catalog.

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
