---
created_at: 2026-09-09T13:01:38+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-a-native-tick-from-reconciled-evidence-not-from-a-worker-s-word
merge_policy:
verification_handoff: 
---

# Name which capability refused a delivery, and use an authorized route

## Overview

PROPOSED. The 2026-09-08 retrospective reports two runners stopping on
`merge_refused: session_type_cannot_merge`, after which an operator-authorized
`gh pr merge --squash` succeeded on the same pull request. One refused REST call became a
statement about the whole session, and no route that was actually available was tried.

`rules/shell.md` already carries the one qualification — a REST merge answered
`403 "Merging pull requests is not permitted for this session type"` may be retried **once**
through `mcp__github__merge_pull_request` — and `commands/implement.md` carries that retry. What
is missing is (a) whether the native `/work` path reaches that retry at all, and (b) a refusal
vocabulary that separates *no tooling here*, *the API errored* and *this session is not permitted*,
so the report names the concrete blocker rather than generalizing one call.

The ask is explicit that alternate command spellings and parent delegation must not become a way
around a permission refusal: an actual authorization denial stays respected and clearly identified.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-pull.sh` — the one REST merge seam; where the
  refusal word is produced today.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport; the place a
  transport/auth/permission distinction can be made once.
- `plugins/workaholic/commands/implement.md` — carries the `session_type_cannot_merge` connector
  retry for the agent-level merge.
- `plugins/workaholic/skills/drive/reference/failure-contract.md` — where a delivery outcome word
  is defined and reported.
- `plugins/workaholic/rules/shell.md` — *GitHub over REST only* and its one qualification.
- `plugins/workaholic/skills/work/reference/native-loop.md` — whether the native path reaches the
  same delivery seam.

## Implementation Steps

1. **Reproduce and localize before designing.** Drive a merge through
   `merge-pull.sh` under a session that answers `403 session type` and capture the exact
   `merge_reason` each layer emits; then walk the native `/work` delivery path and record whether
   it reaches `commands/implement.md`'s connector retry at all. Record what was observed, not what
   the retrospective inferred.
2. Enumerate the delivery refusals reachable today and classify each into one of three: **no
   capability here** (the tool or route is absent), **the call errored** (transport, 5xx, parse),
   and **this identity is not permitted** (an authorization denial). Keep the existing words; add
   the classification beside them rather than renaming anything.
3. Make the reported blocker name the classification and the route it was refused on, so one
   refused call is never reported as the session having no delivery.
4. Where an authorized supported route exists and was not tried, try it — once, through the seam
   that already exists — and report both outcomes by name.
5. Assert that an authorization denial is still a refusal: no alternate spelling, no parent
   delegation and no second account is used to get past it.
6. Extend `scripts/test-workflow-scripts.mjs` with a hermetic row per classification.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A refused delivery reports which of the three classes refused it, and on which route.
- One refused call is never reported as the whole session lacking delivery.
- An authorized supported route that exists is attempted once, and both outcomes are named.
- An explicit authorization denial remains a refusal; nothing routes around it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — new hermetic rows for the three classes.
- A recorded native `/work` delivery attempt showing the classification in its report.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- The retrospective's claim that the native path never reaches the retry is **reported, not
  established** — step 1 exists to settle it, and the ticket may end by confirming the path is
  correct and only the reporting was wrong. That is a valid outcome.
- Do not widen `rules/shell.md`'s one qualification. The connector retry stays a second attempt
  behind REST for one refusal, never a general fallback.
