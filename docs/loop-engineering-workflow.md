# Loop Engineering Workflow — the decision log

Status: **decision log, kept current by appending.** The loop-engineering
reorganization was decided 2026-07-28 (design-elicitation session) and has since
been implemented; the later rounds (fifth through eleventh, 2026-07-30〜2026-08-06)
were appended as they were ruled. Rows are cited by id (A1…P9) from `CLAUDE.md`,
the skills, and the runbooks — read this document for *why a rule is what it is*,
never for current behaviour, which lives in `CLAUDE.md` and the skill that owns
each flow. A superseded row is struck through or annotated in place, never
rewritten. §§1–3 and 5–8 are the planning material the first rounds came from,
kept as history rather than spec: they describe since-retired surfaces
(`/monitor`, the mission draft state, the 15-minute proposal batch, the strategy
layer) as they stood at decision time.

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
| A2 | Feedback frontmatter: `type: Feedback` plus `source` (meeting/slack/discussion), `author`, date-derived slug. Details fixed at ticket time. *(Third round: H2 adds the `kind` axis.)* |
| A3 | Feedback files are **immutable records**; the proposal batch tracks "new" via a processed-cursor (last-processed commit), never by mutating feedback frontmatter. |
| A4 | ~~`concerns/` stays separate: concerns are issues surfacing *from work*, feedback is input *from humans*.~~ **Superseded by H2** — concern becomes a `kind` of feedback; the distinction survives as the axis value, not as a separate artifact. |
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
| F3 | ~~The loop components are Claude-Code-only — no `outputs/` footprint.~~ **Corrected by I8** — the workflow skills stay cross-agent through `outputs/workflows`; only hooks/commands are structurally Claude-native. |
| F4 | This document is the decision record; phases below become missions/tickets. |

### Second round — `/drive` unification (2026-07-28, later session)

| # | Decision |
| - | -------- |
| G1 | **`/monitor` is retired; `/drive` becomes the sole executor.** One command picks up work whether invoked interactively or by the routine, identically on server and client. `/monitor`'s machinery is absorbed, not discarded: worktree-per-mission execution, honest completion reporting, PR auto-creation, and reflections move into `/drive`; its front-loaded pre-flight is replaced by creation-time policy frontmatter (G5) and the claim protocol (G3). |
| G2 | **No drive-time confirmation.** `/drive` autonomously partitions **all** current work — approved (`drive_authorized`) missions and backlog tickets alike — into **PR-worthy units**: a mission is one unit driven in its own worktree through to the report; related backlog tickets are batched into one unit sharing a single PR. The unit of selection is "what deserves one merge", and the selection is the agent's, not asked of a human. |
| G3 | **Claim protocol over pushed branches.** Before driving a unit the runner: (1) creates the worktree and flips the status of the claimed mission/ticket files, (2) commits and pushes that claim to a new branch. Every runner fetches and scans **unmerged remote branches** for claimed artifacts before picking, so a 5-minute tick — or a runner on another machine — never double-picks work already in flight. Replaces run-locks entirely; the repository itself is the coordination medium. |
| G4 | **"Drive Every 5 Minutes."** A scheduled routine invokes `/drive` continuously; newly approved missions and newly created tickets are detected, claimed, implemented, reported, and shipped per policy — the standing loop the whole model runs on. |
| G5 | **Merge policy is recorded per artifact at creation** (revises D3's mission-only placement). Every ticket- and mission-creation flow asks the developer whether the work may merge automatically, and stores the answer explicitly in frontmatter. At drive time the unit's effective policy is derived: all members auto-mergeable → ship automatically (deploy + verify evidence before merge, as always); any member review-flagged — or auto-mergeable work depending on review-flagged work — → stop at the PR and feed its URL back to Slack via the bot (E2). |

### Third round — feedback as the unified information stream (2026-07-28, later session)

| # | Decision |
| - | -------- |
| H1 | **The primary-source principle is unchanged by the Slack/GitHub surface.** Every piece of decision-bearing information — missions, tickets, stories, feedback, AI-generated or not — keeps its primary source as a file under `.workaholic/`. The Slack conversation itself is **not** recorded verbatim; what must materialize in the repository is its **agreements** (as missions/tickets), the development outcome (as stories/reports), and the leftovers and learnings (as feedback). Slack and GitHub are surfaces over the repository record, never the record. |
| H2 | **Concern merges into Feedback** (supersedes A4). Feedback gains a **`kind` axis** — `concern` (born from the development process), `insight` (knowledge/conclusions shared in discussion), customer-material kinds ("received file X from the customer", "customer answered Y"), … enum finalized at ticket time — making "feedback" the single concept for all project-context information that accrues over time. `.workaholic/concerns/` merges into `feedbacks/` (a migration like the strategy one, in a later ticket); the concern-specific lifecycle machinery (promotion floor, demotion, active/archive curation) retires with it — curation becomes the proposal batch's *reading* of the stream, and resolution/mootness is recorded as a **new superseding feedback** referencing the old, upholding A3 immutability. A story's section 6 remains the immutable in-branch record it is today. |
| H3 | **Timing: drive-born feedback is written when a carry-over decision is made** — never immediately at drive end, where a pre-merge fix could moot the entry. The concrete seams are exactly the existing carry-over decision points: `/ship`'s extraction step, `/carry`, and `/mission close` with `carried`. |
| H4 | **Customer materials flow through the same stream.** Files received from a customer land in the repository and are analyzed; the analysis results — and the questions that must be asked of, or answers received from, the customer — are recorded as feedback, so "what do we need to ask/answer" is always derivable from the corpus. |

### Fourth round — consistency sweep rulings (2026-07-28, later session)

| # | Ruling |
| - | ------ |
| I1 | **`/trip` is retired.** Its three roles are fully covered by the new model — design discussion by Slack, decomposition by the proposal batch (or `/ticket`), execution by the unified `/drive` — so the Agent Teams machinery goes with it: the `planner`/`architect`/`constructor` agent files, `trip-protocol`, the `trips/` area, and every trip mode in other commands. The executor surface becomes `/drive` alone. |
| I2 | **One mission state axis.** `status: draft \| approved \| achieved \| abandoned \| carried` becomes the single lifecycle; **`drive_authorized` is retired into `status: approved`** (approved = implementable, exactly the approval flow's vocabulary). `merge_policy` stays a separate, orthogonal axis (G5). The `carried`/reorganize-and-carry ceremony simplifies accordingly: replanning is something the proposal batch proposes from feedback, not a hand ritual. |
| I3 | **Mission `## Reflection` merges into feedback.** Drive-born learnings are `kind: concern`/`insight` feedback written at the carry-over seams (H3); the `append-reflection.sh`/`list-reflections.sh` channel and the reserved `concerns: []` mission key retire with the merger. One learning channel: the proposal batch reads the same stream the planners do. |
| I4 | **Rejected: removing the `/goal` dependency.** `/goal` stays part of the model; the honest terminal token keeps its `/goal`-caller design, and the 5-minute routine coexists with `/goal`-style in-session looping rather than replacing it. |
| I5 | **`/carry` is retired entirely** (not merely reduced). In-flight state lives on the claim branch by construction (G3) — the next tick re-claims and resumes from what is pushed; carry-over learnings are H3 feedback; resumption tickets as a dedicated command surface are no longer needed. **Implemented 2026-08-01**, and only then: the claim scan now derives a `resumable` verdict (same identity, heartbeat lapsed), `plan-units.sh` offers those units in `resumable[]`, and `claim.sh resume <unit-id>` takes one over at its pushed branch tip. Until that landed this row was aspirational — every claimed unit was dropped as `claimed` and refused as `already_claimed`, so nothing ever re-claimed anything, and `release-claim.sh` (which deletes the branch) was the only path anyone could reach. A unit ending in the `handoff` state is the shape a later run resumes. |
| I6 | **Worktree lifecycle unifies with the claim.** A worktree is born at claim time and torn down when its PR-unit ships; an unfinished mission is simply re-claimed by a later tick, which recreates the worktree from the pushed branch (`create-mission-worktree.sh --branch <claim-branch>`, so the resumed run continues from the surviving work rather than restarting at the base). `/mission close` loses its teardown role, and closure itself becomes automatic (or batch-proposed) once acceptance is fully met and merged. Detail design belongs to the phase-3 ticket. |
| I7 | **Agent-hours/KPI recording moves to `/drive`** with the rest of the absorbed `/monitor` machinery (`record-run-hours.sh` seam; G1 absorption list). |
| I8 | **Cross-agent compatibility is retained** (corrects the F3 default). The workflow skills — the unified `/drive` machinery included — keep shipping cross-agent through the generated `outputs/workflows` bundle; only the structurally Claude-native surfaces (hooks, commands, Agent-Teams remnants until I1 lands) stay Claude-only, as they always have. |
| I9 | **H4 presupposes a private repository.** Customer-material intake is only enabled where the repository is private; the constraint is recorded next to the intake flow, and the release-scan/leak-denylist relationship is documented with it (a public repo disables the H4 path). |

### Fifth round — publication to main (2026-07-30)

| # | Ruling |
| - | ------ |
| J1 | **Artifact creation publishes to `main`; the claim is the only creator of a branch or a worktree.** This completes I6. `/ticket` cutting a `work-*` branch and `/mission` building `.worktrees/<slug>/` before anything is written are the surviving remnants of the pre-claim design, and they strand the artifact on a local unpushed ref that no other runner, machine, or fresh clone can see — the concrete failure `docs/drive-loop-runbook.md` §6 documents. `/specificate` is the working proof that a source needs neither: it scaffolds into the main checkout, commits, pushes. Every source follows it. |
| J2 | **The publish tree is the mechanism, and publication never depends on or disturbs the caller's checkout.** `/specificate` can guard on "on `main`, clean tree, else abort" because it is a headless batch; `/ticket` and `/mission` cannot — a developer types them mid-work on a dirty branch, and aborting there would make the sources unusable exactly when they are most useful. So the artifact is written, committed, and pushed inside a dedicated, git-ignored **publish tree** (`.publish/`, on a fixed local `publish-main` branch, reset to `origin/main` on each open), and the caller's branch and uncommitted work are left byte-identical. A publish tree is **not** a claim worktree: it holds no unit, is never pushed as a branch, and is disposable at any moment. |
| J3 | **Publishing to `main` is necessary but not sufficient — the executor must survey a current `main`.** `plan-units.sh` reads claims from git refs but artifacts from the local working tree, and nothing in `/drive` fast-forwards it. A runner whose `main` trails `origin/main` silently surveys yesterday's queue, which on a 5-minute tick looks healthy and does nothing. `/drive` fast-forwards before surveying (`sync-main.sh`), reports every reason it could not, and may emit `ok` only over a survey it knows was current. |

*(J4 — artifact publication moved from direct-to-`main` onto a `work-*` branch behind a pull request, 2026-08-01 — is recorded in `CLAUDE.md`'s claim-protocol section, where the publish-tree mechanics live.)*

### Sixth round — the mission draft gate (2026-07-31)

| # | Ruling |
| - | ------ |
| K1 | **Retire `status: draft`; merging the pull request is the approval.** J4 put every mission behind a PR, so a mission's necessity and content are judged *before* it reaches `main` — and `draft` then gates the same content a second time, requiring a manual `/mission approve` to undo the first gate. The observable cost was six active missions on `main`, every one unclaimable, and `/drive` reporting `pending` tick after tick with nothing it could touch. **The surviving vocabulary is `status: active \| achieved \| abandoned \| carried`** — one in-flight state, named for the area it lives in (`missions/active/`), and three end states in `archive/`. **Drivability is no longer a status word**: a mission is claimable when it is in the active area, has a plan (`## Acceptance` non-empty → `no_plan`), and has at least one queued ticket naming it (`no_tickets`). `plan-units.sh` stops reading `status` for the offer entirely — the *area* is the authority — and `not_approved` leaves its reason vocabulary. |
| K2 | **`approve.sh` and the `/mission approve` subcommand are retired; their three payloads are redistributed, not dropped.** `merge_policy` moves to **creation** (`create.sh`, `scaffold-draft.sh`), adopting the ticket rule exactly — **absent means `review`**, the conservative default, so a mission that arrives with no policy routes to a PR. **Ownership seeding is dropped**, not relocated: an unowned mission on `main` is claimable by anyone, which is already how `list.sh`, `summary.sh`, and the mission lens treat it (`relation: unassigned`). **The floor is kept and re-aimed** — `hooks/validate-mission.sh` fired on `status: approved`; it now fires on any mission in `missions/active/`, because "the thing that can be claimed" is no longer marked by a status word. Its ownership half relaxes to optional; the `## Experience` and `## Acceptance` halves are unchanged and are the load-bearing part of this change. |
| K3 | **Rejected: keeping `draft` as an optional marker.** The tempting middle path is to leave `draft` writable for an author who wants to signal "not ready", and simply stop *gating* on it. It loses because an optional gate that only some artifacts carry is a gate nobody can rely on: a reader seeing no `draft` cannot tell "reviewed and accepted" from "the writer never set it", so every consumer would need a second, real signal anyway — and the first thing a second signal does is drift from the first. This also reverses I2's note *"do not reintroduce `active` as a status word"*, deliberately: that note existed because `active` was ambiguous between `draft` and `approved`. With one in-flight state the ambiguity is gone, and area and status coincide by construction. |

### Seventh round — the release-branch staging tier (2026-08-03)

| # | Ruling |
| - | ------ |
| L1 | **Exactly one new tier: `release/*`. No `develop`, no `hotfix/*`.** `main` stays the default and production branch, and the per-unit claim/branch/worktree/PR mechanics are untouched. **Full Git Flow is rejected**: `develop` duplicates `main` for a fleet whose units already merge one at a time behind a pull request, and it would create a second base — reviving exactly the two questions the mission draft could not answer (what a claim means against two bases, and what `merge_policy` means under two merge targets). Both disappear by not creating the second base; `hotfix/*` goes with it, because a `main` that is deployable at every commit makes a hotfix an ordinary unit. **A `develop`-only tier is rejected** too: it gives a staging area whose identity is continuous, so there is nothing bounded to attach a durable record to — and the record was half the ask. |
| L2 | **Promotion is a batch-level, explicitly-invoked phase over `main`, never a step of the per-unit ship.** The cut is *from* `main`, so it is structurally post-merge — the same phase as release publishing and concern extraction. It adds a **second** confirmation (about a batch already on `main`) rather than deferring or weakening the per-unit one (about one branch before it lands); inverting `/ship`'s evidence-before-merge rule is the one thing a promotion step must not do. And it stays out of the per-unit flow because a promotion inside it would make every `auto` unit cut a release branch, changing per-unit behaviour observably. Landing a unit on `main` is unchanged; promoting landed units to production becomes a distinct, recorded event. |
| L3 | **The durable ship record is a new `.workaholic/releases/` artifact, derived from git at cut and confirm time.** It is additive: `.workaholic/release-notes/<branch>.md` and the story's `## Deployment Evidence` block keep their shape exactly. The record answers "what did this deploy carry, and when" from the filesystem — carried `main` commits, cut time, confirmation/deploy time — and is derived rather than accumulated per unit, because the question is about the release; re-deriving it from per-unit notes would make it a view rather than a record. A release branch whose confirmation **fails is never deleted**: it is the rollback boundary, `main` is unaffected because its units are already merged there, and the next promotion cuts a fresh branch. |

*(The survey behind these rulings — every `/ship` step's reads, writes, and ordering constraint — is the feedback record `20260803212851-adopt-a-release-branch-staging-tier-release-only.md`.)*

### Eighth round — a base-side `claim:` stamp is history (2026-08-04)

| # | Ruling |
| - | ------ |
| M1 | **A `claim:` stamp that reaches the base is history, never a claim. The unmerged-branch scan is the only oracle.** The old invariant — *"`main` never shows a claim"* — was observed false on `b70bb0a9`: merging PR #153, a **handoff** PR for a `blocked` unit, published `claim: work-20260731-221002` onto a ticket still in `todo/`. Both protocols were individually correct. The claim protocol assumed a branch merges only after `archive.sh` has renamed every ticket out of `todo/` (where the stamp is honest history); §7's `handoff`/`blocked` route, and the unattended routine's *"open or update the unit's PR even when the work is incomplete"*, made merging-while-still-queued routine. Nothing was broken by it — `plan-units.sh` subtracts claims from the scan and never from frontmatter, so the ticket was correctly re-offered — so this is a correctness-of-record defect, and the fix is to make the record true. |
| M1a | **The tempting fix is rejected on evidence: do NOT strip the stamp before opening a handoff PR.** The ticket that raised this recommended exactly that. It is wrong. `lib/claims.sh` sources a claim's artifacts as *the files the claim commit touched that still carry `claim: <branch>` **at the tip***, so removing a stamp drops that artifact from the claim — deliberately, and pinned by tests. Stripping at handoff time would therefore un-claim a ticket **while its PR is still open and unmerged**, offering in-flight work as fresh backlog: the double-pick the protocol exists to prevent, observed live 2026-07-30 and again (as a lost artifact list) 2026-08-04. A gate that creates the failure it was written to prevent is not a fix. |
| M1b | **Also rejected: re-sourcing the reader from the claim commit instead of the tip, and any sweep over the base.** Re-sourcing would make M1a's strip safe, but it reverses the deliberate, tested "a stamp removal releases that artifact" behaviour — a real design change that needs its own ticket and a human, not a side effect of a record fix. A sweep is rejected because two writers of claim state is precisely what the single shared scan exists to prevent. Validating `claim:` in `validate-ticket.sh` stays rejected on its original grounds: a `PostToolUse` hook reading one file cannot know whether the remote branch still exists. |

### Ninth round — the repository boundary is crossed as an issue (2026-08-05)

| # | Ruling |
| - | ------ |
| N1 | **A cross-repository ask travels as a GitHub issue on the target, never as a file written into its checkout.** `/request` copied a conforming ticket into the target's `.workaholic/tickets/todo/`, so the crossing arrived as a file in somebody else's `git status` — an artifact its owners had no native way to see, triage, or decline, and one that made this repository a writer into theirs. An issue arrives where they already read, and the target's own `[Specificate]` routine ingests it exactly like any other inbound report, so the **recording and the proposal judgment happen inside the target's loop** rather than ours. Its title carries no prefix of our vocabulary. `hooks/guard-repo-confinement.sh` keeps refusing every other route; this becomes the only sanctioned crossing. |
| N2 | **`/request` is retired, and its knowledge is relocated rather than deleted.** The command, `skills/request/` and `submit-request.sh` are gone; `resolve-target.sh`, `check-outbound-body.sh` and `lib/remote-url.sh` moved into `skills/feedback/scripts/`, and `request/SKILL.md` §1-3 and §6 moved into the feedback skill's *Crossing a repository boundary* section. What was load-bearing was never the file write: it was the one non-skippable verbatim confirmation, the judgement that no matcher can replace masking (with its five measured leak classes), the identifier-not-substring narrowing measured 2026-08-02, and the every-URL-form reading measured 2026-08-04 under an injected `insteadOf` rewrite. The destination was built and tested **before** the surface was deleted, which is what made the retirement a relocation; a grep gate over live `plugins/`, `docs/`, `CLAUDE.md` and `README.md` is what proves nothing live still points at the old route. Archived tickets, stories and the measured-incident passages keep the `/request` name with a dated note — history is never rewritten. |
| N3 | **The second layer is scoped to the body, not to the branch.** `scan-branch-safety.sh` answers "what is this **branch** about to publish", and a crossing body is composed in the session and committed nowhere — so pointing the branch scan at it reports a verdict about the caller's unrelated working branch, which is worse than no verdict because it reads as one. `feedback/scripts/scan-outbound-body.sh` applies the same shared `secret-patterns.sh` and `.workaholic/leak-denylist` rules to one file. `size` is deliberately absent: it is a property of a diff, and an empty tier is honest where a fabricated one would not be. |

### Tenth round — an attended drive chooses its units (2026-08-05)

| # | Ruling |
| - | ------ |
| O1 | **`/drive` has two invocation forms, and the attended one asks which units to take.** This amends G2's *"no drive-time confirmation"*, which was written against the per-ticket approval prompt and swept up a different question with it: not *may I do this* but *which of these first*. Bare `/drive` is **attended** — when the partition offers more than one claimable or resumable target it asks once (`multiSelect`, one option per unit, `[project label]` prefix), drives the chosen units in the chosen order, and reports the rest as `deferred_by_operator`, which keeps them claimable and so forbids `ok`. `/drive auto` (synonym: `night`) is **unattended** and keeps the zero-prompt contract verbatim; the `[Drive]` routine template and every caller-side loop name it explicitly. **Attendance is chosen by the caller's invocation form and never inferred** from a TTY or environment: a wrong inference either parks a cron tick on an unanswerable prompt or silently strips the developer's choice, and the invocation is the only signal that cannot be wrong. Nothing else changes — the partition's *composition* is still reported and never asked, there is still no per-ticket prompt, and steps 3–7 are byte-identical between the forms. The measured failure it closes: on 2026-08-05 an attended run spent its first ~40 minutes reopening a pull request the developer considered parked, because `resumable[]` ranked it above their actual work in progress, and they had to interrupt twice to ask why. The ordering half was fixed by the `parked_with_pr` tier; this is the other half — where a person is present, the choice among peers is theirs, and a heuristic decides only where nobody can. |

### Eleventh round — two routines, one behaviour per command (2026-08-06)

| # | Ruling |
| - | ------ |
| P9 | **A Slack thread URL in a public repository's Issue and pull-request bodies is an ACCEPTED risk, and the untrusted-input problem beside it is not.** The routine chain carries the notification target in an Issue body (in) and a pull-request body (out, P4). On a public repository both are world-readable. **Accepted** (developer, 2026-08-06): it discloses the workspace subdomain, the channel id and a microsecond timestamp — no credential, no read or write for an outsider — leaving post-compromise convenience and metadata accumulation. What makes it a decision rather than a detail is that public issue bodies are permanently archived and scraped, so it **cannot be unpublished**; an earlier note in this repository called the link "workspace-internal; harmless" without accounting for that, which is the sort of unexamined dismissal this row exists to replace. **Revisit if** the channel starts carrying customer material (I9 already confines that to private repositories) or the repository starts taking issues from outside the collaborator set; the cheapest alternative is to drop the URL from the *Issue* and let `/specificate` open the thread, losing only the link to a conversation held before the record existed. **The adjacent risk is NOT accepted**: a routine feeds an Issue or pull-request body to an unattended agent holding Bash, Write and a Slack connector, so on a public repository **Issue and Pull request permissions must be `Collaborators only`** — stated in the developer's own memo, and until now recorded only in a feedback record rather than where a person setting a routine up would read it. It is now a precondition in `workaholic:workaholify` and a banner on every rendered setup sheet. |
| P8 | **Neither trigger narrows to a person; each command filters, and neither prompt does.** The routines UI turns out to offer **no assignee filter at all**, which killed P6's `assignee = the developer` design and the `author` filter that went with it. The ruling: every developer's copy of both routines fires on every matching event, and the **data** decides whose work it is — N−1 empty sessions per event, in exchange for ownership living in the repository where one oracle reads it rather than in a UI setting nothing can read, write or verify. The two commands then ask the same question at the only place each can. `/implement` filters at the **survey** (`owned_by_other`), because it claims artifacts that already carry `assignees`. `/specificate` filters at its **input**: when the ask came from an issue carrying an assignee, it compares that assignee against the session's own GitHub identity (`gh api user`, the credential the session already holds) and reports `not_mine` — necessary because proposing *creates* the artifact that will carry `assignees`, so there is nothing to survey yet, and without it N developers open N pull requests for one issue (the dedup only sees proposals that already reached a branch). **The check is the command's, never the prompt's**: a first attempt put a guard line in `[Specificate]`'s prompt, which made the two templates asymmetric and stated "whose work is this" in a second place — a rule in two routine prompts is a rule that drifts. Both prompts stay the developer's own four lines. |
| P7 | **A routine prompt is the developer's own four lines, not the agent's prose.** P3 cut the prompts to four lines and then wrote *new* four lines — several sentences long each, opening "You are the [Specificate] runner for {repo_slug}…" and naming the repository three ways — so the renderer produced a different text per project and none of it was what the ruling actually said. The source is `20260806183556`, and it is short and concrete: read the notification target and the payload out of the triggering artifact; tell the target, in the payload's own language, that work has started; run the one command; post the result in the given format. That is what ships, rendered into English and otherwise unchanged. **The target comes from the Issue or the pull request**, not from a channel written into the prompt, which is why no repository is named and the same lines paste into every project; `{repo}` survives only as the developer's own placeholder in the format line. **The format is the one thing a routine cannot defer** — no skill states it, because it is the routine's output contract — and everything else is omitted on purpose: no plugin gate, no procedure, no rule a skill already owns, and no "nobody is here" (being unattended is `/implement`'s own contract). The deferral is documented in the template's **header**, for a maintainer; the prompt itself restates nothing. |
| P7a | **Superseded within the day and recorded rather than rewritten: "the prompt carries no substitution at all."** Removing `{repo}` was over-correction — it is in the developer's original format line, and without it every post carries an unfollowable pull-request link. The rule that survives is *names no repository*, not *substitutes nothing*. |
| P7b | **A routine prompt names no repository and carries no substitution.** P3 cut the prompts to four lines but left `{repo_slug}`, `{repo_name}` and `{repo}` in them, so the renderer produced a *different* text per project — which defeats the thing P3 was for: "a developer wiring a new project pastes four lines into each". The session already knows which repository it is running in, so it derives its own `dev-<repo>` channel and its own pull-request links; being told is redundant, and being told *per project* is the per-project cost the reduction removes. The prompts are now **byte-identical everywhere** and the renderer leaves them untouched. `{repo_name}` survives only in a template's `name:`, which is a UI field a routines list has to disambiguate, not the prompt. |
| P6 | **"Who" enters once at the trigger and rides the artifacts; a routine's trigger bounds cost, the data decides ownership.** P2 moved a ticket's owner into an `assignees` field but left the emitting seam silent, so `/specificate` wrote every artifact **unowned** — which correctly means "claimable by anyone", and therefore meant that on a repository with several developers **every** runner judged a merged proposal's work claimable and raced for it. The claim protocol prevented the double-drive; nothing could decide whose job it was, because nothing in the data said. This completes the chain the ownership ticket asked for and P2 half-shipped: the `[Specificate]` routine fires on an issue **assigned to a person**, that assignee is passed to `scaffold-draft.sh` and `scaffold-proposed-ticket.sh` (`--assignee`), and every artifact the run emits carries it. **The empty case is kept** — an unassigned issue yields a team-owned artifact — and **falling back to the running identity is forbidden**, because stamping whichever container executed the batch is exactly the re-derivation the chain removes. The `[Implement]` trigger also narrows to `author = the developer`, and the two mechanisms are deliberately **not** redundant: the filter is a UI setting nothing in the plugin can read or verify, so it can only bound the cost (N developers no longer means N sessions per merge); ownership lives in the repository and is read by every runner through one oracle, so it holds even when a trigger is misconfigured. Ownership is the load-bearing half. |
| P5 | **No command's behaviour depends on the first word of its argument.** A fork on a literal word is a second command wearing one name: it is invisible in the command list, undocumentable in one row, and it reserves a word the argument can then never legitimately be. Every command was inventoried and each fork decided separately — dropped, or moved to a command of its own — and none was left implicit. **`/mission close <slug>` became `/mission-close <slug>`**: it could not be dropped, because `close.sh` is the only sanctioned writer of a mission's end state and that single-writer property is what keeps the archive move from growing a second path, so the behaviour moved rather than going away. **`/mission summary` and `/mission approve`** kept deprecation *stubs* long after the modes themselves were retired (2026-07-22 and 2026-07-31) — the stubs were the surviving fork, buying a courtesy message at the price of two words no mission may be titled — and are **dropped**. **`/ticket summary`** is dropped for the same reason: bare `/ticket` already reports the queue. **`/drive auto` / `night`** went with P1. What is deliberately **kept** is bare-vs-argument, which is a *scope* and not a mode: `/mission` with no mission named opens the planning session over all of yours, `/ticket` with nothing described reports rather than writes, `/drive [<unit>]`, `/implement [<unit>]`, `/catch [window]`, `/setup-dev-routines [repo]` / `/setup-repo-routines [repo]` (one command per routine *scope* since 2026-08-14 — two jobs, not one command switching on a first word), `/explain <q> [dir]` all narrow one behaviour. `/fb`'s cross-repository mode is kept too and is the one judgement call: it routes on *destination* — an `owner/name`, a URL, an explicit "to \<repo\>" — not on a first word, and its masking confirmation and identifier backstop are the substance of that flow; splitting it would move a human gate, which is not what this decision is about. |
| P4 | **The routine chain hands its notification target forward in the pull request body, and a pull request title is not a commit subject.** `/specificate` writes one machine-readable `Notify-Thread: <url>` line (`WORKAHOLIC_NOTIFY_TARGET`), and `/implement` — started by that pull request's merge — reads it back with `branching/scripts/read-notify-target.sh` and replies **there**. It replaces re-deriving the thread from an `fb:<stem>` search, the step that put a reply in the wrong place on 2026-08-05: a search has to guess, and a guess in a notification path produces a message that looks right and is unrelated to the event. **The absent line is a fallback signal, not an error** — every pull request opened before this change carries none, so `reason: "absent"` is distinguished from `no_gh`/`unreadable` and the search stays in place. Inventing a target to fill the line is forbidden for the same reason: a wrong one suppresses the fallback. The **title** half fixes a contradiction the prefix contract had carried unexercised: `check-subject.sh` forbids a `[bracket]` prefix, so `/specificate` could satisfy its own documented `[Proposal]` title only by writing a commit subject the gate refuses, and the publish died at `commit_failed` before any pull request existed. `WORKAHOLIC_PR_TITLE` separates them — the subject keeps the project rule, the title carries the prefix the `[Implement]` trigger filters on — and falls back to the subject, so no other caller changes. Both are env vars rather than positionals because the positionals belong to `commit.sh` and end in an open-ended `[files...]`, where a seventh could not be told from a filename. |
| P3 | **Two routines, four lines each, and `[Consent]` is retired.** A developer configures a routine by hand, once per project, so **every field is a cost that multiplies by the number of projects** — the loop's shape is set by what a person can maintain across a fleet, not by what the plugin can express. So the set is two (`[Specificate]`, `[Implement]`) and each prompt is four lines: the environment, the payload the target is read out of, the one command, and **the channel and post shape**. That last is the only thing a routine may not defer, because it *is* the routine's output contract; everything else has a home (`workaholic:drive`, `workaholic:specificate`/`feedback`, the `workaholify` SKILL, the always-loaded `rules/`) and a prompt that restates it is a second source of truth whose drift is one-directional. **Retiring `[Consent]` costs something, and it is stated rather than discovered**: a pull request a human merges out of band is now announced by nobody, since `[Implement]` posts only for units it ran. The developer accepted that explicitly as the price of one fewer standing process per project. A merged *proposal* still produces a post — it is what starts `[Implement]` — and every merge stays readable on GitHub; what is gone is the channel-side record of a merge that started no run. Do not add a third routine to recover it. |
| P2 | **A ticket's owner is a field, not a directory.** `.workaholic/tickets/todo/<user-slug>/` encoded assignment in the path, and the path is a bad place for it. With no `git config user.email` there was no directory to open, so **an unreadable queue and an empty one were the same observation** — an hourly runner reported a healthy idle tick over a full backlog, and the proposed fix was a `git config` line in the routine prompt: an environment expectation layered over the flaw, the third patch in that area in a week. **Reassignment was a file move**, and following renames across this exact tree is what the claim reader's rename map plus filename fallback exist for, both added after real double-pick incidents. And **two ownership models coexisted** — a mission's plural `assignees` with an unowned, claimable state, against a ticket's single owner with no unowned state at all — with the queue using the worse one. So the ticket adopts the mission's model verbatim: plural `assignees`, empty meaning team-owned, read through **one** oracle for every artifact kind (`gather/scripts/owners.sh`, with `owns.sh` for the `mine`/`unowned`/`other`/`unresolved` verdict — `unresolved` kept distinct from `other` because "somebody else's" and "I cannot tell whose" must not render identically). The survey now reports `backlog_size` and `owner_unresolved` instead of `identity_unresolved`: it **reads the queue whatever its identity**, offers the unowned half, and forbids `ok` — it no longer terminates on an answerable question. **The claim protocol's identity use is unchanged and deliberately so**: claim authorship and resumption still key on `git config user.email`, because that asks "is this my own run" and fails loudly. Readers tolerate both layouts indefinitely and a living migration converges the tree at the write seams, so the migration is convergent rather than a gate — a reader that saw only the flat form would reproduce the very failure being removed. `sweep-todo.sh`, which existed only to route strays *into* the per-user directories, is retired. |
| P1 | **The unattended executor becomes `/implement`; `/drive` is the interactive command again.** This supersedes O1's *two invocation forms* half while keeping everything O1 decided about *what* is asked. O1 was right that attendance must be chosen by the caller and never inferred, and wrong about where to carry that choice: a first word (`auto`, with `night` as a synonym) is a second command wearing one name, so the contract a loop rests on was an argument the caller might forget to pass — and forgetting it parks the tick on a prompt, the exact failure O1 existed to prevent. Two commands make the mistake unrepresentable. `/drive [<unit>]` is **attended** and keeps O1's single `multiSelect` selection, its `deferred_by_operator` reporting, and its `pending` consequence verbatim. `/implement [<unit>]` is **unattended** and keeps the zero-prompt contract verbatim; the routine template and every caller-side loop (`/goal /implement ok`) name it. The optional argument is a **scope, not a mode** — the behaviour is identical with and without it — which is what keeps this a split rather than a new fork. Everything below §2 stays byte-identical between the two, and the knowledge stays in one skill with two entry points: a forked copy of the run would drift, and the run is the part that must not. |

### Twelfth round — the reply thread is found, not carried (2026-08-07)

| # | Ruling |
| - | ------ |
| Q1 | **Each routine finds its own reply thread statelessly; P4's propagation half is superseded and P9's accepted disclosure is withdrawn.** The carried notification target — P4's `Notify-Thread: <url>` body line, its `WORKAHOLIC_NOTIFY_TARGET` env var on `publish-tree-pr.sh`, and its reader `branching/scripts/read-notify-target.sh` — is retired (developer's ruling, 2026-08-07): nothing is carried between routines, and `[Specificate]` and `[Implement]` each locate their own thread in the repository's Slack channel before posting. **What P4 taught is kept, not reversed**: the 2026-08-05 defect was a search that *guessed*, and a guess in a notification path produces a message that looks right and is unrelated to the event — propagation removed the guess by carrying the answer, and statelessness removes it a different way, **by defining the search so that it cannot guess**. The lookup (normative statement in `workaholic:notify`, *One thread per feedback item* — moved out of `workaholic:workaholify` into its own skill 2026-08-07, the setup gateway being the wrong home for a runtime procedure) is ordered exact-string searches only — the session's own trigger message first (not a search; a message written before the record existed can never carry the key), then `fb:<stem>` (derived from the repository: `unit-feedback-stems.sh` for `/implement`, the record `/specificate` just wrote for its finish), then the Issue/pull-request URL or its `#<number>` — and **no exact match posts a new root carrying `fb:<stem>`**, never a fuzzy match, never "the most recent thread that looks related", never recency: fuzzy matching is prohibited by name because it *is* what the 2026-08-05 defect was. **The cost is bounded in writing**: at most two search queries per lookup (a lookup that found nothing in two exact searches posts a new root — cheaper than a third query and strictly more correct than a guess), results capped, no full-channel read at any point; the target is resolved **once per run** and reused for the unit's start and finish — statelessness is between runs, never within one. Two of propagation's benefits are given up knowingly: the thread URL no longer appears in any public Issue or pull-request body — which is why **P9's accepted disclosure is withdrawn** rather than left standing (its `Collaborators only` precondition stays required; it was never about the URL) — and each routine pays its own lookup. The honest residual cost: when nobody pasted the Issue link into Slack, no exact token connects the pre-Issue conversation to the artifact and the routine starts a new root; the mitigation is a convention, not code — paste the Issue link into the thread you filed it from. P4's title half (`WORKAHOLIC_PR_TITLE`, the pull-request title as a separate surface from the commit subject) is untouched. |
| Q2 | **The routine prompts are reshaped: three instructions and two formatted posts; P3/P7's "four lines" literal is superseded in shape, not in ownership.** The developer revised their own prompts (2026-08-07, after the first live chain run): the start notification is now a *formatted post* like the finish — `📐 Designing for [#45 [FB] Issue Title](…/issues/45)` / `🛠️ Implementing for [#123 Proposal PR Title](…/pull/123)` — and both posts carry a second line, `by [Claude Code on the Web](session URL) of <@U…>`, folding the notify skill's session-URL rule and mention resolution into the format itself. What P3/P7 decided survives unchanged: the prompt is the developer's own text, pastes identically into every project, names no repository, defers every rule a skill owns, and carries the post format because the format is the routine's output contract — only the literal line count moved from four to the three-instructions-plus-two-formats shape, because the start post earning a format is more contract, not more procedure. The propose start post points at the *Issue* (no pull request exists yet); every other link points at the pull request. |

### Thirteenth round — the loop supplies its own ask (2026-08-21, issue #555)

| # | Ruling |
| - | ------ |
| R1 | **A third turning routine, `[Propose]` at `:40`, and the loop closes across hours rather than within one.** §1's vision ends at "humans supply feedback, the AI proposes missions" — which leaves the *feedback* as a human-shaped hole in an otherwise unattended machine: an hour in which nobody opened an issue is an hour `[Specificate]` reads an empty inbox and reports `nothing_in_hand`. `/propose` closes it from the direction of the **strategy** rather than the backlog: it reads the running identity's own `status: active` strategies, judges the one evolutionary move that brings the nearest closer to its Aim before its `target_date`, and opens that judgment as a GitHub issue assigned to that identity. Three routines then turn one loop — `:15` ingest, `:30` drive, `:40` propose — and one turn is one hour. `:40` is **after** the executor deliberately: the judgment is made against what actually landed, so a slot before `[Implement]` would judge each hour against the state that hour was about to change. Closing the loop inside a single hour was considered and refused — it would invert the dependency and cost a full day of latency in the ordering to save 35 minutes. What a person supplies moves up a layer, from the ticket to the direction. |
| R2 | **The output is a GitHub issue, and nothing else would close the loop.** `[Specificate]`'s unattended entrance is `list-inbound-issues.sh` — open issues assigned to the running identity. A record written into `.workaholic/feedbacks/` is not discovered, because discovery reads issues, not files; worse, discovery *excludes* an issue a record already names, so writing a record alongside the issue would suppress the ask's own ingestion. That is the defect `/fb` measured and resolved the same way (mission `register-every-fb-as-an-issue`), so the same writer is reused rather than a second one written. `/propose` therefore writes **nothing into the repository** — no file, no commit, no branch, no pull request — which is also what keeps it out of the unattended-`main`-writer class refused twice in `workaholic:ship` §7. |
| R3 | **The loop's output stays attributable with no new field: the ask carries the strategy's own `feedback:` refs forward.** `attributed-work.sh` attributes work to a strategy through `strategy.feedback[] ∩ artifact.feedback[]` plus one hop through a mission. A mission `/specificate` proposes from a `[Propose]` issue would cite only the record that run wrote, so the intersection would be empty and the loop would turn leaving no trace on the direction that asked for it. The proposal's body therefore names the strategy's refs on a visible `feedback:` line, and `/specificate` gained one step (workflow 3b) that carries any refs the ask names onto what it emits. Both scaffolds were already variadic. The three alternatives are refused for the reasons they were refused before: reviving `strategy:` on a mission rebuilds the ownership hop removed on 2026-07-28 (§5), a strategy-side list of slugs needs a third writer the artifact deliberately does not have, and giving up on attribution ships a loop nobody can measure. |
| R4 | **The conservative bar is dropped on purpose, and replaced by mechanical gates rather than a softer judgment.** Every unattended routine here is unified under *when unsure, record only, and say what made you unsure* (§6.3). A routine that proposed only what it was sure of would propose housekeeping, which is precisely what the ask refuses — so `/propose` is the first to drop the bar. What bounds it is a list of derived gates the running session cannot decide differently: `not_active`, `not_mine`, `past_target_date`, `no_feedback_refs`, `work_waiting`, `open_proposal`, `over_cap`, `attribution_unreadable`, each reported by name. `work_waiting` and `open_proposal` are one gate in two halves that hand off with **no window**, giving one proposal per strategy in flight at a time with no cursor and no stored state; `over_cap` holds a tick to one proposal across all strategies. A per-day bound — the obvious import from `deploy-day:<token>` — was refused: it answers a different question (an unchanging status restated hourly) and would cap the very loop this round exists to start. And a gate that cannot be read is not a gate: an unreadable open-proposal list refuses the whole tick. |
| R5 | **The judgment is made only where the reader can see.** `attributed-work.sh` is lossy by design and every consumer is contracted to say what it could not attribute. A strategy citing **no** feedback record can never have anything attributed back to it, so "widen the depth here, contract there" would be judged on a blind read — it is refused with the repair named. A strategy that cites records but has nothing citing it back (`no_citing_artifacts`) is explicitly **not** refused: that is a direction nothing has answered *yet*, which is when a proposal is most wanted. One means "no work yet", the other "no way to see work", and conflating them would have made the loop silent exactly where it should start. |
| R6 | **Anti-housekeeping is a mechanical floor, not an instruction.** A proposal declares exactly one move — `depth`, `breadth` or `contraction` — and its body must carry `## What this is chosen against`. That section is the floor that does the work: "tidy this up", "the docs drifted", "add a test" are all chosen against **nothing**, because nobody argues for the mess. A proposal that cannot name the fork it did not take is either uncontroversial or unformed, and both are the safe small change the ask refuses. Like every write floor here it checks presence, never quality. |

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

- Headless, non-interactive command (working name `/specificate`), cron-scheduled
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
- The "Drive Every 5 Minutes" routine (G4) is simply this run on a schedule,
  invoking the unattended command `/implement` by name (P1, superseding
  O1's two invocation forms); the attended `/drive` behaves identically
  once its units are chosen.
- Needed pieces: a deterministic claim reader (enumerate unmerged remote
  branches, extract claimed artifact IDs), a stale-claim reclamation rule
  (an abandoned claim branch must not block its work forever), and the
  retirement sweep for `/monitor`, `/trip` (I1), and `/carry` (I5) — commands,
  agents, docs. `/goal` compatibility stays (I4).

### 6.5 Slack integration

- Inbound: Claude Tag per-repo channel backed by Claude Code Web (target) /
  interactive sessions on this server (interim).
- Outbound: dedicated bot token; proposals and worker reports post as the bot.

## 7. Roadmap

| Phase | Content |
| ----- | ------- |
| 1 — Foundation | Strategy-layer removal + `assignees` restoration; `feedbacks/` artifact type + capture skill + validators + allowlist registration. Fully useful standalone (feedback works from local sessions too). |
| 2 — Proposal loop | Cursor detection, proposal judgment, draft missions, Slack bot notifications, dedup. Server cron. Plus the concerns→feedback merger (H2: migration, lifecycle-machinery retirement, carry-over-seam extraction per H3). |
| 3 — Approval & autonomous `/drive` | Approval flip flow from Slack sessions; the `status` unification incl. `drive_authorized` retirement (I2); per-artifact `merge_policy` at creation (G5); `/drive` unification with claim protocol, PR-unit partitioning, and claim-born worktree lifecycle (G1–G3, I6); retirement of `/monitor`, `/trip`, `/carry` and the reflection channel (I1, I3, I5, I7); the 5-minute routine (G4); automated `/ship` for all-auto units. |
| 4 — Platform | Claude Code Web port of both batches, kioku transcript ingestion, multi-repo rollout of per-repo channels. |

## 8. Open items (deferred, recorded here so they are not lost)

- kioku auto-ingestion design (which meeting belongs to which repo).
- Claude Code Web scheduling specifics for the two batches.
- Channel↔repo mapping config placement (E3).
- Replan proposals driven by feedback (C3 second stage).
- Stale-claim reclamation rule and the claim reader's exact mechanics (G3).
- The feedback `kind` enum's final vocabulary (H2) and the customer-material
  intake flow's mechanics (H4).
- How the batch-unit claim records its grouping (which tickets share the PR)
  so a later tick reads the same unit boundaries.
