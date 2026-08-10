---
name: workaholify
description: Gateway skill a repo's /workaholify setup refers to — reaches the engineering policies (the pillar policies/ directories) and states the working-directory ground rules, instead of duplicating rules into CLAUDE.md.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
skills:
  - workaholic:planning
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
metadata:
  internal: true
---

# Workaholify

The single gateway a repository refers to in order to work under the workaholic engineering standards. `CLAUDE.md` stays thin and points here; the rules live in the pillar policy skills' `policies/` directories and are reached by reference, never by duplication (`workaholic:development` / `policy-as-plugin`). Relocated detail: [reference/routines.md](reference/routines.md) (trigger evidence, ownership mechanisms, configuration placement), [reference/bootstrap.md](reference/bootstrap.md) (bootstrap mechanics and history).

## 1. The rules live in the policies

Read the relevant pillar for the work at hand; do not copy rules into a project's `CLAUDE.md`: `workaholic:planning` (企画 — business, market, legal grounding), `workaholic:design` (設計 — interaction/experience, security design, data sovereignty, API reach), `workaholic:implementation` (実装 — code structure, correctness, runtime, recovery; `directory-structure` + `coding-standards` always apply to code work), `workaholic:operation` (運用 — delivery, runtime behavior, recovery), `workaholic:development` (how the team develops with AI), `workaholic:safety` (incidents, risk, privacy). Each links English hard copies under its `policies/<slug>.md` — the source of truth, kept in sync from qmu.co.jp.

## 2. Working-directory ground rules

Stay at the repository root; if you must `cd`, return immediately — prefer an absolute path or a `( cd <dir> && … )` subshell over a bare `cd`. Enforced by `hooks/guard-working-directory.sh`, a blocking `PreToolUse(Bash)` guard with no env-var toggle (plugin installed = guard active): a top-level cwd-moving `cd` is denied; subshells, absolute paths, and `--prefix`-style commands pass silently. When wiring a repository, confirm the guard is registered in the plugin's `hooks.json` — a stale or partial install can load without it; if so, tell the user to update the plugin.

## 3. CLAUDE.md audit

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/audit-claude-md.sh
```

Returns `{file, conformant, checks:{claude_md_present, refers_workaholify_gateway}, missing:[...]}`. On `conformant: false`, report the `missing` checks and offer to add a reference to this gateway — never a copy of the rules. Every check stays a verifiable condition.

## 4. The web bootstrap

Claude Code on the web starts each session in a fresh container where `enabledPlugins` installs nothing, so without `.claude/hooks/session-start.sh` (canonical copy: this skill's `bootstrap/session-start.sh`) plus its `SessionStart` entry, every cloud routine stops at its own "the workaholic plugin must be loaded" precondition — firing on time, doing nothing, and reading as healthy. A local session keeps a persistent `~/.claude`, so this is a no-op outside the web.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-bootstrap.sh [repo-root]
```

Every problem is named separately — `hook_missing`, `hook_stale`, `not_registered`, `matcher`, `timeout`, `enabled_plugin`, `marketplace` — because each needs a different fix. Caveats (live rules; mechanics and history in [reference/bootstrap.md](reference/bootstrap.md)):

- The already-installed fast path is version-gated, never presence-gated (a baked-in stale install is refreshed with `plugin update`, not skipped on presence).
- The hook also provisions `gh` — guarded on `command -v gh`, non-fatal in every branch (the web container ships none, and fourteen plugin scripts need it).
- The hook also gives the session the developer's git identity: it resolves the session's GitHub login (`gh api user`) through the committed repo-root `.claude/git-identities` mapping (`<login>=<email>`, one per line, `#` comments tolerated) and sets the repo-local `user.email`/`user.name` — **only** when the current email is empty or an `@anthropic.com` default; a real local identity is never overwritten, and an absent mapping file is the status quo, not an error. Without it, ownership keys on `git config user.email`, so the developer's own `[Implement]` routine cannot claim tickets assigned to them (measured 2026-08-07: `ticket_owner_mismatch` on the developer's own proposal).
- The `SessionStart` matcher must be `startup` (the event also fires on `resume`/`clear`/`compact`); the timeout is 120 (a marketplace clone can exceed the default). The hook is POSIX `sh` with no `set -e` (it must never block session start), idempotent, and fails open; `matches_canonical` compares byte-for-byte, so an older installed copy reports as drift.
- **A hook-registered install is a different question from a bound one.** This section makes the `SessionStart` hook correct and idempotent; it says nothing about whether that install's commands/skills/hooks are actually live for the rest of the session. They may not be — Claude Code exposes no supported way to make a SessionStart-time install effective without a human typing `/reload-plugins`, so an unattended routine can run its whole tick with zero plugin surface even though this hook did everything right (FB `20260807104046`). `workaholic:check-deps`'s `unbound_in_claude_session` field is the legibility answer, and `/drive` terminates `pending` on it — see CLAUDE.md's `/workaholify` row for the full account.

## 5. Scheduled routines

Routines are Claude Code Web routines (scheduled or externally invoked cloud sessions), never cron — where "never cron" names the *mechanism* (a routine, not a machine-local crontab), not "never scheduled": `[Implement]` fires on a fixed schedule (FB `20260810085032`/issue #336, ticket `20260810085347`, 2026-08-10). The plugin holds two templates in this skill's `routines/`, each a short developer-owned prompt (three instructions and two post formats, Q2), applied to whichever repository the command runs in — no per-repository routine file exists: `fb` (`[Propose]` — an issue assigned to the developer becomes a `/fb` record and a PR; kept event-triggered — see *What a routine can be triggered by*) and `implement` (`[Implement]` — the unattended executor, now firing every 30 minutes at :00/:30 rather than on a proposal's merge). Two, because a developer configures these by hand and every field multiplies by the number of projects (P3). `[Consent]`, the merge announcement, was retired 2026-08-06 at a stated cost: a human-merged pull request is now announced by nobody. Do not reintroduce a third routine to recover it.

A template is a thin pointer, not a procedure: a prompt carries only what the plugin cannot know — the environment, the payload, the one command, and the channel and post shape — and defers everything else to its owner (the run to `workaholic:drive`, the notification rules to `workaholic:notify`, the standing prohibitions to `rules/`); a prompt that restates a rule is a second source of truth, and the drift is one-directional. Prompts are byte-identical across repositories (P7): no substitution, no repository name; `{repo_name}` survives only in the `name:` UI field. Changing a template makes every live routine drift by construction; the fleet is refreshed one routine at a time, confirmed verbatim — never as part of the change that edits the template.

#### What a routine can be triggered by

A routine fires three ways — a schedule, an API call, or a GitHub event. The GitHub wiring is configurable only in the web UI: the API record carries no event field, so it is unreadable, unwritable and unverifiable from a session (a template's `trigger:` states the designed trigger, not a stored field), and `last_fired_at` is absent for GitHub-triggered fires, so no claim may rest on it — look at what the routine produced. A schedule trigger's `cron_expression` **is** a genuine field on a routine record, but re-verified against this session's actual tool surface (ticket `20260810085351`, 2026-08-10): no `RemoteTrigger`-family tool is exposed to a session at all — `CronCreate`/`CronList`/`CronDelete` are a *different*, session-only, in-memory mechanism, unrelated to account routines — so a schedule trigger is exactly as unset-from-a-session as a GitHub one. Designed wiring: `[Propose]` on issue assigned (kept — a schedule fire carries no issue in hand, and `/propose`'s whole design is *the ask in hand*, `nothing_in_hand` otherwise; converting it would either report `nothing_in_hand` every tick or resurrect the swept-backlog `[Propose Batch]` design this repository already retired); `[Implement]` on a fixed 30-minute schedule (`0,30 * * * *`) — safe to move because it is survey-driven, not event-driven, so a schedule fire loses only the merge event's instant start. Neither trigger narrows to a person (the UI offers no assignee filter): every developer's copy fires on every matching event/tick and the data decides whose work it is. Neither prompt carries a guard; both commands do their own filtering — `/implement` at its survey (`owned_by_other`), `/propose` at its input (`not_mine`, P8), and a proposal carries the triggering issue's assignee onto every artifact it emits (P6). The check is the command's, never the prompt's. Repairing a live routine's trigger is a human act in the routines UI. Evidence and history: [reference/routines.md](reference/routines.md).

### The notification model lives in `workaholic:notify`

Which events earn a Slack post, the exact post shapes, the stateless reply-thread lookup (*One thread per feedback item*), which thread an `/implement` unit's posts land in, mention resolution, and the red-alert dedup are all stated once in `workaholic:notify` — the templates and every other consumer defer there, and nothing of the model is restated here.

### The scripts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routine-templates.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-routine.sh <template-id> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-setup-sheet.sh <template-id|--all> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh [name-or-url]
```

`/setup-routines` (and its synonym `/set-routines` — the FB `20260810085032` ask, ticket `20260810085351`) renders copy-paste setup sheets and manages nothing, for a schedule trigger exactly as much as a GitHub one: `render-setup-sheet.sh` emits, per template, the name, model, repository, the prompt verbatim, and the UI steps derived from the template's `trigger_kind`/`trigger_event`/`trigger_filters`/`cron_expression` declaration — derived, so a changed trigger cannot leave a stale procedure behind. It makes no `RemoteTrigger` call (none is exposed to a session, either trigger kind) and asks nothing. The account-management surface (digest gate, drift and fleet reports) is retired; do not reintroduce a reader "just to report what exists" — the trigger wiring is invisible to the API, so such a report is authoritative about what does not matter and silent about what does ([reference/routines.md](reference/routines.md)).

### Preconditions, checked before anything is scheduled

Reported, never gates (the web bootstrap in §4 is the third, and the one without which nothing runs at all):

- The Slack connector must be attached (nothing here can verify it was kept), and the channel must exist: `bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>` probes `dev-<repo>`. "Cannot check" is never reported as "does not exist" — only a probe that actually reached Slack may set `exists`; everything else is `checked: false` with a named reason (`no_qfs`, `slack_locked`, `slack_not_connected`).
- On a public repository, Issue and Pull request permissions must be `Collaborators only`. This is the precondition of the whole loop: an Issue or pull-request body becomes an unattended agent's instructions, and this bounds that injection surface to people inside the repository. Nothing here can verify it; the sheet states it.
- The committed `.claude/git-identities` mapping must carry each developer whose tickets a routine should drive (`<login>=<email>`; §4's bootstrap hook reads it). Without their entry, a cloud session keeps the container's `noreply@anthropic.com` identity and the developer's own `[Implement]` routine cannot claim tickets assigned to them.

### What may be applied unattended

Reading (listing, rendering, reporting) is unattended-safe. Every mutation of a standing outward-facing process needs a human seeing exactly what it will be — confirmed verbatim, one routine at a time, never batched, never inferred from a report, never performed by an unattended run. An agent may not bring such a process into existence, or re-point one, without that.

### What the command does with all this

Resolve the repository first (`resolve-repo-url.sh [name-or-url]`; no argument means this checkout — when `source` is `same_org_as_checkout`, say which repository it resolved to). Render the sheets, report the preconditions, and say plainly what cannot be verified from here. Print the prompt blocks verbatim — never summarise, re-wrap, or "clean up" a prompt: what the developer pastes is what runs. There is no mutation to confirm and no account to survey: the developer creates the routine in their own browser from the sheet.
