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
