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

Without it, every cloud routine for the repository stops at its own precondition. The `[Implement]` prompt says so in as many words: *"the workaholic plugin must be loaded … if it is not, post the failure and stop."* The routine fires on time and does nothing, which reads as healthy from the routines list and leaves no trace in git.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-bootstrap.sh [repo-root]
```

The canonical hook is `bootstrap/session-start.sh` — the plugin holds it, the repository installs it, the same shape as the routine templates below. **It also provisions `gh`** (2026-08-06): the web container ships none, and fourteen plugin scripts shell out to it — `publish-tree-pr.sh` pushes the branch and then reports `no_gh` instead of opening the pull request, and `merge-pr.sh` cannot run at all, so every cloud `auto` unit was demoted to the PR path and every routine-published artifact waited for a human. The step is guarded on `command -v gh` (an already-provisioned container pays nothing), needs root, and is **non-fatal in every branch** — `gh` still absent afterwards is the status quo, not a regression, so the hook logs one legible line and session start still succeeds. `matches_canonical` compares the installed copy byte-for-byte, so an older copy is reported as drift rather than passing because a file exists at the path. The hook's already-installed fast path is **version-gated, not presence-gated** (2026-08-04): a cloud container image bakes a marketplace clone in, so "installed" can mean a version several releases behind the checkout, and skipping on presence made that permanent — the stale copy's retired mission migration dirtied the tree on every prompt and aborted every hourly drive tick. The skip now requires the installed version to match the checkout's `.claude-plugin/marketplace.json`; anything else refreshes the marketplace and runs `plugin update` (or `install`).

**Every problem is named separately** (`hook_missing`, `hook_stale`, `not_registered`, `matcher`, `timeout`, `enabled_plugin`, `marketplace`) because they need different fixes. Two are worth knowing on sight: `SessionStart` also fires on `resume`, `clear` and `compact`, so the matcher must be `startup`; and a marketplace clone plus install can exceed the default timeout, so it is set to 120.

The hook's own corrections (qmu/workaholic#126) are recorded in its header — it fails open by design, status-checks each step rather than wrapping them in a `{ … } || echo FAILED` group that silently reported success on total failure, drops the invalid `marketplace add --scope user`, and is idempotent.

## 5. Scheduled routines

Routines are how a project actually runs, and there are **two** templates, each **four lines long**: a `[Propose]` routine (template id `fb`; named `[FB]` until 2026-08-04) turns an assigned GitHub issue into a record and, when its judgment warrants it, the work that record asks for — both in one PR — and an `[Implement]` routine (id `implement`; named `[Drive]` until P1, 2026-08-06) drains the queue when a proposal's pull request merges. Wiring them up is part of *"wire this repository to the standards"*, which is why it lives here and not in a second setup command — the second setup command is the one nobody runs.

**Two, because a developer configures these by hand and every field multiplies by the number of projects** (P3, 2026-08-06). The count is the constraint the loop's shape is set by — not what the plugin can express. Two retirements got it here. `[Propose Batch]` existed for part of 2026-08-04: proposing belongs in the session that receives the ask, not in a sweep over what has already merged (`docs/proposal-loop-runbook.md` §7).

**`[Consent]` was retired on 2026-08-06, and what that costs is stated rather than discovered.** It announced a merge — the approval, in this workflow — into the merged item's feedback thread. **A human-merged pull request is now announced by nobody**: `[Implement]` posts only for the units it ran, so a merge a developer performs out of band produces no channel line at all. That is the accepted price of one fewer standing process per project, and the developer accepted it explicitly. Two things soften it and neither replaces it: the merge is what *starts* `[Implement]`, so a merged **proposal** still produces a post (the run's own 🟠 start line, in the item's thread), and every merge remains readable on GitHub. What is genuinely gone is the channel-side record of a merge that started no run. Do not reintroduce a third routine to recover it — the whole point of the reduction is that a third standing process costs more, per project, than the line it produces.

**What a prompt may carry.** Four lines, each one something the plugin cannot know: the environment (what started the session, that nobody is present), the payload the target and the ask are read out of, the one command, and **the channel and post shape**. That last is the one thing a routine cannot defer — the channel and the shape *are* its output contract, and nothing else in the plugin states them. Everything else has a home and is deferred to it: the run to `workaholic:drive`, the judgment and the record to `workaholic:propose` / `workaholic:feedback`, every other notification rule (thread routing, red-alert dedup, mention resolution) to this SKILL, the standing prohibitions to the always-loaded `rules/`. **A prompt that restates a rule is a second source of truth, and the drift is one-directional** — the routine is what runs, and nothing rebuilds it from the skill. `[Drive]` was the proof: 141 lines of restated run procedure against the other two at ~55, and the restatement had drifted into instructing a hand-filter for mission ownership `plan-units.sh` had performed for weeks.

**These are Claude Code Web routines, not cron jobs.** Each one is a scheduled or externally invoked cloud session with its own checkout, reached through the `RemoteTrigger` tool (`list` / `get` / `create` / `update` / `run`) — and *invoked* is literal, not a synonym for event-driven; see *What a routine can be triggered by* below. There is deliberately no local scheduler in this picture, and no crontab: a machine's crontab would be invisible to everyone but its owner, which is the problem this replaces rather than a mechanism to copy.

### One set of templates, many repositories

The templates live in **this skill** (`routines/*.md`), not in any repository's `.workaholic/`. That is the whole shape of the thing. Measured across the live account when this was written: the `[FB]` prompt is byte-identical across seven repositories, and so was the merge-announcement routine's before it was retired — what differs is only which repository the routine points at. A per-repository declaration would be one copy per repo of a file that is identical everywhere except its own URL, each copy free to drift, and none of them the source of truth (the routine itself lives in the cloud account, and `list` reads it back).

| Template | Trigger | What it does |
| -------- | ------- | ------------ |
| `fb` | github-issue-assigned | An issue assigned to the developer becomes a `/fb` record and a PR |
| `implement` | github-pr-merged | A merged proposal starts the unattended executor (`/implement`) |

#### What a routine can be triggered by — the settled answer (documented + measured, 2026-08-06)

**A routine can be triggered three ways: a schedule, an API call, or a GitHub event — and the GitHub one is configurable only in the web UI.** That is the product's own documentation ([Routines](https://code.claude.com/docs/en/routines), *Add a GitHub trigger*: "GitHub triggers are configured from the web UI only"). Supported event categories are **Pull request** and **Release**, each narrowable by filters (author, title, body, base/head branch, labels, is-draft, **is-merged**) combined with AND; `matches regex` tests the whole value, so substring matching wants `contains`. An API trigger's token is likewise **generated in the UI only** — "The CLI cannot currently create or revoke tokens" — and fires `POST /v1/claude_code/routines/<id>/fire` with an optional `text` payload.

**None of that is visible in a routine record.** Read back over the live account, the record's trigger surface is three fields and nothing else:

| Field | What fires the routine |
| ----- | ---------------------- |
| `cron_expression` | a recurring schedule |
| `run_once_at` | one scheduled time |
| `api_token_hint` / `api_token_created_at` | **an external caller** POSTing `/v1/code/triggers/<id>/run` with that token |

There is **no event-subscription field of any kind** — nothing naming a pull request, a merge, a push, a repository or a webhook — so the GitHub wiring is unreadable, unwritable and unverifiable from a session. A template's `trigger:` therefore states the **designed** trigger for the reader — not a field the API stores.

**"Has this routine ever run?" is unanswerable for exactly the routines that matter.** `last_fired_at` is populated for a **cron** fire (the drive routine's 2026-08-06T02:56Z tick, on the clock it ran before the merge trigger, recorded one) and **absent for a GitHub-triggered fire** — `[Propose] workaholic` turned issue #266 into PR #267 at 03:23Z that same morning and its record still carries no such key. So the field distinguishes nothing for a GitHub-triggered routine, and **no claim may rest on its presence or absence**; a reader who needs to know whether one ran looks at what it produced (an issue, a pull request, a channel post), never at the account.

**The designed wiring, per template** (the developer's instruction, 2026-08-06): `[Propose]` fires when **a GitHub issue is assigned**; `[Implement]` fires when **a proposal's pull request merges** (Pull request → closed, filtered `is merged: true` and title contains `[Proposal]`). One event, one owner — and with `[Consent]` retired, the merged-pull-request event has exactly one owner rather than two templates to keep apart.

**Neither trigger narrows to a person, and that is a ruling rather than a limitation we worked around** (2026-08-06). The routines UI offers no assignee filter at all, which killed the original `assignee = the developer` design; an `author` filter on `[Implement]` was tried and dropped with it. **Every developer's copy of both routines fires on every matching event, and the data decides whose work it is.** That costs N−1 empty sessions per event and buys something the trigger could never give: ownership lives in the repository, where every runner reads it through one oracle, instead of in a UI setting nothing can read, write or verify.

**Neither prompt carries a guard; both commands do their own filtering.** `/implement` filters at the **survey** — it drops what it does not own (`owned_by_other`), so a runner whose work this is not takes nothing and ends `ok`. `/propose` filters at its **input** — it compares the triggering issue's assignee against the session's own GitHub identity (`gh api user`) and reports `not_mine` when they differ (P8). The two ask the same question at the only place each can: `/implement` claims artifacts that already carry `assignees`, while `/propose` *creates* the artifact that will carry them, so it has nothing to survey yet. Without the second check, N developers would open N pull requests for one Issue — the dedup (`list-proposed-refs.sh`) only sees proposals that already reached a branch, and simultaneous routines have all published nothing yet.

**The check is the command's, never the prompt's.** "Whose work is this" is one rule; stated in two routine prompts it is a rule that drifts, and it would also break the templates' symmetry — both are the developer's own four lines with nothing added.

**Both templates are per-developer, and that takes two mechanisms rather than one** (P6, 2026-08-06). A repository has several developers, each with their own copy of both routines, so "whose run is this" has to be answerable — and the trigger filter alone cannot answer it, because a trigger is a UI setting nothing in the plugin can read or verify. So:

- **The filter bounds the cost.** `author = the developer` on `[Implement]` keeps a merged proposal from starting *everyone's* runner; without it, N developers means N sessions per merge and N−1 of them find nothing to do.
- **The data decides the ownership.** `/propose` writes the triggering issue's **assignee** onto every artifact it emits (`--assignee`, `workaholic:propose`), so the identity enters once at the trigger and rides the chain. A runner that fires anyway surveys, sees `owned_by_other`, takes nothing, and ends `ok`.

Ownership is the load-bearing half: it is in the repository, every runner reads it through the same oracle, and it holds even when a trigger is misconfigured. Before it existed, a proposal-born artifact was **unowned** — which correctly means "claimable by anyone" — so every developer's runner raced for it and whose push landed first decided whose job it was.

Two prior readings of the account got this wrong in opposite directions, and both failed the same way — by treating the record as able to answer a question it does not carry. First an absent `last_fired_at` was read as "never fired". Then the absent event field was read as "no event path exists". Neither field answers it; the documentation and the design do.

**A `[Propose]` routine observed firing on a merged pull request is misconfigured.** The merge is `[Implement]`'s event, and one event has one owner. Repairing a live routine's trigger is a **human act in the routines UI**: the trigger wiring is invisible to `RemoteTrigger list` and unreachable by it, so neither the drift report nor `/setup-routines` can see or fix it — they cover the prompt, model, schedule, `enabled` and the Slack connector, and the trigger only through the template's declared intent.

**The consequence for scheduling** (settled 2026-08-06): `[Implement]` is merge-triggered — the developer's original ask, implementable all along through the same UI wiring that fires `[Propose]` on an assigned issue. The clock argument this paragraph used to make (handoff resumption, lapsed claims and `/ticket`-written backlog have no merge event) is answered by the survey itself: every merge-started run offers *everything* claimable, so the leftovers ride the next merge rather than a timer. A machine-local cron remains available as the fallback shape (`docs/drive-loop-runbook.md`), and is a developer's act to stand up.

Everything below a template's `## Prompt` heading is the routine's prompt, verbatim — **and it is byte-identical in every repository** (P7, 2026-08-06). A prompt carries **no substitution and no repository name**: the session already knows which repository it is in, so naming it made each project's copy different, which is exactly the per-project cost the two-template reduction exists to remove. A developer pastes the same four lines everywhere.

`{repo_name}` survives in one place only — a template's `name:`, which is a **UI field**, not the prompt — because a routines list has to say which repository each routine belongs to. **Anything that differs between two repositories' *prompts* is drift, not configuration.**

The renderer accepts the repository URL in **any of its spellings** — `https://github.com/owner/name`, `git@github.com:owner/name`, `ssh://git@github.com/owner/name`, each ± `.git` and a trailing slash — and render identically. The **Repository** field on the setup sheet renders the **https** form, because it is a link a person clicks and the value a created routine carries into a live standing process. A URL that already carries a scheme is passed through untouched, so a proxied `http://…` remote is never rewritten.

Keeping the prompt as readable markdown rather than an embedded JSON string is deliberate: the prompt *is* the routine, template freshness is the entire point of the issue behind this, and a prompt nobody can read in a diff is a prompt nobody will keep current.

**A red failure alert is deduped by reading the channel; an event announcement never is** (added 2026-08-04; the full rule moved here from `routines/drive.md` §0a on 2026-08-05, so the template points at it rather than carrying it). A repeated alert with no new information trains the operator to ignore alerts, and the hourly runner produced one near-identical red post per hour for two days from a single root cause (a stale baked-in plugin install), not one repeat carrying anything the first had not. Each tick is a fresh container, so no local state survives — but the **Slack channel itself** does, and the routine already reads and writes it, so the throttle is a read-before-post rule rather than a stored counter.

**The failure signature** is the precondition or step that failed plus its one-line reason class — `plugin-not-loaded: workaholic absent`, `dirty-tree: uncommitted changes on main`. It must be **stable across ticks**: never a SHA, a timestamp, a file count, a branch name or any other varying detail, or every repeat reads as a change and nothing is ever suppressed. Before posting a red alert, read the channel's recent history (~50 messages), find the most recent red alert from that routine, and suppress **only** when it carries the same signature inside a 24-hour cool-down — a changed signature posts immediately, and a condition recurring after the cool-down posts again. The rule suppresses repeats, never first reports. A suppressed tick **names the suppression in its own terminal report** (`alert suppressed as duplicate - <signature>`), so a quiet-because-healthy tick and a quiet-because-known-repeat tick are distinguishable from the session log alone. It **fails toward alerting**: an unreadable history posts the alert, because silence must never be produced by a failure of the mechanism that decides to be silent.

**A suppressed tick replies in the alert's thread; it does not go silent** (added 2026-08-05). The rule above was written against a failure that *repeated* — one near-identical red post per hour for two days — and it did not anticipate one that **persists through the whole cool-down**. Measured 2026-08-05: the hourly drive routine fired at 11:56, 12:56, 13:56 and 14:56 JST with two claimable tickets queued and produced nothing — no claim, no post, no pull request — because every tick stopped at the superseded-plugin gate whose alert had been posted once at 08:01. The channel was indistinguishable from a working fleet with nothing to do, and it was noticed only because a developer asked what was running. A monitoring signal that cannot tell *healthy* from *broken and already reported* is not a monitoring signal (`workaholic:implementation` / `observability`).

So while a signature is suppressed, the tick posts **one line as a threaded reply on the existing alert**, carrying what has actually changed — that the condition is still present, when it was first reported, and how many ticks have hit it:

```
↳ still failing - `<signature>`, first reported <time>, <N> ticks
```

**The ordering is the part a later edit will get wrong, so read it exactly.** The cool-down suppresses the **top-level** post and nothing else; the threaded reply is what *replaces* that post, never a substitute for either of the two cases that still post a root. A **changed** signature posts a new root immediately, and the **first** report of any signature is always a root. And the fail-open direction is unchanged: an unreadable channel history posts the alert as a **root**, because silence must never be produced by a failure of the mechanism that decides to be silent. A reply that cannot be posted is not an error — Slack is never load-bearing here either.

**Every suppressed tick replies; the reply is not itself rate-limited** (decided, with the alternative named). The reply's entire job is to answer *is this still happening*, and only a fresh reply answers it — a rate-limited one reintroduces one level down the exact ambiguity the top-level suppression created, where a missing line means either "suppressed" or "the fleet is dead". Because the line carries elapsed time and a tick count, each reply carries information the previous one did not, which is what distinguishes it from the repeat the dedup rule exists to remove. The cost is bounded and local: a thread an operator opens deliberately, rather than a channel line everyone scrolls past, and it ends the moment the condition does. An exponential backoff (reply on the 1st, 2nd, 4th, 8th tick) was considered and rejected for making "no reply this tick" ambiguous again while being harder to state and to check.

The orange/green/yellow/purple/rocket posts announce events the session itself produced and are new every time; deduping those would hide real work.

**The shapes of the runner's posts**, so a template names its postable events without restating how each line looks. `<@U…>` follows the mention rule below; `<repo>` is the repository the session is running in, which it derives itself rather than being told.

```
🟢 Proposed to <@U…> - [#123 [Proposal] Issue Title](<repo-url>/pull/123)
One sentence, max 40 words, what the ask is — and, when the PR carries work, what it proposes.
`fb:<stem>` · <session URL>

🔴 drive blocked - `<signature>`
One sentence, max 25 words, what failed and what a human must do.

🟠 drive started - `<unit-id>`
`<branch>`, one sentence, max 25 words, what this unit contains only.

🟢 Merge Requested for <@U…> - [#123 Issue Title](<repo-url>/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

🟡 Handoff <@U…> - [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>
```

**🟢 Proposed is the `[Propose]` routine's thread root** — its `` `fb:<stem>` `` line is the key every later reply searches for, so it is never dropped. The root announces only the pull request you just created in this session, exactly once — post nothing if you created none, and never announce another session's work. A merge uses the 🟢 Merge-Requested shape with its line swapped for the actor: **🚀 Auto Merge by Claude** when the unit's recorded `merge_policy` was `auto` and `/ship` merged it, **🟣 Merged by `<@U…>`** when a human merged it during the run. That distinction is the point — a developer scanning the thread must be able to tell what merged without approval from what a person approved — and it is why the auto line names no person.

### One thread per feedback item — the notification model (decided 2026-08-04)

**The unit of a notification is the reader's item of interest, not the emitter's step** (`workaholic:design` / UX). Until this date each routine posted its own top-level line — "🟢 PR opened", "🟣 PR merged" — so following one feedback item from ask to merge meant reassembling it from posts scattered across the channel, each threading to nothing. The replacement: **one Slack thread per feedback item, carrying its whole life.** The `[Propose]` routine posts the root; every later event of that item — the merge, and any `/implement` outcome for work that traces back to it — is an **in-thread reply**. All three templates implement this model; it is stated here once and referenced, never restated per template.

**The key is the feedback record's filename stem**, embedded verbatim in the thread root as `` `fb:<stem>` `` (for example `` `fb:20260804101847-make-workaholify-record-the-fb-to-merge-lifecycle-as-one-semantic-slack-thread` ``). That identifier was chosen over the GitHub issue number because it is the one that **lives in the repository**: a mission carries `feedback: [<filename>]`, a record carries `supersedes`, and a publishing PR names the file in its own diff — so a later session derives the key from the artifact it is already working on rather than from a channel post it has to find first. The issue number rides the root post too, as a human pointer, but nothing keys on it.

**Finding the thread, in four ordered cases.** Take the first that applies:

1. **The session's own trigger message.** When a routine can identify the Slack message or thread that started its run, reply there. That message *is* the item's thread — a developer who asked for something in the channel is already holding the conversation the routine is about to join.
2. **The target the triggering pull request carries.** When the run was started by a merged pull request, read its body with `branching/scripts/read-notify-target.sh <pr>`: `found: true` gives the thread verbatim and no search happens. This case was added by P4 (2026-08-06) and sits **above** the search deliberately — the writer put the target there, so it cannot be guessed wrong, whereas a search has to guess. `reason: "absent"` falls through to case 3, which is what every pull request opened before that change does.
3. **The `fb:<stem>` key search.** Otherwise search the channel for the key (the Slack MCP tools every routine already loads read channel history) and reply into the thread whose root carries it.
4. **A new root carrying the same key.** Otherwise post one — never a keyless top-level line: search is eventually consistent and a miss is expected, so the fallback must leave the story reconstructable rather than orphan the event. Two roots with one key is a repairable mess; a keyless post is not attributable to anything.

**Cases 1 and 2 are not reducible to the search, which is why they are written separately.** Case 1 (2026-08-05): the key is minted by the very session that posts, so a message a developer wrote *before* the record existed can never carry it and the key search can never match it — on 2026-08-05 that produced two roots for one item, the developer's own thread asking for a fix and a separate top-level announcement of the resulting PR. Case 2 (P4, 2026-08-06): a chain hand-off knows its target at *write* time, so making the next routine re-derive it turns a known fact into a search — the same failure in a different place. The search remains the only answer for an item with neither a human trigger message nor a carried target, so both cases were **added to** it, never substituted for it.

**How a session identifies its trigger message is left to the session; the routine's own trigger payload is the natural source.** Where no reliable identification exists the correct outcome is case 2 — matching by recency or by message content would thread unrelated items together, which is a worse failure than a second root.

#### Which thread an `/implement` unit's posts land in (decided 2026-08-05; scoped to the unattended run 2026-08-07)

**These posts are the unattended run's** (`/implement` — the routine and any caller-side loop): they exist so an absent operator can tell a working fleet from a dead one. An attended `/drive` session posts nothing to Slack — the developer is watching the run, and its report is the session's.

**An implement run's start and finish are per-*unit*, not per-run**, and each lands in the thread of the item that unit's work traces to. Per-run was unroutable by construction: "a run started" names no single item, so there is no thread it could reply in, and the announcement fell back to a top-level line the model exists to eliminate.

**The unit resolves to its stems through one reader.** `drive/scripts/unit-feedback-stems.sh` takes the unit's artifacts — the mission's `mission.md` for a mission unit, the ticket files for a batch — and reports the deduped feedback stems behind them, through `propose/scripts/read-feedback-relation.sh`. A mission unit whose own `feedback:` is empty resolves through its queued tickets instead; a stem is the record's filename without `.md`, which is exactly the `fb:<stem>` token a root carries.

Four rules, each answering a case the resolution actually produces:

- **Several stems → post into each of their threads**, once per stem per event. A batch whose tickets trace to two records advances two items, and an item's thread is supposed to carry that item's whole life — reporting into only one of them leaves the other's story missing the work that answered it. The multiplication is bounded by relatedness: a batch is grouped conservatively, so the count is small by construction, and the deduplication in the resolver means the common case (several tickets, one record) is one thread.
- **No stem → key on `` `unit:<unit-id>` ``**, and never post keyless. Both of the unit's posts carry the same key, so the unit's own two lines still thread together. The unit id is the key rather than the pull request's `#<number>` for a mechanical reason: the start is posted at claim time, **before** any pull request exists, and a key that only the finish can compute cannot thread the pair.
- **A unit posts exactly one start and one finish per thread, and the finish's shape follows the outcome** — 🟢 merge requested, 🚀 / 🟣 for a merge, 🟡 for a handoff, 🔴 for a blocked unit. **A handoff is the finish**, not a third post: it is where that unit's run ended, and giving it a line of its own would put two terminal posts in one thread for the outcome that is already the least conclusive.
- **Never re-announce a merge the channel already carries.** This used to be a rule about not duplicating `[Consent]`'s line; with that routine retired (P3) the constraint is simply the unit's own: before posting a merge line, check that no merge notification for that pull request already exists in the channel, in a thread or at top level. It survives the retirement because a resumed unit can reach the route step twice.

**The bot notice `claim.sh` posts is a different surface and is deliberately left alone.** It goes through `notify-slack.sh` with a bot token and no threading, and it is the CLI-side signal that a claim landed — it is not the threaded start post and must not be grown into one. The threaded posts are the session's, made through the Slack connector the routine already loads, which is the only surface that can search for `fb:<stem>` and reply into a thread. Both are non-load-bearing; a repository with neither wired runs identically.

#### The thread URL is disclosed in a public repository — accepted, with its terms (2026-08-06)

`Notify-Thread:` puts a Slack thread URL into a pull request body, and the routine chain expects one in the Issue that starts it. On a **public** repository both are world-readable. **The developer accepted this**, and the terms are recorded here rather than left implicit, because "we looked at it and decided" and "nobody looked" are indistinguishable a year later.

**What it discloses**: the workspace subdomain (already inferable from the GitHub org), the **channel id**, and the **message timestamp to the microsecond**. It is not a credential and grants no read or write — an outsider opening the URL gets nothing without workspace membership. Its residual value is post-compromise convenience (a known channel id skips a discovery step for anyone who later obtains *any* token in the workspace) and **metadata accumulation**: enough of these timestamps profile a team's working hours and cadence.

**Why it is nonetheless worth stating.** Public issue and pull-request bodies are permanently archived and scraped, so editing one later does not unpublish it. The exposure is small but **not retractable**, which is the property that makes it a decision rather than a detail. An earlier note in this repository called the link "workspace-internal; harmless" without accounting for that.

**The bigger adjacent risk is the input, not the URL** — an untrusted issue body reaching an unattended agent — and its mitigation is the `Collaborators only` precondition above. That one is not accepted; it is required.

**Revisit if**: the channel begins carrying customer material (`docs/loop-engineering-workflow.md` I9 already confines that to private repositories), or the repository starts receiving issues from outside the collaborator set. The alternative that costs least is to stop putting the URL in the *Issue* and let `/propose` open the thread itself — the chain still works, and only the link to a conversation held before the record existed is lost.

**Every post carries its session URL** — the Claude Code Web session that did the work, the same URL the harness gives the session for its `Claude-Session:` commit trailer. It is what turns "merged by Claude" into something a developer can audit. If the URL is not discoverable in a given session, **post without it**; a notification missing one line beats a notification that did not happen.

This model governs **what a post says and where it lands, and nothing else** — it changes no survey, no claim, and nothing `/drive` picks or implements.

### Naming a person means mentioning them (decided 2026-08-05)

**A post that names a developer resolves them to a Slack user id and writes the mention token `<@U…>`.** Plain `@name` is inert text: Slack notifies on the token and on nothing else, so five message formats across the three templates appeared to call someone out while pinging nobody. A notification's job is to reach the person it names (`workaholic:design` / UX); one that names them without reaching them is a notification that did not happen.

**How a session resolves it.** Look the person up through the Slack connector the routine already loads — `slack_search_users` on the identity the session has in hand, `slack_read_user_profile` to confirm the match — and write the resulting `<@U…>` where the format shows it. **Email is the reliable key**; a GitHub login is *not* a Slack handle and must not be passed off as one, so when a session holds only a login it resolves the person through the email git records for them (the merge or claim commit's author) and searches on that. A display-name search is the last resort, and a match it cannot confirm is not a match.

**The fallback is non-blocking, with the same precedence the session-URL rule already sets.** When the id cannot be resolved, **post the line with the plain name** rather than not posting: a missing ping costs a nudge, a missing post costs the event. Nothing about resolution may block, delay, or retry-loop a post.

Which identity each routine starts from: `[Implement]`'s merge lines hold the **merging** user, `[Propose]` holds the repository's developer, and `[Implement]`'s handoff line names **whoever the unit is handed to**. The `🚀 Auto Merge by Claude` line names no person and carries no token.

Stated once here; the templates carry the token in their formats and point back at this rule rather than restating it.

### Slack is the only surface, and an event earns its post (decided 2026-08-04)

**One surface.** A routine notifies through the repository's `dev-<repo_name>` Slack channel and nowhere else. Every template says so in its own prompt, because the instruction has to reach the session that would otherwise reach for a push tool: *post to Slack only; send no mobile or push notification.*

**What a template can and cannot switch off — measured, not assumed.** A live routine record carries `name`, `trigger`, `schedule`, `target repository`, `model`, `enabled` and its MCP connections, and **no notification field of any kind** (the record's documented shape — name, trigger, schedule, target, model, `enabled` and its MCP connections, and nothing else). So the duplicate mobile push is **not** routine configuration: the half a template reaches is the session's own behavior, above; the other half is the Claude app's account-level notification for a routine session completing, which no template, script or drift report can touch. Turning that off is a **developer act in the app's own settings**, surfaced by `/setup-routines` and stated there — a truthful "cannot" beats a claimed "did", and a drift report that silently omitted the field would be the worse outcome.

**Dropping a surface narrows visibility, so the remaining one must be worth reading.** The default for an event is **silence**; it earns a post only by being something a developer must **act on or stay aware of**. Two precedents from this repository decide the hard cases, and both are reused rather than reinvented:

- **Drop the low tier by default** — the branch story keeps every concern and the PR body renders it without the `low` ones (`report/scripts/filter-low-concerns.sh`). Same move here: the session log keeps every step; the channel gets the ones that change what a developer does.
- **Dedupe a repeat by its signature** — a red failure alert is suppressed while the same failure signature persists inside its cool-down (above). Announcements of events the session itself produced are never deduped, because each is new by construction.

**The bright line, because a vague bar refills the channel.** Post: a **unit started** (a fleet that is working must be distinguishable from a dead one — per *unit*, not per run, so the line has an item's thread to land in; see *Which thread a unit's posts land in*), a proposal **opened**, a **merge**, a **handoff**, and a **blocked-on-precondition** failure. Do not post: a survey that found nothing, a claim, a heartbeat, a ticket archived, a commit pushed, a passing test, a build, a rebuild of `outputs/`, or a tick that ran and found nothing to do — an idle tick is correctly **silent**, and silence is a report. When an event is genuinely borderline, the tie goes to silence: an unread post costs attention every time it is scrolled past, while a missing one costs a question that the session log answers.

Changing a template makes every live routine drift by construction, and **the fleet is refreshed by `/workaholify` or `/setup-routines`, one routine at a time, confirmed verbatim** — never as part of the change that edits the template. An unattended run cannot do it at all (`/drive` issues no confirmation of any kind), so a template edit and its rollout are two separate acts by design.

### Where the configuration lives (decided 2026-08-03)

Three places, one kind of fact each, and **the repository declares nothing**:

| Holds | What it owns |
| ----- | ------------ |
| The **plugin** | What a routine *should* be — the templates above, one set for every repository |
| The **account** | What a routine *is* — the live routine, reachable only through `RemoteTrigger` |
| The **repository** | Nothing new. The setup sheet's Repository field and a routine's `{repo_name}` both derive from its own git remote; the prompt names no repository at all |

A repository was never short of a config file; it was short of an **answer**. "What runs against this repo" was unanswerable because nothing read the account back to the developer — so the fix is a reader (`/setup-routines`), not a directory. **No `.workaholic/` area is introduced**, so no closed-layout amendment is involved.

Three alternatives were rejected, and the reasons matter more than the verdict. *Per-repository declarations* would be one copy per repo of a file identical everywhere but its URL, each free to drift and none of them authoritative — the design this skill already refused. *A selection manifest* naming which templates a repo wants is the one genuinely per-repository fact, and the closest call; it was rejected because the selection is uniform across the fleet — and, since the reduction to two templates (P3), there is no per-repository choice left for a manifest to record. *A committed snapshot of the live routines* would go stale silently, and a stale snapshot reading as healthy is exactly the failure §4 exists to catch. The full record with its rejected alternatives is in the feedback stream (`20260803213008-where-routine-configuration-lives-and-what-an-agent-may-apply-unattended.md`).

### What may be applied unattended (decided 2026-08-03)

The boundary is **read versus write**, not one command versus another:

- **Reading is unattended-safe.** Listing, rendering, comparing, and reporting drift may run in any session — `/drive`, a cloud routine, anything. They reach nothing and change nothing.
- **Every mutation needs a human looking at the exact body.** Create, refresh and remove are confirmed **verbatim, one routine at a time**, in an interactive session. Never batched into a single yes, never inferred from a drift report, never performed by an unattended run.

Both loop runbooks say *"do not install the crontab from an agent session — applying a standing outward-facing process is the developer's act."* That rule survives intact; the crontab was incidental to it. Generalized: **an agent may not bring a standing outward-facing process into existence, or re-point one, without a human seeing exactly what it will be.** All that changed is the sanctioned path — the confirmation is now mediated by a script instead of done entirely by hand, which makes it checkable rather than merely instructed.

### The scripts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routine-templates.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-routine.sh <template-id> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-setup-sheet.sh <template-id|--all> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh [name-or-url]
```

**`/setup-routines` renders copy-paste setup sheets; it manages nothing** (the developer's ruling, 2026-08-06). `render-setup-sheet.sh` emits, per template, the routine's name, model, repository, the prompt verbatim in one block, the **UI steps derived from the template's own `trigger_kind` / `trigger_event` / `trigger_filters` declaration**, the connectors to keep and the `dev-<repo>` channel to have ready. Deriving the steps is what keeps them from drifting: a template whose trigger changes cannot leave a stale procedure behind in prose. The command makes **no `RemoteTrigger` call at all** and asks nothing — the developer acts in their own browser, and the sheet is what they act from.

#### The management surface is retired, and why it must not grow back

`plan-routine-change.sh` / `authorize-routine-change.sh` (the digest gate) and `compare-routines.sh` / `list-routines.sh` (drift and fleet reporting) were deleted on 2026-08-06 with their tests. They managed the half of a routine the API exposes while blind to the half that decides whether it runs at all, and the measured cost of that asymmetry was two wrong answers in one day: a paginated `list` (20 rows, `has_more` unread) surveyed as the whole account, and six duplicate records carefully refreshed through the digest gate while the real, wired `[Propose]` ran a stale prompt beyond page one. A "drift-free fleet" verdict was reported both times.

Three things worth keeping from that machinery, because they were right and only their application was wrong:

- **The digest gate's reasoning survives the gate.** It closed *substitution* (the plan no longer hashes to its own digest) and *batching* (one confirmation carries exactly one routine) — the two failures a standing outward-facing process cannot survive. Nothing here weakens that bar; the acts it gated are simply gone, because the plugin no longer performs them. The record is `.workaholic/feedbacks/20260806143907-routine-setup-is-a-human-act-the-plugin-makes-cheap.md`.
- **"Could not check" is never "does not exist."** That rule outlived its reader and still governs `check-slack-channel.sh` below.
- **The account has no delete.** Removing a routine is a human act at <https://claude.ai/code/routines>, and always was.

**Do not reintroduce a reader "just to report what exists."** The trigger wiring — the one field that decides whether a routine ever fires — is invisible to the API, so any such report is authoritative about the parts that do not matter and silent about the part that does. That is the shape that misled twice.

### Preconditions, checked before anything is scheduled

(The web bootstrap in §4 is the third, and the one without which nothing runs at all.)

Every template posts to `dev-<repo_name>`, so two things must hold before a routine is worth creating. Both are **reported, never gates** — they are environment-dependent, and blocking on them would make `/workaholify` unusable on a machine without the tooling. A third, below, is not environment-dependent at all and is the one a **public** repository must not skip.

- **The Slack connector must be attached.** A routine's body needs a `connector_uuid` and `url` that exist only in the account, so the developer picks the connector in the same form they paste the prompt into. The sheet names it (`Connectors: keep …`); nothing here can verify it was kept.
- **The channel must exist.** `check-slack-channel.sh <repo-name>` probes `dev-<repo>`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>
```

- **On a public repository, Issue and Pull request permissions must be `Collaborators only`.** This is the precondition of the whole loop, not a hardening step: a routine fires on an Issue and a merged pull request, and the **body of each becomes an unattended agent's instructions** — a session holding Bash, Write and a Slack connector. Without it, anyone on the internet can write into that input. The `issues.assigned` trigger already means a maintainer must assign before `[Propose]` runs, so the two together bound the injection surface to people inside the repository. Nothing here can verify the setting; the sheet states it, and a public repository that has not set it should not have these routines.

**"Cannot check" is never reported as "does not exist", and that distinction is the reason the script exists.** On a locked qfs credential store, an existing channel and a nonexistent one return the *identical* `slack_auth` error — so a naive "did the read succeed?" test marks every channel missing and sends a developer to create channels that are already there. Only a probe that actually reached Slack may set `exists`; everything else is `checked: false` with a named reason (`no_qfs`, `slack_locked`, `slack_not_connected`).

That failure class has already cost this project twice: a survey concluded "no routines are installed" from an empty crontab, on a machine whose routines run in the cloud. Absence of evidence is not evidence of absence.

### What the command does with all this

Render the sheets, report the two preconditions, and say plainly what cannot be verified from here. There is no mutation to confirm and no account to survey: the developer creates the routine in their own browser from the sheet, and whether they did is observable only through what the routine produces.

