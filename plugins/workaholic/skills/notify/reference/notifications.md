# Notification reference — post shapes, session URL, disclosure terms

Companion to `SKILL.md` (*One thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*). The standing rules live in the SKILL; this file carries the exact shapes and the recorded decisions behind them.

## The shapes of the runner's posts

A template names its postable events and defers the line formats here. This file is the **catalog** a template draws from when it explicitly names an event — never blanket authorization: a shape's presence here does not permit a session to emit it unprompted (SKILL, *The prompt is the ceiling — no self-authorized shapes*). `<@U…>` follows the SKILL's mention rule; `<repo>` is the repository the session is running in, which it derives itself rather than being told. Two events (`/propose` design start/finish, `/implement` unit start/finish) carry the **sole sanctioned** wording — the literal templates from issue #300, reconciled below with the shapes that predate them (P10, 2026-08-07). Every other event keeps its pre-existing shape unchanged.

### `/propose` — design start and finish

```
📐 Designing for [#45 [FB] Issue Title](<repo-url>/issues/45)
by [Claude Code on the Web](<session URL>) of <@U…>

🔵 Proposed - [#123 [Proposal] PR Title](<repo-url>/pull/123)
by [Claude Code on the Web](<session URL>) of <@U…>
```

`🔵 Proposed` retires the earlier `🟢 Proposed to <@U…> - ...` shape and takes over its root role: whichever of the two posts is the first to land in a thread the stateless lookup did not find (SKILL, *One thread per feedback item*, case 4) carries `` `fb:<stem>` `` on its own line, never dropped — one shape now covers both a fresh root and a reply into a found thread, where two overlapping shapes covered only the root before.

### `/implement` — a unit's start and finish

```
🟠 Implementing for [#123 Proposal PR Title](<repo-url>/pull/123)
by [Claude Code on the Web](<session URL>) of <@U…>

🟢 Implemented - [#123 Title](<repo-url>/pull/123)
by [Claude Code on the Web](<session URL>) of <@U…>
```

`🟠 Implementing` retires the earlier terse `🟠 drive started - <unit-id>` shape as the unit's **only** start post. `🟢 Implemented` is the finish shape for the **ordinary** case: the unit reached its `review` effective policy's PR and stopped there — it retires the earlier `🟢 Merge Requested for <@U…> - ...` shape, which announced exactly the same event in more words. Three outcomes keep their own finish shape rather than collapsing into `🟢 Implemented`, because each carries information the generic line would lose — whether an unattended merge happened, whether the unit is genuinely unfinished, or what named blocker stopped it (the bright line in the SKILL: *an event earns its post*):

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

## The session URL

Every post carries the Claude Code Web session URL that did the work — the same URL the harness gives the session for its `Claude-Session:` commit trailer. It is what turns "merged by Claude" into something a developer can audit. If the URL is not discoverable in a given session, post without it: a notification missing one line beats a notification that did not happen.

## Mention resolution — how a session resolves a person

Look the person up through the Slack connector the routine already loads — `slack_search_users` on the identity in hand, `slack_read_user_profile` to confirm the match; a display-name search is the last resort, and a match that cannot be confirmed is not a match. When a session holds only a GitHub login, resolve through the email git records for the person (the merge or claim commit's author) and search on that. Which identity each routine starts from: `[Implement]`'s merge lines hold the merging user, `[Propose]` holds the repository's developer, and the handoff line names whoever the unit is handed to. Nothing about resolution may block, delay, or retry-loop a post.

## Red-alert dedup — history and rejected alternatives

The rule itself is in the SKILL. Its history: the hourly runner produced one near-identical red post per hour for two days (2026-08-02〜04) from a single root cause — a repeated alert with no new information trains the operator to ignore alerts. Each tick is a fresh container, so no local state survives, but the Slack channel itself does, and the routine already reads and writes it — which is why the throttle is a read-before-post rule rather than a stored counter.

The threaded reply was added 2026-08-05, after a failure that *persisted* rather than repeated: four consecutive hourly ticks stopped at the superseded-plugin gate whose alert had been posted once at 08:01, producing nothing, while the channel was indistinguishable from a working fleet with nothing to do. A monitoring signal that cannot tell *healthy* from *broken and already reported* is not a monitoring signal (`workaholic:implementation` / `observability`). Rejected alternative: an exponential backoff on the reply (reply on the 1st, 2nd, 4th, 8th tick) — it reintroduces one level down the exact "no line means suppressed or dead?" ambiguity the reply exists to remove, while being harder to state and to check. Because the reply carries elapsed time and a tick count, each one carries information the previous did not. A reply that cannot be posted is not an error — Slack is never load-bearing here either.

## What a template can and cannot switch off

A live routine record carries `name`, `trigger`, `schedule`, `target repository`, `model`, `enabled` and its MCP connections — and no notification field of any kind. So the duplicate mobile push is not routine configuration: it is the Claude app's account-level notification for a routine session completing, which no template, script or report can touch. Turning it off is a developer act in the app's own settings, surfaced by `/setup-routines` and stated there — a truthful "cannot" beats a claimed "did".

## The event bar's two precedents

The "an event earns its post" line reuses two precedents from this repository rather than inventing a bar: drop the low tier by default (the branch story keeps every concern; the PR body renders it without the `low` ones — `report/scripts/filter-low-concerns.sh`), and dedupe a repeat by its signature (red alerts only; announcements of events the session itself produced are new by construction). When an event is genuinely borderline, the tie goes to silence: an unread post costs attention every time it is scrolled past, while a missing one costs a question the session log answers.

## The carried-target disclosure (P9) — WITHDRAWN (2026-08-07)

**Withdrawn, not deleted.** P9 (2026-08-06) accepted a risk: the routine chain carried its notification target as a Slack thread URL in a pull-request body (P4's labelled line), and expected one in the Issue that starts the chain — on a public repository both are world-readable. Q1 retired the propagation the same week: the reply thread is now **found** by the stateless exact-token lookup (the SKILL's *One thread per feedback item*), so **the URL no longer reaches a public body at all** and there is nothing left to accept. The reasoning is kept because it is what a future "let's carry the URL again" proposal must answer: what the URL disclosed was the workspace subdomain (already inferable from the GitHub org), the channel id, and the message timestamp to the microsecond — no credential, no read or write for an outsider, but public issue and PR bodies are permanently archived and scraped, so the exposure was **not retractable**, which is what made it a decision rather than a detail. The adjacent risk was never accepted and **survives the withdrawal unchanged**: a routine feeds an Issue or pull-request body to an unattended agent, so on a public repository the **`Collaborators only` precondition stays required** (`workaholic:workaholify`, *Preconditions*) — it was never about the URL. The withdrawal's own cost is P4's benefit given up: when nobody pasted the Issue link into Slack, no exact token connects the pre-Issue conversation to the artifact and the routine starts a new root; the mitigation is a convention, not code — paste the Issue link into the thread you filed it from.

## Finding the thread — history

The lookup's normative statement lives in the SKILL (*One thread per feedback item*); this is how it got its shape. Re-deriving the thread by search put a reply in the wrong place on 2026-08-05: the search was a *guess*, and a guess in a notification path produces a message that looks right and is unrelated to the event. P4 (2026-08-06) removed the guess by **carrying** the answer — a labelled line in the pull-request body, written by `/propose` and read back by `/implement`. Q1 (2026-08-07, developer's ruling) reversed the direction while keeping what P4 taught: statelessness removes the guess **by defining the search so that it cannot guess** — ordered exact-string searches only, a prohibition on fuzzy/recency matching by name, a written query bound, and a not-found branch that posts a new keyed root instead of picking the closest thing. Two of propagation's benefits were given up knowingly: no target is carried between routines (each pays its own bounded lookup), and the thread URL left the public bodies (the withdrawal above).
