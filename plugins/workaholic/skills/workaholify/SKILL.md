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

## 3a. The `.workaholic/` layout

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/layout-doctor.sh [repo-root]
```

Read-only. `conforming: false` means the tree holds something the closed layout does not designate; each finding carries its own `remediation`. Report them, never apply them silently — the layout is the repository's, and the audit's job is to make a mismatch legible.

**The retired documentation areas.** `guides/`, `policies/` and `specs/` left the allowlist on 2026-08-13 (issue #436) because an area with no writer in the loop goes stale and then lies — in this repository all 17 substantive files still described the three-plugin architecture retired months earlier. A consuming repository updates its plugin before its tree, so it will meet the de-listed allowlist while still holding the directories, and **every later write into them is hard-blocked** (the layout gate has no opt-out). `layout-doctor.sh` classifies those three as `retired-area` and says so by name rather than as a generic undesignated directory. **What happens to the content is the owner's call, not this command's**: move what is still true into the repository's own `docs/` tree, outside `.workaholic/`, then remove the directory. This repository deleted its own; nothing imposes that answer elsewhere.

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
- **A hook-registered install is a different question from a bound one.** This section makes the `SessionStart` hook correct and idempotent; it says nothing about whether that install's commands/skills/hooks are actually live for the rest of the session. They may not be — Claude Code exposes no supported way to make a SessionStart-time install effective without a human typing `/reload-plugins`. `workaholic:check-deps`'s `unbound_in_claude_session` field is the legibility answer, and `/drive` warns and continues on it rather than terminating (2026-08-10, ticket `20260810090005`): the plugin's own scripts stay directly runnable via `bash` from the checkout path, and the safety hooks stay active, independent of that binding — the general form of this fallback is stated once in `plugins/workaholic/rules/general.md` ("An unbound skill surface is not, by itself, a reason to stop"), so a future unattended entry point does not have to re-learn it from a live correction; see CLAUDE.md's `/workaholify` row for the full account.

## 5. Scheduled routines

Routines are Claude Code Web routines (scheduled or externally invoked cloud sessions), never cron — where "never cron" names the *mechanism* (a routine, not a machine-local crontab), not "never scheduled": both `[Propose]` and `[Implement]` fire hourly on distinct, non-zero minutes (FB `20260810085032`/issue #336, ticket `20260810085347`, 2026-08-10 — the developer's explicit ask covers both routines; a first pass of this ticket kept `[Propose]` on its GitHub trigger over the *ask in hand* conflict below, corrected live on the same day's PR; the original `0,30 * * * *` value was itself rejected by the API — see *What a routine can be triggered by*). The plugin holds two templates in this skill's `routines/`, each a short developer-owned prompt (three instructions and two post formats, Q2), applied to whichever repository the command runs in — no per-repository routine file exists: `fb` (`[Propose]` — an issue assigned to the developer becomes a `/fb` record and a PR; now firing hourly at `:15` rather than on assignment — see *What a routine can be triggered by* for what this costs) and `implement` (`[Implement]` — the unattended executor, now firing hourly at `:30` rather than on a proposal's merge). Two, because a developer configures these by hand and every field multiplies by the number of projects (P3). `[Consent]`, the merge announcement, was retired 2026-08-06 at a stated cost: a human-merged pull request is now announced by nobody. Do not reintroduce a third routine to recover it.

A template is a thin pointer, not a procedure: a prompt carries only what the plugin cannot know — the environment, the payload, the one command, and the channel and post shape — and defers everything else to its owner (the run to `workaholic:drive`, the notification rules to `workaholic:notify`, the standing prohibitions to `rules/`); a prompt that restates a rule is a second source of truth, and the drift is one-directional. Prompts are byte-identical across repositories (P7): no substitution, no repository name; `{repo_name}` survives only in the `name:` UI field. Changing a template makes every live routine drift by construction; the fleet is refreshed one routine at a time, confirmed verbatim — never as part of the change that edits the template.

#### What a routine can be triggered by

A routine fires three ways — a schedule, an API call, or a GitHub event. The GitHub wiring is configurable only in the web UI: the API record carries no event field, so it is unreadable, unwritable and unverifiable from a session (a template's `trigger:` states the designed trigger, not a stored field), and `last_fired_at` is absent for GitHub-triggered fires, so no claim may rest on it — look at what the routine produced. A schedule trigger's `cron_expression` **is** a genuine field on a routine record, but re-verified against this session's actual tool surface (ticket `20260810085351`, 2026-08-10): no `RemoteTrigger`-family tool is exposed to the *unattended, routine-fired* session class at all — `CronCreate`/`CronList`/`CronDelete` are a *different*, session-only, in-memory mechanism, unrelated to account routines — so for that class a schedule trigger is exactly as unset-from-a-session as a GitHub one (an interactive session can differ — see *Direct-apply when `RemoteTrigger` is exposed* below). A separate attended session (ticket `20260810104620`) found `RemoteTrigger` present on its own tool surface, and both live routine records had already drifted from their designed wiring (empty `cron_expression`, a stale prompt) — see [reference/routines.md](reference/routines.md)'s session-class scoping and its 2026-08-10 live-drift addendum for the full account. Designed wiring: both `[Propose]` and `[Implement]` fire hourly, on the developer's explicit ask — `[Propose]` at `:15` (`15 * * * *`), `[Implement]` at `:30` (`30 * * * *`); a shared `0,30 * * * *` was tried first and rejected by the API (`cron interval too short`, measured 2026-08-10 — the minimum realizable interval is one hour, and a bare `:00` minute is silently rewritten to a server-chosen jitter minute), so the two routines now carry distinct, explicit non-zero minutes instead. The two routines accept this move on different terms, stated rather than glossed over: `[Implement]` is survey-driven, so a schedule fire loses only the merge event's instant start; `[Propose]`'s whole design is *the ask in hand*, and a schedule fire alone carries no issue in hand — a gap first stated as an unresolved cost and then closed on the developer's instruction (2026-08-12): `/propose` now runs its own **clock-fired discovery** (`propose/scripts/list-inbound-issues.sh` — the open GitHub issues assigned to the session's own identity, minus those a feedback record already names, each taken as an ask through the full run), so a tick reports `nothing_in_hand` only when that inbox is genuinely empty. This is still not the swept-backlog `[Propose Batch]` design this repository already retired: that read the repository's own backlog for something to propose, while the discovery reads the inbound ask channel — the issues the retired event trigger used to hand over one at a time. Neither trigger narrows to a person (the UI offers no assignee filter): every developer's copy fires on every matching event/tick and the data decides whose work it is. Neither prompt carries a guard; both commands do their own filtering — `/implement` at its survey (`owned_by_other`), `/propose` at its input (`not_mine`, P8), and a proposal carries the triggering issue's assignee onto every artifact it emits (P6). The check is the command's, never the prompt's. Repairing a live routine's trigger is a human act in the routines UI. Evidence and history: [reference/routines.md](reference/routines.md).

#### Configuring the routines is the job; `no_transport` is its one refusal

**`/setup-routines` configures the routines.** It is not a renderer that occasionally gets to configure, and a session that succeeds must never describe its success as luck — "a tool happened to be available, so I registered them" was reported as the defect itself (issue #408, FB `20260812204800`), because it tells the developer the command's purpose is contingent when only its *reachability* is. One job, one named failure mode:

1. **Attempt the configuration.** Find the transport: `ToolSearch` for a `RemoteTrigger`-family tool (list/get/create/update/run over **account** routines). Never assume either answer — an interactive session may well carry one (FB `20260810214929`, 2026-08-10: it did, and listing this repository's routines found both with an empty `cron_expression`), and the routine-fired class genuinely carries none.
2. **Converge, one routine at a time.** For each template (`list-routine-templates.sh`), list the account's routines, match by the rendered `name` (`render-routine.sh <id> <repo-url>`), and diff name/prompt/model/`cron_expression`/`autofix_on_pr_create`/`mcp` against the live record. The auto-fix flag lives at `job_config.ccr.session_context.autofix_on_pr_create` (discovered 2026-08-12 by toggling the UI option and re-reading the record; the API silently drops unknown fields, so the record read-back — never a 400 — is what confirms a write took). Where they differ, call the tool's own create/update method and report exactly which fields changed (or that the routine did not exist and was created). Where nothing differs, report that too; a silent "nothing to do" reads identically to "did not check."
3. **No transport → a named refusal, then the sheet as its recovery path.** Report `no_transport: RemoteTrigger-family tool` — naming what was looked for, so the reader can tell "this session cannot reach an account routine" from "there was nothing to do" — and *then* render `render-setup-sheet.sh --all <repo-url>`. The sheet's content is unchanged; what changed is its standing. It is the repair a developer performs by hand for a refusal this session reported, never the ordinary outcome of the command. **Measured, so the refusal is honest** (2026-08-12, the routine-fired class): no `RemoteTrigger`-family tool is exposed, `CronCreate`/`CronList`/`CronDelete` are a session-only in-memory scheduler that cannot touch an account routine, and the `claude` CLI exposes no routine subcommand — there is no second transport to reach for before giving up.
4. **No `AskUserQuestion`, by design, not by unattended necessity.** Converging a live routine to the developer's own already-declared template is not a judgment call with alternatives to weigh — it fails the *Recommended-label test* (`rules/interaction.md`): there is nothing to recommend against, so nothing to ask. Report the diff applied and move on; a mutation the tool itself refuses (a rejected `cron_expression`, a missing scope) is reported as a refusal like `no_transport`, never retried and never silently downgraded to the sheet. This also keeps the path safe under §*What may be applied unattended*'s stricter rule rather than contradicting it: that rule exists to keep a *routine-fired* run from mutating the very processes that drive it, and this path is reachable only through a developer's own interactive `/setup-routines` invocation — no `[Propose]`/`[Implement]` prompt names it, so "never performed by an unattended run" holds by construction, not by an extra gate.

### The notification model lives in `workaholic:notify`

Which events earn a Slack post, the exact post shapes, the stateless reply-thread lookup (*One thread per feedback item*), which thread an `/implement` unit's posts land in, mention resolution, and the red-alert dedup are all stated once in `workaholic:notify` — the templates and every other consumer defer there, and nothing of the model is restated here.

### The scripts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routine-templates.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-routine.sh <template-id> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-setup-sheet.sh <template-id|--all> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh [name-or-url]
```

`/setup-routines` (and its synonym `/set-routines` — the FB `20260810085032` ask, ticket `20260810085351`) **converges routine wiring directly**; it manages nothing only when its session can reach no account routine at all, which it reports as `no_transport` before falling back (see *Configuring the routines is the job* above — the routine-fired class is where that refusal actually fires, as every session checked before 2026-08-10 confirmed). Either way, `render-setup-sheet.sh` (the fallback, and the direct-apply path's own source of the target state) emits, per template, the name, model, repository, the prompt verbatim, and the UI steps derived from the template's `trigger_kind`/`trigger_event`/`trigger_filters`/`cron_expression` declaration — derived, so a changed trigger cannot leave a stale procedure behind. The account-management surface (digest gate, drift and fleet reports) stays retired; the direct-apply path is not its return — it converges to the plugin's own templates on the spot, never surveys or reports drift as a standalone act, and never runs unattended ([reference/routines.md](reference/routines.md)).

### Preconditions, checked before anything is scheduled

Reported, never gates (the web bootstrap in §4 is the third, and the one without which nothing runs at all):

- The Slack connector must be attached (nothing here can verify it was kept), and the channel must exist: `bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>` probes `dev-<repo>`. "Cannot check" is never reported as "does not exist" — only a probe that actually reached Slack may set `exists`; everything else is `checked: false` with a named reason (`no_qfs`, `slack_locked`, `slack_not_connected`).
- On a public repository, Issue and Pull request permissions must be `Collaborators only`. This is the precondition of the whole loop: an Issue or pull-request body becomes an unattended agent's instructions, and this bounds that injection surface to people inside the repository. Nothing here can verify it; the sheet states it.
- The committed `.claude/git-identities` mapping must carry each developer whose tickets a routine should drive (`<login>=<email>`; §4's bootstrap hook reads it). Without their entry, a cloud session keeps the container's `noreply@anthropic.com` identity and the developer's own `[Implement]` routine cannot claim tickets assigned to them.

### What may be applied unattended

Reading (listing, rendering, reporting) is unattended-safe. Every mutation of a standing outward-facing process needs a human seeing exactly what it will be — confirmed verbatim, one routine at a time, never batched, never inferred from a report, never performed by an unattended run. An agent may not bring such a process into existence, or re-point one, without that.

### What the command does with all this

Resolve the repository first (`resolve-repo-url.sh [name-or-url]`; no argument means this checkout — when `source` is `same_org_as_checkout`, say which repository it resolved to). **Then attempt the configuration** (*Configuring the routines is the job* above): list/diff/apply directly and report exactly what changed per routine — no mutation is inferred from a report or batched, each is applied and stated as its own line. **Only when the attempt cannot be made**, report `no_transport: RemoteTrigger-family tool` and then render the sheets as that refusal's recovery path, with the preconditions and a plain statement of what cannot be verified from here; print the prompt blocks verbatim — never summarise, re-wrap, or "clean up" a prompt: what the developer pastes is what runs, and there is no mutation to confirm because there is no account this session can reach — the developer creates the routine in their own browser from the sheet.
