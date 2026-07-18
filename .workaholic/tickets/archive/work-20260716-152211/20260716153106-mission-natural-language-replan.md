---
created_at: 2026-07-16T15:31:06+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# /mission routes a natural-language instruction to a replan flow on the existing mission

## Overview

`/mission` today has four modes — create (title), list (bare), `summary`, and `close <slug>` — and none of them can reopen an existing mission's plan. A thin mission (hand-authored `0/0`), a mid-flight mission whose scope grew, and a `carried` successor (minted by `close.sh` with no worktree and no tickets) all have no sanctioned path back into the Creation Interrogation. The create branch stops twice on an existing slug (`create-mission-worktree.sh` "worktree already exists", `create.sh` `reason: "exists"`), so `/mission "<same title>"` dead-ends.

This ticket adds a **replan flow** that is reached **without a subcommand**: the developer writes `/mission <slug-or-title>のミッションの<X>を<Y>する` (or any free-form instruction that references an existing mission) and the command routes it to a full replan of that mission. Dispatch is context-aware, like `/report` and `/ship`: the argument's *content* selects the mode, not a keyword.

**Dispatch (decided):** model judgment with confirmation on ambiguity. After the existing `summary` → `close` → empty matches, the command runs `list.sh` and judges whether the remaining argument references an existing mission (slug verbatim, title verbatim or as a clear substring, or an instruction phrased *about* a mission — "〜のミッションの…"). Clearly referencing → replan flow; ambiguous (could be a new title, or matches more than one mission) → `AskUserQuestion` with the `[<project label>]` prefix offering "update mission <slug>" vs "create a new mission with this title"; referencing nothing → the create flow, unchanged. The judgment criteria are written into `commands/mission.md` so the routing is reviewable; a deterministic resolver script was considered and rejected — matching "〜する感じに" is natural-language understanding, which is the main agent's job, and the命令文 must never silently become a garbage mission title.

**Replan scope (decided): full.** A replan may rewrite `## Goal` / `## Scope` / `## Experience`, append `## Acceptance` items, emit additional tickets in one pass, and re-stamp `drive_authorized` — everything the Creation Interrogation produces, applied as a delta.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work; any new/changed shell stays POSIX `#!/bin/sh -eu`)
- `workaholic:design` / `policies/modeless-design.md` — the whole point of the ticket: no `replan` subcommand/mode switch; the argument's content selects the flow, mirroring `/report`/`/ship` context-awareness
- `workaholic:planning` / `policies/modeling-centric-design.md` — the replan interrogation's bar is a structured delta model (what changes, which tickets, what order), not a Q&A transcript
- `workaholic:implementation` / `policies/objective-documentation.md` — appended `## Acceptance` items stay observable and ticket-linked (`(#<filename>)`); progress stays computed, never stored
- `workaholic:design` / `policies/history-structures.md` — a replan is itself history: it lands as idempotent `## Changelog` lines through `append-changelog.sh`, never as rewritten past lines

## Key Files

- `plugins/workaholic/commands/mission.md` - dispatch order (summary → close → empty → **reference-to-existing → replan** → title → create) with the written judgment criteria and the ambiguity `AskUserQuestion`; the new replan mode section; the `carried` branch's successor paragraph updated to point at replan
- `plugins/workaholic/skills/mission/SKILL.md` - new **Replan** protocol section (which Creation Interrogation rounds re-run, what the delta may touch, what it must never touch), the `drive_authorized` re-stamp conditions, and the new standard changelog event(s)
- `plugins/workaholic/skills/mission/scripts/append-changelog.sh` - reused as-is (events are free-form; only SKILL.md's standard-events list grows)
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` - reused by replan when the mission has no worktree (the carried-successor case)
- `plugins/workaholic/skills/mission/scripts/list.sh` - the dispatch's mission inventory (slug + title + status + path); no change expected
- `scripts/test-workflow-scripts.mjs` - new hermetic assertions (see Quality Gate)
- `outputs/workflows/` - regenerated (the mission skill ships there; argument-less `node scripts/build-plugins/build.mjs`)
- `CLAUDE.md` - `/mission` command-table row gains the update capability; the mission sections' "one-shot plan" framing updated in the same commit

## Related History

The mission worktree model, the active/archive split with `close.sh`, and the many-valued relation were all built in the last few days; this ticket adds the one lifecycle verb they left out (reopening the plan).

- [20260714011847-mission-create-worktree-kickoff.md](.workaholic/tickets/archive/work-20260714-000543/20260714011847-mission-create-worktree-kickoff.md) - built the create flow (worktree + interrogation + one-pass ticket emission) the replan flow re-enters
- [20260713103820-mission-active-archive-split-and-close.md](.workaholic/tickets/archive/work-20260713-102453/20260713103820-mission-active-archive-split-and-close.md) - built `close.sh` and the `carried` successor whose "no worktree, no tickets" state replan must be able to flesh out
- [20260715143954-mission-relation-many-valued.md](.workaholic/tickets/archive/work-20260715-112717/20260715143954-mission-relation-many-valued.md) - the relation/read-path conventions replan-emitted tickets must follow (`mission: <slug>` stamped, read through `read-relation.sh`)

## Implementation Steps

1. **Dispatch** (`commands/mission.md`): insert the reference-detection step between the empty branch and the title branch. Run `list.sh`; judge the argument against every mission's `slug` and `title` per the written criteria. Three outcomes: replan / `AskUserQuestion` (ambiguous — `[<project label>]`-prefixed body, options "update <slug>" per candidate + "create new") / create (unchanged). **Only `status: active` missions are replan targets**; an argument referencing an archived mission gets a short report pointing at `close carried`'s successor or a new mission instead.
2. **Replan flow — locate and enter the worktree.** Resolve the mission's `mission.md` via `list.sh`'s `path`. If `.worktrees/<slug>` is missing (carried successor, hand-authored mission), create it with `create-mission-worktree.sh "<slug>"` — this closes the seam gap where the command's carried branch pointed at a create flow that dead-ends on `create.sh` `exists`. All writes happen in the worktree via `( cd <worktree_path> && … )` subshells.
3. **Scoped re-interrogation** (SKILL.md new section): re-run the Creation Interrogation rounds the instruction touches — Direction changes → rounds 1–2; plan growth → rounds 3–5 for the delta tickets; a thin mission (`0/0`, empty sections) → all five rounds. Same rules as creation: multiple sequential `AskUserQuestion` rounds from the main agent, grill until the delta is drive-ready, `gate_*` never interrogated.
4. **Apply the delta.** Rewrite `## Goal`/`## Scope`/`## Experience` from the answers (the command already owns body-section writes at creation; replan follows the same pattern — no new body-mutator script). Emit the delta tickets in one pass into the worktree's `todo/<user>/` (each `mission: <slug>`, mandatory `## Policies`/`## Quality Gate` pre-answered, `depends_on` ordered, unique timestamps, split cap inapplicable — mission-scoped exception already recorded in SKILL.md). Append one `## Acceptance` item per new criterion with its `(#<filename>)` marker.
5. **What replan must never touch** (SKILL.md, stated explicitly): `status` (only `close.sh` flips it), the checked state of existing `## Acceptance` items (only `tick-acceptance.sh` flips those), and existing `## Changelog` lines (append-only). Existing unchecked acceptance items may be *reworded or dropped only* when the developer explicitly says the criterion no longer holds — record such a drop as its own changelog line.
6. **History**: append changelog lines through `append-changelog.sh` — `ticket added — <filename>` per emitted ticket (the `(event, artifact)` pair keeps it idempotent), plus one `mission replanned — <first-new-ticket-or-mission.md>` line marking the event. Add both to SKILL.md's standard-events list.
7. **`drive_authorized` re-stamp rules** (SKILL.md): already-stamped mission + fully interrogated delta → stamp stays/re-set `true` (the original set was interrogated at creation, the delta now). Never-stamped mission (hand-authored) → stamp only if the replan interrogated the **entire current set**, not just the delta — the stamp asserts every judgement call about these exact tickets was answered. Interrogation cut short → no stamp, ever.
8. **Commit** in the worktree via the commit skill: subject `Replan mission <slug>`.
9. **Docs in the same change**: `commands/mission.md`, `skills/mission/SKILL.md`, `CLAUDE.md` (`/mission` row + mission lifecycle prose), `.workaholic/README.md` if it describes `/mission` modes. Rebuild `outputs/` (argument-less `build.mjs`) since the mission skill ships to `outputs/workflows`.
10. **Tests**: extend `scripts/test-workflow-scripts.mjs` with hermetic assertions for the script-level behavior the flow relies on (see Quality Gate).

## Quality Gate

How the outcome's quality is assured, captured from the developer at ticket time. `/drive` surfaces this in its approval prompt and forwards it into the commit `Verify:` key.

**Acceptance criteria** — the checkable conditions that must hold:

- `/mission <instruction referencing an existing active mission>` enters the replan flow: no new mission directory is created, the referenced `mission.md` gains the interrogated updates, and delta tickets land in that mission worktree's `todo/<user>/` stamped `mission: <slug>`.
- `/mission "<fresh title>"` still creates a new mission exactly as today (regression guard on the create route).
- An ambiguous argument produces an `AskUserQuestion` whose body carries the `[<project label>]` prefix — never a silent route to either flow.
- Replanning a mission with no worktree (carried successor) creates `.worktrees/<slug>` via `create-mission-worktree.sh` and proceeds; the carried branch of `close` no longer points at a dead-ended create flow.
- A replan never flips `status`, never changes an existing item's `[x]`/`[ ]` state except via the sanctioned mutators, and never rewrites an existing changelog line; re-running the same replan appends no duplicate changelog lines (idempotent `(event, artifact)` keys).
- `drive_authorized` is re-stamped only under the step-7 conditions; a cut-short interrogation leaves it unset.
- An argument referencing an **archived** mission is refused with a pointer to `carried`/new-mission — the archive area stays immutable history.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic assertions covering: `append-changelog.sh` idempotency for the new event names; a worktree-less mission gaining a worktree through `create-mission-worktree.sh` in the replan sequence; replan-emitted ticket frontmatter passing the same checks `validate-ticket.sh` enforces.
- `node scripts/build-plugins/build.mjs` (argument-less) then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs` all clean — the mission skill ships into `outputs/workflows`, so the freshness guard must pass.

**Gate** — what must pass before approval:

- The suite, build, verify, and metadata checks above are green, and both dispatch routes are exercised live in-session on a real mission — one instruction-form invocation lands in the replan flow end to end (interrogation → delta tickets → changelog → re-stamp), and one fresh-title invocation still creates — with the developer confirming the routing decisions shown.

## Considerations

- The dispatch judgment criteria must be *written*, not implied — which signals count as a reference (verbatim slug, title substring, "〜のミッション" phrasing) live in the command prose so a reviewer can audit a routing decision after the fact (`plugins/workaholic/commands/mission.md`).
- The `close carried` successor paragraph currently tells the developer the successor "is created through the normal `/mission` worktree flow", which dead-ends on `create.sh` `exists` — replan becomes the sanctioned successor-flesh-out path and that paragraph must say so (`plugins/workaholic/commands/mission.md`).
- Do not add body-section mutator scripts: Goal/Scope/Experience writes are already the command's job at creation, and replan reuses that pattern; only `status`, acceptance ticks, and changelog stay script-owned (`plugins/workaholic/skills/mission/SKILL.md`).
- The mission lens needs no change: a replanned mission that gains its first acceptance items simply starts passing the signal gate — the replan flow is exactly the "sanctioned path to enrich a `0/0` mission" the lens documentation says is missing (`plugins/workaholic/hooks/mission-lens.sh`).
- Keep the replan interrogation's bar equal to creation's: with `drive_authorized` skipping per-ticket approval downstream, an under-interrogated delta is concretized across the whole mission unchecked (`plugins/workaholic/skills/mission/SKILL.md`).
- `outputs/` rebuild is mandatory in the same commit — the `Outputs Freshness` CI workflow fails on any drift (`.github/workflows/outputs-freshness.yml`).

## Final Report

Development completed as planned, with one recorded gate deviation.

The dispatch judgment (written criteria: verbatim slug, clear title substring,
instruction-about-a-mission phrasing; active-only targets; the ambiguity
`AskUserQuestion`; archived → pointer, never a write) landed in
`commands/mission.md` as a new *Referencing an existing mission — replan*
section, with the dispatch paragraph rewritten to route by content. The replan
protocol (scoped rounds table, what the delta may/must-never touch, the
`acceptance dropped` drop-record rule, the three `drive_authorized` re-stamp
conditions) landed in `skills/mission/SKILL.md`, and the standard changelog
events grew `ticket added` / `mission replanned` / `acceptance dropped` —
`append-changelog.sh` itself unchanged, as planned. The `close carried`
successor paragraph now points at replan instead of the dead-ended create flow.
Docs updated in the same change: `CLAUDE.md` `/mission` row and
`.workaholic/README.md`'s one-shot framing.

**Gate deviation (developer-decided):** the live in-session exercise of both
dispatch routes could not run — the repository has no mission to replan, and the
developer chose to exercise the flow in first real use and return feedback as a
new ticket, rather than manufacture a throwaway mission. The hermetic half of
the gate is fully met (853/853, including the three new replan-seam pins:
idempotent replan events, the worktree-less mission gaining `.worktrees/<slug>`
through the sanctioned creator while `create.sh` still refuses `exists`, and a
replan-emitted delta ticket passing `validate-ticket.sh`).

### Discovered Insights

- **Insight**: A mission fixture whose directory slug does not equal
  `slug.sh(title)` is unrealistic and produces false test verdicts — the first
  version of the seam test seeded `replanme` with title "Replan Me", and
  `create.sh` "failed to refuse" simply because it derived `replan-me` and
  created a sibling.
  **Context**: `slug.sh` being the single source of the slug rule means test
  fixtures must honor it too; any hand-built mission dir in a test should be
  named exactly `slug.sh(title)`.
