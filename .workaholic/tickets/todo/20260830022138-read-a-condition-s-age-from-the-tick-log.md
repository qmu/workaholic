---
created_at: 2026-08-30T02:21:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Read a condition's age from the tick log

## Overview

PROPOSED. Every reading in this repository answers *what* and none answers *how long*.
Add `moderate/scripts/condition-age.sh` — one reader that, given a subject key, answers the
earliest tick that named it, the tick count since, and `readable`. It composes `log-read.sh`
(the log's only parser) and `lib/question-id.sh` (the question id's one derivation) and owns
nothing else. **No new store, no cursor, no field on any artifact, no second walker.**

**Discovery established which log line carries the subject, and it is not the step summary.**
Only `step-retire-claims.sh` names units in its summary; `undrivable-units`, `undelivered-units`
and `stalled-units` carry counts only — and each of those steps' own headers states that
putting per-unit detail or an age in a summary is a **correctness violation**, because
`render-tick-post.sh`'s changed-step diff would then mark the step changed every tick (the
retired `📦 Release Preparation` shape). So the age is read from the **question ledger** the
subject key already writes: `human-checkin-ask-<slug>` and `human-checkin-reasked-<slug>`,
written exactly once per key by `ask-question.sh --record-ask`, never moved afterwards.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — new; the one reader.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — composed, never modified; already
  accepts `--step`, `--step-prefix`, `--contains`, `--since` and returns `{read, count, days,
  entries:[{day,tick,step,status,summary}]}`.
- `plugins/workaholic/skills/moderate/scripts/lib/question-id.sh` — `question_slug`, the one
  derivation the gate, `record-answer.sh` and `question-state.sh` already share.
- `plugins/workaholic/skills/moderate/scripts/lib/jq-guard.sh` — sourced, as every script in
  this skill that embeds a jq program must be.
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` — read for its shape and its
  `asked_tick`; **not** modified, and not composed (it answers a question's *state*, all-time
  and unbounded; this answers an *age*, bounded).

## Implementation Steps

1. Write `condition-age.sh --key <subject-key> [--root <repo-root>]`. Source `lib/jq-guard.sh`
   and `lib/question-id.sh`; derive the slug with `question_slug` so an age read under one id
   cannot disagree with a gate reading another.
2. Read `human-checkin-ask-<slug>` and `human-checkin-reasked-<slug>` through `log-read.sh
   --step`, take the **earliest** entry by tick across both, and emit:
   `{"first_seen": "<tick-id>", "ticks": <n>, "readable": true}`. `ticks` counts the distinct
   ticks in the log at or after `first_seen` (`log-read.sh --since` over the day files),
   never a wall-clock difference — the loop already refuses date arithmetic here.
3. **Absent is not degraded.** A key the ledger has never carried answers `first_seen: null`,
   `ticks: 0`, `readable: true` — *this is the first time anybody is being asked*, an ordinary
   state. Only a log that exists and could not be read answers `readable: false` with a named
   reason and **null** counts, never zeroed ones (`unattributed-work.sh`'s rule).
4. Follow the absent-means-completed convention: emit `readable` only when it is `false`, so a
   completed reading is byte-identical for a consumer not yet taught the term, and every test
   is `readable == false` rather than `readable // true`.
5. Exit 0 on every path, including a refusal. It is a pure read: no write, no network, no
   `plan-units.sh`, no `gh`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given a tick log whose ledger carries a key on an earlier day, the reader answers that day's
  tick as `first_seen` and a `ticks` count greater than 1.
- A key the ledger never carried answers `first_seen: null`, `ticks: 0` and no `readable` field.
- An unreadable log answers `readable: false` with a named reason and **null** counts.
- The reader writes nothing and makes no network call.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — new rows over a throwaway tick-log fixture.
- `sh -n` on the new script, and the suite's `every embedded jq program compiles` row.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes; `log-read.sh`, `question-state.sh` and
  `lib/question-id.sh` are byte-identical.

## Considerations

- **The alternative source, and why it lost.** Keying the walk on the step *summary* via
  `--contains` is what the ask describes, and it is only satisfiable for `retire-claims`. The
  other three steps would have to start naming subjects in their summaries, which their own
  headers forbid as a correctness requirement. The ledger line is subject-keyed already,
  written once, and never moves — so it is the source that needs no step to change.
- **What the reading means, stated so it is not over-read.** It is the age of *the question*,
  which is a lower bound on the age of the condition: a blocker that existed before anybody
  asked reads younger than it is. That is the honest direction (understating an age asks a
  person to look sooner than the truth would), and it must be said in the script's header so a
  later reader does not present it as the condition's own age.
