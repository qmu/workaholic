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
command, hook, or routine creates one on its own.

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
