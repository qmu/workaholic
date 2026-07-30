# Mission schema — reference

Companion reference for [`../SKILL.md`](../SKILL.md)'s **Schema** section, which carries the
frontmatter block itself and the body-section list. Everything below is the full detail behind
those fields: the optional quality gate, what `status: approved` asserts, the ownership oracle,
the duration record, and the two line formats. Nothing here is optional reading when you are
actually writing or reading one of these fields — it is separated only so the skill itself stays
loadable, per the ~50-150 line guideline in `CLAUDE.md`.

### Quality gate — optional, and normally empty

**The mission's substance is `## Experience` plus the ticket plan, not these fields.** `gate_*` is an *optional* declaration for the rare mission whose outcome has a stable, objective check that is knowable at kickoff. **Empty is the normal case, not a defect**, and nothing treats an absent gate as an error.

This is a deliberate demotion. A gate declared at creation is a prediction about work that does not exist yet: as the mission learns, the gate goes stale — but it stays in the file, and an agent keeps steering by it. A `gate_target` route plus a one-line assert is also a thin proxy for what a mission is *for*; a route returning 200 is not evidence the demanded experience is right. The record supports the demotion rather than merely arguing it: **every mission created to date left all three fields empty**, and `gate.sh` cannot resolve ports for a mission living in its own worktree — the prescribed layout. The gate has been inert since it shipped and nothing broke.

So do **not** interrogate these at mission creation, and do not treat a mission without them as incomplete. Write `## Experience` instead.

When a mission *does* declare one: `gate_type` is `documentation` (the mission's docs render and read correctly), `live-app` (the mission's feature works in the running app), or `check` (the project's own verification command passes); `gate_target` is the route to check — or, for `check`, the command to run; `gate_assert` states what must hold. The browser-shaped types are verified by driving the mission worktree's running server (unique port base, `WORKAHOLIC_DEV_PORT`) with the Playwright plugin, so several missions' gates can be checked at once; workaholic declares the gate and supplies the port, while the server-start command is the project's (declared once, e.g. in the project's `CLAUDE.md`). A `check` gate is verified by running `gate_target` in the mission's worktree and passes on exit 0 — the type for projects with no browser-drivable surface (a CLI, a daemon, a library, a compiler), whose stable objective check is the verification command their `CLAUDE.md` already declares. Two cautions on `check`: it certifies **the project's checks**, not the demanded experience — `## Experience` still carries the substance — and its command must be the project's *own* declared verification, never a bespoke one-liner invented at mission creation (that would be the inert-gate problem in a new spelling). Read a gate with `gate.sh` (below); a declared gate stays **objective** (`workaholic:implementation` / `objective-documentation`) — a named route or command plus an asserted condition, never "looks good".

**The objectivity requirement outlives the gate.** `## Experience` is prose, so it cannot be machine-checked the way a route-plus-assert could. That makes objectivity a convention here rather than a check — hold it anyway: describe behavior that can be observed, not qualities that cannot.

### Approval — the drive authorization

`status: approved` records that this mission's ticket set was **interrogated and approved** by a human: `/drive`'s survey then offers the mission as a **claimable PR-unit** and drives its whole queue. `draft` (the scaffold default) is invisible to the executor — a proposal nobody has answered for yet. The flip is performed only by `approve.sh` (below), which also records the `merge_policy` ruling and seeds the approver as owner.

**Authorization lives here, on the mission, because this is the thing that was actually interrogated.** The Creation Interrogation is where the developer answered every judgement call and co-authored each ticket's `## Quality Gate`; approving the mission is approving that act. Two alternatives were considered and rejected, recorded so they are not re-litigated:

- **Keying off the ticket's `mission:` relation alone** — a ticket hand-added to the mission later would inherit an authorization nobody granted.
- **An explicit `/drive mission` argument** — makes authorization an act by whoever runs `/drive`, who may not be the person who ran the interrogation (and on the routine, is nobody at all).
- **A separate `drive_authorized` boolean beside the status** — the original spelling, retired 2026-07-28 (see the *Redefinition record* above): two fields for one concept, free to disagree.

**Explicit approval is relocated, never removed.** `/drive` has no per-ticket prompt at all (retired 2026-07-28); this approval — or, for an unmissioned ticket, its creation — is the authorization that took its place. What is removed is the *completeness check inside the drive loop*; the qualitative looking-through `workaholic:development` / `qa-engineering` makes non-delegable **relocates to the PR** (`/report` still writes the story, `/ship` still gates the merge on evidence). Do not blur those two: eliminate the completeness check and you are on policy; eliminate the looking-through and you are in the state three policies exist to prevent.

Read it with `drive-authorized.sh` — never by grepping the field yourself.

### Ownership — carried on the mission (2026-07-28)

**A mission's owners are its own plural `assignees` list.** The creator/approver is the default owner (`create.sh` seeds the list with the creator); an empty list means the mission is **team-owned** — unclaimed work, surfaced to everyone as claimable.

Redefinition record, so the moves are not re-litigated: ownership lived on the mission (`assignee`, singular) → moved to the strategy's `assignees` (2026-07-24 — "a direction is what a set of people own") → **returned to the mission, plural, 2026-07-28**: the loop-engineering reorganization retired the strategy layer (direction now accretes in the feedback stream — `docs/loop-engineering-workflow.md` decisions B3/B4), and in the team + AI-proposal model the approver of a mission, not the owner of a direction, is who answers for it. The single-oracle design is what made both moves cheap; the living migration (`migrate-strategies.sh`) folded strategy assignees down into their missions so the strategy hop could go without orphaning anything.

Read a mission's owner(s) **only** through `mission/scripts/mission-owners.sh` — never by grepping `assignee` or `assignees`. It is the single ownership oracle; first non-empty tier wins:

1. the mission's own `assignees` (via `mission/scripts/read-assignees.sh`, the single parser of the field shape — list and bare forms);
2. **legacy fallback**: the mission's own singular `assignee`, so missions predating the plural field are never orphaned.

Prints one owner per line; **empty output means unowned** — unclaimed work, surfaced to everyone as claimable. A mission may be **co-owned**; "mine" means the caller is **among** the owners, not the sole one.

**Not somebody else's, not exactly mine.** `summary.sh`, the **mission lens**, `list.sh`'s `relation`, and `/drive`'s survey all gate on "is this mission my business" — the caller is among the owners (mine, shown first), or there are no owners (unassigned, shown as claimable, after your own); a mission owned only by others stays silent. All four read through `mission-owners.sh`, so the gate is defined once.

**Claiming a mission = a one-line edit to that mission** — add yourself to its `assignees`. The claim is mission-local: it commits you to this plan and nothing else.

This is per-worktree by construction — each worktree checks out its own `.workaholic/`, so the lens that fires there reflects the missions that are the business of whoever is working that tree.

### Duration (predicted / actual)

`predicted_hours` and `actual_hours` record, in decimal **agent-hours**, how long a mission's implementation is expected to take a coding agent and how long it actually consumed — so archived missions accumulate a trend the next planning reads.

- **`predicted_hours`** is stamped **once at creation**, deterministically, by `predict-duration.sh`: `median(actual_hours ÷ acceptance-item total)` across archived missions that carry both, times this mission's planned item count. With **no archived basis** it reports `basis: 0` and the field stays **empty** with a changelog note — never a fabricated number. It is a **report line to the developer, never a question** (`workaholic:development` / `overnight-ai`: pre-answer, don't ask).
- **`actual_hours`** is accumulated by `/drive` (decision I7), which sums the wall-clock its run spent on that mission's PR-unit and calls `record-run-hours.sh` once per mission per run-id. That recorder is `actual_hours`'s **only writer** (same doctrine as `tick-acceptance.sh` — never hand-edited), idempotent per run-id, and it carries each increment in a `run recorded (+Xh) — <run-id>` changelog line so the sum reconstructs from history.

**The actual is agent time on mission units only** — a deliberate, documented limitation, not a gap to close silently. A batch unit of unmissioned backlog tickets has no mission to accumulate into, so it records nothing: the prediction answers "how long will the *agents* need on this mission", and only a mission has a plan to measure against. Calendar span and commit-timestamp heuristics were rejected (idle pollution / estimation logic).

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
