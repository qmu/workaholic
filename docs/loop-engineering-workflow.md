# Loop Engineering Workflow — Reorganization Design

Status: **decided 2026-07-28** (design-elicitation session). Implementation has not
started; this document is the decision record and the gap analysis it came from.
When implementation begins, each phase becomes missions/tickets and the affected
docs (`CLAUDE.md`, `rules/*.md`, skill docs) are updated in those changes — this
document records the *direction*, not the final wording of every rule.

## 1. Vision

workaholic evolves from a per-developer Claude Code plugin into a **team
development engine**: a continuous loop in which humans supply feedback — design
discussions, meeting transcripts, Slack instructions, conclusions reached in AI
discussions — and the AI turns that feedback stream into proposed missions,
discusses them with the team in Slack, and implements approved missions
unattended.

Target workflow:

1. **Feedback capture** — each repository has a dedicated Slack channel (Claude
   Tag, backed by a Claude Code Web session with this plugin installed). Every
   clue, technical or not, is registered as a feedback artifact in the repo.
2. **Mission proposal** — a scheduled batch (~15 min) detects feedback newly
   merged to main, reads the stream against the current state, and drafts
   missions: registered, committed, and merged as **draft** missions.
3. **Discussion & approval** — the draft is proposed back in Slack ("here is the
   mission I intend to run — thoughts?"). The team discusses; approval flips the
   mission from draft to implementable.
4. **Unattended implementation** — a scheduled routine ("Drive Every 5
   Minutes") invokes `/drive`, which autonomously partitions all approved
   missions and backlog tickets into PR-worthy units, claims each unit on a
   pushed branch, implements it in its own worktree, reports, and — per the
   artifacts' recorded merge policy — ships or feeds the PR URL back to Slack.

Local interactive use survives unchanged: the same plugin keeps working in a
terminal session. The loop is an additional, headless driver over the same
`.workaholic/` artifacts, not a replacement surface. Likewise the standalone
ticket survives unchanged: a mission is an optional, epic-equivalent grouping,
never a required parent (decision B5) — `/ticket` → `/drive` with no mission
remains a fully sanctioned path.

## 2. What the current implementation already provides

The distance to the vision is shorter than it looks, because the execution half
already exists:

- **The implementation worker core is near-complete.** `/monitor` already runs
  missions long and unattended: front-loaded escalations, one leaf per mission
  worktree, bounded waves, PR auto-creation, reflection write-back, and an
  honest terminal token designed exactly for a `/goal /monitor ok` caller loop.
  (Second round: this machinery is **absorbed into the unified `/drive`** and
  `/monitor` itself is retired — G1.)
- **The approval concept exists** as `drive_authorized` — the draft→approved
  transition is a generalization of it, not a new idea.
- **The elicitation machinery exists** (`/mission` Creation Interrogation); in
  the new model its information source shifts from interactive developer
  interrogation to the accumulated feedback stream.
- **The artifact substrate exists**: the OKF-compatible `.workaholic/` tree,
  the closed-layout allowlist, `refresh-index.sh`, and the commit seams that
  roll missions give feedback artifacts a ready-made home and lifecycle.

## 3. What does not exist yet

1. `feedbacks/` — the artifact type, its schema/hook/allowlist registration,
   and a capture skill.
2. The **proposal batch** — new-feedback detection, proposal judgment, draft
   mission creation, dedup.
3. The mission **draft state** and the approval transition (today a mission is
   made drive-ready interactively at creation).
4. **Slack round-trip** — inbound is Claude Tag; outbound (proposal
   notifications) has no channel today.
5. A **headless entry point** — every command today assumes an interactive
   session origin.
6. A **post-strategy ownership model** — today ownership derives from the
   strategy layer, which this reorganization abolishes.

## 4. Decisions (2026-07-28)

Asked and answered:

| # | Decision |
| - | -------- |
| A1 | **One feedback = one file** under `feedbacks/`, plus a maintained `index.md`. No single append-only `feedback.md`: parallel Slack-origin writers would collide, and per-file `type` frontmatter keeps OKF conformance. |
| B3 | **The strategy layer is abolished.** Long-lived direction is carried by the feedback stream itself; missions become the top work artifact. |
| B4 | **`assignees` returns to `mission.md`** (optional, plural). The approver becomes the default owner; an unassigned mission is team-owned and eligible for the worker. Local `/monitor` keeps its "my missions" scope through this field. |
| C1 | **Server cron + headless claude first.** Complete the loop on this machine's cron; port to Claude Code Web scheduling afterwards. |
| D3 | **The merge gate is a per-mission choice**, confirmed at approval time and recorded in mission frontmatter (working name `merge_policy: auto \| review`). `review` stops at the PR for human check-then-merge; `auto` proceeds to merge — still through the `/ship` doctrine (deploy + verify **before** merge, evidence-gated). Mission approval itself always stays human. |
| E2 | **Outbound Slack via a dedicated bot token.** AI proposals appear as the bot, distinct from human speech. Inbound stays Claude Tag. |
| A5 | **Meeting-transcript ingestion is out of scope for now.** The first loop is Slack-origin feedback only; the kioku (minutes MCP) pathway is a later phase. |
| B5 | **Mission membership is optional — the ticket stays the first-class standalone unit** (decided 2026-07-28, after phase-1 kickoff). This confirms what the mechanism already does (`mission:` on a ticket is optional at every layer: `/ticket` offers "None", `validate-ticket.sh` checks only a present value, `/drive` runs unmissioned tickets with the per-ticket prompt) and revises the *framing*: a mission is the **epic-equivalent, optional grouping** of a batch of tickets for management and efficiency — typically pre-built as a dozen-odd tickets and executed together overnight — never a required parent. Two equally sanctioned modes: (1) build a mission's ticket set and run it as a batch; (2) create and drive single tickets with no mission at all. The 2026-07-21 "overnight-executable execution plan of a strategy" definition is superseded on both ends — the strategy end by B3, the mandatory-sounding end by this row; ticket `20260728183203`'s docs sweep records the redefinition in the mission skill. |

Defaults decided without asking (veto anytime):

| # | Default |
| - | ------- |
| A2 | Feedback frontmatter: `type: Feedback` plus `source` (meeting/slack/discussion), `author`, date-derived slug. Details fixed at ticket time. |
| A3 | Feedback files are **immutable records**; the proposal batch tracks "new" via a processed-cursor (last-processed commit), never by mutating feedback frontmatter. |
| A4 | `concerns/` stays separate: concerns are issues surfacing *from work*, feedback is input *from humans*. |
| B1 | Draft is `status: draft` in mission frontmatter; approval sets `drive_authorized: true` (+ `merge_policy`). The `validate-mission.sh` floor keeps firing only once authorized. |
| B2 | The approval flip is committed and merged by the Slack conversation session itself. |
| C2 | Detection is cursor + `git log` polling on main; webhooks later. |
| C3 | The batch proposes **new missions only** at first; replan proposals for existing missions are a second stage. |
| C4 | Dedup via the cursor plus a `feedback:` reference list on proposed missions (doubling as traceability from mission back to its source feedback). |
| D1 | ~~The worker is a cron job that detects approved-and-incomplete missions and fires the `/goal /monitor ok` loop.~~ **Superseded by G4** (2026-07-28, second round). |
| D2 | ~~Single worker + run-lock first; multi-worker claiming later if ever needed.~~ **Superseded by G3** — the claim protocol makes concurrent runners the design, not a later option. |
| E3 | Channel↔repository mapping config placement is a ticket-time decision. |
| F1 | **One plugin.** The `workaholic` plugin gains feedback/proposal skills and commands; all interactive commands remain, preserving local use. |
| F2 | Batch entry points are non-interactive commands designed on the `/monitor` model: front-load everything, never prompt mid-run. |
| F3 | The loop components are Claude-Code-only — no `outputs/` footprint. |
| F4 | This document is the decision record; phases below become missions/tickets. |

### Second round — `/drive` unification (2026-07-28, later session)

| # | Decision |
| - | -------- |
| G1 | **`/monitor` is retired; `/drive` becomes the sole executor.** One command picks up work whether invoked interactively or by the routine, identically on server and client. `/monitor`'s machinery is absorbed, not discarded: worktree-per-mission execution, honest completion reporting, PR auto-creation, and reflections move into `/drive`; its front-loaded pre-flight is replaced by creation-time policy frontmatter (G5) and the claim protocol (G3). |
| G2 | **No drive-time confirmation.** `/drive` autonomously partitions **all** current work — approved (`drive_authorized`) missions and backlog tickets alike — into **PR-worthy units**: a mission is one unit driven in its own worktree through to the report; related backlog tickets are batched into one unit sharing a single PR. The unit of selection is "what deserves one merge", and the selection is the agent's, not asked of a human. |
| G3 | **Claim protocol over pushed branches.** Before driving a unit the runner: (1) creates the worktree and flips the status of the claimed mission/ticket files, (2) commits and pushes that claim to a new branch. Every runner fetches and scans **unmerged remote branches** for claimed artifacts before picking, so a 5-minute tick — or a runner on another machine — never double-picks work already in flight. Replaces run-locks entirely; the repository itself is the coordination medium. |
| G4 | **"Drive Every 5 Minutes."** A scheduled routine invokes `/drive` continuously; newly approved missions and newly created tickets are detected, claimed, implemented, reported, and shipped per policy — the standing loop the whole model runs on. |
| G5 | **Merge policy is recorded per artifact at creation** (revises D3's mission-only placement). Every ticket- and mission-creation flow asks the developer whether the work may merge automatically, and stores the answer explicitly in frontmatter. At drive time the unit's effective policy is derived: all members auto-mergeable → ship automatically (deploy + verify evidence before merge, as always); any member review-flagged — or auto-mergeable work depending on review-flagged work — → stop at the PR and feed its URL back to Slack via the bot (E2). |

## 5. Strategy-layer removal — migration inventory

Abolishing `strategies/` touches every ownership consumer. The single-reader
design (`mission-owners.sh`) contains the blast radius:

- Retire the `strategy` skill (`create.sh`/`list.sh`/`read-strategy-relation.sh`/
  `retire.sh`/`read-assignees.sh`) and the `strategy:` relation on `mission.md`.
- `mission-owners.sh` derives from the mission's own `assignees` (the existing
  legacy `assignee` fallback already points the right way; it becomes the
  primary path).
- Consumers — mission-lens, `/monitor` scope, `summary.sh`, `list.sh`'s
  `relation`, `validate-mission.sh`'s authorized-owner floor, `ship`'s
  concern-lane owner — all read through `mission-owners.sh` and need no
  individual redesign.
- `/mission` creation stops resolving a strategy.
- Remove `strategies/` from `hooks/workaholic-layout-allowlist.txt` **and** the
  `rules/workaholic.md` table in the same commit (closed-layout lockstep rule).
- Living migration for existing `.workaholic/strategies/`: copy each strategy's
  `assignees` down to its missions, then archive the directory.
- Docs sweep: every mention of the strategy layer in `CLAUDE.md`, `README.md`,
  rules, and skill docs.

## 6. New components

### 6.1 `feedbacks/`

- `.workaholic/feedbacks/<YYYYMMDDHHMMSS>-<slug>.md`, one per feedback, plus
  `index.md` maintained by `refresh-index.sh`.
- Registered in the layout allowlist + rules table (same commit that first
  writes it).
- A `validate-feedback.sh` PostToolUse hook enforcing the frontmatter floor,
  mirroring the ticket/mission validators.
- A capture skill/command (working name `/feedback`) any session — Slack-backed
  or local — uses to register one; commits land directly on main (feedback is a
  knowledge artifact, like the existing knowledge-commit seams).

### 6.2 Mission draft state

- `status: draft` at proposal time; approval sets `drive_authorized: true` and
  `merge_policy`. No validator floor until authorized (unchanged behavior).
- Draft missions carry `feedback:` references to their source feedback.

### 6.3 Proposal batch

- Headless, non-interactive command (working name `/propose`), cron-scheduled
  (~15 min): advance the cursor over main, read new feedback against active
  missions and recent reflections, decide whether a mission is warranted, write
  the draft (commit + merge), notify Slack via the bot, record the cursor.
- Silence is a valid outcome; the batch never prompts.

### 6.4 Unified `/drive` and the routine (second round, G1–G5)

- `/drive` scans the repository state: approved missions, backlog tickets, and
  — via fetch + unmerged-branch scan — the claims already in flight (G3).
- It partitions the unclaimed remainder into PR-worthy units (mission = one
  unit; related backlog tickets batched into one), claims each unit (status
  flip + commit + push on a fresh branch), then drives each in its own
  worktree through implementation and report.
- Unit outcome per the artifacts' recorded merge policy (G5): all-auto →
  automated `/ship` (deploy + verify evidence before merge); otherwise → PR
  created and its URL posted to Slack.
- The "Drive Every 5 Minutes" routine (G4) is simply this command on a
  schedule; interactive invocation behaves identically.
- Needed pieces: a deterministic claim reader (enumerate unmerged remote
  branches, extract claimed artifact IDs), a stale-claim reclamation rule
  (an abandoned claim branch must not block its work forever), and the
  `/monitor` retirement sweep (command, docs, `/goal` loop references).

### 6.5 Slack integration

- Inbound: Claude Tag per-repo channel backed by Claude Code Web (target) /
  interactive sessions on this server (interim).
- Outbound: dedicated bot token; proposals and worker reports post as the bot.

## 7. Roadmap

| Phase | Content |
| ----- | ------- |
| 1 — Foundation | Strategy-layer removal + `assignees` restoration; `feedbacks/` artifact type + capture skill + validators + allowlist registration. Fully useful standalone (feedback works from local sessions too). |
| 2 — Proposal loop | Cursor detection, proposal judgment, draft missions, Slack bot notifications, dedup. Server cron. |
| 3 — Approval & autonomous `/drive` | Approval flip flow from Slack sessions; per-artifact `merge_policy` at creation (G5); `/drive` unification with claim protocol and PR-unit partitioning (G1–G3); `/monitor` retirement; the 5-minute routine (G4); automated `/ship` for all-auto units. |
| 4 — Platform | Claude Code Web port of both batches, kioku transcript ingestion, multi-repo rollout of per-repo channels. |

## 8. Open items (deferred, recorded here so they are not lost)

- kioku auto-ingestion design (which meeting belongs to which repo).
- Claude Code Web scheduling specifics for the two batches.
- Channel↔repo mapping config placement (E3).
- Replan proposals driven by feedback (C3 second stage).
- Stale-claim reclamation rule and the claim reader's exact mechanics (G3).
- How the batch-unit claim records its grouping (which tickets share the PR)
  so a later tick reads the same unit boundaries.
