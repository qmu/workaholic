---
name: mission
description: Use when the user runs `/mission`, asks to "start a mission", "plan a batch of work", "show mission progress", or "what missions are in flight". A mission is an optional, epic-equivalent grouping — a bounded, information-rich batch of tickets an agent fleet drives together, never a required parent of any ticket; this skill creates one, lists missions with computed progress, and defines the mission schema every workflow reads.
allowed-tools: Bash
---

# Mission

A **mission** is a first-class knowledge artifact: an **optional, epic-equivalent grouping of tickets** — a fairly immediate developer request, interrogated to question-free drive-readiness, that bundles the ordered ticket set an agent fleet drives through together (typically overnight). It carries the information-rich statement of *what this batch of tickets accomplishes* and *how far it has come*, with a machine-readable web of relations to the tickets, stories, and concerns that advance it. The mission is bounded, not long-lived — and **never a required parent**: the ticket stays the first-class standalone unit, and `/ticket` → `/drive` with no mission is a fully sanctioned path. Long-lived *direction* accretes in the [feedback stream](../feedback/SKILL.md) (`docs/loop-engineering-workflow.md`, decisions B3/B5).

Distinguish the terms and never conflate them (`planning` / `terminology`):

- **feedback** — the inbound stream of project context (`feedback`); long-lived **direction** lives here, as accumulated insights and instructions. It answers *why is this work being launched*.
- **mission** — an **optional, epic-equivalent grouping**: a bounded batch of tickets with acceptance criteria and an append-only changelog. It answers *what does this batch of tickets accomplish together*. A mission finishes; the stream persists.
- **trip** — a short, bounded design/build *session* (Planner/Architect/Constructor) that produces design rationale and decomposes into tickets.
- **epic / milestone** — generic project-management words this repo deliberately does **not** use as artifact names. "Mission" is the word for this level.

See the **Granularity** section below for the full commit → ticket → mission discipline and the record of how "mission" was redefined twice.

## Granularity

The **single home** of the granularity discipline (`planning` / `modeling-centric-design`). Four description layers each describe code change and its planning at *their own* level, and **no artifact restates a lower level's detail**:

| Layer | Answers | Size | Normalized by |
| --- | --- | --- | --- |
| **commit** | *what is this one normalized change* | ~a few hundred lines, one reviewable unit | the release-scan per-commit changed-lines gate (ticket `20260721020759`) |
| **ticket** | *what is this one change* (a single drive-able unit) | one `/drive` pass, with its own `## Quality Gate` | its `## Policies` / `## Quality Gate` |
| **mission** | *what does this batch of tickets accomplish together* (optional — a ticket needs no mission) | hours of agent time; a fairly immediate request interrogated to question-free readiness | the Creation Interrogation |

"Why is this work being launched" is answered one level up by the **feedback stream** (`feedback`) — accumulated direction, not an artifact layer of its own.

**The balance test cuts both ways.** A mission that re-narrates its tickets' specifics is **over-written** — trust the ticket to hold the detail. A ticket that says essentially what its mission says means the **mission is under-sized** — a mission must be bigger than any one ticket; surface that and merge, do not write the duplicate. Neither is "add more words"; both are "put each fact at exactly one level".

### Redefinition record

Recorded here so it is not re-litigated (`planning` / `terminology`):

- **First meaning** (before 2026-07-21): "mission" was the long-lived container — "a durable goal spanning many tickets over a long horizon; it outlives any single branch or session".
- **Second meaning** (2026-07-21): "the overnight-executable execution plan of a strategy" — bounded, with longevity moved up to a new `strategy` artifact. Reason: the mission was playing two roles at once — the executable unit *and* the long-lived goal container. Provenance: mission `reorganize-missions-under-strategies`.
- **Current meaning** (2026-07-28): an **optional, epic-equivalent grouping of tickets** — bounded, never a required parent. The strategy layer is **retired**: direction accretes in the feedback stream instead of a second direction artifact (two homes would drift), and mission ownership returned to the mission itself. The 2026-07-21 phrase is superseded on both ends — the strategy end and the mandatory-sounding framing (`docs/loop-engineering-workflow.md`, decisions B3/B5; provenance: mission `loop-engineering-foundation`). Retired strategies survive verbatim as feedback records (`migrate-strategies.sh`).

Every other place that touches granularity **links here** rather than restating it (`create-ticket`, `commit`).

## Lifecycle — one status axis

**A mission has exactly one lifecycle field.** `status` carries the whole state, and every reader keys on it:

| state | area | meaning |
| --- | --- | --- |
| `draft` | `active/` | proposed, not yet answered for. Written by `create.sh` (before its interrogation) and by the `/propose` batch (`scaffold-draft.sh`). Invisible to executors. |
| `approved` | `active/` | a human answered every judgment call about **this exact plan**, and recorded whether its completed units may merge automatically. `/drive` may drain its queue without the per-ticket prompt. |
| `achieved` | `archive/` | the goal was reached. |
| `abandoned` | `archive/` | ended without reaching it, and the remainder is not worth doing. |
| `carried` | `archive/` | done **as framed**; the remainder became a successor mission. |

Transitions, and **who** performs each — every flip is a script, never a hand-edit:

```
(create.sh | scaffold-draft.sh) ──▶ draft ──approve.sh──▶ approved
                                      │                      │
                                      └──────close.sh────────┴──▶ achieved | abandoned | carried
```

- **`/propose` and `/mission "<title>"` mint drafts.** A scaffold predates its interrogation, so nothing about it has been approved.
- **`approve.sh` is the only path to `approved`.** It clears the floor (owner + `## Experience` + `## Acceptance`), records `merge_policy`, seeds the approver as owner, and writes the transition to the `## Changelog`.
- **`close.sh` is the only path to an end state**, from *either* in-flight state — an approved mission that ran, or a draft nobody approved.

### Redefinition record — `drive_authorized` → `status: approved`

Recorded here so it is not re-litigated (`planning` / `terminology`): the separate `drive_authorized: true` stamp is **retired into the status** (2026-07-28 — `docs/loop-engineering-workflow.md` decision I2). "Approved" is precisely what the stamp asserted — a human answered every judgment call about this exact plan — so carrying both a `status` and a boolean meant **one concept wearing two words**, in two fields that could disagree (a mission could be `active` and unstamped, `active` and stamped, or, after a hand-edit, stamped and archived). One concept, one word.

Consequences, stated so no reader has to infer them:

- **New missions never carry the key.** Neither scaffold writes it.
- **Legacy files migrate on the next mission-script touch** (`lib/resolve.sh`): `status: active` + `drive_authorized: true` → `approved`; `status: active` without the stamp → `draft`; the retired key line is dropped from the rewritten file.
- **Readers keep a legacy-tolerance branch** — `drive-authorized.sh`, `hooks/validate-mission.sh` and the pre-flight still honor a `drive_authorized: true` stamp — only for the transition window, so a mission in an untouched checkout is not silently de-authorized mid-drive.
- **"Active" is now the name of an *area*, not a state.** Prose saying "active missions" means the active area — drafts plus approved. Do not reintroduce `active` as a status word.

### Merge policy — the orthogonal axis

`merge_policy: auto | review` is a **separate** axis from the lifecycle (decision G5), and the one genuinely human ruling the approval flow owns: **may this mission's completed units merge automatically, or must a human review the PR?** It is recorded at **approval**, not creation — a draft has no approver yet — and `approve.sh` **requires** it: there is no default, because `auto` by default grants unattended merging nobody asked for and `review` by default silently discards the question. Tickets carry the same field, asked at their creation (the human is present); on a ticket, **absent means `review`** — see `create-ticket`.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Where a step uses the agent's selection prompt (the `/mission` command's create/list choice), use the agent's native selection prompt; only the mechanism varies. All logic lives in the bundled POSIX scripts, which run identically everywhere.

## Allowed Location

A mission lives in one of two areas — mirroring the tickets `todo/`-vs-`archive/` split — selected by its `status`:

```
.workaholic/missions/active/<slug>/mission.md    # status: draft | approved (in flight)
.workaholic/missions/archive/<slug>/mission.md   # status: achieved | abandoned | carried (ended)
.workaholic/missions/index.md                    # regenerated by okf/refresh-index.sh, one entry per mission per area
```

A **draft** (`status: draft`) is a mission nobody has approved yet — written either by `create.sh` (before its Creation Interrogation completes) or by the `/propose` batch (`propose` — `scaffold-draft.sh`, which additionally leaves it unowned, `assignees: []`, and carries a `feedback:` list naming the records it grew from, read via the propose skill's single reader `read-feedback-relation.sh`). A draft lives in `active/` (in flight, not history), is invisible to executors (only approved work runs), and reports `ready_reason: "draft"` in `list.sh`.

`<slug>` is derived from the title: lowercased, every run of non-`[a-z0-9]` characters collapsed to a single hyphen, leading/trailing hyphens trimmed (e.g. `"Real-time Notifications"` → `real-time-notifications`). One directory per mission; the directory name **is** the slug and is the stable key other artifacts reference (`mission: <slug>`). The area is **never** part of that key — seams pass bare slugs and the scripts resolve the location, so a mission's move to `archive/` breaks no relation.

Resolution takes an explicit **root** (a `.workaholic` directory), never the process cwd. A seam that holds an artifact (a ticket, a `mission.md`) derives the root from *that artifact's own path* — the mission tree is fixed by where the ticket lives (its worktree), so `mission: <slug>` on a worktree ticket resolves to *that* worktree's mission from any cwd. A caller with only a slug and no artifact (`create.sh`, `close.sh`) roots on the repository it runs in (via `git rev-parse`). `lib/resolve.sh` is the single source of this: `missions_root_from_artifact` / `missions_root_default` / `missions_root_for_arg` choose the root, and `mission_resolve <root> <arg>` returns an **absolute** `mission.md` path — so two same-slug missions in two worktrees never yield the same string, and which file was read is visible in the output rather than hidden behind a cwd-relative path.

The scripts own all placement: `create.sh` writes into `active/`, `close.sh` moves to `archive/`, and every script runs the **living migrations** first — a legacy flat `missions/<slug>/` dir (the pre-split layout) is relocated into the area its `status` selects (`git mv`, preserving history), and a legacy `status: active` mission is normalized onto the one status axis (`approved` when it carried `drive_authorized: true`, else `draft`, with the retired key line dropped). Both are idempotent and best-effort (a failure never blocks the calling seam; the resolver still finds an unmovable flat mission, and every reader tolerates the pre-migration shape). Never `mv` a mission dir or hand-edit `status:` yourself.

## Schema

`mission.md` carries this frontmatter (the `type: Mission` line is the OKF conformance floor):

```yaml
---
type: Mission
title: <human title>
slug: <slug>
status: draft           # draft | approved | achieved | abandoned | carried — the ONE lifecycle axis, and it selects the area (draft/approved in active/, the rest in archive/). Flipped only by approve.sh (draft → approved) and close.sh (either → an end state); never by hand
merge_policy:           # auto | review — the orthogonal merge axis (G5), recorded by approve.sh at approval. Empty on a draft; never defaulted to auto
carried_from:           # only on a successor: the slug of the mission whose remainder it inherited
created_at: <ISO-8601>
author: <email>
assignees: [<email>]    # the mission's OWNERS (plural — a mission can be co-owned). Creator-seeded by create.sh (the approver is the default owner); empty = team-owned/claimable. Read ONLY via mission-owners.sh
assignee: <email>       # LEGACY FALLBACK only (missions predating `assignees`). Empty on new missions; never read directly
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

### Approval — the drive authorization

`status: approved` records that this mission's ticket set was **interrogated and approved** by a human: `/drive` may then drain its queue **without the per-ticket approval prompt**. `draft` (the scaffold default) means ask, as always. The flip is performed only by `approve.sh` (below), which also records the `merge_policy` ruling and seeds the approver as owner.

**Authorization lives here, on the mission, because this is the thing that was actually interrogated.** The Creation Interrogation is where the developer answered every judgement call and co-authored each ticket's `## Quality Gate`; approving the mission is approving that act. Two alternatives were considered and rejected, recorded so they are not re-litigated:

- **Keying off the ticket's `mission:` relation alone** — a ticket hand-added to the mission later would inherit an authorization nobody granted.
- **An explicit `/drive mission` argument** — mirrors night mode, but makes authorization an act by whoever runs `/drive`, who may not be the person who ran the interrogation.
- **A separate `drive_authorized` boolean beside the status** — the original spelling, retired 2026-07-28 (see the *Redefinition record* above): two fields for one concept, free to disagree.

**Explicit approval is relocated, never removed.** The gate is skipped exactly when a prior explicit batch authorization covers the ticket — `/drive night`'s invocation, or this approval — and never otherwise. What is removed is the *completeness check inside the drive loop*; the qualitative looking-through `development` / `qa-engineering` makes non-delegable **relocates to the PR** (`/report` still writes the story, `/ship` still gates the merge on evidence). Do not blur those two: eliminate the completeness check and you are on policy; eliminate the looking-through and you are in the state three policies exist to prevent.

Read it with `drive-authorized.sh` — never by grepping the field yourself.

### Ownership — carried on the mission (2026-07-28)

**A mission's owners are its own plural `assignees` list.** The creator/approver is the default owner (`create.sh` seeds the list with the creator); an empty list means the mission is **team-owned** — unclaimed work, surfaced to everyone as claimable.

Redefinition record, so the moves are not re-litigated: ownership lived on the mission (`assignee`, singular) → moved to the strategy's `assignees` (2026-07-24 — "a direction is what a set of people own") → **returned to the mission, plural, 2026-07-28**: the loop-engineering reorganization retired the strategy layer (direction now accretes in the feedback stream — `docs/loop-engineering-workflow.md` decisions B3/B4), and in the team + AI-proposal model the approver of a mission, not the owner of a direction, is who answers for it. The single-oracle design is what made both moves cheap; the living migration (`migrate-strategies.sh`) folded strategy assignees down into their missions so the strategy hop could go without orphaning anything.

Read a mission's owner(s) **only** through `mission/scripts/mission-owners.sh` — never by grepping `assignee` or `assignees`. It is the single ownership oracle; first non-empty tier wins:

1. the mission's own `assignees` (via `mission/scripts/read-assignees.sh`, the single parser of the field shape — list and bare forms);
2. **legacy fallback**: the mission's own singular `assignee`, so missions predating the plural field are never orphaned.

Prints one owner per line; **empty output means unowned** — unclaimed work, surfaced to everyone as claimable. A mission may be **co-owned**; "mine" means the caller is **among** the owners, not the sole one.

**Not somebody else's, not exactly mine.** `summary.sh`, the **mission lens**, `list.sh`'s `relation`, and `/monitor`'s pre-flight all gate on "is this mission my business" — the caller is among the owners (mine, shown first), or there are no owners (unassigned, shown as claimable, after your own); a mission owned only by others stays silent. All four read through `mission-owners.sh`, so the gate is defined once.

**Claiming a mission = a one-line edit to that mission** — add yourself to its `assignees`. The claim is mission-local: it commits you to this plan and nothing else.

This is per-worktree by construction — each worktree checks out its own `.workaholic/`, so the lens that fires there reflects the missions that are the business of whoever is working that tree.

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

**Grill; do not tick a box.** The bar is a *structured model* — the demanded behavior, the ticket plan, the order — not a question count and not a Q&A transcript pasted into a file (`planning` / `modeling-centric-design`). Ask as many rounds as it takes — but apply the **Recommended-label test** (`rules/interaction.md`) to every round: if you could honestly recommend an answer, **do not ask it** — decide it, record the decision where the plan is written (the mission `## Changelog`, or the relevant ticket's `## Quality Gate`), and let the developer veto it. "As many rounds as it takes" therefore means as many *unrecommendable* rounds as it takes: the grilling is undiminished on the genuine forks, and silent on the calls you could already make. Where uncertainty is high, prove it small before emitting the set (`planning` / `verify-before-building`): with no per-ticket approval downstream, an unverified premise is not caught at ticket 3 — it is concretized across the whole mission.

### Read recent reflections (before the rounds)

Before interrogating, read back what recent runs learned: `bash mission/scripts/list-reflections.sh` returns recent `## Reflection` entries across active and archived missions, newest first, each with its `blocked` / `leaked` / `front_load` bullets. Fold recurring **`front-load next:`** items into round 4's per-ticket pre-answers — a judgment call that leaked into a past night is exactly the question the next mission should pre-answer rather than meet again in the dark (`development` / `overnight-ai`). This closes the loop: planning quality is measured by how few judgment calls leak into the night, and the reflections are the record of which ones did.

### Elicit the requirements first — the *what*, before any plan (the highest-leverage gate)

**Plan quality gates everything. No amount of downstream verification rescues a plan built on a wrong understanding of the goal** — an unattended run faithfully amplifies a shallow plan into hours of unusable output, and "the artifact exists / the tests pass" cannot see whether the *thing itself* was the wrong thing. So the first job of the interrogation is not the ticket set; it is to **draw out of the developer the requirements the agent cannot derive** from the code, the ticket title, or the repo: what a user must actually be able to *do*, what a **correct/good output looks like (ask for a concrete example)**, and the **real end-to-end workflow**. Ask specific, concrete questions about the actual unknowns the plan depends on — never a generic "any feedback?".

This is a distinct discipline from the **decide-don't-ask** rule the execution phase follows (`drive`'s *When the gate is skipped*, `monitor` §1): that rule governs **execution-time decidable choices** (which fixable failure to retry, finalize-now vs. push) — the *how* — and rightly says decide, do not offload. **Requirements elicitation is the opposite case: the *what*, which the developer holds and the agent cannot derive.** Decide the *how*; never assume the *what*. The two do not conflict once separated, and the decide-don't-ask rule must not be over-read into "don't elicit requirements."

Three hard gates on this step:

- **A developer's invitation to ask is a hard gate.** If the developer signals "ask me what you need to firm this up", failing to ask is a **planning defect**, not efficiency — the one time the elicitation is most owed is exactly when it was invited.
- **A user-facing feature may not be planned from a title.** The plan must encode what *usable* means for a real person, because the agent's own checks cannot see usability. For user-facing work, require an **example of a good output** and a **walked end-to-end workflow** before the plan is committed.
- **If the goal is not yet understood well enough to write verifiable, user-experience-level `## Acceptance` criteria, the plan is not ready** — keep eliciting; do not start building. Long autonomous execution on an un-elicited plan is the anti-pattern this gate exists to prevent (`planning`; `development` / `overnight-ai`).

Every genuine requirements question is a legitimate the agent's selection prompt — it is precisely the "developer holds information you cannot derive" fork the Recommended-label test never silences (`rules/interaction.md`).

### The rounds

1. **Direction** — the business "why", the outcome pursued, and what is explicitly out of scope. → `## Goal`, `## Scope`
2. **The demanded experience** — the user experience, the behavior required, and/or the overall structure, **elicited per the gate above** (for user-facing work: the concrete example of a good output and the walked workflow, not a title-level guess). This is the mission's substance: what the thing *does*. Keep it observable, at the user-experience level. → `## Experience`
3. **The ticket set** — how many tickets, what each covers, and the `depends_on` order. **This is the round nobody asked before, and it is the one that matters most**: "more of a plan or tickets" is what makes a mission complete.
4. **Per-ticket pre-answers** — everything `create-ticket` §4b would ask later, asked now, per ticket in the set: acceptance criteria, verification method, the gate that must pass.
5. **Acceptance** — one `## Acceptance` item per criterion, each naming the ticket that satisfies it. **For user-facing work, at least one criterion must be phrased at the user-experience level** (what a person can do / what the output looks like), not only "artifact exists / tests pass".

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

The sanctioned path to **reopen an existing active mission's plan** — reached without a subcommand: `/mission <instruction referencing the mission>` (the command owns the dispatch judgment and its written criteria). It exists because three legitimate states previously had no route back into the interrogation: a thin hand-authored `0/0` mission, a mid-flight mission whose scope grew, and a `carried` successor minted by `close.sh` with no worktree and no tickets — while the create flow dead-ends on an existing slug. Only **in-flight** missions (`draft` or `approved` — the active area) are replan targets; the archive is immutable history.

**Surface sibling PRs before re-interrogating.** A replan grows the plan, so it must first see whether another lane is already implementing the same acceptance. Run `list-related-prs.sh <slug>` (below) and, when it returns open PRs referencing the mission, factor them into the delta rather than emitting tickets that duplicate a sibling's unmerged work. The check is best-effort — `available: false` means it could not run (no `gh`/auth/remote), which is *unknown*, not *no siblings*. This is the replan-side complement to `create-mission-worktree.sh`'s fetch-first base resolution: the fetch keeps a new worktree off a stale *merged* base; this keeps a replan off a sibling's *unmerged* work.

**Scoped re-interrogation.** Re-run the Creation Interrogation rounds the instruction touches — nothing more, nothing less:

| the instruction changes | rounds re-run |
| --- | --- |
| direction (goal, scope) | 1–2 |
| the plan (more/changed work) | 3–5, for the delta tickets |
| a thin mission (`0/0`, empty sections) | all five |

The bar equals creation's: a structured **delta model** — what changes, which tickets, in what order — not a Q&A transcript (`planning` / `modeling-centric-design`), grilled until the delta is drive-ready. The **Recommended-label test** applies exactly as at creation (`rules/interaction.md`): a delta decision you could honestly recommend is decided-and-recorded (a `## Changelog` line or the delta ticket's `## Quality Gate`), not asked; only the unrecommendable forks reach an the agent's selection prompt. `gate_*` is never interrogated, exactly as at creation.

**What the delta may touch** — everything the Creation Interrogation produces, applied as a delta: rewrite `## Goal` / `## Scope` / `## Experience`; append `## Acceptance` items (observable, ticket-linked by `(#<filename>)`); emit delta tickets in one pass (the same emission rules, including the mission-scoped split-cap exception); run the approval under the conditions below.

**What a replan must never touch:**

- `status` — only `approve.sh` (draft → approved) and `close.sh` (→ an end state) flip it.
- the checked state of existing `## Acceptance` items — only `tick-acceptance.sh` flips those.
- existing `## Changelog` lines — append-only, always (`design` / `history-structures`).

An existing **unchecked** acceptance item may be reworded or dropped **only** when the developer explicitly says the criterion no longer holds — and the drop is recorded as its own changelog line (`acceptance dropped — <the item's (#filename) artifact>`), so the plan's shrinkage is history rather than a silent rewrite.

**History.** A replan lands as idempotent changelog lines through `append-changelog.sh`, never as edits: `ticket added — <filename>` per emitted ticket, plus one `mission replanned — <artifact>` line marking the event (both in the standard-events list below). Re-running the same replan appends nothing — the `(event, artifact)` key already exists.

**Approval after a replan.** `approved` asserts that every judgement call about *these exact tickets* was answered by a human, so a replan that changes the ticket set re-opens that question:

- already `approved` + a fully interrogated delta → it stays approved (the original set was interrogated at creation, the delta now). Re-running `approve.sh` with the same `merge_policy` is a no-op success; passing a different one records the policy change as its own changelog line.
- still a `draft` (a hand-authored mission, a `/propose` proposal, a `carried` successor) → run `approve.sh` only if the replan interrogated the **entire current set**, not just the delta. This is the sanctioned path from proposal to drive-ready.
- interrogation cut short → no approval, ever; the mission stays a draft.

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

Create a new mission: derive the slug from the title (via `slug.sh`), scaffold `.workaholic/missions/active/<slug>/mission.md` (frontmatter + the four empty sections), stamp `created_at`/`author` from the `gather` skill, seed `assignees` with the optional second argument or (default) the creator's `git config user.email` (the approver is the default owner), refresh the OKF bundle indexes, and git-stage. Refuses to overwrite an existing mission in either area. Emits `{created, slug, path}` JSON. (The `/mission` command runs this with a mission worktree as the working directory, so `mission.md` lands inside `.worktrees/<slug>/` — see the command's create flow.)

```bash
bash mission/scripts/slug.sh "<title>"
```

Derive a mission slug from a title (lowercase, non-`[a-z0-9]` runs → single hyphen, ends trimmed). The **single source of the slug rule** — both `create.sh` (the mission directory name) and the `/mission` worktree flow (the `.worktrees/<slug>` directory name) derive the slug here, so the worktree directory always matches the mission slug. Emits the slug on stdout (empty when the title has no `[a-z0-9]`).

```bash
bash mission/scripts/read-relation.sh <artifact-file>
```

Read an artifact's `mission:` relation; prints one slug per line, nothing when absent or empty. The **single source of the relation's shape** — every seam reads through this rather than parsing frontmatter itself. Accepts `mission: [a, b]` and a bare `mission: a` alike, and only ever looks inside the frontmatter block (a body line starting `mission:` is not the relation). Never fails: a missing file, a file with no frontmatter, and an empty field all print nothing. Note this reads a relation **on** an artifact — `mission.md`'s own fields (`title`/`status`/`gate_*`) are read by `list.sh`, `progress.sh`, and `gate.sh` instead.

```bash
bash mission/scripts/mission-owners.sh <mission-file>
```

Resolve **who owns a mission** — the single ownership oracle (2026-07-28). First non-empty tier wins: the mission's **own plural `assignees`** (via `mission/scripts/read-assignees.sh`, the single parser of the field shape), then a **legacy fallback** to the mission's own singular `assignee`, so a mission predating the plural field is never orphaned. Prints one owner per line; **empty output means unowned** (claimable). Every ownership consumer — `list.sh`'s `relation`, `summary.sh`, `hooks/mission-lens.sh`, `/monitor`'s pre-flight, `hooks/validate-mission.sh`'s authorized-owner floor, and `ship`'s concern-lane owner — reads through this, never by parsing the fields itself.

```bash
bash mission/scripts/read-assignees.sh <file>
```

Read a file's `assignees:` frontmatter field, one owner per line — **the single parser of the field shape** (inline-list `[a, b]` and bare-scalar forms; empty/absent prints nothing). Born on the strategy side (2026-07-24) and relocated here when ownership returned to the mission; `mission-owners.sh`'s primary tier reads through it.

```bash
bash mission/scripts/migrate-strategies.sh [workaholic-root]
```

Retire a lingering `.workaholic/strategies/` tree — the direct/test entry to the living migration every mission script also runs through `lib/resolve.sh`'s seam (`missions_migrate_strategies`; the logic lives there so the two entries cannot drift). Each strategy document survives **verbatim** as a feedback record (`feedbacks/<ts>-strategy-<slug>.md`, `kind: insight`, `source: discussion`, original author/`created_at` preserved; the timestamp derives from `created_at`, so the migration is deterministic and idempotent), its `assignees` fold down into each linked active mission whose own `assignees` is still empty, and then the directory is removed (`git rm` when tracked). Best-effort: a failure never blocks the calling seam. Nothing is deleted from knowledge, only from structure.

```bash
bash mission/scripts/approve.sh <mission-slug-or-file> <auto|review> [date]
```

**Approve a mission — the only sanctioned path to `status: approved`.** It clears the floor first, mutates only after: `## Experience` must carry non-comment content and `## Acceptance` at least one checklist item (the same floor `hooks/validate-mission.sh` enforces at write time, asserted here at the moment the authority is granted), and the mission must have an owner — an unowned one is **seeded with the approver** (`git config user.email`; decision B4: the approver is the default owner), refused only when there is no identity to seed. Then it sets `status: approved` and `merge_policy`, drops any legacy `drive_authorized` key still present, appends `mission approved — merge_policy: <p>` to the `## Changelog`, refreshes the OKF indexes, and git-stages. It never commits — the calling flow owns the commit seam.

The `merge_policy` argument is **required** and enum-validated (`auto` | `review`): it is the one genuinely human ruling this flow owns (decision G5), and neither default is honest (see *Merge policy* above). The history is appended **before** the status flip, so a mission that cannot record its own approval is refused rather than approved untraceably.

**Idempotent**: re-approving with the same policy is a no-op success (`reason: "already_approved"`); re-approving with a *different* policy records the change as its own changelog line, because the policy rides in the event id. Emits `{approved, slug, status, merge_policy, owners, path, reason}`; a refusal exits non-zero with `reason` one of `missing_args`, `invalid_merge_policy`, `not_found`, `not_in_flight` (the mission has ended — history is immutable), `no_owner`, `no_experience`, `no_plan`, `no_changelog_section`.

```bash
bash mission/scripts/drive-authorized.sh <ticket-file>
```

Answer, for one ticket: **may `/drive` implement this without the per-ticket approval prompt?** Emits `{authorized, reason, missions}` — `reason` is `""` (authorized), `no_ticket`, `no_mission` (nothing authorized it), `mission_not_found`, `not_authorized` (a claimed mission is not `status: approved` — a draft, or an ended mission), or `no_plan` (a claimed mission is approved but its `## Acceptance` is empty — approval with no plan authorizes nothing; the floor is `progress.sh`'s `total > 0`). Reads the relation through `read-relation.sh`, so `mission: [a, b]` and a bare `mission: a` behave identically. A legacy `drive_authorized: true` stamp is still honored for the transition window, so a mission in a checkout the living migration has not touched is not de-authorized mid-drive; the JSON contract (including the `not_authorized` key) is unchanged, so `/drive` callers needed no change.

Missions get a write-time floor too: `hooks/validate-mission.sh` (PostToolUse `Write|Edit`, the mission analogue of `validate-ticket.sh`) lets a **draft** pass with **nothing required** (that is the scaffold moment, and `create.sh` scaffolds a draft by design), and — once a mission claims `status: approved` (or a legacy `drive_authorized: true`) — rejects a **missing owner** (`mission-owners.sh` empty — its own `assignees` and the legacy `assignee` both empty; unattended work needs an owner), a comment-only `## Experience`, or an empty `## Acceptance` at the write, where the author can still fix it. (A legacy `strategy:` key from the retired strategy layer is tolerated and ignored.) `archive/` missions are history and are never retro-blocked.

**Conservative by construction**: a ticket claiming several missions is authorized only if **every** one of them is approved. Naming a mission is a commitment, not a label — the same reason `/drive` holds a ticket to the gate of every mission it names ("all of them must pass, not the most convenient one"). One unapproved mission means ask.

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

List every mission — across both `active/` and `archive/` — with its `status`, recorded `merge_policy`, derived ownership, computed progress, and its `predicted_hours`/`actual_hours`: a JSON array of `{slug, title, status, merge_policy, assignee, owners, relation, next, checked, total, ready, ready_reason, predicted_hours, actual_hours, path}`, sorted by slug (`path` is the resolved `mission.md` location, so consumers never rebuild it by hand). Emits `[]` when there are no missions. `owners` is the full owner set (`mission-owners.sh` — the mission's own `assignees` first, then the legacy `assignee`), `assignee` aliases the first owner for back-compat, and `relation` is the caller-centric partition (`mine` / `unassigned` / `others` — the same "not somebody else's" gate `summary.sh`, the lens, and `/monitor` read, all through `mission-owners.sh`, computed once here so consumers never re-derive it; a missing git email degrades to nothing-`mine`, never an error). `next` is the first unchecked acceptance item via `next-acceptance.sh`. `ready`/`ready_reason` are the **planning-session drive-readiness verdict**, keyed on the one status axis: `ready: true` when the mission is `approved` and has a plan (`total > 0`); otherwise `ready: false` with `ready_reason` naming the blocker — `draft` (awaiting approval: an approval target, not a replan target), `no_plan` (empty `## Acceptance`), or `not_active` (an ended mission) — so the bare `/mission` session can explain what is missing. The retired `not_authorized` reason is gone: an unapproved mission *is* a draft. Together these let the bare `/mission` view render its two tiers and drive its replan loop with **no inline logic**. All keys are additive; older consumers parse a subset and are unaffected.

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

Append one dated line to a mission's `## Changelog`. **The single writer of changelog lines** — every workflow seam calls it rather than hand-editing `mission.md`. Append-only and **idempotent**: the `(event, artifact)` pair is the stable event id, so re-running for the same event never duplicates a line. Git-stages the mission file. Standard events: `ticket archived` (drive), `story reported` (report), `concern deferred (stuck)` (ship), `concern resolved (unstuck)` (report), `mission achieved` / `mission abandoned` / `mission carried into <successor-slug>` (close.sh), `ticket added` / `mission replanned` / `acceptance dropped` (replan).

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
bash mission/scripts/list-related-prs.sh <slug>
```

List OPEN pull requests referencing a mission slug (slug present in a PR's title or body — a mission-linked story names the mission; `work-*` branch names do not), so the **Replan** flow can see a sibling lane's in-flight, not-yet-merged work before emitting duplicate delta tickets. Emits `{slug, available, prs:[{number, title, url, headRefName}]}`. **Read-only, best-effort**: `available: false` (empty `prs`) when `gh` is missing/unauthenticated or the repo has no usable remote — *unknown*, not *no siblings*, so a replan is never blocked by tooling. Complements `create-mission-worktree.sh`'s fetch-first base resolution (that guards a new worktree's *merged* base; this guards a replan against a sibling's *unmerged* work).

```bash
bash mission/scripts/close.sh <mission-slug-or-file> <achieved|abandoned|carried> [date] \
  [--successor-title "<title>" | --successor <slug>]
```

End a mission — the only sanctioned way. Flips `status`, appends the closing changelog line through `append-changelog.sh` so the transition itself becomes history (`design` / `history-structures`), moves the mission dir into `archive/`, refreshes the OKF indexes, and git-stages. Idempotent: re-closing with the same status is a no-op (`{closed: false, reason: "already_closed"}`); re-closing with another status flips it in place and appends its own line. Emits `{closed, slug, status, path}` JSON (plus `successor` / `successor_path` on a carry).

**Completion lifecycle — "merge and clean up" is a chain, not an auto-merge.** When a mission's tickets are all done, it moves through four stages, each with a distinct owner: **complete** (derived by `status.sh` — `## Acceptance` fully checked, gate exercised when declared) → **PR** (opened by `/monitor`'s §5 PR phase from the mission worktree's branch — auto-*creation*, so the morning starts at review) → **`/ship`** (the human, deploy-evidence-gated merge — full auto-merge was rejected: it would bypass PR review and the deploy-before-merge doctrine) → **`/mission close`** (archives the mission). Auto-merge is deliberately **not** part of this chain; the PR is where a night's work becomes reviewable, and the merge stays a human decision on evidence.

#### Worktree lifecycle — claim-born and ship-torn

A mission's `.worktrees/<slug>/` worktree belongs to the **claim**, not to the mission record (`docs/loop-engineering-workflow.md` I6). It is created when a runner claims the unit (`drive`'s *Claims* section — `claim.sh` cuts the worktree and its `work-*` branch together) and removed when that unit **ships**, or when its claim is explicitly released (`release-claim.sh`). An unfinished mission is simply re-claimed by a later tick, which recreates the worktree from the pushed branch.

**So `close.sh` and `/mission close` keep only the archive move.** Closing a mission is a statement about the *record* — this goal is reached, abandoned, or carried — and it says nothing about whether a worktree is still in use. A worktree still standing at close time is an in-flight or stale **claim**, which the claim reader already surfaces and a human already decides about; having `close` tear it down instead made a bookkeeping action quietly destructive, and hid the one signal (`list-claims.sh`) that says whether anyone is still working there. `cleanup-mission-worktree.sh` is unchanged and still the sanctioned cleaner — it is now called from the claim-release and ship paths rather than from close.

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

**The successor gets no worktree from the predecessor.** Closing manages no worktrees at all (see *Worktree lifecycle* above — they are claim-born and ship-torn), and a carry deliberately does not hand one over: `.worktrees/<slug>` is keyed 1:1 to the unit slug by `slug.sh`, and a successor living in the predecessor's directory **silences the mission lens inside that very worktree** — the lens reads a worktree whose basename names no active mission as a `/drive` worktree and says nothing at all. The successor gets its own worktree when it is claimed; in-flight state and the port allocation do not carry.

#### When the direction changes — reorganize and carry (the encouraged answer)

A mission is **sticky to finish**: `achieved` demands every `## Acceptance` item checked, which is the right bar for a mission whose direction held. But a mission's direction often **changes mid-flight**, and then grinding to check the original criteria is effort spent against a plan that no longer describes the work. The **encouraged, positive** response in that case is **reorganize and carry** — not grind to `achieved`, not `abandoned`. Reach for it on any of three signals:

- **A different class of issue surfaced** — the work uncovered a problem the mission was not framed around, and the remaining criteria no longer point at what now matters.
- **The remaining criteria became contradictory or moot** — progress made the original plan internally inconsistent, or answered a criterion by making it irrelevant.
- **The remainder belongs to another active mission** — the leftover work is really that mission's, so it should **merge** there rather than persist as a parallel goal.

Why carry rather than the alternatives: forcing `achieved` **fabricates completion** the computed-progress model exists to prevent (progress is counted from unchecked items, never hand-set), and `abandoned` **discards real progress**. `carried` is the honest verdict — *"this landed as framed; the rest, reorganized, is still worth doing"* — and it **preserves** what was done while re-pointing the remainder.

**Reorganizing is a replan, then a carry — and it deliberately does not grind quality gates.** The mechanism is the existing **Replan** flow plus `close.sh`, used together and recorded, never hand-editing:

1. **Reorganize** via `/mission <instruction>` (the Replan flow): rewrite `## Goal`/`## Scope`/`## Experience` to the changed direction, and **drop the now-moot unchecked acceptance criteria** — do **not** force them checked. A dropped item is recorded as its own `acceptance dropped — <the item's (#filename) artifact>` changelog line (Replan already owns this), so the plan's shrinkage is history, not a silent rewrite. This is what *"skip filling quality gates"* means here: **stop grinding to check criteria the new direction made obsolete** — it is **not** a relaxation of the write-time floor (`hooks/validate-mission.sh` still requires a non-empty `## Acceptance` and `## Experience` once the mission is `approved`).
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

1. **ownership** — the current `git config user.email` is among the mission's owners (`mission-owners.sh` — the mission's own `assignees` first, then the legacy `assignee`), or the mission is unowned (surfaced as claimable). Only a mission owned solely by others stays silent.
2. **location** — worktree focus: inside a mission's own `.worktrees/<slug>`, only that mission; inside a worktree that owns **no** mission (a `/drive` worktree), nothing at all; in the main tree, only missions that own no worktree.
3. **signal** — the mission has at least one acceptance criterion. A mission whose `## Acceptance` is empty would render as `0/0` with no next step — a technical condition with nothing to act on — so it stays silent.

It keeps the agent oriented to the roadmap without hijacking the turn — it never blocks a stop (informs, does not force). Silent no-op when nothing passes all three. The gap that made this matter is now closed upstream: the **Creation Interrogation** is mandatory and a mission is not finished being created until `## Acceptance` names at least one criterion, so a mission is no longer *born* matching the silence gate. `create.sh` still scaffolds the section empty — it is a POSIX scaffold and cannot interrogate — so a hand-authored `mission.md` that bypasses `/mission` can still arrive at `0/0` and stay invisible here (the bare `/mission` view's full tier and `/catch` keep the lower assignee-only bar and still show it). That residue is the same shape as the unassigned-mission gap: a default on the sanctioned path does not constrain the other paths. Like `/catch` it mutates nothing, so it is in no seam table. (Because a Stop hook cannot inject model-visible context without `decision: block`, the model-facing half deliberately rides `UserPromptSubmit`; the `Stop` half is the user-facing nudge only.)
