---
created_at: 2026-08-29T19:21:36+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Read back whether an operator-facing pull request was acted on

## Overview

PROPOSED. The loop opens pull requests **for a person** and nothing reads them back.
This is the reader: one script, per pull request, answering `merged` / `closed` /
`open:<age>` / `unreadable` — the shape `act-effect.sh` already uses for the loop's own
two acts on a proof, applied to the act the loop takes **on the operator's behalf**.

It is a **pure read**: no merge, no close, no gate, no hold, no store, no cursor and no
field on any artifact. Every value is a **judgement** — a pull request can be merged or
reopened between two reads, which is the one property a proof must not have.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a degraded read is named, never rendered as an answer
- `workaholic:operation` / `policies/runtime-resilience.md` — an unreadable transport degrades rather than stops

## Key Files

- `plugins/workaholic/skills/drive/scripts/act-effect.sh` — the shape to copy (`taken` /
  `refused:<word>` / `pending` / `unavailable` / `unreadable`), and the rule it states:
  own the assembly, own no act's vocabulary.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport
  (`rules/shell.md`); `gh pr …` is GraphQL-backed and a web session may 403 mid-run.
- `plugins/workaholic/skills/moderate/scripts/list-open-rulings.sh` — an existing
  per-pull REST read whose refusal shape (`ok: false` + `reason`, exit 0) this mirrors.
- `plugins/workaholic/skills/propose/scripts/list-open-proposals.sh` — the other one.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the words get classified
  (ticket 6 owns that half).

## Implementation Steps

1. Write `moderate/scripts/publication-effect.sh <pull-request-number>` (name at the
   implementer's discretion; one home, one reader). It reads that pull request once
   through `gh-rest.sh api repos/{owner}/{repo}/pulls/<N>` and answers
   `{"ok", "number", "url", "effect", "age_hours", "reason"}`, exit 0 in every case.
2. `effect` is `merged` (`merged_at` set), `closed` (state closed, not merged),
   `open:<age>` (state open; `age_hours` from `created_at`), or `unreadable` with the
   transport's own reason (`gh_unavailable` / `read_failed` / `not_found`) and a **null**
   age — never a zero, which reads as *just opened*.
3. Take the candidate set from ticket 2's derivation rather than re-deriving membership
   here: this script answers *what happened to this pull request*, never *whose it is*.
4. Bound the reads (`--limit`, default matching `pulls-state.sh`'s 10) and **report the
   cap** so a busy repository is never silently half-read.
5. Add hermetic coverage to `scripts/test-workflow-scripts.mjs` over a stubbed transport:
   the four values, the null age on `unreadable`, exit 0 on every path.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader answers exactly `merged` / `closed` / `open:<age>` / `unreadable` and exits 0
  on every path, including an unreachable transport.
- `unreadable` carries a named reason and a **null** age, never a zero.
- The script writes nothing, creates nothing, and reaches no merge, close or gate call.
- Every GitHub read goes through `gather/scripts/gh-rest.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `grep -n 'gh \(pr\|issue\|repo\) ' plugins/workaholic/skills/moderate/scripts/` returns
  no non-comment hit.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` and `node scripts/build-plugins/verify.mjs` pass.

## Considerations

- The obvious shortcut is to answer from the list endpoint. It does not carry `merged_at`
  reliably for a closed-unmerged pull request, which is exactly the distinction that makes
  `closed` a different answer from `merged`.
- Ticket 2's derivation and this reader are deliberately two scripts: *which pull requests
  are the operator's* and *what happened to one* are different questions, and one script
  answering both is how two readings of one fact start to disagree.

## Final Report

**Implemented.** `branching/scripts/publication-effect.sh <number>` answers
`{ok, number, url, effect, age_hours, reason}`, exit 0 on every path.

- **`effect`** is `merged` (`merged_at` set) / `closed` (state closed, not merged) /
  `open:<age>` (hours from `created_at`) / `unreadable` with the transport's own reason
  (`gh_unavailable`, `read_failed`, `not_found`, `jq_unavailable`, `no_pull_number`).
- **`unreadable` carries a NULL age**, never a zero — a zero reads as *just opened*, the most
  urgent thing this vocabulary can say, for a read we could not make. A degraded **age** alone
  (the clock arithmetic failing on a readable open pull request) reports `open:unknown` with a
  null age and `age_unreadable`, so the state stays honest.
- **The single-pull endpoint**, per the ticket's Consideration: the list endpoint does not carry
  `merged_at` reliably for a closed-unmerged pull request, which is exactly the distinction that
  makes `closed` a different answer from `merged`.
- **Membership is not answered here** — that is the derivation's question, and the candidate set
  is passed in.

**All four values verified against live GitHub**, not only against the stub: #694 → `open:18`
(the mission's own measured 18 hours), #732/#700 → `merged`, #612 → `closed`, #999999 →
`unreadable`/`not_found`, `abc` → `unreadable`/`no_pull_number`.

**Bound (ticket step 4):** `--limit`, default 10, matching `pulls-state.sh`, with the cap
reported on the derivation's side so a busy repository is never silently half-read.

**Home:** `branching/scripts/`, not `moderate/scripts/` — see the derivation ticket's Final
Report for the measured closure reason.

**Gate:** `node scripts/test-workflow-scripts.mjs` and `node scripts/build-plugins/verify.mjs`
pass. Every GitHub read goes through `gather/scripts/gh-rest.sh`; no `gh pr|issue|repo` call
exists in either new script.
