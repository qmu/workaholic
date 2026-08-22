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
mcp: []
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

**It is granted no Slack connector (`mcp: []`) and posts nothing.** The issue it opens is
assigned to exactly one person — the running identity — and GitHub already delivers it to them;
a Slack copy would be the same noise twice — the argument that gave the retired
`[Workaholic]` no connector — and a status line addressed to nobody is what retired
`🔧 Needs a decision` and `📦 Release Preparation`. Its result reaches its one reader as a
Claude notification (`notifications: push`) instead; since 2026-08-22 (issue #557) this is
the only template that declares the field.

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
prohibitions. It names no post format because this routine emits none.

## Prompt

Run `/propose`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/propose.md` and follow it with every script path under `<src>`.

Post nothing to Slack. Report the proposal's issue URL and its move, or the named reason nothing was proposed.
