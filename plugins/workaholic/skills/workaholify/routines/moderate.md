---
type: Routine Template
id: moderate
name: "[Moderate] {repo_name}"
scope: repository
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 50 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep]
mcp: [Slack]
---

# [Moderate] — the maintenance tick, one copy for the repository

**This routine was renamed on 2026-08-19, and its cutover was the ordered half of a swap**
(issue #526; the names it held are in this file's git history). Behaviour did not move: it
still runs `/moderate`, still fires at `:50`,
still declares `autofix_on_pr_create: true` and `scope: repository`, still names the same two
post formats. Only `name:` moved — and it moved **into a name that was live until the same
change**. The routine that held it, running `/specificate` at `:15`, is now `[Specificate]`.

**The cutover is done, and `renamed_from:` is gone with it** (2026-08-19). This routine
passed briefly through `[Propose]` — a name `[Specificate]` was vacating the same day,
which made the two migrations ordered: converging this one before the other was renamed would
have left two routines with one rendered name, indistinguishable to a convergence that matches
by name. The field existed to carry that instruction into the sheet and both setup commands'
reports. The fleet has cut over, so it is **deleted from this template**, exactly as the rule
requires — it described a migration, not a routine. The mechanism is unchanged and documented
in `workaholic:workaholify` §5 for the next rename that needs it.

**Nothing is deduped by a routine's name**, so no post changes frequency or threading under
this rename: nothing searches a heading or a routine name. (The printed key lines were removed
from every post on 2026-08-22 — case 2 searches the record filename the root already links, and
the tick and question keys were searched by nothing at all.) This is stated
here rather than left to be re-derived — the 2026-08-17 release-tick rename was reversed the
next day on exactly that mistaken assumption.

**`scope: repository`** — the repository needs exactly **one** of this routine, configured by
one designated person or a project/service account through `/setup-repo-routines`.

**The ask said `/setup-dev-routines`, and that sentence is answered rather than dismissed**
(resolved 2026-08-17, issue #471). It was written before the nine steps were decomposed. Once
they were, seven of the nine read the **repository**, not the developer: issue triage,
auto-merge reminders and documentation drift produce identical findings from every copy, and
the check-in would ask five questions per copy per hour. N copies firing hourly is the exact
failure the `repository` scope was introduced for on 2026-08-14 (issue #451), and the plugin
**cannot detect it** — a routine is an account-level record no other account can list. The
argument that pointed the other way was step 8 (proposals), where per-developer copies would at
least be racing under their own identities; that argument is moot, because step 8 ships
**gated** and emits nothing until the operator rules on it.

Two steps genuinely are personal — the inbound sweep's Gmail, Drive and Slack connectors belong
to whichever account runs the tick — and they degrade **honestly** rather than silently: each
surface is reported by name (`no_surface: gmail`), so a single account's copy says exactly whose
inboxes it could and could not see. The `unanswered-asks` step added on 2026-08-26 reads the
repository's **own** channel rather than anyone's inbox, so it belongs to this scope and not to a
personal one; it degrades by the same rule (`no_slack_transport`, `channel_unreadable` — never an
unread channel reported as a quiet one). If the operator wants both, the faithful shape is a split
(a developer-scoped inbound routine and this repository-scoped one), which is a template to add
rather than a line to change. Moving this one is a **one-line** change to `scope:`; both setup
commands and both setup sheets read this field, so nothing else has to move with it.

**Fires at :50** — the API's minimum interval is one hour, a bare `:00` minute is rewritten to
server jitter, and `15` / `30` / `45` are taken by `[Specificate]`, `[Implement]` and
`[Prepare Release]`. Landing last in the hour is deliberate: the tick reads what the other three
have just done.

**`autofix_on_pr_create: true`, and `Write`/`Edit` are granted rather than inherited.** This
routine is not a pure reader like `[Prepare Release]`: it writes its own tick log under
`.workaholic/moderations/`, and filing a finding means writing a feedback record or a ticket —
which publishes behind a pull request, exactly as `/specificate` does. A pull request this routine
opened and then left red is a stuck artifact nobody owns, so the flag is `true` for the same
reason it is true on `[Specificate]`.

**Its container is discarded, so the tick commits its own log.** A routine tick runs in a fresh
clone; a log left in that checkout would take every dedup's memory with it and leave an hourly
unattended process with no audit trail. `persist-log.sh` is the tick's closing act and the one
thing this routine puts on `main` — an append to its own log, through the publish tree, leaving
the checkout byte-identical and creating no branch (`workaholic:moderate`, *The tick log*).

**What it never does**, and none of it is left to the prompt: it never merges a pull request,
never pushes into a branch the claim protocol owns (step 4 reports conflict state and the claim
holder resolves it), never edits a live strategy, never closes an issue, never rewrites a
document on `main` — its own append-only tick log is the single exception, stated above — and
never calls `AskUserQuestion` — step 9 asks humans **in Slack**. Every one of those rules lives
in `workaholic:moderate` and its `reference/workflow.md`, which is why this prompt does not
restate them.

**The prompt is the ceiling** (P3, Q2, P10): the literal formats below are the only shapes a
session running this routine may emit, and `workaholic:notify`'s `reference/notifications.md`
mirrors each of them verbatim. A future edit to either copy is a drift to fix, never a second
wording.

**And a shape addressed to somebody only reaches them if somebody else is speaking** (2026-08-31, mission `notify-the-person-a-directed-question-addresses`). Every post here reaches Slack as the operator's own account, and Slack notifies nobody of their own message — so in the single-developer configuration the `🙋` question's `<@U…>`, the one token this loop keeps unconditionally, resolved to the poster and paged nobody. The prompt below therefore names **which transport carries the question reply**: the tokened script when a bot token is configured, into the root's own `thread_ts`, so a different account speaks it. That is a prompt line because *the prompt is the ceiling* — the rule in `workaholic:notify` sanctions the shape and only this template lets a session running this routine emit it. The **root**, the `✅` confirmation and the `🟢`/`⚫` reconciliation replies stay on the connector: none of them mentions anyone.

**Every shape here is addressed to somebody, because a status line addressed to nobody is noise** (2026-08-19, the developer's
instruction). This routine used to emit a second, `🔧 Needs a decision`, and the merged-in
release tick a third, `📦 Release Preparation`; both were top-level roots carrying no mention
token. Measured on `#dev-workaholic` the same day: ten `📦` lines in ten consecutive hours for
one unchanged request, none answered by anyone. Both are retired. A finding this tick cannot
turn into a question addressed to somebody does not reach Slack at all — it stays in the tick
log and, where it is work, becomes a ticket.

## Prompt

Run `/moderate`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/moderate.md` and follow it with every script path under `<src>`.

Read Slack only through the Slack connector, and only as a step asks: the `unanswered-asks` step names one channel and one window and hands that read back to you — no mention of any bot is required for a message to count, and you never reply to, react to, or capture a message you read there. Emit only the shapes below.

The `question-answers` step names one thread per outstanding question, each on a coordinate it already holds: read exactly those threads, one read each, and never search Slack or read channel history for one. Record each person's answer through `record-answer.sh`, or name why you did not — a machine's own post is never an answer. React `:ballot_box_with_check:` on an answer message you actually recorded this tick, and post **no reply** for that event, in any thread.

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

Post that reply through the **tokened transport** — `bash <src>/skills/specificate/scripts/notify-slack.sh --thread-ts <the root's ts> "<the reply text>"` — whenever `SLACK_BOT_TOKEN` is set, so a bot speaks it and its `<@U…>` notifies the person even when that person is the account this session posts as. That script is `workaholic:notify`'s **fallback** transport, and it is selected here for its **identity** rather than for its availability: this one reply is a directed post, which is the only case where which account speaks matters. The connector returns the root's `ts` when it posts the root, so hand that same value straight through: never search for it. With no token, post the reply through the connector exactly as you post the root. Report per question which surface carried it — `bot`, `connector`, or the transport's own refusal word — and never retry a refusal. **The root, the `✅` confirmation and the `🟢`/`⚫` reconciliation replies always ride the connector**, unchanged.

For each previously asked question whose subject the check-in read as settled this tick, post one confirmation as a reply into the thread where it was asked — no mention token, once ever per question:

```
✅ 解消を確認 - <the question's subject, one line>
One sentence: what the tick measured that says it settled.
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
