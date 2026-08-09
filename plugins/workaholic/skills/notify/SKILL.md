---
name: notify
description: The runtime notification model — which events earn a Slack post, the exact post shapes, and the stateless reply-thread lookup — used by /implement's per-unit posts, /propose's thread root and finish, and the routine prompts, which defer to it.
user-invocable: false
metadata:
  internal: true
---

# Notify

The notification model of the unattended loop, stated once. `workaholic:drive`'s claim and route steps, `workaholic:propose`'s finish post, and the routine prompts ("the `workaholic:notify` lookup") defer here rather than restating rules; `workaholic:workaholify` owns the routine templates and their setup sheets and points here for the model the templates defer to. Relocated detail: [reference/notifications.md](reference/notifications.md) (post shapes, session URL, mention mechanics, red-alert history, the withdrawn disclosure, the lookup's history).

## One thread per feedback item — the notification model

The unit of a notification is the reader's item of interest, not the emitter's step: one Slack thread per feedback item, carrying its whole life. The `[Propose]` routine posts the root; every later event of that item is an in-thread reply. The key is the feedback record's filename stem, embedded verbatim in the root as `` `fb:<stem>` `` — the identifier that lives in the repository (`feedback:` relations, `supersedes`, the publishing PR's diff), so a later session derives it from the artifact in hand; the issue number rides along as a human pointer only.

Finding the thread is **stateless** (Q1, 2026-08-07 — nothing carries a target between routines; the search is defined so it cannot guess). Ordered cases, take the first that applies — every search an **exact-string** Slack search, never a similarity or content match:

1. The session's own trigger message — reply there; that message is the item's thread. Not a search, and not reducible to one: a hand-off knows its target at write time, and a message written before the record existed can never carry the key.
2. Search `` `fb:<stem>` `` — the key a thread root already carries, derived from the repository, never from Slack (`drive/scripts/unit-feedback-stems.sh` for `/implement`; the record `/propose` just wrote for its finish post).
3. Search the Issue or pull-request URL — or its `#<number>` reference when no URL is in hand, a substitute and never an extra query — which finds the originating human thread when somebody pasted the link into Slack.
4. No exact match → post a **new root** carrying `fb:<stem>` — never a keyless top-level line (two roots with one key is repairable; a keyless post is not attributable to anything).

**Fuzzy matching is prohibited by name**: never a similarity match, never "the most recent thread that looks related", never recency — it is what put a reply in the wrong place on 2026-08-05, and a guess in a notification path is a message that looks right and is unrelated to the event. The not-found branch is what makes the search safe: a lookup that cannot find the thread **says so** by starting one. **The bound is a written number**: **at most two search queries per lookup** (cases 2 and 3, one each), results capped to the top few matches, and **no full-channel read at any point** — search returns matches; channel history returns everything and is never the instrument. **Resolve once per run and reuse it**: a unit's start and finish go to the same thread — statelessness is between runs, never within one. (History and the withdrawn disclosure: [reference/notifications.md](reference/notifications.md).)

### Which thread an `/implement` unit's posts land in

These posts are the unattended run's (`/implement` — the routine and any caller-side loop): they exist so an absent operator can tell a working fleet from a dead one. **An attended `/drive` session posts nothing to Slack** — the developer is watching the run, and its report is the session's.

A unit's start and finish are **per-unit, never per-run** ("a run started" names no item, so it has no thread to land in). `drive/scripts/unit-feedback-stems.sh` resolves the unit's artifacts to their deduped feedback stems. Rules:

- Several stems → post into each thread, once per stem per event. No stem → key on `` `unit:<unit-id>` ``, never keyless (the unit id, not the PR number: the start posts before any pull request exists).
- Start is always `🛠️ Implementing for [...]` (issue #300's literal template, [reference/notifications.md](reference/notifications.md)); exactly one start and one finish per thread, and the finish's shape follows the outcome: `🛠️ Implemented` for the ordinary review-stop, `🚀`/`🟣` merge, `🟡` handoff, `🔴` blocked. A handoff is the finish, never a third post.
- Never re-announce a merge the channel already carries (a resumed unit can reach the route step twice).

The bot notice `claim.sh` posts (bot token, no threading) is a different surface and is deliberately left alone; neither surface is load-bearing.

## Post shapes, mentions, and the red-alert dedup

The exact shapes of the runner's posts (📐 designing / 📐 proposed / 🛠️ implementing / 🛠️ implemented / 🔴 blocked / 🟡 handoff / 🚀 auto merge / 🟣 human merge) are in [reference/notifications.md](reference/notifications.md); a template names its postable events and defers the shapes there. `/propose`'s and `/implement`'s start/finish pairs carry issue #300's literal wording as the **sole** sanctioned format for those four events (P10, 2026-08-07) — they retire the earlier `🟢 Proposed`, `🟠 drive started`, and `🟢 Merge Requested` shapes, which said the same things in different words; the outcome-specific finish shapes (`🚀`/`🟣` merge, `🟡` handoff, `🔴` blocked) are unchanged, since each carries information the generic finish line would lose. Standing rules:

- 📐 Proposed is the `[Propose]` routine's thread root; its `` `fb:<stem>` `` line is never dropped. The root announces only the pull request you just created in this session, exactly once — post nothing if you created none, and never announce another session's work.
- Every post carries its session URL when discoverable; a post missing it still posts. No thread URL rides a public Issue or pull-request body — the carried target is retired and its recorded disclosure withdrawn (Q1; [reference/notifications.md](reference/notifications.md)).
- Naming a person means mentioning them: resolve to a Slack user id and write `<@U…>` — plain `@name` pings nobody. Email is the reliable key (a GitHub login is not a Slack handle). The fallback is non-blocking: an unresolved id posts the plain name rather than not posting.
- A red failure alert is deduped by its failure signature — the failed precondition or step plus its one-line reason class, stable across ticks: never a SHA, a timestamp, a file count or any varying detail. Before posting, read the channel's recent history (~50 messages) and suppress only the same signature inside a 24-hour cool-down; the rule suppresses repeats, never first reports. A suppressed tick names the suppression in its terminal report (`alert suppressed as duplicate - <signature>`) and posts one line as a threaded reply on the existing alert (`↳ still failing - <signature>, first reported <time>, <N> ticks`) — the reply is not itself rate-limited, since only a fresh reply answers "is this still happening". The cool-down suppresses the **top-level** post and nothing else: a changed signature or a first report always posts a root, and an unreadable history posts the alert anyway, because silence must never be produced by a failure of the mechanism that decides to be silent.
- The orange/green/yellow/purple/rocket posts announce events the session itself produced and are new every time; deduping those would hide real work.

## The prompt is the ceiling — no self-authorized shapes

A session may emit only the notification events and post shapes its own routine prompt or invoking command names. Nothing else authorizes one: not a shape documented in this skill or its [reference/notifications.md](reference/notifications.md) catalog, and not a post the session itself made or reasoned about earlier in the same run — this documentation describes the sanctioned wording for events a session was already instructed to post, it never grants permission to post. An event or shape not named by the prompt or command becomes standing behavior only after developer confirmation, and citing this skill's own text is not a substitute for that confirmation. Measured origin (FB `20260807082554`, issue #298): an `/implement` run posted a `🟣 Merged by` line its routine prompt never specified, justifying the addition from this skill's documentation and its own earlier in-session reasoning — exactly the move this rule forbids.

## The bright line — what earns a post

Slack is the only surface — the repository's `dev-<repo_name>` channel; no mobile or push notification. An event earns its post by being something a developer must act on or stay aware of: post a unit started, a proposal opened, a merge, a handoff, a blocked-on-precondition failure; do not post an idle tick, a claim, a heartbeat, a ticket archived, a commit, a passing test, or a build — the tie goes to silence.
