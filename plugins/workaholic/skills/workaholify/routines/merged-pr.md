---
type: Routine Template
id: merged-pr
name: "[Consent] {repo_name}"
trigger: github-pr-merged
trigger_kind: github
trigger_event: pull_request.closed
trigger_filters: is merged = true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Consent] — announce a merge into its feedback item's thread

Renamed from `Merged PR` on 2026-08-04 by the developer's ruling: merging the pull
request is the approval in this workflow, so the routine that announces it is named for
what the event *means* — consent — not for the mechanics. The template `id` stays
`merged-pr`. A live routine still named `Merged PR <repo>` reads as `unknown` in the
drift report until renamed through `/setup-routines`' verbatim-confirmed refresh.

No cron: it waits to be invoked. This is the routine that makes a merge an announceable
event, which is the whole reason every artifact reaches `main` through a pull request.

**It owns the merged-pull-request event, including a merged proposal's** (decided
2026-08-05, when the ask arrived to start `[Drive]` on a merged proposal instead). One
event gets one owner, and this is the template whose subject already *is* that event —
`[Drive]` does not become a second watcher of it. What that ask actually needs is an
**invoker**: measured the same day, a routine record has no event-subscription field, so
nothing in the record says how an unscheduled routine comes to run (`workaholify` SKILL,
*What a routine can be triggered by*). A companion claim — that this routine has never
fired anywhere — was retracted on 2026-08-06: it was read off an absent `last_fired_at`,
which distinguishes nothing.
Narrowing "a merge" to "a proposal's merge" is likewise not a trigger setting — it is the
invoker's decision and this prompt's, which is why the key derivation below reads the
repository rather than the event payload.

**It replies; it does not found.** A merge is one event in a feedback item's life, so it
lands in that item's thread rather than as a top-level line of its own. The threading
model, the key and the not-found fallback are stated once in the `workaholify` SKILL,
*One thread per feedback item*; this template implements it and does not restate it.

**Its subject is an external event, which is what made it fragile.** The earlier prompt
said "about the pull request" without ever saying *which*, and a cloud session has no
state and no memory of what was already announced — so when two PRs merged four seconds
apart (2026-08-01 04:19 JST, #135 and #137), two sessions started and **each announced
both**, producing four messages in visibly different wording. N merges landing before
their sessions run gives N sessions × N merges. A single merge in isolation looked
correct, which is why it survived until a productive drive loop merged twice in a minute.

## Prompt

Announce **exactly one** merged pull request: the one whose merge started this session.

Route it by the three ordered cases in the `workaholify` SKILL, *One thread per feedback item*: reply in this run's own trigger message's thread when one can be identified, otherwise find the item's thread by its key, otherwise post a new root. This routine fires on a merge rather than on a Slack message, so the first case will usually not apply — it is stated because any event that does carry a trigger message must behave the same way everywhere.

For the key search, first derive the **feedback key** — the filename stem of the feedback record the merged work traces to. It is in the repository, not in Slack: the PR's own diff when the PR published the record, or the `feedback:` field of the mission the PR's tickets name. Then search the channel `dev-[project name]` for `` fb:<stem> `` and reply **in that thread**, in the format below.

-----------
🟣 Proposal merged by <@U…> - [#123 Issue Title](https://github.com/org-name/repo-name/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

-----------

Rules, in order of precedence:

1. **One message, one pull request.** Never announce more than one, even when several merged recently. Other recent merges are not this session's to report — another session was started for each of them.
2. **If you cannot identify which merge started this session, post nothing and stop.** Silence is the correct failure mode for a notification. Do not fall back to "announce whatever merged most recently": that fallback is exactly the defect this rule exists to prevent, and it produces a message that looks right while being unrelated to the event.
3. Never re-announce a pull request that already has a merge notification in the channel — in a thread or at top level. Check the recent channel history before posting.
4. **Slack is the only notification surface.** Post to the channel and send no mobile or push notification. This routine's one postable event is the merge that started it — a merge is exactly the class of event a developer must stay aware of (`workaholify` skill, *Slack is the only surface*).
5. **`<@U…>` is a real mention, not a placeholder.** Resolve the merging user to their Slack user id — through the email git records for them, since a GitHub login is not a Slack handle — and write the token; fall back to the plain name only when it cannot be resolved, and never let resolution delay the post (`workaholify` skill, *Naming a person means mentioning them*).
6. **A missing key is not a reason to stay silent, and never a reason to post keyless.** If the merge traces to no feedback record, or the record's thread cannot be found, post a **new root** carrying `` `fb:<stem>` `` (or, with genuinely no record, the merged PR's own `#<number>` as the key) and put this message in it. Rule 2 governs *which merge*; this rule governs *where it lands*, and the two must not be confused — a merge you identified always gets posted somewhere attributable.
