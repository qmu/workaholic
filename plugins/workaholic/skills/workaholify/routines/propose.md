---
type: Routine Template
id: propose
name: "[Propose] {repo_name}"
scope: developer
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 15 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
notifications: push
---

# [Propose] — supply the loop's ask and turn it into the work it warrants

**This routine absorbed `[Specificate]` on 2026-09-02** (the developer's instruction). Until
then the loop spread one act across two routines and a whole hour: `[Propose]` at `:40` read
the running identity's strategies and opened the next ask as a GitHub issue, and the **next
hour's** `[Specificate]` at `:15` discovered that issue and turned it into a record and a
ticket set. The seam bought nothing — the issue is the only artifact that crosses it, and the
session that opens it is best placed to ingest it. One routine now runs `/propose` first and
`/specificate` second in the same session, so the ask it just supplied is in the inbox its own
discovery reads seconds later. The loop is **`[Propose]` → `[Implement]`**: `[Propose]` at
`:15` supplies and specifies, `[Implement]` at `:30` drives what it queued, and the
ask-to-drive distance is fifteen minutes where the three-routine loop took fifty.

**The ordering inside the run is load-bearing.** `/propose` judges the strategies against what
has actually landed — at `:15` that is everything up to the previous hour's `[Implement]`,
settled for forty-five minutes, the same freshness the retired `:40` slot bought.
`/specificate` then discovers inbound issues oldest-first, so the proposal just opened queues
behind any older human ask rather than jumping it. Running them the other way would ingest an
inbox the run is about to add to, and re-open the hour-long seam this merge closes.

**`scope: developer`** — every developer needs their own copy, so `/setup-dev-routines`
converges it and `/setup-repo-routines` never sees it. `/propose` acts on the strategies
assigned to the **running identity** and opens issues assigned to it; `/specificate` acts only
on issues assigned to that identity and reports `not_mine` otherwise. One repository-wide copy
would route every developer's directions through whichever account created it (measured
2026-08-14, issue #451). The scope is the template's own field because both commands and both
setup sheets have to read one source (`workaholic:workaholify` §5, *Two scopes, two commands*).

**Fires on a fixed hourly schedule (:15 — the API floor is one hour)** — FB
`20260810085032`/issue #336, 2026-08-10: loop-engineering cadence over instant webhook
reaction. Every developer's copy fires independently on its own tick, and the **data** decides
whose work it is: `/specificate` reads whatever ask is in hand and reports `not_mine` when it
is not theirs.

**A schedule fire carries nothing in hand, so the `/specificate` half discovers its own asks**:
`list-inbound-issues.sh` lists the open GitHub issues on this repository assigned to the
session's own identity, minus those a feedback record already names, and takes each returned
issue as an ask in hand, oldest-first, one full run per issue. This is **not** the retired
`[Propose Batch]` sweep: that read the repository's own backlog for something to propose; this
reads the inbound ask channel, and feedback stays the only input that can originate a proposal.
A tick whose propose half opened nothing and whose discovery returns nothing still reports
`nothing_in_hand` and ends — the honest answer, meaning "the inbox is empty".

**It carries the Slack connector to read the channel** (2026-08-23, the developer's
instruction to drop the Claude Tag dependency). The inbound sweep reads the repository's
designated channel (`WORKAHOLIC_INBOUND_SLACK_CHANNEL`, default `<repo_name>`) for asks a
person wrote **without mentioning any bot**, and files each as an `[FB]` issue assigned to the
running identity — which the same run's `/specificate` half then ingests. The sweep posts its
receipt (the `📥 受理` reply and the `:inbox_tray:` reaction) and its result reaches its one
reader as a Claude notification (`notifications: push`); this is the only template declaring
the field.

**The prompt names the commands and nothing else** (2026-09-01, the developer's instruction).
Everything a session running this routine may do — the post shapes, the transports, what it may
read, and what it must never emit — lives in `plugins/workaholic/commands/propose.md` and
`plugins/workaholic/commands/specificate.md`, versioned with the plugin and shipped with it. A
routine record is an **account-level** object no repository can edit, so every rule that lived
in a prompt had to be re-pasted into every developer's copy in every project before it took
effect. A rule written in the command reaches every account's routine on its next run with no
routine edit at all.

**The command is the ceiling** (`workaholic:notify`, *The command is the ceiling*): the shapes
the two commands' own notification sections name are the only ones a session running this
routine may emit, and `workaholic:notify`'s `reference/notifications.md` mirrors each of them
verbatim, so a drift between the two is a defect to fix rather than a second wording. What
stays in the prompt is the one instruction the commands cannot carry — the load fallback that
finds and reads them when the plugin did not bind.

## Prompt

Run `/propose`, then run `/specificate`.

If a command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/propose.md` and `<src>/commands/specificate.md` and follow them in that order with every script path under `<src>`.
