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

Read Slack only through the Slack connector, and only as a step asks: the `unanswered-asks` step names one channel and one window and hands that read back to you — no mention of any bot is required for a message to count, and you never reply to, react to, or capture a message you read there. Emit only the shapes below.

The `question-answers` step names one thread per outstanding question, each on a coordinate it already holds: read exactly those threads, one read each, and never search Slack or read channel history for one. Record each person's answer through `record-answer.sh`, or name why you did not — a machine's own post is never an answer. React `:ballot_box_with_check:` on an answer message you actually recorded this tick, and post **no reply** for that event, in any thread — the outcome reply below is a different event, posted only once the loop has acted on the answer.

When the tick's rendered post says to post, post this root as a new top-level message — no mention token of any kind on the root:

```
🔎 Moderation - <N> change(s), <M> question(s)<, <K> step(s) could not read — only when K > 0>
<on the morning tick only, first: the per-strategy digest — numbered strategies, bold title on its own line, headline commits since yesterday, honesty line naming tickets and the window>
<what happened to the repository, one line per changed step that has an event>
<one line per step that could not read, after the event lines: ⚠️ <step> — <status>: <reason>, at most 5 then "and <K> more">
<session URL>
```

Then post each question the check-in step cleared as a reply into that root, addressed to the resolved person:

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

For each candidate the `thread-reconcile` step hands back, find the item's thread through the stateless lookup, **read it first**, and post one reply only when its last status reply is `🔵 Proposed` or `🟡 Handoff` and the pull request it names has merged or closed. A thread already carrying its finish is never touched, and no thread found means nothing to correct — post nothing and report it:

```
🟢 Implemented - [#123 Title](<repo-url>/pull/123)
Merged outside the loop by <who> on <when> — no run posted this item's finish.
```

```
⚫ Closed - [#123 Title](<repo-url>/pull/123)
Closed without merging outside the loop on <when> — no run posted this item's finish.
```

If the rendered post says not to post, post nothing at all — no root, no question, ever. An hour with nothing changed and nothing to ask is silent.


Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
