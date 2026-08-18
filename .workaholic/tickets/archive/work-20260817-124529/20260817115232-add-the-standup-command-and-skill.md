---
created_at: 2026-08-17T11:52:32+00:00
status: done
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

## Final Report

Development completed as planned.

`/standup` ships as a thin command over a new `workaholic:standup` skill whose one script,
`digest.sh`, returns the whole morning as data. Attribution is **not** this skill's question — it
calls the previous ticket's one reader (`strategy/scripts/attributed-work.sh`) and parses no
relation itself. What the skill owns is the shape of a morning: the strategy set, the schedule
proximity, the caps, the silence rule, and the one post.

**The pure-read property is demonstrated, not asserted** (the ticket's Gate). Three independent
proofs, because the property is what allows a daily unattended tick at all: the hermetic fixture
asserts `git status --porcelain` is empty and the commit count unchanged after the digest runs;
`sh scripts/e2e/loop-drill.sh verify-standup` asserts the working tree is byte-identical across
two runs against this checkout; and the digest reaches GitHub **not at all**, so it has no token,
no 403 and no network failure mode. `rules/shell.md`'s REST-only rule is satisfied by having no
such read rather than by skipping one, and the test greps the script's *code* for a transport call
so the header sentence explaining the absence cannot pass for the property.

**Zero strategies is a named no-op** — the first case that had to be right, since this repository
is in that state today: `noop: true`, `noop_reason: no_strategies`, and nothing posted.

**One decision was made rather than deferred, and it is the digest's whole editorial rule.**
"Nothing moved but something is queued" is **not** news each morning: a queued ticket that sat
there yesterday will sit there tomorrow, so repeating it daily is exactly the recurring post
`workaholic:notify`'s bright line refuses. It rides a digest that had another reason to exist and
never creates one. What *does* break the silence on its own is an **approaching `target_date`**
(`STANDUP_TARGET_HORIZON`, 14 days, overdue included) — the ticket's own Considerations call that
the most useful line the command can produce, and unlike waiting work it terminates. Everything
else is `noop_reason: no_activity`.

Two acceptance criteria were met in a shape worth naming rather than glossing:

- *"an unreadable input yields its reason"* — the named reasons are `strategy_list_unreadable` and
  `attribution_unreadable:<slug>`, carried in `errors[]`. There is no `gh_unavailable` because
  there is no GitHub read to fail; a reason for a call the command does not make would be
  documentation of a fiction.
- *"the digest is bounded regardless of strategy count"* — `STANDUP_MAX_STRATEGIES` (8) and
  `STANDUP_MAX_ITEMS` (3), with every cut counted in `strategies_omitted` / `moved_omitted` /
  `waiting_omitted`. A cap that is silent reads as "this is everything", which is the same defect
  as an exhaustive-looking lossy digest.

### Discovered Insights

- **Insight**: the honesty line is what keeps a lossy summary honest, and it must be a *count*.
  **Context**: attribution through the feedback stream cannot see work that answers a strategy
  without citing the same record. Reporting `unattributed` as a number tells the reader the digest
  is partial; listing the items would quietly turn a per-strategy summary into the repository-wide
  changelog `/catch` already is, and the strategy grouping would stop being the point.

- **Insight**: "what is waiting" and "what is news" are different questions, and conflating them
  is how a daily digest becomes ignorable.
  **Context**: waiting work is the *content* a standup wants and a terrible *trigger* for one —
  it is by definition unchanged since yesterday. Separating the two (a gate on movement and dates,
  a body that includes what waits) is what lets the post be daily without being noise.

- **Insight**: a reader that a scheduler calls must exit 0 on every degradation, including
  "wrong argument".
  **Context**: a non-zero exit inside an unattended tick is a silent morning with no explanation
  anywhere. Every path here — no strategies, unreadable area, unknown slug, missing slug — emits
  a JSON object with a named reason and exits 0, so the caller always has something to report.
