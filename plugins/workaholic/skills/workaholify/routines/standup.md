---
type: Routine Template
id: standup
name: "[Standup] {repo_name}"
scope: repository
trigger: schedule-daily
trigger_kind: schedule
cron_expression: 5 0 * * *
autofix_on_pr_create: false
model: claude-opus-5
allowed_tools: [Bash, Read, Glob, Grep]
mcp: [Slack]
---

# [Standup] — the repository's morning digest, and it writes nothing

**`scope: repository`** — the repository needs exactly **one** of this routine, configured by
one designated person or a project/service account through `/setup-repo-routines`. The scope
is deliberate rather than inherited: a per-strategy digest describes the **repository**, not a
developer, so N developers' copies would post the same digest N times each morning — the
failure the scope was introduced for on 2026-08-14 (issue #451). `[Prepare Release]` is the
precedent this template follows in every frontmatter value.

**It is a reader.** No file, no commit, no branch, no pull request, no merge, no deployment —
and no `AskUserQuestion`. `autofix_on_pr_create: false` because it opens no pull request, and
an `allowed_tools` list with no `Write`/`Edit` states the contract where the product can act
on it. `workaholic:standup` owns the digest and its silence rule; `workaholic:strategy` owns
the attribution rule the digest reads through; `workaholic:notify` owns every notification
rule. Nothing is restated here.

**09:00 is Asia/Tokyo, and the cron says `5 0 * * *` in UTC** (the Open Decision on ticket
`20260817115233`, resolved 2026-08-17). Two facts decided it. The routines API takes a bare
cron expression and carries **no timezone field**, so the schedule is UTC whatever a reader
assumes — `9 UTC` would land at 18:00 in Tokyo, the end of the working day, and a standup
posted after the work is done is the wrong artifact. And **the minute cannot be `0`**: a bare
`:00` is rewritten to server jitter, which is why every existing routine uses an explicit
non-zero minute (`15`, `30`, `45`). So 09:00 Tokyo is expressed as `00:05` UTC and the digest
lands at **09:05 Asia/Tokyo** — five minutes is the cost of a deterministic schedule, and the
deviation from a round "09:00" is this decision, not a mistake. A team whose working day sits
in another timezone changes this one field; the digest is written to be *readable* rather than
timed, which is what makes that safe.

**Two gates make an idle morning silent**, and they are why a recurring post is allowed at all
under `workaholic:notify`'s bright line: the digest's own `noop` (no active strategy, or
nothing moved with no `target_date` inside the horizon) posts nothing, and a digest already
posted for this date (a `📣 Standup` search bounded to today finds it) posts nothing. The check
is the **morning**, not a content hash — a daily digest speaks for today even when today
resembles yesterday, and what the check prevents is two posts for one morning, which is exactly
what the repository scope cannot prevent on its own.

**The prompt is the developer's own** (P3, Q2) and states no rule a skill already owns. The one
literal format below stays embedded because a routine cannot defer its own output contract, and
`workaholic:notify`'s `reference/notifications.md` mirrors it verbatim as the sole sanctioned
shape for this event (P10) — a future edit to either copy is a drift to fix, never a second
wording. No repository is named in the prompt (P7); `{repo}` does not appear at all, because
this line links no pull request. It carries **no mention token of any kind**: the digest names
a repository's state, not a person's work.

## Prompt

Run `/standup`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/standup.md` and follow it with every script path under `<src>`.

If the digest is not a no-op and a `📣 Standup` search bounded to today finds no earlier post, post this one message as a new top-level message (the workaholic:notify lookup) — no mention token of any kind:

```
📣 Standup - <N> strategy/strategies, <M> moved since yesterday
<Strategy title> (<days> to <target_date>): one line, what moved and what waits.
<Strategy title>: no activity.
<K> item(s) not attributable to any strategy.
<session URL>
```

If the digest is a no-op, or that search finds today's digest already posted, post nothing.
