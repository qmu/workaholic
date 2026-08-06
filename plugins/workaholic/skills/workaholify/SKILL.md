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

The canonical hook is `bootstrap/session-start.sh` — the plugin holds it, the repository installs it, the same shape as the routine templates below. **It also provisions `gh`** (2026-08-06): the web container ships none, and fourteen plugin scripts shell out to it — `publish-tree-pr.sh` pushes the branch and then reports `no_gh` instead of opening the pull request, and `merge-pr.sh` cannot run at all, so every cloud `auto` unit was demoted to the PR path and every routine-published artifact waited for a human. The step is guarded on `command -v gh` (an already-provisioned container pays nothing), needs root, and is **non-fatal in every branch** — `gh` still absent afterwards is the status quo, not a regression, so the hook logs one legible line and session start still succeeds. `matches_canonical` compares the installed copy byte-for-byte, so an older copy is reported as drift rather than passing because a file exists at the path. The hook's already-installed fast path is **version-gated, not presence-gated** (2026-08-04): a cloud container image bakes a marketplace clone in, so "installed" can mean a version several releases behind the checkout, and skipping on presence made that permanent — the stale copy's retired mission migration dirtied the tree on every prompt and aborted every hourly drive tick. The skip now requires the installed version to match the checkout's `.claude-plugin/marketplace.json`; anything else refreshes the marketplace and runs `plugin update` (or `install`).

**Every problem is named separately** (`hook_missing`, `hook_stale`, `not_registered`, `matcher`, `timeout`, `enabled_plugin`, `marketplace`) because they need different fixes. Two are worth knowing on sight: `SessionStart` also fires on `resume`, `clear` and `compact`, so the matcher must be `startup`; and a marketplace clone plus install can exceed the default timeout, so it is set to 120.

The hook's own corrections (qmu/workaholic#126) are recorded in its header — it fails open by design, status-checks each step rather than wrapping them in a `{ … } || echo FAILED` group that silently reported success on total failure, drops the invalid `marketplace add --scope user`, and is idempotent.

## 5. Scheduled routines

Routines are how a project actually runs, and there are **three** templates: a `[Propose]` routine (template id `fb`; named `[FB]` until 2026-08-04) turns a Slack-reported issue into a record and, when its judgment warrants it, the work that record asks for — both in one PR — a `[Consent]` routine (id `merged-pr`; named `Merged PR` until the same ruling) announces a merge — the approval, in this workflow — and a `[Drive]` routine runs the queue on a schedule. Only the last of the three is reachable by any trigger the API actually offers, which is measured below and is not a detail of the wiring. A fourth, `[Propose Batch]`, existed for part of 2026-08-04 and was retired the same day: proposing belongs in the session that receives the ask, not in a sweep over what has already merged (`docs/proposal-loop-runbook.md` §7). Wiring them up is part of *"wire this repository to the standards"*, which is why it lives here and not in a second setup command — the second setup command is the one nobody runs.

**These are Claude Code Web routines, not cron jobs.** Each one is a scheduled or externally invoked cloud session with its own checkout, reached through the `RemoteTrigger` tool (`list` / `get` / `create` / `update` / `run`) — and *invoked* is literal, not a synonym for event-driven; see *What a routine can be triggered by* below. There is deliberately no local scheduler in this picture, and no crontab: a machine's crontab would be invisible to everyone but its owner, which is the problem this replaces rather than a mechanism to copy.

### One set of templates, many repositories

The templates live in **this skill** (`routines/*.md`), not in any repository's `.workaholic/`. That is the whole shape of the thing. Measured across the live account when this was written: the `[FB]` prompt is byte-identical across seven repositories, and so is `Merged PR` — what differs is only which repository the routine points at. A per-repository declaration would be one copy per repo of a file that is identical everywhere except its own URL, each copy free to drift, and none of them the source of truth (the routine itself lives in the cloud account, and `list` reads it back).

| Template | Trigger | What it does |
| -------- | ------- | ------------ |
| `fb` | github-issue-assigned | An issue assigned to the developer becomes a `/fb` record and a PR |
| `merged-pr` | invoked | A merge is announced to `dev-<repo>` |
| `drive` | github-pr-merged | A merged proposal starts the unattended drive runner (still a pilot) |

#### What a routine can be triggered by — and what "event" actually means (measured 2026-08-05)

**A routine cannot subscribe to a repository event.** Read back over the whole live account (`RemoteTrigger list`, 20 routines), a routine record's entire trigger surface is three fields and nothing else:

| Field | What fires the routine |
| ----- | ---------------------- |
| `cron_expression` | a recurring schedule |
| `run_once_at` | one scheduled time |
| `api_token_hint` / `api_token_created_at` | **an external caller** POSTing `/v1/code/triggers/<id>/run` with that token |

There is **no event-subscription field of any kind** — nothing naming a pull request, a merge, a push, a repository or a webhook. So `trigger: event` in a template never meant "this routine watches an event": the wiring that starts an unscheduled routine lives **outside the record**, in the GitHub integration, and the record cannot be read for it. A template's `trigger:` therefore states the **designed** trigger for the drift report and the reader — `github-issue-assigned` for `[Propose]` — not a field the API stores.

**What invokes them is now stated by the developer, and it is neither a clock nor a merge** (2026-08-06): **`[Propose]` fires when a GitHub issue assigned to the developer is opened.** That is the whole design; the wiring lives in the GitHub integration, outside the routine record. Two prior readings of the account got this wrong in opposite directions, and both failed the same way — by treating the record as able to answer a question it does not carry. First an absent `last_fired_at` was read as "never fired" (retracted: a web session did the `[Propose]` job for issue #260 → PR #261 on 2026-08-05 with the key absent throughout — the field cannot distinguish "never ran" from "ran ten minutes ago"). Then the absent event field was read as "no event path exists". Neither field answers it; the design does.

**A `[Propose]` routine observed firing on a merged pull request is misconfigured.** The merge is `[Consent]`'s event, and one event has one owner. Repairing a live routine's trigger is a **human act in the routines UI**: the trigger wiring is invisible to `RemoteTrigger list` and unreachable by it, so neither the drift report nor `/setup-routines` can see or fix it — they cover the prompt, model, schedule, `enabled` and the Slack connector, and the trigger only through the template's declared intent.

**The consequence for scheduling** (settled 2026-08-06): `[Drive]` is merge-triggered — the developer's original ask, implementable all along through the same UI wiring that fires `[Propose]` on an assigned issue. The clock argument this paragraph used to make (handoff resumption, lapsed claims and `/ticket`-written backlog have no merge event) is answered by the survey itself: every merge-started run offers *everything* claimable, so the leftovers ride the next merge rather than a timer. A machine-local cron remains available as the fallback shape (`docs/drive-loop-runbook.md`), and is a developer's act to stand up.

Everything below a template's `## Prompt` heading is the routine's prompt, verbatim. Three substitutions, each demanded by the live routines: `{repo}` (full URL, for the `…/pull/123` links), `{repo_slug}` (`org/repo`, how the Drive prompt names the repository in prose), and `{repo_name}` (bare name, the routine's own name and the `dev-<name>` Slack channel). **Anything else that differs between two repositories' routines is drift, not configuration.**

All three accept the repository URL in **any of its spellings** — `https://github.com/owner/name`, `git@github.com:owner/name`, `ssh://git@github.com/owner/name`, each ± `.git` and a trailing slash — and render identically. `{repo}` specifically renders the **https** form, because it becomes a link a person clicks and a value a *created* routine carries into a live standing process; an SSH spelling left raw would render `git@github.com:owner/name/pull/123` and make every routine read as prompt-drifted. A URL that already carries a scheme is passed through untouched, so a proxied `http://…` remote is never rewritten.

Keeping the prompt as readable markdown rather than an embedded JSON string is deliberate: the prompt *is* the routine, template freshness is the entire point of the issue behind this, and a prompt nobody can read in a diff is a prompt nobody will keep current.

**A red failure alert is deduped by reading the channel; an event announcement never is** (added 2026-08-04; the full rule moved here from `routines/drive.md` §0a on 2026-08-05, so the template points at it rather than carrying it). A repeated alert with no new information trains the operator to ignore alerts, and the hourly runner produced one near-identical red post per hour for two days from a single root cause (a stale baked-in plugin install), not one repeat carrying anything the first had not. Each tick is a fresh container, so no local state survives — but the **Slack channel itself** does, and the routine already reads and writes it, so the throttle is a read-before-post rule rather than a stored counter.

**The failure signature** is the precondition or step that failed plus its one-line reason class — `plugin-not-loaded: workaholic absent`, `dirty-tree: uncommitted changes on main`. It must be **stable across ticks**: never a SHA, a timestamp, a file count, a branch name or any other varying detail, or every repeat reads as a change and nothing is ever suppressed. Before posting a red alert, read the channel's recent history (~50 messages), find the most recent red alert from that routine, and suppress **only** when it carries the same signature inside a 24-hour cool-down — a changed signature posts immediately, and a condition recurring after the cool-down posts again. The rule suppresses repeats, never first reports. A suppressed tick **names the suppression in its own terminal report** (`alert suppressed as duplicate - <signature>`), so a quiet-because-healthy tick and a quiet-because-known-repeat tick are distinguishable from the session log alone. It **fails toward alerting**: an unreadable history posts the alert, because silence must never be produced by a failure of the mechanism that decides to be silent.

**A suppressed tick replies in the alert's thread; it does not go silent** (added 2026-08-05). The rule above was written against a failure that *repeated* — one near-identical red post per hour for two days — and it did not anticipate one that **persists through the whole cool-down**. Measured 2026-08-05: the hourly `[Drive]` routine fired at 11:56, 12:56, 13:56 and 14:56 JST with two claimable tickets queued and produced nothing — no claim, no post, no pull request — because every tick stopped at the superseded-plugin gate whose alert had been posted once at 08:01. The channel was indistinguishable from a working fleet with nothing to do, and it was noticed only because a developer asked what was running. A monitoring signal that cannot tell *healthy* from *broken and already reported* is not a monitoring signal (`workaholic:implementation` / `observability`).

So while a signature is suppressed, the tick posts **one line as a threaded reply on the existing alert**, carrying what has actually changed — that the condition is still present, when it was first reported, and how many ticks have hit it:

```
↳ still failing - `<signature>`, first reported <time>, <N> ticks
```

**The ordering is the part a later edit will get wrong, so read it exactly.** The cool-down suppresses the **top-level** post and nothing else; the threaded reply is what *replaces* that post, never a substitute for either of the two cases that still post a root. A **changed** signature posts a new root immediately, and the **first** report of any signature is always a root. And the fail-open direction is unchanged: an unreadable channel history posts the alert as a **root**, because silence must never be produced by a failure of the mechanism that decides to be silent. A reply that cannot be posted is not an error — Slack is never load-bearing here either.

**Every suppressed tick replies; the reply is not itself rate-limited** (decided, with the alternative named). The reply's entire job is to answer *is this still happening*, and only a fresh reply answers it — a rate-limited one reintroduces one level down the exact ambiguity the top-level suppression created, where a missing line means either "suppressed" or "the fleet is dead". Because the line carries elapsed time and a tick count, each reply carries information the previous one did not, which is what distinguishes it from the repeat the dedup rule exists to remove. The cost is bounded and local: a thread an operator opens deliberately, rather than a channel line everyone scrolls past, and it ends the moment the condition does. An exponential backoff (reply on the 1st, 2nd, 4th, 8th tick) was considered and rejected for making "no reply this tick" ambiguous again while being harder to state and to check.

The orange/green/yellow/purple/rocket posts announce events the session itself produced and are new every time; deduping those would hide real work.

**The shapes of the runner's posts**, so a template names its postable events without restating how each line looks. `<@U…>` follows the mention rule below; `{repo_name}` and `{repo}` are the routine's own substitutions.

```
🟢 Proposed to <@U…> - [#123 [Proposal] Issue Title]({repo}/pull/123)
One sentence, max 40 words, what the ask is — and, when the PR carries work, what it proposes.
`fb:<stem>` · <session URL>

🔴 drive blocked - `<signature>`
One sentence, max 25 words, what failed and what a human must do.

🟠 drive started - `<unit-id>`
`<branch>`, one sentence, max 25 words, what this unit contains only.

🟢 Merge Requested for <@U…> - [#123 Issue Title]({repo}/pull/123)
`from-branch` → `to-branch`, one sentence, max 40 words, what the PR does only.
<session URL>

🟡 Handoff <@U…> - [#123 Issue Title]({repo}/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>
```

**🟢 Proposed is the `[Propose]` routine's thread root** — its `` `fb:<stem>` `` line is the key every later reply searches for, so it is never dropped. The root announces only the pull request you just created in this session, exactly once — post nothing if you created none, and never announce another session's work. A merge uses the 🟢 Merge-Requested shape with its line swapped for the actor: **🚀 Auto Merge by Claude** when the unit's recorded `merge_policy` was `auto` and `/ship` merged it, **🟣 Merged by `<@U…>`** when a human merged it during the run. That distinction is the point — a developer scanning the thread must be able to tell what merged without approval from what a person approved — and it is why the auto line names no person.

### One thread per feedback item — the notification model (decided 2026-08-04)

**The unit of a notification is the reader's item of interest, not the emitter's step** (`workaholic:design` / UX). Until this date each routine posted its own top-level line — "🟢 PR opened", "🟣 PR merged" — so following one feedback item from ask to merge meant reassembling it from posts scattered across the channel, each threading to nothing. The replacement: **one Slack thread per feedback item, carrying its whole life.** The `[Propose]` routine posts the root; every later event of that item — the merge, and any `/drive` outcome for work that traces back to it — is an **in-thread reply**. All three templates implement this model; it is stated here once and referenced, never restated per template.

**The key is the feedback record's filename stem**, embedded verbatim in the thread root as `` `fb:<stem>` `` (for example `` `fb:20260804101847-make-workaholify-record-the-fb-to-merge-lifecycle-as-one-semantic-slack-thread` ``). That identifier was chosen over the GitHub issue number because it is the one that **lives in the repository**: a mission carries `feedback: [<filename>]`, a record carries `supersedes`, and a publishing PR names the file in its own diff — so a later session derives the key from the artifact it is already working on rather than from a channel post it has to find first. The issue number rides the root post too, as a human pointer, but nothing keys on it.

**Finding the thread, in three ordered cases.** Take the first that applies:

1. **The session's own trigger message.** When a routine can identify the Slack message or thread that started its run, reply there. That message *is* the item's thread — a developer who asked for something in the channel is already holding the conversation the routine is about to join.
2. **The `fb:<stem>` key search.** Otherwise search the channel for the key (the Slack MCP tools every routine already loads read channel history) and reply into the thread whose root carries it.
3. **A new root carrying the same key.** Otherwise post one — never a keyless top-level line: search is eventually consistent and a miss is expected, so the fallback must leave the story reconstructable rather than orphan the event. Two roots with one key is a repairable mess; a keyless post is not attributable to anything.

**Case 1 is not reducible to case 2, which is why it is written separately** (2026-08-05). The key is minted by the very session that posts, so a message a developer wrote *before* the record existed can never carry it and the key search can never match it. On 2026-08-05 that produced two roots for one item: the developer's own thread asking for a fix, and a separate top-level announcement of the resulting PR. Case 2 remains the only answer for routine-originated items, which have no human trigger message to find — so the case was **added to** the search, never substituted for it.

**How a session identifies its trigger message is left to the session; the routine's own trigger payload is the natural source.** Where no reliable identification exists the correct outcome is case 2 — matching by recency or by message content would thread unrelated items together, which is a worse failure than a second root.

#### Which thread a `/drive` unit's posts land in (decided 2026-08-05)

**A drive run's start and finish are per-*unit*, not per-run**, and each lands in the thread of the item that unit's work traces to. Per-run was unroutable by construction: "a run started" names no single item, so there is no thread it could reply in, and the announcement fell back to a top-level line the model exists to eliminate.

**The unit resolves to its stems through one reader.** `drive/scripts/unit-feedback-stems.sh` takes the unit's artifacts — the mission's `mission.md` for a mission unit, the ticket files for a batch — and reports the deduped feedback stems behind them, through `propose/scripts/read-feedback-relation.sh`. A mission unit whose own `feedback:` is empty resolves through its queued tickets instead; a stem is the record's filename without `.md`, which is exactly the `fb:<stem>` token a root carries.

Four rules, each answering a case the resolution actually produces:

- **Several stems → post into each of their threads**, once per stem per event. A batch whose tickets trace to two records advances two items, and an item's thread is supposed to carry that item's whole life — reporting into only one of them leaves the other's story missing the work that answered it. The multiplication is bounded by relatedness: a batch is grouped conservatively, so the count is small by construction, and the deduplication in the resolver means the common case (several tickets, one record) is one thread.
- **No stem → key on `` `unit:<unit-id>` ``**, and never post keyless. Both of the unit's posts carry the same key, so the unit's own two lines still thread together. The unit id is the key rather than the pull request's `#<number>` (which is what `[Consent]` falls back to) for a mechanical reason: the start is posted at claim time, **before** any pull request exists, and a key that only the finish can compute cannot thread the pair.
- **A unit posts exactly one start and one finish per thread, and the finish's shape follows the outcome** — 🟢 merge requested, 🚀 / 🟣 for a merge, 🟡 for a handoff, 🔴 for a blocked unit. **A handoff is the finish**, not a third post: it is where that unit's run ended, and giving it a line of its own would put two terminal posts in one thread for the outcome that is already the least conclusive.
- **The merge line does not duplicate `[Consent]`'s.** `[Consent]` rule 3 already forbids re-announcing a pull request that carries a merge notification anywhere in the channel, thread or top level, so whichever posts first is the only one — no new rule, and deliberately none, since a second rule pointing the other way would make the outcome depend on which of the two ran first.

**The bot notice `claim.sh` posts is a different surface and is deliberately left alone.** It goes through `notify-slack.sh` with a bot token and no threading, and it is the CLI-side signal that a claim landed — it is not the threaded start post and must not be grown into one. The threaded posts are the session's, made through the Slack connector the routine already loads, which is the only surface that can search for `fb:<stem>` and reply into a thread. Both are non-load-bearing; a repository with neither wired runs identically.

**Every post carries its session URL** — the Claude Code Web session that did the work, the same URL the harness gives the session for its `Claude-Session:` commit trailer. It is what turns "merged by Claude" into something a developer can audit. If the URL is not discoverable in a given session, **post without it**; a notification missing one line beats a notification that did not happen.

This model governs **what a post says and where it lands, and nothing else** — it changes no survey, no claim, and nothing `/drive` picks or implements.

### Naming a person means mentioning them (decided 2026-08-05)

**A post that names a developer resolves them to a Slack user id and writes the mention token `<@U…>`.** Plain `@name` is inert text: Slack notifies on the token and on nothing else, so five message formats across the three templates appeared to call someone out while pinging nobody. A notification's job is to reach the person it names (`workaholic:design` / UX); one that names them without reaching them is a notification that did not happen.

**How a session resolves it.** Look the person up through the Slack connector the routine already loads — `slack_search_users` on the identity the session has in hand, `slack_read_user_profile` to confirm the match — and write the resulting `<@U…>` where the format shows it. **Email is the reliable key**; a GitHub login is *not* a Slack handle and must not be passed off as one, so when a session holds only a login it resolves the person through the email git records for them (the merge or claim commit's author) and searches on that. A display-name search is the last resort, and a match it cannot confirm is not a match.

**The fallback is non-blocking, with the same precedence the session-URL rule already sets.** When the id cannot be resolved, **post the line with the plain name** rather than not posting: a missing ping costs a nudge, a missing post costs the event. Nothing about resolution may block, delay, or retry-loop a post.

Which identity each routine starts from: `[Consent]` and `[Drive]`'s merge lines hold the **merging** user, `[Propose]` holds the repository's developer, and `[Drive]`'s handoff line names **whoever the unit is handed to**. The `🚀 Auto Merge by Claude` line names no person and carries no token.

Stated once here; the templates carry the token in their formats and point back at this rule rather than restating it.

### Slack is the only surface, and an event earns its post (decided 2026-08-04)

**One surface.** A routine notifies through the repository's `dev-<repo_name>` Slack channel and nowhere else. Every template says so in its own prompt, because the instruction has to reach the session that would otherwise reach for a push tool: *post to Slack only; send no mobile or push notification.*

**What a template can and cannot switch off — measured, not assumed.** A live routine record carries `name`, `trigger`, `schedule`, `target repository`, `model`, `enabled` and its MCP connections, and **no notification field of any kind** (`scripts/list-routines.sh`'s documented shape; `lib/compare_routines.py` compares prompt, model, schedule, enabled and the Slack connector — there is nothing else to compare). So the duplicate mobile push is **not** routine configuration: the half a template reaches is the session's own behavior, above; the other half is the Claude app's account-level notification for a routine session completing, which no template, script or drift report can touch. Turning that off is a **developer act in the app's own settings**, surfaced by `/setup-routines` and stated there — a truthful "cannot" beats a claimed "did", and a drift report that silently omitted the field would be the worse outcome.

**Dropping a surface narrows visibility, so the remaining one must be worth reading.** The default for an event is **silence**; it earns a post only by being something a developer must **act on or stay aware of**. Two precedents from this repository decide the hard cases, and both are reused rather than reinvented:

- **Drop the low tier by default** — the branch story keeps every concern and the PR body renders it without the `low` ones (`report/scripts/filter-low-concerns.sh`). Same move here: the session log keeps every step; the channel gets the ones that change what a developer does.
- **Dedupe a repeat by its signature** — a red failure alert is suppressed while the same failure signature persists inside its cool-down (above). Announcements of events the session itself produced are never deduped, because each is new by construction.

**The bright line, because a vague bar refills the channel.** Post: a **unit started** (a fleet that is working must be distinguishable from a dead one — per *unit*, not per run, so the line has an item's thread to land in; see *Which thread a `/drive` unit's posts land in*), a proposal **opened**, a **merge**, a **handoff**, and a **blocked-on-precondition** failure. Do not post: a survey that found nothing, a claim, a heartbeat, a ticket archived, a commit pushed, a passing test, a build, a rebuild of `outputs/`, or a tick that ran and found nothing to do — an idle tick is correctly **silent**, and silence is a report. When an event is genuinely borderline, the tie goes to silence: an unread post costs attention every time it is scrolled past, while a missing one costs a question that the session log answers.

Changing a template makes every live routine drift by construction, and **the fleet is refreshed by `/workaholify` or `/setup-routines`, one routine at a time, confirmed verbatim** — never as part of the change that edits the template. An unattended run cannot do it at all (`/drive` issues no confirmation of any kind), so a template edit and its rollout are two separate acts by design.

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
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh [name-or-url]
<RemoteTrigger list JSON> | bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/compare-routines.sh <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routines.sh <repo-url> --live <file>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/plan-routine-change.sh <create|refresh|remove> <template-id> <repo-url> --live <file> [--enable]
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/authorize-routine-change.sh --plan <file> --digest <digest>
```

**Scripts own the templates and the comparison; the command owns the API and the confirmation.** A shell script cannot call `RemoteTrigger` — only the main agent can — so the command fetches the live list and pipes it in. That split is what keeps the logic out of markdown (the Shell Script Principle) *and* testable: `compare-routines.sh` is driven against fixtures in the suite without touching anyone's account.

**`list-routines.sh` is the developer-facing reader, and `/setup-routines` is its command.** `compare-routines.sh` answers "what has drifted, fleet-wide" for whoever is maintaining the templates; `list-routines.sh` answers "what runs against *this* repository" for somebody who has never seen it before — one block per routine with its trigger, schedule, target and template status, plus the fleet's drift as a summary rather than a drop. Its per-routine `trigger` is **the template's declaration, never live wiring** — every row carries `trigger_source: "template_declared"` and the top level carries `trigger_readable: false`, because the API exposes no trigger field (*What a routine can be triggered by*); the report must say so beside the value and point at the routines UI. Its one hard rule: **`checked: false` carries no `routines` key at all.** An absent, empty, unparseable, errored or unrecognised response is *not* an empty account, and the two must never render the same — a developer told a live repository has no routines will believe it. Only a response that actually parsed as a routines list may set `checked: true`.

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

### Changing a routine: the plan, the digest, and what "remove" means

`plan-routine-change.sh` renders the exact content one change would carry and stamps it with a `confirm_digest`; `authorize-routine-change.sh` re-derives that digest and refuses anything that does not match. The command must pass through both — plan, show verbatim, confirm, authorize, then call the API with the returned `apply` block.

**What the gate actually buys, stated precisely so it is not oversold.** It cannot prove a human was present; no script an agent runs can. What it closes are the two failures a standing outward-facing process cannot survive: **substitution** (`plan_tampered` — the plan no longer hashes to its own digest, so what was read and what would be sent differ) and **batching** (`digest_mismatch` — one confirmation carries exactly one digest, so a single yes can never cover a fleet). The digest covers only what a developer verifies by eye — action, repository, name, trigger, schedule, model, `enabled`, and the whole prompt — never the account plumbing nobody reads.

**A noop is an answer and carries no digest**, so it cannot be forced through: refreshing an undrifted routine reports `no_drift` and changes nothing, and `already_exists`, `not_present`, `already_disabled` and `disabled_routine` each name what to do instead. `disabled_routine` exists because removal *is* disabling: a refresh that silently re-enabled a routine somebody switched off would undo a deliberate act, so it needs `--enable` to say that is what you mean.

**"Remove" means disable, and says so.** The API has no delete, so removal is an update setting `enabled: false`; deleting the entry is a human act at <https://claude.ai/code/routines>. A removal's plan shows the **live** prompt rather than the template's — you are switching off what is actually there, which may have drifted.

### What the command does with all this

Report the state, then **show the developer the rendered prompt and get an explicit confirmation before any `create` or `update`**. A routine is a standing, outward-facing process that will act on this repository unattended; that is the same class of commitment as `/fb` crossing a repository boundary, and it gets the same treatment — the verbatim body, confirmed, every time. `environment_id` is an account-level fact with more than one valid answer, so it is asked rather than guessed.

