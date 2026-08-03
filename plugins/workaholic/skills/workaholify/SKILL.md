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

The single **gateway** a repository refers to in order to work under the workaholic engineering standards. `CLAUDE.md` stays thin and points here; the rules themselves live in the policy skills' `policies/` directories and are reached **by reference, never by duplication** (`workaholic:development` / `policy-as-plugin`). Referring to this one skill is what gives a session access to the whole rule set.

## 1. The rules live in the policies

The engineering rules are the pillar policy skills — read the relevant ones for the work at hand; do not copy them into a project's `CLAUDE.md`:

- `workaholic:planning` — 企画: business, market, and legal grounding before design/implementation.
- `workaholic:design` — 設計: interaction/experience, security design, data sovereignty, API reach.
- `workaholic:implementation` — 実装: code structure, correctness, runtime, recovery, `directory-structure` + `coding-standards` (always apply to code work).
- `workaholic:operation` — 運用: delivery paths, runtime behavior, recovery.
- `workaholic:development` — how the team develops: AI utilization, review, commit history, and working conventions.
- `workaholic:safety` — incident response, risk management, privacy, and security standards.

Each links English hard copies under its `policies/<slug>.md`. This gateway is the referral point; the always-on `hooks/policy-lens.sh` injects the same lens on the workflow commands. To read a rule, open the pillar skill and its `policies/` hard copy — that is the source of truth, kept in sync from qmu.co.jp.

## 2. Working-directory ground rules

Two operational rules a session keeps while working in a repository:

- **Stay at the repository root.** Do not move the working directory away from the repo root; treat the root as home.
- **If you must `cd`, return immediately.** Prefer an **absolute path** or a `( cd <dir> && … )` **subshell** (which never changes the persistent working directory) over a bare `cd` that strands the session outside the root.

These are enforced by `hooks/guard-working-directory.sh` (a `PreToolUse(Bash)` guard that detects a top-level `cd` moving the persistent cwd; a `( cd <dir> && … )` subshell, an absolute-path command, and a tool prefix like `npm --prefix <dir>` are not flagged). A matched top-level `cd` is **denied** (`permissionDecision: "deny"`), with a reason naming the offending command and the sanctioned alternatives — **unconditionally, with no env-var toggle**: enforcement is built into the plugin code, so "plugin installed = guard active", identical on every machine and fresh clone. (An injectable opt-in switch fails open exactly when it is not set, which is when the guard is needed, and an advisory reminder is text an agent ignores.) The subshell / absolute-path / `--prefix` patterns still pass silently, so correct usage is never blocked.

## 3. CLAUDE.md audit

`/workaholify` checks that the repository's `CLAUDE.md` meets the documentation standard — it exists at the root and **refers to this gateway** (rather than embedding the rules). Run the audit and report the checklist:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/audit-claude-md.sh
```

It returns `{file, conformant, checks:{claude_md_present, refers_workaholify_gateway}, missing:[...]}`. When `conformant` is `false`, report the `missing` checks self-explanatorily (`workaholic:design` / `self-explanatory-ui`) and offer to add the missing content — a reference to this gateway, not a copy of the rules. The checklist is intentionally small and extends as the documentation standard grows; keep every check a **verifiable** condition (`workaholic:implementation` / `objective-documentation`).

## 4. The web bootstrap

**A routine that is configured and a routine that works are different states**, and the difference is this hook.

Claude Code on the web starts every session in a fresh, ephemeral container. `enabledPlugins` and `extraKnownMarketplaces` in `.claude/settings.json` are **not** enough there — the plugin is not fetched or installed automatically, it must be installed explicitly before the session's skill registry is built. A local session keeps a persistent `~/.claude`, so this is a no-op outside the web.

Without it, every cloud routine for the repository stops at its own precondition. The `[Drive]` prompt says so in as many words: *"the workaholic plugin must be loaded … if it is not, post the failure and stop."* The routine fires on time and does nothing, which reads as healthy from the routines list and leaves no trace in git.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-bootstrap.sh [repo-root]
```

The canonical hook is `bootstrap/session-start.sh` — the plugin holds it, the repository installs it, the same shape as the routine templates below. `matches_canonical` compares the installed copy byte-for-byte, so an older copy is reported as drift rather than passing because a file exists at the path.

**Every problem is named separately** (`hook_missing`, `hook_stale`, `not_registered`, `matcher`, `timeout`, `enabled_plugin`, `marketplace`) because they need different fixes. Two are worth knowing on sight: `SessionStart` also fires on `resume`, `clear` and `compact`, so the matcher must be `startup`; and a marketplace clone plus install can exceed the default timeout, so it is set to 120.

The hook's own corrections (qmu/workaholic#126) are recorded in its header — it fails open by design, status-checks each step rather than wrapping them in a `{ … } || echo FAILED` group that silently reported success on total failure, drops the invalid `marketplace add --scope user`, and is idempotent.

## 5. Scheduled routines

Routines are how a project actually runs: a `[FB]` routine turns a Slack-reported issue into a feedback record and a PR, a `Merged PR` routine announces a merge, and a `[Drive]` routine runs the queue on a schedule. Wiring them up is part of *"wire this repository to the standards"*, which is why it lives here and not in a second setup command — the second setup command is the one nobody runs.

**These are Claude Code Web routines, not cron jobs.** Each one is a scheduled or event-driven cloud session with its own checkout, reached through the `RemoteTrigger` tool (`list` / `get` / `create` / `update` / `run`). There is deliberately no local scheduler in this picture, and no crontab: a machine's crontab would be invisible to everyone but its owner, which is the problem this replaces rather than a mechanism to copy.

### One set of templates, many repositories

The templates live in **this skill** (`routines/*.md`), not in any repository's `.workaholic/`. That is the whole shape of the thing. Measured across the live account when this was written: the `[FB]` prompt is byte-identical across seven repositories, and so is `Merged PR` — what differs is only which repository the routine points at. A per-repository declaration would be one copy per repo of a file that is identical everywhere except its own URL, each copy free to drift, and none of them the source of truth (the routine itself lives in the cloud account, and `list` reads it back).

| Template | Trigger | What it does |
| -------- | ------- | ------------ |
| `fb` | event | A reported issue becomes a `/fb` record and a PR |
| `merged-pr` | event | A merge is announced to `dev-<repo>` |
| `drive` | cron `56 * * * *` | The hourly unattended drive runner (still a pilot; bounded to 2 units/tick) |

Everything below a template's `## Prompt` heading is the routine's prompt, verbatim. Three substitutions, each demanded by the live routines: `{repo}` (full URL, for the `…/pull/123` links), `{repo_slug}` (`org/repo`, how the Drive prompt names the repository in prose), and `{repo_name}` (bare name, the routine's own name and the `dev-<name>` Slack channel). **Anything else that differs between two repositories' routines is drift, not configuration.**

Keeping the prompt as readable markdown rather than an embedded JSON string is deliberate: the prompt *is* the routine, template freshness is the entire point of the issue behind this, and a prompt nobody can read in a diff is a prompt nobody will keep current.

### Where the configuration lives (decided 2026-08-03)

Three places, one kind of fact each, and **the repository declares nothing**:

| Holds | What it owns |
| ----- | ------------ |
| The **plugin** | What a routine *should* be — the templates above, one set for every repository |
| The **account** | What a routine *is* — the live routine, reachable only through `RemoteTrigger` |
| The **repository** | Nothing new. `{repo}`, `{repo_slug}` and `{repo_name}` all derive from its own git remote |

A repository was never short of a config file; it was short of an **answer**. "What runs against this repo" was unanswerable because nothing read the account back to the developer — so the fix is a reader (`/setup-routines`), not a directory. **No `.workaholic/` area is introduced**, so no closed-layout amendment is involved.

Three alternatives were rejected, and the reasons matter more than the verdict. *Per-repository declarations* would be one copy per repo of a file identical everywhere but its URL, each free to drift and none of them authoritative — the design this skill already refused. *A selection manifest* naming which templates a repo wants is the one genuinely per-repository fact, and the closest call; it was rejected because the selection is uniform across the fleet today except for `[Drive]`, which is a pilot, so the manifest would freeze an unsettled pilot into repository policy. *A committed snapshot of the live routines* would go stale silently, and a stale snapshot reading as healthy is exactly the failure §4 exists to catch. The full record with its rejected alternatives is in the feedback stream (`20260803213008-where-routine-configuration-lives-and-what-an-agent-may-apply-unattended.md`).

### What may be applied unattended (decided 2026-08-03)

The boundary is **read versus write**, not one command versus another:

- **Reading is unattended-safe.** Listing, rendering, comparing, and reporting drift may run in any session — `/drive`, a cloud routine, anything. They reach nothing and change nothing.
- **Every mutation needs a human looking at the exact body.** Create, refresh and remove are confirmed **verbatim, one routine at a time**, in an interactive session. Never batched into a single yes, never inferred from a drift report, never performed by an unattended run.

Both loop runbooks say *"do not install the crontab from an agent session — applying a standing outward-facing process is the developer's act."* That rule survives intact; the crontab was incidental to it. Generalized: **an agent may not bring a standing outward-facing process into existence, or re-point one, without a human seeing exactly what it will be.** All that changed is the sanctioned path — the confirmation is now mediated by a script instead of done entirely by hand, which makes it checkable rather than merely instructed.

### The scripts, and the split they enforce

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routine-templates.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-routine.sh <template-id> <repo-url>
<RemoteTrigger list JSON> | bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/compare-routines.sh <repo-url>
```

**Scripts own the templates and the comparison; the command owns the API and the confirmation.** A shell script cannot call `RemoteTrigger` — only the main agent can — so the command fetches the live list and pipes it in. That split is what keeps the logic out of markdown (the Shell Script Principle) *and* testable: `compare-routines.sh` is driven against fixtures in the suite without touching anyone's account.

**A routine belongs to a repository when its `sources[].git_repository.url` matches**, compared after stripping a trailing slash and `.git` — never by name. Names are what drift; matching on them would report a renamed routine as both missing and unknown at once.

**Drift is surveyed across the whole fleet, not just this checkout.** The templates are one set applied to many repositories, so drift is a property of the fleet: `Merged PR qmu-co-jp` losing its `model` is the same defect whichever repository you are standing in, and a survey scoped to the current repo would need somebody to visit seven checkouts to find seven instances of one problem. The asymmetry in the output is deliberate — `this_repo` reports **missing and drifted** (you are here; adopting a template is in scope), `other_repos` reports **drifted only**, over routines that already exist. A repository with no `[Drive]` routine has not failed to install one: that template is still a pilot, and "every repo should have all three" is not established. Proposing to create routines in repositories nobody is working in would be inventing policy out of a survey.

**A missing Slack connector counts as drift.** Every template posts to `dev-<repo>`; a routine without the connector runs, does its work, and fails silently at the last step.

**Drift is reported per field, not as a boolean.** Measured live: `Merged PR qmu-co-jp` and `[FB] coop-csnet` carry no `model` at all while every sibling pins `claude-opus-5`, and `[FB] data-platform` has one extra prompt line. "This routine differs" would not tell a developer which of those they are looking at.

**`unknown` is information, not an error.** A routine pointing at this repository that matches no template is somebody's deliberate one-off. It is listed so nothing is invisible, and nothing here ever proposes removing it — the API has no delete at all, and that asymmetry is a feature: this flow can add and refresh, never destroy. Deletion is a human act at <https://claude.ai/code/routines>.

### Preconditions, checked before anything is scheduled

(The web bootstrap in §4 is the third, and the one without which nothing runs at all.)

Every template posts to `dev-<repo_name>`, so two things must hold before a routine is worth creating. Both are **reported, never gates** — they are environment-dependent, and blocking on them would make `/workaholify` unusable on a machine without the tooling.

- **The Slack connector must be attachable.** `compare-routines.sh` reports `slack_connector` — discovered from whatever live routine already carries one, because a new routine's body needs that `connector_uuid` and `url`, and the account is the only place they exist. A routine created without it is drift by definition, and the comparison says so.
- **The channel must exist.** `check-slack-channel.sh <repo-name>` probes `dev-<repo>`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>
```

**"Cannot check" is never reported as "does not exist", and that distinction is the reason the script exists.** On a locked qfs credential store, an existing channel and a nonexistent one return the *identical* `slack_auth` error — so a naive "did the read succeed?" test marks every channel missing and sends a developer to create channels that are already there. Only a probe that actually reached Slack may set `exists`; everything else is `checked: false` with a named reason (`no_qfs`, `slack_locked`, `slack_not_connected`).

That failure class has already cost this project twice: a survey concluded "no routines are installed" from an empty crontab, on a machine whose routines run in the cloud. Absence of evidence is not evidence of absence.

### What the command does with all this

Report the state, then **show the developer the rendered prompt and get an explicit confirmation before any `create` or `update`**. A routine is a standing, outward-facing process that will act on this repository unattended; that is the same class of commitment as `/request` crossing a repository boundary, and it gets the same treatment — the verbatim body, confirmed, every time. `environment_id` is an account-level fact with more than one valid answer, so it is asked rather than guessed.

