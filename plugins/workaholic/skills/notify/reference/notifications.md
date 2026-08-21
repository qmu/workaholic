# Notification reference — post shapes, session URL, disclosure terms

Companion to `SKILL.md` (*One thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*). The standing rules live in the SKILL; this file carries the exact shapes and the recorded decisions behind them.

## The shapes of the runner's posts

A template names its postable events and defers the line formats here. This file is the **catalog** a template draws from when it explicitly names an event — never blanket authorization: a shape's presence here does not permit a session to emit it unprompted (SKILL, *The prompt is the ceiling — no self-authorized shapes*). `<@U…>` follows the SKILL's mention rule; `<repo>` is the repository the session is running in, which it derives itself rather than being told. Two events (`/specificate` finish, `/implement` unit finish) carry the **sole sanctioned** wording — the literal templates from issue #300, reconciled below with the shapes that predate them (P10, 2026-08-07), aligned against the developer's dictated wording in issue #333, and **narrowed to the finish alone on 2026-08-11** (issue #351 / mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`): the start shapes `📐 Proposing` and `🟠 Implementing` are **retired** — a routine posts its finish only, and the live routine records were edited to match the same day. Every other event keeps its pre-existing shape unchanged.

### `/specificate` — the finish, plus a description root when no thread was found

```
🔵 Proposed - [#123 [Proposal] PR Title](<repo-url>/pull/123)
by the [routine](<session URL>) of <@U…>
```

`🔵 Proposed` retires the earlier `🟢 Proposed to <@U…> - ...` shape. Since 2026-08-14 it is a **reply** in every connector case — into the thread the stateless lookup found, or into the description root below when it found none. It is a keyed top-level line only on the tokened fallback, which cannot thread; there it carries `` `fb:<stem>` `` on its own line, never dropped. The retired `📐 Proposing` start once preceded it; nothing replaces it.

#### The description root — `/specificate`, case 4 only

The root the run posts **before** the finish line when the lookup found no thread (SKILL, *One thread per feedback item* case 4, *The description root*). `/implement`'s case-4 finish line is unaffected and stays its own keyed root. Byte-identical in `workaholify/routines/specificate.md`; a diff between the two copies is a drift to fix, never a second wording:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
`fb:<stem>`
<session URL>
```

Then `🔵 Proposed` above as a reply whose `thread_ts` is this message's timestamp, without the `` `fb:<stem>` `` line — the key lives on the root, which is what case 2 searches for. **No mention token of any kind appears on the root**: a `<@U…>` resolving to the Claude app would re-trigger the Slack app on the routine's own post, and a person's mention belongs on the reply that names them. The title and the sentence come from the feedback record the run just wrote; nothing is invented for the post.

**Why the root links the record and not an auto-filed issue** (the ticket's Open Decision, ruled 2026-08-14 — issue #443). The report's title asked for a short `[FB]` issue to be filed so the root had a URL to point at; the record's own file URL answers the same need without either of that option's costs. An issue filed **assigned** is re-discovered as an inbound ask by `/specificate`'s clock-fired discovery on the next tick and **cannot be excluded** — `list-inbound-issues.sh` subtracts issues a feedback record already names, and the record naming this one was written *before* it, immutably; an **unassigned** issue is never discovered, which makes it safe and also makes it a page nobody is asked to act on. Opening an issue on this repository unattended would additionally be a new class of write: the confinement rule reserves issue-opening for `/fb`'s cross-repository mode behind a verbatim human confirmation. The accepted cost of linking the record instead: the `main` blob URL 404s until the proposal's pull request merges — which it does on opening, so the window is seconds, except when a scan finding holds the PR open, and then the run reports the link as pending rather than claiming it resolves.

**Why two messages do not breach the event bar.** *The event bar's two precedents* below and the SKILL's bright line both hold: the proposal is still **one** event. The root is not a second announcement — it is the same announcement's readable header, split off so the thread opens with something a human can answer instead of a status line. A found thread still receives exactly one message.

### `/implement` — a unit's finish only

```
🟢 Implemented - [#123 Title](<repo-url>/pull/123)
by the [routine](<session URL>) of <@U…>
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

🟡 Handoff <@U…> - [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>

🔴 Blocked - `<signature>`
One sentence, max 25 words, what failed and what a human must do.
```

`🚀 Auto Merge` names no person and carries no mention token — a developer scanning the thread must be able to tell what merged without approval from what a person approved. It keeps the pre-existing merge shape's `from-branch → to-branch` body line verbatim; only the base template it extends moved from `🟢 Merge Requested` to `🟢 Implemented`'s simpler two-line form. `🟡 Handoff` and `🔴 Blocked` are unchanged from the shapes that predate this reconciliation.

**A human merge is not announced by `/implement` at all** — that was `[Consent]`'s job, and `[Consent]` is retired (`workaholic:workaholify`, *Routines*): "a human-merged pull request is now announced by nobody." The `Merged by <@U…>` purple-circle shape this section once documented erased with it (2026-08-09, qmu/workaholic#317) rather than being reassigned — nothing in the current system posts a human-merge finish line, so keeping the shape on the books described a post nobody makes. The auto/human distinction the shape used to carry survives anyway, in the silence itself: `🚀 Auto Merge` is the only merge line `/implement` ever posts, so its presence in a thread means the run shipped the unit unattended; a `review` unit's thread ends at `🟢 Implemented` and stays there even after a human merges the PR later, and the merge itself is always readable on GitHub regardless. A developer telling the two apart reads the thread, not a second emoji.

Exactly one finish per thread stays the rule (SKILL, *Which thread an `/implement` unit's posts land in*): a unit posts `🟢 Implemented` **or** one of the three outcome shapes above, never both — `handoff` is the finish, never a third post, and the same holds for a blocked or merged unit.

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

### `/moderate` — the maintenance tick's one shape

**One shape, and the reason is measured** (2026-08-19, the developer's instruction). This tick
used to emit a second root, `🔧 Needs a decision`, keyed `` `stuck:<digest>` `` — a top-level post
carrying no mention token, saying how many pull requests were blocked and on what. It is retired
for the same reason `📦 Release Preparation` is: **a status line addressed to nobody is noise**,
and its dedup key never made it otherwise. The finding survives; only the broadcast is gone.
`step-stuck-prs.sh` still resolves every blocked pull request and the decision each one needs,
and hands them to step 10 as `action: "ask"` candidates carrying an `ask_key` — where they either
become a question addressed to a person, or stay in the tick log.

That is the tick's whole rule now: **it speaks only to ask somebody something.** A finding it
cannot turn into a question with a name on it does not reach Slack — it is a log row, and where
it is work, a ticket.

The check-in question is a **reply into the thread of the item it concerns**, and it is the one
post in this file that **carries a mention token**, because it is the one post that needs a
specific person to do something.

```
🙋 Question <@U…> - <what this tick could not decide>
One sentence, max 25 words, the question itself, with the two options when there are two.
`ask:<key>`
<session URL>
```

**The emoji moved from `❓` on 2026-08-19**, when this became the tick's only voice: a mark a
reader should recognise as "my turn to answer" rather than as one more machine notice. Nothing
searches the heading — the key is `` `ask:<key>` `` — so the change cost nothing, the same
property the 2026-08-17 release-tick rename got wrong and the 2026-08-18 one got right.

**Asked once, never re-asked.** `` `ask:<key>` `` is the content key, and an unanswered question
is not re-posted next hour: a question is a demand on a person's attention, and repeating it
turns asking into nagging. Silence is never read as an answer — the unanswered set stays visible
in the tick log. `ask-question.sh` holds the per-tick cap, the daily bound and the quiet-hours
window; a question it suppresses is recorded as held and handed back on the next eligible tick,
which is what makes suppression a delay rather than a loss.

### `/setup-user-routines` — posts nothing, and the reason is the audience

**The `🔄 Workaholic` keyed root is retired** (2026-08-19, the developer's correction). The
`[Workaholic]` routine has no Slack connector and emits no post of any kind.

The reasoning is the one that retired `🔧 Needs a decision` and `📦 Release Preparation` from
`/moderate`, plus one thing specific to this routine. The shared half: a status line addressed
to nobody is noise whatever its dedup key, and "which of your routines I updated this hour" is
a status line. The specific half: this is an **account-level** routine acting on the operator's
**own** account, so its audience is exactly one person — the one who is also the only person
who can act on a refusal it reports. A channel of colleagues is the wrong room for it.

**Its result reaches that person as a Claude notification instead** — `notifications: push` on
the routine record, declared by its template and diffed by the setup commands like any other
field. It is the **only** routine that declares it. Every other one is a channel's business,
and pushing a copy of a Slack post to a phone is the same noise twice.


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
