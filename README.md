# Workaholic

The development workflows we use at [qmu](https://github.com/qmu), written down so our coding agents can run them the way we do. They're tuned to how we work, so they may not fit everyone, and they'll keep changing as we do. We keep it public so the people we work with can share the same base.

**Concretely**, it's a cross-agent distribution of structured development workflows and engineering-standard skills: ticket-driven development, AI-collaborative exploration, and the `leading-*` policy lenses. It's richest on **Claude Code** (a plugin marketplace: slash commands, hooks, `/trip` Agent Teams); the same skills install on **Codex**, **OpenCode**, and 40+ other agents via the [Agent Skills standard](https://skills.sh). Authored once under `plugins/`, generated into portable artifacts under `dist/`.

> [!WARNING]
> **This drives git on your behalf.** Workaholic lets your coding agent autonomously create branches, commit, amend, push, and open pull requests. Review the plugin/skill descriptions below before installing so you know what to expect.

## Quick Start (Claude Code)

```bash
claude
/plugin marketplace add qmu/workaholic
```

Enable the plugins you want after installation. Auto update is recommended. For Codex, OpenCode, and other agents, see [Use with other coding agents](#use-with-other-coding-agents) below.

## Use with other coding agents

Workaholic follows the cross-agent [Agent Skills standard](https://skills.sh). What's portable:

- **`standards`** — the four `leading-*` policy lenses (pure prose, self-contained). Available on every Agent-Skills agent.
- **`write-release-note`** — release-note structure guidance (pure prose).
- **Workflows** — `create-ticket`, `drive`, `report`, `ship` as agent-neutral skills (`trip` stays Claude-only; it needs Agent Teams). On non-Claude agents the workflow runs the same steps without Claude's parallel subagents/`AskUserQuestion` — see each skill's **Agent Compatibility** note.

### Install matrix

| Agent | How |
| ----- | --- |
| **Claude Code** | `/plugin marketplace add qmu/workaholic` (slash commands `/ticket`, `/drive`, `/report`, `/ship`, `/trip`) |
| **OpenAI Codex** | `codex plugin marketplace add qmu/workaholic --ref main`<br>`codex plugin add standards@workaholic`<br>`codex plugin add workflows@workaholic` |
| **Cursor / OpenCode / Pi / 50+** | `npx skills add qmu/workaholic` (exposes `standards` + `workflows`) |

### How the workflows reach other agents

The workflow skills share helper scripts across `plugins/core` via the Claude-only `${CLAUDE_PLUGIN_ROOT}` token, so they are not self-contained in source. `scripts/build-plugins` generates **self-contained** copies (each skill bundling its own scripts, references rewritten to relative paths) and assembles one neutral, committed plugin under `dist/workflows/`. That single dir serves every non-Claude agent: Codex via `.agents/plugins/marketplace.json` (and the co-located `.codex-plugin/plugin.json`), and OpenCode/Cursor/40+ via the `skills` CLI reading the `workflows` entry in `.claude-plugin/marketplace.json`. Regenerate after changing a core workflow skill:

```bash
node scripts/build-plugins/build.mjs   # regenerate dist/workflows artifacts (no args = full build)
node scripts/build-plugins/verify.mjs  # assert every script reference resolves
```

The `plugins/core` source stays Claude-Code-only (`metadata.internal: true`, `${CLAUDE_PLUGIN_ROOT}`); the committed `dist/workflows/` artifacts are the public, portable versions, kept in sync by the `Dist Freshness` CI check. The **`work`** plugin's commands/hooks/Agent Teams remain Claude-Code-only.

## Plugins

### Core

Shared commands that work across all workflows. Auto-detects your development context from the current branch pattern.

| Command    | What it does                                          |
| ---------- | ----------------------------------------------------- |
| `/report`  | Context-aware: generate story or journey report and create PR |
| `/ship`    | Context-aware: merge PR, deploy, and verify           |
| `/scan`    | Full documentation scan                               |

### Standards

Repository structuring policy, qualitative agents, and documentation standards. This plugin has no commands — it provides agents and skills referenced by other plugins. Includes lead agents (a11y, db, delivery, infra, observability, quality, recovery, security, test, ux), manager agents (architecture, project, quality), and documentation writers (changelog, terms, specs, release notes).

### Work

Unified development workflow combining ticket-driven development (TiDD) and AI-collaborative exploration. Write implementation tickets, implement them serially with confirmation, generate PR stories, or launch Agent Teams for collaborative design.

| Command    | What it does                                          |
| ---------- | ----------------------------------------------------- |
| `/ticket`  | Plan a change with context and steps                  |
| `/drive`   | Implement queued tickets one by one                   |
| `/trip`    | Launch Agent Teams session for collaborative design   |

> [!NOTE]
> `/trip` requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to be set in your environment.

**Typical drive session:**

```bash
/ticket add dark mode toggle to settings page
/ticket support system preference detection
/drive                            # implement both, confirm each
/ticket fix flash of light theme on page load
/drive                            # fix discovered issue
/report                           # generate story + create PR
/ship                             # merge, deploy, verify
```

**Typical trip session:**

```bash
/trip design a real-time notification system for our web app
# Three agents collaborate:
#   Planner  — defines direction from user/stakeholder perspective
#   Architect — models system structure and boundaries
#   Constructor — designs implementation with engineering trade-offs
# All work happens in an isolated worktree branch
/report                           # generate journey report + create PR
/ship                             # merge, clean up worktree, verify
```

## How It Works

### Ticket-Driven Development

A ticket is a markdown file describing a change you want to make — the context, plan, and rationale. Run `/ticket your change request` and a coding agent explores both codebase and history, then writes the ticket for you. Committed alongside the code, tickets become searchable history for future coding agents.

Once tickets are queued, `/drive` implements them one by one with confirmation at each step. While one agent drives, others can keep creating tickets — no worktree overhead, just serial execution with clear commits.

When ready to deliver, `/report` generates changelogs and PR descriptions from the accumulated ticket history. Then `/ship` merges the PR, deploys following the `## Deploy` instructions in your project's `CLAUDE.md`, and verifies the deployment.

> [!NOTE]
> **A flavor of Spec-Driven Development**
>
> This follows [Spec-Driven Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) principles with distinct terminology:
>
> - **Ticket**: A change request describing what should be different (flowing, temporal)
> - **Spec**: Current state documentation describing what exists now (snapshot, persistent)
>
> Tickets drive implementation; specs document the result. Both are markdown, both are versioned, but they serve complementary purposes.

### AI-Collaborative Exploration

The `/trip` command launches an Agent Teams session where three agents with different perspectives collaborate to explore and develop a concept:

- **Planner** (Progressive) — Non-tech perspective: user value, stakeholder clarity, explanatory accountability
- **Architect** (Neutral) — Structural perspective: system coherence, abstraction quality, boundary integrity
- **Constructor** (Conservative) — Tech perspective: implementation feasibility, performance, maintainability

The session runs in two phases inside an isolated git worktree:
1. **Specification** — Agents produce direction, model, and design artifacts through mutual review
2. **Implementation** — Agents build, review, and test the agreed specification

## Artifacts under `.workaholic/`

Working artifacts live in [.workaholic/](.workaholic/README.md). Each artifact captures a snapshot of the code change at a specific point in the workflow — they are not generic documentation. The table below summarizes what gets stored, when it is written, and how it survives (or is eliminated) through the ship process.

### Lifecycle Reference

| Artifact | Written by | Snapshot of | Diffed on ship? | Carried over? | Eliminated when |
| -------- | ---------- | ----------- | --------------- | ------------- | --------------- |
| `tickets/todo/<ts>-*.md` | `/ticket` | Intended change (not yet implemented) | committed as a normal file | no | `/drive` archives it after approval |
| `tickets/archive/<branch>/*.md` | `/drive` (archive) | Implemented change with final report and commit hash | committed, permanent | no — permanent record | never (institutional history) |
| `tickets/icebox/*.md` | `/ticket --icebox` (or manual move) | Deferred change | committed | yes (survives across PRs until promoted) | `/drive` (after user promotes from icebox) |
| `tickets/abandoned/*.md` | `/drive` (abandon flow) | Attempted-then-abandoned change with failure analysis | committed, permanent | no | never |
| `stories/<branch>.md` | `/report` | PR description: overview, journey, outcome, concerns, ideas, release readiness | committed before PR creation | concerns/ideas sections only (extracted by `/ship`) | never (per-branch permanent record) |
| `release-notes/<branch>.md` | `/report` | Concise release narrative for GitHub Releases | committed after PR creation | no | never |
| `concerns/<pr>-<slug>-<kind>.md` | `/ship` (extract from story) | Unresolved concern or idea surfaced in a past PR | committed during ship | **yes — this is the carry-over corpus**; remains `status: active` until `/report` judges it resolved | judge marks `status: resolved` (file preserved, audit trail intact) |
| `trips/<branch>/*` | `/trip` | Multi-agent collaborative design output (planner/architect/constructor) | committed inside trip worktree | no | never |
| `specs/*.md` | manual (hand-edited reference) | Current-state documentation of how things work today | committed | n/a — not branch-scoped | superseded when manually rewritten |
| `guides/*.md` `policies/*.md` `terms/*.md` | manual | Persistent reference material (user docs, policies, glossary) | committed | n/a | superseded when manually rewritten |

### When, Where, and How Changes Occur

The branch lifecycle traverses these artifacts in a fixed order:

```mermaid
flowchart LR
  subgraph plan[Plan]
    direction TB
    a1[/ticket] --> a2[tickets/todo/]
  end
  subgraph implement[Implement]
    direction TB
    b1[/drive] --> b2[tickets/archive/<branch>/]
  end
  subgraph report[Report]
    direction TB
    c1[/report] --> c2[stories/<branch>.md]
    c1 --> c3[release-notes/<branch>.md]
    c1 -.judge.-> c4[concerns/]
  end
  subgraph ship[Ship]
    direction TB
    d1[/ship] --> d2[merge PR]
    d2 --> d3[extract carry-overs<br/>to concerns/]
  end
  plan --> implement --> report --> ship
  d3 -.next /report reads.-> c1
```

**Plan** — `/ticket` writes a new file under `tickets/todo/` describing the intended change. This is the only artifact created before code exists.

**Implement** — `/drive` reads `tickets/todo/`, implements one ticket at a time, and on approval moves the file to `tickets/archive/<branch>/`. The archive subdirectory is named after the current branch so all of a branch's tickets cluster under one folder. Final reports and the resolving `commit_hash` are written into the ticket frontmatter at archive time.

**Report** — `/report` runs after all tickets on a branch are archived. It does four writes in order:
1. Judges every active file in `concerns/` (carry-overs from past PRs) via a `general-purpose` carry-over-judge subagent. Resolved items are moved to `concerns/archive/`; still-active items are passed to the section-reviewer.
2. Writes `stories/<branch>.md` — the full PR description including section 6 (Concerns), each item prefixed with `(carried from PR #N)` if surfaced from the corpus.
3. Commits the story together with any `concerns/` status changes (including moves to `archive/`), so the audit history is coherent.
4. Opens the GitHub PR and writes `release-notes/<branch>.md`.

**Ship** — `/ship` merges the PR, then immediately extracts section 6 (Concerns) from the just-shipped story into `concerns/`, one file per item. Filenames use `<pr-number>-<slug>.md` (sidestepping the ticket validation hook); each file carries a `severity` label (`urgent`/`moderate`/`low`) in frontmatter and a Title / Description / How to Fix body. From that point on, those concerns are read on every subsequent `/report` until they are judged resolved and moved to `concerns/archive/`.

### What "Carried Over" Means

Most artifacts are written once and never revisited — they form the permanent history of the codebase. The exception is `concerns/`: it is the **only** living corpus, deliberately persistent across PR cycles so that risks and improvement ideas raised in one PR cannot silently vanish when the PR merges. Three forces keep the corpus from growing unbounded:

1. **Judge** — each `/report` re-evaluates active items and marks resolved ones.
2. **Promote** — items that survive judgement become housekeeping tickets after one cycle.
3. **Mark, don't delete** — resolved items remain on disk with `status: resolved` so the audit trail survives misclassification.

See [`.workaholic/concerns/README.md`](.workaholic/concerns/README.md) for the file format, frontmatter schema, and lifecycle script references.

## Author

tamurayoshiya <a@qmu.jp>
