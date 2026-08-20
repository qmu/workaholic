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

Returns `{file, conformant, checks:{claude_md_present, refers_workaholify_gateway}, missing:[...]}`. Every check stays a verifiable condition.

**On `conformant: false`, apply it** — `/workaholify` is the preparation command, not an audit (the developer's ruling, 2026-08-14, issue #445), and the layout half below already converges:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/apply-claude-md-reference.sh [repo-root]
```

Report the `missing` checks and the block that will be written, take **one** confirmation (the body prefixed with the project label — `gather/scripts/project-label.sh`), then apply. Returns `{file, changed, created, conformant, reason}` with `reason` in `applied | already_conformant | unwritable`.

- **A reference, never a copy.** The block points at this gateway and at the pillar `policies/`; a repository that copied a rule would carry a second source of truth that drifts the moment the plugin updates (`workaholic:development` / `policy-as-plugin`).
- **It appends; it never rewrites.** An existing `CLAUDE.md` is the repository's own document, so nothing here reorders or removes a line of it; the file is created only when absent.
- **The check is composed, never reimplemented** — conformance is read from `audit-claude-md.sh`, so the apply cannot disagree with the audit that motivated it. A conformant repository is `changed: false` and no byte moves, so the step is safe every run.
- **Report-only is a refusal's recovery path, never the ordinary outcome.** A declined confirmation, or a named refusal (`unwritable`), falls back to reporting what is missing — stated as the refusal it is.

## 3a. The `.workaholic/` layout

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/layout-doctor.sh [repo-root]
```

Read-only. `conforming: false` means the tree holds something the closed layout does not designate; each finding carries its own `remediation`. Report them, never apply them silently — the layout is the repository's, and the audit's job is to make a mismatch legible.

**The retired documentation areas.** `guides/`, `policies/` and `specs/` left the allowlist on 2026-08-13 (issue #436) because an area with no writer in the loop goes stale and then lies — in this repository all 17 substantive files still described the three-plugin architecture retired months earlier. A consuming repository updates its plugin before its tree, so it will meet the de-listed allowlist while still holding the directories, and **every later write into them is hard-blocked** (the layout gate has no opt-out). `layout-doctor.sh` classifies those three as `retired-area` and says so by name rather than as a generic undesignated directory. **What happens to the content is the owner's call, not this command's**: move what is still true into the repository's own `docs/` tree, outside `.workaholic/`, then remove the directory. This repository deleted its own; nothing imposes that answer elsewhere.

### Converging the layout

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/converge-layout.sh [repo-root]
```

The seam issue #436 closes with — *"these migrations need to be applied through `/workaholify`"* — and it exists because **the plugin updates before the tree does**. A repository takes a new plugin version and immediately meets floors written for a shape it has never had; the layout gate has no env-var opt-out, so its next ticket write is hard-blocked with a reason describing someone else's repository. Convergence is the only way out of that state.

It runs `layout-doctor.sh`, applies the mechanical migrations, runs the doctor again, and reports the delta — `{before, applied, after, decisions, rename_conversions, legacy_strategies, changed, conforming}`. Report `changed`, each entry of `decisions`, and each entry of `rename_conversions` to the operator; a converged repository produces `changed: 0`, `decisions: []`, `rename_conversions: []` and no diff at all, so it is safe to run every time.

**The line it will not cross.** It **applies** only what is mechanical and already has a single idempotent entry point — `migrate-todo-owners.sh` (`todo/<user>/` → `todo/`), `migrate-ticket-states.sh` (`abandoned/`+`icebox/` → `archive/unbranched/` with the state in frontmatter) and `migrate-renamed-areas.sh` (every `area` row of the rename registry). It **composes** those; it never reimplements one, so there is one behaviour per migration. Everything needing a judgment is **reported with the decision it needs and never guessed**: a `retired-area` finding is the owner's call about their own content (this repository deleted its own after measuring it; another repository's `guides/` may be maintained and true), and a `retired-ticket-state` that survived the migration is a fact — a name collision, an unwritable file — not something to retry.

**It stages; it never commits.** The migrations git-stage their own moves, which is their existing contract. Committing here would make an attended audit an author of history in a repository whose state it has only just learned, and every other step of this command reports rather than writes. The blocked-write condition lifts the moment the files move on disk, so staging is enough to unblock the repository; the commit is the operator's.

**The living-migration registry contract** (2026-08-14, issue #445). `converge-layout.sh` is **the one seam** a repository's tree is converged through, so it is also the **registry** every living migration must appear in. A structural change to `.workaholic/`'s shape ships, **in the same commit**:

1. its idempotent migration, named `gather/scripts/migrate-<what>.sh`, and
2. its registration in `converge-layout.sh` — composed, never reimplemented.

This mirrors the closed-layout rule's two-lockstep-sources pattern (`rules/workaholic.md`), and for the same reason: the failure it prevents is silent. An unregistered migration leaves consuming repositories on a shape the plugin misreads while `/workaholify` calls them conformant — exactly what happened to the per-user ticket queue and the retired ticket-state directories (issues #444, #445). So the obligation is **mechanically checked**, not merely stated: `scripts/test-workflow-scripts.mjs` walks every `gather/scripts/migrate-*.sh` and fails the suite unless each is either invoked by `converge-layout.sh` or carried in that check's explicit exclusion list **with a reason**. The exclusion list is empty today, deliberately — a migration that must not run at converge is a real case (one needing a judgment, or one whose target area is live), and it is written down rather than inferred. A retired migration is **deleted**, never excluded (the erased `migrate-strategies.sh` is the precedent).

The contract obliges **registration, not application**: a migration needing a judgment still belongs in the REPORTED class above, named with the decision it needs.

### The rename registry

A rename used to cost a manual sweep plus a note somebody had to remember, and a repository still holding the old name met a floor written for a shape it had never had — told only that its directory was *not in the canonical allowlist*, which is the least useful true sentence available. A rename now costs **one row** in `gather/scripts/renames.tsv`, read through its one reader `list-renames.sh`, and everything below follows from that row.

**Two kinds, and the line between them is the whole design.**

| Kind | What it names | What happens |
| ---- | ------------- | ------------ |
| `area` | a `.workaholic/` top-level directory | **Applied.** `migrate-renamed-areas.sh` `git mv`s it and rewrites the generated root index's links. A machine-owned path has exactly one correct destination. |
| `name` | a token (`workaholic:report`, `/report`) | **Proposed, never applied.** `rename-conversions.sh` counts the survivors and prints one bulk conversion command per row; the operator runs it or declines. |

A name lives in prose a human wrote, in code comments, and in a consuming repository's own documents, where the vocabulary may deliberately differ. Rewriting those is the judgment this command reports rather than makes — the same line the `retired-area` class draws, on the other axis. `report` is also an ordinary English word, which is what a blind conversion gets wrong.

**A retirement is not a rename.** `guides/`, `policies/` and `specs/` were deleted; their content had no destination. A row with an empty `new` would make that column's meaning conditional and give the migration a second behaviour inside one kind, so `layout-doctor.sh` keeps its distinct `retired-area` classification for those three — a fixed historical fact about three names, not a list that grows.

**The table is a migration record, not history.** A row is deleted once the fleet has cut over, exactly as `renamed_from:` is deleted from a routine template. `rename-conversions.sh` returning an empty list for a row is the signal that it has: the rename is finished everywhere this command can see, and git history remains the durable record of what the thing used to be called.

**Two changes need no migration at all**, and saying so is part of the report: the feedback `subject:` floor applies to **new writes only** (the stream is immutable and history is grandfathered), and an absent `strategies/` area is the correct state, not a gap — a strategy is operator-authored. A repository still holding the **legacy nested** `strategies/<area>/<slug>/strategy.md` shape is reported as `legacy_strategies: true` and **never converted**: the migration that used to fold it away was retired with the artifact's revival, deliberately, because an erasing living migration and a live artifact area cannot share a directory.

## 4. The web bootstrap

Claude Code on the web starts each session in a fresh container where `enabledPlugins` installs nothing, so without `.claude/hooks/session-start.sh` (canonical copy: this skill's `bootstrap/session-start.sh`) plus its `SessionStart` entry, every cloud routine stops at its own "the workaholic plugin must be loaded" precondition — firing on time, doing nothing, and reading as healthy. A local session keeps a persistent `~/.claude`, so this is a no-op outside the web.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-bootstrap.sh [repo-root]
```

Every problem is named separately — `hook_missing`, `hook_stale`, `not_registered`, `matcher`, `timeout`, `enabled_plugin`, `marketplace` — because each needs a different fix.

**Then apply those fixes** (2026-08-14, issue #445 — the same ruling as §3: running the preparation command leaves the repository prepared):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/apply-bootstrap.sh [repo-root]
```

Report the `problems`, take **one** confirmation (project-label prefixed), then apply. Returns `{changed, applied:[...], refused, ok, problems_before, problems_after}`; each entry of `applied` is a problem id, so the repair is legible against the check that named it.

- **One repair per named problem, mapped one-to-one**: `hook_missing`/`hook_stale` install or refresh the canonical `bootstrap/session-start.sh` copy; `not_registered` adds the `SessionStart` entry; `matcher` corrects it to `startup`; `timeout` raises it to 120; `enabled_plugin` and `marketplace` add the two settings keys. A hook that `matches_canonical` reports no problem and is therefore **never touched**.
- **It refuses rather than half-writes.** Settings are read and rewritten through `python3` from the parsed object (parse-don't-regex — a `SessionStart` entry nests several ways). An existing `.claude/settings.json` that does not parse is `refused: settings_unparseable` with **nothing written at all, the hook included**: a hook installed but unregistered is a state this run would have created, worse than the one it found. `hook_source_missing` and `unwritable` refuse the same way. A refusal's recovery path is the report.
- **It corrects the existing entry rather than appending a second** — two `SessionStart` groups would run the bootstrap twice per session and disagree about the matcher — and every unrelated settings key survives untouched.
- **Idempotent**: a bootstrapped repository is `changed: false, applied: []` and no byte moves.

Caveats (live rules; mechanics and history in [reference/bootstrap.md](reference/bootstrap.md)):

- The already-installed fast path is version-gated, never presence-gated (a baked-in stale install is refreshed with `plugin update`, not skipped on presence).
- The hook also provisions `gh` — guarded on `command -v gh`, non-fatal in every branch (the web container ships none, and fourteen plugin scripts need it).
- The hook also gives the session the developer's git identity: it resolves the session's GitHub login (`gh api user`) through the committed repo-root `.claude/git-identities` mapping (`<login>=<email>`, one per line, `#` comments tolerated) and sets the repo-local `user.email` plus, when the **repo-local** `user.name` is unset, `user.name` from the account's real name (`gh api user --jq .name`, falling back to the login) — **only** when the current email is empty or an `@anthropic.com` default; a real local identity is never overwritten, and an absent mapping file is the status quo, not an error. The name half read the *effective* scope until 2026-08-18 (issue #506), so a container's global `Claude` kept it from ever firing and GitHub rendered every routine commit as Claude's; the repair is forward-only. Without it, ownership keys on `git config user.email`, so the developer's own `[Implement]` routine cannot claim tickets assigned to them (measured 2026-08-07: `ticket_owner_mismatch` on the developer's own proposal).
- The `SessionStart` matcher must be `startup` (the event also fires on `resume`/`clear`/`compact`); the timeout is 120 (a marketplace clone can exceed the default). The hook is POSIX `sh` with no `set -e` (it must never block session start), idempotent, and fails open; `matches_canonical` compares byte-for-byte, so an older installed copy reports as drift.
- **A hook-registered install is a different question from a bound one.** This section makes the `SessionStart` hook correct and idempotent; it says nothing about whether that install's commands/skills/hooks are actually live for the rest of the session. They may not be — Claude Code exposes no supported way to make a SessionStart-time install effective without a human typing `/reload-plugins`. `workaholic:check-deps`'s `unbound_in_claude_session` field is the legibility answer, and `/drive` warns and continues on it rather than terminating (2026-08-10, ticket `20260810090005`): the plugin's own scripts stay directly runnable via `bash` from the checkout path, and the safety hooks stay active, independent of that binding — the general form of this fallback is stated once in `plugins/workaholic/rules/general.md` ("An unbound skill surface is not, by itself, a reason to stop"), so a future unattended entry point does not have to re-learn it from a live correction; see CLAUDE.md's `/workaholify` row for the full account.

## 5. Scheduled routines

Routines are Claude Code Web routines (scheduled or externally invoked cloud sessions), never cron — where "never cron" names the *mechanism* (a routine, not a machine-local crontab), not "never scheduled": both `[Specificate]` and `[Implement]` fire hourly on distinct, non-zero minutes (FB `20260810085032`/issue #336, ticket `20260810085347`, 2026-08-10 — the developer's explicit ask covers both routines; a first pass of this ticket kept `[Specificate]` on its GitHub trigger over the *ask in hand* conflict below, corrected live on the same day's PR; the original `0,30 * * * *` value was itself rejected by the API — see *What a routine can be triggered by*). The plugin holds six templates in this skill's `routines/` — two `developer`-scoped, three `repository`-scoped and one `user`-scoped (2026-08-19, issue #526) — each a short developer-owned prompt (the command, the load fallback, and the post formats it authorizes — Q2; `[Implement]` names its finish line, `[Specificate]` names its finish line plus the description root that line replies into when the thread lookup finds nothing), applied to whichever repository the command runs in — no per-repository routine file exists: `fb` (`[Specificate]` — an issue assigned to the developer becomes a `/fb` record and a PR; now firing hourly at `:15` rather than on assignment — see *What a routine can be triggered by* for what this costs) and `implement` (`[Implement]` — the unattended executor, now firing hourly at `:30` rather than on a proposal's merge). The *developer* set stays at two, because a developer configures these by hand and every field multiplies by the number of projects (P3); the other scopes exist precisely so the rest do not multiply that way — `repository` once per repository, `user` once per account. `[Consent]`, the merge announcement, was retired 2026-08-06 at a stated cost: a human-merged pull request is now announced by nobody, and nothing has reintroduced a routine to recover it — the templates added since answer different asks, not that one.

#### Three scopes, three commands

**A routine template declares its own `scope:`, and the scope decides which command configures it** (2026-08-14, issue #451 — the developer's instruction). Three values since 2026-08-19 (issue #526), and the distinction is *how many copies of this routine should end up existing*:

| `scope:` | Copies that should exist | Configured by |
| -------- | ------------------------ | ------------- |
| `developer` | one per developer **per repository** — each fires on its own tick and the data decides whose work it is | `/setup-dev-routines` |
| `repository` | exactly **one per repository**, created by a designated person or a project/service account | `/setup-repo-routines` |
| `user` | exactly **one per account**, across every repository that account has set up | `/setup-user-routines` |

**`user` is a third value, not a rename of `developer`**, and the third command follows from the counting rather than from taste: `developer` multiplies by developers **and** by repositories, `user` multiplies by neither. Widening `/setup-dev-routines` to cover both would give one command two jobs (against *One behaviour per command*) and, run in a second repository, would re-converge an account-wide routine the first repository's run already created — leaving its report unable to answer the one question the scope field exists to answer. The cost is one more setup step, paid once per account rather than once per repository, and the sheet's own header says so before the reader repeats it.

The field lives on the **template**, not in either command's body, for the same reason the template set is discovered by scanning the directory rather than enumerated in code: two commands each carrying their own list of ids is one list written twice, and the drift between them would be invisible exactly the way live-routine drift was. `list-routine-templates.sh [<scope>]` and `render-setup-sheet.sh <id|--all> <repo-url> [<scope>]` both filter on it, so a command, its diff and its recovery sheet cannot disagree about which routines are in scope.

**The repository scope is a convention this plugin cannot enforce, and says so.** A routine is an *account-level* record; no account can list another's, so nothing here can detect — let alone refuse — the failure the scope exists to prevent: N members each converging the repository's single routine, N copies firing every hour. There is no ownership signal to check against and no authorization mechanism the API could carry, so `/setup-repo-routines` states the convention in its own body and reports precisely which routines it converged, by name. A second person who runs it anyway sees their duplicate in their own report. Inventing a gate that looked stronger than that would be the aspirational guarantee this repository refuses elsewhere.

**The repository scope holds two routines, and which two has moved twice** (2026-08-19). It was `[Prepare Release]` + `[Standup]`; `[Prepare Release]` is **retired** — its two reads are now steps 8 and 9 of the maintenance tick, and its `📦` post was not carried over — so the scope is `[Moderate]` + `[Standup]`. The count is **stated in the sheet's own header** by `render-setup-sheet.sh` rather than left to be discovered by scrolling: the whole premise of the scope is that one account carries every routine in it, so a designated person who creates the first and stops leaves the repository half-configured with nothing to say so. The per-developer burden is unchanged at two, which is the argument the scope was introduced with. **`[Moderate]` is the scope's one writer**, and that was a decision rather than a drift: the reader-only property that made `[Prepare Release]` safe to run hourly could not survive the merge into a tick that files tickets, so it is carried by the release steps' own contract (they read and report) instead of by the template's tool list.

**`/setup-routines` is removed, not aliased** (same change). One behaviour per command holds: these are two commands with two jobs, not one command switching on its first argument — and an alias that silently converged only the developer half would be worse than a name that is plainly gone. A runbook still naming the old command fails visibly on a command that does not exist, which is the recoverable failure; the rename is stated in the Release Note and in this repository's `CLAUDE.md`/`README.md` command roster.

A template is a thin pointer, not a procedure: a prompt carries only what the plugin cannot know — the environment, the payload, the one command, and the channel and post shape — and defers everything else to its owner (the run to `workaholic:drive`, the notification rules to `workaholic:notify`, the standing prohibitions to `rules/`); a prompt that restates a rule is a second source of truth, and the drift is one-directional. Prompts are byte-identical across repositories (P7): no substitution, no repository name; `{repo_name}` survives only in the `name:` UI field. Changing a template makes every live routine drift by construction; the fleet is refreshed one routine at a time, confirmed verbatim — never as part of the change that edits the template.

#### What a routine can be triggered by

A routine fires three ways — a schedule, an API call, or a GitHub event. The GitHub wiring is configurable only in the web UI: the API record carries no event field, so it is unreadable, unwritable and unverifiable from a session (a template's `trigger:` states the designed trigger, not a stored field), and `last_fired_at` is absent for GitHub-triggered fires, so no claim may rest on it — look at what the routine produced. A schedule trigger's `cron_expression` **is** a genuine field on a routine record, but re-verified against this session's actual tool surface (ticket `20260810085351`, 2026-08-10): no `RemoteTrigger`-family tool is exposed to the *unattended, routine-fired* session class at all — `CronCreate`/`CronList`/`CronDelete` are a *different*, session-only, in-memory mechanism, unrelated to account routines — so for that class a schedule trigger is exactly as unset-from-a-session as a GitHub one (an interactive session can differ — see *Direct-apply when `RemoteTrigger` is exposed* below). A separate attended session (ticket `20260810104620`) found `RemoteTrigger` present on its own tool surface, and both live routine records had already drifted from their designed wiring (empty `cron_expression`, a stale prompt) — see [reference/routines.md](reference/routines.md)'s session-class scoping and its 2026-08-10 live-drift addendum for the full account. Designed wiring: both `[Specificate]` and `[Implement]` fire hourly, on the developer's explicit ask — `[Specificate]` at `:15` (`15 * * * *`), `[Implement]` at `:30` (`30 * * * *`); a shared `0,30 * * * *` was tried first and rejected by the API (`cron interval too short`, measured 2026-08-10 — the minimum realizable interval is one hour, and a bare `:00` minute is silently rewritten to a server-chosen jitter minute), so the two routines now carry distinct, explicit non-zero minutes instead. The two routines accept this move on different terms, stated rather than glossed over: `[Implement]` is survey-driven, so a schedule fire loses only the merge event's instant start; `[Specificate]`'s whole design is *the ask in hand*, and a schedule fire alone carries no issue in hand — a gap first stated as an unresolved cost and then closed on the developer's instruction (2026-08-12): `/specificate` now runs its own **clock-fired discovery** (`specificate/scripts/list-inbound-issues.sh` — the open GitHub issues assigned to the session's own identity, minus those a feedback record already names, each taken as an ask through the full run), so a tick reports `nothing_in_hand` only when that inbox is genuinely empty. This is still not the swept-backlog `[Propose Batch]` design this repository already retired: that read the repository's own backlog for something to propose, while the discovery reads the inbound ask channel — the issues the retired event trigger used to hand over one at a time. Neither trigger narrows to a person (the UI offers no assignee filter): every developer's copy fires on every matching event/tick and the data decides whose work it is. Neither prompt carries a guard; both commands do their own filtering — `/implement` at its survey (`owned_by_other`), `/specificate` at its input (`not_mine`, P8), and a proposal carries the triggering issue's assignee onto every artifact it emits (P6). The check is the command's, never the prompt's. Repairing a live routine's trigger is a human act in the routines UI. Evidence and history: [reference/routines.md](reference/routines.md).

#### Configuring the routines is the job; `no_transport` is its one refusal

**`/setup-dev-routines`, `/setup-repo-routines` and `/setup-user-routines` configure the routines** — each over its own scope, each running the identical flow below. Neither is a renderer that occasionally gets to configure, and a session that succeeds must never describe its success as luck — "a tool happened to be available, so I registered them" was reported as the defect itself (issue #408, FB `20260812204800`), because it tells the developer the command's purpose is contingent when only its *reachability* is. One job, one named failure mode:

1. **Attempt the configuration.** Find the transport: `ToolSearch` for a `RemoteTrigger`-family tool (list/get/create/update/run over **account** routines). Never assume either answer — an interactive session may well carry one (FB `20260810214929`, 2026-08-10: it did, and listing this repository's routines found both with an empty `cron_expression`), and the routine-fired class genuinely carries none.
2. **Converge, one routine at a time.** For each template **of the invoking command's scope** (`list-routine-templates.sh <scope>`), list the account's routines, match by the rendered `name` (`render-routine.sh <id> <repo-url>`), and diff name/prompt/model/`cron_expression`/`autofix_on_pr_create`/`mcp` against the live record. A routine outside the command's scope is never read, diffed or touched — an out-of-scope live routine is not drift and is not this command's to report. The auto-fix flag lives at `job_config.ccr.session_context.autofix_on_pr_create` (discovered 2026-08-12 by toggling the UI option and re-reading the record; the API silently drops unknown fields, so the record read-back — never a 400 — is what confirms a write took). Where they differ, call the tool's own create/update method and report exactly which fields changed (or that the routine did not exist and was created). Where nothing differs, report that too; a silent "nothing to do" reads identically to "did not check."
3. **No transport → a named refusal, then the sheet as its recovery path.** Report `no_transport: RemoteTrigger-family tool` — naming what was looked for, so the reader can tell "this session cannot reach an account routine" from "there was nothing to do" — and *then* render `render-setup-sheet.sh --all <repo-url> <scope>` for the invoking command's own scope. The sheet's content is unchanged; what changed is its standing. It is the repair a developer performs by hand for a refusal this session reported, never the ordinary outcome of the command. **Measured, so the refusal is honest** (2026-08-12, the routine-fired class): no `RemoteTrigger`-family tool is exposed, `CronCreate`/`CronList`/`CronDelete` are a session-only in-memory scheduler that cannot touch an account routine, and the `claude` CLI exposes no routine subcommand — there is no second transport to reach for before giving up.
4. **No `AskUserQuestion`, by design, not by unattended necessity.** Converging a live routine to the developer's own already-declared template is not a judgment call with alternatives to weigh — it fails the *Recommended-label test* (`rules/interaction.md`): there is nothing to recommend against, so nothing to ask. Report the diff applied and move on; a mutation the tool itself refuses (a rejected `cron_expression`, a missing permission) is reported as a refusal like `no_transport`, never retried and never silently downgraded to the sheet. This also keeps the path safe under §*What may be applied unattended*'s stricter rule rather than contradicting it: that rule exists to keep a *routine-fired* run from mutating the very processes that drive it, and both commands are reachable only through a developer's own interactive invocation — no routine prompt names either of them, so "never performed by an unattended run" holds by construction, not by an extra gate. **This is what keeps the repository-scoped routine from configuring itself**: `[Prepare Release]` is created by a person running `/setup-repo-routines`, never by a tick.

5. **A renamed template is the one convergence a no-transport session cannot finish itself.** Matching is by rendered `name`, so a template whose `name:` moved does not rename the operator's live routine — it **creates a second** beside it, and the old one keeps firing until its owner deletes it by hand, which no other account can do for them. A template records the old name in `renamed_from:`, both setup commands state the cutover in their report, and `render-setup-sheet.sh` renders it as the sheet's first note. The field describes a migration, not a routine: it is **deleted from the template** once the fleet has cut over. **No template carries one today** (2026-08-19) — the fleet is one account, it has cut over, and all three were deleted. **The limitation is the no-transport class's, not the API's**: `update` moves a `name`, which is how `[Propose]` → `[Specificate]` was performed the same day with no duplicate and no manual step, so a session that reaches the account renames in place and owes the operator nothing. The mechanism stays documented here for the next rename that needs it.

**When two renames are a swap, the cutover is ordered** (2026-08-19, issue #526) — **and that swap is over**, so this rule binds nothing today. The record, because the trap is real and will recur: `[Propose]` became `[Specificate]` while the maintenance tick took the freed name `[Propose]`, which made the two migrations dependent — an account creating the new `[Propose]` while its old one still ran would hold **two routines with the same rendered name**, one firing `/specificate` at `:15` and one firing the tick at `:50`, which convergence could neither tell apart nor repair. Both setup commands therefore stated the **order** rather than merely "rename, do not create a second". Later the same day the tick was renamed again, to `[Moderate]`, vacating `[Propose]` for nobody: no template's `name:` is any other template's `renamed_from:` any more — indeed no template carries the field at all — `render-setup-sheet.sh` derives the ordering note from exactly that condition, and it therefore renders on no sheet. Nothing else about a swap differs from a single rename.

### The notification model lives in `workaholic:notify`

Which events earn a Slack post, the exact post shapes, the stateless reply-thread lookup (*One thread per feedback item*), which thread an `/implement` unit's posts land in, mention resolution, and the red-alert dedup are all stated once in `workaholic:notify` — the templates and every other consumer defer there, and nothing of the model is restated here.

### The scripts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routine-templates.sh [developer|repository|user]
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-routine.sh <template-id> <repo-url>
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-setup-sheet.sh <template-id|--all> <repo-url> [developer|repository|user]
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh [name-or-url]
```

`/setup-dev-routines`, `/setup-repo-routines` and `/setup-user-routines` (the first two superseding the single `/setup-routines` and its `/set-routines` synonym — the FB `20260810085032` ask, ticket `20260810085351`) **converge routine wiring directly**, each over its own scope; either manages nothing only when its session can reach no account routine at all, which it reports as `no_transport` before falling back (see *Configuring the routines is the job* above — the routine-fired class is where that refusal actually fires, as every session checked before 2026-08-10 confirmed). Either way, `render-setup-sheet.sh` (the fallback, and the direct-apply path's own source of the target state) emits, per template, the name, its scope, model, repository, the prompt verbatim, and the UI steps derived from the template's `trigger_kind`/`trigger_event`/`trigger_filters`/`cron_expression` declaration — derived, so a changed trigger cannot leave a stale procedure behind. A `--all` run narrowed to a scope that this plugin version ships no template for says so rather than rendering an empty sheet. The account-management surface (digest gate, drift and fleet reports) stays retired; the direct-apply path is not its return — it converges to the plugin's own templates on the spot, never surveys or reports drift as a standalone act, and never runs unattended ([reference/routines.md](reference/routines.md)).

### Preconditions, checked before anything is scheduled

Reported, never gates (the web bootstrap in §4 is the third, and the one without which nothing runs at all):

- The Slack connector must be attached (nothing here can verify it was kept), and the channel must exist: `bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>` probes `dev-<repo>`. "Cannot check" is never reported as "does not exist" — only a probe that actually reached Slack may set `exists`; everything else is `checked: false` with a named reason (`no_qfs`, `slack_locked`, `slack_not_connected`).
- On a public repository, Issue and Pull request permissions must be `Collaborators only`. This is the precondition of the whole loop: an Issue or pull-request body becomes an unattended agent's instructions, and this bounds that injection surface to people inside the repository. Nothing here can verify it; the sheet states it.
- The committed `.claude/git-identities` mapping must carry each developer whose tickets a routine should drive (`<login>=<email>`; §4's bootstrap hook reads it). Without their entry, a cloud session keeps the container's `noreply@anthropic.com` identity and the developer's own `[Implement]` routine cannot claim tickets assigned to them.

### What may be applied unattended

Reading (listing, rendering, reporting) is unattended-safe. Every mutation of a standing outward-facing process needs a human seeing exactly what it will be — confirmed verbatim, one routine at a time, never batched, never inferred from a report, never performed by an unattended run. An agent may not bring such a process into existence, or re-point one, without that.

### `/workaholify` converges too, and the sheet is its refusal's recovery path

**Measured 2026-08-19 on a second repository**, which is what closed this: a `/workaholify` run
rendered the five setup sheets, told the operator it could not answer whether any routine
existed, and finished — **in a session that was carrying a `RemoteTrigger` tool the whole
time**. The operator was handed paste-by-hand work for a job the session could have done, and
the report's own "what the plugin cannot answer" list was false in that session.

The 2026-08-14 ruling (issue #445) — *running the preparation command leaves the repository
prepared* — was applied to three of this skill's four subjects. `CLAUDE.md` (§3), the
`.workaholic/` layout (§3a) and the web bootstrap (§4) all **converge**. §5 alone only rendered,
because the three setup commands existed and rendering felt like the safe half. It is not the
safe half: a repository nobody finished wiring is exactly the state where routines fire on time
and do nothing, which §4 exists to prevent by the same argument.

**So `/workaholify` §5 runs *Configuring the routines is the job* above, unchanged, over every
scope** — `list-routine-templates.sh` with no scope filter — and reports per routine what it
created, what fields it updated, and what already matched. It calls no setup command: the flow
is this skill's, and the three commands are the same flow narrowed to one scope each, for a
developer who wants exactly that scope converged.

Its refusal is the same single one: `no_transport: RemoteTrigger-family tool`, and only then
`render-setup-sheet.sh --all <repo-url>` as that refusal's recovery path. **A rendered sheet is
now evidence that something was refused**, never the ordinary outcome — the same standing the
sheet has in the three setup commands.

**One thing `/workaholify` must say that the scoped commands need not**: it converges the
`repository`-scoped routines, which are the ones exactly one account should create. It cannot
detect a teammate's copy — no account can list another's — so it reports which repository-scoped
routines it converged, by name, and states that convention plainly. Running `/workaholify` in a
repository a colleague already wired is how a duplicate gets made, and the report is the only
place a person can notice.


### What the commands do with all this

Identical for `/setup-dev-routines`, `/setup-repo-routines` and `/setup-user-routines`; only the scope they pass differs. **`/workaholify` runs the same flow over every scope** — see *`/workaholify` converges too* below. Identical for `/setup-dev-routines`, `/setup-repo-routines` and `/setup-user-routines`; only the scope they pass differs. Resolve the repository first (`resolve-repo-url.sh [name-or-url]`; no argument means this checkout — when `source` is `same_org_as_checkout`, say which repository it resolved to). **Then attempt the configuration** (*Configuring the routines is the job* above) over `list-routine-templates.sh <scope>`: list/diff/apply directly and report exactly what changed per routine — no mutation is inferred from a report or batched, each is applied and stated as its own line. **Only when the attempt cannot be made**, report `no_transport: RemoteTrigger-family tool` and then render the sheets for that scope (`render-setup-sheet.sh --all <repo-url> <scope>`) as that refusal's recovery path, with the preconditions and a plain statement of what cannot be verified from here; print the prompt blocks verbatim — never summarise, re-wrap, or "clean up" a prompt: what the developer pastes is what runs, and there is no mutation to confirm because there is no account this session can reach — the developer creates the routine in their own browser from the sheet. `/setup-repo-routines` adds one more thing it cannot verify to that statement: whether somebody else on the team already created the same routine.
