---
name: strategy
description: Use when a session needs to record, list, read, or close a strategy — the operator's outbound, resolved direction, bounded by a schedule and carried by a named assignee. Defines the artifact's model and owns its scripts.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Strategy

A **Strategy** is one piece of **outbound, resolved direction**: what the operator has committed
to pursue (**Aim**), by when (**Schedule**), and who carries it (**Assignee**). It lives flat at
`.workaholic/strategies/<slug>.md`, one file per strategy, and is **operator-authored** — no
command, hook, or routine puts one on `main` on its own.

**The one drafting exemption** (2026-08-14): `/propose` may draft a strategy into its proposal
pull request, and **that pull request never auto-merges**, so the file still reaches `main` only
when a human merges it — the operator's merge is the authorship. Everything else holds unchanged:
`create.sh` is still the only writer, `close.sh` still the only writer of an end state, `/drive`
still never surveys a strategy, and the bar `/propose` must clear is all three parts present in
the ask (a date, a named owner, an aim with no decomposable plan) or it emits nothing
(`workaholic:propose`, *The strategy form, and the one rule it widens*). The same exemption
covers `close.sh` when an ask **announces** that a named strategy ended — matched by explicit
slug only, never by title similarity. There is still no third writer: nothing edits a live
strategy's Aim, Schedule or Assignee, so an announced *change* is captured as feedback and
applied by the operator.

## The model

| Part | Where it lives | What it means |
| ---- | -------------- | ------------- |
| **Aim** | `## Aim` body section | The direction's substance, in the operator's words. What is being pursued and what "pursued" means here. |
| **Schedule** | `target_date:` frontmatter + `## Schedule` body section | The dated bound. `target_date` is a single `YYYY-MM-DD` — the date by which the aim is meant to hold. `## Schedule` carries the shape around it (a start, milestones, a cadence) in prose. |
| **Assignee** | `assignees:` frontmatter | Who carries it. Plural like every other artifact, resolved through the one ownership oracle (`gather/scripts/owners.sh`), but — unlike everywhere else — **it may not be empty**: an unowned direction is not a strategy. |

`status:` is a single axis, `active | achieved | abandoned`. `close.sh` is the only writer of an
end state; nothing else edits the field. There is no separate `archive/` area — a closed strategy
stays where it is and its `status` says what happened, because a strategy is small enough that its
whole history is the file.

## What a strategy is not

- **Not the feedback stream.** `feedbacks/` records what someone *said*: inbound, immutable,
  undated, unowned. A strategy records what the operator *decided*: outbound, revisable until
  closed, dated, owned. The link is **one-way** — a strategy may cite the records that formed it
  through the many-valued `feedback:` relation, and no feedback record ever points at a strategy.
  Two homes for direction only drift when both are inboxes; only one of these is.
- **Not a mission.** A strategy carries **no ticket plan and no acceptance list**. Planning
  executable work is a mission's job (`workaholic:mission`, and the two-or-more-tickets floor).
  A strategy that wants execution gets missions created under it by the operator; it never grows
  a queue of its own, and `/drive` never surveys it.
- **Not a status board.** Progress is not computed and not stored. The schedule is the only
  temporal claim a strategy makes.

## Its relation to missions

A strategy and a mission are **not linked in either direction**. The 2026-07-28 retirement removed
`strategy:` from the mission scaffold and folded strategy `assignees` down onto missions precisely
because the extra relation gave ownership a second resolution path (the "ownership hop"
`mission-owners.sh` used to make), and that hop is not being rebuilt. A mission's owner is on the
mission; a strategy's owner is on the strategy. An operator who wants to see them together reads
both.

## Which work belongs to a strategy — through the feedback stream, adding no field

A reader that needs "what moved on this strategy" — `/standup`'s per-strategy digest is the first —
asks **one script** and nothing else parses the question:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/attributed-work.sh <slug> [window] [.workaholic-root]
```

**The rule, written down before any summary is computed** (the Open Decision on ticket
`20260817115231-resolve-strategy-to-activity-attribution`, resolved 2026-08-17): attribution runs
along the citation that already exists, and **no new field is added anywhere**.

| Hop | Rule | `attribution` |
| --- | ---- | ------------- |
| 1 | The artifact's `feedback:` refs intersect the strategy's | `direct` |
| 2 | A **mission** attributed by hop 1 is named by the artifact's `mission:` relation | `via_mission:<slug>` |

Hop 2 is load-bearing, not a nicety: `/propose` puts the `feedback:` refs on the **mission** and its
ticket set carries `mission:` instead, so a one-hop reader would see almost nothing. Both hops read
their relation through that relation's existing single reader
(`propose/scripts/read-feedback-relation.sh`, `mission/scripts/read-relation.sh`), so this script
parses neither field itself.

**The direction is unchanged and stays one-way.** A strategy cites feedback; nothing cites a
strategy. That is what makes this option the one that answers the 2026-07-28 removal instead of
reopening it — it adds no relation, so it cannot rebuild the ownership hop, and it needs no write
floor, no hook and no migration. The three rejected alternatives and why are in the script's own
header, beside the rule they lost to.

**It is lossy, and it says so.** Work that answers a strategy without citing the same record is
invisible to hop 1 and hop 2 alike. Every artifact therefore carries the `attribution` that caught
it, and a consumer states what it could not attribute rather than implying the digest is exhaustive.
A quiet strategy is a real answer, not an error: `empty_reason` is `no_feedback_refs` (it cites
nothing), `no_citing_artifacts` (nothing cites it back) or `no_activity_in_window` (attributable work
exists, none of it moved) — never an empty result with no reason, and never a guess.

## Scripts

```bash
# Create — the only writer. Body (the ## Aim prose) arrives on stdin.
printf '%s\n' "<aim prose>" | bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/create.sh \
  "<title>" <target-date YYYY-MM-DD> "<assignee-email>[,<assignee-email>...]" "<schedule prose>" ["<feedback-ref>,..."]

# List — every strategy with its status, target date and assignees, as JSON.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/list.sh [--status active|achieved|abandoned]

# Read — one strategy's fields and body, as JSON.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/read.sh <slug>

# Close — the ONLY writer of an end state.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/close.sh <slug> achieved|abandoned

# Attributed work — the ONE reader of "which work belongs to strategy X in window W".
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/attributed-work.sh <slug> [window] [workaholic-root]
```

Every script is POSIX `#!/bin/sh -eu`, takes an optional trailing `.workaholic` root so it can be
pointed at another tree, and emits one JSON object. `create.sh` refuses an empty aim, an empty
assignee list, a non-`YYYY-MM-DD` target date, and an existing slug — the same presence floor
`validate-strategy.sh` enforces at the write seam, so a refusal is never a surprise later.

## The write-time floor

`hooks/validate-strategy.sh` (PostToolUse `Write|Edit`) holds any file under
`.workaholic/strategies/` to: non-empty `type: Strategy`, a `status` in the closed set, a
`YYYY-MM-DD` `target_date`, non-empty `assignees`, and non-empty `## Aim` and `## Schedule`
sections. Like its siblings it checks **presence, never quality**, and **git-tracked files are
grandfathered** — history is never retro-blocked.
