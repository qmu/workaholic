# Workaholic

Private, cross-agent distribution of structured development workflows and engineering standards. **AI agents are the primary users** — routines invoking `/implement` and `/specificate`, and sessions running the workflow skills — while the **developer is the operator** who approves pull requests, configures routines, and rules on deferred decisions. Richest on **Claude Code** (plugin marketplace: commands, hooks, the always-on policy lens); portable skills also ship to **Codex** (`.agents/plugins/marketplace.json` → `outputs/workflows`) and to 40+ agents via the Agent Skills standard / `skills` CLI. Authored source lives under `plugins/`; cross-agent artifacts are generated into `outputs/`.

This file states **current behavior only**, as briefly as it can. Decision history, rationale, measurements and rejected alternatives live in `docs/loop-engineering-workflow.md`, `docs/proposal-loop-runbook.md`, `docs/drive-loop-runbook.md`, `docs/loop-drill-runbook.md`, each skill's `SKILL.md` and `reference/` directory, the feedback stream (`.workaholic/feedbacks/`), and this file's own git history. **Do not re-import them here** — a rule belongs here, its story does not. Keep this file well under 150k characters.

## Important

- Edit `plugins/`, not `.claude/` — this repo develops plugins; changes go to `plugins/` unless explicitly requested otherwise.
- **Update the docs in the same change.** When a change alters behavior, structure, commands, skills, or conventions, update every affected document (`README.md`, `.workaholic/README.md`, `CLAUDE.md`, `plugins/workaholic/rules/*.md`) in the same commit. Outdated documentation is a defect; `/story` runs `doc-drift.sh` and `area-freshness.sh` only as backstops.
- **Write each surface in the language its audience reads.** Reasoning on the `#dev-workaholic` channel and in Claude Code Web routines is **Japanese**; the Slack rule also ships in the plugin (`rules/interaction.md`, *The language of a post is the language its readers use*) in one wording across `rules/interaction.md`, the notify catalog and the four routine-fired command ceilings, pinned byte-identical by `test-workflow-scripts.mjs`. That Japanese must be understood on first sight: established technical terms keep their katakana/English form (ビルド, CI, デプロイ, PR, `terms/` entries), a title's meaning is translated rather than its words, and an untranslatable title is paraphrased. GitHub artifacts (issues, PRs, commit messages) and `.workaholic/` artifacts are **English**. Code, comments and `docs/` are untouched by the rule.

## Project Structure

```
.claude/                 # Local Claude Code configuration (rules/, git-identities, settings.json)
.claude-plugin/          # Marketplace configuration (marketplace.json)
plugins/
  workaholic/            # The single plugin (no dependencies)
    .claude-plugin/      # Plugin configuration
    .codex-plugin/       # Hand-maintained Codex-facing manifest
    skills/              # Workflow skills + policy skills (planning, design, implementation,
                         # operation, safety, development; English hard copies under policies/)
    commands/            # Claude-only thin aliases (see "Commands")
    hooks/               # Validation + guard hooks (see "Hooks") and generated policy-index.md
    rules/               # diagrams, general, interaction, shell, typescript, workaholic
scripts/
  claude.sh              # Launcher
  build-plugins/         # Generates outputs/ (argument-less run = full build)
  test-workflow-scripts.mjs  # Hermetic smoke tests
  e2e/loop-drill.sh      # Drill the loop's own mechanisms; `verify-all` runs the classified set
outputs/                 # GENERATED, committed cross-agent artifacts — never hand-edit (CI-guarded)
  workflows/             # Self-contained portable workflows plugin (+ .codex-plugin/plugin.json)
  okf/                   # OKF v0.1 bundle of the four pillars' policies
.agents/plugins/marketplace.json  # Codex plugin list (workflows -> ./outputs/workflows)
.github/workflows/       # release.yml, release-note-draft.yml, claim-retirement.yml, loop-drills.yml, …
docs/                    # Documentation; VitePress site (dependencies/ = dependency-decision logs)
```

**The documentation site deploys on merge**: `docs/` is a VitePress site served at <https://workaholic.qmu.co.jp> by the assets-only `workaholic-docs` Cloudflare Worker (`docs/wrangler.jsonc`, `assets.directory` = `docs/.vitepress/dist`, `not_found_handling: "404-page"` so dead links answer 404). `.github/workflows/docs-deploy.yml` builds and deploys on push to `main` filtered to `docs/**`, plus `workflow_dispatch`. Without `CLOUDFLARE_API_TOKEN`/`CLOUDFLARE_ACCOUNT_ID` it builds, skips the deploy and names the skip in the job summary. It is a registered deployment target (`.workaholic/deployments/docs-site.md`, `deploy-on-merge`, `api-probe`), inactive until those secrets exist and the custom domain is bound. Neither target declares `paths:`, so both read `attribution: whole_range`.

### Hooks (all shipped active in hooks.json)

- `guard-work-control.sh` (PreToolUse Agent|Task|AskUserQuestion) — only for a registered native `/work` session: reject dispatch while held/stopped, require a reserved receipt in the child prompt, reject unattended interactive questions. A review-required handoff persists `hold` and asks 「ループを再開してよろしいですか？」 as the final response text (`work/scripts/final-response-contract.sh`), never via `AskUserQuestion`.
- `validate-ticket.sh` (PostToolUse Write|Edit) — ticket floor on `todo/`: frontmatter, location, mandatory `## Policies`/`## Quality Gate`, resolvable `mission:`, and the `deferred:` shape.
- `validate-mission.sh` — Experience/≥1-acceptance floor under `missions/active/`; archive never retro-blocked.
- `validate-story.sh` / `validate-trip.sh` / `validate-feedback.sh` / `validate-strategy.sh` — OKF `type:` and schema floors on new writes; tracked history is grandfathered. Strategies need a `YYYY-MM-DD` `target_date`, non-empty `assignees`, non-empty `## Aim`/`## Schedule`, and a `stage:` from the closed set when present.
- `guard-ticket-structure.sh` (PreToolUse Bash) — blocks non-canonical ticket moves.
- `guard-git-commit.sh` / `guard-git-branch.sh` — commit-subject and branch-name gates.
- `guard-git-push.sh` — denies a composed `git push` whose refspec names only the base (`main`, `HEAD:main`, `x:refs/heads/main`, `--delete main`). No env toggle.
- `guard-askuserquestion-label.sh` — every question body opens with a `[<project label>]` prefix (`gather/scripts/project-label.sh`).
- `guard-working-directory.sh` — denies a top-level cwd-moving `cd`; a subshell `( cd … )`, absolute paths, `--prefix` forms and a leading `cd` onto a repository root pass. No env toggle.
- `guard-repo-confinement.sh` (PreToolUse Write|Edit) — blocks writes outside this repository and its worktrees (the agent's memory store is exempt). Syntactic backstop; the rule lives in `rules/general.md`.
- `policy-lens.sh` (UserPromptSubmit) — injects the policy index for commands carrying the `workaholic:policy-lens` sentinel. Regenerate `hooks/policy-index.md` with `build.mjs` after editing a pillar's `## Policies` list (CI fails on drift).
- `layout-doctor.sh [path]` — read-only audit of `.workaholic/` against the layout allowlist.

## Architecture Policy

**The coordinator.** The native `/work` coordinator caps workers at `WORKAHOLIC_MAX_WORKERS` (default 2), further bounded by available capacity; capacity-deferred roles remain due. `loops/scripts/allocate-implement.sh` treats an unreadable queue as a one-runner fallback, but a queue held entirely by operator deferral is a successful zero. Confirmed child cancellation releases its receipt without claiming completion; an unconfirmed stop keeps it live.

- **Final response.** A native parent's final response is reserved for three events: an explicit stop, a named inability to continue, and a review-required handoff (persisted `hold`, then exactly 「ループを再開してよろしいですか？」, held until explicit `resume`). Everything else is commentary; the coordinator returns to the same instance and startup anchor with no second `start`. **A unit waiting on someone else's act is a per-unit wait, never a global hold**: `blocked_on` ∈ `merge_authority | pull_request_review | verification_handoff`, and the reader refuses `unit_wait_is_not_global_hold` for `review_required` beside any of them. `task_wait` reads the same `interruptible_parent` derivation the routine path does.
- **Continuation.** A routine turn returns to a **proved continuation** (interruptible parent or same-chat scheduled tick, by `kind` and `id`; refused `continuation_unproved` when absent). `resumed` is derived at every event (`control == running` and an unexpired recorded continuation; else `continuation_unproved`, `continuation_lapsed` or the control mode); `running` alone is never reported as resumed. A named continuation is not yet a live one: `final-response-contract.sh` refuses a lapsed one with the same `continuation_lapsed` word right after `continuation_unproved`, requires `now` on any input naming a continuation (absent → `invalid_facts`), and refuses `routine_emits_no_final_response` when a routine turn declares `intends_final_response` (absent means false). `next_due < now` has exactly two call sites (the reader and `lib/coordinator.jq`), kept in step by the suite. The reader writes nothing; no closed set widened.
- **Durable record.** `runtime/scripts/state.sh` passes every unbounded value to `jq` by file (`--slurpfile`/`--rawfile`, `lib/result.sh`'s `runtime_json_result_file`), never argv, and renders the success result before the record lands. Words: `state_too_large` (over `RECORD_MAX_BYTES`, 1 MiB; gates writes only), `state_write_failed`, `state_unreadable` (also what `coordinator.sh` answers instead of exiting silently); `state_invalid` is the shape assertion only. `lib/coordinator.jq` bounds each stored `result.report` to 1200 characters with a marker, re-bounded on every write; the finishing tick still relays the full report. Contract: `skills/runtime/SKILL.md`.
- **Dispatch context policy.** `dispatch.context_policy` (`full_conversation` | `bounded_task`) is a top-level config key read only through `runtime/scripts/dispatch-policy.sh`; absent means today's behaviour, an unknown value is refused `invalid_context_policy`, and a harness that cannot honour it answers `supported: false` with its reason (`fork_turns` is a harness mapping, not a policy). Receipts record the policy launched under. No count or cadence depends on it. The child input contract (bounded task, artifact paths, worktree and claim, receipt id, user constraints, result schema, no inherited conversation) is written once in `skills/work/SKILL.md`, *Children and reports*; a worker's finish is evidence for the parent, never automatic permission.
- **Operator restrictions name what they cost.** The four loop properties (`observation_clock`, `acknowledgement_on_cadence`, `work_advances_without_waiting`, `separable_worker_evidence`) are listed once in `skills/work/SKILL.md`; `work/scripts/delegation-lapse.sh` derives which a restriction lapses (refused delegation lapses the last two; the coordinator keeps observing and never becomes an inline implementer). `announce: true` posts notify's existing precondition-stop shape. A dispatch-policy change is a correction, not a restart. Drilled by `loop-drill.sh verify-observation-during-work`.
- **Gated writes.** Read the gate in one tool call before composing the merge, push or deletion in another; exit zero is not a passing JSON gate. Internally gated delivery scripts keep their check-and-act flow. The implement command beats the claim before each ticket. Base-health detection does not itself queue a fix.
- **A reading the coordinator could not make is never zero capacity.** `loops/scripts/claimable-units.sh`'s `readable: false` falls back to one runner and is reported; a tick that spawns nothing because something it needed was degraded posts notify's precondition-stop shape under its own signature (the class decides severity, never whether a stop is announced). An idle tick posts nothing.

### Component Nesting Rules

| Caller                     | Can invoke                                                                                     | Cannot invoke              |
| -------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------- |
| Command                    | Skill, `general-purpose` subagent                                                              | —                          |
| Skill                      | Skill; (when loaded by a command/main agent) may direct it to spawn `general-purpose` subagents | Command                    |
| `general-purpose` subagent | Skill (via preload)                                                                            | Command, Task (no nesting) |

- **No per-workflow agent files.** A command spawns `subagent_type: "general-purpose"` subagents whose prompts name the skill to preload, section, inputs and return schema.
- **One-level fan-out.** Subagents cannot nest `Task` or call `AskUserQuestion`; they do non-interactive work and return JSON.
- **One plugin.** `workaholic` has `dependencies: []`; all references are same-plugin (`${CLAUDE_PLUGIN_ROOT}/skills/<name>/...`, `workaholic:<name>`). The `workflows` marketplace entry is the generated `outputs/workflows` bundle.

### The ticket spine

Everything converges on the **ticket**: sources fill `tickets/todo/`, one executor drains it to `tickets/archive/`.

- **Sources**, each named with **whose input it carries**: `/ticket` (a human's direction), `/mission`'s Creation Interrogation (a human's direction decomposed into an ordered ticket set), and `/specificate` (the feedback stream — a human's ask or a human-authored strategy, never a record the loop wrote about itself). All publish through the **publish tree** onto a `work-*` branch behind a PR; merging queues the work. What may originate a mission is stated once in `rules/workaholic.md`, *What May Originate a Mission* (`self_authored` and `self_refining` may not; `only_the_loop_spoke` is evidence, not a refusal).
- **Mission floor and ceiling.** ≥2 tickets (`mission/scripts/check-floor.sh`, read at every seam that publishes a mission). What a mission is and its scale: `rules/workaholic.md`, *What a Mission Must Be Able to Hold* — rule 1 the floor, rule 2 a judgement refusing missions with no mid-term plan; a batch sharing one review surface, one feedback thread and one acceptance walk qualifies (reported `mission_held_by:review_batch` / `mission_held_by:mid_term_plan` / `separated_by:<…>`). Ceiling: `## Acceptance` ≤3 items, `mission.md` ~60 lines / 2 KB (`mission/scripts/size.sh`). `layout-doctor.sh` reports a below-floor mission as advisory.
- **Regrouping.** `mission/scripts/regroup-tickets.sh <mission> <ticket>...` writes `mission:` onto named queued tickets and one changelog line, all-or-nothing (`mission_not_found`, `not_active`, `ticket_not_found`, `not_queued`, `in_other_mission`, `claimed`, `claim_unreadable`, `immutable_field`; re-run → `already_in_mission`). Seam: `/specificate` step 9f; that publication never auto-merges by the caller's rule.
- **One executor, two commands**: `/drive` (attended; asks only which units to take) and `/implement` (unattended; never prompts). Unified Run: freshen (`sync-main.sh`) → survey (`plan-units.sh`) → partition into PR-units → claim → drive → report → route by merge policy → account.
- **The survey.** `plan-units.sh`'s `ok`-forbidding facts: `current: false`, `shallow: true`, `backlog_error`, `owner_unresolved`, `placeholder_identity`. `backlog_all_excluded` counts exclusions per reason. The offer is ordered: mission units before loose backlog, then nearest `target_date` of the served direction (via `mission-strategy.sh`), then the mission's own ticket order; groups `direction_date` → `direction_undated` → `unattributed` → `direction_unreadable`. Each row carries `direction`, `direction_target_date`, `days_to_target`, `order_reason`. Ordering changes order, never eligibility. `feedback_refs` is carried as an annotation, never applied: a shared `feedback:` ref (read through `read-feedback-relation.sh`) is grounds — not an obligation — for grouping tickets into one PR-unit beside `depends_on`; each group names its grounds.
- **Residue already on the base.** `branching/scripts/classify-residue.sh` is a pure read (no fetch) classifying dirty paths as `on_base` (index and worktree both byte-identical to base), `regenerable` (generated path per `ship/scripts/lib/conflict-class.sh` plus the generator's marker on the base blob), `untracked`, `divergent`, `unanswerable`. `branching/scripts/clear-proved-residue.sh` runs once in `/drive` §1 on `dirty_workspace`, re-derives each path's class before touching it, restores `on_base`/`regenerable` paths (re-running the generator), never removes an untracked file, and refuses `divergent_residue`, `unanswerable_residue`, `untracked_present`, `generator_failed`. The freshen then re-runs once. `sync-main.sh` is unchanged.
- **Merge policy** (`merge_policy: auto | review`; absent means review): `auto` ships through `/ship` (drafts the plan and merges, never deploys); `review` merges its PR after `/story` opens it. No gate is overridden: `secret` hard-stops; `size`/`leak` blocks or a missing confirmation method demote `auto` to the PR path.
- **Every merge is bound to one observed head SHA.** `drive/scripts/branch-checks.sh <pr> <expected-head>` owns the check verdict (`checks_red`/`checks_pending` refuse; transport failures defer; `no_checks` is an unverified compatibility pass; `WORKAHOLIC_MERGE_CHECK_GATE=0` disables). `gather/scripts/merge-pull.sh` sends that SHA and reports success only from merged evidence.
- **The `review` route reads the severity tier**: merges on `pass` or `override_only` (reporting findings); `secret` hard-stops; `leak` holds the PR; `decision: "refuse"` merges nothing (`merge_refused: scan_unreadable`).
- **Open Decisions.** Writing floor (`create-ticket/reference/ticket-format.md`): the question, the sources consulted and what they said, and the fork's sides; may not declare the question unanswerable. Driving floor (`drive/reference/ticket-workflow.md` §1): read the named sources before honouring one as a blocker; a `blocked` outcome names them. `/ticket` asks a human instead of writing one.
- **Verification handoff** (read before merge policy): `verification_handoff: <what cannot run here>` declared at creation; `drive/scripts/verification-handoff.sh` is the one reader and also derives one for a `## Key Files` entry naming `.claude/`. A declared value wins. A handoff takes the **`handoff`** route: PR opens and stays open, `## Handoff` quotes the reason, claim stays, finish line `🟡 Handoff`, token `pending`. It holds only the **members** that carry it: none → ordinary route; all (or the mission itself) → whole-unit handoff; otherwise the non-declaring members are driven and declaring ones stay queued. `verification_handoff: probe: <command>` is run at claim time by `drive/scripts/run-verification-probe.sh` → `clean` (ordinary route) / `blocking` (handoff with the probe's output) / `unmeasured` (prose) / `unreadable` (declaration stands). Writers: `/ticket` and `/specificate` only; a run never declares one for its own unit, and it is never written as a `## Quality Gate` item. A prose declaration makes the claim `awaiting_verification`; a probe declaration never does.
- **Only a verified external limitation is handed back.** Still stopping: `secret`, `leak`, an operator-facing publication, a `blocking` probe, `pull_request_reviewed`, a colleague's claim. The run's own work: a `content_conflict` residue (resolved at agent level on the bounds in `skills/drive/SKILL.md` §6, reported `conflict_resolved` / `conflict_unresolved: <reason>`), and a prose `unmeasured` handoff (verify the named limitation here; drive the unit if absent). The proof discipline (`drive/reference/claims.md`) is unchanged.
- Retired predecessors (`/monitor`, `/trip`, `/carry`): `docs/loop-engineering-workflow.md` I1/I3/I5. `.workaholic/trips/` is read-only legacy.

### `.workaholic/` runtime conventions

`README.md` and `index.md` are the only files allowed at the `.workaholic/` root.

- **OKF floor**: every knowledge artifact carries a non-empty `type:` (`Story`, `Mission`, `Feedback`, `Strategy`, `Deployment`, `Term`, `Release Note`, `Release`); `okf/scripts/refresh-index.sh` regenerates indexes before each knowledge commit. Exceptions: `tickets/` and `moderations/`.
- **`moderations/`** — the `/moderate` tick log: one file per UTC day, one `## <tick-id>` section per tick, one line per step. **Git-ignored and committed nowhere** (no branch, notes ref or remote store — the retired `workaholic-log` branch must not be reintroduced). `moderate/scripts/log-append.sh` is the only writer (append-only, idempotent per `(tick, step)`, never prunes); `log-read.sh` reads with `--owner <moderate|loop|propose|all>` derived per entry from the step id (`loop-finish-*`/`loop-attempt-*` → `loop`, `propose-*` → `propose`, else `moderate`), default `moderate`. The `propose` owner currently has no writer and reads empty by design. `persist-log.sh --record <path>` carries a tick's feedback records to `main` **through a PR** (`publish-tree-pr.sh`, `WORKAHOLIC_AUTO_MERGE=1`, `[Record]` title), reporting `carried` / `already_on_base` / `missing` / `unreadable` / `unlanded` and refusing any `.workaholic/moderations/` path `log_destination_is_base`. `WORKAHOLIC_LOG_PERSIST=0` (in `.claude/settings.json`) turns off the legacy branch half. `step-open-log.sh` raises `log_tracked_on_base` if day files are tracked; the writer set is pinned by the suite and drilled by `verify-log-off-base`.
- **Mission rolling**: commit seams append `## Changelog` lines and tick `## Acceptance` items via `append-changelog.sh` / `tick-acceptance.sh`. Progress is computed, never stored. Items become tickable through their `(#<filename>)` link (`link-acceptance.sh`). `mission:` is many-valued; read it only through `read-relation.sh`.
- **Slug collisions**: `create.sh` refuses a slug existing in either area or on an unmerged branch (`exists_on_branch`, via `/specificate`'s `lib/unmerged-branches.sh`); an incomplete walk warns on stderr and creates anyway. `layout-doctor.sh` reports existing pairs as advisory and chooses nothing.
- **Mission lifecycle**: `status: active | achieved | abandoned | carried`; `active/` vs `archive/`; `mission/scripts/close.sh` is the only end-state writer. Drivability is derived. `archive.sh` closes only `achieved`, when acceptance is fully checked (`progress.sh`) and the queue empty (`queue-size.sh`), held only by a **prose** handoff (`mission/scripts/acceptance-handoffs.sh`; probe declarations come back as `measurable_tickets` and hold nothing). `/moderate`'s `closable-missions` step catches missions finished by other paths.

#### The strategy layer

`.workaholic/strategies/<slug>.md` is the operator's outbound, resolved direction: **Aim**, **Schedule** (`target_date`), **Assignee** (non-empty `assignees`), **Stage** (`stage:` ∈ `進行中 | 改良中 | 観察中`; absent means 進行中, resolved in `read.sh`). Operator-authored through `workaholic:strategy`; `/drive` never surveys one. The stage is **declared, never derived**; stuckness is orthogonal to it.

**Three writers**: `create.sh` (`--stage`, refusing `bad_stage`), `amend.sh` (Aim, Schedule, Assignee, Stage of a live direction; immutable fields asserted; refuses `not_active`; appends one dated `## Schedule` line naming what moved), `close.sh` (the only end-state writer; no re-opening). A run never amends on its own reading.

**Readers** (each composes the ones below; no second walker):

| Script | Answers |
| ------ | ------- |
| `read.sh` / `list.sh` | the artifact, absent-stage default resolved once (`stage_declared`) |
| `attributed-work.sh` | work belonging to a strategy — `direct` feedback-ref intersection plus `via_mission:<slug>`; ticket and mission grains |
| `mission-strategy.sh` | which strategy a mission belongs to |
| `unattributed-work.sh` | what no direction claims |
| `unattributed-asks.sh` | open inbound asks no active direction covers |
| `survey-strategies.sh` | one row per strategy: `refusal`, `pace`, `overdue`, `expiring`, `dormant`, `quiescent`, `landed`, `stage`, `residue`, `target_date`, `days_to_target` |
| `direction-state.sh` | `live \| arrived \| overdue \| expiring \| dormant \| unreadable` (+ repository `none`); `--with-leaving`; `--emit-survey <file>` |
| `closing-residue.sh` | what a direction is leaving, each block with its own `readable` |
| `landing-arithmetic.sh` | `clears` / `does_not_clear` / `no_target_date` / `unreadable` |
| `default-target-date.sh` | the one-week default (the constant 7 lives only here) |

Precedence: **`unreadable` > `arrived` > `overdue` > `expiring` > `dormant` > `live`**; `stage` rides beside it. `overdue` = `days_to_target < 0`; `expiring` = `0 <= days_to_target <= window_days`; `dormant` = legible, active, mine, not overdue, cited, nothing landed/waiting/proposed in the window; `quiescent` = `dormant` with `landed` non-empty and no date term, `false` on a degraded residue read; `pace` changes order, never eligibility.

**Only a mature question may become a gate**: `rules/workaholic.md`, *When a Human Decision May Block the Loop* — verdicts `retire`, `prerequisite`, `defer`, `ask_now` (the only one that asks). `moderate/scripts/decision-maturity.sh` derives it (with `premises[]`) and gates nothing; its one consumer is `/moderate`'s `direction-health` step over `arrived`, `cutover`, `dormant`, `settled`. A withheld question spends no ledger line; `readable: false` asks anyway. A recorded answer beside a still-blocked direction is `resumable`: the next `/propose` turn must read it before reporting `no_evolutionary_move` and name the `answer_state`; it lifts no refusal.

**Degradation is stated, never a verdict**: an incomplete walk answers `readable: false` with a named reason (`corpus_unreadable`, `patterns_unreadable`, `attribution_unreadable`, `strategy_unreadable`, `waiting_unreadable:<reason>`) and null counts. `readable` is absent on a completed walk — test `readable == false`, never `readable // true`. Named empties: `no_feedback_refs`, `no_citing_artifacts`, `no_activity_in_window`. Attribution is transitive, lossy, `exhaustive: false`.

**Succession**: a created announcement may name a predecessor; its `feedback:` refs are passed to `create.sh` (refusals `strategy_not_found`, `predecessor_active`, `no_predecessor`). **A strategy-touching publication never auto-merges** (`merge_reason: strategy_touching`, derived by the seam). The retired `strategy:` mission relation and `migrate-strategies.sh` stay retired. **Which direction a mission serves is a render, not a field**: `mission-strategy.sh` answers it for the `/mission` roadmap, the Mission Position Report and `/standup` (see `mission/reference/schema.md`).

#### The planning job

Planning is eight acts inside existing ticks — no new command, routine or artifact.

| Act | Where it lives | What it does |
| --- | -------------- | ------------ |
| **Hold new divergence** | `/propose`'s `wip_limit` rung | refuses origination at `WORKAHOLIC_WIP_LIMIT` active missions with queued work; absent means no limit |
| **Stop holding a dead handoff** | `/propose`'s `open_proposal` rung | holds only while no feedback record newer than the proposal is on the base (`open_proposal_uningested` otherwise) |
| **Name an unclaimed ask** | `/propose` report + `/moderate`'s `unattributed-asks` | names open asks no active direction covers; originates nothing |
| **Say when origination has stopped** | `/moderate`'s `propose-yield` | raises a run of propose ticks that originated nothing |
| **Order the offer** | `plan-units.sh` (`order_reason`) | nearest direction date first; order, never eligibility |
| **Do the arithmetic** | `landing-arithmetic.sh` | remaining work vs time left at the measured rate |
| **Escalate a date** | `/moderate`'s `date-will-not-hold` | asks the assignee before the date when the board will not clear |
| **Say what moved** | `/moderate`'s `📋` clause | directions advancing, held, and whether the WIP limit holds |

Authority is `drive/reference/claims.md` (*Proofs and judgements*; *When a bounded act may read a judgement*): act only on a proof re-derived at the moment of the act; otherwise report or ask. Planning may not re-date a direction, merge missions, retire a ticket it judges mooted, or close a non-arithmetic mission (full acceptance with queued tickets is asked about as `mission-leftovers:<slug>`). Dates, end states and judgements about queued work stay the operator's.

#### Tickets, ownership, identity

- **Ticket state**: `tickets/` is `todo/` and `archive/<branch>/`. `status:` absent = queued, `done` (by `archive.sh`), `abandoned`, `icebox` (`promote-icebox.sh` clears it). Never-driven tickets land in `archive/unbranched/`. Retired `icebox/`/`abandoned/` directories are still read and converged by `gather/scripts/migrate-ticket-states.sh`; `layout-doctor.sh` reports survivors as `retired-ticket-state`.
- **Operator deferral holds a ticket in the queue**: `deferred: <why>` on a queued ticket (bare `deferred:` and values opening `[`/`{` are refused by the write floor). `drive/scripts/read-deferral.sh` is the one parser; `plan-units.sh` excludes it `operator_deferred` (still counted in `backlog_size`), `deferral_unreadable` otherwise. `claimable-units.sh` reports a deferred-only queue as a successful `claimable: 0` with `deferred: <n>` (zero runners, no alert); an unreadable one still takes one runner. Removing the line is the only re-offer path; nothing in the loop writes it. Mission members' deferrals are not read. `icebox` parks a ticket out of the queue; `deferred:` holds one in it.
- **Ownership**: plural `assignees`; empty means team-owned. One oracle: `gather/scripts/owners.sh` / `owns.sh` → `mine`/`unowned`/`other`/`unresolved`.
- **Identity**: `.claude/git-identities` maps `<login>=<canonical>[,<alias>...]`; `gather/scripts/identity.sh` is its one reader and never guesses (`resolved: false` echoes the input). The only other parser is the web bootstrap's step 0b. `gather/scripts/migrate-assignee-aliases.sh` converges written artifacts (stages, never commits). Claims key on `git config user.email`; `WORKAHOLIC_CLAIM_IDENTITY` overrides for an executor with none.
- **Ticket-only tolerance tier**: a ticket at `tickets/todo/<user-slug>/<file>.md` with no ownership fields resolves to `<user-slug>`.
- **Feedback subject**: `subject: <kind>[:<identity>]`, kind ∈ `person | meeting | observer_ai | customer | team | other` (subject = who formed the opinion, source = channel, author = git identity). `create.sh` refuses `no_subject`.
- **Deferred concerns**: the story's Concerns section is the durable record; `ship`'s `extract-deferred-concerns.sh` persists each as a `kind: concern` record keyed on `concern_id`; open until superseded.
- **Red-alert cool-down** expires at the earlier of 24h after first report and the start of the next working day (`WORKAHOLIC_WORK_DAYS`, `WORKAHOLIC_QUIET_HOURS`, `WORKAHOLIC_QUIET_TZ`); a re-posted root names how long it has failed. A red base rides this cool-down as a report (not a question), signed by failing check names, not SHA.

#### Areas

- **Hand-maintained areas** (`deployments/`, `terms/`): defined in `rules/workaholic.md`; `story/scripts/area-freshness.sh` reports `retired_terms` and `stale_days`, never writes. `/ship` gates on a deployment record's `## Confirmation`.
- **Retired areas** (`policies/`, `guides/`, `specs/`): gone; reference docs live in `docs/`. `layout-doctor.sh` classifies them `retired-area`.
- **Renames**: `skills/gather/scripts/renames.tsv`, read only through `list-renames.sh`. `area` rows are applied (`migrate-renamed-areas.sh`; survivors `renamed-area`); `name` rows are proposed only (`rename-conversions.sh`). `WORKAHOLIC_RENAMES_TABLE` points at another table.
- **Closed layout**: permitted top-level directories live in two lockstep sources — `hooks/workaholic-layout-allowlist.txt` and the table in `rules/workaholic.md` — registered in the same commit that first writes to a new one; CI fails on `conforming: false`.

### Claim protocol

The repository is the coordination medium. Model: `skills/drive/SKILL.md` (**Claims**); detail: `skills/drive/reference/claims.md`.

- A runner claims a PR-unit (mission slug or `batch-<ts>`) as a `Claim <unit-id>` commit on a pushed `work-*` branch; **unmerged remote branches are the only claim oracle** (`list-claims.sh`). One unit ↔ one branch ↔ one worktree (`.worktrees/<unit-id>/`) ↔ one PR.
- A merge releases a claim. `release-claim.sh` discards an unfinished unit. `claim.sh resume` takes over only **your own** claim whose heartbeat lapsed; a colleague's is untouchable. Staleness is reported, never acted on.
- The heartbeat is the branch tip (`heartbeat.sh`, empty commit via a scratch index). **Beat at step 0 of every ticket** — the takeover window is `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` (30); `WORKAHOLIC_CLAIM_STALE_HOURS` (24) is only reported staleness. No background timer.
- Worktrees are claim-born and ship-torn (`cleanup-mission-worktree.sh`; backstops `survey-worktrees.sh` / `reap-worktrees.sh`). `/moderate`'s `worktree-sweep` step runs `reap-worktrees.sh --apply` hourly, removing only `reclaimable` (merged **and** clean, re-derived) worktrees, never `--force`. Under squash merges a landed branch stays `merged: false`, so held worktrees are named, not removed. Keep `.worktrees/` and `.publish/` in `.dockerignore` and archiver ignores.
- `branching/scripts/ensure-worktree.sh` refuses a branch name that exists on origin; attaching is `create-mission-worktree.sh --branch`'s job.

#### Verdicts

| Verdict | Meaning | Resumable | Survey exclusion |
| ------- | ------- | --------- | ---------------- |
| `claim_active` | live claim, heartbeat fresh | no | `claimed_*` |
| `stale` | tip older than `WORKAHOLIC_CLAIM_STALE_HOURS` — look, don't take | own claim only | — |
| `superseded` | tickets on the base **and** branch empty against it | no | `claimed_superseded` (work resurveyed) |
| `stranded` | tickets on the base, branch still holds work found on no other ref | no | `claimed_stranded` |
| `queue_drained` | drained, story at tip, PR open | no | `claimed_reported` |
| `report_incomplete` | drained, no story | **yes** (re-enters at §5) | `claimed_resumable` |
| `report_undelivered` | the transport's refusal recorded in the branch story | no — merge retry | `claimed_undelivered` |
| `awaiting_verification` | every remaining member (or the mission) declares a **prose** handoff | no | `claimed_awaiting_verification` |
| `parked_with_pr` | reported with follow-up work on the branch | yes | — |
| `heartbeat_lapsed` / `foreign_identity` / `identity_unresolved` / `shallow_history` / `ambiguous_claim` | as named | no | — |

**Proofs and judgements** (`drive/reference/claims.md`, keyed on the words `lib/claims.sh` emits): a consumer may **act** on a proof and only **report or ask about** a judgement. `superseded` (gated by `claims_branch_empty_against_base`; unanswerable emptiness → `stranded`) and `report_undelivered` are the only claim proofs. Further keyed vocabularies there: `candidate_reason` (three proofs), base checks, operator-facing PR action, condition age, mergeability, act effect (`drive/scripts/act-effect.sh`), and answer outcome (`moderate/scripts/answer-outcome.sh` → `settled:nothing_filed` / `settled:issue_closed` / `pending` / `unreadable:<reason>`, `not_answered:<state>`). The suite fails on an unclassified word, a stale row, a judgement called a proof, or an enumerated consumer reaching an acting call site. A bounded act may read a judgement only if it re-derives it at the act, is idempotent, reversible and refuses each bound by its own word (`catch-up-claim.sh` is the only consumer).

**Resolution**: a unit held by two branches resolves to the **live** row (`claims_unit_resolution` / `claims_unit_row` / `claims_unit_live_branches`); two live claims are `ambiguous_claim`, never picked between. `plan-units.sh` names freed work in `resurveyed: [{kind, id, claim}]`.

**`superseded` at both grains**: batch claims from the tree (every ticket archived on the base); mission claims from the claim's tip (`claims_mission_landed`, `every`), falling back to `drive/scripts/claim-merged.sh` — the one network read, three-valued, `unanswerable` named in `merged_lookup_unanswered[]`, skipped `offline` or `disabled` (`WORKAHOLIC_CLAIM_MERGED_LOOKUP=0`).

**Claim races**: `claim.sh` §3b wins one ref per claimed artifact (`drive/scripts/claim-arbitrate.sh`, `refs/claims/artifact/<path>`, create-only lease, all-or-nothing, unique value per claimant) before creating anything; the loser refuses `claim_race_lost`. The lock lives only for the claim act (released on push or `abort_claim`); a leaked lock is reaped when no live claim stands behind it and it is older than `WORKAHOLIC_CLAIM_ARBITER_STALE_MINUTES` (10). Where the transport refuses the ref write it answers `unavailable` and the claim proceeds; `archive.sh` then re-derives the holder via `drive/scripts/claim-holder.sh` before each move (`claim_taken_over`, `ambiguous_claim`). Live races reach a person via `list-raced-units.sh` and `/moderate`'s `raced-units` step.

#### The three acts on a claim

Each acts on a proof re-derived at the act, is idempotent, and refuses by its own word with nothing written and exit 0.

- **Retirement** — `drive/scripts/retire-claim.sh <unit>` on `superseded`: close the PR, delete the remote branch, reap the worktree, in that order. It merges and pushes nothing. Branch deletion runs in `.github/workflows/claim-retirement.yml` (`contents: write`): `list-retirable-claims.sh` supplies candidates with a `candidate_reason` — `superseded_only`, `pull_request_merged`, `pull_request_closed_unmerged`, `mission_not_active` — and `delete-retired-claim-branch.sh` acts, refusing by word (`not_a_work_branch`, `release_branch`, `not_on_base`, `pull_request_open`, `gh_unavailable`, `slug_unresolved`, `branch_delete_failed`, `not_superseded:<verdict>`, `pull_request_unreadable:<reason>`, `not_merged:<state>`, `not_closed_unmerged:<state>`, `no_unit_for_mission_class`, `mission_unreadable:<reason>`, `mission_still_active:<state>`, `branch_holds_work`, `emptiness_unanswerable`). An open PR is never a candidate. `record-ci-retirement-turn.sh` / `read-ci-retirement-record.sh` record and read outcomes via check-run annotations (`WORKAHOLIC_CI_RECORD_MAX`). CI scripts use `lib/runner-identity.sh` (override only when no identity is configured).
- **Delivery retry** — `plan-units.sh` emits `undelivered: [{unit, branch, merge_outcome}]`; `drive/scripts/retry-undelivered.sh <unit>` makes one REST merge on `report_undelivered` (`not_undelivered:<verdict>`, `scan_held:<tier>`), recording a new refusal via `record-merge-outcome.sh`. `--own-tip` relaxes only the heartbeat term.
- **Catch-up** — `drive/scripts/claim-mergeability.sh` → `clean | mechanical | content | unanswerable` from `git merge-tree --write-tree`, computed with `.gitattributes` out of reach (GitHub applies no merge driver). `drive/scripts/catch-up-claim.sh <unit>` composes `ship/scripts/catchup-main.sh --resolve-mechanical`, regenerates, runs the local proof and pushes; a `queue_drained` unit's PR is then merged (scan first, via `gate-decision.sh`), reported in `delivery` (`merged` / `merge_refused: <word>` / `not_attempted[: <reason>]`). `report_undelivered` belongs to `retry-undelivered.sh`; `awaiting_verification` is reported `not_attempted: awaiting_verification`. Refusals: `content_conflict`, `not_my_claim`, `foreign_identity`, `identity_unresolved`, `claim_active`, `dirty_worktree`, `scan_held:<tier>`, `not_a_work_branch`, `ambiguous_claim`, `mergeability_unanswerable:<reason>`, `catchup_<class>`, `validation_failed:<check>`, `push_failed`, `pull_request_reviewed` (`reviews_unreadable:<reason>`; bot reviews don't count). The classification rule lives only in `ship/scripts/lib/conflict-class.sh`. `list-catchable-claims.sh` offers this identity's `report_undelivered`, `queue_drained` and `awaiting_verification` claims whose mergeability is `mechanical` or `content` (a `content` prediction is attempted; a hunk the merge cannot settle refuses `content_conflict` with nothing pushed). Per-class resolution strategy: `drive/reference/claims.md`, *The resolution strategy, per class*.
- **Stranded publications** (not claims): `branching/scripts/list-stranded-publications.sh` names open PRs on `work-*` branches with no claim and no publication-refusal word, with their mergeability and `age_hours` (`lib/publication-age.sh`; null when unreadable; evidence, never a gate). `branching/scripts/settle-stranded-publication.sh <number>` settles `clean` (merge only), `mechanical` and `content` (catch up, regenerate, check, push, merge), scanning first; refusals `not_mechanical:<class>`, `content_conflict`, `has_claim_commit`, `not_a_work_branch`, `scan_held:<tier>`, `validation_failed:<check>`, `push_failed`. Headless PRs are counted (`headless`) and listed by `list-headless-pulls.sh` for `/moderate`'s `headless-pull:<number>` question; the loop closes nothing itself.

#### The publish tree

Artifact writers use a checkout of `origin/main` at git-ignored `.publish/` on branch `publish-main`: `open-publish-tree.sh` → write → `publish-tree-pr.sh` (the only unattended path) or `publish-tree-commit.sh` (attended use and fixtures only) → `close-publish-tree.sh`. The caller's checkout stays byte-identical.

- **Ingest references, never closes, the ask's issue**: `/specificate` sets `WORKAHOLIC_REFERENCES_ISSUE` (`Refs #<N>` + a line saying it stays open); `WORKAHOLIC_CLOSES_ISSUE` still writes `Closes #<N>` for other callers and wins if both are set. The ask stops being re-offered through `list-inbound-issues.sh`'s record check, not closure.
- **Two publications never auto-merge** (the seam's rule, on the shape of the change): `strategy_touching` (`.workaholic/strategies/`) and `ruling_touching` (an existing mission's `feedback:` line moved, or `.claude/git-identities` touched). The test lives in `branching/scripts/lib/publication-refusal.sh`; `branching/scripts/publication-effect.sh` reads them back for `/moderate`'s `operator-pull:<number>`.
- The claim oracle degrades offline; writers fail loudly. Unattended notifications use the binding resolved by `workaholic:transport`. Thread lookup is a private-inclusive exact lookup; only a complete not-found permits a description root, otherwise `thread_unresolved`. `notify-slack.sh --thread-ts` carries a resolved coordinate but cannot search. Never switch accounts to make a self-mention effective; an unresolved directed mention is omitted and reported `(メンション先未解決: 誰にも通知していません)`. Delivery is established by provider receipts; failed or unknown deliveries stay in the binding-scoped outbox. Permission refusals are recorded, never bypassed. An attended `/drive` posts nothing to Slack.

### The Slack binding is declared by the repository, not by its environment

- **Declaration**: a fenced **`workaholic-slack-binding`** block (`transport/scripts/schemas/binding.schema.json`: `workspace`, `channel`, optional `channel_id`, `mount`, `account`, `sender_id`, `operations`, `fallback`). This repository declares it in `AGENTS.md`.
- **One reader**: `transport/scripts/read-declared-binding.sh` — root `CLAUDE.md`, root `AGENTS.md`, then each `--scope`, then `WORKAHOLIC_SLACK_BINDING_FILE`; deeper scope overrides, two disagreeing sources at one depth are a `conflict`. `declared: false` under `ok: true` falls back to `WORKAHOLIC_INBOUND_SLACK_CHANNEL` / `WORKAHOLIC_SLACK_WORKSPACE`. **Read `ok` first**: an `ok: false` reading is `binding_unreadable:<reason>`, never "undeclared"; `apply-slack-binding.sh` refuses `declaration_unreadable`. `declared_digest` travels with the resolved binding. `/infinite-development` reads it before any Slack act.
- **Route resolution**: `transport/scripts/describe-qfs.sh` describes a declared mount directly (one call) or enumerates connections and falls back to the aggregate `/slack` describe (three calls). Nothing is guessed: `public_miss`, `channel_verified: false`, and an empty describe body is not a route. Refusals: `qfs_unavailable`, `connections_unreadable`, `no_connection`, `mount_not_described`, `missing_scope`, `no_route`. `resolve-target.sh` verifies workspace, channel, account, sender and required operations as one binding: `target_unverified` (nothing reaches the channel), `operations_unsatisfied` (a route reaches it but can't do what was declared), `sender_unverified` (a declared `sender_id` no route proves; no opt-in needed), `ambiguous_identity`. An `account` is never offered as a `sender_id`.
- **Thread replies are discovered** via `list_thread_changes` over the same bounded overlap window; `observe-channel.sh` reads each changed thread whole, captures through `capture-inbox.sh`, and routes each human reply `moderation_answer` / `answer_to_loop` / `reaction_only` / `needs_judgement`. Fan-out `WORKAHOLIC_THREAD_FANOUT` (5); truncation reported. `coverage.threads.status` is `covered` only when discovery ran, else `partial` with its reason; `coverage.complete` derives from all axes. The thread capture never moves the channel cursor.
- **An unproved observation is unread, never quiet**: `plan-poll.sh` answers `observation_unreadable` for an unproved read, `observed_quiet` only for a proved quiet one, `observation_incomplete` when `observation_settled` is false (`unsettled[]`: `channel_delta_incomplete`, `thread_coverage_partial`, `thread_fanout_truncated`, `sender_identity_unverified`). `observe-channel.sh` records `unproved_since`, widens `overlap_seconds` to cover it, and clears it only when a capture's window reached it. The word moves, never the cadence.
- **Drain and remember**: the delta is consumed to its end within `WORKAHOLIC_CHANNEL_PAGES` (5; else `channel_pages_exhausted`). Roots and permalinks join a bounded watch set (`watch_threads`, `WORKAHOLIC_WATCH_SET_MAX` 50; `watch_set_unwritten` on refusal), read as a fallback (`source: watch_set_fallback`, still `partial`) when discovery is unavailable. One bounded `search_exact` per tick for the sender's mention token adds threads and reads them (`WORKAHOLIC_MENTION_FANOUT` 3); the search captures nothing; `coverage.mentions` is `exhaustive: false`. A thread is read at most once per tick.
- **Inbox dedup key** (`capture-inbox.sh`, declared in its header): `provider_id` + sender (`sender_id // user`); `thread_ts`, `user`, `subtype`, `edited_at`, `text` are excluded as per-operation, per-route or mutable. Every failing branch reports `status: deferred`, `reason: capture_incomplete` with cause and offending id, exit 0.
- **Route fallback** (`transport/scripts/perform.sh`): **Typed is not the same as fallback-permitting.** Classes: `qfs_unavailable`, `qfs_operation_unavailable` / `qfs_map_unverified`, `qfs_preview_refused`, `qfs_preview_failed`. `qfs_preview_refused` keeps the operation on the declared route (`qfs_fallback_class()` → `none`): an authorization denial stays a refusal, with no alternate route, spelling, delegation or account (same doctrine as `refusal-capability.sh`'s `not_permitted`). Reads may also fall back on reachability; writes may not (`qfs_connector_failure`, `accepted_send_timeout` → outbox `unknown`, reconciled, never resent). The declared `fallback` order governs (empty forbids all); destination fields ride verbatim. Results carry `route`, `degraded`, `degraded_from`, `degradation_reason`, `preferred_route_verified` (true only for an `ok` QFS result). `expected_declared_digest` mismatch → `binding_stale`, nothing written. A declared sender is settled before a route is chosen (`sender_mismatch`, outbox `refused`).
- **QFS native adapter**: `adapters/qfs-native.sh` reads the preview count at `.total_affected` or `.preview.total_affected` (number or `{"exact": N}`); `describe-native-qfs.sh` advertises `list_thread_changes` only when `<base>/threads` proves `verbs.select`, else states `thread_discovery_unavailable` with its reason.
- **Reports name the destination**: both report contracts (`commands/infinite-development.md`, `workaholic:work`) name workspace, channel and `channel_id` from the reader's `binding`, in one pinned wording; the suite also rejects a `read-declared-binding.sh` call piped into `jq` without `binding`.
- **Audit** (advisory): `workaholify/scripts/check-slack-binding.sh` → `not_declared`, `incomplete_declaration`, `contradictory_declaration`, `invalid_declaration`, `unknown_key:<key>`, `unverifiable_sender`, `unreadable:<source>`. `apply-slack-binding.sh` appends a declaration and refuses `already_declared`.

### The release tier (`release/*`)

`main` is the continuously auto-merged development branch; **quality is gated at the `release/*` QA window**. `branching/scripts/cut-release-branch.sh` cuts `release/YYYYMMDD-HHMMSS` from `main` (batch-level, explicitly invoked, no commits of its own, invisible to claims). `/ship` §5 does not deploy or confirm pre-merge. The ship record is `.workaholic/releases/<release-branch>.md`, written by `ship/scripts/record-release-cut.sh` and `confirm-release.sh`. Confirmation is never skipped; a failed one deletes nothing and the next attempt cuts a fresh branch. No `develop`, no `hotfix/*`.

### Design principles

- **Thin commands, comprehensive skills.** Commands name the skill, section and entry contract; knowledge lives in skills (~50-150 lines; overflow to `reference/`).
- **Common operations go through skills** (`gather/scripts/git-context.sh`, `gather/scripts/ticket-metadata.sh`) — never inline `git branch --show-current` etc. in markdown.
- **No complex inline shell** in command/subagent markdown — extract to a skill script.
- **`${CLAUDE_PLUGIN_ROOT}` for every skill script reference in markdown.** It is not set in the Bash tool's environment: a session expands it when composing the call, writing the path in full with the reader first and no assignment prefix (`rules/general.md`, `rules/shell.md`).
- **Plugin boundary**: invoke skills by their `workaholic:` namespace; never read installs on disk to find skill content. The one sanctioned crossing is `check-deps/scripts/plugin-src.sh` (newest version wins; ties go to the immutable candidate; answers `src`, `src_immutable` and `call_src` — the checkout's path when it holds the same version). In an attended session with a missing skill, ask which plugins are loaded.

### Cross-agent exposure and generated outputs

- Script-bearing skills carry `metadata.internal: true` and keep `${CLAUDE_PLUGIN_ROOT}`, reaching other agents only through the generated bundle. Pure-prose skills (`design`/`implementation`/`operation`, `write-release-note`, `review-sections`) are exposed.
- `outputs/workflows/` is the self-contained bundle (paths rewritten, internal metadata stripped, `reference/` carried). **Regenerate with argument-less `node scripts/build-plugins/build.mjs` whenever a workflow skill or its script closure changes**; `Outputs Freshness` CI fails on any diff.
- The `workflows` marketplace entry keeps **`"strict": false`** (no `.claude-plugin/plugin.json` in the bundle). `hooks/hooks.json` keeps `hooks` as its only top-level key.
- `outputs/okf/` is the OKF v0.1 policy bundle generated by `okf.mjs` (`docs/dependencies/okf.md`).

## Commands

Command bodies in `plugins/workaholic/commands/` define execution; their named skills own the rules, scripts and reference material.

| Command | Owner |
| --- | --- |
| `/ticket` | `workaholic:create-ticket` |
| `/drive`, `/implement` | `workaholic:drive` |
| `/commit` | `workaholic:commit` |
| `/specificate` | `workaholic:specificate` |
| `/propose` | `workaholic:propose` |
| `/fb` | `workaholic:feedback` |
| `/story`, `/report` | `workaholic:story` |
| `/ship`, `/prepare-release` | `workaholic:ship` |
| `/mission`, `/mission-close` | `workaholic:mission` |
| `/catch` | `workaholic:catch` |
| `/explain` | `workaholic:explain` |
| `/standup` | `workaholic:standup` |
| `/moderate` | `workaholic:moderate` |
| `/work`, `/infinite-development` | `workaholic:work`, `workaholic:loops` |
| `/workaholify` | `workaholic:workaholify` |

Routine setup commands use their matching command body. Release-note, deployment-plan, drill and routine details live in the owning skills and `docs/`.

## Development Workflow

1. `/ticket` — write specs (published behind a PR; merging queues them) — or let `/propose` supply the ask and `/specificate` turn it into specs
2. `/drive` (attended) or `/implement` (unattended) — implement each spec
3. `/story` — story + PR
4. `/ship` — merge, deploy, verify

## Type Checking

No build step required — this is a configuration/documentation project.

## Local Verification

Before pushing changes to workflow scripts or plugin manifests:

```bash
node scripts/build-plugins/build.mjs              # regenerate outputs/ AND hooks/policy-index.md
node scripts/build-plugins/verify.mjs             # generated skills self-contained, policy index in sync
node scripts/build-plugins/validate-metadata.mjs  # Codex manifests well-formed and version-aligned
node scripts/test-workflow-scripts.mjs            # hermetic smoke tests
node --test scripts/tests/agentic-loop/*.test.mjs # compatibility contracts and portable consumers
bash plugins/workaholic/hooks/layout-doctor.sh .  # audit .workaholic/ layout
sh scripts/e2e/loop-drill.sh verify-all           # classified drill set; CI runs the hermetic part
```

Smoke tests use throwaway repositories under the OS temp dir and never touch the network. On a machine whose `/tmp` is a shared tmpfs, point `TMPDIR` at local disk.

**The machine reads `branching/scripts/local-proof.sh`**, the one declaration and runner of the local proof set (CI's `validate` job commands plus `verify.mjs` and the hermetic drill). A PR based on `main` merges on `pass development_main_local_proof` without reading remote checks, so this set is what stands in. Both `catch-up-claim.sh` and `prepare-publication.sh` compose it. Output fields: **`ok`** (no check ran and failed — callers refuse on `ok: false` with `validation_failed:<check>`), **`complete`** (every check ran; reported, never a refusal), **`not_run`** (`check_absent`, `interpreter_unavailable:<tok>`, `timeout:<n>s`). Every check runs even after a failure; claim tunables are unset; each check's log path rides the result. A check killed without an applied timeout (e.g. status 137 on a row declaring none) is a failure (`killed:SIGKILL`), not `not_run`. The set runs under a per-run `TMPDIR` in `${XDG_CACHE_HOME:-$HOME/.cache}/workaholic/`, proved to be outside every repository and removed on exit; an unusable one is named in `scratch` (`no_cache_home`, `scratch_dir_unwritable`, `scratch_dir_inside_repository`) and never refuses. Reporting obligation: `skills/drive/SKILL.md` §7; the suite pins the declaration against `validate-plugins.yml`.

## Enforcement gates

- **Commit trailers** (`skills/commit/SKILL.md`): `commit.sh` is the one writer — `Category:` with `--category`, `Workaholic-Housekeeping: <heartbeat|claim|index|hours>` with `--housekeeping` (else `bad_housekeeping_kind`), `Claude-Session:` when `CLAUDE_CODE_REMOTE_SESSION_ID` is set, and `Co-Authored-By:` always. The author email is untouched (claims key on it); the web bootstrap sets a repo-local `user.name` only if none exists.
- **Half a rename is refused**: with default staging, a staged deletion beside an untracked file makes `commit.sh` refuse and name both halves. A caller that just wrote a new file passes it in `files...`.
- **Commit subject** (present tense, ≤50 chars, no `feat:`/`[bracket]` prefix): `skills/commit/scripts/check-subject.sh`, run by `commit.sh`, `archive.sh` (before moving the ticket), `guard-git-commit.sh`, and the opt-in `hooks/git/commit-msg` (`hooks/install-git-hooks.sh`).
- **Embedded jq that does not compile is our defect** (`rules/shell.md`): jq exit 3 = compile error, 5 = data. At run time `skills/moderate/scripts/lib/jq-guard.sh` records compile errors and `run.sh` reclassifies the step `degraded` / `jq_compile_error`; at build time the suite compiles every extractable `jq` program (interpolated ones are counted).
- **`//` is not a default where `false` is a real answer**, and **`<array> | index(.)` tests the array against itself** — write `has()` / `!= false`, and bind the element first (`. as $d | any($set[]; . == $d)`). Writing/review rules, not machine-checkable.
- **A base write is a merge of a pull request, never a push.** `branching/scripts/lib/base-ref-gate.sh` is the one reader (`allowed:<why>` / `refused:base_ref_write`), sourced by every commit and push site. Absent `WORKAHOLIC_ROLE` means attended; unattended paths set their role at their own entry. `work-*`, `release/*`, `refs/claims/*` are allowed by name; `land-unit.sh` reads it with `reviewed`. `hooks/guard-git-push.sh` is the agent-level half; the suite fails on an ungated push site and proves Propose, Moderate, notification and finish-log paths against a fake origin (`loop-drill.sh verify-base-ref-gate`). `check-repo-settings.sh` reports `base_branch_unprotected` as advisory.
- **Branch names**: exactly `work-YYYYMMDD-HHMMSS` (only via `branching/scripts/create.sh`) and `release/YYYYMMDD-HHMMSS` (only via `cut-release-branch.sh`); `guard-git-branch.sh` blocks everything else.
- **One behaviour per command**: no command's behaviour depends on its argument's first word. Retired forks: `/mission close` → `/mission-close`; `/mission summary|approve`, `/ticket summary` dropped; `/drive auto|night` → `/implement`.
- **AskUserQuestion**: `[<label>]` prefix enforced by hook; whether to ask follows `rules/interaction.md`'s **Recommended-label test** (if an option could be marked Recommended, decide instead). An unattended run never blocks on any prompt and composes only allowlistable commands: plugin skill/reference files are read with the **Read tool**, never `sed`/`grep`/`cat`/`head`/`tail`/`awk` (`rules/shell.md`), and every reach uses `plugin-src.sh`'s `call_src` (the checkout's path) rather than a path under `.claude/`, which the session classifies as sensitive above the allowlist. This is carried byte-identically into the four routine-fired command ceilings and pinned by the suite. No allow entry for the plugin cache is added and no hook blocks the shape.
- **A scratchpad redirect must not assume `>` truncates**: under `noclobber` use `>|` or a run-unique filename (`rules/shell.md`).
- **Repository confinement**: every write lands inside this repository or its worktrees; the only crossing is `/fb`'s issue-opening mode with verbatim human confirmation. Do not grow the confinement hook toward content matching.
- **Every merge is a squash, and method and body are derivations**: `gather/scripts/merge-method.sh` and `gather/scripts/merge-commit-body.sh` (`source`: `story` / `fallback` / `unreadable:<reason>` such as `no_commit_range`, `commit_walk_failed`; reported as `body_source`; always yields a body; housekeeping commits dropped by trailer, no interpreter needed). Every REST call site (`ship/scripts/merge-pr.sh`, `branching/scripts/publish-tree-pr.sh`, `drive/scripts/retry-undelivered.sh`, `drive/scripts/catch-up-claim.sh`, `branching/scripts/settle-stranded-publication.sh`) and the agent-level merges read them; the suite fails on a literal method/body or a merge site reading no composer. Squash safety relies on `superseded` being tree-derived and `delete_branch_on_merge`. History is not rewritten.
- **GitHub over REST only** (`rules/shell.md`): through `gather/scripts/gh-rest.sh` (`slug` / `api` / `available`). Never `gh issue|pr|repo …` (GraphQL-backed); no `search/*`. `gh release …` stays. A REST merge refused `403 … not permitted for this session type` → `merge_reason: session_type_cannot_merge`, which alone may be retried once through `mcp__github__merge_pull_request` at the agent level (also in `commands/infinite-development.md`). `branching/scripts/refusal-capability.sh <word> [route]` classifies refusals `no_capability` / `call_errored` / `not_permitted` / `none` / `unclassified` with `route` and `authorized_route` (non-empty only for that one case → `github_connector`); refused deliveries are reported `merge_refused: <word> (<capability> on <route>)`. The suite fails on any `gh issue|pr|repo <verb>` under `skills/` or `hooks/` (empty allowlist).

## One accepted request, several pull requests, one delivery state

- **Per item**: `work/scripts/feedback-outcome.sh` owns whether one feedback item is delivered. `work/scripts/delivery-ledger.sh` composes it over the item's PR set (`every`, never `any`), adding the first absent stage (`merge` → `deployment` → `public_verification`), a per-row `delivered`, a bounded dependency-ordered `next[]` (`WORKAHOLIC_INTEGRATION_MAX` 3; `order_unresolved:<numbers>`, `depends_on_outside_item:<numbers>`), one `blockers[]` entry per gate with its whole scope, and `independent[]`. It acts on nothing; unreadable → `readable: false`, null counts, null `next`. Read by `commands/implement.md` and `commands/infinite-development.md`.
- **Per thread**: `work/scripts/thread-completion.sh` composes the ledger across one human thread (`every`), keyed `<channel>:<thread-root ts>` (the existing `slack-ref:`) by exact equality. The accepted set is every request from that thread and its explicitly linked continuations, minus requests a person explicitly deferred or cancelled (`excluded[]`); keyless items go to `keyless[]`. Anything unreadable answers `unreadable`, never `complete`. Its one consumer is `/infinite-development`'s *Announce landed asks*.
- **Reread before the mention**: that thread is reread through `observe-channel.sh`'s bounded thread read (no cursor advance), new requests captured via `capture-inbox.sh` first; `work/scripts/mention-reread.sh` answers `allow` or withholds by word (`no_reread`, `observation_unreadable`, an `unsettled[]` term, `capture_unreadable`, `capture_incomplete`, `new_request_found`). One wording in `commands/infinite-development.md` and `skills/work/SKILL.md`, pinned.
- **Three acts** (defined once in `workaholic:notify`, *Three acts: a worker receipt, scoped progress, and a completion mention*, carried into `commands/infinite-development.md`): a worker terminal receipt is internal evidence; scoped progress (`📊`) carries no mention; a completion mention (`🏁`) fires once per set, only on `complete` after `allow`. Only an explicit human defer or cancel narrows the set. `🟢 Implemented` keeps its per-unit meaning.
- **Review surface is persisted**: `review_surface:` on the feedback record, written by `feedback/scripts/create.sh --review-surface` at `/specificate` step 3, read by `feedback/scripts/review-surface.sh`. `feedback-outcome.sh` is the one resolution site (caller-supplied `expected_surface` is ignored; `verified_surface` stays a caller fact): absent → `surface_unresolved`, unreadable record → `surface_unreadable` (`record_not_found` / `record_unreadable` / `no_feedback_ref`), differing → `surface_mismatch`. Corrections are new records via `supersedes`.
- **Closing the source issue**: `work/scripts/close-source-issue.sh` re-derives the verdict and closes via REST `PATCH` only when delivered; idempotent (`already_closed`); refuses `still_queued`, `not_implemented`, `not_verified`, `surface_unresolved`, `surface_unreadable`, `surface_mismatch`, `evidence_missing`, `unreadable` with `requested: false`. Only `/implement`'s per-item reconciliation calls it; asks landing elsewhere are closed by a person.

## A tightened constraint over persisted data is verified against legacy rows

A fresh-schema pass is not evidence for an upgrade: a change narrowing what already-stored data must satisfy is verified by exercising the upgrade path against a representative legacy fixture, including rows the new constraint rejects. Stated once in `plugins/workaholic/rules/general.md`, *A tightened constraint over persisted data is verified against legacy rows*; asked for in `create-ticket/reference/ticket-format.md` and observed in `workaholic:ship` (*A failed or pending deployment is its own state*). The mirrored policy pages under `skills/<pillar>/policies/` are deliberately not edited (upstream `standards-sync/*` owns them); the suite pins both.

## Release-safety scan

`skills/release-scan/scan-branch-safety.sh` is a deterministic gate over `git diff <base>..HEAD`, run by `/story` (warn) and `/ship` (block). Each finding cites `file:line` + rule:

- **`secret`** (hard, never overridable) — `lib/secret-patterns.sh`: key shapes, then literal values (references, env reads, templates subtracted). Generated paths are exempt from pass 2.
- **`size`** (overridable) — per-file/branch ceilings plus per-commit changed lines (`lib/commit-size.sh`; read its header before changing it).
- **`leak`** (confirm) — terms from the git-ignored `.workaholic/leak-denylist`. A `pass` only means no listed term; the no-client-names convention is enforced by confinement and human confirmation.

Consumers key on the **severity tier** via `gate-decision.sh` (`override_only` stays releasable). **An unread scan refuses**: `decision: "refuse"` with `reason` ∈ `no_scan_input`, `unparseable_input`, `not_a_scan_verdict`, `finding_unclassified`, `bad_argument`, `jq_unavailable` and null counts; counts are structural over `severity`, so `pass` beside a non-zero `hard` is unreachable. `catch-up-claim.sh` and `prepare-publication.sh` map it to `scan_unreadable`. `drive/scripts/land-unit.sh` routes through the gate with a `refuse` arm above every block arm and above `--override-scan`, and a mandatory `*)`; `scan_verdict` stays `pass | overridden`. `publish-tree-pr.sh` reads the scan raw with a `*)` → `scan_unreadable`.

## Version Management

Releases name selected committed changes, not completed missions. Version publication, deployment and production activation are distinct.

Version bumps are manual (no `/release` command). After bumping and pushing to `main`, CI (`.github/workflows/release.yml`) publishes the GitHub Release.

Version files (all at the same semver; `.claude-plugin/marketplace.json` is the source of truth):

1. `.claude-plugin/marketplace.json` — root `version` AND every `plugins[].version` (workaholic, workflows)
2. `plugins/workaholic/.claude-plugin/plugin.json`
3. `plugins/workaholic/.codex-plugin/plugin.json`
4. `outputs/workflows/.codex-plugin/plugin.json` — generated; rebuild with `build.mjs`, never hand-edit

Bump PATCH by default, update 1-3, regenerate 4, commit as `Bump version to v{new_version}`.

**A bump is checked against the base twice.** `check-version-bump.sh` answers `already_bumped` and `version_ahead` (field-wise semver, `null` when unreadable). `/story` Phase 0 bumps unless both hold; `/drive` §6 re-reads before merge and re-bumps when the base has overtaken the branch. It is a repair, never a gate. Motivation: five consecutive merges carried two versions between them; those collided numbers are recorded and left, and the next bump names the current `main`.
