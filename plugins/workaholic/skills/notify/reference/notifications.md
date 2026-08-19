# Notification reference — post shapes, session URL, disclosure terms

Companion to `SKILL.md` (*One thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*). The standing rules live in the SKILL; this file carries the exact shapes and the recorded decisions behind them.

## The shapes of the runner's posts

A template names its postable events and defers the line formats here. This file is the **catalog** a template draws from when it explicitly names an event — never blanket authorization: a shape's presence here does not permit a session to emit it unprompted (SKILL, *The prompt is the ceiling — no self-authorized shapes*). `<@U…>` follows the SKILL's mention rule; `<repo>` is the repository the session is running in, which it derives itself rather than being told. Two events (`/propose` finish, `/implement` unit finish) carry the **sole sanctioned** wording — the literal templates from issue #300, reconciled below with the shapes that predate them (P10, 2026-08-07), aligned against the developer's dictated wording in issue #333, and **narrowed to the finish alone on 2026-08-11** (issue #351 / mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`): the start shapes `📐 Proposing` and `🟠 Implementing` are **retired** — a routine posts its finish only, and the live routine records were edited to match the same day. Every other event keeps its pre-existing shape unchanged.

### `/propose` — the finish, plus a description root when no thread was found

```
🔵 Proposed - [#123 [Proposal] PR Title](<repo-url>/pull/123)
by the [routine](<session URL>) of <@U…>
```

`🔵 Proposed` retires the earlier `🟢 Proposed to <@U…> - ...` shape. Since 2026-08-14 it is a **reply** in every connector case — into the thread the stateless lookup found, or into the description root below when it found none. It is a keyed top-level line only on the tokened fallback, which cannot thread; there it carries `` `fb:<stem>` `` on its own line, never dropped. The retired `📐 Proposing` start once preceded it; nothing replaces it.

#### The description root — `/propose`, case 4 only

The root the run posts **before** the finish line when the lookup found no thread (SKILL, *One thread per feedback item* case 4, *The description root*). `/implement`'s case-4 finish line is unaffected and stays its own keyed root. Byte-identical in `workaholify/routines/fb.md`; a diff between the two copies is a drift to fix, never a second wording:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
`fb:<stem>`
<session URL>
```

Then `🔵 Proposed` above as a reply whose `thread_ts` is this message's timestamp, without the `` `fb:<stem>` `` line — the key lives on the root, which is what case 2 searches for. **No mention token of any kind appears on the root**: a `<@U…>` resolving to the Claude app would re-trigger the Slack app on the routine's own post, and a person's mention belongs on the reply that names them. The title and the sentence come from the feedback record the run just wrote; nothing is invented for the post.

**Why the root links the record and not an auto-filed issue** (the ticket's Open Decision, ruled 2026-08-14 — issue #443). The report's title asked for a short `[FB]` issue to be filed so the root had a URL to point at; the record's own file URL answers the same need without either of that option's costs. An issue filed **assigned** is re-discovered as an inbound ask by `/propose`'s clock-fired discovery on the next tick and **cannot be excluded** — `list-inbound-issues.sh` subtracts issues a feedback record already names, and the record naming this one was written *before* it, immutably; an **unassigned** issue is never discovered, which makes it safe and also makes it a page nobody is asked to act on. Opening an issue on this repository unattended would additionally be a new class of write: the confinement rule reserves issue-opening for `/fb`'s cross-repository mode behind a verbatim human confirmation. The accepted cost of linking the record instead: the `main` blob URL 404s until the proposal's pull request merges — which it does on opening, so the window is seconds, except when a scan finding holds the PR open, and then the run reports the link as pending rather than claiming it resolves.

**Why two messages do not breach the event bar.** *The event bar's two precedents* below and the SKILL's bright line both hold: the proposal is still **one** event. The root is not a second announcement — it is the same announcement's readable header, split off so the thread opens with something a human can answer instead of a status line. A found thread still receives exactly one message.

### `/implement` — a unit's finish only

```
🟢 Implemented - [#123 Title](<repo-url>/pull/123)
by the [routine](<session URL>) of <@U…>
```

**The authorship line is conditional, and it is a body line on every finish shape — never a fifth shape and never a second post** (2026-08-14, issue #454). A unit whose tickets are all the runner's own adds nothing; otherwise the finish line carries exactly one extra line, appended last:

```
tickets authored by <identity>
```

or, when this runner has no identity to compare against:

```
ticket authorship unresolved
```

The fact comes from `drive/scripts/unit-authors.sh` (`foreign` / `unresolved` / `mine`), which compares by slug through the one comparison `owns.sh` already uses. **It carries no mention token**: a `<@U…>` on a routine's own post has re-triggered the Slack app before, and the identity here is a plain email or slug for exactly that reason. `unresolved` is kept distinct from "authored by me" for the same reason `owns.sh` keeps it — a runner that cannot tell must not render as one that checked. This is **disclosure, not a policy change**: an empty `assignees:` still means claimable by anyone, and nothing about which units a run takes moved.

`🟢 Implemented` is the finish shape for the **ordinary** case: the unit's pull request opened and merged (the immediate-merge route; a scan finding that held the merge still finishes with this line, the open PR URL saying the rest) — it retires the earlier `🟢 Merge Requested for <@U…> - ...` shape, which announced exactly the same event in more words, and the `🟠 Implementing` start post (with the older `🟠 drive started - <unit-id>` it had itself retired); nothing replaces the start. Three outcomes keep their own finish shape rather than collapsing into `🟢 Implemented`, because each carries information the generic line would lose — whether an unattended merge happened, whether the unit is genuinely unfinished, or what named blocker stopped it (the bright line in the SKILL: *an event earns its post*):

```
🚀 Auto Merge - [#123 Title](<repo-url>/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

🟡 Handoff <@U…> - [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>

🔴 Blocked - `<signature>`
One sentence, max 25 words, what failed and what a human must do.
```

`🚀 Auto Merge` names no person and carries no mention token — a developer scanning the thread must be able to tell what merged without approval from what a person approved. It keeps the pre-existing merge shape's `from-branch → to-branch` body line verbatim; only the base template it extends moved from `🟢 Merge Requested` to `🟢 Implemented`'s simpler two-line form. `🟡 Handoff` and `🔴 Blocked` are unchanged from the shapes that predate this reconciliation.

**A human merge is not announced by `/implement` at all** — that was `[Consent]`'s job, and `[Consent]` is retired (`workaholic:workaholify`, *Routines*): "a human-merged pull request is now announced by nobody." The `Merged by <@U…>` purple-circle shape this section once documented erased with it (2026-08-09, qmu/workaholic#317) rather than being reassigned — nothing in the current system posts a human-merge finish line, so keeping the shape on the books described a post nobody makes. The auto/human distinction the shape used to carry survives anyway, in the silence itself: `🚀 Auto Merge` is the only merge line `/implement` ever posts, so its presence in a thread means the run shipped the unit unattended; a `review` unit's thread ends at `🟢 Implemented` and stays there even after a human merges the PR later, and the merge itself is always readable on GitHub regardless. A developer telling the two apart reads the thread, not a second emoji.

Exactly one finish per thread stays the rule (SKILL, *Which thread an `/implement` unit's posts land in*): a unit posts `🟢 Implemented` **or** one of the three outcome shapes above, never both — `handoff` is the finish, never a third post, and the same holds for a blocked or merged unit.

### `/prepare-release` — the repository tick's one line

```
📦 Release Preparation - <N> commit(s) waiting on <target>
One sentence, max 25 words, what a human must do (cut a release, declare a confirmation method).
Draft note: <draft release URL>
`deploy:<digest>` `deploy-day:<day_token>`
<session URL>
```

**And when the read is doubtful, the same root with the count withheld:**

```
📦 Release Preparation - refs not freshened (<refs_reason>); count unavailable on <target>
One sentence, max 25 words, what a human must do (restore the container's network, then re-read).
`deploy:<digest>` `deploy-day:<day_token>`
<session URL>
```

**A top-level keyed root, never a reply.** This event belongs to no feedback item — nobody *said* anything, the repository's own state changed — so it has no thread to land in and keys on its own `` `deploy:<digest>` `` instead, exactly as an `/implement` unit with no stem keys on `` `unit:<unit-id>` ``. The digest is `report-deploy-status.sh`'s, which hashes the substantive per-target state and **not** the base sha (`workaholic:ship` §7).

**The doubtful variant posts the degradation and withholds the number** (2026-08-18, the Open Decision the ticket carried). It is used whenever the read reports `doubtful: true` — the boundary collapsed to `full_history`/`unresolvable` under refs that were not freshened. Both alternatives were weighed and both are wrong on their own: staying silent is indistinguishable from a quiet repository, which is the invisible degradation the change exists to remove, and posting the bare count endorses a number the reader has just flagged. So the line says what it could not do and names no count, and the `Draft note:` line is omitted with it — a draft rendered from refs this read distrusts is not an artifact to send anyone to. The remaining lines, the token and its shape are unchanged.

**The dedup is the whole reason the line is postable at all.** Before posting, search `` `deploy:<digest>` `` exactly once (private-inclusive, `include_bots: true`, like every case-2 search): found ⇒ **post nothing**, because the answer has not changed since it was last said, and an hourly repeat of an unchanged status is the idle tick the bright line refuses. This is *not* the red-alert cool-down — there is no time window and no escalation; the key is the content itself, so a status that stops being true stops matching and a status that becomes true again posts once more.

**And a second search bounds the rate, because the digest alone did not** (2026-08-18, ticket `20260818214615`). Search `` `deploy-day:<day_token>` `` exactly once as well — found ⇒ **post nothing**, whatever the digest says. Two searches is this section's whole query budget and both gates are required, AND'd with `actionable || doubtful`.

*Measured, over the nine hours after the refs fix landed at 23:11 JST on 2026-08-18*: **nine posts in nine consecutive hours**, counts 10, 12, 14, 16, 18, 22, 30, 2, 2 — and **one** request behind all nine, "cut a release for marketplace". No hour was silent. The refs fix cured the accuracy half (the 2721/181/165 swings are gone) and left the rate untouched, because `unreleased_count` is in the digest's input and a commit lands on the base every hour on an active day: the digest prevents a *repeat* and never fired against an hourly *restatement*.

`day_token` is `report-deploy-status.sh`'s, `<Asia/Tokyo day>:<hash of the per-target needs sets>` — **what the tick is asking for, not how much of it there is**. So an unchanged ask is said once a day, while a **new kind** of ask — a target that starts needing a confirmation method, a target that appears — moves the token and is said the same hour. The day matches `[Standup]`'s stated rule that a daily post is a standing claim on attention, and `run-note-cadence.sh`'s existing `Asia/Tokyo` floor; like both, it is derived (from the clock and from Slack's own record) and stores no cursor.

**`deploy:<digest>` did not move.** Its derivation and format are unchanged — narrowing it was the obvious fix and was refused, because it had just been settled the same day (the doubtful redaction) and re-cutting a dedup key a day later is the churn this ticket exists to stop. The heading, the `📦`, the mention-token rule and the two existing gates are untouched too; the rate bound is a *third* condition, not a rewrite of the first two. **The case for changing nothing**, recorded rather than dismissed: the request genuinely is still open every one of those hours, and a daily floor can leave a renewed ask unsaid for the rest of the day. It loses to the measurement — nine identical asks in nine hours is how a channel teaches its readers to stop reading it — and the loss is bounded by keying on `needs` rather than on the clock alone.

**`actionable: false` posts nothing either**, whatever either token says: every target's `needs[]` empty means nothing is waiting and nobody has anything to do. A tick that reports a quiet repository is a tick that says nothing. **One exception, and only one**: `doubtful: true` posts the degraded variant above even when nothing looks actionable — precisely because "nothing is waiting" is one of the things stale refs can fabricate, so the quiet this gate protects would be the unreliable half of the read speaking for the repository. The gate is therefore `actionable || doubtful`, still AND'd with the digest search, and a container stuck offline says it once rather than hourly: the doubtful digest redacts the values that move with the refs, so it stops changing (`workaholic:ship` §7).

**No mention token of any kind** — no `<@U…>` for a person and none for the Claude app. The line names a repository state, not a person's work, and there is nobody whose turn it is; a mention would page whoever was named every hour for a condition that is nobody's in particular.

**The heading was renamed with the command, and it was free to move** (2026-08-18, issue #485 — `📦 Release status` before it). The 2026-08-17 rename left it alone on the stated ground that "the prefix is the notify lookup's own exact-string dedup key", which was wrong: the search above is for `` `deploy:<digest>` `` and nothing queries the heading, so no cutover duplicate was ever at stake. The token, the two gates and the `📦` are unchanged; only the words a human reads moved, to match the command that posts them.

**Then once more, from the verb to the noun** (2026-08-18, later the same day, issue #504). The record, in order: `📦 Release status` → `📦 Prepare release` → `📦 Release Preparation`. On seeing the second wording in a live post, the developer ruled the heading should **name the report** rather than repeat the command's imperative — a Slack root is something a human reads, not an instruction addressed to the machine. The reason a heading is free to move at all is the one stated above and is not restated per rename: nothing searches it. Deliberately **not** moved with it: the routine record's name (`[Prepare Release]` — convergence matches routines by name, so renaming it would create a second routine rather than rename the existing one), the command (`/prepare-release`), the `📦`, the `` `deploy:<digest>` `` token, and both posting gates.

**The `Draft note:` line points at the artifact; it never restates it** (2026-08-17, issue #472). Since the repository tick keeps each target's draft release note current, the note is where the answer lives — what is waiting, the procedure, the verification required. A notification's job is to bring a human *to* the artifact, so the line carries the URL and nothing more: summarising the note's contents into the post would make the note redundant and re-create the fragmentation the ask is about. Omit the line entirely when no draft exists yet (a repository whose cadence has not run, or one with no `gh`) rather than posting a dead link — the shape's other four lines are unchanged and still stand alone.

### `/standup` — the daily per-strategy digest

```
📣 Standup - <N> strategy/strategies, <M> moved since yesterday
<Strategy title> (<days> to <target_date>): one line, what moved and what waits.
<Strategy title>: no activity.
<K> item(s) not attributable to any strategy.
`standup:<YYYY-MM-DD>`
<session URL>
```

**A top-level keyed root, never a reply**, and **no mention token of any kind** — the same two reasons `📦 Release Preparation` carries none: no feedback item said anything, and the line names the repository's state rather than a person's work.

**One strategy line each, in the digest's own order, capped.** A quiet strategy gets the explicit `no activity` line rather than being dropped — a strategy missing from the digest reads as a strategy nobody is working on, which is a different claim. `strategies_omitted` above the cap is stated as a trailing count, never silently cut. The final `not attributable` line is a **count** and rides only when it is non-zero; enumerating it would make this a repository changelog, which is `/catch`'s job.

**Keyed on the date, not on the content.** A daily digest speaks for today even when today resembles yesterday; what the key prevents is two posts for one morning. Search the token exactly once (private-inclusive, `include_bots: true`): found ⇒ post nothing. `noop: true` from the digest posts nothing either, whatever the date says.

### `/housekeep` — the maintenance tick's two shapes

The stuck-pull-request reminder is a **top-level keyed root**, exactly as `📦 Release Preparation` is
and for the same reason: nobody *said* anything, the repository's own state did something, so
there is no thread to land in and the post keys on its own content instead.

```
🔧 Needs a decision - <the step's headline: how many pull requests, and what is blocking them>
One sentence, max 25 words, what the decision is (resolve a conflict, review it, fix a check).
`stuck:<digest>`
<session URL>
```

**The first line names the kind of finding, and the key does not move** (2026-08-18, issue #513).
It read `<N> pull request(s) waiting on a human` every time, so the varying half — the sentence
naming the decision — sat under an invariant heading and the post read the same whether the finding
was a merge conflict, an un-run auto-merge or a failing check. The heading now carries
`step-stuck-prs.sh`'s `headline`, derived from the `blocked_by` set the script already resolves
(`conflicting with main` / `waiting on review` / `with a failing check` / `still in draft` /
`behind main` / `with mergeability not yet computed`, and `stuck: <kind>, <kind>` when one post
covers several). **Visible wording only**: `` `stuck:<digest>` `` is still the sorted
`<number>:<blocked_by>` set, nothing searches the heading, and the 2026-08-17 release-tick rename
was reversed the next day precisely because the heading was mistaken for the dedup key. Making the
post more informative must not make it more frequent — both gates below are untouched.

**Two gates, both required, and an idle tick is silent.** Nothing waiting posts nothing; a state
already posted (the `` `stuck:<digest>` `` search finds it) posts nothing. The digest hashes the
sorted `<number>:<blocked_by>` set, so a pull request that is still stuck for the same reason
next hour is not news while a new one — or the same one stuck for a *different* reason — is. The
key is deliberately distinct from `` `deploy:<digest>` ``: one line reports what is waiting to
deploy and this one what is waiting on a person, and a shared key would let either dedup the
other away. **No mention token of any kind**: the line names a repository state, not a person's
work.

The check-in question is the opposite case — it is addressed to somebody, so it carries a
resolved mention and lands in the thread of the item it is about (a new keyed root only when the
lookup finds none):

```
❓ Question <@U…> - <what this tick could not decide>
One sentence, max 25 words, the question itself, with the two options when there are two.
`ask:<key>`
<session URL>
```

**Asked once, never re-asked.** `` `ask:<key>` `` is the content key, and an unanswered question
is not re-posted next hour: the red-alert `↳ still failing` escalation covers a machine-observable
state that persists, while a question is a demand on a person's attention, and repeating it turns
asking into nagging. Silence is never read as an answer — the unanswered set stays visible in the
tick log and the run report, and the post is still sitting in its thread. The mention is a
resolved `<@U…>` from the person's email; a bare `@name` pings nobody, and a Claude mention token
on a routine's own post re-triggers the app.

**The shape was measured against the channel and deliberately left as it is** (2026-08-18, issue
#513). Both `❓` posts `#dev-workaholic` has ever carried named their two options in one sentence,
exactly as the shape requires, and neither drew a reply — so the evidence says the wording is not
what silence is about, and tightening an instruction both examples already satisfy would be a
change with nothing behind it. What a reply is *for* was ruled on at the same time: a reply is a
person answering another person, and **nothing ingests a Slack reply back into the loop**. Building
an answer the loop itself consumes is a new mechanism, not a rewording, and it is unbuilt until
somebody scopes it.

### `/setup-user-routines` — the account updater's one line

```
🔄 Workaholic - <what changed, or the named refusal and what it could not read>
One sentence, max 25 words, which routines converged on which repositories, or what is not being converged.
`fleet:<digest>`
<session URL>
```

**A top-level keyed root, never a reply, and no mention token of any kind** — the same reasons `📦 Release Preparation` and `🔧 Needs a decision` carry none: no feedback item said anything, and the line names the state of the account's routines rather than a person's work. There is no thread for it to land in — a `user`-scoped routine has no repository artifact to key on.

**It posts only on a change or a refusal, and only once per distinct state.** A quiet fleet posts nothing at all; an hourly "nothing drifted" would be the standing claim on attention every idle tick in this catalog already refuses to make. The `` `fleet:<digest>` `` token is searched exactly once (private-inclusive, `include_bots: true`): found ⇒ post nothing. The digest covers what converged, on which repositories, and the refusal reason if there was one — so a *new* kind of drift, or a refusal that changes shape, is said the same hour, while an unchanged state is said once.

**The refusal is a post, not a silence, and that is the point.** `[Workaholic]` is the one routine whose entire job may be permanently unreachable — no `RemoteTrigger`-family tool is exposed to the routine-fired session class (measured 2026-08-19), so in that class it converges nothing, every hour, forever. A routine firing on time and doing nothing reads as healthy, which is the exact failure `workaholic:workaholify` §4 names about the web bootstrap; one keyed line saying `no_transport` by name is the minimum that makes it legible, and the digest gate keeps it to one.

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

The "an event earns its post" line reuses two precedents from this repository rather than inventing a bar: drop the low tier by default (the branch story keeps every concern; the PR body renders it without the `low` ones — `report/scripts/filter-low-concerns.sh`), and dedupe a repeat by its signature (red alerts only; announcements of events the session itself produced are new by construction). When an event is genuinely borderline, the tie goes to silence: an unread post costs attention every time it is scrolled past, while a missing one costs a question the session log answers.

## The carried-target disclosure (P9) — WITHDRAWN (2026-08-07)

**Withdrawn, not deleted.** P9 (2026-08-06) accepted a risk: the routine chain carried its notification target as a Slack thread URL in a pull-request body (P4's labelled line), and expected one in the Issue that starts the chain — on a public repository both are world-readable. Q1 retired the propagation the same week: the reply thread is now **found** by the stateless exact-token lookup (the SKILL's *One thread per feedback item*), so **the URL no longer reaches a public body at all** and there is nothing left to accept. The reasoning is kept because it is what a future "let's carry the URL again" proposal must answer: what the URL disclosed was the workspace subdomain (already inferable from the GitHub org), the channel id, and the message timestamp to the microsecond — no credential, no read or write for an outsider, but public issue and PR bodies are permanently archived and scraped, so the exposure was **not retractable**, which is what made it a decision rather than a detail. The adjacent risk was never accepted and **survives the withdrawal unchanged**: a routine feeds an Issue or pull-request body to an unattended agent, so on a public repository the **`Collaborators only` precondition stays required** (`workaholic:workaholify`, *Preconditions*) — it was never about the URL. The withdrawal's own cost is P4's benefit given up: when nobody pasted the Issue link into Slack, no exact token connects the pre-Issue conversation to the artifact and the routine starts a new root; the mitigation is a convention, not code — paste the Issue link into the thread you filed it from.

## Finding the thread — history

The lookup's normative statement lives in the SKILL (*One thread per feedback item*); this is how it got its shape. Re-deriving the thread by search put a reply in the wrong place on 2026-08-05: the search was a *guess*, and a guess in a notification path produces a message that looks right and is unrelated to the event. P4 (2026-08-06) removed the guess by **carrying** the answer — a labelled line in the pull-request body, written by `/propose` and read back by `/implement`. Q1 (2026-08-07, developer's ruling) reversed the direction while keeping what P4 taught: statelessness removes the guess **by defining the search so that it cannot guess** — ordered exact-string searches only, a prohibition on fuzzy/recency matching by name, a written query bound, and a not-found branch that posts a new keyed root instead of picking the closest thing. Two of propagation's benefits were given up knowingly: no target is carried between routines (each pays its own bounded lookup), and the thread URL left the public bodies (the withdrawal above).

**Ticket `20260810163359` (2026-08-11) found the actual defect was never the design above — it was one unwritten detail underneath it.** Issue #360 kept reporting the same symptom Q1 was supposed to have fixed: a lookup that found nothing and posted a new root. FB `20260811084546` measured why, live: `dev-<repo>` is a **private** Slack channel, and `slack_search_public` — the connector's default, consent-free search tool — covers public channels only, so an exact `` `fb:<stem>` `` query against it returns zero results **by construction**, regardless of how faithfully the root carries the key (verified: the same query returned 0 via `slack_search_public` and an instant exact hit via `slack_search_public_and_private`). Q1 pinned the query shape — ordered, exact-string, bounded, no fuzzy matching — but never pinned the search *surface*, and the gap read as "search is unreliable" when it was "search never looked here." The fix is a one-line specification, not a mechanism change: cases 2 and 3 now name `slack_search_public_and_private` with `include_bots: true` explicitly, carried as a standing developer consent rather than re-asked per run (an unattended routine has no one to ask). A **persisted-key mechanism was drafted first** — a `thread_ref` field committed to the feedback record, checked before any search ran — and was independently ruled out by the developer the same day, before it shipped (FB `20260811084130`): a Slack thread coordinate committed to this **public** repository is exactly the exposure the P9 withdrawal (above) already found irretractable, under a new name. Both correction commits landed on `main` while a first implementation attempt of the persisted-key design was already in flight on an open pull request; that PR was closed unmerged rather than shipping a barred design once the correction was found. The scope-corrected search is the whole fix unless it is measured to still miss — and only then does a persisted key reopen as a question, constrained from the start to a store outside the repository (SKILL, above).

**Ticket `20260818062653` (2026-08-18) added the query-source clause to case 3 — the same shape of defect as the entry above: the run looked in the wrong place.** An `/implement` run merged PR #484 and posted its `🟢 Implemented` line top-level, mentioning the developer, while a live thread for the same feedback item already existed (`p1786960288121629`). Both searches missed for reasons the design permitted: case 2's `` `fb:<stem>` `` could not match because that thread's root is a **human** message written before the record existed, so it carries no key; and case 3 searched the URL of **the pull request the run had just opened**, a string no message in Slack could have contained, because it did not exist until minutes earlier. The `/propose` run that wrote the ticket corroborated it from the other side — its own case 3 found the developer's existing thread by searching the **originating issue** URL, which existed before the run. The correction is a **query-source specification, not a mechanism change**: case 3 now says the URL it searches is one that pre-existed the run and that a self-created URL is never a query. The lookup's other constraints are deliberately untouched — the two-query bound, the private-inclusive surface, the fuzzy-matching prohibition, and case 4's keyed root — and this makes the failing case *less* likely rather than impossible: a human-rooted thread with no issue link pasted into it stays unfindable. Two reversals the ask also raised (lifting the effort ceiling, and letting `/propose`'s reply carry the `` `fb:<stem>` `` key into a root it did not write) each reverse something written deliberately (Q1, 2026-08-07; FB `20260811084130`) and were left to the operator, unresolved by the run that made this change.
