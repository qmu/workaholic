# Notification reference — post shapes, session URL, disclosure terms

Companion to `SKILL.md` §5 (*One thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*). The standing rules live in the SKILL; this file carries the exact shapes and the recorded decisions behind them.

## The shapes of the runner's posts

A template names its postable events and defers the line formats here. `<@U…>` follows the SKILL's mention rule; `<repo>` is the repository the session is running in, which it derives itself rather than being told.

```
🟢 Proposed to <@U…> - [#123 [Proposal] Issue Title](<repo-url>/pull/123)
One sentence, max 40 words, what the ask is — and, when the PR carries work, what it proposes.
`fb:<stem>` · <session URL>

🔴 drive blocked - `<signature>`
One sentence, max 25 words, what failed and what a human must do.

🟠 drive started - `<unit-id>`
`<branch>`, one sentence, max 25 words, what this unit contains only.

🟢 Merge Requested for <@U…> - [#123 Issue Title](<repo-url>/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

🟡 Handoff <@U…> - [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>
```

A merge uses the 🟢 Merge-Requested shape with its line swapped for the actor: `🚀 Auto Merge by Claude` when the unit's recorded `merge_policy` was `auto` and `/ship` merged it, `🟣 Merged by <@U…>` when a human merged it during the run. That distinction is the point — a developer scanning the thread must be able to tell what merged without approval from what a person approved — and it is why the auto line names no person and carries no mention token.

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

## The `Notify-Thread:` disclosure — accepted, with its terms (2026-08-06)

`Notify-Thread:` puts a Slack thread URL into a pull-request body, and the routine chain expects one in the Issue that starts it; on a public repository both are world-readable. The developer accepted this, and the terms are recorded because "we looked at it and decided" and "nobody looked" are indistinguishable a year later. What it discloses: the workspace subdomain (already inferable from the GitHub org), the channel id, and the message timestamp to the microsecond. It is not a credential and grants no read or write; its residual value is post-compromise convenience and metadata accumulation (enough timestamps profile a team's working hours). Public issue and PR bodies are permanently archived and scraped, so the exposure is small but not retractable — which is what makes it a decision rather than a detail. The bigger adjacent risk is the input, not the URL — an untrusted issue body reaching an unattended agent — and its mitigation, the `Collaborators only` precondition, is required, not accepted. Revisit if the channel begins carrying customer material or the repository starts receiving issues from outside the collaborator set; the cheapest alternative is to stop putting the URL in the Issue and let `/propose` open the thread itself.
