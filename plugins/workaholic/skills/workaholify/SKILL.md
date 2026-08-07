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

The single gateway a repository refers to in order to work under the workaholic engineering standards. `CLAUDE.md` stays thin and points here; the rules live in the pillar policy skills' `policies/` directories and are reached by reference, never by duplication (`workaholic:development` / `policy-as-plugin`). Relocated detail: [reference/notifications.md](reference/notifications.md) (post shapes, session URL, mention mechanics, disclosure terms), [reference/routines.md](reference/routines.md) (trigger evidence, ownership mechanisms, configuration placement), [reference/bootstrap.md](reference/bootstrap.md) (bootstrap mechanics and history).

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
- The `SessionStart` matcher must be `startup` (the event also fires on `resume`/`clear`/`compact`); the timeout is 120 (a marketplace clone can exceed the default). The hook is POSIX `sh` with no `set -e` (it must never block session start), idempotent, and fails open; `matches_canonical` compares byte-for-byte, so an older installed copy reports as drift.

## 5. Scheduled routines

Routines are Claude Code Web routines (scheduled or externally invoked cloud sessions), never cron. The plugin holds two templates in this skill's `routines/`, each four lines long, applied to whichever repository the command runs in — no per-repository routine file exists: `fb` (`[Propose]` — an issue assigned to the developer becomes a `/fb` record and a PR) and `implement` (`[Implement]` — a merged proposal starts the unattended executor). Two, because a developer configures these by hand and every field multiplies by the number of projects (P3). `[Consent]`, the merge announcement, was retired 2026-08-06 at a stated cost: a human-merged pull request is now announced by nobody. Do not reintroduce a third routine to recover it.

A template is a thin pointer, not a procedure: a prompt carries only what the plugin cannot know — the environment, the payload, the one command, and the channel and post shape — and defers everything else to its owner (the run to `workaholic:drive`, the notification rules to this SKILL, the standing prohibitions to `rules/`); a prompt that restates a rule is a second source of truth, and the drift is one-directional. Prompts are byte-identical across repositories (P7): no substitution, no repository name; `{repo_name}` survives only in the `name:` UI field.

#### What a routine can be triggered by

A routine fires three ways — a schedule, an API call, or a GitHub event — and the GitHub wiring is configurable only in the web UI: the API record carries no event field, so the wiring is unreadable, unwritable and unverifiable from a session (a template's `trigger:` states the designed trigger, not a stored field), and `last_fired_at` is absent for GitHub-triggered fires, so no claim may rest on it — look at what the routine produced. Designed wiring: `[Propose]` on issue assigned; `[Implement]` on pull request closed, `is merged = true`, title contains `[Proposal]`. Neither trigger narrows to a person (the UI offers no assignee filter): every developer's copy fires on every matching event and the data decides whose work it is. Neither prompt carries a guard; both commands do their own filtering — `/implement` at its survey (`owned_by_other`), `/propose` at its input (`not_mine`, P8), and a proposal carries the triggering issue's assignee onto every artifact it emits (P6). The check is the command's, never the prompt's. Repairing a live routine's trigger is a human act in the routines UI. Evidence and history: [reference/routines.md](reference/routines.md).

### One thread per feedback item — the notification model

The unit of a notification is the reader's item of interest, not the emitter's step: one Slack thread per feedback item, carrying its whole life. The `[Propose]` routine posts the root; every later event of that item is an in-thread reply. The key is the feedback record's filename stem, embedded verbatim in the root as `` `fb:<stem>` `` — the identifier that lives in the repository (`feedback:` relations, `supersedes`, the publishing PR's diff), so a later session derives it from the artifact in hand; the issue number rides along as a human pointer only.

Finding the thread — four ordered cases, take the first that applies:

1. The session's own trigger message — reply there; that message is the item's thread.
2. The target the triggering pull request carries — `branching/scripts/read-notify-target.sh <pr>`: `found: true` gives the thread verbatim; `reason: "absent"` falls through.
3. The `fb:<stem>` key search over the channel history.
4. A new root carrying the same key — never a keyless top-level line (two roots with one key is repairable; a keyless post is not attributable to anything).

Cases 1 and 2 are not reducible to the search: a message written before the record existed can never carry the key, and a hand-off knows its target at write time. With no reliable trigger identification, fall through — never thread by recency or message content.

#### Which thread an `/implement` unit's posts land in

These posts are the unattended run's (`/implement` — the routine and any caller-side loop): they exist so an absent operator can tell a working fleet from a dead one. **An attended `/drive` session posts nothing to Slack** — the developer is watching the run, and its report is the session's.

A unit's start and finish are **per-unit, never per-run** ("a run started" names no item, so it has no thread to land in). `drive/scripts/unit-feedback-stems.sh` resolves the unit's artifacts to their deduped feedback stems. Rules:

- Several stems → post into each thread, once per stem per event. No stem → key on `` `unit:<unit-id>` ``, never keyless (the unit id, not the PR number: the start posts before any pull request exists).
- Exactly one start and one finish per thread; the finish's shape follows the outcome (🟢 merge requested, 🚀/🟣 merge, 🟡 handoff, 🔴 blocked). A handoff is the finish, never a third post.
- Never re-announce a merge the channel already carries (a resumed unit can reach the route step twice).

The bot notice `claim.sh` posts (bot token, no threading) is a different surface and is deliberately left alone; neither surface is load-bearing.

### Post shapes, mentions, and the red-alert dedup

The exact shapes of the runner's posts (🟢 proposed / 🔴 blocked / 🟠 started / 🟢 merge requested / 🟡 handoff / 🚀 auto merge / 🟣 human merge) are in [reference/notifications.md](reference/notifications.md); a template names its postable events and defers the shapes there. Standing rules:

- 🟢 Proposed is the `[Propose]` routine's thread root; its `` `fb:<stem>` `` line is never dropped. The root announces only the pull request you just created in this session, exactly once — post nothing if you created none, and never announce another session's work.
- Every post carries its session URL when discoverable; a post missing it still posts. The `Notify-Thread:` URL in a public pull-request body is an accepted, recorded disclosure (terms in [reference/notifications.md](reference/notifications.md)).
- Naming a person means mentioning them: resolve to a Slack user id and write `<@U…>` — plain `@name` pings nobody. Email is the reliable key (a GitHub login is not a Slack handle). The fallback is non-blocking: an unresolved id posts the plain name rather than not posting.
- A red failure alert is deduped by its failure signature — the failed precondition or step plus its one-line reason class, stable across ticks: never a SHA, a timestamp, a file count or any varying detail. Before posting, read the channel's recent history (~50 messages) and suppress only the same signature inside a 24-hour cool-down; the rule suppresses repeats, never first reports. A suppressed tick names the suppression in its terminal report (`alert suppressed as duplicate - <signature>`) and posts one line as a threaded reply on the existing alert (`↳ still failing - <signature>, first reported <time>, <N> ticks`) — the reply is not itself rate-limited, since only a fresh reply answers "is this still happening". The cool-down suppresses the **top-level** post and nothing else: a changed signature or a first report always posts a root, and an unreadable history posts the alert anyway, because silence must never be produced by a failure of the mechanism that decides to be silent.
- The orange/green/yellow/purple/rocket posts announce events the session itself produced and are new every time; deduping those would hide real work.

Slack is the only surface — the repository's `dev-<repo_name>` channel; no mobile or push notification. An event earns its post by being something a developer must act on or stay aware of: post a unit started, a proposal opened, a merge, a handoff, a blocked-on-precondition failure; do not post an idle tick, a claim, a heartbeat, a ticket archived, a commit, a passing test, or a build — the tie goes to silence. Changing a template makes every live routine drift by construction; the fleet is refreshed one routine at a time, confirmed verbatim — never as part of the change that edits the template.

### The scripts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routine-templates.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-routine.sh <template-id> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-setup-sheet.sh <template-id|--all> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh [name-or-url]
```

`/setup-routines` renders copy-paste setup sheets and manages nothing: `render-setup-sheet.sh` emits, per template, the name, model, repository, the prompt verbatim, and the UI steps derived from the template's `trigger_kind`/`trigger_event`/`trigger_filters` declaration — derived, so a changed trigger cannot leave a stale procedure behind. It makes no `RemoteTrigger` call and asks nothing. The account-management surface (digest gate, drift and fleet reports) is retired; do not reintroduce a reader "just to report what exists" — the trigger wiring is invisible to the API, so such a report is authoritative about what does not matter and silent about what does ([reference/routines.md](reference/routines.md)).

### Preconditions, checked before anything is scheduled

Reported, never gates (the web bootstrap in §4 is the third, and the one without which nothing runs at all):

- The Slack connector must be attached (nothing here can verify it was kept), and the channel must exist: `bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>` probes `dev-<repo>`. "Cannot check" is never reported as "does not exist" — only a probe that actually reached Slack may set `exists`; everything else is `checked: false` with a named reason (`no_qfs`, `slack_locked`, `slack_not_connected`).
- On a public repository, Issue and Pull request permissions must be `Collaborators only`. This is the precondition of the whole loop: an Issue or pull-request body becomes an unattended agent's instructions, and this bounds that injection surface to people inside the repository. Nothing here can verify it; the sheet states it.

### What may be applied unattended

Reading (listing, rendering, reporting) is unattended-safe. Every mutation of a standing outward-facing process needs a human seeing exactly what it will be — confirmed verbatim, one routine at a time, never batched, never inferred from a report, never performed by an unattended run. An agent may not bring such a process into existence, or re-point one, without that.

### What the command does with all this

Resolve the repository first (`resolve-repo-url.sh [name-or-url]`; no argument means this checkout — when `source` is `same_org_as_checkout`, say which repository it resolved to). Render the sheets, report the preconditions, and say plainly what cannot be verified from here. Print the prompt blocks verbatim — never summarise, re-wrap, or "clean up" a prompt: what the developer pastes is what runs. There is no mutation to confirm and no account to survey: the developer creates the routine in their own browser from the sheet.
