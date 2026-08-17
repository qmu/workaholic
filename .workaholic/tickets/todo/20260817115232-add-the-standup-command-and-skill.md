---
created_at: 2026-08-17T11:52:32+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817115231-resolve-strategy-to-activity-attribution.md
mission: add-the-standup-daily-per-strategy-summary
merge_policy:
verification_handoff: 
---

# Add the /standup command and skill

## Overview

The command itself: `/standup` reads the strategy set and, for each strategy, summarises the
recent development activity attributable to it — commits, pull requests, archived tickets,
stories — as a concise digest a stakeholder can read in a few seconds.

It is a **pure read**, on the `/release-status` model: no file, no commit, no branch, no
pull request, no merge, no deployment, no prompt. That is what lets it run unattended on a
daily schedule without becoming a new class of write, and it is the same argument
`workaholic:ship` §7 makes for the repository tick.

## Policies

- `workaholic:operation` / `policies/observability.md` — a digest is only useful if it distinguishes "nothing happened" from "could not read"
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/interaction.md` — a daily digest competes for attention; brevity is the feature

## Key Files

- `plugins/workaholic/commands/standup.md` — new; thin, on the model of
  `commands/release-status.md`.
- `plugins/workaholic/skills/standup/SKILL.md` — new, or a section on an existing skill if
  the reviewer prefers; `metadata.internal: true` if it bears scripts.
- The attribution reader from the previous ticket — the only source of "which work belongs
  to this strategy".
- `plugins/workaholic/skills/strategy/scripts/list.sh` — the strategy set; degrades to an
  empty list in a tree with no `strategies/` area, and an empty set is a real answer.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — the existing recent-activity
  window reader; reuse rather than write a second one.
- `plugins/workaholic/skills/mission/scripts/progress.sh` — computed `checked ÷ total`
  progress, the natural per-strategy progress signal once missions are attributable.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — for anything read from GitHub.

## Implementation Steps

1. Read the strategy set. **Zero strategies is a clean no-op** with a named reason, not an
   empty digest — this repository is in that state today, so it is the first case to get
   right.
2. Per strategy, gather the window's activity through the attribution reader and
   `scan-window.sh`; include the strategy's own `target_date` and how close it is, since a
   dated, owned direction is exactly what a standup wants to surface.
3. Render concisely: a few lines per strategy, an explicit "no activity" line for a quiet
   one, and a hard cap on length so the digest stays readable as strategies accumulate.
4. Report unreadable inputs by name (`gh_unavailable`, unreadable area) rather than as
   silence — the distinction `list-inbound-issues.sh` already draws.
5. Keep the command free of `AskUserQuestion` and of any write.
6. Register in `CLAUDE.md`'s commands table and `README.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/standup` writes nothing: no file, no commit, no branch, no pull request.
- Zero strategies yields a named no-op; a quiet strategy yields an explicit "no activity"
  line; an unreadable input yields its reason.
- The digest is bounded in length regardless of strategy count.
- Every GitHub read goes through `gh-rest.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `/standup` against this repository today: no-op, nothing written.
- `/standup` against a two-strategy fixture, one active and one quiet.
- `git status` after a run: clean.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The pure-read property is demonstrated, not asserted.

## Considerations

- The digest's value is in **omission**: a standup that lists everything is a changelog.
  Prefer "what moved and what is waiting" over completeness.
- `target_date` gives the digest something a commit list cannot — a strategy approaching its
  date with no activity is the single most useful line this command can produce.
