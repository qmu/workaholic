---
created_at: 2026-08-27T20:21:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Name claimed_awaiting_verification in the run report

## Overview

PROPOSED. The driving run's report names the survey's `backlog_all_excluded` reading with a
count per exclusion reason, so *the queue is empty* and *the queue is full and I can offer none
of it* never render alike. `claimed_undelivered` is called out by name there as the one reason
that means the loop finished a unit and could not deliver it. `claimed_awaiting_verification`
gets no such sentence, so a queue held entirely by a declared handoff reads to an operator like
the protocol working quietly — when it is a person's business.

**Discovery finding, and it changes what this ticket is.** The per-reason counts in
`plan-units.sh` are already **derived from whatever `excluded[]` carries** (see the header note
at ~line 724), so `claimed_awaiting_verification` is already counted, by construction, with no
edit. What is missing is the **report contract**: the sentence in `drive/SKILL.md` §7 and its
copy in `CLAUDE.md` that tells the operator what that count means. So this ticket writes prose
and must **not** add a hand-maintained list of reasons — that genericity is stated as the
property to preserve, and a second vocabulary is exactly what would drift.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a reading a reader cannot interpret is not a reading

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the generic count derivation
  (~715–752) and the `claimed_awaiting_verification` mapping (~398). **Read the header before
  touching it**; the expected outcome here is that no code change is needed.
- `plugins/workaholic/skills/drive/SKILL.md` — §7's report contract, where
  `claimed_undelivered` is named; the sentence this ticket writes sits beside it.
- `CLAUDE.md` — the `/implement` row carries the same statement and must move with it.

## Implementation Steps

1. Confirm the discovery finding first, before writing anything: run `plan-units.sh` over a
   fixture whose whole backlog is excluded `claimed_awaiting_verification` and read the emitted
   `backlog_all_excluded.reasons`. If the count is already present, no script changes.
2. If — and only if — the count is absent, fix it **inside the generic derivation**, never by
   enumerating reasons.
3. Write the §7 sentence: a queue held by a declared handoff is a **person's** business, not
   the protocol working quietly, and the repair is the declared verification. Say it in one
   clause beside `claimed_undelivered`'s, not as a new paragraph.
4. State that it **moves no token**, and why: a unit waiting on a declared human verification
   is the gate working, so `ok` stays reachable exactly as it is today. This is the existing
   ruling; the ticket records it where the count is read, it does not change it.
5. Update `CLAUDE.md`'s `/implement` row in the same commit — an outdated document is a defect
   by this repository's own rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `backlog_all_excluded.reasons` carries `claimed_awaiting_verification` with its count when
  the queue is held by declared handoffs
- No hand-maintained list of exclusion reasons exists anywhere in `plan-units.sh`
- §7 and `CLAUDE.md` both say what the count means and that it moves no token
- `ok` remains reachable over a queue held only by declared handoffs

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `plan-units.sh` over a fixture whose backlog is entirely `claimed_awaiting_verification`

**Gate** — what must pass before approval:

- The hermetic suite passes and the token behaviour is provably unchanged

## Considerations

- The ask describes this as giving the reason "its own row in the per-reason counts". Read
  literally that suggests a code change; the mechanism already provides the row. Deliver what
  the ask is **for** — an operator who can read the count — and report that the counting half
  was already true rather than adding an edit to make the sentence come out right.
- Resist making this a token change. That is a separate ruling with its own recorded reasoning,
  and reversing it here would put `ok` out of reach for as long as a person takes.
