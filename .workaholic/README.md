---
type: Guide
title: Work
description: Working artifacts hub for the workaholic plugin — what lives here and where to enter
category: developer
---

# Work

This is the working artifacts hub for the `workaholic` plugin. The tree is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) bundle: enter at [index.md](index.md) (regenerated automatically by the workflows) and every knowledge document carries frontmatter with a `type` key — tickets are the exception: the queue is not index-managed and a ticket carries no `type`.

## Which kind of artifact — feedback, ticket, or mission

Three kinds carry inbound intent, and they are only distinguishable because the middle one has a lower bound. Pick by *what you have*, not by how important it feels:

| You have | Write | Why not the others |
| -------- | ----- | ------------------ |
| A direction, a conclusion, an instruction, customer material — no unit of work yet | a **feedback record** (`/fb`) | A mission with no tickets is a feedback record on the roadmap, carrying a progress bar over nothing |
| One drive-able unit of work | a **ticket** (`/ticket`) | A mission around one ticket is a ticket with a board, a progress fraction and a close decision bolted on |
| Two or more tickets that only make sense driven together | a **mission** (`/mission`) | Splitting them loses the shared acceptance the batch is judged by |

**A mission is created with two or more tickets, or it is not a mission** — the ticket floor, checked at the seam that publishes a mission and its tickets together, so a sub-floor one is refused before it exists and the refusal names which of the other two to write (`workaholic:mission`, *Granularity → The ticket floor*). It is a rule about **creation**: `missions/archive/` holds one pre-rule single-ticket mission, which stays exactly as it is.

- [deployments/](deployments/index.md) - Deployment targets and confirmation methods `/ship` executes
- [feedbacks/](feedbacks/index.md) - The inbound feedback stream: one **immutable** record per entry (`kind`: insight / instruction / concern / material / answer; `source`: meeting / slack / discussion / development; `subject`: **whose opinion it is**, `<kind>[:<identity>]` over the closed kind set person / meeting / observer_ai / customer / team / other — a different question from `source`, the channel, and from `author`, the identity that ran the capture; required on records written since 2026-08-13, never defaulted, and never backfilled onto older ones), written by `/fb` (conclusions/instructions), `/propose` (**one record on every run**, whatever the run judges — the stream's highest-volume writer), `/ship` (`kind: concern` records extracted from shipped stories), and `/report` (superseding resolution records). Never edited or moved after writing — resolution is a new record naming the old one via `supersedes` — so consumers track "new" by commit cursor and the open concern set is computed as "not superseded"
- [guides/](guides/) - User documentation
- [missions/](missions/index.md) - Optional, epic-equivalent groupings of **two or more tickets** (the ticket floor — see the partition below), with acceptance progress, a data-driven duration record (`predicted_hours` stamped once at creation from the archived-mission trend, `actual_hours` accumulated by `/drive` across runs), and an append-only changelog. In-flight missions live under `missions/active/` on the one in-flight `status: active`, ended ones under `missions/archive/` (`achieved`/`abandoned`/`carried`, moved by `/mission-close`, which performs the archive move only). There is no draft gate and no `approve` subcommand: `merge_policy` (`auto` | `review`; absent reads as `review`) is recorded **at creation**, and **merging the mission's pull request is the approval**. Creating a mission with `/mission "<title>"` interrogates the developer — direction, the demanded experience, and the ticket plan — then **publishes onto a `work-*` branch behind a pull request, in one commit**, the mission statement and the **whole** ordered ticket set it emitted; under two tickets it is not published at all, and the refusal names what to write instead. It creates no worktree and no branch of its own (a worktree is claim-born, made by `/drive`'s `claim.sh` when it takes the mission as a PR-unit), and an abandoned interrogation publishes nothing. The plan is not one-shot: `/mission <instruction referencing an existing mission>` (no subcommand) **replans** it — re-enters the interrogation scoped to what changed, applies the delta, and emits delta tickets, published the same way; this is also how a thin mission or a `carried` successor gets its tickets. Each claim worktree is assigned a unique local port base so several can run dev/docs servers at once without colliding — written to the worktree's `.env` when the project carries one, else to a separate `.env.worktree` (a bare root `.env` holding only port vars is never fabricated). Auto-rolled by `/drive`, `/report`, and `/ship` as missioned work lands; surfaced read-only in `/catch`, which also shows unmerged in-flight work heading toward each mission, and in the bare `/mission` roadmap. Execution is the one executor's, reached through **`/drive`** (attended) or **`/implement`** (unattended): its survey picks up every claimable mission and drives each claimed PR-unit in that claim's worktree, opening a PR per unit and routing it by the mission's recorded `merge_policy` — `auto` goes through `/ship`'s deploy-and-confirm doctrine, `review` merges its PR as soon as `/report` opens it and the branch-safety scan passes, a scan finding being the one thing that leaves it open. Worktree teardown rides the claim — ship or an explicit claim release — never `/mission-close`. What a run learns is written back as feedback records rather than onto the mission, so the next planning reads one stream instead of per-mission notes
- [policies/](policies/) - Project-local policy documentation
- [release-notes/](release-notes/index.md) - Per-branch release notes: one per shipped **unit** branch, written by `/ship` just before the merge
- **releases/** (the directory appears at the first release cut) - Per-`release/*`-branch **ship records**: which `main` commits a release carried, when it was cut, when it was confirmed or failed. Written only by the promotion pipeline (`ship/scripts/record-release-cut.sh` at the cut, `confirm-release.sh` at each confirmation attempt) and derived from git, never hand-authored. Distinct from `release-notes/` — that is one note per shipped unit, this is one record per production release, and a failed confirmation is recorded rather than erased
- [specs/](specs/index.md) - Technical specifications
- [stories/](stories/index.md) - Development narratives and PR descriptions per branch
- [strategies/](strategies/index.md) - **Outbound, resolved direction**: one flat `<slug>.md` per strategy, carrying an **Aim** (what is being pursued), a **Schedule** (`target_date`, a real date) and an **Assignee** (non-empty `assignees` — the one artifact where empty is a refusal rather than team-owned). Operator-authored through `workaholic:strategy`'s `create.sh`; no command, hook or routine writes one, and `/drive` never surveys it. It is the complement of `feedbacks/`, not a second copy: the stream records what someone **said** (inbound, immutable), a strategy records what the operator **decided**, and the citation link runs one way (strategy → feedback) so the two homes cannot drift into rival inboxes. Retired 2026-07-28 as an open-ended `## Direction` artifact with no completion condition and re-introduced 2026-08-13 in this bounded/dated/owned shape; ended with `close.sh` (`achieved`/`abandoned`), which does not move the file
- [terms/](terms/index.md) - Consistent term definitions across the project
- [tickets/](tickets/) - Implementation work queue and archives (`todo/`, `archive/`, `icebox/`, `abandoned/`). A new ticket is **published onto a `work-*` branch behind a pull request** at creation — by `/ticket`, by `/mission` (its whole ordered ticket set at once), or by `/propose` — written and committed inside a publish tree checked out at `origin/main`, without touching the developer's own branch or uncommitted work; merging that pull request is what puts it on `main` and into the queue every runner surveys. A ticket taken by a runner then carries a `claim: <branch>` stamp written on that runner's claim branch; a stamp that reaches `main` (through a merged handoff PR) is history, not a claim — the unmerged-branch scan is the only claim oracle (the claim protocol; `/drive`'s `list-claims.sh`)
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
