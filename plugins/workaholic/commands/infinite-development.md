---
name: infinite-development
description: Observe inbound Slack and feedback issues, answer people, dispatch due work, and end without waiting.
---

# Infinite Development

Execute one short tick. Use Japanese for human-facing free text. Keep identifiers, URLs,
commands, slugs, and established technical terms unchanged. Read plugin files with the Read
tool because shell reads from an installed plugin may require unattended permission.

## Observe

Read `git status --porcelain` once. Report a dirty checkout and its file count because this
tick is already executing that unreviewed plugin behavior. Do not block, modify, or commit it.

Observe both inbound sources before dispatch:

1. Read `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default: repository name) through the Slack
   connector. Capture each message durably before advancing the cursor.
2. Run
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/list-inbound-issues.sh`.
   These are assigned, open GitHub feedback issues not already captured on main or an open
   branch. An unreadable result is reported and is never treated as an empty inbox.

New human Slack activity or a new assigned feedback issue resets adaptive observation to the
short interval. A successful quiet observation advances the idle backoff. If either configured
source is unreadable, preserve the quiet streak and use provider retry. A new feedback issue
makes propose-then-specificate due on this tick.

`formation_pending: true` is the intake/implementation ownership boundary. Dispatch
propose-then-specificate for the whole oldest-first page and allocate **zero new implement
runners on this tick**. This is derived from unsettled issues and proposal branches by the
reader, not from a timer or ticket-count guess. Existing implement runners continue; they are
never killed. A later tick may implement only after the reader says formation is settled.

## Answer Slack

Fetch the dedup ledger with
`bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-swept-slack-refs.sh`. If it is
unreadable, skip ask capture as `sweep_dedup_unreadable`.

For each unswept message written by a person:

- Skip Workaholic's own posts by their shapes: `📝 FB`, `🔎 Moderation`, `🔵 Proposed`,
  `🟢 Implemented`, `📥 受理`, and `💬`.
- For a repository question, read its thread. If this loop has not answered, reply:

```
💬 [<質問を一行で>]
<80語以内の平易な日本語による回答と根拠の場所>
<session URL>
```

- For an ask to build, change, fix, or redirect work, write it through:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/file-inbound-ask.sh \
  --slack-ref <channel>:<ts> --permalink <url> \
  --subject 'person:<name>' --assignee <running-login> \
  [--feedback '<direction refs>'] <owner/name> "<title>" <body-file>
```

  Then reply in that message's thread and add `:inbox_tray:` to the same coordinate:

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<依頼をどう受け取り、specificate が次にどう扱うか。80語以内>
<session URL>
```

- A reply under the loop's own `🙋` question is an answer, not a new ask; moderate records it.
- React to other human messages with `:eyes:` and do not reply.

Never answer at the channel root when a thread was requested. A mid-loop question or correction
does not stop the loop or reset its anchor. An explicit stop prevents further dispatch and names
the roles still running.

## Announce landed asks

Run
`bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-unannounced-closed-asks.sh`.
For each readable item, resolve the exact `fb:<stem>` Slack thread, read it, and post one
finish reply only if that thread has no prior finish from this loop. If the thread is missing
or ambiguous, post nothing. Read the finish-line shape from
`skills/notify/reference/notifications.md` only when a reply is due, and use it exactly. Report `announced`, `already_announced`,
`thread_unresolved:<reason>`, `post_failed:<reason>`, or `held:<reason>`.

## Dispatch

List current role workers once. Release completed native children after recording their result.
Never start a second worker for a role already running.

Read each cadence from the loop tick log with both filters:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh \
  --owner loop --step-prefix loop-finish-<role> --latest-tick
```

An empty or unreadable finish is due. A failed attempt still records its finish time.

| Role | Due | Command |
| --- | --- | --- |
| implement | every work tick, subject to claimable work and fanout | `commands/implement.md` |
| propose | default 15 minutes, immediately after a captured ask or newly observed assigned feedback issue | `commands/propose.md`, then `commands/specificate.md` |
| moderate | 30 minutes | `commands/moderate.md` |

Dispatch due roles in the background and never await them. Native agents use bounded background
children. Other agents call
`sh <work-skill>/scripts/codex-loop.sh --dispatch <role>`.

For implement, derive claimable units with `loops/scripts/claimable-units.sh` only when issue
discovery reports `formation_pending: false`. When formation is pending, report
`implement allocation: 0 (mission_formation_pending)` without running the claimable reader.
Otherwise fanout is:

`min(WORKAHOLIC_IMPLEMENT_FANOUT default 1, claimable units, available child capacity)`.

Before each runner beyond the first, apply `WORKAHOLIC_MAX_LOAD_PER_CORE` when configured.
Never stop a running worker because of load, never refuse the first runner, and never turn an
unreadable load into zero capacity. A non-advancing runner may free a fanout slot only when
`loops/scripts/read-runner-advance.sh` proves it; do not kill it.

Start `loops/scripts/tick-progress.sh` in the background and render the previous completed
reading. It may be one tick old. Null or unreadable counts stay named and never become zero.

## Report and end

Return one short Japanese block:

- dirty checkout, only when dirty;
- each Slack action or named degradation;
- each assigned feedback issue observation or unreadable issue source;
- each ask announcement result;
- roles spawned or reaped; use `loops: none due` when all were quiet;
- implement allocation and any load, fanout, or advancement refusal;
- the latest progress reading and its observation time;
- each completed worker's `executed`, `outcome`, and `reason`;
- where this report is delivered.

Say `idle` alone when nothing happened. Claim completion only from merged work, an empty queue,
and reconciled pull requests. Then end this tick without polling, waiting for workers, or
summarizing work whose result has not arrived.
