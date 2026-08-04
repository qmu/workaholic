---
name: mission
description: Use when the user runs `/mission`, asks to "start a mission", "plan a batch of work", "show mission progress", or "what missions are in flight". A mission is an optional, epic-equivalent grouping — a bounded, information-rich batch of tickets an agent fleet drives together, never a required parent of any ticket; this skill creates one, lists missions with computed progress, and defines the mission schema every workflow reads.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Mission

A **mission** is a first-class knowledge artifact: an **optional, epic-equivalent grouping of tickets** — a fairly immediate developer request, interrogated to question-free drive-readiness, that bundles the ordered ticket set an agent fleet drives through together (typically overnight). It carries the information-rich statement of *what this batch of tickets accomplishes* and *how far it has come*, with a machine-readable web of relations to the tickets, stories, and concerns that advance it. The mission is bounded, not long-lived — and **never a required parent**: the ticket stays the first-class standalone unit, and `/ticket` → `/drive` with no mission is a fully sanctioned path. Long-lived *direction* accretes in the feedback stream (`workaholic:feedback`; `docs/loop-engineering-workflow.md`, decisions B3/B5).

Distinguish the terms and never conflate them (`workaholic:planning` / `terminology`):

- **feedback** — the inbound stream of project context (`workaholic:feedback`); long-lived **direction** lives here, as accumulated insights and instructions. It answers *why is this work being launched*.
- **mission** — an **optional, epic-equivalent grouping**: a bounded batch of tickets with acceptance criteria and an append-only changelog. It answers *what does this batch of tickets accomplish together*. A mission finishes; the stream persists.
- **epic / milestone** — generic project-management words this repo deliberately does **not** use as artifact names. "Mission" is the word for this level.

The vocabulary lost a word on 2026-07-28: **trip** — a design/build *session* run by a three-agent team — is retired along with its command (`docs/loop-engineering-workflow.md` decision I1). Design discussion is now feedback, decomposition is `/mission` and `/propose`, and execution is `/drive`. The `.workaholic/trips/` tree stays on disk as read-only history with no writer.

See the **Granularity** section below for the full commit → ticket → mission discipline and the record of how "mission" was redefined twice.

## Granularity

The **single home** of the granularity discipline (`workaholic:planning` / `modeling-centric-design`). Four description layers each describe code change and its planning at *their own* level, and **no artifact restates a lower level's detail**:

| Layer | Answers | Size | Normalized by |
| --- | --- | --- | --- |
| **commit** | *what is this one normalized change* | ~a few hundred lines, one reviewable unit | the release-scan per-commit changed-lines gate (ticket `20260721020759`) |
| **ticket** | *what is this one change* (a single drive-able unit) | one `/drive` pass, with its own `## Quality Gate` | its `## Policies` / `## Quality Gate` |
| **mission** | *what does this batch of tickets accomplish together* (optional — a ticket needs no mission) | hours of agent time; a fairly immediate request interrogated to question-free readiness | the Creation Interrogation |

"Why is this work being launched" is answered one level up by the **feedback stream** (`workaholic:feedback`) — accumulated direction, not an artifact layer of its own.

**The balance test cuts both ways.** A mission that re-narrates its tickets' specifics is **over-written** — trust the ticket to hold the detail. A ticket that says essentially what its mission says means the **mission is under-sized** — a mission must be bigger than any one ticket; surface that and merge, do not write the duplicate. Neither is "add more words"; both are "put each fact at exactly one level".

### Redefinition record

Recorded here so it is not re-litigated (`workaholic:planning` / `terminology`):

- **First meaning** (before 2026-07-21): "mission" was the long-lived container — "a durable goal spanning many tickets over a long horizon; it outlives any single branch or session".
- **Second meaning** (2026-07-21): "the overnight-executable execution plan of a strategy" — bounded, with longevity moved up to a new `strategy` artifact. Reason: the mission was playing two roles at once — the executable unit *and* the long-lived goal container. Provenance: mission `reorganize-missions-under-strategies`.
- **Current meaning** (2026-07-28): an **optional, epic-equivalent grouping of tickets** — bounded, never a required parent. The strategy layer is **retired**: direction accretes in the feedback stream instead of a second direction artifact (two homes would drift), and mission ownership returned to the mission itself. The 2026-07-21 phrase is superseded on both ends — the strategy end and the mandatory-sounding framing (`docs/loop-engineering-workflow.md`, decisions B3/B5; provenance: mission `loop-engineering-foundation`). Retired strategies survive verbatim as feedback records (`migrate-strategies.sh`).

Every other place that touches granularity **links here** rather than restating it (`workaholic:create-ticket`, `workaholic:commit`).

### The ticket floor — two or more, or it is not a mission

**A mission is created with two or more tickets, or it is not a mission** (`.workaholic/feedbacks/20260804173526-a-mission-is-created-with-two-or-more-tickets-or-it-is-not-a-mission.md`). This is the granularity table's bottom edge made checkable: without it a ticketless mission is a feedback record on the roadmap, and a one-ticket mission is a ticket with a progress bar. The three artifact kinds are only distinguishable if the middle one has a lower bound.

**What counts, and when.** Tickets carrying this mission in their `mission:` relation, **present in the same publication commit as the `mission.md`**. The count is taken at the **publish seam** — the moment the mission and its tickets become one artifact — and nowhere else.

**Not at the write of `mission.md`, and the reason is ordering, not convenience.** A `PostToolUse` hook fires when the file is written, which is *before* the interrogation has emitted anything, so a write-time floor would refuse the normal authoring order. This is the same argument that put acceptance-link stamping at the emitting seam rather than at authoring time (`reference/schema.md`, *The link contract*) — and that contract was itself written after 37 acceptance items across six missions were found unlinked, so the cost of putting a check where the data does not yet exist is already measured in this repository. **Do not put the floor in `validate-mission.sh`.**

**The floor is exactly two, and a one-ticket mission is refused, not warned.** One ticket has nothing to group: the wrapper adds a board, a progress fraction and a close decision to a unit that already had its own tracking. A warning would preserve exactly the ambiguity the rule exists to remove. Note the existing instance so the rule is not misread as a judgment on it — `drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` (archived, 1 ticket) shipped fine. The claim is not that it did harm; it is that "mission" and "ticket" must not both name it.

**A refusal names the alternative.** The author is not wrong to have something to record, only to record it as the wrong kind of thing: a bare direction is a **feedback record**, a single unit of work is a **plain ticket**. A refusal that cites only the rule leaves the author unable to act (`workaholic:implementation` / `observability`).

**What a carried close does: `--successor-title` is refused; a carry must name an existing mission** (`--successor <slug>`). `close.sh --successor-title` mints a successor from the predecessor's unmet acceptance items and emits **no tickets at all**, so under the floor it produces a violation by construction, every time — and did, on 2026-08-04, an instance that reached `main`. The rejected alternatives, with their costs, so the trade is visible:

| Option | Why not |
| ------ | ------- |
| **(a)** The close emits the successor's ticket set in the same pass | Consistent with the rule, but `close.sh` is a bookkeeping script and this hands it a *planning* responsibility. The planning input — what the remaining tickets actually are — is not derivable from the unmet acceptance items; a person or an interrogation must supply it. Rejected for putting planning in the one seam that has none. |
| **(c)** A carried successor is exempt from the floor | Rejected on its face: the carry is the **only** seam that has ever produced a violation, so an exemption covering it is not a rule. |

The cost of the chosen option is real and accepted: a genuine "this direction continues but nothing suitable exists yet" carry has no one-step path, and the developer must create the successor first. That is not a workaround — **creating it *is* the interrogation that produces its tickets**, which is precisely the behavior the floor is asking for.

**Where the check lives, stated once:** the publish seam shared by every creation path — the Creation Interrogation, `/propose`'s scaffold, and any future minting path. Enforcement is written against this section, not re-derived per seam.

## Lifecycle — one status axis

**A mission has exactly one lifecycle field.** `status` carries the whole state, and every reader keys on it:

| state | area | meaning |
| --- | --- | --- |
| `active` | `active/` | in flight. The project accepted this mission by merging its pull request, so it is **claimable** as soon as it has a plan and a ticket queue: `/drive`'s survey offers it as a PR-unit. |
| `achieved` | `archive/` | the goal was reached. |
| `abandoned` | `archive/` | ended without reaching it, and the remainder is not worth doing. |
| `carried` | `archive/` | done **as framed**; the remainder became a successor mission. |

Transitions, and **who** performs each — every flip is a script, never a hand-edit:

```
(create.sh | scaffold-draft.sh) ──▶ active ──close.sh──▶ achieved | abandoned | carried
```

- **`/propose` and `/mission "<title>"` mint active missions** — behind a pull request, which is where their necessity and content are judged.
- **`close.sh` is the only path to an end state**, and the only status flip that exists.

### Redefinition record — `status: draft` retired; the merge is the approval

Recorded here so it is not re-litigated (`workaholic:planning` / `terminology`): **`draft` and `approved` are retired into the single in-flight state `active`** (2026-07-31 — `docs/loop-engineering-workflow.md` decision K1), and **merging a mission's pull request is its approval**.

`draft` made sense in the world it was designed for: `/propose` pushed a mission straight to `main` (J1), so *something* had to stop `/drive` claiming work nobody had looked at. **J4 replaced that premise** — every artifact now arrives behind a PR — and the flag stayed, so a mission was reviewed once in its PR and then gated a second time by `/mission approve`, whose only remaining job was to undo the first gate. The observable cost was six active missions on `main`, every one unclaimable, and `/drive` reporting `pending` tick after tick.

**Drivability is no longer a status word.** A mission is claimable when it is in the active area, has a plan (`## Acceptance` non-empty) and has at least one queued ticket naming it — the `no_plan` and `no_tickets` floors, both of which ask "is there anything to drive", never "did someone approve this".

Consequences, stated so no reader has to infer them:

- **`approve.sh` and `/mission approve` are gone** (K2). Their three payloads were redistributed, not dropped: `merge_policy` moved to creation, ownership seeding was dropped, and the write-time floor was kept and re-aimed (below).
- **Legacy files migrate on the next mission-script touch** (`lib/resolve.sh`): `status: draft` → `active` and `status: approved` → `active`, with the long-retired `drive_authorized:` key line dropped from the rewritten file. Both spellings are tolerated by every reader for the transition window, so an untouched checkout keeps working.
- **The floor moved from a status to an area.** `hooks/validate-mission.sh` fired on `status: approved`; it now fires on **any** mission written under `missions/active/`, because "the thing that can be claimed" is no longer marked by a word. Practically: an agent editing an active mission must land the `## Experience` and `## Acceptance` content in that write. The scaffold writers are unaffected — they write with a shell heredoc, which a `PostToolUse` hook never sees.
- **Ownership is no longer a floor.** An unowned mission is claimable by anyone, which is already how `list.sh`, `summary.sh` and the lens treat it (`relation: unassigned`), and `/propose` writes unowned proposals by design.
- **`active` is now both an area name and the status word**, and that is deliberate. I2's note said *"do not reintroduce `active` as a status word"* — because `active` was then ambiguous between `draft` and `approved`. With one in-flight state the ambiguity is gone and the two coincide by construction. **Rejected**: keeping `draft` as an *optional* marker — an optional gate that only some artifacts carry is a gate nobody can rely on, since a reader seeing no `draft` cannot distinguish "accepted" from "the writer never set it".

### Merge policy — the orthogonal axis

`merge_policy: auto | review` is a **separate** axis from the lifecycle (decision G5): **may this mission's completed units merge automatically, or must a human review the PR?** It is recorded at **creation** (K2 — `create.sh`'s optional third argument, and empty from `scaffold-draft.sh`), adopting the ticket rule exactly: **absent means `review`**, the conservative default, so a mission that arrives with no policy routes to a PR. It used to be recorded at approval, which no longer exists; one creation-time rule now covers missions and tickets alike — see `workaholic:create-ticket`.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Where a step uses `AskUserQuestion` (the `/mission` command's create/list choice), use the agent's native selection prompt; only the mechanism varies. All logic lives in the bundled POSIX scripts, which run identically everywhere.

## Allowed Location

A mission lives in one of two areas — mirroring the tickets `todo/`-vs-`archive/` split — selected by its `status`:

```
.workaholic/missions/active/<slug>/mission.md    # status: active (in flight)
.workaholic/missions/archive/<slug>/mission.md   # status: achieved | abandoned | carried (ended)
.workaholic/missions/index.md                    # regenerated by okf/refresh-index.sh, one entry per mission per area
```

A mission is written either by `create.sh` (whose Creation Interrogation fills it before the publish commit) or by the `/propose` batch (`workaholic:propose` — `scaffold-draft.sh`, which additionally leaves it unowned, `assignees: []`, and carries a `feedback:` list naming the records it grew from, read via the propose skill's single reader `read-feedback-relation.sh`). Either way it lands in `active/` and reaches `main` — and therefore every runner's survey — only when its pull request merges. A mission that is in flight but carries no acceptance items reports `ready_reason: "no_plan"` in `list.sh` and is excluded from `/drive`'s offer for the same reason.

`<slug>` is derived from the title: lowercased, every run of non-`[a-z0-9]` characters collapsed to a single hyphen, leading/trailing hyphens trimmed (e.g. `"Real-time Notifications"` → `real-time-notifications`). One directory per mission; the directory name **is** the slug and is the stable key other artifacts reference (`mission: <slug>`). The area is **never** part of that key — seams pass bare slugs and the scripts resolve the location, so a mission's move to `archive/` breaks no relation.

Resolution takes an explicit **root** (a `.workaholic` directory), never the process cwd. A seam that holds an artifact (a ticket, a `mission.md`) derives the root from *that artifact's own path* — the mission tree is fixed by where the ticket lives (its worktree), so `mission: <slug>` on a worktree ticket resolves to *that* worktree's mission from any cwd. A caller with only a slug and no artifact (`create.sh`, `close.sh`) roots on the repository it runs in (via `git rev-parse`). `lib/resolve.sh` is the single source of this: `missions_root_from_artifact` / `missions_root_default` / `missions_root_for_arg` choose the root, and `mission_resolve <root> <arg>` returns an **absolute** `mission.md` path — so two same-slug missions in two worktrees never yield the same string, and which file was read is visible in the output rather than hidden behind a cwd-relative path.

The scripts own all placement: `create.sh` writes into `active/`, `close.sh` moves to `archive/`, and every script runs the **living migrations** first — a legacy flat `missions/<slug>/` dir (the pre-split layout) is relocated into the area its `status` selects (`git mv`, preserving history), and a retired `status: draft` or `status: approved` mission is folded onto the one in-flight state `active` (with the long-retired `drive_authorized:` key line dropped). Both are idempotent and best-effort (a failure never blocks the calling seam; the resolver still finds an unmovable flat mission, and every reader tolerates the pre-migration shape). Never `mv` a mission dir or hand-edit `status:` yourself.

## Schema

`mission.md` carries this frontmatter (the `type: Mission` line is the OKF conformance floor):

```yaml
---
type: Mission
title: <human title>
slug: <slug>
status: active          # active | achieved | abandoned | carried — the ONE lifecycle axis, and it selects the area (active in active/, the rest in archive/). Flipped only by close.sh (→ an end state); never by hand. The retired `draft`/`approved` spellings fold to `active` on the next script touch
merge_policy:           # auto | review — the orthogonal merge axis (G5), recorded at CREATION (K2). EMPTY MEANS `review`, exactly as on a ticket; never defaulted to auto
carried_from:           # only on a successor: the slug of the mission whose remainder it inherited
created_at: <ISO-8601>
author: <email>
assignees: [<email>]    # the mission's OWNERS (plural — a mission can be co-owned). Creator-seeded by create.sh; empty = team-owned/claimable, and NEVER a floor (K2). Read ONLY via mission-owners.sh
assignee: <email>       # LEGACY FALLBACK only (missions predating `assignees`). Empty on new missions; never read directly
predicted_hours:        # decimal agent-hours, stamped ONCE at creation from archived-mission trend (predict-duration.sh); empty when basis 0
actual_hours:           # decimal agent-hours accumulated by /drive across runs (record-run-hours.sh is its only writer); empty until a run records
tickets: []             # machine-readable member lists — reserved; populated by later work
stories: []
gate_type:              # OPTIONAL and normally EMPTY — documentation | live-app | check
gate_target:            # what to exercise: a route on the mission worktree's port (e.g. /docs), or the verification command for `check` (e.g. npm test)
gate_assert:            # one line: what must hold for the mission's outcome to pass
---
```

The `tickets` / `stories` lists are reserved for the machine-readable relations that downstream artifacts emit; a freshly created mission leaves them empty. A `concerns: []` key is no longer scaffolded — deferred concerns live in the feedback stream (`docs/loop-engineering-workflow.md` H2), so a reserved slot on the mission would have been a second, always-empty home for them. Missions predating 2026-07-28 still carry the key; it is tolerated and read by nothing.

### Body sections, in order

- `## Goal` — the information-rich "why": business grounding and the outcome the mission pursues.
- `## Experience` — **the mission's substance**: the user experience, the demanded behavior, and/or the overall structure it pursues. Where `## Goal` says *why* the work is worth doing, this says *what the thing does*. Keep it observable (`workaholic:implementation` / `objective-documentation`) — "the list reorders without a reload" is checkable; "feels fast" is not. This is the persistent content a kickoff-time `gate_*` could never be, and it is what a later session reads to know what is actually demanded.
- `## Acceptance` — a checklist, and **the mission's plan**: each item names the ticket expected to satisfy it — through a `(#<filename>)` link that the **emission seam stamps** rather than the author typing it (decided 2026-08-03; see the reference's *link contract*), so the list doubles as the route to completion. **Three items or fewer** — see *Size norms* below. **Progress toward achievement is `checked ÷ total`, computed from this list, never a hand-set number** (`workaholic:implementation` / `objective-documentation`). An unchecked item is a **heading, not a specification** — re-check it against the source before cutting its ticket (see the checklist convention below).
- `## Changelog` — an append-only, dated, human-readable timeline (`workaholic:design` / `history-structures`).

**`## Scope` was removed from the template on 2026-08-01**, deleted rather than made optional: no validator, script, or hook ever read it, so it was pure authoring cost, and `## Goal` (why) plus `## Experience` (what) already carry what it was reaching for. Missions written before that date still have the section — it is left verbatim as history and read by nothing. **A carried successor does not inherit it**: the successor is scaffolded from the template, so there is no `## Scope` heading for a carry to land in, and copying one would re-introduce a retired section into a *new* mission — the opposite of the removal's point. The predecessor keeps its own section as history.

### Size norms

Missions became hard to *finish*, and the diagnosis matters: the gates were not too strict — **nothing bounded how much a mission may say**. An unbounded `## Acceptance` grows into an exhaustive audit list, and a mission whose acceptance list is an audit list can never be honestly closed. The measurement at adoption: six active missions, every one at 0 of 3–9 criteria.

| Norm | Value | Measured by |
| ---- | ----- | ----------- |
| `## Acceptance` items | **3 or fewer** | `scripts/size.sh` |
| Whole `mission.md` | **60 lines / 2 KB** | `scripts/size.sh` |

**The three-item rule is the one doing the real work.** Write only the minimum conditions under which the work can be called done. Exhaustive coverage, per-file checklists, and future audit items do not belong in a mission — they belong in tickets and the feedback stream. The line and byte ceiling is a **backstop**: a mission can meet 2 KB by saying less and meaning less, so it shapes the artifact rather than the thinking.

**Norm for a human, gate for the batch** — the asymmetry is deliberate. A developer authoring a mission is present and exercising judgment, so `size.sh` *reports* and the interrogation shows the measurement; a hard refusal would fire on legitimately larger work, and a gate that refuses good work is worse than a norm that guides it. `/propose` writes **unattended**, with no judgment to exercise and nobody to show a measurement to, so the same ceiling is enforced on its proposals — its scaffold reports the measurement on every mission it writes (`workaholic:propose`).

**This is a ceiling, and lowering a ceiling is not loosening a floor.** The write-time floor is untouched in substance: `hooks/validate-mission.sh` still requires a non-empty `## Experience` and **at least one** `## Acceptance` item — now on **any** active mission rather than on an approved one, since `draft` was retired (K1/K2). Its ownership half was dropped deliberately, on its own reasoning; a later reader must not mistake the size ceiling for that relaxation.

A mission carries **no `## Reflection` section**. The per-run reflection channel retired with the parallel-mission executor (`docs/loop-engineering-workflow.md` decision I3): what a run learned — what stopped autonomy, which judgment call leaked, what the next plan should pre-answer — is written as a `kind: concern` or `kind: insight` **feedback record** instead of a section only mission-planning ever read. That is the seam `/drive` already uses for everything else it defers, and it reaches `/propose` and the next interrogation alike. Missions closed before 2026-07-28 still carry the section; it is history and is left verbatim (any `## ` heading ends `## Acceptance`, so its checklist-shaped lines never counted toward progress and still do not).


### The field detail lives in the reference file

[`reference/schema.md`](reference/schema.md) carries the full detail for the fields above, and it is where the rulings live:

- **Quality gate** (`gate_*`) — optional and normally empty, with the record of why it was demoted.
- **Drivability** — what being in the active area asserts, and the alternatives rejected with `draft`.
- **Ownership** — the `mission-owners.sh` oracle, its legacy fallback, and the redefinition record.
- **Duration** — how `predicted_hours` is derived once and `actual_hours` accumulated, and why the actual covers mission units only.
- **Acceptance-checklist convention** — the `(#<filename>)` marker, **the link contract** (item-scoped, stamped at emission, unlinked-is-reported) with the alternatives it rejected, and the measured reason an unchecked item is a heading rather than a specification.
- **Changelog line format** — the dated append-only line and its idempotent event id.

Read it before writing or interpreting any of these fields; the block above names them, it does not define them.

## Creation Interrogation (mandatory — always run)

When `/mission "<title>"` creates a mission, **interrogate the developer until the mission is drive-ready**, then emit the whole ticket set in one pass. This step **always runs — it is not skippable**, and it is not gated on the request "seeming obvious".

`create.sh` is a POSIX scaffold: it writes the sections as HTML comments and cannot ask anything (`allowed-tools: Bash`), and it must not. The interrogation is the command's job, and this section is the protocol it follows.

**Why it is mandatory.** A mission's whole value is that judgement is answered *before* the work starts. `workaholic:development` / `overnight-ai`: *"identify in advance the points where AI would want to ask for judgment and write the answers to those questions into the ticket. We eliminate the causes of stopping in the night before the run starts."* A mission scaffolded with empty sections is an empty shell that stops the first time it meets a decision — and, because the mission lens's signal gate silences a `0/0` mission, it is an empty shell **nobody can see**.

**Grill; do not tick a box.** The bar is a *structured model* — the demanded behavior, the ticket plan, the order — not a question count and not a Q&A transcript pasted into a file (`workaholic:planning` / `modeling-centric-design`). Ask as many rounds as it takes — but apply the **Recommended-label test** (`rules/interaction.md`) to every round: if you could honestly recommend an answer, **do not ask it** — decide it, record the decision where the plan is written (the mission `## Changelog`, or the relevant ticket's `## Quality Gate`), and let the developer veto it. "As many rounds as it takes" therefore means as many *unrecommendable* rounds as it takes: the grilling is undiminished on the genuine forks, and silent on the calls you could already make. Where uncertainty is high, prove it small before emitting the set (`workaholic:planning` / `verify-before-building`): with no human gate downstream of approval, an unverified premise is not caught at ticket 3 — it is concretized across the whole mission.

### Read the recent feedback stream (before the rounds)

Before interrogating, read back what recent runs learned: `bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/list.sh` returns the feedback stream newest-first. Read the `kind: concern` and `kind: insight` records an unattended `/drive` deferred — every judgment call it met and recorded instead of asking lands there — and fold the recurring ones into round 4's per-ticket pre-answers: a decision that leaked into a past night is exactly the question the next mission should pre-answer rather than meet again in the dark (`workaholic:development` / `overnight-ai`). This closes the loop: planning quality is measured by how few judgment calls leak into the night, and the stream is the record of which ones did.

### Elicit the requirements first — the *what*, before any plan (the highest-leverage gate)

**Plan quality gates everything. No amount of downstream verification rescues a plan built on a wrong understanding of the goal** — an unattended run faithfully amplifies a shallow plan into hours of unusable output, and "the artifact exists / the tests pass" cannot see whether the *thing itself* was the wrong thing. So the first job of the interrogation is not the ticket set; it is to **draw out of the developer the requirements the agent cannot derive** from the code, the ticket title, or the repo: what a user must actually be able to *do*, what a **correct/good output looks like (ask for a concrete example)**, and the **real end-to-end workflow**. Ask specific, concrete questions about the actual unknowns the plan depends on — never a generic "any feedback?".

This is a distinct discipline from the **decide-don't-ask** rule the execution phase follows (`workaholic:drive`'s *Where the per-ticket approval prompt went*): that rule governs **execution-time decidable choices** (which fixable failure to retry, finalize-now vs. push) — the *how* — and rightly says decide, do not offload. **Requirements elicitation is the opposite case: the *what*, which the developer holds and the agent cannot derive.** Decide the *how*; never assume the *what*. The two do not conflict once separated, and the decide-don't-ask rule must not be over-read into "don't elicit requirements."

Three hard gates on this step:

- **A developer's invitation to ask is a hard gate.** If the developer signals "ask me what you need to firm this up", failing to ask is a **planning defect**, not efficiency — the one time the elicitation is most owed is exactly when it was invited.
- **A user-facing feature may not be planned from a title.** The plan must encode what *usable* means for a real person, because the agent's own checks cannot see usability. For user-facing work, require an **example of a good output** and a **walked end-to-end workflow** before the plan is committed.
- **If the goal is not yet understood well enough to write verifiable, user-experience-level `## Acceptance` criteria, the plan is not ready** — keep eliciting; do not start building. Long autonomous execution on an un-elicited plan is the anti-pattern this gate exists to prevent (`workaholic:planning`; `workaholic:development` / `overnight-ai`).

Every genuine requirements question is a legitimate `AskUserQuestion` — it is precisely the "developer holds information you cannot derive" fork the Recommended-label test never silences (`rules/interaction.md`).

### The rounds

1. **Direction** — the business "why", the outcome pursued, and what is explicitly out of scope. → `## Goal` (the out-of-scope notes belong in the same section now that `## Scope` is gone; state them in a sentence, not a second list)
2. **The demanded experience** — the user experience, the behavior required, and/or the overall structure, **elicited per the gate above** (for user-facing work: the concrete example of a good output and the walked workflow, not a title-level guess). This is the mission's substance: what the thing *does*. Keep it observable, at the user-experience level. → `## Experience`
3. **The ticket set** — how many tickets, what each covers, and the `depends_on` order. **This is the round nobody asked before, and it is the one that matters most**: "more of a plan or tickets" is what makes a mission complete.
4. **Per-ticket pre-answers** — everything `create-ticket` §4b would ask later, asked now, per ticket in the set: acceptance criteria, verification method, the gate that must pass.
5. **Acceptance** — one `## Acceptance` item per criterion, each naming the ticket that satisfies it. **For user-facing work, at least one criterion must be phrased at the user-experience level** (what a person can do / what the output looks like), not only "artifact exists / tests pass".

**Do not interrogate the mission gate.** `gate_*` is optional and normally empty (see *Quality gate*). Ask only if the developer volunteers a stable, objective outcome check; never treat its absence as an unfinished mission.

### Ordering

The requirement is *all questions before any ticket is created* — and `## Acceptance` items link tickets by `(#<filename>)`, which cannot exist until the tickets do. Both hold, because the **writing** order differs from the **asking** order:

> ask everything → decide the ticket set → write the tickets → write `## Acceptance` → stamp each item's link.

Do not read the requirement as "Acceptance first". The last step is a script, not typing: the criteria are written as prose and `link-acceptance.sh` stamps each `(#<filename>)` once the ticket that satisfies it exists. **A mission whose items are written before its tickets — every `/propose` proposal — is therefore normal, not broken**; it is the *emission without the linking step* that strands the board.

### Emitting the set

Write the tickets **in one pass**, not N serial `create-ticket` runs. Each carries its mandatory `## Policies` and `## Quality Gate` (`validate-ticket.sh` rejects it otherwise), is stamped `mission: <slug>`, and is ordered by `depends_on` — foundation first, dependencies only where genuinely ordered, unique timestamps (`+1s` per ticket). Reuse `create-ticket`'s split mechanics rather than re-deriving them.

**Stamp the acceptance links in the same pass** — the step that closes the seam. Once the tickets are written, run `link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per acceptance item, naming the pair explicitly (the interrogation just decided it; nothing infers it). An item that **no** emitted ticket satisfies stays unlinked and is **reported to the developer**, never linked to the nearest ticket — an unlinked item is an honest "no artifact claims this yet", and a guessed link is a checkbox that will one day flip on work that did not satisfy it. Skipping this step is what strands a board: the criteria are written, the tickets exist, and nothing joins them (`reference/schema.md`, *The link contract*).

**The split cap does not apply to a mission — a deliberate, scoped exception.** `create-ticket` §4 caps a split at "2–4 discrete tickets", which is right for one request that turns out to be several. A mission is the opposite case: an execution plan that bundles *many* tickets by definition, and "a complete set to drive through one by one" is the requirement. Capping it at 4 would force either an incomplete plan or a fake ticket boundary. A mission decomposition answers to its own rule: **one ticket per genuinely separable unit of work, however many that is**. The cap still applies to `/ticket` itself; this exception is mission-scoped and stated here so it is not a silent violation.

**Stamp the duration prediction at the end of emission — as a report line, never a question.** Once the ticket set and `## Acceptance` are written, run `predict-duration.sh <acceptance-item-count>`: when `basis > 0`, stamp `predicted_hours` and state the number and its basis to the developer honestly ("predicted 6.0h from 2 archived missions"); when `basis: 0` (today's state, no archive), leave `predicted_hours` empty and record a `duration predicted (archive basis 0)` changelog note rather than dressing a guess as data (`workaholic:planning` / `verify-before-building`). Never ask the developer for an estimate — the predictor answers this, and `actual_hours` is filled later by `/drive` (`record-run-hours.sh`).

## Replan (re-entering the interrogation)

The sanctioned path to **reopen an existing active mission's plan** — reached without a subcommand: `/mission <instruction referencing the mission>` (the command owns the dispatch judgment and its written criteria). It exists because three legitimate states previously had no route back into the interrogation: a thin hand-authored `0/0` mission, a mid-flight mission whose scope grew, and a `carried` successor minted by `close.sh` with no worktree and no tickets — while the create flow dead-ends on an existing slug. Only **in-flight** missions (`status: active` — the active area) are replan targets; the archive is immutable history.

**Surface sibling PRs before re-interrogating.** A replan grows the plan, so it must first see whether another lane is already implementing the same acceptance. Run `list-related-prs.sh <slug>` (below) and, when it returns open PRs referencing the mission, factor them into the delta rather than emitting tickets that duplicate a sibling's unmerged work. The check is best-effort — `available: false` means it could not run (no `gh`/auth/remote), which is *unknown*, not *no siblings*. This is the replan-side complement to the publish tree's fetch-first base: the fetch keeps the replan off a stale `main`; this keeps it off a sibling's *unmerged* work.

**Scoped re-interrogation.** Re-run the Creation Interrogation rounds the instruction touches — nothing more, nothing less:

| the instruction changes | rounds re-run |
| --- | --- |
| direction (goal, scope) | 1–2 |
| the plan (more/changed work) | 3–5, for the delta tickets |
| a thin mission (`0/0`, empty sections) | all five |

The bar equals creation's: a structured **delta model** — what changes, which tickets, in what order — not a Q&A transcript (`workaholic:planning` / `modeling-centric-design`), grilled until the delta is drive-ready. The **Recommended-label test** applies exactly as at creation (`rules/interaction.md`): a delta decision you could honestly recommend is decided-and-recorded (a `## Changelog` line or the delta ticket's `## Quality Gate`), not asked; only the unrecommendable forks reach an `AskUserQuestion`. `gate_*` is never interrogated, exactly as at creation.

**What the delta may touch** — everything the Creation Interrogation produces, applied as a delta: rewrite `## Goal` / `## Experience` (and a legacy `## Scope` if the mission still carries one); append `## Acceptance` items (observable); emit delta tickets in one pass (the same emission rules, including the mission-scoped split-cap exception **and the link-stamping step** — a replan is an emission seam, so it links its new items with `link-acceptance.sh`, and it is the sanctioned route by which a mission whose items predate this contract gets linked at all); run the approval under the conditions below.

**What a replan must never touch:**

- `status` — only `close.sh` (→ an end state) flips it; there is no other transition left.
- the checked state of existing `## Acceptance` items — only `tick-acceptance.sh` flips those.
- existing `## Changelog` lines — append-only, always (`workaholic:design` / `history-structures`).

An existing **unchecked** acceptance item may be reworded or dropped **only** when the developer explicitly says the criterion no longer holds — and the drop is recorded as its own changelog line (`acceptance dropped — <the item's (#filename) artifact>`), so the plan's shrinkage is history rather than a silent rewrite.

**History.** A replan lands as idempotent changelog lines through `append-changelog.sh`, never as edits: `ticket added — <filename>` per emitted ticket, plus one `mission replanned — <artifact>` line marking the event (both in the standard-events list below). Re-running the same replan appends nothing — the `(event, artifact)` key already exists.

**Review after a replan.** There is no approval step to re-run (K2) — but the *question* approval asked has not gone away, only moved: a replan that changes the ticket set changes what an unattended run will do, and that belongs in a pull request a human merges. So a replan publishes its delta the same way creation does, and **merging that pull request is the acceptance of the new set**.

- A replan whose interrogation was **cut short** publishes nothing. The mission keeps its previous, already-merged plan rather than landing half a new one — an unattended runner reads whatever is on `main`, so a partially-applied delta is worse than no delta.
- A thin hand-authored `0/0` mission, a `/propose` proposal, and a `carried` successor are all reached this way: replan them to a real `## Experience` and `## Acceptance`, publish, merge. That is the whole path from proposal to drive-ready.
- `merge_policy` is recorded at creation and is **not** re-asked by a replan. Changing it is an ordinary edit to the mission, published and reviewed like any other.

## Mission Position Report

**The one definition of "where does the mission stand".** Every seam that hands work across a boundary states this; none re-states or re-derives it. It contains exactly three things:

1. **How far** — `checked/total`, from `progress.sh`. Computed, never narrated.
2. **What is next** — the next unchecked acceptance item, from `next-acceptance.sh`.
3. **How far a fresh session can proceed** — what is ready to drive right now, and what is waiting on a decision or an external blocker. This is the part a later session cannot reconstruct, and the reason the report exists.

Read every figure through those scripts (`workaholic:implementation` / `domain-layer-separation`); never parse `mission.md` to answer this. The relation is **many-valued** — read it with `read-relation.sh` and report **every** mission the work advances, not the first.

**It is a report, never a prompt.** It states position and continues; it must not grow into a "shall I proceed?" — the whole direction is *less* confirmation.

**An empty `## Acceptance` (`0/0`) is reported honestly, not silenced.** The mission lens deliberately stays quiet on a `0/0` mission (an always-on nudge with nothing to act on is noise). A handoff is the **opposite** case: *"this mission has no criteria written yet"* is precisely what the next session needs to know, because it is the difference between "drive the queue" and "the plan does not exist yet". Do not copy the lens's signal gate here — this divergence is deliberate, not drift.

**Where it is stated:**

| seam | when |
| --- | --- |
| `/mission close` | before asking for the outcome, and again on a carry (what moved to the successor). |
| `/drive` | in the run report, for each mission unit the run left unfinished — the position a later run or a reader picks the work up from. Say nothing for a batch unit whose tickets carry no `mission:` relation — never fabricate a mission-shaped frame around unrelated work. |
| `/report`, `/ship` | **not** stated — recorded decision, below. |

`/report` and `/ship` roll missions but do **not** carry this report. Their audience is the PR reviewer, and the story's own sections already say what landed; adding mission position there would duplicate `/catch` and the lens for a reader who did not ask. The report exists for **continuity across a session boundary** — that is `/mission close` and an unfinished `/drive` unit, where the context is otherwise lost. Decided rather than defaulted; revisit if a reviewer ever has to ask "which mission is this?".

The dedicated hand-off command that once owned the first row is retired (`docs/loop-engineering-workflow.md` decision I5): in-flight state now lives on the **claim branch** by construction — the next run re-claims the unit with `claim.sh resume <unit-id>` and continues from the pushed work — so a resumption ticket written by hand would restate what the branch already holds. Resumption is scoped to the claim's **own** identity and fires once its heartbeat lapses; a colleague's claim is never taken over (`workaholic:drive`, *Claims*).

## Progress Rule

Progress toward achievement is **derived, never stored**: `checked ÷ total` over the `## Acceptance` checklist. No `progress:` percentage is persisted anywhere — a stored number would drift from the checklist. `scripts/progress.sh` computes `{checked, total, unlinked}` from the file on demand.

`unlinked` is what makes a stuck board legible: it counts the unchecked items carrying no `(#<filename>)` link, so `0/8` with `unlinked: 8` reads as *"this board was never wired to its tickets"* rather than *"nothing has been done"*. The two look identical without it, and for six missions they were confused for exactly that reason.

## Scripts

Every script lives at `${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/<name>`. **This table is a locator, not a contract** — each script's arguments, emitted JSON keys, idempotence, and the rulings behind it are in [`reference/scripts.md`](reference/scripts.md). Read that entry before running one.

| Script | What it does |
| ------ | ------------ |
| `create.sh` | Scaffold a new mission (slug, frontmatter, empty sections, creator-seeded `assignees`); refuses to overwrite |
| `slug.sh` | Derive a mission slug from a title — the single source of the slug rule |
| `close.sh` | The **only** sanctioned way to end a mission: flips `status`, appends the closing line, moves the dir to `archive/` |
| `list.sh` | The whole roadmap, with computed `relation`, `next`, `ready`/`ready_reason`, `merge_policy` |
| `summary.sh` | The canonical statement of the shared owner gate the lens and `/drive`'s survey answer to |
| `progress.sh` | `checked ÷ total` over `## Acceptance` — progress is computed, never stored |
| `next-acceptance.sh` | The next unchecked acceptance item |
| `gate.sh` | Read the optional `gate_*` declaration and resolve the worktree ports it is checked against (`valid` vs `driveable`) |
| `drive-authorized.sh` | Per-ticket authorization answer; conservative across a many-valued `mission:` relation |
| `read-relation.sh` | The single reader of an artifact's `mission:` relation (list or bare form) |
| `mission-owners.sh` | The single ownership oracle — `assignees`, then the legacy `assignee` |
| `read-assignees.sh` | The single parser of the `assignees` field shape |
| `append-changelog.sh` | The single changelog writer; idempotent on its (event, artifact) pair |
| `link-acceptance.sh` | The only writer of an acceptance item's `(#<filename>)` link; the caller names the pair, nothing is inferred |
| `unlinked-acceptance.sh` | Name the unchecked items no artifact can tick — the audit half of the link contract |
| `tick-acceptance.sh` | The only writer of an acceptance `[x]`, keyed on the item's `(#<filename>)` marker |
| `predict-duration.sh` | Stamp `predicted_hours` once at creation from the archived-mission trend; empty when the basis is 0 |
| `record-run-hours.sh` | The only writer of `actual_hours`; idempotent per run-id |
| `list-related-prs.sh` | Open PRs referencing a slug, so a replan sees a sibling lane's unmerged work (best-effort) |
| `queue-size.sh` | How many tickets name the mission (`todo` / `archive` / `total`) — the single counter both drivability floors read |
| `migrate-strategies.sh` | Living migration folding a legacy `strategies/` tree into feedback records |

## Ending a mission — outcomes, worktrees, and the carry doctrine

### Worktree lifecycle — claim-born and ship-torn

A mission's `.worktrees/<slug>/` worktree belongs to the **claim**, not to the mission record (`docs/loop-engineering-workflow.md` I6). It is created when a runner claims the unit (`workaholic:drive`'s *Claims* section — `claim.sh` cuts the worktree and its `work-*` branch together) and removed when that unit **ships**, or when its claim is explicitly **discarded** (`release-claim.sh`, which deletes the remote branch and is therefore not a recovery path). An unfinished mission is re-claimed by a later tick through `claim.sh resume <slug>`, which recreates the worktree **at the pushed branch tip** so the earlier run's commits and archived tickets survive.

**And creation makes none either** (decision J1, 2026-07-30 — the completion of I6). `/mission` once built the worktree before writing anything and committed inside it without pushing, which left a mission invisible to `plan-units.sh` — the failure `docs/drive-loop-runbook.md` §6 documented and `claim.sh` carried a tolerance comment for. Every mission write now goes into a **publish tree** and is published for merge: creation, replan, and close alike (`workaholic:branching`'s *The Publish Tree*). `claim.sh` is the only creator of a branch or a worktree anywhere in the plugin. The mission scripts themselves were not touched — they are cwd-relative and never branch or commit, so only the caller's `cd` target moved.

**A consequence worth expecting: an unclaimed mission owns no worktree**, so the mission lens surfaces it in the **main tree** (its location gate admits a mission that owns no worktree) rather than staying silent until you enter a directory that no longer exists at creation time. The worktree-focus rule itself is unchanged and still scopes a claim worktree's session to its own unit.

**`create-mission-worktree.sh` keeps its name, and the name is now a slight misnomer.** After J1 its only caller is `claim.sh`, and what it creates is a **claim** worktree keyed on a unit id — a mission slug being just one kind of unit id (a batch id is the other). It was **not** renamed to `create-claim-worktree.sh`: the script ships in the generated `outputs/workflows` bundle, so the name is public API to cross-agent consumers, and a rename would touch `claim.sh`, the tests, several documents, and the generated closure for no behavioural gain. The cheaper honest fix is this sentence plus the script's own header, which states it is claim-side only. Read every remaining "mission worktree" in this skill as "the claim worktree of a mission unit".

**So `close.sh` and `/mission close` keep only the archive move.** Closing a mission is a statement about the *record* — this goal is reached, abandoned, or carried — and it says nothing about whether a worktree is still in use. A worktree still standing at close time is an in-flight or stale **claim**, which the claim reader already surfaces and a human already decides about; having `close` tear it down instead made a bookkeeping action quietly destructive, and hid the one signal (`list-claims.sh`) that says whether anyone is still working there. `cleanup-mission-worktree.sh` is unchanged and still the sanctioned cleaner — it is now called from the claim-release and ship paths rather than from close.

### Outcomes

The status set is closed and validated — anything else is `invalid_status`:

| outcome | meaning |
| --- | --- |
| `achieved` | the goal was reached |
| `abandoned` | ended without reaching it, and the remainder is not worth doing |
| `carried` | done **as framed**, with the remainder still worth doing — it becomes a **successor** mission that inherits the unmet criteria |

`carried` exists because the other two could not express the common, honest verdict *"most of this landed, the rest is still worth doing"*. Forcing it into `achieved` lies to a progress model whose entire claim is that progress is **computed** from unchecked items and never hand-set; `abandoned` is simply false. It **requires** a successor — and since the ticket floor was decided, that successor must be an **existing** mission: `--successor <slug>` carries into an active one, and **`--successor-title` is refused**, because a freshly minted successor arrives with no tickets and so violates the floor by construction (*Granularity → The ticket floor*, which records the rejected alternatives). Create the successor first through the ordinary mission-creation path — that interrogation is what produces its ticket set. A carry with nowhere to carry to remains an abandon wearing a nicer name. Do not let it become a way to avoid `abandoned`: a successor nobody drives is an abandoned mission with a longer name (the bare `/mission` view and the lens surface an unclaimed successor, which is a feature).

**What the successor inherits, and why:**

- The **unchecked** `## Acceptance` items, verbatim, with their `(#<filename>)` markers intact. Checked items stay with the predecessor — they were achieved *there*, and re-listing them would make the successor's computed progress claim work it did not do. The successor starts at `0/<n unmet>`, which falls out of its own list; **no number is ever carried across**.
- `## Goal` and the `gate_*` fields, verbatim (**not** `## Scope` — see above). A carry-over is a **continuation** by definition — the mission is done as framed and the remainder pursues the same outcome — so the goal is shared and the gate still applies. A genuine *re-framing* is a new mission, not a carry.

**Lineage is recorded in both directions** (`workaholic:design` / `history-structures`): the predecessor's changelog gets `mission carried into <successor-slug>`, and the successor records `carried_from: <predecessor-slug>`. Without both, the archive shows a mission that stopped and a mission that started, with nothing joining them.

**The successor gets no worktree from the predecessor.** Closing manages no worktrees at all (see *Worktree lifecycle* above — they are claim-born and ship-torn), and a carry deliberately does not hand one over: `.worktrees/<slug>` is keyed 1:1 to the unit slug by `slug.sh`, and a successor living in the predecessor's directory **silences the mission lens inside that very worktree** — the lens reads a worktree whose basename names no active mission as a `/drive` worktree and says nothing at all. The successor gets its own worktree when it is claimed; in-flight state and the port allocation do not carry.

### When the direction changes — reorganize and carry (the encouraged answer)

A mission is **sticky to finish**: `achieved` demands every `## Acceptance` item checked, which is the right bar for a mission whose direction held. But a mission's direction often **changes mid-flight**, and then grinding to check the original criteria is effort spent against a plan that no longer describes the work. The **encouraged, positive** response in that case is **reorganize and carry** — not grind to `achieved`, not `abandoned`. Reach for it on any of three signals:

- **A different class of issue surfaced** — the work uncovered a problem the mission was not framed around, and the remaining criteria no longer point at what now matters.
- **The remaining criteria became contradictory or moot** — progress made the original plan internally inconsistent, or answered a criterion by making it irrelevant.
- **The remainder belongs to another active mission** — the leftover work is really that mission's, so it should **merge** there rather than persist as a parallel goal.

Why carry rather than the alternatives: forcing `achieved` **fabricates completion** the computed-progress model exists to prevent (progress is counted from unchecked items, never hand-set), and `abandoned` **discards real progress**. `carried` is the honest verdict — *"this landed as framed; the rest, reorganized, is still worth doing"* — and it **preserves** what was done while re-pointing the remainder.

**Reorganizing is a replan, then a carry — and it deliberately does not grind quality gates.** The mechanism is the existing **Replan** flow plus `close.sh`, used together and recorded, never hand-editing:

1. **Reorganize** via `/mission <instruction>` (the Replan flow): rewrite `## Goal`/`## Experience` (and a legacy `## Scope`) to the changed direction, and **drop the now-moot unchecked acceptance criteria** — do **not** force them checked. A dropped item is recorded as its own `acceptance dropped — <the item's (#filename) artifact>` changelog line (Replan already owns this), so the plan's shrinkage is history, not a silent rewrite. This is what *"skip filling quality gates"* means here: **stop grinding to check criteria the new direction made obsolete** — it is **not** a relaxation of the write-time floor (`hooks/validate-mission.sh` requires a non-empty `## Acceptance` and `## Experience` on every active mission).
2. **Carry** the still-valid remainder with `close.sh … carried --successor <existing-slug>`, carrying the unchecked criteria into an existing active mission. For a genuinely new heading, **create that mission first** (the interrogation emits its ticket set) and then carry into it — `--successor-title` is refused by the ticket floor. Merging needs no new operation: `--successor <slug>` already carries the unmet items and shared goal/scope into the named mission, and lineage is recorded both directions (above).

The three checked-vs-unchecked, inherit, and lineage rules above are unchanged — reorganize-and-carry is those mechanics used *deliberately and early* when the direction turns, framed as the normal move rather than a last resort.

## Automatic Updates (the workflow seams)

The mutators above are called automatically as missioned work moves through the pipeline, so a mission's progress and changelog stay current without hand-editing. Each seam reads the artifact's `mission:` relation through the single reader — `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/read-relation.sh <artifact>`, which prints one slug per line — and calls the shared scripts **once per slug**:

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

Separately from the mutating seams above, a workflow may **read** missions without writing them. `/catch` (`workaholic:catch`) is such a consumer: its scanner calls `list.sh`/`progress.sh` for the active-mission list and derived progress, window-filters each mission's `## Changelog` for merged activity, and reads the `mission:` relation on unarchived tickets to surface **in-flight** (unmerged) progress the merge-time seams cannot yet show. It appears in no seam table because a `/catch` run mutates no mission content — no changelog line, no acceptance tick. (The one tree change any reader can trigger is the living layout migration, which relocates a legacy flat mission dir without touching its bytes.)

The **mission lens** (`hooks/mission-lens.sh`) is the other read-only consumer, and an always-on one. On every `UserPromptSubmit` it injects a model-visible `additionalContext` line, and on every `Stop` a user-visible `systemMessage`, naming each **active** mission that passes all three of its gates, with derived `checked/total` and the next unchecked acceptance item (via `progress.sh` + `next-acceptance.sh`):

1. **ownership** — the current `git config user.email` is among the mission's owners (`mission-owners.sh` — the mission's own `assignees` first, then the legacy `assignee`), or the mission is unowned (surfaced as claimable). Only a mission owned solely by others stays silent.
2. **location** — worktree focus: inside a mission's own `.worktrees/<slug>`, only that mission; inside a worktree that owns **no** mission (a `/drive` worktree), nothing at all; in the main tree, only missions that own no worktree.
3. **signal** — the mission has at least one acceptance criterion. A mission whose `## Acceptance` is empty would render as `0/0` with no next step — a technical condition with nothing to act on — so it stays silent.

It keeps the agent oriented to the roadmap without hijacking the turn — it never blocks a stop (informs, does not force). Silent no-op when nothing passes all three. The gap that made this matter is now closed upstream: the **Creation Interrogation** is mandatory and a mission is not finished being created until `## Acceptance` names at least one criterion, so a mission is no longer *born* matching the silence gate. `create.sh` still scaffolds the section empty — it is a POSIX scaffold and cannot interrogate — so a hand-authored `mission.md` that bypasses `/mission` can still arrive at `0/0` and stay invisible here (the bare `/mission` view's full tier and `/catch` keep the lower assignee-only bar and still show it). That residue is the same shape as the unassigned-mission gap: a default on the sanctioned path does not constrain the other paths. Like `/catch` it mutates nothing, so it is in no seam table. (Because a Stop hook cannot inject model-visible context without `decision: block`, the model-facing half deliberately rides `UserPromptSubmit`; the `Stop` half is the user-facing nudge only.)
