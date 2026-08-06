---
type: Routine Template
id: drive
name: "[Drive] {repo_name} (pilot)"
trigger: cron
cron_expression: "56 * * * *"
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Drive] — the hourly unattended drive runner

The **only** scheduled template: `[Propose]` and `[Consent]` carry no schedule and are
invoked by something outside the routine record, which does not say what. (An earlier
version of this line claimed those two had never fired at all; that was read off an absent
`last_fired_at` and is retracted — `workaholify` SKILL, *What a routine can be triggered
by*.) The `[Propose Batch]` that briefly shared this line was retired on 2026-08-04
(`docs/proposal-loop-runbook.md` §7). It runs `/drive` in an
isolated cloud session every hour at :56 UTC. Still marked `(pilot)` in its name.

**Why the clock, and not a merge event** (decided 2026-08-05, from the ask that this
routine start when a proposal's pull request merges). A routine record has no
event-subscription field at all — its whole trigger surface is `cron_expression`,
`run_once_at`, and an API token letting an external caller POST `/run` (`workaholify`
SKILL, *What a routine can be triggered by*). So there is no merge for **this template's
frontmatter** to key on, and the `[Consent]` template — whose subject already *is* a
merged pull request — keeps ownership of that event rather than this one growing a second
watcher of it. Starting a drive run from a merge means arranging an **invoker**, not
adding a second routine on the same event, and standing one up is a human act.

**The decision does not rest on the trigger surface, which is why it survived a correction
to it.** The clock covers three things no merge event ever will: resuming a handoff,
taking back a claim whose heartbeat lapsed, and driving a ticket `/ticket` wrote rather
than a proposal. That reason alone settles it. What was retracted on 2026-08-06 is the
companion claim that the unscheduled routines never fire at all — read off an absent
`last_fired_at`, and contradicted the next day.

Its Slack posts name a unit or a PR the session itself just produced, so it has no
"which one?" ambiguity — unlike `merged-pr`, whose subject is an external event.

**It was 141 lines until 2026-08-05**, restating a run procedure `/drive` and the `drive`
skill already own — and the restatement had drifted: it instructed the runner to filter
mission ownership by hand on the claim that the survey did not, which `plan-units.sh` had
in fact been doing for weeks, and the same sentence still used a mission status word
retired on 2026-07-31. A prompt that duplicates a procedure becomes a second source of
truth and diverges from it. It now names the policy points and defers, like the other two templates: the
run procedure lives in `workaholic:drive`, the notification rules in this skill (*Slack is
the only surface*, *One thread per feedback item*, *Naming a person means mentioning
them*, and the alert-dedup rule and post shapes beside them), and the standing
prohibitions in the repository's own always-loaded rules.

## Prompt

You are the hourly unattended drive runner for {repo_slug}, in an isolated cloud session. No human is here: never ask a question, never wait for input, never use AskUserQuestion.

1. **Identity first.** `git config user.email a@qmu.jp` and `git config user.name "TAMURA Yoshiya"`. The ticket queue is scoped by git identity (`todo/a-qmu-jp/`), so a wrong identity surveys an EMPTY backlog silently and the tick looks healthy while doing nothing. This is the routine's own environment; every other precondition is `/drive`'s and it enforces them itself.

2. **The `workaholic` plugin must be loaded** — it carries `/drive` and every script it runs. If it is not, report through the alert rule in step 5 and stop. Never hand-roll a drive run, and never read plugin content from a marketplace install: this checkout's `plugins/workaholic/` is the source of truth for any script invoked by path.

3. **Run `/drive auto`** — the **unattended** form, named explicitly because attendance is chosen by the invocation and never inferred. The bare `/drive` would ask which unit to take, and there is nobody here to answer. It surveys, partitions, claims, drives, reports and routes on its own; let it work under its own failure contract and its own gates, and do not re-derive what it already decides (ownership filtering, merge policy, the per-unit route, the claim order). End with its terminal contract as this session's literal last two lines.

4. **Hand off everything unfinished** before the session ends: push the claim branch including partial work, open or update the unit's PR with a leading `## Handoff` section, and **leave the claim in place** — `release-claim.sh` deletes the remote branch and with it the very claim a later run resumes from. The pushed branch is the sole surviving copy; the worktree dies with this container.

5. **Post to Slack channel `dev-{repo_name}` and nowhere else** — no mobile or push notification of any kind. This routine's postable events are exactly five, and the first four are **per unit**, not per run: a unit **started**, a **merge requested**, a **merge**, a **handoff**, and a **blocked-on-precondition failure**. Everything else is silent, including a tick that found nothing to do — an idle tick is correctly silent and that silence is the report. The shapes of the five posts, the mention rule, the red-alert dedup, and which thread a post lands in are all stated in the `workaholify` skill (*Slack is the only surface*, *A red failure alert is deduped…*, *Naming a person means mentioning them*, *One thread per feedback item*); this template does not restate them. Their PR links render as `{repo}/pull/<number>`.

6. **Announce only the pull request THIS session just opened**, and only once. Recent activity in the repository is not this session's to report: never announce a pull request, merge or unit that this session did not itself produce. Every other standing prohibition — the gates, the destructive git commands, repository confinement, `plugins/` over `.claude/`, the docs-in-the-same-commit rule — is in the repository's always-loaded rules and `/drive`'s own contract, and is not restated here.
