---
created_at: 2026-08-01T03:04:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260801-033154
---

# Make `/workaholify` provision a developer's loop-engineering environment, and nudge them to re-run it

## Overview

Routines are how this project actually runs — `[FB]` turns a Slack-reported issue into a feedback record and a PR, `Merged PR` announces a merge, `[Drive]` runs the queue hourly. They are configured ad hoc by one person, so *"what runs against this repo"* can only be answered by asking them, and a developer joining has no path to the same setup.

**This is `/workaholify`'s job, not a new command's.** `/workaholify` already means "wire this repository to the standards", and a routine is part of that wiring. A separate `/setup-routines` would split "make this repo work the way we work" across two commands, and the second is the one nobody runs.

## What these routines actually are

**Claude Code Web routines** — scheduled or event-driven cloud sessions, each with its own checkout, managed through the `RemoteTrigger` tool (`list` / `get` / `create` / `update` / `run`). Not cron. This distinction is the whole ticket: an earlier attempt built a crontab provisioner and had to be withdrawn, and the evidence against it was already on the machine — **this server has no crontab at all, yet the loops run every hour**.

Measured on the live account (2026-08-01): 16 routines, in three patterns replicated across seven repositories. The `[FB]` prompt is **byte-identical** in every repository that has one, and so is `Merged PR`; the only thing that varies is which repository the routine points at.

## The model

**One set of templates in the plugin, applied to many repositories.** The templates live in `skills/workaholify/routines/`; there is no per-repository routine file anywhere, and `.workaholic/` gains no new directory. A per-repo declaration would be one copy per repo of a file identical everywhere except its own URL — each free to drift, and none of them authoritative, since the routine itself lives in the cloud account where `list` reads it back.

Three substitutions, each demanded by the live prompts: `{repo}` (full URL, for `…/pull/123` links), `{repo_slug}` (`org/repo`, how the Drive prompt names the repository), `{repo_name}` (bare name — the routine's own name and the `dev-<name>` Slack channel). **Anything else that differs between two repositories' routines is drift, not configuration.**

The drift is not hypothetical. Live today: `Merged PR qmu-co-jp` and `[FB] coop-csnet` carry no `model` while every sibling pins `claude-opus-5`, and `[FB] data-platform` has an extra prompt line. Issue #120's "pull the latest version of each template" is aimed at exactly this.

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — a routine is delivery infrastructure; how it is provisioned and how drift is detected belong to the operation pillar
- `workaholic:implementation` / `policies/objective-documentation.md` — "which routines run against this repo" must become an observable fact from a command, not an answer only one person holds
- `workaholic:development` / `policies/review.md` — a routine is a standing outward-facing process; creating or refreshing one is confirmed verbatim, like `/request` crossing a repository boundary

## Key Files

- `plugins/workaholic/skills/workaholify/routines/` — the three templates (`fb`, `merged-pr`, `drive`), captured verbatim from the live routines
- `plugins/workaholic/skills/workaholify/scripts/` — `list-routine-templates.sh`, `render-routine.sh`, `compare-routines.sh`
- `plugins/workaholic/commands/workaholify.md` — the survey step and the per-routine confirmation; the only place `RemoteTrigger` is called
- `plugins/workaholic/skills/workaholify/SKILL.md` — the model, the substitutions, and the script/command split
- `CLAUDE.md` — the `/workaholify` command-table row

## Related History

`/workaholify` was deliberately kept thin: rules live in the gateway skill, never copied into `CLAUDE.md`. That shape is preserved — the routines step refers to the skill, and the skill holds the model.

The originating records are `20260731160449-support-a-setup-routines-skill-…` and `20260731160517-routine-configuration-has-no-source-of-truth-…` (issue #120). They asked for `/setup-routines [repository name]`; answering the need inside `/workaholify` instead is the developer's ruling (2026-08-01), as is the finding that no per-repository declaration is wanted.

## Implementation Steps

1. **Capture the three templates verbatim** from the live routines into `skills/workaholify/routines/*.md`, with the varying parts replaced by the three substitutions and everything else byte-identical.
2. **`list-routine-templates.sh`** — report what the plugin ships.
3. **`render-routine.sh <id> <repo-url>`** — the prompt with substitutions applied, plus the fields a `RemoteTrigger` body needs. It emits no `job_config`: the environment id is an account-level fact with more than one valid answer.
4. **`compare-routines.sh <repo-url>`**, reading the live `list` JSON on stdin — match by `sources[].git_repository.url` (never by name), report `missing`, `present` with **per-field** drift, and `unknown`.
5. **Wire the command**: survey, report, then render and **confirm each routine verbatim** before `create`/`update`. Ask which environment to use.
6. **Update the docs in the same change** and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Rendering each template against a repository reproduces the live routine's prompt **byte-for-byte** — proven by comparing the rendered output against the real prompts and getting an empty `drift`.
- `compare-routines.sh` includes only routines whose source URL matches the repository, names drift per field, and lists an untemplated routine as `unknown` rather than proposing to remove it.
- No `.workaholic/` directory is added; `layout-doctor.sh .` still reports `conforming: true`.
- Nothing outside the command calls `RemoteTrigger`, and no script writes to the account.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with hermetic cases driving `compare-routines.sh` against a fixture built from the real routine shapes (exact match, model drift, other-repo exclusion, unknown one-off). No test touches the account.
- A live `RemoteTrigger list` compared against the rendered templates shows empty prompt drift for this repository.

**Gate** — what must pass before approval:

- The suite is green and the live comparison shows the templates reproduce the real prompts exactly.

## Considerations

- **`RemoteTrigger` has no delete.** This flow can add and refresh, never remove; deletion is a human act at <https://claude.ai/code/routines>. That asymmetry is safe in the right direction and should stay.
- A routine acts on the repository unattended once created, so the confirmation is per routine and verbatim — not one blanket yes for a batch (`plugins/workaholic/commands/workaholify.md`).
- Prompt comparison is exact-match after trimming. Any future reformatting of a template — even whitespace — will read as drift on every repository at once, which is loud but correct; the alternative (fuzzy matching) would hide the real drift this exists to find (`compare-routines.sh`).
- The `[Drive]` template is still a pilot: its prompt bounds a tick to two units and its name carries `(pilot)`. Applying it to a second repository is a decision, not a default.

## Final Report

Development completed as planned, on the second attempt. The first implementation was
withdrawn whole (PR #136, closed unmerged) because it targeted the wrong mechanism.

### Discovered Insights

- **Insight**: The evidence against the wrong design was already in hand and was written
  down as a concern rather than acted on. The first attempt built a crontab provisioner;
  its own survey reported `crontab: false` on a machine where the loops demonstrably run
  every hour. That contradiction was recorded in the branch story as a low-severity
  concern and shipped past. It should have been treated as a refutation of the premise.
  **Context**: When a measurement contradicts the design's assumption, it is not a
  concern to file — it is the design being wrong. "The loops run but there is no crontab"
  had exactly one explanation, and reading the originating feedback once more would have
  produced it in a sentence: *"a `/setup-routines` skill **in Claude Code Web**"*.

- **Insight**: The template set is provably faithful because the test asserts an *empty*
  drift against a fixture built from the rendered templates themselves, and the same
  comparison against the live account also comes back empty. That is a stronger check
  than "the template looks right" — a paraphrased prompt would fail it immediately.
  **Context**: The corollary is that any future reformatting of a template, even
  whitespace, reads as drift on every repository at once. Loud, but correct: fuzzy
  matching would hide the real drift this exists to find.

- **Insight**: Three substitutions were needed, not two, and the live prompts said so.
  `{repo_name}` for the routine's own name and the Slack channel, `{repo}` for the
  `…/pull/123` links, and `{repo_slug}` because the Drive prompt names the repository as
  `qmu/workaholic` in prose. The first render produced `[FB] https://github.com/qmu/…`
  as a routine name, which the live listing immediately contradicted.
  **Context**: When capturing templates from live configuration, render one and compare
  it field by field against the original before writing anything else.
