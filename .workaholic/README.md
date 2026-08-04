---
type: Guide
title: Work
description: Working artifacts hub for the workaholic plugin — what lives here and where to enter
category: developer
---

# Work

This is the working artifacts hub for the `workaholic` plugin. The tree is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) bundle: enter at [index.md](index.md) (regenerated automatically by the workflows) and every document carries frontmatter with a `type` key.

- [deployments/](deployments/index.md) - Deployment targets and confirmation methods `/ship` executes
- [feedbacks/](feedbacks/index.md) - The inbound feedback stream: one **immutable** record per entry (`kind`: insight / instruction / concern / material / answer; `source`: meeting / slack / discussion / development), written by `/fb` (conclusions/instructions), `/ship` (`kind: concern` records extracted from shipped stories), and `/report` (superseding resolution records). Never edited or moved after writing — resolution is a new record naming the old one via `supersedes` — so consumers track "new" by commit cursor and the open concern set is computed as "not superseded"
- [guides/](guides/) - User documentation
- [missions/](missions/index.md) - Optional, epic-equivalent groupings of tickets — **created with two or more tickets, or it is not a mission** (the *ticket floor*, `workaholic:mission` → *Granularity*). That lower bound is what keeps the three artifact kinds distinguishable: a bare direction with no work attached is a **feedback record**, a single unit of work is a **plain ticket**, and a mission is what groups two or more of them. Without it a ticketless mission is a feedback record on the roadmap and a one-ticket mission is a ticket with a progress bar. The floor is counted at the **publish seam**, where the mission and its tickets become one artifact, and every creation seam refuses below it, naming which of the other two artifacts to write instead. Each mission carries acceptance progress, a data-driven duration record (`predicted_hours` stamped once at creation from the archived-mission trend, `actual_hours` accumulated by `/drive` across runs), and an append-only changelog; in-flight missions live under `missions/active/` (`status: active` — the single in-flight state since 2026-07-31, when `draft`/`approved` were retired because **merging a mission's pull request is its approval**) and ended ones under `missions/archive/` (`achieved`/`abandoned`/`carried`, moved by `/mission close`, which performs the archive move only and is the only status flip that exists). `merge_policy` (`auto` | `review`; absent reads as `review`) is recorded at **creation**, not at a separate approval step. Creating a mission with `/mission "<title>"` interrogates the developer — direction, the demanded experience, and the ticket plan — then **publishes onto a `work-*` branch behind a pull request, in one commit,** the mission statement and the **whole** ordered ticket set it emitted; it creates no worktree and no branch to drive (a worktree is claim-born, made by `/drive`'s `claim.sh` when it takes the mission as a PR-unit), and an abandoned interrogation publishes nothing. The plan is not one-shot: `/mission <instruction referencing an existing mission>` (no subcommand) **replans** it — re-enters the interrogation scoped to what changed, applies the delta, and emits delta tickets, published the same way; this is also how a `carried` successor gets its tickets. Each claim worktree is assigned a unique local port base (in its `.env`) so several can run dev/docs servers at once without colliding. Auto-rolled by `/drive`, `/report`, and `/ship` as missioned work lands; surfaced read-only in `/catch`, which also shows unmerged in-flight work heading toward each mission, and in the bare `/mission` roadmap. Execution itself is `/drive`'s and only `/drive`'s: its survey picks up every claimable active mission at once — one it owns or that is unowned, with a plan and a queued ticket — and drives each claimed PR-unit in that claim's worktree, in parallel, opening a PR per unit and routing it by the mission's recorded `merge_policy` (merge stays `/ship`; worktree teardown rides the claim — ship or an explicit claim release — never `/mission close`). What a run learns is written back as feedback records rather than onto the mission, so the next planning reads one stream instead of per-mission notes
- [policies/](policies/) - Project-local policy documentation
- [release-notes/](release-notes/index.md) - Per-branch release notes: one per shipped **unit** branch, written by `/ship` just before the merge
- [releases/](releases/index.md) - Per-`release/*`-branch **ship records**: which `main` commits a release carried, when it was cut, when it was confirmed or failed. Written only by the promotion pipeline (`ship/scripts/record-release-cut.sh` at the cut, `confirm-release.sh` at each confirmation attempt) and derived from git, never hand-authored. Distinct from `release-notes/` — that is one note per shipped unit, this is one record per production release, and a failed confirmation is recorded rather than erased
- [specs/](specs/index.md) - Technical specifications
- [stories/](stories/index.md) - Development narratives and PR descriptions per branch
- [terms/](terms/index.md) - Consistent term definitions across the project
- [tickets/](tickets/) - Implementation work queue and archives (`todo/`, `archive/`, `icebox/`, `abandoned/`). A new ticket is **published to `main`** by `/ticket` at creation — written and committed inside a publish tree checked out at `origin/main`, so it reaches the queue every runner surveys without touching the developer's own branch or uncommitted work, and without cutting a branch. A ticket taken by a runner then carries an optional `claim: <branch>` stamp on that runner's claim branch only — never on `main` — so the set of units in flight is readable straight from the unmerged remote branches (the claim protocol; `/drive`'s `list-claims.sh`)
- [trips/](trips/index.md) - **Legacy, read-only.** Design/decision artifacts from the retired `/trip` command; no writer since 2026-07-28 (design discussion moved to `feedbacks/`, decomposition to `missions/`, execution to `/drive`). Kept as history — knowledge is never deleted

For the full per-artifact lifecycle (who writes it, when, and how it survives or is eliminated through the ship process), see the **Artifacts under `.workaholic/`** section of the [root README](../README.md).

## Orchestration Throughput KPI

`/catch` surfaces a commit-count **orchestration-throughput KPI** (`gather/scripts/commit-kpi.sh`), derived from git history on demand — there is no stored metrics file. It measures how well a fleet of coding agents is orchestrated and kept running (agent-authored commit count and share, median/p90 changed lines, and how many commits exceed the per-commit granularity cap), **not** any person's output. The commit is a comparable unit only because the release-scan changed-lines gate normalizes per-commit size. Two guards are part of the definition: quota consumed only to raise the number is worthless (`development/weekly-quota`), and history is never reshaped to improve it — no squash/rebase grooming (`development/commit-change-history`).

## Design Policy

### Cultivating Semantics

Developer cognitive load is the primary bottleneck in software productivity. Workaholic invests heavily in generating structured knowledge artifacts to reduce this load. The trade-off is intentional: more upfront work creating documentation pays dividends in reduced context-switching, faster onboarding, and better decision-making.

Each artifact type serves a specific cognitive purpose:

| Artifact   | Purpose                           | Reduces cognitive load by...           |
| ---------- | --------------------------------- | -------------------------------------- |
| Tickets    | Change requests (future and past) | Capturing intent before implementation |
| Specs      | Current state snapshot            | Providing authoritative reference      |
| Stories    | Development narrative             | Preserving decision context            |
