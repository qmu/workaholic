# Workaholic

Private, cross-agent distribution of structured development workflows and engineering standards. **AI agents are the primary users** — routines invoking `/implement` and `/propose`, and sessions running the workflow skills — while the **developer is the operator** who approves pull requests, configures routines, and rules on deferred decisions. Richest on **Claude Code** (plugin marketplace: commands, hooks, always-on lenses); portable skills also ship to **Codex** (`.agents/plugins/marketplace.json` → `outputs/workflows`) and to 40+ agents via the Agent Skills standard / `skills` CLI. Authored source lives under `plugins/`; cross-agent artifacts are generated into `outputs/`.

This file states **current behavior only**. Decision history and rationale live in `docs/loop-engineering-workflow.md`, `docs/proposal-loop-runbook.md`, `docs/drive-loop-runbook.md`, each skill's `reference/` directory, the feedback stream (`.workaholic/feedbacks/`), and this file's own git history.

## Important

- Edit `plugins/`, not `.claude/` — this repo develops plugins; changes go to `plugins/` unless explicitly requested otherwise.
- **Update the docs in the same change.** When a change alters behavior, structure, commands, skills, or conventions, update every affected document (`README.md`, `.workaholic/README.md`, `CLAUDE.md`, `plugins/workaholic/rules/*.md`) in the same commit. Outdated documentation is a defect; `/report` runs `doc-drift.sh` and `area-freshness.sh` only as backstops.

## Project Structure

```
.claude/                 # Local Claude Code configuration (rules/)
.claude-plugin/          # Marketplace configuration (marketplace.json)
plugins/
  workaholic/            # The single plugin (no dependencies)
    .claude-plugin/      # Plugin configuration
    .codex-plugin/       # Hand-maintained Codex-facing manifest
    skills/              # Workflow skills (branching, catch, check-deps, commit, create-ticket,
                         # discover, drive, explain, feedback, gather, mission, notify, okf,
                         # propose, release-scan, report, review-sections, ship, strategy,
                         # system-safety, validate-writer-output, workaholify,
                         # write-release-note) + policy
                         # skills (planning, design, implementation, operation, safety,
                         # development; English hard copies under each skill's policies/)
    commands/            # Claude-only thin aliases (ticket, drive, implement, commit, propose,
                         # fb, report, ship, mission, mission-close, catch, explain, workaholify,
                         # setup-routines)
    hooks/               # Validation + guard hooks (see "Hooks" below) and generated policy-index.md
    rules/               # diagrams, general, interaction, shell, typescript, workaholic
scripts/
  claude.sh              # Launcher
  build-plugins/         # Generates outputs/ (argument-less run = full build)
  test-workflow-scripts.mjs  # Hermetic smoke tests
  e2e/loop-drill.sh      # Operator tooling: drill the propose-implement loop on demand
                         # (assumes the server's full gh + qfs; ships to no other agent)
outputs/                 # GENERATED, committed cross-agent artifacts — never hand-edit (CI-guarded)
  workflows/             # Self-contained portable workflows plugin (+ .codex-plugin/plugin.json)
  okf/                   # OKF v0.1 bundle of the four pillars' policies
.agents/plugins/marketplace.json  # Codex plugin list (workflows -> ./outputs/workflows)
docs/                    # Documentation (dependencies/ = dependency-decision logs)
```

### Hooks (all shipped active in hooks.json)

- `validate-ticket.sh` (PostToolUse Write|Edit) — ticket floor on the `todo/` queue only: frontmatter, location, mandatory `## Policies`/`## Quality Gate`, resolvable `mission:` relation.
- `validate-mission.sh` (PostToolUse) — Experience/≥1-acceptance floor on any mission under `missions/active/`; archive never retro-blocked.
- `validate-story.sh` / `validate-trip.sh` / `validate-feedback.sh` / `validate-strategy.sh` (PostToolUse) — OKF `type:` and schema floors on new writes; git-tracked history is grandfathered. `validate-strategy.sh` holds the revived strategy artifact to the three properties that distinguish it from the one retired in 2026-07-28: a `YYYY-MM-DD` `target_date`, a **non-empty** `assignees` (the one artifact where empty is a refusal, not team-owned), and non-empty `## Aim` / `## Schedule`.
- `guard-ticket-structure.sh` (PreToolUse Bash) — blocks non-canonical ticket moves.
- `guard-git-commit.sh` / `guard-git-branch.sh` (PreToolUse Bash) — commit-subject and branch-name gates (see below).
- `guard-askuserquestion-label.sh` (PreToolUse AskUserQuestion) — every question body must open with a `[<project label>]` prefix (`gather/scripts/project-label.sh`).
- `guard-working-directory.sh` (PreToolUse Bash) — denies a top-level cwd-moving `cd`; a `( cd … )` subshell, an absolute path, or a `--prefix` form always passes. No env-var toggle.
- `guard-repo-confinement.sh` (PreToolUse Write|Edit) — blocks writes outside this repository and its worktrees (the agent's per-project memory store is exempt). Syntactic backstop only; the primary rule lives in `rules/general.md`.
- `policy-lens.sh` (UserPromptSubmit) — injects the engineering-policy index for commands carrying the `workaholic:policy-lens` sentinel; bodies are read on demand from `skills/<pillar>/policies/`. Regenerate `hooks/policy-index.md` with `build.mjs` after editing a pillar's `## Policies` list (CI rebuilds and fails on drift).
- `mission-lens.sh` (UserPromptSubmit + Stop, non-forcing) — surfaces the active missions that pass ownership/location/signal gates, full block on roster change and a one-liner otherwise. Reads through `mission/scripts/progress.sh` / `next-acceptance.sh` and `gather/scripts/owners.sh`.
- `layout-doctor.sh [path]` — read-only audit of `.workaholic/` against the layout allowlist.

## Architecture Policy

### Component Nesting Rules

| Caller                         | Can invoke                                   | Cannot invoke              |
| ------------------------------ | -------------------------------------------- | -------------------------- |
| Command                        | Skill, `general-purpose` subagent            | —                          |
| Skill                          | Skill; (when loaded by a command/main agent) may direct it to spawn `general-purpose` subagents | Command                    |
| `general-purpose` subagent     | Skill (via preload)                          | Command, Task (no nesting) |

- **No per-workflow agent files.** The repo ships no agent `.md` files at all. A command spawns `subagent_type: "general-purpose"` subagents whose prompts name the `workaholic` skill to preload, the section, the inputs, and the return schema.
- **One-level fan-out.** A subagent cannot nest `Task` and cannot call `AskUserQuestion`; all fan-out and all user interaction happen at the command/main-agent level. Leaves do non-interactive work and return JSON.
- **One plugin.** `workaholic` has `dependencies: []`. All skill references are same-plugin (`${CLAUDE_PLUGIN_ROOT}/skills/<name>/...`, `workaholic:<name>` namespaces). The `workflows` marketplace entry is the generated `outputs/workflows` bundle, not an authored plugin.

### The ticket spine

Everything converges on the **ticket** as the unit of work: *sources* fill `tickets/todo/`, one executor drains it to `tickets/archive/`.

- **Sources**: `/ticket` (human-directed, with discovery) and `/mission`'s Creation Interrogation (which emits a mission's whole ordered ticket set). `/propose` feeds them from the feedback stream. All publish through a **publish tree** onto a `work-*` branch behind a pull request; the artifact reaches `main` — and the executor's survey — when that PR merges.
- **Mission floor and ceiling**: a mission is created with **two or more tickets** or it is not a mission (checked at the publish seam by `mission/scripts/check-floor.sh`; a ticketless direction is a feedback record, a one-ticket one is a plain ticket). The ceiling: `## Acceptance` normatively ≤3 items, whole `mission.md` ~60 lines / 2 KB — measured by `mission/scripts/size.sh`, enforced on `/propose`'s unattended drafts. Write-time floor: `## Experience` + ≥1 acceptance item.
- **One executor, two commands**: `/drive` (attended — asks exactly one thing: which units to take when several are offered) and `/implement` (unattended — no prompt at any step). Same Unified Run either way: freshen (`sync-main.sh`) → survey (`plan-units.sh`) → partition into PR-units → claim → drive → report → route by effective merge policy → account. The full contract lives in `skills/drive/SKILL.md` and its `reference/`.
- **Merge policy** (`merge_policy: auto | review`, recorded at creation on missions and tickets; **absent means review**): `auto` ships through `/ship`'s evidence-gated doctrine then tears the claim down; `review` merges its PR immediately after `/report` opens it — a release-scan finding is the one thing that leaves it open. **No gate is ever overridden** by either entry point: a `secret` finding hard-stops; a `size`/`leak` block or a missing confirmation method demotes the unit to the PR path.
- Retired predecessors (`/monitor`, `/trip`, `/carry`) and their landed ideas: `docs/loop-engineering-workflow.md` I1/I3/I5. `.workaholic/trips/` is read-only legacy history.

### `.workaholic/` runtime conventions

- **OKF floor**: every knowledge artifact carries a non-empty `type:` (`Story`, `Mission`, `Feedback`, `Strategy`, `Deployment`, `Term`, `Release Note`, `Release`); `okf/scripts/refresh-index.sh` regenerates the bundle indexes before each knowledge commit. **Tickets are the exception**: no `type:` frontmatter, and `tickets/` internals are never index-managed. `README.md` and `index.md` are the only files allowed at the `.workaholic/` root.
- **Mission rolling**: commit seams (archive, ship, report) append `## Changelog` lines and tick `## Acceptance` items via the mission skill's idempotent mutators (`append-changelog.sh` / `tick-acceptance.sh`). Progress (`checked ÷ total`) is computed, never stored. Acceptance items become tickable through their `(#<filename>)` link, stamped only by the emitting seam via `link-acceptance.sh`. The `mission:` relation is many-valued; read it only through `read-relation.sh`.
- **Strategy** (`.workaholic/strategies/<slug>.md`, revived 2026-08-13 — issue #436): the operator's **outbound, resolved direction** — an **Aim**, a **Schedule** (`target_date`), an **Assignee** (non-empty `assignees`). Flat, one file, operator-authored through `workaholic:strategy`; no command, hook or routine writes one and `/drive` never surveys it. It carries **no ticket plan** — planning executable work stays a mission's job. It is the complement of the feedback stream, not a rival inbox: `feedbacks/` holds what someone *said* (inbound, immutable), a strategy holds what the operator *decided*, and the citation link runs **one way** (strategy → feedback). The 2026-07-28 retirement (B3) stands as history and its reasoning is answered rather than dismissed — the retired artifact was open-ended `## Direction` prose with no completion condition, the revived one is bounded, owned and closable. The `strategy:` mission relation and its ownership hop did **not** return. `mission/scripts/migrate-strategies.sh` and the `missions_migrate_strategies` seam that erased `strategies/` on every mission-script touch are **retired**; do not re-add them. Full record: `skills/mission/SKILL.md`, *The strategy layer: retired, then redefined*.
- **Ticket state is a field, the archive is a place** (2026-08-13, issue #436): `tickets/` is **two-state** — `todo/` and `archive/<branch>/`, nothing else. A ticket's state is its `status:` frontmatter field: **absent means queued**, `done` (stamped by `archive.sh` at the gate), `abandoned`, `icebox`. `icebox` survives as a state distinct from `abandoned` — deferred and promotable versus decided against — and `promote-icebox.sh` **clears** the field when it returns a ticket to the queue. A ticket that was never driven lands in the synthetic `archive/unbranched/` (the archive is keyed by the branch that drove a ticket; inventing one would assert a drive that never happened). The retired `icebox/` and `abandoned/` directories are still read by every reader and accepted by the write floor while `gather/scripts/migrate-ticket-states.sh` converges them at the write seams; `layout-doctor.sh` reports a survivor as `retired-ticket-state`.
- **Ownership**: plural `assignees` on every artifact; **empty means team-owned/claimable**. One oracle resolves it — `gather/scripts/owners.sh`, with `owns.sh` returning `mine`/`unowned`/`other`/`unresolved` (compared by slug). Claim authorship and resumption key on `git config user.email` separately.
- **Mission lifecycle**: `status: active | achieved | abandoned | carried` — one in-flight state; `active/` vs `archive/` areas; `mission/scripts/close.sh` is the **only** writer of an end state. Merging the mission's PR is the approval; drivability is derived (active area + plan + queued tickets), never a status word.
- **Feedback subject** (2026-08-13, issue #436): every new record names **whose opinion it is** — `subject: <kind>[:<identity>]`, kind from the closed set `person | meeting | observer_ai | customer | team | other`, identity free text. Three axes that look alike and answer different questions: **subject** = who formed the opinion, **source** = the channel it arrived through, **author** = the git identity that ran the capture. `create.sh` takes it as the `--subject` **option** (the positional contract did not move) and **refuses** (`no_subject`) rather than default it — a routine writes most of the stream, so a default would record every opinion as the machine's. `/propose` supplies the triggering issue's author; `ship`'s extractor supplies `observer_ai:<author>`; `validate-feedback.sh` floors new writes and grandfathers everything written before the axis.
- **Deferred concerns** live in the feedback stream: the story's Concerns section is the durable record (PR body drops `low` blocks at render); `ship`'s `extract-deferred-concerns.sh` persists each as a `kind: concern` record keyed on `concern_id`; the open set is computed — a concern is open until a later record names it in `supersedes`.
- **The two hand-maintained areas** (`deployments/`, `terms/`): the ones that survived the 2026-08-13 reshape, each now carrying a **definition** (what it holds, what it never holds, who writes it, when it is refreshed — `rules/workaholic.md`) and an **upkeep seam**. The seam is `report/scripts/area-freshness.sh`, read by `/report` beside `doc-drift.sh`: it **reports, it never writes** — a deployment record describes a procedure a human authored, so a machine rewriting it from a run would record what happened rather than what should happen, and a glossary a machine maintained would define the words it already uses. Two mechanical facts per record: `retired_terms` (it still names a de-listed area or a retired namespace — wrong, not merely old) and `stale_days` (reported, thresholded by nobody, because the right interval differs per project). `/ship` stays the only live *reader* of a deployment record and gates on its `## Confirmation`. Records carry `type: Deployment` / `type: Term`; `terms/inconsistencies.md` is a term entry like any other with no special status.
- **Retired areas** (2026-08-13, issue #436): `.workaholic/policies/`, `guides/` and `specs/` are gone — the three areas with **no writer in the loop**. An area nothing writes goes stale and then lies: all 17 substantive files in them still described the retired three-plugin architecture and had not been touched since 2026-05-14. Reference documentation lives in the repository's own `docs/` tree, **outside** `.workaholic/`; the `"docs" → specs/` request mapping now points there. Content was deleted, not relocated — git history is the durable record and nothing in them was still true. A consuming repository whose plugin updates before its tree is told by name: `layout-doctor.sh` classifies those three as `retired-area`, and the content decision stays the owner's.
- **Closed layout**: the permitted top-level `.workaholic/` directories are fixed in **two lockstep sources** — `hooks/workaholic-layout-allowlist.txt` and the table in `plugins/workaholic/rules/workaholic.md`. A new artifact directory must be registered in both **in the same commit** that first writes to it; `layout-doctor.sh` audits, and the `Validate Plugins` CI workflow fails the merge on `conforming: false`.

### Claim protocol

The repository is the coordination medium; the model is stated once in `skills/drive/SKILL.md` (**Claims**) with full detail in `skills/drive/reference/claims.md`. Operational facts:

- A runner claims a PR-unit (mission slug or `batch-<ts>`) as a `Claim <unit-id>` commit on a pushed `work-*` branch; **unmerged remote branches are the only claim oracle** (`list-claims.sh`). One unit ↔ one branch ↔ one worktree (`.worktrees/<unit-id>/`) ↔ one PR.
- A merge releases a claim by definition. `release-claim.sh` explicitly discards an unfinished unit (never a recovery path). `claim.sh resume` takes over **your own** claim whose heartbeat lapsed; a colleague's is untouchable at any age. Staleness is reported, never acted on.
- The heartbeat is the branch tip (`heartbeat.sh`, empty commit built against a scratch index). `archive.sh` pushes the claim branch itself after each archive commit.
- Worktrees are **claim-born and ship-torn** (`cleanup-mission-worktree.sh` is the sanctioned cleaner; `survey-worktrees.sh` / `reap-worktrees.sh` back the teardowns up). `.worktrees/` and `.publish/` sit inside the repo root — add them to `.dockerignore` and any archiver's ignore list.
- The claim is the only creator of a branch a runner may drive. Artifact writers use the **publish tree** instead: a checkout of `origin/main` at git-ignored `.publish/` on local branch `publish-main` (`open-publish-tree.sh` → write → `publish-tree-pr.sh` (default, PR path) or `publish-tree-commit.sh` (direct, post-merge seams only) → `close-publish-tree.sh`). The caller's checkout is left byte-identical.
- The reader degrades offline; the writer fails loudly. Under `/implement`, each unit posts one finish line into its feedback item's thread (`unit-feedback-stems.sh` + `workaholic:notify`'s stateless lookup) on the transport that skill selects — **connector primary, the tokened `notify-slack.sh` the machine fallback** (keyed root only, it cannot thread); an attended `/drive` run posts nothing to Slack.

### The release tier (`release/*`)

`main` is the continuously auto-merged development branch; **quality is gated at the `release/*` QA window**, not at merge time. A release branch is cut from `main` by `branching/scripts/cut-release-branch.sh` (`release/YYYYMMDD-HHMMSS`, batch-level, explicitly invoked — never a step of the per-unit ship), carries no commits of its own, and is invisible to the claim protocol. The durable ship record is `.workaholic/releases/<release-branch>.md`, written by `ship/scripts/record-release-cut.sh` and `confirm-release.sh`, both derived from git. A promotion adds a second confirmation and never weakens the per-unit one; a failed confirmation deletes nothing — the next attempt cuts a fresh release branch. No `develop`, no `hotfix/*`; per-unit mechanics are untouched.

### Design principles

- **Thin commands, comprehensive skills.** Commands are a few lines naming the skill, section, and entry-point contract; knowledge (templates, rules, scripts) lives in skills (~50-150 lines; overflow goes to `reference/`).
- **Common operations go through skills**: git context via `gather/scripts/git-context.sh`, ticket metadata via `gather/scripts/ticket-metadata.sh` — never inline `git branch --show-current` etc. in command/agent markdown.
- **No complex inline shell** in command/subagent markdown (no conditionals, pipes, loops, text processing, defaulting expansions) — extract to a skill script.
- **`${CLAUDE_PLUGIN_ROOT}` for every skill script reference** — relative paths do not resolve at runtime.
- **Plugin boundary**: invoke skills by their loaded `workaholic:` namespace; never read global/marketplace installs on disk to *find* skill content, never guess a namespace (`drivin`, `trippin`, `core`, `standards`, `work` are obsolete). The one sanctioned crossing is `check-deps/scripts/plugin-src.sh`, which resolves the newest plugin tree on the machine (checkout, registry install path, clone, binding) so an unattended run whose binding is missing or superseded still executes the workflow instead of stopping — the harness binding is an input, never a precondition (`rules/general.md`; measured 2026-08-12, twelve `[Implement]` ticks lost to a project-scope pin the bootstrap never updated). It resolves on **two axes: newest version wins, and an equal version goes to the immutable candidate** — a version-addressed cache path cannot move under a run, whereas the checkout the freshen is about to touch can (measured 2026-08-12, a container's stale baked `main` reverted a resolved checkout 200 commits mid-run). Callers read `src_immutable` and either require it or re-resolve after a tree-moving step. If a skill is missing from context in an *attended* session, ask which plugins are loaded.

### Cross-agent exposure and generated outputs

- Script-bearing skills carry `metadata.internal: true` (hides them from the `skills` CLI; Claude Code ignores the field). Pure-prose skills (`design`/`implementation`/`operation`, `write-release-note`, `review-sections`) are intentionally exposed. Script-bearing skills keep `${CLAUDE_PLUGIN_ROOT}` and reach non-Claude agents only through the generated bundle.
- `outputs/workflows/` is the self-contained public bundle: `${CLAUDE_PLUGIN_ROOT}` rewritten relative, internal/preload metadata stripped (`publicizeSkillMd`), `reference/` directories carried with their paths rewritten. **Regenerate with argument-less `node scripts/build-plugins/build.mjs` whenever a workflow skill or its script closure changes.** `outputs/` is committed; the `Outputs Freshness` CI workflow rebuilds and fails on any diff.
- The `workflows` marketplace entry keeps **`"strict": false`** (the bundle deliberately has no `.claude-plugin/plugin.json`; do not add one). Codex reads `.agents/plugins/marketplace.json`; `hooks/hooks.json` must keep `hooks` as its only top-level key.
- `outputs/okf/` is the OKF v0.1 policy bundle generated by `okf.mjs`; consumers read it from the repo path, no manifest involved. Adoption record: `docs/dependencies/okf.md`.

## Commands

| Command | Contract |
| ------- | -------- |
| `/ticket <description>` | Write an implementation spec for this repository, recording `merge_policy` at creation, and publish it via publish tree onto a `work-*` branch behind a PR — from any branch, caller's checkout untouched, no branch of its own created. Discovery applies the **diagnosis-first rule** (`workaholic:discover`): a failure-report ask gets reproduce-and-localize steps first, the reporter's fix demoted to Considerations. Bare `/ticket` reports the queue (yours + unowned). |
| `/drive [<unit>]` | The executor, attended. Survey → partition → claim → drive → report → route → account; asks exactly once (multiSelect) which units to take when several are offered, else nothing. `<unit>` is a scope, not a mode. Never overrides a gate. |
| `/implement [<unit>]` | The executor, unattended: same run, no `AskUserQuestion` anywhere. A mid-run problem becomes a ticket; a half-driven unit ends in `handoff` (PR body's non-droppable `## Handoff`). The run report names each unit's **notification outcome** — the surface the finish line used and whether it landed; an unposted line is reported as unposted and never moves the token. Ends with the `N units: X shipped, Y PR'd, Z blocked` reconciliation and the honest terminal token (`ok` only when nothing claimable remains and the survey was current and readable) — the `/goal /implement ok` contract. |
| `/commit` | Commit working changes with a policy-conformant message (small non-ticketed changes; prefer `/drive` for ticketed work). |
| `/propose` | Judge the ask **in hand** — the argument, a record just written, or, on a clock-fired tick with nothing handed in, the **discovered inbound issues** (`list-inbound-issues.sh`: open GitHub issues assigned to the session's own identity, read through REST via `gather/scripts/gh-rest.sh` — never the GraphQL-backed `gh issue list`, which a web session may 403 — oldest-first, pull requests filtered out, minus those a feedback record already names; never unassigned issues, never a title filter; each taken through the full run). `nothing_in_hand` only when that inbox is empty too — an unreadable inbox reports its reason instead; an issue assigned to someone else is `not_mine` via `gh api user`. Writes the feedback record into a publish tree, reads base state as constraints (`survey-state.sh`), runs a history-mode discovery pass (diagnosis-first for failure reports; unrecommendable forks become `## Open Decisions`), dedups via `list-proposed-refs.sh` (including unmerged branches), and emits in one PR the record plus what the work's shape selects: a mission with ≥2 tickets, one loose ticket (mandatory `feedback:` refs), or the record alone. The PR auto-merges on opening (`WORKAHOLIC_AUTO_MERGE=1`; a scan finding leaves it open), titled `[Proposal] …` via `WORKAHOLIC_PR_TITLE`, with `Closes #<N>` when the ask carried an issue number. The triggering issue's assignee rides every artifact (`--assignee`); never the running identity. Never prompts. |
| `/fb [<content>]` | Register one immutable feedback record (`kind`: insight/instruction/concern/material/answer; `source`: meeting/slack/discussion; `subject`: **whose opinion it is** — `<kind>[:<identity>]` over the closed kind set person/meeting/observer_ai/customer/team/other, taken from the ask and **never defaulted to the runner**) via the feedback skill's `create.sh` — only for genuine feedback or something that must not be overlooked. Resolution is a new record naming the old via `supersedes`, never an edit. **Cross-repository mode** (`/fb <ask> to <owner/name>`): composes the ask in the target's vocabulary, applies the masking judgment, shows one non-skippable verbatim confirmation (destination, visibility, exact title and body), runs the secret/leak scan and the self-name backstop, and opens a **GitHub issue on the target** — the only sanctioned crossing (`/request` is retired). The issue title carries an `[FB] ` marker, stamped idempotently in one place (`feedback/scripts/fb-title.sh`, called by `open-issue.sh` and by the confirmation so the developer sees the wire string); this reverses the earlier no-prefix rule on the developer's instruction (issue #411). Abbreviated because Claude Code ships a built-in `/feedback`. |
| `/report` | Context-aware story + PR creation (warn-tier scan; `doc-drift.sh` and `area-freshness.sh` as documentation backstops). Right-sized: ≤2 archived tickets → one combined worker, no Journey; >2 → 3-worker fan-out. Identical result record and cross-document relations either way. |
| `/ship` | Context-aware: merge PR, deploy, verify — blocks pre-merge on the scan; secrets non-overridable; deploy + confirm **before** merge. |
| `/mission ["<title>" \| "<instruction>"]` | Create a mission (asks the one `merge_policy` ruling, interrogates to drive-ready, publishes mission + whole ticket set in one PR; under two tickets publishes nothing and names the alternative), **replan** an in-flight one (free-form instruction; also how a `carried` successor gets fleshed out), or show the roadmap (bare). No word of the argument is a subcommand. A direction change is answered by reorganize-and-carry: replan, then `carried` with `--successor <slug>` (appends unmet items idempotently; `--successor-title` is refused by the ticket floor). |
| `/catch [window]` | Read-only catch-up: commits/tickets/stories by developer, Missions view, Orchestration Throughput (`commit-kpi.sh`), then Q&A. |
| `/explain <question> [dir]` | Answer a repo question and export a printer-ready PDF (HTML staged in-repo at git-ignored `.explain/`, printed by a real browser; exports to `dir`, else Desktop→Home). |
| `/workaholify` | Wire the current repo to the standards: check the web bootstrap first (`check-bootstrap.sh` — cloud sessions need `.claude/hooks/session-start.sh`, version-gated, or every routine stops at its plugin precondition), audit `CLAUDE.md` (refer to the gateway skill, never copy rules), **converge the `.workaholic/` layout** (`converge-layout.sh` — runs `layout-doctor.sh`, applies the mechanical migrations (`migrate-todo-owners.sh`, `migrate-ticket-states.sh`), re-runs the doctor and reports the delta; it **stages and never commits**, and everything needing a judgment — a `retired-area`, a legacy nested `strategies/` tree — is **reported with the decision it needs, never guessed**. A converged repo produces an empty delta), survey routines, confirm the working-directory guard. |
| `/mission-close <slug> [achieved\|abandoned\|carried]` | End a mission into `missions/archive/` (archive move only; worktrees are claim-born/ship-torn). States the Mission Position Report, asks the outcome only when the argument omits it, runs `close.sh` — the only sanctioned writer of an end state. |
| `/setup-routines [repo]` | **Configures the routines** — one job with one named failure mode, never two branches. Attempts it every time through a `RemoteTrigger`-family tool: list the account's routines, diff each against its template (name/prompt/model/`cron_expression`/`autofix_on_pr_create`/connectors), apply create/update to converge, report per-routine changes; no questions, and never framed as luck. **No transport reachable** (the routine-fired class; measured — the session-only `CronCreate` family cannot touch an account routine): report `no_transport: RemoteTrigger-family tool`, then render the copy-paste setup sheets (`render-setup-sheet.sh --all`) **as that refusal's recovery path**, with the preconditions (Slack channel probe — `checked: false` is never "does not exist"; web bootstrap) and what cannot be verified. The account-management surface (digest gate, drift/fleet reports) stays retired. |

### Routines

Two Claude Code Web routines per repository, from the templates in `skills/workaholify/routines/`: **`[Propose]`** (`fb.md`, hourly `15 * * * *`) and **`[Implement]`** (`implement.md`, hourly `30 * * * *`). The API's minimum interval is one hour; a bare `:00` minute is rewritten to server jitter, so explicit non-zero minutes are used. Both declare `autofix_on_pr_create: true` (stored at `job_config.ccr.session_context.autofix_on_pr_create`). A template is a thin pointer: the prompt carries only the command, the finish-post formats, and the environment — every rule stays in the skill that owns it (`workaholic:drive`, `workaholic:notify`, `rules/`). The whole chain is drillable on demand — `scripts/e2e/loop-drill.sh` (seed / status / reset / verify-propose / verify-implement), operator tooling outside the plugin because it assumes the server's full `gh` and `qfs`; the operator procedure, the cron race windows and the failure-reason→file blame tables are `docs/loop-drill-runbook.md`. A routine cannot subscribe to a repository event (the API's trigger surface is `cron_expression` / `run_once_at` / API token only); `[Propose]`'s tick therefore discovers its own asks (the propose skill's *Clock-fired discovery*). Neither trigger narrows to a person: the data decides ownership (`owned_by_other` at `/implement`'s survey, `not_mine` at `/propose`'s input). Do not reintroduce a third routine.

## Development Workflow

1. `/ticket` — write specs (published behind a PR; merging queues them)
2. `/drive` (attended) or `/implement` (unattended) — implement each spec
3. `/report` — story + PR
4. `/ship` — merge, deploy, verify

## Type Checking

No build step required — this is a configuration/documentation project.

## Local Verification

Before pushing changes to workflow scripts or plugin manifests:

```bash
node scripts/build-plugins/build.mjs              # regenerate outputs/ AND hooks/policy-index.md
node scripts/build-plugins/verify.mjs             # assert generated skills are self-contained AND the policy index is in sync
node scripts/build-plugins/validate-metadata.mjs  # assert Codex manifests are well-formed and version-aligned
node scripts/test-workflow-scripts.mjs            # hermetic smoke tests for branching + drive scripts
bash plugins/workaholic/hooks/layout-doctor.sh .  # audit .workaholic/ for an unregistered artifact directory
```

The smoke tests create throwaway repositories under the OS temp dir, never touch the working tree, and never call `gh`/network.

## Enforcement gates

- **Commit subject** (present-tense, ≤50 chars, no `feat:`/`[bracket]` prefix — `skills/commit/SKILL.md`): canonical validator `skills/commit/scripts/check-subject.sh`, run by `commit.sh` itself, by `drive/scripts/archive.sh` **before it moves the ticket** (so a refused subject leaves the tree byte-identical rather than half-archived), by the `PreToolUse` hook `guard-git-commit.sh`, and by the opt-in git-native `hooks/git/commit-msg` (install with `sh ${CLAUDE_PLUGIN_ROOT}/hooks/install-git-hooks.sh`; bypass one commit with `--no-verify`). One rule source; the layers cannot drift.
- **Branch names**: exactly two literal patterns — `work-YYYYMMDD-HHMMSS` (named only by `branching/scripts/create.sh`) and `release/YYYYMMDD-HHMMSS` (named only by `cut-release-branch.sh`); `guard-git-branch.sh` blocks everything else.
- **One behaviour per command**: no command's behaviour depends on the first word of its argument (bare-versus-argument is a scope and is kept; `/fb`'s cross-repository mode routes on destination, not a first word). Retired forks: `/mission close` → `/mission-close`; `/mission summary|approve`, `/ticket summary` dropped; `/drive auto|night` → `/implement`.
- **AskUserQuestion**: label hook enforces the `[<label>]` prefix; *whether* to ask is governed by `rules/interaction.md` — the **Recommended-label test**: if an option could honestly be marked "(Recommended)", don't ask; decide, record, let the developer veto.
- **Repository confinement**: every write lands inside this repository or its worktrees; the only crossing is `/fb`'s issue-opening mode with its verbatim human confirmation. Do not grow the confinement hook toward content matching — vocabulary is a human judgment. The rule only reaches repos that install the plugin; enable it user-level (`~/.claude/settings.json`).
- **GitHub over REST only** (`rules/shell.md`): every workflow script reaches GitHub through the one transport `gather/scripts/gh-rest.sh` (`slug` / `api` / `available`) — never `gh issue …`, `gh pr …` or `gh repo …`, which are GraphQL-backed and which a Claude Code Web session may 403 mid-run (measured 2026-08-12, a `[Propose]` tick that pushed its branch and then could not open the PR). A bound session is narrower still: `search/*` is refused too, so slug matching uses repository-scoped endpoints and filters locally. `gh release …` is REST-backed and stays. `node scripts/test-workflow-scripts.mjs` fails on any non-comment `gh issue|pr|repo <verb>` under `skills/` or `hooks/`; its allowlist is empty on purpose.

## Release-safety scan

`skills/release-scan/scan-branch-safety.sh` is a deterministic, script-only gate over `git diff <base>..HEAD`, run by `/report` (warn) and `/ship` (block). Three rule families, each finding citing `file:line` + rule:

- **`secret`** (hard, never overridable) — `lib/secret-patterns.sh`: pass 1 unmistakable key shapes; pass 2 matches on the **value** (quoted-alphanumeric or line-ending bare run = literal; identifiers, calls, env reads, HCL `var.`/`local.`/`data.`/`module.` references, templates, annotations are subtracted). Generated paths are exempt from pass 2 (the `Outputs Freshness` CI carries the residual risk).
- **`size`** (overridable) — per-file/branch ceilings plus a per-commit changed-lines rule (`lib/commit-size.sh` — read its header before changing it; it exempts binary rows, lockfiles, generated paths, `.workaholic/` prose, files already over the per-file ceiling, and merge commits, and counts additions only).
- **`leak`** (confirm) — re-introduction of terms from the git-ignored, developer-maintained `.workaholic/leak-denylist`. Read its scope literally: it matches listed terms in the branch diff, nothing more; a `pass` never means "no client context here". The "never name other repos/clients" convention is enforced by confinement + the crossing flow's human confirmation, not by this scan.

## Version Management

Version bumps are manual (no `/release` command). After bumping and pushing to `main`, CI (`.github/workflows/release.yml`) publishes the GitHub Release.

Version files (all at the same semver; `.claude-plugin/marketplace.json` is the source of truth):

1. `.claude-plugin/marketplace.json` — root `version` AND every `plugins[].version` (workaholic, workflows)
2. `plugins/workaholic/.claude-plugin/plugin.json`
3. `plugins/workaholic/.codex-plugin/plugin.json`
4. `outputs/workflows/.codex-plugin/plugin.json` — generated; rebuild with `build.mjs`, never hand-edit

Bump PATCH by default, update 1-3, regenerate 4, commit as `Bump version to v{new_version}`.
