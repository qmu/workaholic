---
created_at: 2026-08-04T20:12:30+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-routine-notifications-one-semantic-story
merge_policy:
---

# Truth up the drive template's resumption model

## Overview

FB `20260804143009` (a work request with a "How to Fix" — the measured capture
miss): the [Drive] routine template's §5 still opens with "this routine cannot
resume its own unfinished work … a claimed unit is excluded from every later
survey", which has been false since resumption shipped on 2026-08-01
(`claim.sh resume`, `plan-units.sh`'s `resumable[]` offer). Worse, §1's live
unit-limit rule cites that stale sentence as its reason, so a retired premise is
load-bearing for current scheduling behavior. Nothing is lost today (the error
is in the conservative direction), but the routine's stated model of the system
no longer matches the system.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / documentation policies — a document that states the system's model is a defect when the system moves and it does not

## Key Files

- `plugins/workaholic/skills/workaholify/routines/drive.md` — §5 (the stale claim) and §1 (the rule that cites it)
- `plugins/workaholic/skills/drive/SKILL.md` — the shipped resumption model §5 must now restate accurately (resumable/heartbeat/identity), referenced not copied

## Implementation Steps

1. Rewrite §5 to the shipped truth: an unfinished unit is pushed and left
   claimed; the next tick's survey offers it back as `resumable[]` once the
   heartbeat lapses (same identity only), and `claim.sh resume` re-creates the
   worktree at the branch tip — a human is not required.
2. Re-derive §1's unit-limit reasoning from what is actually true now: a
   half-driven unit still costs a takeover round trip (heartbeat lapse wait +
   resume), so a limit can survive — but resting on that cost, not on the
   retired impossibility. If the re-derivation dissolves the rule, dissolve it
   and say why.
3. Cross-check no other template or workaholify doc repeats the retired
   sentence (`grep -rn "cannot resume"`).
4. Note in the PR body that the live [Drive] routine carries the same stale
   text and needs a /workaholify refresh once this template merges (the
   developer's confirmed act).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- §5 describes the shipped resumption behavior accurately (verifiable against drive/SKILL.md's Claims section)
- §1's rule no longer cites the retired gap; its justification stands or the rule is removed
- No other shipped document repeats the retired premise

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "cannot resume" plugins/ docs/` returns nothing stale
- Read-through of §1/§5 against `drive/SKILL.md`

**Gate** — what must pass before approval:

- Docs consistent in the same change

## Considerations

- Template-only change; the resumption code is already shipped and untouched.
- The compare-routines drift report will show the live routine drifted after
  merge — the desired signal, not a defect.
