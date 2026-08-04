# Mission schema — reference

Companion reference for [`../SKILL.md`](../SKILL.md)'s **Schema** section, which carries the
frontmatter block itself and the body-section list. Everything below is the full detail behind
those fields: the optional quality gate, what makes a mission drivable, the ownership oracle,
the duration record, and the two line formats. Nothing here is optional reading when you are
actually writing or reading one of these fields — it is separated only so the skill itself stays
loadable, per the ~50-150 line guideline in `CLAUDE.md`.

### Quality gate — optional, and normally empty

**The mission's substance is `## Experience` plus the ticket plan, not these fields.** `gate_*` is an *optional* declaration for the rare mission whose outcome has a stable, objective check that is knowable at kickoff. **Empty is the normal case, not a defect**, and nothing treats an absent gate as an error.

This is a deliberate demotion. A gate declared at creation is a prediction about work that does not exist yet: as the mission learns, the gate goes stale — but it stays in the file, and an agent keeps steering by it. A `gate_target` route plus a one-line assert is also a thin proxy for what a mission is *for*; a route returning 200 is not evidence the demanded experience is right. The record supports the demotion rather than merely arguing it: **every mission created to date left all three fields empty**, and `gate.sh` cannot resolve ports for a mission living in its own worktree — the prescribed layout. The gate has been inert since it shipped and nothing broke.

So do **not** interrogate these at mission creation, and do not treat a mission without them as incomplete. Write `## Experience` instead.

When a mission *does* declare one: `gate_type` is `documentation` (the mission's docs render and read correctly), `live-app` (the mission's feature works in the running app), or `check` (the project's own verification command passes); `gate_target` is the route to check — or, for `check`, the command to run; `gate_assert` states what must hold. The browser-shaped types are verified by driving the mission worktree's running server (unique port base, `WORKAHOLIC_DEV_PORT`) with the Playwright plugin, so several missions' gates can be checked at once; workaholic declares the gate and supplies the port, while the server-start command is the project's (declared once, e.g. in the project's `CLAUDE.md`). A `check` gate is verified by running `gate_target` in the mission's worktree and passes on exit 0 — the type for projects with no browser-drivable surface (a CLI, a daemon, a library, a compiler), whose stable objective check is the verification command their `CLAUDE.md` already declares. Two cautions on `check`: it certifies **the project's checks**, not the demanded experience — `## Experience` still carries the substance — and its command must be the project's *own* declared verification, never a bespoke one-liner invented at mission creation (that would be the inert-gate problem in a new spelling). Read a gate with `gate.sh` (below); a declared gate stays **objective** (`implementation` / `objective-documentation`) — a named route or command plus an asserted condition, never "looks good".

**The objectivity requirement outlives the gate.** `## Experience` is prose, so it cannot be machine-checked the way a route-plus-assert could. That makes objectivity a convention here rather than a check — hold it anyway: describe behavior that can be observed, not qualities that cannot.

### Drivability — what makes a mission claimable

**Being in the active area is the authorization** (2026-07-31 — `docs/loop-engineering-workflow.md` K1). A mission reaches `missions/active/` on `main` only by merging the pull request it was published behind, and that merge *is* the project accepting it: `/drive`'s survey then offers the mission as a **claimable PR-unit** and drives its whole queue. Two floors still apply, and neither re-asks the PR's question — both ask whether there is anything to drive: a plan (`## Acceptance` non-empty, else `no_plan`) and a queue (at least one todo ticket naming it, else `no_tickets`).

**Drivability lives on the mission, because this is the thing that was actually interrogated.** The Creation Interrogation is where the developer answered every judgement call and co-authored each ticket's `## Quality Gate`; the pull request is where that act is reviewed. Alternatives considered and rejected, recorded so they are not re-litigated:

- **Keying off the ticket's `mission:` relation alone** — a ticket hand-added to the mission later would inherit an authorization nobody granted.
- **An explicit `/drive mission` argument** — makes authorization an act by whoever runs `/drive`, who may not be the person who ran the interrogation (and on the routine, is nobody at all).
- **A separate `drive_authorized` boolean beside the status** — the original spelling, retired 2026-07-28: two fields for one concept, free to disagree.
- **A `status: draft` gate plus an `approve.sh` flip** — the spelling from 2026-07-28 to 2026-07-31, retired by K1: once every mission arrived behind a PR (J4) it gated the same content twice, and the second gate needed a manual command to undo the first. Keeping `draft` as an *optional* marker was rejected with it (K3).

**Explicit approval is relocated, never removed.** `/drive` has no per-ticket prompt at all (retired 2026-07-28); the merge of the mission's pull request — or, for an unmissioned ticket, its creation — is the authorization that took its place. What is removed is the *completeness check inside the drive loop*; the qualitative looking-through `development` / `qa-engineering` makes non-delegable **relocates to the PR** (`/report` still writes the story, `/ship` still gates the merge on evidence). Do not blur those two: eliminate the completeness check and you are on policy; eliminate the looking-through and you are in the state three policies exist to prevent.

Read it with `drive-authorized.sh` — never by grepping the field yourself.

### Ownership — carried on the mission (2026-07-28)

**A mission's owners are its own plural `assignees` list.** The creator is the default owner (`create.sh` seeds the list with the creator); an empty list means the mission is **team-owned** — unclaimed work, surfaced to everyone as claimable. Ownership is **never a floor**: an unowned mission is claimable and is not refused by any validator (K2).

Redefinition record, so the moves are not re-litigated: ownership lived on the mission (`assignee`, singular) → moved to the strategy's `assignees` (2026-07-24 — "a direction is what a set of people own") → **returned to the mission, plural, 2026-07-28**: the loop-engineering reorganization retired the strategy layer (direction now accretes in the feedback stream — `docs/loop-engineering-workflow.md` decisions B3/B4), and in the team + AI-proposal model whoever takes a mission on, not the owner of a direction, is who answers for it. The single-oracle design is what made both moves cheap; the living migration (`migrate-strategies.sh`) folded strategy assignees down into their missions so the strategy hop could go without orphaning anything.

Read a mission's owner(s) **only** through `mission/scripts/mission-owners.sh` — never by grepping `assignee` or `assignees`. It is the single ownership oracle; first non-empty tier wins:

1. the mission's own `assignees` (via `mission/scripts/read-assignees.sh`, the single parser of the field shape — list and bare forms);
2. **legacy fallback**: the mission's own singular `assignee`, so missions predating the plural field are never orphaned.

Prints one owner per line; **empty output means unowned** — unclaimed work, surfaced to everyone as claimable. A mission may be **co-owned**; "mine" means the caller is **among** the owners, not the sole one.

**Not somebody else's, not exactly mine.** `summary.sh`, the **mission lens**, `list.sh`'s `relation`, and `/drive`'s survey all gate on "is this mission my business" — the caller is among the owners (mine, shown first), or there are no owners (unassigned, shown as claimable, after your own); a mission owned only by others stays silent. All four read through `mission-owners.sh`, so the gate is defined once.

**Claiming a mission = a one-line edit to that mission** — add yourself to its `assignees`. The claim is mission-local: it commits you to this plan and nothing else.

This is per-worktree by construction — each worktree checks out its own `.workaholic/`, so the lens that fires there reflects the missions that are the business of whoever is working that tree.

### Duration (predicted / actual)

`predicted_hours` and `actual_hours` record, in decimal **agent-hours**, how long a mission's implementation is expected to take a coding agent and how long it actually consumed — so archived missions accumulate a trend the next planning reads.

- **`predicted_hours`** is stamped **once at creation**, deterministically, by `predict-duration.sh`: `median(actual_hours ÷ acceptance-item total)` across archived missions that carry both, times this mission's planned item count. With **no archived basis** it reports `basis: 0` and the field stays **empty** with a changelog note — never a fabricated number. It is a **report line to the developer, never a question** (`development` / `overnight-ai`: pre-answer, don't ask).
- **`actual_hours`** is accumulated by `/drive` (decision I7), which sums the wall-clock its run spent on that mission's PR-unit and calls `record-run-hours.sh` once per mission per run-id. That recorder is `actual_hours`'s **only writer** (same doctrine as `tick-acceptance.sh` — never hand-edited), idempotent per run-id, and it carries each increment in a `run recorded (+Xh) — <run-id>` changelog line so the sum reconstructs from history.

**The actual is agent time on mission units only** — a deliberate, documented limitation, not a gap to close silently. A batch unit of unmissioned backlog tickets has no mission to accumulate into, so it records nothing: the prediction answers "how long will the *agents* need on this mission", and only a mission has a plan to measure against. Calendar span and commit-timestamp heuristics were rejected (idle pollution / estimation logic).

### Acceptance-checklist convention

Each acceptance item is a Markdown checklist entry that names the ticket or story expected to satisfy it, by filename, in a trailing `(#<filename>)` marker:

```markdown
- [ ] Users can create a mission from the CLI (#20260706203044-mission-artifact-type-and-command.md)
- [x] Missions carry machine-readable relations (#20260706203045-mission-frontmatter-linkage.md)
```

The `(#<filename>)` marker is the **stable link** from an acceptance item to the artifact that satisfies it. Progress computation counts `[x]` against the total; the marker lets a completed ticket/story flip exactly its own item to `[x]` (that flip is owned by the mission update scripts, not by hand-editing).

#### The link contract (decided 2026-08-03)

The marker stays the link, and three rules define how it is established and read. Each closes one way a board could misreport itself:

1. **The link is item-scoped, not line-scoped.** The marker counts wherever it appears within the item — the checkbox line or any of its wrapped continuation lines — and `tick-acceptance.sh` flips that item's box. A criterion long enough to wrap is ordinary in a mission, and a link that only worked on unwrapped prose would be a formatting requirement wearing a link's clothes.
2. **The link is established when the ticket set is emitted, never demanded at authoring time.** An acceptance item may legitimately be written *before* any ticket exists — that is exactly what `/propose` does — so a markerless item is a valid intermediate state, not a defect. The moment the ticket set is emitted, every filename exists at once, and that is when `link-acceptance.sh` stamps the marker: item text preserved exactly, one explicit item↔artifact pair per call, never inferred.
3. **Unlinked is a reported state, never a silent one.** `progress.sh` carries an `unlinked` count beside `checked`/`total`, and `tick-acceptance.sh` separates *not satisfied* (`no_unchecked_match` — the open items are linked, this artifact just does not satisfy one) from *not addressable* (`unlinked_items` — the board carries unchecked items no artifact could ever tick). `unlinked-acceptance.sh` lists exactly which items those are, which is what makes a stranded board repairable by script rather than by hand.

**The measurement that forced this** (re-measured 2026-08-03, and it had grown since the mission was written): across ten missions, **19 of 47 acceptance items carry a link** — and the split is entirely by authoring route, not by author care. Every one of the **19 items across the four interrogation-authored missions is linked**, and all four closed `achieved` at N/N. Every one of the **37 items across the six `/propose`-scaffolded missions is unlinked** — the five active ones sit at 0/28, and the single one that reached the archive got there as **`abandoned` at 0/9**. No markerless mission has ever been recorded as achieved, because none of them could be.

**Repairing a board that predates the contract is a plan statement, so it is made where the plan is made.** `unlinked-acceptance.sh` names every stranded item with the index `link-acceptance.sh` takes as its selector, so any of them is reachable by script with no checkbox hand-edited — but the *pairing* still has to come from someone who knows the mission's plan. That is the **replan** seam (or the run that drives the mission), not a bulk sweep: a runner linking five missions it never planned would be guessing at scale, which is the one thing the contract forbids. The measurement is the audit; the repair rides the next plan.

**Rejected alternatives**, recorded so they are not re-litigated:

- **Relax the ticker to resolve markerless items by title match or position.** Inference guesses *which* artifact satisfies *which* criterion, and a wrong guess checks a box the work did not satisfy — a false `[x]` is strictly worse than a stuck `[ ]`, and it is the exact class of misreport this contract exists to remove.
- **Require the marker at authoring time** (a write-time floor on `## Experience`'s sibling). It collides head-on with the structural cause: `/propose` writes acceptance items before any ticket filename exists, so the floor would either refuse the proposal batch outright or push a fabricated filename into the file.
- **Replace the marker with a satisfaction check** derived from ticket or test state. A mission's criteria are written at the user-experience level ("a developer whose criteria are satisfied sees a board that says so"); no mechanical check knows whether that holds. Judgment is what the acceptance list carries, and a check that could replace it would mean the criterion was written at the wrong altitude.

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

### The ticket floor — the carry decision (decided 2026-08-04)

The rule and its boundary are in [`../SKILL.md`](../SKILL.md), *Granularity → The ticket floor*: a mission is created with two or more tickets, counted at the publish seam via `queue-size.sh`'s `meets_floor`. This file carries the part a reader only needs when changing it.

**`close.sh --successor-title` is refused; a carry names an existing mission.** The rejected alternatives, with their costs, so the trade stays visible:

| Option | Why not |
| ------ | ------- |
| **(a)** The close emits the successor's ticket set in the same pass | Consistent with the rule, but `close.sh` is a bookkeeping script and this hands it a *planning* responsibility. The planning input — what the remaining tickets actually are — is not derivable from the unmet acceptance items; a person or an interrogation must supply it. Rejected for putting planning in the one seam that has none. |
| **(c)** A carried successor is exempt from the floor | Rejected on its face: the carry is the **only** seam that has ever produced a violation, so an exemption covering it is not a rule. |

The chosen option's cost is real and accepted: a genuine "this direction continues but nothing suitable exists yet" carry has no one-step path, and the developer must create the successor first. That is not a workaround — **creating it *is* the interrogation that produces its tickets**, which is the behavior the floor is asking for.

**Sequencing — do not reverse these two steps.** The unmet-acceptance inheritance lives *entirely inside* `close.sh`'s mint branch; `--successor <slug>` resolves a path and falls through, inheriting nothing, despite `SKILL.md` and `CLAUDE.md` both claiming it "already carries the unmet items". Refusing `--successor-title` before that is corrected would leave **no** carry route that transfers the remainder — trading a record defect (a ticketless mission on the roadmap) for a data-loss one (a carry that reports success and drops its payload). Relocate the inheritance so both routes perform it (ticket `20260804184949-a-carry-into-an-existing-mission-silently-drops-the-remainder.md`), **then** refuse the title. `close.sh` carries this note at the refusal site.
