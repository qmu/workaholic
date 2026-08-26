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
`dev-<repo_name>`) for asks a person wrote **without mentioning any bot**, and files each as
the same `[FB]` issue the Claude Tag route produced — assigned to the running identity, so the
next `[Specificate]` ingests it (`workaholic:propose`, *The inbound sweep*). The tag route
cost a tagged session per ask and stopped capturing at the usage limit; this reads the channel
as the account itself.

**And since 2026-08-26 it posts exactly one shape: the sweep's receipt** (the developer's
instruction). Until then it posted nothing at all, which made a captured ask and an ignored one
byte-identical from the channel — measured the same day, two asks became issues within the hour
and the developer, seeing no trace in the thread, asked why neither had been treated as
feedback. The prompt names that one shape and no other, which is the ceiling on what this
routine may emit. **The no-posting argument is unchanged for everything else** and is why
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

**The prompt is the developer's own** and states no rule a skill already owns:
`workaholic:propose` owns the gates, the three moves and the refusal of housekeeping,
`workaholic:strategy` owns the artifact, and the always-loaded `rules/` own the standing
prohibitions. It names **one** post format — the sweep's receipt — byte-identical to
`workaholic:notify`'s catalog copy, and that one shape is the ceiling on what a session running
this routine may emit.

## Prompt

Run `/propose`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/propose.md` and follow it with every script path under `<src>`.

Read Slack only through the Slack connector; the inbound sweep needs no mention to capture an ask.

For each ask the sweep files **in this run**, post one reply into that message's own thread — its `thread_ts` is the `ts` half of the `slack-ref` just written, so run no lookup and no search:

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<session URL>
```

Post nothing else to Slack: not for an already-swept message, not for an exclusion, not for a degradation, not for the proposal, and not on an idle tick. A reply that fails is reported as `ack_failed` and never blocks the capture.

Report each swept ask's issue URL and whether its receipt landed, or its named exclusion, then the proposal's issue URL and its move, or the named reason nothing was proposed.
