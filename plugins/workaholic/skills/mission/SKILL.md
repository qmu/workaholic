---
name: mission
description: Use when the user runs `/mission`, asks to "start a mission", "plan a batch of work", "show mission progress", or "what missions are in flight". A mission is an optional, epic-equivalent grouping — a bounded, information-rich batch of two or more tickets an agent fleet drives together, never a required parent of any ticket; this skill creates one, lists missions with computed progress, and defines the mission schema every workflow reads.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Mission

A **mission** is an optional, epic-equivalent grouping of **two or more tickets**: a request brought to question-free drive-readiness — interrogated from the developer at creation, or judged from the feedback stream by an agent session (`/specificate`) — bundling the ordered ticket set an agent fleet drives together. It answers *what does this batch of tickets accomplish together*; the **feedback** stream (`workaholic:feedback`) answers *why is this work being launched* and is where long-lived direction accretes. A mission is bounded and finishes; it is **never a required parent** — the ticket stays the first-class standalone unit, and `/ticket` → `/drive` with no mission is fully sanctioned ("epic"/"milestone" are deliberately not used as artifact names). Detail lives in three reference files: [`reference/schema.md`](reference/schema.md) (the frontmatter block, field detail, quality gate, drivability, ownership, duration, the link contract, the carry decision, retired-state history), [`reference/scripts.md`](reference/scripts.md) (per-script contracts), [`reference/command-flows.md`](reference/command-flows.md) (the `/mission` and `/mission-close` orchestration, including *Routing the argument*).

## Granularity

The single home of the granularity discipline — every other place links here rather than restating it. Three description layers, no artifact restating a lower level's detail: a **commit** answers *what is this one normalized change* (normalized by the release-scan per-commit changed-lines gate); a **ticket** answers *what is this one change*, one drive-able unit (normalized by its `## Policies` / `## Quality Gate`); a **mission** answers *what does this batch accomplish together* (normalized by the Creation Interrogation, floored at two tickets). The balance test cuts both ways: a mission re-narrating its tickets' specifics is over-written; a ticket restating its mission means the mission is under-sized — surface and merge, do not write the duplicate. Put each fact at exactly one level.

### The ticket floor

**A mission is created with two or more tickets, or it is not a mission** — a ticketless one is a feedback record on the roadmap, a one-ticket one is a ticket with a progress bar. What counts: tickets naming the mission in `mission:`, present in the same publication commit as `mission.md` — checked at the **publish seam** (every creation seam calls `check-floor.sh <slug>`, whose count is `queue-size.sh`'s `meets_floor`), never at the write of `mission.md`, where the tickets do not yet exist. One ticket is refused, not warned, and **a refusal names the alternative**: a bare direction is a feedback record, a single unit of work is a plain ticket. A carry must name an existing mission (`--successor <slug>`); `--successor-title` is refused, because a minted successor arrives with zero tickets. Rejected alternatives and the accepted cost: [`reference/schema.md`](reference/schema.md), *The ticket floor*. (`create.sh` and `close.sh` deliberately do not call the check, each recording why in its header; one archived one-ticket mission predates the rule and is history, not an open violation.)

## Lifecycle

`status` is the one lifecycle field: `active` (in `active/`, in flight) | `achieved` | `abandoned` | `carried` (ended, in `archive/`). **Merging a mission's pull request is its approval** — there is no draft state and no approve step (retirement record: [`reference/schema.md`](reference/schema.md), *History*) — and **`close.sh` is the only status flip that exists**: never hand-edit `status:` or `mv` a mission dir. Drivability is not a status word: a mission is claimable when it is in the active area, has a plan (`## Acceptance` non-empty, else `no_plan`) and has a queued ticket naming it (`no_tickets`). `merge_policy: auto | review` is the orthogonal axis (G5), recorded at creation (K2); **absent means `review`**, exactly as on a ticket.

## Location and Schema

```
.workaholic/missions/active/<slug>/mission.md    # status: active
.workaholic/missions/archive/<slug>/mission.md   # achieved | abandoned | carried
```

`<slug>` derives from the title via `slug.sh` (the single source of the slug rule) and is the stable key other artifacts reference (`mission: <slug>`); the area is never part of the key — seams pass bare slugs and `lib/resolve.sh` resolves an absolute path against an explicit root (an artifact's own tree, or the repository for slug-only callers), never the process cwd. Every script first runs the living migrations (legacy flat `missions/<slug>/` dirs, retired statuses, a lingering `strategies/` tree), idempotent and best-effort. Writers: `create.sh` (filled by the Creation Interrogation) and `/specificate`'s `scaffold-draft.sh` (unowned, `feedback:`-linked); both land in `active/` and reach `main` — and every runner's survey — only when their pull request merges.

The frontmatter block (`type: Mission`, `status`, `merge_policy`, `carried_from`, `assignees`/legacy `assignee`, `predicted_hours`/`actual_hours`, reserved `tickets`/`stories`, optional `gate_*`) and every field's detail — the quality gate, drivability, the ownership oracle (`gather/scripts/owners.sh`; creator-seeded plural `assignees`, empty = team-owned/claimable, never a floor), duration, **the link contract**, the changelog line format — live in [`reference/schema.md`](reference/schema.md); read it before writing or interpreting any of these fields. Body sections, in order: `## Goal` (the information-rich why), `## Experience` (the substance — the demanded, observable behavior; what a later session reads to know what is actually demanded), `## Acceptance` (the plan: a checklist whose items name their tickets through `(#<filename>)` links stamped by the emitting seam), `## Changelog` (append-only, dated). The write-time floor (`hooks/validate-mission.sh`, on any mission under `active/`): non-empty `## Experience` and at least one `## Acceptance` item; ownership is not a floor.

### Size norms

`## Acceptance` is normatively **three items or fewer**, and the whole `mission.md` is held to ~60 lines / 2 KB — both measured by `scripts/size.sh`. Write only the minimum conditions under which the work can be called done; exhaustive coverage, per-file checklists, and audit items belong in tickets and the feedback stream (an audit-list `## Acceptance` can never be honestly closed). A **norm** for a human author (the interrogation shows the measurement), **enforced** on `/specificate`'s unattended drafts. This is a ceiling and never relaxes the write-time floor.

## Creation Interrogation (mandatory — always run)

When `/mission "<title>"` creates a mission, interrogate the developer until it is drive-ready, then emit the whole ticket set in one pass. Never skippable, never gated on the request "seeming obvious": a mission's value is that judgement is answered *before* the run starts, and a scaffolded empty shell stops at the first decision it meets. `create.sh` only scaffolds (POSIX, cannot ask); the interrogation is the command's job. Before the rounds, read the recent feedback stream (`bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/list.sh`): the `kind: concern`/`kind: insight` records an unattended run deferred are exactly the judgment calls the next mission should pre-answer.

### Elicit the requirements first

Plan quality gates everything; no downstream verification rescues a wrong understanding of the goal. First draw out what the agent cannot derive: what a user must actually be able to *do*, a **concrete example of a good output**, the **real end-to-end workflow** — specific questions about actual unknowns, never a generic "any feedback?". Grill on genuine forks only: the Recommended-label test (`rules/interaction.md`) silences every question you could answer yourself — decide those and record them where the plan is written (the `## Changelog`, or the ticket's `## Quality Gate`). Three hard gates:

- A developer's invitation to ask is a hard gate — failing to ask when invited is a planning defect, not efficiency.
- A user-facing feature may not be planned from a title: require the good-output example and the walked workflow first.
- If the goal cannot yet yield verifiable, user-experience-level `## Acceptance` criteria, the plan is not ready — keep eliciting; do not start building. (This is the opposite case from execution's decide-don't-ask rule, `workaholic:drive`: decide the *how*; never assume the *what*. Where uncertainty is high, prove it small before emitting the set.)

### The rounds

1. **Direction** — the why, the outcome, what is out of scope → `## Goal` (out-of-scope notes in a sentence, not a second list)
2. **The demanded experience** — elicited per the gate above, observable → `## Experience`
3. **The ticket set** — how many, what each covers, the `depends_on` order (the round that matters most)
4. **Per-ticket pre-answers** — everything `create-ticket` §4b would ask later, asked now, per ticket
5. **Acceptance** — one item per criterion, each naming its ticket; user-facing work needs at least one user-experience-level criterion

Never interrogate `gate_*` (optional, normally empty; ask only if the developer volunteers one). Ordering: ask everything → decide the ticket set → write the tickets → write `## Acceptance` → stamp each item's link. Items written before their tickets exist are normal (every `/specificate` proposal); it is *emission without the linking step* that strands a board.

### Emitting the set

Write the tickets in one pass, not N serial `create-ticket` runs — each with its mandatory `## Policies` and `## Quality Gate`, stamped `mission: <slug>`, ordered by `depends_on` with unique timestamps; reuse `create-ticket`'s split mechanics. The split cap does not apply to a mission — one ticket per genuinely separable unit, however many (a mission-scoped exception; the 2–4 cap still governs `/ticket` itself). In the same pass:

- **Stamp the links**: `link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per item — the pairing is named by the caller, never inferred; an item no emitted ticket satisfies stays unlinked and is reported to the developer, never linked to the nearest ticket.
- **Check the floor before the publish commit** (`check-floor.sh <slug>`; non-zero exit = not published, tell the author its `alternative`) — and say the floor out loud during decomposition, not at the publish.
- **Stamp the duration as a report line, never a question**: `predict-duration.sh <item-count>`; on `basis: 0` leave `predicted_hours` empty and record a changelog note rather than dressing a guess as data.

## Replan

The sanctioned path to reopen an active mission's plan — `/mission <instruction referencing it>`, no subcommand (routing criteria: [`reference/command-flows.md`](reference/command-flows.md)). Only active missions are targets; the archive is immutable. First surface sibling PRs (`list-related-prs.sh <slug>` — `available: false` means *unknown*, not "no siblings") and factor them into the delta. Re-run only the rounds the instruction touches: direction → 1–2; the plan → 3–5 for the delta tickets; a thin `0/0` mission (a `carried` successor, a `/specificate` proposal, a hand-authored shell) → all five. The bar equals creation's — a structured delta model, Recommended-label test included, `gate_*` never interrogated.

The delta may rewrite `## Goal`/`## Experience` (and a legacy `## Scope`), append observable `## Acceptance` items, and emit delta tickets under the same emission rules **including link-stamping** — a replan is an emission seam, and the sanctioned route by which pre-contract boards get linked at all. It must never touch `status` (only `close.sh`), the checked state of existing items (only `tick-acceptance.sh`), or existing changelog lines (append-only). An unchecked item is reworded or dropped only on the developer's explicit say-so, recorded as its own `acceptance dropped — <(#filename)>` changelog line. History lands through `append-changelog.sh` (`ticket added` per ticket, one `mission replanned`), idempotent. A cut-short interrogation publishes nothing — a partially-applied delta is worse than none — and **merging the delta's pull request is the acceptance of the new set**. `merge_policy` is not re-asked.

## Mission Position Report

The one definition of "where does the mission stand"; every hand-off seam states it, none re-derives it. Exactly three things: **how far** (`checked/total` from `progress.sh` — computed, never narrated), **what is next** (`next-acceptance.sh`), and **how far a fresh session can proceed** (what is ready to drive, what waits on a decision or blocker — the part a later session cannot reconstruct). Read every figure through the scripts; the relation is many-valued, so report every mission the work advances (`read-relation.sh`). It is a report, never a "shall I proceed?". A `0/0` mission is reported honestly ("no criteria written yet"), not silenced as the lens does — deliberate divergence, since a handoff needs exactly that fact. Stated by `/mission-close` (before asking the outcome, and again on a carry) and by `/drive` for each unfinished mission unit (never fabricated for an unmissioned batch); deliberately **not** by `/report`/`/ship`, whose audience is the PR reviewer. Progress itself is derived, never stored: `progress.sh` computes `{checked, total, unlinked}` on demand — `unlinked` distinguishes "never wired to its tickets" from "nothing done", which look identical without it.

## Scripts

At `${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/<name>`. A locator, not a contract — arguments, JSON keys, idempotence, and rulings are in [`reference/scripts.md`](reference/scripts.md); read the entry before running one.

- **Create / end**: `create.sh` (scaffold, creator-seeded `assignees`; refuses to overwrite), `slug.sh` (title → slug, the single source of the slug rule), `close.sh` (the only sanctioned way to end a mission: status flip + archive move).
- **Read**: `list.sh` (the roadmap with computed `relation`, `next`, `ready`/`ready_reason`), `summary.sh` (canonical statement of the shared owner gate), `progress.sh` (`{checked, total, unlinked}`), `next-acceptance.sh`, `gate.sh` (`gate_*` + worktree ports; `valid` vs `driveable`), `drive-authorized.sh` (per-ticket, conservative across a many-valued relation), `read-relation.sh` (the single reader of `mission:`), `unlinked-acceptance.sh`, `list-related-prs.sh` (best-effort, for the replan), `queue-size.sh` (the single ticket counter, home of `meets_floor`).
- **Write** (each the *only* writer of its field): `append-changelog.sh` (idempotent per event+artifact), `link-acceptance.sh` (the acceptance `(#<filename>)` link; pairing named, never inferred), `tick-acceptance.sh` (the `[x]`, keyed on the link), `predict-duration.sh` / `record-run-hours.sh` (`predicted_hours` once / `actual_hours`).
- **Floors / migrations**: `check-floor.sh` (the ticket floor as an act-on-able verdict). `migrate-strategies.sh` was **retired 2026-08-13** with the strategy artifact's return — see *The strategy layer: retired, then redefined* below.

## The strategy layer: retired, then redefined

A mission is **not** a strategy's execution plan, and has not been one since 2026-07-28. That day the strategy layer was retired (decision B3): a mission became an optional, epic-equivalent grouping of tickets, ownership returned to the mission itself, and long-lived direction was sent to the feedback stream — because a second direction artifact and an inbox of direction would drift, and because the retired artifact carried open-ended `## Direction` prose with **no completion condition**, so nothing could ever say it was done.

On **2026-08-13** the artifact returned, with a different definition (`workaholic:strategy`, issue #436). This is a recorded inversion, not an erasure of the retirement — both halves stand:

- **What returned**: a `Strategy` is one piece of outbound, resolved direction at `.workaholic/strategies/<slug>.md`, carrying an **Aim**, a **Schedule** (`target_date`, a real date) and an **Assignee** (non-empty `assignees`). It is bounded, owned and closable — precisely the three properties the retired artifact lacked, and the three the write floor `validate-strategy.sh` checks.
- **Why it does not re-open the drift**: the feedback stream stays the sole home of *inbound* direction — what someone said, immutable and unowned. A strategy is what the operator *decided*, and the citation link runs one way (strategy → feedback). Two homes drift when both are inboxes; only one of these is.
- **What did not return**: the `strategy:` relation on a mission, and the ownership hop it fed (`owners.sh`). A mission's owner is on the mission; a strategy's owner is on the strategy. A legacy `strategy:` key in an old mission stays tolerated history and is still read by nothing.
- **What was unwired**: `migrate-strategies.sh` and the `missions_migrate_strategies` seam, which erased `strategies/` on every mission-script touch. Leaving them wired would have deleted each revived strategy silently. The retirement's own folding stands in history; nothing reverses it, and no route re-adds the erasure.

## Worktree lifecycle

A mission's `.worktrees/<slug>/` worktree belongs to the **claim**, not the record (I6): claim-born (`claim.sh` cuts worktree and `work-*` branch together), ship-torn (or discarded by `release-claim.sh`), re-created at the pushed branch tip by `claim.sh resume` so earlier commits and archived tickets survive. Creation makes none either (J1): every mission write — create, replan, close — goes through a **publish tree** (`workaholic:branching`'s *The Publish Tree*), and `claim.sh` is the only creator of a branch or worktree in the plugin; an unclaimed mission therefore owns no worktree, and the lens surfaces it in the main tree. So `close.sh` and `/mission-close` keep **only the archive move**: a worktree still standing at close is an in-flight or stale claim, which the claim reader surfaces and a human decides about — tearing it down at close made a bookkeeping action quietly destructive. `cleanup-mission-worktree.sh` stays the sanctioned cleaner, called from the claim-release and ship paths.

## Outcomes — ending a mission

`achieved` (the goal was reached — every item checked) | `abandoned` (ended short, remainder not worth doing) | `carried` (done as framed; the remainder became a successor). Anything else is `invalid_status`. `carried` exists because neither other word can honestly say "most landed, the rest is still worth doing" — forcing `achieved` fabricates completion the computed-progress model exists to prevent, and `abandoned` is false. It requires an **existing** successor (`--successor <slug>`): the unchecked items are appended verbatim, markers intact (checked items stay with the predecessor; the successor starts at its own computed `0/<n unmet>` — no number is carried across), idempotent by item text; the successor's own Goal, gates and items are untouched, and no route imports the predecessor's framing — a genuine re-framing is a new mission. Lineage is recorded both directions: a `mission carried into <successor-slug>` changelog line, and `carried_from` on the successor (a list under a second carry). The successor gets **no worktree** from the predecessor. Do not let `carried` become a way to avoid `abandoned`: a successor nobody drives is an abandoned mission with a longer name (the lens and bare `/mission` surfacing an unclaimed successor is a feature).

**When the direction changes mid-flight, reorganize-and-carry is the encouraged answer**, not grinding to `achieved` or `abandoned`: **replan** to rewrite `## Goal`/`## Experience` and drop the now-moot unchecked criteria (each drop its own changelog line — this stops the grinding; it never relaxes the write-time floor), then **carry** the still-valid remainder with `close.sh … carried --successor <existing-slug>`. Reach for it when a different class of issue surfaced, the remaining criteria became moot or contradictory, or the remainder really belongs to another active mission (the carry merges it there).

## Automatic updates (the workflow seams)

Each seam reads the artifact's many-valued `mission:` relation through the single reader (`bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/read-relation.sh <artifact>`, one slug per line — never parse frontmatter yourself; four hand-rolled copies once truncated lists silently) and calls the shared, idempotent mutators once per slug:

| Seam | Trigger | Changelog event | Acceptance |
| ---- | ------- | --------------- | ---------- |
| `drive` (`archive.sh`) | a missioned ticket is archived | `ticket archived` | ticks the ticket's item |
| `report` (story flow) | a missioned story is reported | `story reported` | reconciles the story's `tickets:` |
| `report` (concern verdicts) | a missioned concern judged resolved | `concern resolved (unstuck)` | — |
| `ship` (concern extraction) | a missioned concern is deferred | `concern deferred (stuck)` | — |

Non-blocking is not silent: a seam never lets a mission problem block the work it is archiving, but a failed mutator is named loudly and a mutator that ran and changed nothing prints its `reason` (`"ticked": false` is not a failure, so a bare `|| true` never catches it) — never route a mutator's stdout, stderr, and exit code to `/dev/null`. Read-only consumers — `/catch`, and the always-on mission lens (`hooks/mission-lens.sh`, via `progress.sh`/`next-acceptance.sh`, gated on ownership through `gather/scripts/owners.sh`, worktree focus, and at least one acceptance item) — mutate nothing.

## Caveats

- An unchecked acceptance item is a heading, not a specification: re-check it against the source before cutting or driving its ticket, and never write the ticket by paraphrasing the item (measured: 3 of 7 up-front items were wrong at the code; [`reference/schema.md`](reference/schema.md)).
- Data is plural, placement is singular: an artifact records every mission it advances, but a ticket is driven in exactly one worktree and `.worktrees/<slug>` stays keyed 1:1 to a mission.
- Legacy artifacts are tolerated history, read by nothing, and never retro-blocked: retired `draft`/`approved` statuses, `## Scope`, `## Reflection`, `concerns: []`, `strategy:` keys ([`reference/schema.md`](reference/schema.md), *History*).
- Agent Compatibility: this skill runs on any Agent-Skills-compatible agent — where a step uses `AskUserQuestion`, use the agent's native selection prompt; the bundled POSIX scripts run identically everywhere.
