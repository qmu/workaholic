---
created_at: 2026-09-18T08:07:34+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: [20260918074738-question-reconciliation-retires-the-unreadable-channel-escalation-before-it-is-ever-asked.md]
claim: work-20260918-081459
---

# Retire a check-in question only on a positive reading

## Overview

`/moderate`'s question reconciliation retires a check-in question that was never asked and
whose premise still holds, and it does so structurally — every tick, for a whole class of
question. `reconcile-questions.sh` treats `question-liveness.sh`'s `settled` — *the owning
step ran and did not name this key* — as proof that the premise resolved, writing
`evidence: {proved: true, reason: "owning_step_resolved_premise"}`. That is an **absence of a
reading presented as a proof**, which is the one shape this repository's own doctrine forbids
(`drive/reference/claims.md`, *Proofs and judgements*).

Restrict the retirement's evidence to a **positive** reading: a question is retired only when
the owning step's own row states that the subject is resolved. Everything else — a step that
ran and said nothing about the key, a degraded step, an unreadable run — leaves the row alone
and is reported by name.

The measured victim is the one route by which *this channel cannot be read* reaches a person.
Because the escalation key is composed by the **agent** after the step runs,
`step-unanswered-asks.sh` can never name it as an exact string, so liveness reads `settled`
whatever the channel's real state and the key is retired on the first tick that reconciles.
`ask-question.sh` then answers `premise_resolved` with `hold: false` — the one refusal that
does not hold — so the question is extinguished rather than deferred, permanently:
`question-registry.sh`'s `register` merges only `step`/`coordinate`/`subject` over a retired
row, and its `asked` event is a no-op on one.

Measured on tick `20260917-223112` and confirmed in this checkout's live registry today:

```
question-state.sh --key inbound-channel-unreadable:dev-workaholic
  → {"state": "retired", "asked_tick": "", "coordinate_reason": "never_asked"}

.git/workaholic/runtime/v1/instances/questions
  → {"key": "inbound-channel-unreadable:dev-workaholic", "state": "retired",
     "evidence": {"proved": true, "step": "unanswered-asks",
                  "reason": "owning_step_resolved_premise"}}
```

`never_asked` and `retired` in one reading is the defect stated in two words: no ledger line
was ever spent on the question, and it can never be asked again. In the same tick the premise
was measurably unresolved — `describe-qfs.sh` verified channel `C0BLL9J7FMY` offering only
`read_channel_delta` / `read_thread` / `search_exact`, `resolve-target.sh` refused the
read-only binding `ambiguous_identity`, and the connector read was denied. The channel could
not be read; the question saying so was gone.

**The fork is closed, not deferred** (see *Considerations* for the two rejected repairs). Do
not write an `## Open Decisions` section for it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` scripts, one reader per question (all code work)
- `workaholic:implementation` / `policies/type-driven-design.md` — the resolution word is a closed, named set; an unreadable reading is its own value and never rounds into a verdict
- `workaholic:implementation` / `policies/observability.md` — a reading the loop could not make is reported by name, never rendered as a healthy one
- `workaholic:implementation` / `policies/test.md` — the upgrade path over already-stored rows is exercised against a legacy fixture, not a fresh registry

## Key Files

- `plugins/workaholic/skills/moderate/scripts/reconcile-questions.sh` (lines 32-41) — the retirement loop; it turns `settled` into `evidence: {proved: true, reason: "owning_step_resolved_premise"}`, hard-coded.
- `plugins/workaholic/skills/moderate/scripts/question-liveness.sh` (line 95) — `any((.needs_agent // []) | .. | strings; . == $k)`, the exact-string match whose failure is read as `settled`. Its header already states that `unknown` is load-bearing; `settled` needs the same discipline.
- `plugins/workaholic/skills/moderate/scripts/question-registry.sh` (lines 31-34) — the `retire` event, which demands `evidence.proved == true` and is satisfied by a flag the caller manufactures; `register`/`asked` are no-ops over a retired row, which is what makes the retirement permanent.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` (lines 303-313) — `retired` → `{"ask": false, "reason": "premise_resolved", "hold": false}`.
- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` (line 177) — the `escalation` sentence that carries `inbound-channel-unreadable:<channel>` as a substring and never as a candidate.
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` (lines 75-88) — reads the registry before the log; the one reader a consumer sees.
- `plugins/workaholic/skills/moderate/reference/question-lifecycle.md` (item 2) — the prose home of the rule being changed.
- `plugins/workaholic/skills/moderate/reference/workflow.md` (lines 723-761, and the `unanswered-asks` row at 2651) — the liveness contract and the classification that names this question as the only route to a person.
- `plugins/workaholic/commands/moderate.md` (line 35) — the command body that instructs the reconcile call before questions are offered.
- `scripts/tests/agentic-loop/repair-contracts.test.mjs` (lines 46-63) — the contract test that currently **asserts the defect**: `held:two`, registered and never raised, is expected to reach `retired`.
- `scripts/test-workflow-scripts.mjs` (lines 3185-3212) — the row pinning the escalation key and the asked-once gate over it.

## Related History

The liveness reader was built to tell *asked and settled* from *asked and still blocking*, and
its own header already rules that an absence must not be read as an answer — `unknown` "never
collapses into either other answer". That discipline was applied to a step that could not
report and not to a step that reports without ever naming the key, which is the gap this
ticket closes. The durable registry that makes a retirement permanent arrived later and
carried the same assumption through.

- [20260822155250-read-whether-an-asked-question-s-subject-is-still-live.md](.workaholic/tickets/archive/work-20260823-141725/20260822155250-read-whether-an-asked-question-s-subject-is-still-live.md) — introduced `question-liveness.sh`, its three words, and the exact-string match (direct predecessor)
- Commit `895538f06` (PR #1129), *Preserve question state and allocate cohesive work* — added `question-registry.sh` and `reconcile-questions.sh`, including the hard-coded retirement evidence

## Implementation Steps

1. **Reproduce and localize before changing anything.** In a throwaway repository, register a
   key, run `reconcile-questions.sh` with a run report whose owning step is `ok` and whose
   `needs_agent` mentions the key only inside a longer string, and record that the row reaches
   `state: retired` with `reason: "owning_step_resolved_premise"` and that `ask-question.sh`
   then answers `premise_resolved` / `hold: false`. Confirm the same two facts against this
   checkout's live registry (above) and keep both readings as the regression's starting point.

2. **Add the positive reading to `question-liveness.sh` as an additive field**, beside
   `liveness` and never in place of it: `resolution` from the closed set
   `proved | unwitnessed | unknown`.
   - `proved` — the step's row has status `ok`/`filed` **and** names this key as an exact
     string in its own statement of what it resolved (a `resolved_keys` array on the step row,
     matched exactly as `needs_agent` is matched today).
   - `unwitnessed` — the step ran `ok`/`filed`, does not raise the key and does not name it
     resolved. This is the case the current code calls proof.
   - `unknown` — every case `liveness` already answers `unknown` for: step absent, degraded,
     blocked, run unreadable, no key, no step.
   **Do not touch the three `liveness` words and do not narrow the exact-string match.**
   `settled` has two other consumers — the bounded re-ask and the `✅ 解消を確認` confirmation
   (`reference/workflow.md`, lines 745-779) — whose behaviour must stay byte-identical; a key
   genuinely absent from `needs_agent` cannot be recovered by any matching rule, so narrowing
   the match would move the defect rather than remove it.

3. **Make `reconcile-questions.sh` retire only on `resolution == "proved"`.** The evidence it
   writes then describes a reading that was actually made:
   `{proved: true, step: <step>, reason: "owning_step_reported_resolution"}` — a **new** word,
   chosen so the old one stays unwritten from this change onward, which is what makes step 5
   self-terminating. Every other resolution leaves the row untouched and appends a result row
   naming what was not done and why (`{"status": "not_retired", "reason": "<resolution>",
   "key": "<key>"}`), so a run report states the outcome instead of implying it by silence.

4. **Leave `question-registry.sh`'s `retire` guard exactly as it is.** `evidence.proved != true
   → error` is correct and stays; what changes is that no caller can manufacture that flag out
   of an absence. Add no second retirement path.

5. **Reinstate the residue this defect already wrote, in the same seam, before the retirement
   loop.** A registry row with `state == "retired"` **and**
   `evidence.reason == "owning_step_resolved_premise"` is returned to `state: "candidate"`
   with its evidence dropped, through one new bounded `reinstate` event on
   `question-registry.sh`. Bounds, each refusing with nothing written:
   - an `answered` row is never touched (a person's own words outrank this repair);
   - any other `evidence.reason`, and a row with no evidence, is refused by name;
   - it restores `candidate` and **never** `asked` — the question was never asked, and
     spending the asked-once ledger line on a question nobody heard is the failure that gate
     exists to prevent;
   - it is idempotent: after one run no row carries the old word, so a second run is a no-op.
   Why it runs here rather than as an operator's one-shot: the registry is per-clone runtime
   state under `.git/workaholic/runtime/v1/instances/questions`, uncommitted and unreachable
   by any migration a pull request could carry, so every checkout must repair its own copy
   unattended.

6. **Update the prose in the same change** (an outdated document is a defect —
   `CLAUDE.md`, *Update the docs in the same change*):
   `reference/question-lifecycle.md` item 2, whose current wording ("retires a candidate only
   when its owning step ran successfully without raising its exact key") **states the defect as
   the rule**; the liveness section of `reference/workflow.md` (lines 723-761) and its
   `unanswered-asks` row (line 2651); and the reconcile paragraph of `commands/moderate.md`
   (line 35).

7. **Extend the suite**, including the legacy row (see *Quality Gate*). The existing assertion
   at `repair-contracts.test.mjs:55` — `held:two` reaching `retired` — encodes the defect and
   is **updated to the new rule, not deleted**: the same fixture must now leave the row
   `candidate` and report `not_retired: unwitnessed`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A key whose owning step reported `ok` and whose `needs_agent` carries it only as a
  **substring** of a longer string is **not** retired; the row keeps the state it had, and the
  reconcile result names `not_retired` with `unwitnessed`.
- A key whose owning step reported `ok` and never mentions it at all is **not** retired, same
  reading, same result row.
- A key the owning step positively names as resolved **is** retired, and the written evidence
  carries `reason: "owning_step_reported_resolution"`; no code path writes
  `owning_step_resolved_premise` any more.
- A degraded, skipped, missing or unparseable owning step retires nothing, as today.
- `question-liveness.sh`'s `liveness` field is unchanged for every input the suite already
  exercises — three words, same exact-string match — and `resolution` is additive; the bounded
  re-ask and the `✅ 解消を確認` confirmation behave identically.
- **Legacy upgrade** (the one that proves the fix on the case it was measured on): a registry
  seeded with the row this checkout actually holds —
  `{"inbound-channel-unreadable:dev-workaholic": {"state": "retired", "evidence": {"proved":
  true, "step": "unanswered-asks", "reason": "owning_step_resolved_premise"}}}` — is reinstated
  to `candidate` by one `reconcile-questions.sh` run; a second run changes the record not at
  all; an `answered` row and a row retired under any other reason come out byte-identical.
- After that reinstatement, `question-state.sh --key inbound-channel-unreadable:dev-workaholic`
  no longer answers `retired`, and `ask-question.sh` for that key answers `ask: true` on the
  next tick whose channel reading is still `channel_unreadable` (gates permitting), restoring
  the route `reference/workflow.md`'s `unanswered-asks` row names as the only one this reading
  has.
- `repair-contracts.test.mjs`'s `held:two` expectation is updated to the new rule rather than
  removed, and its `held:one` (verified answer → `answered`) and `held:three` (unproved
  association → `candidate`) assertions are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/repair-contracts.test.mjs` — green, with the updated
  `held:two` row, a new row for the substring case keyed on the real escalation shape, and a
  new row for a `proved` retirement.
- `node scripts/test-workflow-scripts.mjs` — green, including the existing
  `inbound-channel-unreadable:source-repo` rows (lines 3185-3212), which must not move.
- **The legacy fixture is a seeded registry record, written before the new code runs**, at
  `.git/workaholic/runtime/v1/instances/questions` inside a throwaway repository, holding the
  retired row above. **A registry created empty and then driven by the new code is not
  evidence for this upgrade** (`plugins/workaholic/rules/general.md`, *A tightened constraint
  over persisted data is verified against legacy rows*): `question-state.sh` answers
  `never_asked` for every key a fresh registry has never seen, so a fresh-registry test proves
  nothing about the already-retired row — which is precisely the row that is holding a real
  question closed today. The fixture must also hold one `answered` row and one row retired
  under a different reason, so the reinstatement's two refusals are exercised rather than
  assumed.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `outputs/`
  regenerated with no diff (the `Outputs Freshness` workflow fails the merge otherwise).
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`.

**Gate** — what must pass before approval:

- Both suites green; `outputs/` clean; layout conforming.
- The four prose surfaces in step 6 updated in the same commit as the code.
- Every new script path is POSIX `sh` (`#!/bin/sh -eu`), and any embedded jq program compiles
  under the suite's `every embedded jq program compiles` row.
- No new store, no new script beyond the additive field and the one bounded registry event, and
  no second reader of a question's liveness.
- `Decided: the resolution word rides question-liveness.sh rather than a second script — it is
  the one reader of a step's row for a key, and a second reader is how two answers about one
  fact start disagreeing (developer may override at /drive).`
- `Decided: hermetic suites only — the change is script-internal with no runtime surface, and
  the one live reading it needs (this checkout's retired row) is reproduced as a fixture; a
  live tick would prove nothing the fixture does not (developer may override at /drive).`
- `Decided: merge_policy left empty, which reads review — this changes what the loop is
  allowed to consider resolved, and the conservative default is the right one for that
  (developer may override at /drive).`

## Considerations

- **The legacy row is un-retired, and that is a consequence of the design rather than a
  question for a later session.** The row was written by the defect; its evidence is a claim
  about a reading nobody made; and the channel it names is measurably still unreadable. Leaving
  it retired would leave the only route to a person closed permanently in exactly the case the
  fix was measured on, making the fix cosmetic there. The cost is bounded and stated: a row
  reinstated whose premise *did* genuinely resolve simply sits as a `candidate` — nothing asks
  a candidate spontaneously, since a question is composed only when a step raises it again, so
  the worst case is a dormant row, against a permanently extinguished question on the other
  side (`plugins/workaholic/skills/moderate/scripts/question-registry.sh`).
- **Rejected: narrow the liveness match.** The key genuinely is not in `needs_agent` — it is
  composed by the agent after the step ran — so no matching rule recovers it. This would move
  the defect to whichever key the next agent-composed question uses
  (`plugins/workaholic/skills/moderate/scripts/question-liveness.sh` line 95).
- **Rejected: exclude agent-originated escalation keys from reconciliation.** It leaves the
  `proved: true`-on-an-absence write standing for every other key, so the same defect stays
  reachable by a different question — and it needs a new classification of which keys are
  "agent-originated", which nothing in the registry records
  (`plugins/workaholic/skills/moderate/scripts/reconcile-questions.sh` lines 36-40).
- **`step-unanswered-asks.sh` is not modified.** Making it enumerate the escalation key as a
  candidate would have the step claim a channel reading it explicitly does not make — its own
  header rules that the channel read is the agent's half — and it would fire the question on
  every tick regardless of the channel's state
  (`plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` lines 18-23).
- **No step is required to emit `resolved_keys` by this ticket.** Until one does, the
  reconciliation retires nothing, which is the honest side of the trade: an open question is
  visible and re-askable, an extinguished one is neither. Say so plainly in the prose of step 6
  rather than leaving a reader to infer that retirement still happens
  (`plugins/workaholic/skills/moderate/reference/question-lifecycle.md`).
- **Adjacent, deliberately out of scope**: the queued ticket
  `20260917174439-prove-the-declared-slack-transport-before-retiring-delivery-incidents.md`
  works the *other* half of the same incident — proving the declared Slack route before
  delivery incidents are retired. This ticket touches no transport script and declares no
  verification handoff; it repairs the question mechanism, which needs no credential, device
  or account to verify.
- `question-state.sh`'s header documents four states (`never_asked|asked|answered|unreadable`)
  while line 86 emits a fifth, `retired`. Correct the header comment while in the file; it is a
  documentation slip, not part of this repair
  (`plugins/workaholic/skills/moderate/scripts/question-state.sh` lines 38-42, 86).
