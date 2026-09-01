---
type: Term
title: Core Concepts
description: The vocabulary of the system itself — what a plugin, a skill, a claim and a unit mean here
category: developer
last_updated: 2026-08-13
---

# Core Concepts

The vocabulary of the system itself. A term earns an entry here when this project
uses it in a way a competent reader would otherwise have to guess at.

## plugin

A plugin packages Claude Code extensions — commands, skills, rules, hooks — into one
distributable unit. **This repository ships exactly one**, `workaholic`, authored under
`plugins/workaholic/` with its metadata in `.claude-plugin/plugin.json` and
`dependencies: []`. Every skill reference inside it is same-plugin: the
`workaholic:<name>` namespace, or `${CLAUDE_PLUGIN_ROOT}/skills/<name>/...` for a script
path. It is not a collection of cooperating plugins — the single-plugin shape is what
makes "never guess a namespace" enforceable. Related terms: command, skill, rule, hook,
marketplace.

## marketplace

The marketplace is the distribution manifest a host agent reads to install plugins.
`.claude-plugin/marketplace.json` is Claude Code's and is the **version source of
truth**; `.agents/plugins/marketplace.json` is Codex's and points at the generated
`outputs/workflows` bundle. A marketplace entry is not a plugin: the `workflows` entry
is generated output, which is why it carries `"strict": false` and deliberately has no
`plugin.json`. Related terms: plugin, bundle.

## command

A command is a user-invocable slash action — `/ticket`, `/drive`, `/report`. Each is a
markdown file in `plugins/workaholic/commands/`, and each is **thin by rule**: a few
lines naming the skill, the section, and the entry-point contract. Knowledge never lives
in a command. A command is Claude-only; other agents reach the same work through the
skills. Related terms: skill, plugin, subagent.

## skill

A skill is the durable knowledge unit — templates, rules, and scripts — loaded by name
rather than invoked by a user. Each lives at `plugins/workaholic/skills/<name>/` with a
`SKILL.md` (~50-150 lines), an optional `scripts/` directory, and an optional
`reference/` directory for overflow. A skill may load another skill; it may never invoke
a command. Related terms: command, preload, reference, subagent.

## rule

A rule is a persistent constraint on behavior rather than a procedure to run — coding
standards, shell conventions, interaction limits. Rules live in
`plugins/workaholic/rules/` (`diagrams`, `general`, `interaction`, `shell`, `typescript`,
`workaholic`). A rule states what must hold; a skill states how work is done. Related
terms: plugin, skill, hook.

## hook

A hook is a callback the host agent runs at a point in the tool lifecycle, configured in
`plugins/workaholic/hooks/hooks.json` (whose only top-level key is `hooks`). This
repository uses four kinds: `PostToolUse` validators that floor what gets written
(tickets, missions, stories, feedback records, strategies), `PreToolUse` guards that
refuse an off-policy action before it happens (commit subject, branch name, working
directory, repository confinement, ticket moves), and a `UserPromptSubmit` lens that
injects context (the policy lens). A hook is registered by the host,
so a session with no plugin binding runs the scripts but not the hooks. Related terms:
rule, lens, guard.

## subagent

A subagent is a Claude Code sub-process with its own context window, spawned with the
`Task` tool. This repository ships **no agent files at all**: every fan-out uses
`subagent_type: "general-purpose"` with a prompt naming the skill to preload, the
section, the inputs and the return schema. Fan-out is **one level** — a subagent cannot
nest another and cannot ask the user a question, so all interaction happens at the
command level and leaves return JSON. Related terms: skill, preload, context-window.

## preload

Preloading is how a skill's content reaches a subagent at spawn time: the prompt names
the skill, and its `SKILL.md` is in context before the subagent starts. It is the only
sanctioned way a leaf gets knowledge — a subagent never invokes a command to get it.
Related terms: skill, subagent.

## lens

A lens is context injected into a session rather than requested by it. One ships active:
the **policy lens** (`policy-lens.sh`) puts the engineering-policy index in front of any
command carrying the `workaholic:policy-lens` sentinel. The **mission lens** was retired
on 2026-08-26 — its roster surfacing lives on in the bare `/mission` roadmap and
`/moderate`'s closable-missions step. A lens informs; it never forces.
Related terms: hook, pillar, mission.

## pillar

A pillar is one of the six engineering-policy domains this project distributes —
planning (企画), design (設計), implementation (実装), operation (運用), safety (安全)
and development (開発). Each is a skill holding English hard copies of the canonical
articles under its own directory, indexed by that skill's `SKILL.md`. A ticket's
mandatory policy list names the specific documents its work answers to, and the driver
opens each one before writing code. Related terms: lens, skill, ticket.

## executor

The executor is the single component that drains the ticket queue. It has **two entry
points and one run**: `/drive` (attended — it asks exactly one thing, which units to
take) and `/implement` (unattended — no question at any step). Attendance is a property
of which command was invoked, never of a terminal or an environment variable. Related
terms: unit, claim, drive.

## unit

A unit — a **PR-unit** — is what deserves one merge. One unit maps to exactly one claim,
one branch, one worktree and one pull request. A claimable mission is always one unit;
related backlog tickets group into a `batch-<timestamp>` unit only on a reason statable
in one sentence. Merge policy is never a grouping input. Related terms: claim, mission,
merge-policy, executor.

## claim

A claim is how a runner takes a unit **visibly**, so concurrent runners do not collide:
a `Claim <unit-id>` commit pushed on a `work-*` branch. **The repository is the
coordination medium** — unmerged remote branches are the only claim oracle, a merge
releases a claim by definition, and the push (never a clock) settles a race. The
heartbeat is the branch tip; staleness is reported and never acted on. A claim is not a
lock file and not a database row. Related terms: unit, worktree, heartbeat, work-branch.

## heartbeat

The heartbeat is the claim branch's tip time — refreshed by an empty commit, or for free
by any archive commit. A lapsed heartbeat makes a claim **resumable by its own author**;
a colleague's claim is untouchable at any age. It measures liveness, not progress.
Related terms: claim, resume.

## worktree

A worktree is a second checkout of this repository on its own branch, at
`.worktrees/<unit-id>/`. Worktrees are **claim-born and ship-torn**: the claim creates
one, the ship (or an explicit claim release) removes it, and all of a unit's work happens
inside it. `.worktrees/` and `.publish/` sit inside the repository root, so they belong
in any archiver's ignore list. Related terms: claim, publish-tree, unit.

## publish tree

The publish tree is how an artifact writer publishes **without a claim**: a checkout of
`origin/main` at git-ignored `.publish/` on local branch `publish-main`. `/ticket`,
`/mission` and `/propose` open it, write, push behind a pull request, and close it — the
caller's own checkout is left byte-identical. It is the counterpart of a worktree: a
worktree is for driving work, a publish tree is for publishing artifacts. Related terms:
worktree, claim, ticket, mission.

## merge policy

`merge_policy` is a field recorded **at creation** on a mission or a ticket, with two
values and one default: `auto` merges unattended through the ship flow, `review` merges
its pull request as soon as the report opens it and the branch-safety scan passes, and
**absent means `review`**. A batch unit is `auto` only if every member says so. It
answers "may this merge without a human deciding", never "may this deploy". Related
terms: unit, ship, gate, scan.

## gate

A gate is a check the run **may not override**. Three kinds sit on the path to a merge: a
ticket's `## Quality Gate` (acceptance criteria plus the verification that proves them),
the branch-safety scan's findings, and a deployment target's confirmation method. A
`secret` finding hard-stops; an overridable finding demotes an `auto` unit to the pull
request path rather than being waved through, because the override is a human ruling an
unattended run does not have. Related terms: scan, merge-policy, quality-gate.

## routine

A routine is a Claude Code Web schedule that fires a prompt on a cron expression. This
project ships **two per repository** — `[Propose]` hourly at `15 * * * *` and
`[Implement]` hourly at `30 * * * *` — and a routine template is a thin pointer: it
carries the command, the post format and the environment, never a rule. A routine cannot
subscribe to a repository event, which is why `[Propose]` discovers its own asks. Do not
add a third. Related terms: command, executor, propose.

## OKF

OKF (Open Knowledge Format) is the bundle convention `.workaholic/` conforms to: every
knowledge artifact carries a non-empty `type:`, and each area's `index.md` is
regenerated rather than hand-written. **Tickets are the deliberate exception** — no
`type:`, and their internals are never index-managed. Related terms: artifact, index,
frontmatter.

## TiDD

TiDD (Ticket-Driven Development) is this project's premise: the **ticket** is the unit of
work and the single source of truth for what should change and what happened. Sources
fill `tickets/todo/`, one executor drains it to `tickets/archive/`, and everything else —
missions, stories, release notes — hangs off that spine. Related terms: ticket, executor,
mission.

## context window

A context window is the isolated conversation memory an agent has while it runs. Work is
delegated to a subagent precisely to spend a fresh one on a bounded task and return a
small result, keeping the orchestrating conversation legible. Related terms: subagent,
preload.

## Retired vocabulary

Names this project once used and no longer has — the two-plugin architecture, its agent
tiers and its scan pipeline — are recorded with their dates and successors in
[retired-terms.md](retired-terms.md), not here. A current-vocabulary record that still
defined them would teach a reader words that match nothing they can find.
