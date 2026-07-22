---
name: mission
description: Use when the user runs `/mission`, asks to "start a mission", "plan a batch of work", "show mission progress", or "what missions are in flight". A mission is the overnight-executable execution plan of a strategy — a bounded, information-rich batch of tickets an agent fleet drives in a night; this skill creates one, lists missions with computed progress, and defines the mission schema every workflow reads.
allowed-tools: Bash
---

# Mission

A **mission** is a first-class knowledge artifact: the **overnight-executable execution plan of a strategy** — a fairly immediate developer request, interrogated to question-free drive-readiness, that bundles the ordered ticket set an agent fleet drives through in a night. It carries the information-rich statement of *what this batch of tickets accomplishes* and *how far it has come*, with a machine-readable web of relations to the tickets, stories, and concerns that advance it. **Longevity lives one level up, in the [strategy](../strategy/SKILL.md)** the mission executes; the mission is bounded, not long-lived.

Distinguish the terms and never conflate them (`planning` / `terminology`):

- **strategy** — long-lived **direction** (戦略) with no completion conditions. It answers *why these missions are being launched* and outlives every one of them. Missions are its execution plans (`strategy`).
- **mission** — the **execution plan** of one strategy: a bounded, overnight-executable batch of tickets with acceptance criteria and an append-only changelog. It answers *what does this batch of tickets accomplish tonight*. A mission finishes; the strategy persists.
- **trip** — a short, bounded design/build *session* (Planner/Architect/Constructor) that produces design rationale and decomposes into tickets.
- **epic / milestone** — generic project-management words this repo deliberately does **not** use as artifact names. "Strategy" and "mission" are the words for these two levels.

See the **Granularity** section below for the full commit → ticket → mission → strategy discipline and the record of why "mission" was narrowed from its earlier long-lived meaning.

## Granularity

The **single home** of the granularity discipline (`planning` / `modeling-centric-design`). Four description layers each describe code change and its planning at *their own* level, and **no artifact restates a lower level's detail**:

| Layer | Answers | Size | Normalized by |
| --- | --- | --- | --- |
| **commit** | *what is this one normalized change* | ~a few hundred lines, one reviewable unit | the release-scan per-commit changed-lines gate (ticket `20260721020759`) |
| **ticket** | *what is this one change* (a single drive-able unit) | one `/drive` pass, with its own `## Quality Gate` | its `## Policies` / `## Quality Gate` |
| **mission** | *what does this batch of tickets accomplish tonight* | hours of agent time; a fairly immediate request interrogated to question-free readiness | the Creation Interrogation |
| **strategy** | *why are these missions being launched* | long-lived direction, no completion conditions | — |

**The balance test cuts both ways.** A mission that re-narrates its tickets' specifics is **over-written** — trust the ticket to hold the detail. A ticket that says essentially what its mission says means the **mission is under-sized** — a mission must be bigger than any one ticket; surface that and merge, do not write the duplicate. Neither is "add more words"; both are "put each fact at exactly one level".

### Redefinition record

Recorded here so it is not re-litigated (`planning` / `terminology`):

- **Old meaning** (before 2026-07-21): "mission" was the long-lived container — "a durable goal spanning many tickets over a long horizon; it outlives any single branch or session".
- **New meaning**: "mission" is the **overnight-executable execution plan of a strategy** — bounded, not long-lived. **Longevity moved up to the new `strategy` artifact.**
- **Reason**: the mission was playing two roles at once — the executable unit *and* the long-lived goal container. Splitting them lets the developer plan by day (missions, front-loading every judgment call) and let agents execute by night, while direction persists above in a strategy.
- **Provenance**: mission `reorganize-missions-under-strategies`, 2026-07-21.

Every other place that touches granularity **links here** rather than restating it (`strategy`, `create-ticket`, `commit`).

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Where a step uses the agent's selection prompt (the `/mission` command's create/list choice), use the agent's native selection prompt; only the mechanism varies. All logic lives in the bundled POSIX scripts, which run identically everywhere.

## Allowed Location

A mission lives in one of two areas — mirroring the tickets `todo/`-vs-`archive/` split — selected by its `status`:

```
.workaholic/missions/active/<slug>/mission.md    # status: active (in progress)
.workaholic/missions/archive/<slug>/mission.md   # status: achieved | abandoned | carried (ended)
.workaholic/missions/index.md                    # regenerated by okf/refresh-index.sh, one entry per mission per area
```

`<slug>` is derived from the title: lowercased, every run of non-`[a-z0-9]` characters collapsed to a single hyphen, leading/trailing hyphens trimmed (e.g. `"Real-time Notifications"` → `real-time-notifications`). One directory per mission; the directory name **is** the slug and is the stable key other artifacts reference (`mission: <slug>`). The area is **never** part of that key — seams pass bare slugs and the scripts resolve the location, so a mission's move to `archive/` breaks no relation.

Resolution takes an explicit **root** (a `.workaholic` directory), never the process cwd. A seam that holds an artifact (a ticket, a `mission.md`) derives the root from *that artifact's own path* — the mission tree is fixed by where the ticket lives (its worktree), so `mission: <slug>` on a worktree ticket resolves to *that* worktree's mission from any cwd. A caller with only a slug and no artifact (`create.sh`, `close.sh`) roots on the repository it runs in (via `git rev-parse`). `lib/resolve.sh` is the single source of this: `missions_root_from_artifact` / `missions_root_default` / `missions_root_for_arg` choose the root, and `mission_resolve <root> <arg>` returns an **absolute** `mission.md` path — so two same-slug missions in two worktrees never yield the same string, and which file was read is visible in the output rather than hidden behind a cwd-relative path.

The scripts own all placement: `create.sh` writes into `active/`, `close.sh` moves to `archive/`, and every script runs a **living migration** first — a legacy flat `missions/<slug>/` dir (the pre-split layout) is relocated into the area its `status` selects (`git mv`, preserving history) on the next touch. The migration is idempotent and best-effort (a failure never blocks the calling seam; the resolver still finds an unmovable flat mission). Never `mv` a mission dir or hand-edit `status:` yourself.

## Schema

`mission.md` carries this frontmatter (the `type: Mission` line is the OKF conformance floor):

```yaml
---
type: Mission
title: <human title>
slug: <slug>
status: active          # active | achieved | abandoned | carried — selects the area (active/ vs archive/); flipped only by close.sh
carried_from:           # only on a successor: the slug of the mission whose remainder it inherited
created_at: <ISO-8601>
author: <email>
assignee: <email>       # the user id / email that owns driving this mission (defaults to author)
strategy: <slug>        # the ONE strategy this mission executes; resolved in the interrogation, read only via strategy/scripts/read-strategy-relation.sh. Empty on the scaffold; non-empty is required once drive_authorized: true
drive_authorized:       # `true` once the Creation Interrogation emitted the full ticket set
predicted_hours:        # decimal agent-hours, stamped ONCE at creation from archived-mission trend (predict-duration.sh); empty when basis 0
actual_hours:           # decimal agent-hours accumulated by /monitor across runs (record-run-hours.sh is its only writer); empty until a run records
tickets: []             # machine-readable member lists — reserved; populated by later work
stories: []
concerns: []
gate_type:              # OPTIONAL and normally EMPTY — documentation | live-app | check
gate_target:            # what to exercise: a route on the mission worktree's port (e.g. /docs), or the verification command for `check` (e.g. npm test)
gate_assert:            # one line: what must hold for the mission's outcome to pass
---
```

The `tickets` / `stories` / `concerns` lists are reserved for the machine-readable relations that downstream artifacts emit; a freshly created mission leaves them empty.

### Quality gate — optional, and normally empty

**The mission's substance is `## Experience` plus the ticket plan, not these fields.** `gate_*` is an *optional* declaration for the rare mission whose outcome has a stable, objective check that is knowable at kickoff. **Empty is the normal case, not a defect**, and nothing treats an absent gate as an error.

This is a deliberate demotion. A gate declared at creation is a prediction about work that does not exist yet: as the mission learns, the gate goes stale — but it stays in the file, and an agent keeps steering by it. A `gate_target` route plus a one-line assert is also a thin proxy for what a mission is *for*; a route returning 200 is not evidence the demanded experience is right. The record supports the demotion rather than merely arguing it: **every mission created to date left all three fields empty**, and `gate.sh` cannot resolve ports for a mission living in its own worktree — the prescribed layout. The gate has been inert since it shipped and nothing broke.

So do **not** interrogate these at mission creation, and do not treat a mission without them as incomplete. Write `## Experience` instead.

When a mission *does* declare one: `gate_type` is `documentation` (the mission's docs render and read correctly), `live-app` (the mission's feature works in the running app), or `check` (the project's own verification command passes); `gate_target` is the route to check — or, for `check`, the command to run; `gate_assert` states what must hold. The browser-shaped types are verified by driving the mission worktree's running server (unique port base, `WORKAHOLIC_DEV_PORT`) with the Playwright plugin, so several missions' gates can be checked at once; workaholic declares the gate and supplies the port, while the server-start command is the project's (declared once, e.g. in the project's `CLAUDE.md`). A `check` gate is verified by running `gate_target` in the mission's worktree and passes on exit 0 — the type for projects with no browser-drivable surface (a CLI, a daemon, a library, a compiler), whose stable objective check is the verification command their `CLAUDE.md` already declares. Two cautions on `check`: it certifies **the project's checks**, not the demanded experience — `## Experience` still carries the substance — and its command must be the project's *own* declared verification, never a bespoke one-liner invented at mission creation (that would be the inert-gate problem in a new spelling). Read a gate with `gate.sh` (below); a declared gate stays **objective** (`implementation` / `objective-documentation`) — a named route or command plus an asserted condition, never "looks good".

**The objectivity requirement outlives the gate.** `## Experience` is prose, so it cannot be machine-checked the way a route-plus-assert could. That makes objectivity a convention here rather than a check — hold it anyway: describe behavior that can be observed, not qualities that cannot.

### Drive authorization

`drive_authorized: true` records that this mission's ticket set was **interrogated and pre-authorized** by the developer: `/drive` may then drain its queue **without the per-ticket approval prompt**. Empty (the scaffold default) means ask, as always.

**Authorization lives here, on the mission, because this is the thing that was actually interrogated.** The Creation Interrogation is where the developer answered every judgement call and co-authored each ticket's `## Quality Gate`; stamping the mission is stamping that act. Two alternatives were considered and rejected, recorded so they are not re-litigated:

- **Keying off the ticket's `mission:` relation alone** — a ticket hand-added to the mission later would inherit an authorization nobody granted.
- **An explicit `/drive mission` argument** — mirrors night mode, but makes authorization an act by whoever runs `/drive`, who may not be the person who ran the interrogation.

**Explicit approval is relocated, never removed.** The gate is skipped exactly when a prior explicit batch authorization covers the ticket — `/drive night`'s invocation, or this stamp — and never otherwise. What is removed is the *completeness check inside the drive loop*; the qualitative looking-through `development` / `qa-engineering` makes non-delegable **relocates to the PR** (`/report` still writes the story, `/ship` still gates the merge on evidence). Do not blur those two: eliminate the completeness check and you are on policy; eliminate the looking-through and you are in the state three policies exist to prevent.

Read it with `drive-authorized.sh` — never by grepping the field yourself.

### Assignee

`assignee` names the user responsible for driving the mission to completion — a git user id / email. `create.sh` self-assigns it to the creator (`git config user.email`) by default; pass an explicit second argument to assign it to someone else.

**Absent or empty means unclaimed, not hidden.** Both `summary.sh` and the **mission lens** gate on "is this mission my business", which is *not somebody else's* — not *exactly mine*. A mission whose `assignee` matches your `git config user.email` is yours; one with no `assignee` is **unassigned** and is surfaced to everyone as claimable, after your own; one assigned to another developer stays silent. Absent and empty are the same thing — the schema draws no distinction, so neither does any reader.

The earlier rule was an exact email match, which meant an unassigned mission matched nobody and was silently skipped for *everybody* — invisible in the summary and the lens while `list.sh` showed it plainly. `create.sh`'s self-assignment default does not close that on its own, because it is not the only way a `mission.md` comes into existence (hand-authored ones arrive without it).

This is per-worktree by construction — each worktree checks out its own `.workaholic/missions/`, so the lens that fires there reflects the missions that are the business of whoever is working that tree.

### Strategy

`strategy` names the **one strategy this mission executes** — a mission is the execution plan of a strategy (`strategy`). The value is a strategy slug, single-valued by convention (one plan, one strategy), and it is read **only** through `strategy/scripts/read-strategy-relation.sh`, never by parsing frontmatter directly. It is the mission→strategy direction of the model, mirroring ticket→mission (`mission:` on a ticket).

Empty is the **scaffold** state; the link is resolved during the Creation Interrogation (see *Strategy resolution* below). Once a mission is stamped `drive_authorized: true`, a non-empty `strategy:` is **required** — `validate-mission.sh` refuses an authorized mission with no strategy at write time, the same floor that requires an owner, `## Experience`, and `## Acceptance`. Nothing is stored on the strategy side, so per-strategy mission rollups are always computed (`strategy/scripts/list.sh`).

### Duration (predicted / actual)

`predicted_hours` and `actual_hours` record, in decimal **agent-hours**, how long a mission's implementation is expected to take a coding agent and how long it actually consumed — so archived missions accumulate a trend the next planning reads.

- **`predicted_hours`** is stamped **once at creation**, deterministically, by `predict-duration.sh`: `median(actual_hours ÷ acceptance-item total)` across archived missions that carry both, times this mission's planned item count. With **no archived basis** it reports `basis: 0` and the field stays **empty** with a changelog note — never a fabricated number. It is a **report line to the developer, never a question** (`development` / `overnight-ai`: pre-answer, don't ask).
- **`actual_hours`** is accumulated by `/monitor`, whose dispatcher sums each leaf's dispatch→completion wall-clock per mission across waves and nights, and calls `record-run-hours.sh` once per mission per run-id. That recorder is `actual_hours`'s **only writer** (same doctrine as `tick-acceptance.sh` — never hand-edited), idempotent per run-id, and it carries each increment in a `run recorded (+Xh) — <run-id>` changelog line so the sum reconstructs from history.

**The actual is agent time under `/monitor` only** — a deliberate, documented limitation, not a gap to close silently. Solo `/drive` outside `/monitor` is not counted: the prediction answers "how long will the *agents* need", and the monitor run is where agents run at scale. Calendar span and commit-timestamp heuristics were rejected (idle pollution / estimation logic).

Body sections, in order:

- `## Goal` — the information-rich "why": business grounding and the outcome the mission pursues.
- `## Scope` — definition of done, and explicit out-of-scope notes.
- `## Experience` — **the mission's substance**: the user experience, the demanded behavior, and/or the overall structure it pursues. Where `## Goal` says *why* the work is worth doing, this says *what the thing does*. Keep it observable (`implementation` / `objective-documentation`) — "the list reorders without a reload" is checkable; "feels fast" is not. This is the persistent content a kickoff-time `gate_*` could never be, and it is what a later session reads to know what is actually demanded.
- `## Acceptance` — a checklist, and **the mission's plan**: each item names the ticket expected to satisfy it, so the list doubles as the route to completion. **Progress toward achievement is `checked ÷ total`, computed from this list, never a hand-set number** (`implementation` / `objective-documentation`). An unchecked item is a **heading, not a specification** — re-check it against the source before cutting its ticket (see the checklist convention below).
- `## Changelog` — an append-only, dated, human-readable timeline (`design` / `history-structures`).
- `## Reflection` — **optional**, appended by `/monitor` after each run (`append-reflection.sh`): one dated `### <date> run <run-id>` entry per run, carrying three fixed bullets — `blocked:` (what stopped autonomy, or none), `leaked questions:` (judgment calls that surfaced mid-run, or none), `front-load next:` (what the next planning should pre-answer). It is the feedback loop of the overnight model: the next Creation Interrogation reads recent reflections back (`list-reflections.sh`) so recurring leaks become pre-answered questions. **Explicitly outside `progress.sh` / `next-acceptance.sh` scope** — any `## ` heading ends `## Acceptance`, so a `- [ ]`-shaped line here never counts toward progress. It records **causes**, never pending decisions (the escalation list owns those — do not blur them).

### Acceptance-checklist convention

Each acceptance item is a Markdown checklist entry that names the ticket or story expected to satisfy it, by filename, in a trailing `(#<filename>)` marker:

```markdown
- [ ] Users can create a mission from the CLI (#20260706203044-mission-artifact-type-and-command.md)
- [x] Missions carry machine-readable relations (#20260706203045-mission-frontmatter-linkage.md)
```

The `(#<filename>)` marker is the **stable link** from an acceptance item to the artifact that satisfies it. Progress computation counts `[x]` against the total; the marker lets a completed ticket/story flip exactly its own item to `[x]` (that flip is owned by the mission update scripts, not by hand-editing).

**An unchecked item is a heading, not a specification.** Acceptance items are written at creation — the moment of least knowledge in a mission's life, from a directive and prior records rather than from the source. Measured on real use: of seven items written up front from concern records, **three were wrong when finally checked against the code** (one named a component that had no defect, one called a working counter-example an unfinished placeholder, and a *correction* over-credited a component whose verbatim reuse would have broken every fixture) — and the same item was mis-stated four times in two days, every time by paraphrasing a summary instead of reading the code. So before cutting or driving a ticket from an unchecked item, **re-check the item against the source** — and write the ticket from what the source says, never by paraphrasing the item into it. Detail specified up front is inventory that decays; the item's job is to say *where the bar is*, and the ticket's `## Quality Gate` — written with the code open — is where the bar becomes proof.

### Changelog line format

Each changelog line is a single dated, append-only entry relating one event to the mission — the "historical stuck changelog": where work stalled, deferred ("stuck"), resumed ("unstuck"), or completed. Format:

```markdown
- <YYYY-MM-DD> — <event> — <artifact-filename>
```

for example:

```markdown
- 2026-07-06 — ticket archived — 20260706203044-mission-artifact-type-and-command.md
- 2026-07-08 — concern deferred (stuck) — 61-progress-double-count-low.md
```

The `<event>` phrase plus the `<artifact-filename>` together form a stable event id, so an append is idempotent (the same event never adds a second line). Never rewrite or reorder past lines — the changelog is append-only history.

## Creation Interrogation (mandatory — always run)

When `/mission "<title>"` creates a mission, **interrogate the developer until the mission is drive-ready**, then emit the whole ticket set in one pass. This step **always runs — it is not skippable**, and it is not gated on the request "seeming obvious".

`create.sh` is a POSIX scaffold: it writes the sections as HTML comments and cannot ask anything (`allowed-tools: Bash`), and it must not. The interrogation is the command's job, and this section is the protocol it follows.

**Why it is mandatory.** A mission's whole value is that judgement is answered *before* the work starts. `development` / `overnight-ai`: *"identify in advance the points where AI would want to ask for judgment and write the answers to those questions into the ticket. We eliminate the causes of stopping in the night before the run starts."* A mission scaffolded with empty sections is an empty shell that stops the first time it meets a decision — and, because the mission lens's signal gate silences a `0/0` mission, it is an empty shell **nobody can see**.

**Grill; do not tick a box.** The bar is a *structured model* — the demanded behavior, the ticket plan, the order — not a question count and not a Q&A transcript pasted into a file (`planning` / `modeling-centric-design`). Ask as many rounds as it takes — but apply the **Recommended-label test** (`rules/interaction.md`) to every round: if you could honestly recommend an answer, **do not ask it** — decide it, record the decision where the plan is written (the mission `## Changelog`, or the relevant ticket's `## Quality Gate`), and let the developer veto it. "As many rounds as it takes" therefore means as many *unrecommendable* rounds as it takes: the grilling is undiminished on the genuine forks, and silent on the calls you could already make. Where uncertainty is high, prove it small before emitting the set (`planning` / `verify-before-building`): with no per-ticket approval downstream, an unverified premise is not caught at ticket 3 — it is concretized across the whole mission. (Note the strategy-resolution step above already runs this test explicitly — infer/create silently, ask only the unrecommendable multi-strategy fork.)

### Strategy resolution (before the rounds)

Every mission executes **one strategy** (`strategy`), so the first thing the interrogation resolves — before round 1's `## Goal`/`## Scope` output is written — is which strategy this mission executes. Resolve it by **inference from context** (the request, the repo, and the existing strategies via `bash strategy/scripts/list.sh`), following the decide-and-record doctrine — **do not ask a question you can answer**:

- **Link silently** when exactly one active strategy plausibly covers the mission. Stamp `strategy: <slug>` and record it — `strategy linked — <slug>` — via `append-changelog.sh`. No question.
- **Create on the spot** when no active strategy fits: mint one with `bash strategy/scripts/create.sh "<title>"`, deriving its `## Direction` from the mission's own `## Goal` **one level more general and end-condition-free**, then link and record `strategy created — <slug>`. No question.
- **Ask only** when several active strategies genuinely compete and no recommendation is honest — the sole unrecommendable case. The command issues one the agent's selection prompt (`[<project label>]` prefix, one option per candidate strategy plus "create new"), then records the chosen link.

The link is `strategy: <slug>` on `mission.md`, read back only through `strategy/scripts/read-strategy-relation.sh`. Both changelog events (`strategy linked` / `strategy created`) are in the standard-events list below. A mission is not drive-ready — and `validate-mission.sh` will not let it be stamped `drive_authorized: true` — until this link is resolved.

### Read recent reflections (before the rounds)

Before interrogating, read back what recent runs learned: `bash mission/scripts/list-reflections.sh` returns recent `## Reflection` entries across active and archived missions, newest first, each with its `blocked` / `leaked` / `front_load` bullets. Fold recurring **`front-load next:`** items into round 4's per-ticket pre-answers — a judgment call that leaked into a past night is exactly the question the next mission should pre-answer rather than meet again in the dark (`development` / `overnight-ai`). This closes the loop: planning quality is measured by how few judgment calls leak into the night, and the reflections are the record of which ones did.

### The rounds

1. **Direction** — the business "why", the outcome pursued, and what is explicitly out of scope. → `## Goal`, `## Scope`
2. **The demanded experience** — the user experience, the behavior required, and/or the overall structure. This is the mission's substance: what the thing *does*. Keep it observable. → `## Experience`
3. **The ticket set** — how many tickets, what each covers, and the `depends_on` order. **This is the round nobody asked before, and it is the one that matters most**: "more of a plan or tickets" is what makes a mission complete.
4. **Per-ticket pre-answers** — everything `create-ticket` §4b would ask later, asked now, per ticket in the set: acceptance criteria, verification method, the gate that must pass.
5. **Acceptance** — one `## Acceptance` item per criterion, each naming the ticket that satisfies it.

**Do not interrogate the mission gate.** `gate_*` is optional and normally empty (see *Quality gate*). Ask only if the developer volunteers a stable, objective outcome check; never treat its absence as an unfinished mission.

### Ordering

The requirement is *all questions before any ticket is created* — and `## Acceptance` items link tickets by `(#<filename>)`, which cannot exist until the tickets do. Both hold, because the **writing** order differs from the **asking** order:

> ask everything → decide the ticket set → write the tickets → write `## Acceptance` naming them.

Do not read the requirement as "Acceptance first".

### Emitting the set

Write the tickets **in one pass**, not N serial `create-ticket` runs. Each carries its mandatory `## Policies` and `## Quality Gate` (`validate-ticket.sh` rejects it otherwise), is stamped `mission: <slug>`, and is ordered by `depends_on` — foundation first, dependencies only where genuinely ordered, unique timestamps (`+1s` per ticket). Reuse `create-ticket`'s split mechanics rather than re-deriving them.

**The split cap does not apply to a mission — a deliberate, scoped exception.** `create-ticket` §4 caps a split at "2–4 discrete tickets", which is right for one request that turns out to be several. A mission is the opposite case: an execution plan that bundles *many* tickets by definition, and "a complete set to drive through one by one" is the requirement. Capping it at 4 would force either an incomplete plan or a fake ticket boundary. A mission decomposition is closer to `trip-protocol`'s Decomposition gate than to a `/ticket` split, and is governed by the same rule: **one ticket per genuinely separable unit of work, however many that is**. The cap still applies to `/ticket` itself; this exception is mission-scoped and stated here so it is not a silent violation.

**Stamp the duration prediction at the end of emission — as a report line, never a question.** Once the ticket set and `## Acceptance` are written, run `predict-duration.sh <acceptance-item-count>`: when `basis > 0`, stamp `predicted_hours` and state the number and its basis to the developer honestly ("predicted 6.0h from 2 archived missions"); when `basis: 0` (today's state, no archive), leave `predicted_hours` empty and record a `duration predicted (archive basis 0)` changelog note rather than dressing a guess as data (`planning` / `verify-before-building`). Never ask the developer for an estimate — the predictor answers this, and `actual_hours` is filled later by `/monitor`.

## Replan (re-entering the interrogation)

The sanctioned path to **reopen an existing active mission's plan** — reached without a subcommand: `/mission <instruction referencing the mission>` (the command owns the dispatch judgment and its written criteria). It exists because three legitimate states previously had no route back into the interrogation: a thin hand-authored `0/0` mission, a mid-flight mission whose scope grew, and a `carried` successor minted by `close.sh` with no worktree and no tickets — while the create flow dead-ends on an existing slug. Only `active` missions are replan targets; the archive is immutable history.

**Scoped re-interrogation.** Re-run the Creation Interrogation rounds the instruction touches — nothing more, nothing less:

| the instruction changes | rounds re-run |
| --- | --- |
| direction (goal, scope) | 1–2 |
| the plan (more/changed work) | 3–5, for the delta tickets |
| a thin mission (`0/0`, empty sections) | all five |

The bar equals creation's: a structured **delta model** — what changes, which tickets, in what order — not a Q&A transcript (`planning` / `modeling-centric-design`), grilled until the delta is drive-ready. The **Recommended-label test** applies exactly as at creation (`rules/interaction.md`): a delta decision you could honestly recommend is decided-and-recorded (a `## Changelog` line or the delta ticket's `## Quality Gate`), not asked; only the unrecommendable forks reach an the agent's selection prompt. `gate_*` is never interrogated, exactly as at creation.

**What the delta may touch** — everything the Creation Interrogation produces, applied as a delta: rewrite `## Goal` / `## Scope` / `## Experience`; append `## Acceptance` items (observable, ticket-linked by `(#<filename>)`); emit delta tickets in one pass (the same emission rules, including the mission-scoped split-cap exception); re-stamp `drive_authorized` under the conditions below.

**Strategy link on replan.** An active mission whose `strategy:` is still empty (a legacy or thin hand-authored mission that predates the link, or one that reached `/monitor`'s pre-flight as a replan item) gets the same **Strategy resolution** as at creation on its next replan — infer/create/ask, recorded as a `strategy linked` / `strategy created` changelog line. Re-stamping `drive_authorized: true` requires the link resolved, exactly as at creation.

**What a replan must never touch:**

- `status` — only `close.sh` flips it.
- the checked state of existing `## Acceptance` items — only `tick-acceptance.sh` flips those.
- existing `## Changelog` lines — append-only, always (`design` / `history-structures`).

An existing **unchecked** acceptance item may be reworded or dropped **only** when the developer explicitly says the criterion no longer holds — and the drop is recorded as its own changelog line (`acceptance dropped — <the item's (#filename) artifact>`), so the plan's shrinkage is history rather than a silent rewrite.

**History.** A replan lands as idempotent changelog lines through `append-changelog.sh`, never as edits: `ticket added — <filename>` per emitted ticket, plus one `mission replanned — <artifact>` line marking the event (both in the standard-events list below). Re-running the same replan appends nothing — the `(event, artifact)` key already exists.

**`drive_authorized` re-stamp.** The stamp asserts that every judgement call about *these exact tickets* was answered by the developer:

- already stamped `true` + a fully interrogated delta → the stamp stays / is re-set `true` (the original set was interrogated at creation, the delta now).
- never stamped (a hand-authored mission) → stamp only if the replan interrogated the **entire current set**, not just the delta.
- interrogation cut short → no stamp, ever.

## Mission Position Report

**The one definition of "where does the mission stand".** Every seam that hands work across a boundary states this; none re-states or re-derives it. It contains exactly three things:

1. **How far** — `checked/total`, from `progress.sh`. Computed, never narrated.
2. **What is next** — the next unchecked acceptance item, from `next-acceptance.sh`.
3. **How far a fresh session can proceed** — what is ready to drive right now, and what is waiting on a decision or an external blocker. This is the part a later session cannot reconstruct, and the reason the report exists.

Read every figure through those scripts (`implementation` / `domain-layer-separation`); never parse `mission.md` to answer this. The relation is **many-valued** — read it with `read-relation.sh` and report **every** mission the work advances, not the first.

**It is a report, never a prompt.** It states position and continues; it must not grow into a "shall I proceed?" — the whole direction is *less* confirmation.

**An empty `## Acceptance` (`0/0`) is reported honestly, not silenced.** The mission lens deliberately stays quiet on a `0/0` mission (an always-on nudge with nothing to act on is noise). A handoff is the **opposite** case: *"this mission has no criteria written yet"* is precisely what the next session needs to know, because it is the difference between "drive the queue" and "the plan does not exist yet". Do not copy the lens's signal gate here — this divergence is deliberate, not drift.

**Where it is stated:**

| seam | when |
| --- | --- |
| `/carry` | in the resumption ticket, when the in-flight work carries a `mission:` relation. Say nothing when it carries none — never fabricate a mission-shaped frame around unrelated work. |
| `/mission close` | before asking for the outcome, and again on a carry (what moved to the successor). |
| `/report`, `/ship` | **not** stated — recorded decision, below. |

`/report` and `/ship` roll missions but do **not** carry this report. Their audience is the PR reviewer, and the story's own sections already say what landed; adding mission position there would duplicate `/catch` and the lens for a reader who did not ask. The report exists for **continuity across a session boundary** — that is `/carry` and `/mission close`, where the context is otherwise lost. Decided rather than defaulted; revisit if a reviewer ever has to ask "which mission is this?".

## Progress Rule

Progress toward achievement is **derived, never stored**: `checked ÷ total` over the `## Acceptance` checklist. No `progress:` percentage is persisted anywhere — a stored number would drift from the checklist. `scripts/progress.sh` computes `{checked, total}` from the file on demand.

## Scripts

```bash
bash mission/scripts/create.sh "<title>" [assignee]
```

Create a new mission: derive the slug from the title (via `slug.sh`), scaffold `.workaholic/missions/active/<slug>/mission.md` (frontmatter + the four empty sections), stamp `created_at`/`author` from the `gather` skill, set `assignee` to the optional second argument or (default) the creator's `git config user.email`, refresh the OKF bundle indexes, and git-stage. Refuses to overwrite an existing mission in either area. Emits `{created, slug, path}` JSON. (The `/mission` command runs this with a mission worktree as the working directory, so `mission.md` lands inside `.worktrees/<slug>/` — see the command's create flow.)

```bash
bash mission/scripts/slug.sh "<title>"
```

Derive a mission slug from a title (lowercase, non-`[a-z0-9]` runs → single hyphen, ends trimmed). The **single source of the slug rule** — both `create.sh` (the mission directory name) and the `/mission` worktree flow (the `.worktrees/<slug>` directory name) derive the slug here, so the worktree directory always matches the mission slug. Emits the slug on stdout (empty when the title has no `[a-z0-9]`).

```bash
bash mission/scripts/read-relation.sh <artifact-file>
```

Read an artifact's `mission:` relation; prints one slug per line, nothing when absent or empty. The **single source of the relation's shape** — every seam reads through this rather than parsing frontmatter itself. Accepts `mission: [a, b]` and a bare `mission: a` alike, and only ever looks inside the frontmatter block (a body line starting `mission:` is not the relation). Never fails: a missing file, a file with no frontmatter, and an empty field all print nothing. Note this reads a relation **on** an artifact — `mission.md`'s own fields (`title`/`status`/`assignee`/`gate_*`) are read by `list.sh`, `progress.sh`, and `gate.sh` instead.

```bash
bash mission/scripts/drive-authorized.sh <ticket-file>
```

Answer, for one ticket: **may `/drive` implement this without the per-ticket approval prompt?** Emits `{authorized, reason, missions}` — `reason` is `""` (authorized), `no_ticket`, `no_mission` (nothing authorized it), `mission_not_found`, `not_authorized` (a claimed mission is not stamped), or `no_plan` (a claimed mission is stamped but its `## Acceptance` is empty — a stamp with no plan authorizes nothing; the floor is `progress.sh`'s `total > 0`). Reads the relation through `read-relation.sh`, so `mission: [a, b]` and a bare `mission: a` behave identically.

Missions get a write-time floor too: `hooks/validate-mission.sh` (PostToolUse `Write|Edit`, the mission analogue of `validate-ticket.sh`) lets `create.sh`'s empty scaffold pass, requires the `assignee:` key to exist (empty = deliberately unclaimed), and — once a mission claims `drive_authorized: true` — rejects a missing owner, an empty `strategy:` link, a comment-only `## Experience`, or an empty `## Acceptance` at the write, where the author can still fix it. `archive/` missions are history and are never retro-blocked.

**Conservative by construction**: a ticket claiming several missions is authorized only if **every** one of them is stamped. Naming a mission is a commitment, not a label — the same reason `/drive` holds a ticket to the gate of every mission it names ("all of them must pass, not the most convenient one"). One unauthorized mission means ask.

This is a **script, not prose**, on purpose: the approval gate lived entirely in `drive/SKILL.md` prose, which is why neither it nor night mode ever carried a single assertion. A rule that decides whether to ask a human for permission has to be reproducible and testable.

```bash
bash mission/scripts/gate.sh <mission-slug-or-file>
```

Read the mission's **quality-gate** declaration (`gate_type`/`gate_target`/`gate_assert`) and resolve the mission worktree's ports the gate is checked against. Emits `{type, target, assert, valid, driveable, reason, slug, port_base, dev_port, docs_port}`.

`valid` and `driveable` answer **different questions**, and the distinction is the point:

- **`valid`** — the *declaration* is well-formed: `gate_type` is empty or one of `documentation`/`live-app`/`check`. It says nothing about whether the gate can be run.
- **`driveable`** — the gate can actually be *exercised*: one is declared **and** its worktree ports resolved (for `check`, the worktree itself exists — no port is involved). `reason` names why not — `no_gate` (none declared: the **normal** case, not an error) or `no_worktree` (declared, but no worktree to serve or run its target in).

`driveable` exists because `valid: true` with empty ports reported success for a gate that could not be addressed at all: a mission could declare a live gate, pass validation, and be silently unverifiable. The port fields are `""` when the mission has no worktree.

The ports are resolved from the **main checkout** (`git rev-parse --git-common-dir`, whose dirname is the main root), **not** `--show-toplevel`: a mission lives in its own `.worktrees/<slug>/` and `/drive` auto-routes there, so `--show-toplevel` returns the worktree and the lookup becomes `<worktree>/.worktrees/<slug>/.env` — a path nothing creates. That returned empty ports for every mission in the prescribed layout.

`/drive` surfaces this for a missioned ticket so the work is judged against the mission's gate when one is declared; the live check runs the project's server on `dev_port` and drives `target` with the Playwright plugin.

```bash
bash mission/scripts/progress.sh <mission-file-or-slug>
```

Compute `{checked, total}` over a mission's `## Acceptance` checklist. Accepts either a path to `mission.md` or a bare slug.

```bash
bash mission/scripts/list.sh
```

List every mission — across both `active/` and `archive/` — with its `status`, `assignee`, computed progress, and its `predicted_hours`/`actual_hours`: a JSON array of `{slug, title, status, assignee, relation, next, checked, total, drive_authorized, ready, ready_reason, predicted_hours, actual_hours, path}`, sorted by slug (`path` is the resolved `mission.md` location, so consumers never rebuild it by hand). Emits `[]` when there are no missions. `relation` is the caller-centric partition (`mine` / `unassigned` / `others` — the same "not somebody else's" gate `summary.sh` and the lens inline, computed once here so consumers never re-derive it; a missing git email degrades to nothing-`mine`, never an error) and `next` is the first unchecked acceptance item via `next-acceptance.sh`. `ready`/`ready_reason` are the **planning-session drive-readiness verdict**: `ready: true` when the mission is `active`, has a plan (`total > 0`), and is stamped `drive_authorized: true`; otherwise `ready: false` with `ready_reason` naming the blocker (`no_plan` / `not_authorized` / `not_active`) so the bare `/mission` session can explain what a replan must fix. Together these let the bare `/mission` view render its two tiers and drive its replan loop with **no inline logic**. All keys are additive; older consumers parse a subset and are unaffected.

```bash
bash mission/scripts/summary.sh
```

Summarize the **current user's assigned active** missions (read-only). The `/mission summary` command mode this once powered is **retired** (2026-07-22 — the bare `/mission` view is developer-centric now, rendered from `list.sh`'s `relation` partition, so a my-business-only mode became a near-duplicate); the script stays because it is the **canonical statement of the shared assignee gate** — "not somebody else's": mine first, then unassigned/claimable, colleagues excluded — which the monitor skill's *Scope: whose missions* section and the mission lens both reference, and its business-set output still serves programmatic callers. **Its bar is deliberately lower than the mission lens's** (assignee alone — no location or signal gate), because the lens speaks unasked while this output is read on request: an unfilled `0/0` mission shows here (and in the bare view's full tier) that the lens stays silent about. Emits a JSON array `[{slug, title, checked, total, next, path}]` sorted by slug, or `[]` when no active mission is assigned to the current user. Reuses `progress.sh` and `next-acceptance.sh`, so the ownership and progress rules stay defined once. Mutates nothing.

```bash
bash mission/scripts/next-acceptance.sh <mission-slug-or-file>
```

Emit the display text of the mission's **first unchecked** `## Acceptance` item — the next criterion on the road to achievement — with its trailing `(#<filename>)` marker stripped. Scoped to the `## Acceptance` section with the same checklist convention as `progress.sh`. Prints nothing when every item is checked or the section is empty. The mission lens uses it to show "next: …" alongside `checked/total`.

```bash
bash mission/scripts/append-changelog.sh <mission-slug-or-file> <event> <artifact-filename> [date]
```

Append one dated line to a mission's `## Changelog`. **The single writer of changelog lines** — every workflow seam calls it rather than hand-editing `mission.md`. Append-only and **idempotent**: the `(event, artifact)` pair is the stable event id, so re-running for the same event never duplicates a line. Git-stages the mission file. Standard events: `ticket archived` (drive), `story reported` (report), `concern deferred (stuck)` (ship), `concern resolved (unstuck)` (report), `mission achieved` / `mission abandoned` / `mission carried into <successor-slug>` (close.sh), `ticket added` / `mission replanned` / `acceptance dropped` (replan), `strategy linked — <slug>` / `strategy created — <slug>` (Strategy resolution, creation or replan).

```bash
bash mission/scripts/tick-acceptance.sh <mission-slug-or-file> <artifact-filename>
```

Flip the `## Acceptance` item whose `(#<artifact-filename>)` marker matches from `- [ ]` to `- [x]`. Idempotent (an already-checked or unmatched item is a no-op) and scoped to the `## Acceptance` section. Progress stays derived — this changes only checklist state; `progress.sh` recomputes `checked/total`. Git-stages the mission file.

```bash
bash mission/scripts/predict-duration.sh <planned-item-count>
```

Predict a mission's agent-hours **deterministically** from archived-mission trend: `median(actual_hours ÷ acceptance-item total)` across archived missions carrying both, times the planned item count. Emits `{predicted_hours, basis, per_item_median}` — `predicted_hours: null` and `basis: 0` when no archived mission has both fields, so the create flow states confidence honestly instead of dressing a guess as data. **Pure read; writes nothing.** Called once at the end of the Creation Interrogation's emission.

```bash
bash mission/scripts/record-run-hours.sh <mission-slug-or-file> <hours> <run-id>
```

Accumulate a `/monitor` run's agent-hours into `actual_hours` (float add), **idempotently per run-id** — a run already recorded (its `run recorded (+Xh) — <run-id>` changelog line present) adds nothing, so a crash-recovery re-run is safe. The changelog line carries the increment so the sum reconstructs from history. **This is the only writer of `actual_hours`** (same doctrine as `tick-acceptance.sh`; never hand-edited). Emits `{recorded, actual_hours, run_id, path}`.

```bash
printf '%s' "<three-bullet body>" | bash mission/scripts/append-reflection.sh <mission-slug-or-file> <run-id> [date]
```

Append one dated `### <date> run <run-id>` reflection entry (body — the three fixed bullets — on stdin) under `## Reflection`, creating the section after `## Changelog` if absent. **Idempotent per run-id** and append-only (existing entries are never altered). The model composes the bullets; the script owns placement and idempotency, so the section stays machine-readable. Emits `{appended, run_id, path}`.

```bash
bash mission/scripts/list-reflections.sh [limit]
```

List recent reflection entries across active and archived missions, newest first, bounded (default 20): a JSON array of `{slug, date, run_id, blocked, leaked, front_load}` parsed from each entry's three bullets. **Read-only.** The Creation Interrogation reads this back before composing round 4, so recurring `front-load next:` items become pre-answered questions.

```bash
bash mission/scripts/close.sh <mission-slug-or-file> <achieved|abandoned|carried> [date] \
  [--successor-title "<title>" | --successor <slug>]
```

End a mission — the only sanctioned way. Flips `status`, appends the closing changelog line through `append-changelog.sh` so the transition itself becomes history (`design` / `history-structures`), moves the mission dir into `archive/`, refreshes the OKF indexes, and git-stages. Idempotent: re-closing with the same status is a no-op (`{closed: false, reason: "already_closed"}`); re-closing with another status flips it in place and appends its own line. Emits `{closed, slug, status, path}` JSON (plus `successor` / `successor_path` on a carry).

**Completion lifecycle — "merge and clean up" is a chain, not an auto-merge.** When a mission's tickets are all done, it moves through four stages, each with a distinct owner: **complete** (derived by `status.sh` — `## Acceptance` fully checked, gate exercised when declared) → **PR** (opened by `/monitor`'s §5 PR phase from the mission worktree's branch — auto-*creation*, so the morning starts at review) → **`/ship`** (the human, deploy-evidence-gated merge — full auto-merge was rejected: it would bypass PR review and the deploy-before-merge doctrine) → **`/mission close`** (archives the mission and tears down its worktree). Auto-merge is deliberately **not** part of this chain; the PR is where a night's work becomes reviewable, and the merge stays a human decision on evidence.

#### Outcomes

The status set is closed and validated — anything else is `invalid_status`:

| outcome | meaning |
| --- | --- |
| `achieved` | the goal was reached |
| `abandoned` | ended without reaching it, and the remainder is not worth doing |
| `carried` | done **as framed**, with the remainder still worth doing — it becomes a **successor** mission that inherits the unmet criteria |

`carried` exists because the other two could not express the common, honest verdict *"most of this landed, the rest is still worth doing"*. Forcing it into `achieved` lies to a progress model whose entire claim is that progress is **computed** from unchecked items and never hand-set; `abandoned` is simply false. It **requires** a successor — `--successor-title "<t>"` mints one, `--successor <slug>` carries into an existing active mission — because a carry with nowhere to carry to is an abandon wearing a nicer name. Do not let it become a way to avoid `abandoned`: a successor nobody drives is an abandoned mission with a longer name (the bare `/mission` view and the lens surface an unclaimed successor, which is a feature).

**What the successor inherits, and why:**

- The **unchecked** `## Acceptance` items, verbatim, with their `(#<filename>)` markers intact. Checked items stay with the predecessor — they were achieved *there*, and re-listing them would make the successor's computed progress claim work it did not do. The successor starts at `0/<n unmet>`, which falls out of its own list; **no number is ever carried across**.
- `## Goal`, `## Scope` and the `gate_*` fields, verbatim. A carry-over is a **continuation** by definition — the mission is done as framed and the remainder pursues the same outcome — so the goal is shared and the gate still applies. A genuine *re-framing* is a new mission, not a carry.

**Lineage is recorded in both directions** (`design` / `history-structures`): the predecessor's changelog gets `mission carried into <successor-slug>`, and the successor records `carried_from: <predecessor-slug>`. Without both, the archive shows a mission that stopped and a mission that started, with nothing joining them.

**The successor gets no worktree from the predecessor.** `close.sh` never managed worktrees (the `/mission` command tears the mission worktree down *after* `close.sh` succeeds), and a carry deliberately does not hand one over: `.worktrees/<slug>` is keyed 1:1 to the mission slug by `slug.sh`, and a successor living in the predecessor's directory **silences the mission lens inside that very worktree** — the lens reads a worktree whose basename names no active mission as a `/drive` worktree and says nothing at all. The successor gets a fresh worktree through the normal `/mission` flow; in-flight state and the port allocation do not carry.

#### When the direction changes — reorganize and carry (the encouraged answer)

A mission is **sticky to finish**: `achieved` demands every `## Acceptance` item checked, which is the right bar for a mission whose direction held. But a mission's direction often **changes mid-flight**, and then grinding to check the original criteria is effort spent against a plan that no longer describes the work. The **encouraged, positive** response in that case is **reorganize and carry** — not grind to `achieved`, not `abandoned`. Reach for it on any of three signals:

- **A different class of issue surfaced** — the work uncovered a problem the mission was not framed around, and the remaining criteria no longer point at what now matters.
- **The remaining criteria became contradictory or moot** — progress made the original plan internally inconsistent, or answered a criterion by making it irrelevant.
- **The remainder belongs to another active mission** — the leftover work is really that mission's, so it should **merge** there rather than persist as a parallel goal.

Why carry rather than the alternatives: forcing `achieved` **fabricates completion** the computed-progress model exists to prevent (progress is counted from unchecked items, never hand-set), and `abandoned` **discards real progress**. `carried` is the honest verdict — *"this landed as framed; the rest, reorganized, is still worth doing"* — and it **preserves** what was done while re-pointing the remainder.

**Reorganizing is a replan, then a carry — and it deliberately does not grind quality gates.** The mechanism is the existing **Replan** flow plus `close.sh`, used together and recorded, never hand-editing:

1. **Reorganize** via `/mission <instruction>` (the Replan flow): rewrite `## Goal`/`## Scope`/`## Experience` to the changed direction, and **drop the now-moot unchecked acceptance criteria** — do **not** force them checked. A dropped item is recorded as its own `acceptance dropped — <the item's (#filename) artifact>` changelog line (Replan already owns this), so the plan's shrinkage is history, not a silent rewrite. This is what *"skip filling quality gates"* means here: **stop grinding to check criteria the new direction made obsolete** — it is **not** a relaxation of the write-time floor (`hooks/validate-mission.sh` still requires a non-empty `## Acceptance` and `## Experience` once `drive_authorized`).
2. **Carry** the still-valid remainder with `close.sh … carried`: mint a fresh successor (`--successor-title "<t>"`) for a genuinely new heading, or — for the **mergeable** case — **`--successor <existing-slug>`** to carry the unchecked criteria into an existing active mission. Merging needs no new operation: `--successor <slug>` already carries the unmet items and shared goal/scope into the named mission, and lineage is recorded both directions (above).

The three checked-vs-unchecked, inherit, and lineage rules above are unchanged — reorganize-and-carry is those mechanics used *deliberately and early* when the direction turns, framed as the normal move rather than a last resort.

## Automatic Updates (the workflow seams)

The mutators above are called automatically as missioned work moves through the pipeline, so a mission's progress and changelog stay current without hand-editing. Each seam reads the artifact's `mission:` relation through the single reader — `bash mission/scripts/read-relation.sh <artifact>`, which prints one slug per line — and calls the shared scripts **once per slug**:

The relation is **many-valued**: an artifact records every mission it advances (`mission: [alpha, beta]`; a bare `mission: alpha` still reads as one, and is the right spelling for the common case). Looping needs no de-duplication — both mutators are keyed and idempotent, and `tick-acceptance.sh` finds nothing on a mission whose Acceptance does not list that artifact, so each mission reconciles only what it actually claims. Never re-implement the parse in a seam: the field's shape lives in `read-relation.sh` alone, and the four hand-rolled copies that used to exist all truncated a list to nothing **silently**, because every seam is best-effort (`|| true`).

**Non-blocking is not the same as silent.** A seam must never let a mission problem block the work it is archiving/shipping — but "does not block" and "is not reported" are two decisions, and only the first is wanted. The `drive` (`archive.sh`) seam captures each mutator's outcome and reports it at its own volume: a mutator that failed (non-zero exit) is named loudly, a mutator that ran and changed nothing (exit 0 with `"ticked": false` / `"appended": false` — the case a bare `|| true` never even catches, because nothing failed) prints the `reason` the mutator returns, and an ordinary success is one terse line. The reader is read with its exit code captured too, so a relation that could not be read is distinguished from a ticket that names no mission instead of being collapsed into it. Routing a mutator's stdout, stderr, and exit code all to `/dev/null` is the anti-pattern: it hides a mission that was never rolled behind a successful archive.

Note the split this rests on: **data is plural, placement is singular.** The relation answers "which missions does this work advance"; it says nothing about where the work happens. A ticket is still driven in exactly one worktree, and `.worktrees/<slug>` stays keyed 1:1 to a mission.

| Seam | Trigger | Changelog event | Acceptance |
| ---- | ------- | --------------- | ---------- |
| `drive` (`archive.sh`) | a missioned ticket is archived | `ticket archived` | ticks the ticket's item |
| `report` (story flow) | a missioned story is reported | `story reported` | reconciles items for the story's `tickets:` |
| `report` (`apply-deferred-concern-verdicts.sh`) | a missioned concern is judged resolved | `concern resolved (unstuck)` | — |
| `ship` (`extract-deferred-concerns.sh`) | a missioned concern is deferred | `concern deferred (stuck)` | — |

An un-missioned artifact touches no mission. Because the appends are idempotent, a re-run (retry, re-report) never double-counts.

### Read-only consumers

Separately from the mutating seams above, a workflow may **read** missions without writing them. `/catch` (`catch`) is such a consumer: its scanner calls `list.sh`/`progress.sh` for the active-mission list and derived progress, window-filters each mission's `## Changelog` for merged activity, and reads the `mission:` relation on unarchived tickets to surface **in-flight** (unmerged) progress the merge-time seams cannot yet show. It appears in no seam table because a `/catch` run mutates no mission content — no changelog line, no acceptance tick. (The one tree change any reader can trigger is the living layout migration, which relocates a legacy flat mission dir without touching its bytes.)

The **mission lens** (`hooks/mission-lens.sh`) is the other read-only consumer, and an always-on one. On every `UserPromptSubmit` it injects a model-visible `additionalContext` line, and on every `Stop` a user-visible `systemMessage`, naming each **active** mission that passes all three of its gates, with derived `checked/total` and the next unchecked acceptance item (via `progress.sh` + `next-acceptance.sh`):

1. **assignee** — matches the current `git config user.email`.
2. **location** — worktree focus: inside a mission's own `.worktrees/<slug>`, only that mission; inside a worktree that owns **no** mission (a `/drive` worktree), nothing at all; in the main tree, only missions that own no worktree.
3. **signal** — the mission has at least one acceptance criterion. A mission whose `## Acceptance` is empty would render as `0/0` with no next step — a technical condition with nothing to act on — so it stays silent.

It keeps the agent oriented to the roadmap without hijacking the turn — it never blocks a stop (informs, does not force). Silent no-op when nothing passes all three. The gap that made this matter is now closed upstream: the **Creation Interrogation** is mandatory and a mission is not finished being created until `## Acceptance` names at least one criterion, so a mission is no longer *born* matching the silence gate. `create.sh` still scaffolds the section empty — it is a POSIX scaffold and cannot interrogate — so a hand-authored `mission.md` that bypasses `/mission` can still arrive at `0/0` and stay invisible here (the bare `/mission` view's full tier and `/catch` keep the lower assignee-only bar and still show it). That residue is the same shape as the unassigned-mission gap: a default on the sanctioned path does not constrain the other paths. Like `/catch` it mutates nothing, so it is in no seam table. (Because a Stop hook cannot inject model-visible context without `decision: block`, the model-facing half deliberately rides `UserPromptSubmit`; the `Stop` half is the user-facing nudge only.)
