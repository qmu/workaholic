---
type: Routine Template
id: propose
name: "[Propose] {repo_name}"
scope: developer
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 40 * * * *
autofix_on_pr_create: false
model: claude-opus-5
allowed_tools: [Bash, Read, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
notifications: push
---

# [Propose] — the routine that supplies the loop's own ask

**The third turning routine** (2026-08-21, issue #555). `[Specificate]` turns an ask into a
record and the work it warrants; `[Implement]` drives that work; this one **supplies the ask**,
so the loop turns without a person having to write the next ticket. What a person supplies
instead is the direction — a strategy's Aim, Schedule and Assignee.

**`scope: developer`** — every developer needs their own copy, so `/setup-dev-routines`
converges it and the other two setup commands never see it. `/propose` acts on the strategies
assigned to the **running identity** and opens issues assigned to it, so one repository-wide
copy would route every developer's directions through whichever account created it. That is
the measured 2026-08-14 reasoning (issue #451) that keeps `[Specificate]` developer-scoped, and
it applies here for the same reason and with the same force.

**Fires at `:40`, after `[Implement]` and before the next hour's `[Specificate]`.** The
judgment is made against what has actually landed, so it must run after the hour's driving
rather than before it. The loop therefore **closes across hours, not within one**: a proposal
opened at 14:40 is ingested at 15:15 and driven at 15:30 — one turn is one hour, which is also
the routines API's minimum interval. `:40` is non-zero for the same measured reason every other
minute here is (a bare `:00` is rewritten to server jitter) and shares its minute with nothing.

**It writes nothing into the repository and opens no pull request**, which is why
`autofix_on_pr_create` is `false` and `allowed_tools` carries no `Write`/`Edit`. Its only write
is a GitHub issue, and that lands outside the tree — the contract `/standup` and
`/prepare-release` already hold, and the reason this adds no unattended-`main`-writer class to a
repository whose conflicts are resolved append-only.

**It carries the Slack connector to read the channel** (2026-08-23, the developer's
instruction to drop the Claude Tag dependency). Before the strategy judgment the
run sweeps the repository's designated channel (`WORKAHOLIC_INBOUND_SLACK_CHANNEL`, default
`<repo_name>`) for asks a person wrote **without mentioning any bot**, and files each as
the same `[FB]` issue the Claude Tag route produced — assigned to the running identity, so the
next `[Specificate]` ingests it (`workaholic:propose`, *The inbound sweep*). The tag route
cost a tagged session per ask and stopped capturing at the usage limit; this reads the channel
as the account itself.

**And since 2026-08-26 it posts exactly one shape: the sweep's receipt** (the developer's
instruction). Until then it posted nothing at all, which made a captured ask and an ignored one
byte-identical from the channel — measured the same day, two asks became issues within the hour
and the developer, seeing no trace in the thread, asked why neither had been treated as
feedback. The receipt is **two signals for two audiences on one event**: the threaded reply,
which carries the issue link for whoever opens the thread, and a **reaction on the message
itself**, which says the same thing to whoever is only scrolling the channel — a reply lives
inside a thread and is invisible from a scroll. `/propose` names that one shape and that one
reaction and nothing else, which is the ceiling on what a session running this routine may emit. **The no-posting argument is unchanged for everything else** and is why
nothing else moved: the proposal issue is assigned to exactly one person whom GitHub already
notifies, a Slack copy would be the same noise twice, and a status line addressed to nobody is
what retired `🔧 Needs a decision` and `📦 Release Preparation`. The receipt is none of those —
it is addressed to the person who wrote the message, in their own thread, exactly once, and
only when this run captured something. Its result reaches its one reader as a Claude
notification (`notifications: push`); since 2026-08-22 (issue #557) this is the only template
that declares the field.

**The name was vacated on 2026-08-19 and this takes it back.** `[Propose] {repo_name}` was the
maintenance tick's rendered name until it became `[Moderate]`, and `/propose` was the command
that became `/specificate`; both were freed in the same change (issue #526) and neither is
claimed by any live template. An account still running a pre-cutover `[Propose] <repo>` must
**delete it** before converging this one — convergence matches by rendered name and would
otherwise adopt a repository-scoped `/moderate` record as this developer-scoped routine. That
is the inverse of what `renamed_from:` instructs, and no template carries the field today
(`workaholic:propose`, `reference/loop.md`, *Taking the name back*).

**The prompt names the command and nothing else** (2026-09-01, the developer's instruction).
Everything a session running this routine may do — the post shapes, the transports, what it may
read, and what it must never emit — lives in `plugins/workaholic/commands/propose.md`, versioned
with the plugin and shipped with it. A routine record is an **account-level** object no
repository can edit, so every rule that lived in this prompt had to be re-pasted into every
developer's copy in every project before it took effect, and a prompt that drifted from the
plugin was invisible from the repository. A rule written in the command reaches every account's
routine on its next run with no routine edit at all.

**The command is the ceiling** (`workaholic:notify`, *The command is the ceiling*): the shapes
that command's own notification section names are the only ones a session running this routine
may emit, and `workaholic:notify`'s `reference/notifications.md` mirrors each of them verbatim,
so a drift between the two is a defect to fix rather than a second wording. What stays in the
prompt is the one instruction the command cannot carry — the load fallback that finds and reads
the command when the plugin did not bind.

## Prompt

Run `/propose`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/propose.md` and follow it with every script path under `<src>`.
