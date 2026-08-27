---
created_at: 2026-08-27T16:19:54+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Write read-base-checks.sh, the one checks reader

## Overview

<!-- PROPOSED. -->

Nothing in this plugin reads a check run. A grep over `plugins/workaholic/` for
`check-runs`, `/actions/runs`, `workflow_run` and combined-status paths returns
no script — the single approximation is `moderate/scripts/pulls-state.sh`, which
infers `blocked_by: checks` from one **pull request's** `mergeable_state ==
unstable` and is read only by the two reporting steps. So there is no way to ask
what the **base's** checks said about a commit.

This ticket writes that one reader, and nothing else consumes it yet — the
consumers arrive in the tickets that follow. It answers `green` / `red` /
`unanswerable` for a given commit, with the failing check names on a red answer,
and it never dresses a read it could not make as a green one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — degrade by name, never silently

## Key Files

- `plugins/workaholic/skills/drive/scripts/read-base-checks.sh` — **new**, the reader.
  Recommended home: beside `claim-merged.sh`, whose shape this copies. Its header
  records why such a reader must sit in `scripts/` and not `lib/` — the bundle
  build detects a cross-skill closure only by the literal
  `${SCRIPT_DIR}/../../<skill>/scripts/` form, so a reader in `lib/` ships to
  non-Claude agents with its transport missing.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport
  (`slug` / `api` / `available`). Read its header: `gh issue`/`gh pr`/`gh repo` are
  GraphQL-backed and a web session may 403 them mid-run. Invoked, never sourced.
- `plugins/workaholic/skills/drive/scripts/claim-merged.sh` — the three-valued
  precedent to follow: `unanswerable` is a fact about *us*, exit 0 in every case
  including every degradation, executed rather than sourced.
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests; add coverage here.

## Implementation Steps

1. Read `claim-merged.sh` end to end first. It is the shape this reader copies —
   three-valued, exit 0 always, one network read, executed not sourced — and its
   header states the reasons for each of those properties.
2. Write `read-base-checks.sh <commit-sha>` emitting
   `{"ok", "commit", "state": "green|red|unanswerable", "reason", "failing": [{"name", "conclusion"}]}`.
3. Reach GitHub **only** through `gh-rest.sh api`, on a repository-scoped REST
   endpoint (`repos/{owner}/{repo}/commits/{sha}/check-runs` and/or `/status`).
   Never `gh pr`/`gh issue`/`gh repo`; `search/*` is refused to a bound session.
4. Derive `red` from a completed check whose conclusion is a failure, `green` when
   every completed check succeeded (or was neutral/skipped) and none is pending.
5. Make `unanswerable` cover — each **named** in `reason`, never collapsed into
   either other answer: an offline or failed transport, a refused read, a rate
   limit, a response that would not parse, **and a commit with no checks at all**.
   A commit nothing checked is not a green commit.
6. Decide what a still-**running** check means and state it in the header. Recommended:
   `unanswerable` with its own reason — the base has not finished answering yet, and
   calling it green is the failure this reader exists to prevent.
7. Exit 0 in every case, including every degradation. A non-zero exit turns a
   degraded read into a failed one for every caller downstream.
8. Add hermetic coverage to `scripts/test-workflow-scripts.mjs` with the transport
   stubbed on `PATH`: green, red (with names), and each `unanswerable` reason.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `read-base-checks.sh <sha>` answers exactly one of `green` / `red` / `unanswerable`
- a `red` answer names the failing checks; an `unanswerable` answer names its reason
- no check, and any transport failure, answers `unanswerable` — never `green`
- the script exits 0 in every case, including every degradation
- GitHub is reached only through `gather/scripts/gh-rest.sh`

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new cases, transport stubbed, no network
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the
  closure ships (this is what the `scripts/`-not-`lib/` placement buys)

**Gate** — what must pass before approval:

- the hermetic suite passes with no network call
- `verify.mjs` reports the cross-skill closure detected

## Considerations

- **Where the reader lives** is a real fork with a recommendation, not an open
  decision. `drive/scripts/` beside `claim-merged.sh` is recommended: identical
  shape and contract, and `/moderate`'s steps already reach into `drive/scripts/`
  (`list-claims.sh`). `gather/` is the alternative — its own header argues it is the
  home of *common operations* — and would be the right move if a third and fourth
  skill wanted this. Two consumers is not that yet; move it when a third arrives.
- This ticket deliberately ships a reader **nothing calls**. That is the mission's
  order, and it keeps the reader's contract arguable before any consumer depends on it.
- Do not add a fourth value, and do not let `red` mean "probably red". A re-run can
  turn a red check green — which is exactly why the next tickets only report it.

## Final Report

Development completed as planned. `read-base-checks.sh` ships beside `claim-merged.sh`,
answering `green` / `red` / `unanswerable` for one commit over
`repos/{owner}/{repo}/commits/{sha}/check-runs` through `gather/scripts/gh-rest.sh`, exit 0
in every case. Nothing calls it yet — that is the mission's order.

Decisions taken and recorded in the script's header rather than left implicit:

- **Check runs only, never the legacy combined-status endpoint.** Two calls per commit would
  double the cost of the attribution walk that composes this reader. The limit is stated:
  a repository whose CI reports only legacy commit statuses reads `no_checks`, hence
  `unanswerable`, never `green`.
- **A still-running check is `checks_pending`, not green** (the ticket's recommendation), and
  **`red` outranks it** — a completed failure is a reading we did make and a later check
  cannot un-fail it.
- **`neutral` and `skipped` are successes**; `failure`, `timed_out`, `cancelled`,
  `action_required` and `stale` are failures.
- **A truncated page is `checks_truncated`**, not green — a green derived from a partial set
  is exactly the confident wrong answer the reader exists to refuse.

### Discovered Insights

- **Insight**: `set -e` makes `[ cond ] && emit …` a script-ending statement when the
  condition is false, because the compound's own status is 1 and it is not a condition.
  **Context**: every early-exit in this file is written `if [ … ]; then emit …; fi` for that
  reason. `claim-merged.sh` avoids it by structure rather than by rule, so a later reader
  copying its shape into a guard chain would hit this silently — the script would exit 0 with
  no output, which every JSON-parsing caller reads as a crash.

- **Insight**: `verify.mjs`'s cross-skill closure detection keys on the literal
  `${SCRIPT_DIR}/../../<skill>/scripts/` form, which is only writable from a skill's own
  `scripts/` directory.
  **Context**: this is why the reader is not in `lib/` despite reading like a library. The
  build fans the closure out into six consuming skills under `outputs/workflows/`; from
  `lib/` the reference needs a third `../` and ships with its transport missing.
