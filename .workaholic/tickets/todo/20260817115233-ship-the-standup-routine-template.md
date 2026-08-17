---
created_at: 2026-08-17T11:52:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817115232-add-the-standup-command-and-skill.md
mission: add-the-standup-daily-per-strategy-summary
merge_policy:
verification_handoff: 
---

# Ship the Standup routine template

## Overview

Make `/standup` a routine: a `[Standup]` template with `scope: repository`, configured by
`/setup-repo-routines` as the ask specifies, firing daily at 09:00 and posting the digest to
Slack.

The scope is right and worth stating as deliberate rather than inherited: a per-strategy
digest describes the repository, not a developer, so N developers' copies would post the
same digest N times each morning — the exact failure the `repository` scope was introduced
for on 2026-08-14 (issue #451). `[Release Status]` is the existing precedent: repository
scope, read-only, `allowed_tools` with no `Write`/`Edit`.

## Policies

- `workaholic:operation` / `policies/delivery.md` — a routine is a standing process
- `workaholic:design` / `policies/interaction.md` — a daily post is a standing claim on attention
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/standup.md` — new. Model on
  `release-status.md`: `scope: repository`, `autofix_on_pr_create: false`, `allowed_tools`
  with no `Write`/`Edit`, `mcp: [Slack]`.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh`,
  `render-setup-sheet.sh` — both filter on `scope:`; the template set is discovered by
  scanning the directory, so no command body needs editing.
- `plugins/workaholic/skills/workaholify/SKILL.md` §5, *Two scopes, two commands* — and its
  plain statement that the repository scope is a convention the plugin cannot enforce.
- `plugins/workaholic/skills/notify/SKILL.md` — **The bright line**, and *The repository
  tick's status line*, whose keyed-root-with-no-mention-token shape is this post's closest
  precedent. A digest has no feedback item, so it keys on its own content, never on a
  thread.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shape catalog; the new
  shape must be byte-identical to the template's copy, pinned by
  `scripts/test-workflow-scripts.mjs`.
- `CLAUDE.md` — the routines table and the `/setup-repo-routines` row.
- `scripts/e2e/loop-drill.sh`, `docs/loop-drill-runbook.md` — the on-demand drill.

## Implementation Steps

1. Settle the timezone Open Decision — the ask itself defers it, so it is genuinely open.
2. Write the template. **The cron minute cannot be `0`**: the API rewrites a bare `:00` to
   server jitter, which is why every existing routine uses an explicit non-zero minute
   (`15`, `30`, `45`). Express 09:00 as an explicit nearby minute and say so in the
   template's prose so the deviation from "09:00" is not read as a mistake.
3. Name the post shape verbatim in the prompt and mirror it in `notifications.md`. Keep the
   template a thin pointer: the command, the shape, the environment — every rule stays in
   the skill that owns it.
4. Gate the post the way the bright line requires: **an idle morning posts nothing.** Zero
   strategies, or no activity anywhere, is silence — a daily post that always fires trains
   its readers to ignore it, and the tie goes to silence.
5. Carry no mention token: the digest names a repository's state, not a person's work.
6. Update `CLAUDE.md`'s routines table, add the drill verb, and regenerate the bundle.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `list-routine-templates.sh repository` returns the new template; the developer-scoped
  command never sees it.
- The cron is daily with an explicit non-zero minute, in the timezone the decision fixed.
- An idle morning posts nothing.
- The post shape is byte-identical between the prompt and `notifications.md`, and carries no
  mention token.
- The routine's `allowed_tools` contains no `Write`/`Edit`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the template-drift pin.
- `bash plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh standup <repo-url> repository`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `sh scripts/e2e/loop-drill.sh verify-standup`

**Gate** — what must pass before approval:

- The timezone decision resolved and recorded; CI green.

## Open Decisions

1. **Whose 09:00?** The ask says "the repository's local/working timezone, or UTC if
   unspecified — clarify with requester if needed", so it is explicitly unresolved. The
   container's clock is UTC; the Slack workspace's is `Asia/Tokyo`, which is UTC+9 — so
   `9 UTC` lands at 18:00 in Tokyo, the end of the working day rather than its start, and a
   standup posted after the work is done is the wrong artifact. The routines API takes a
   cron expression, so whichever is chosen is fixed at configuration time and does not
   follow daylight saving anywhere it matters. Decide the timezone, and note that a
   distributed team may need the digest to be *readable* rather than *timed*.

## Considerations

- **This is a fourth routine and a second repository-scoped setup step.** The per-developer
  setup burden is unchanged at two, which is the argument the repository scope was
  introduced with, but a designated person now has two routines to create instead of one.
  Say so in the setup sheet rather than leaving it to be discovered.
- A routine cannot subscribe to a repository event — the API's trigger surface is
  `cron_expression` / `run_once_at` / API token only — so the digest is necessarily a
  scheduled read, not a reaction to the day's activity.

## Final Report

Development completed as planned.

**The timezone Open Decision is resolved: 09:00 Asia/Tokyo, written `5 0 * * *`, landing at
09:05 JST.** Two facts decided it and both are recorded in the template's own prose so the
deviation cannot later be read as a mistake and "tidied" into a bug:

1. **The routines API stores a bare cron with no timezone field**, so the expression is UTC
   whatever a reader assumes. `9 * * *` would post at 18:00 in Tokyo — the end of the working day,
   and a standup posted after the work is done is the wrong artifact. The Slack workspace is
   `Asia/Tokyo`, so the digest is timed for that morning: 09:00 JST = 00:00 UTC.
2. **The minute cannot be `0`** — a bare `:00` is rewritten to server-chosen jitter, the measured
   reason every existing routine carries an explicit non-zero minute (`15`, `30`, `45`). So 00:05
   UTC, and five minutes is the price of a deterministic schedule.

A team in another timezone changes this one field; the digest is written to be *readable* rather
than *timed*, which is what makes that safe. Both halves are pinned by
`node scripts/test-workflow-scripts.mjs` (the hour, the non-zero minute across every template, and
the template's own statement of whose 09:00 it is), because each is exactly the kind of value a
later cleanup rounds off.

**The scope is repository, and the second one in it.** `list-routine-templates.sh repository` now
returns `release-status` and `standup`; the developer-scoped command never sees either. The
ticket's Considerations asked that the new burden be *said* rather than discovered — so
`render-setup-sheet.sh`'s repository header now states the **count** ("There are **2** routines in
this scope"), computed from the templates rather than written into prose that could drift. The
per-developer burden is unchanged at two, which is the argument the scope was introduced with.

**An idle morning posts nothing**, which is what makes a recurring post admissible under
`workaholic:notify`'s bright line: the digest's own `noop` gate (no active strategy, or nothing
moved with no date approaching) and the `standup:<YYYY-MM-DD>` search. The post carries **no
mention token of any kind**, `autofix_on_pr_create: false`, and an `allowed_tools` list with no
`Write`/`Edit`.

**One deliberate difference from `📦 Release status`, stated where it will be questioned**: the key
is the **morning**, not a content hash. A release status must not repeat an unchanged answer; a
*daily* digest is expected to speak for today even when today resembles yesterday, so what the key
prevents is two posts for one morning — precisely the failure the repository scope cannot prevent
on its own, since nothing can detect N copies of a repository routine.

Verified: `render-setup-sheet.sh standup <repo-url> repository` renders the full sheet;
`build.mjs` + `verify.mjs` + `validate-metadata.mjs` clean; the shape is byte-identical between
the prompt and `notify/reference/notifications.md` (pinned); and
`sh scripts/e2e/loop-drill.sh verify-standup --json` returns `pass` on four load-bearing rows.

### Discovered Insights

- **Insight**: a repository-scoped routine set only stays cheap while every member of it is a
  *reader*.
  **Context**: the scope was introduced to stop N copies of one routine; it says nothing about
  what a routine may do. Two readers cost the designated account two UI forms and add no
  unattended-write class to `main`. The moment a repository-scoped template wants to write, the
  2026-08-13 objection (an hourly agent rewriting a document on a tree whose conflicts are
  resolved append-only) applies to it in full — which is a design question for the developer, not
  a template edit.

- **Insight**: the drill's JSON matching is transport-sensitive in a way that silently fails a
  new stage.
  **Context**: the older scripts print JSON with `printf` and a space after each colon; anything
  emitting `jq -c` output has none, so a `case "$out" in *'"ok": true'*)` pattern copied from a
  neighbouring verb never matches and the stage reports a false failure on a passing script. New
  drill rows should match colon-space-optionally.

- **Insight**: stating a count in generated text beats stating it in prose, even for a "2".
  **Context**: the sheet's header could have said "both routines" — and would have been wrong the
  next time the scope grows, in a document nobody re-reads. Counting the templates makes the
  sentence maintain itself, which is the same reason the scope lives on the template rather than
  in two command bodies.
