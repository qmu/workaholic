---
created_at: 2026-08-31T04:23:12+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
merge_policy:
verification_handoff: 
---

# Drill the directed notification offline

## Overview

PROPOSED. Every mechanism in this loop that matters is proved by a drill with a
breaker row, run hermetically by `Loop Drills` on every push, and read back by
`/moderate`'s `drill-health` step. A notification path is exactly the kind that
fails silently — the defect this mission repairs went unnoticed until an operator
asked a session directly, twice — so the repair needs a proof that fails when
somebody removes it.

Drill the whole path with no network: transport → rule → call site → template.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher and the new `verify-*` arm.
- `docs/loop-drill-runbook.md` §9 — the drill register, whose row classifies the
  new drill's `Kind`, `Breaker` and `Mission`.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's
  one reader; it must classify the new row or `verify-all` reports
  `skipped:unclassified`.
- `scripts/test-workflow-scripts.mjs` — fails on a drill the register does not
  classify.

## Implementation Steps

1. Add a `verify-*` arm that stands up a stub Slack endpoint through
   `WORKAHOLIC_SLACK_API_URL` and asserts, with **no network and no real token**:
   the payload carries `thread_ts` when the flag is passed and not when it is
   not; a directed post whose addressee is the posting identity is carried by the
   bot; every other shape is carried by the connector; and with no token the
   directed post falls back and is **reported**, never dropped.
2. Assert the gate did not move: the question's key, the caps and the holds are
   byte-identical across a run with a bot token and one without.
3. Add a **breaker** row written against the **behaviour** rather than a return
   shape — wire the carrier selection at the transport's *availability* instead
   of the addressee, so the pre-repair rule is restored — and prove the drill
   goes red on it.
4. Register the drill in `docs/loop-drill-runbook.md` §9 with `Kind: hermetic`,
   `Breaker: yes` and this mission's slug, so `verify-all` runs it and
   `drill-health` can name it.
5. Confirm the whole hermetic set still passes.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The drill exercises transport, rule, call site and template with no network,
  no `gh`, no credential and no Slack post.
- Its breaker row is proved able to fail.
- The register classifies it, and `verify-all` runs rather than skips it.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh <the new verb>`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill passes on the repaired tree, fails on the deliberately broken one,
  and `verify-all` reports it as a run rather than a skip.

## Considerations

- The drill can prove which surface the run *chose* and what payload it built;
  it cannot prove a human's phone buzzed. That half is the mission's handoff
  ticket, and the two are deliberately separate so the mechanical proof is not
  held hostage to a credential.

## Final Report

**Outcome:** implemented.

**`verify-directed-notification`**, 13 load-bearing rows and **two** breakers, hermetic: `curl`
is stubbed on `PATH` for the transport rows, so the assertion is on the **bytes that would have
gone out** — no network, no `gh`, no credential, no Slack post, and the checkout byte-identical
afterwards (its own row). A stub rather than a listener: no socket and no port to race.

**What it walks.** *Transport* — a coordinate carried verbatim into a resolved thread; an
unflagged payload byte-identical to the pre-repair builder; a malformed coordinate refused
`bad_thread_ts` with **nothing posted**; a missing token reported as a `no_token` no-op at exit 0.
*Rule* — the directed set is enumerated, names both shapes, and makes extending it a deliberate
edit. *Call site* — `moderate/reference/workflow.md` and `drive/reference/routing.md` state the
carrier, the addressee and what an unresolved address does. *Template* — each names both its
shape and its carrier.

**Two judgements worth reading.** The unflagged payload is compared against the **pre-repair
builder re-run inside the drill**, never against a literal: the real builder escapes non-ASCII,
and a hand-typed expectation would assert the drill's idea of the payload rather than the bytes
the script used to send — caught by the first run, which failed on exactly that. And the rule and
the call sites are **read rather than run** because the carrier selection is prose an agent
executes, not a function: what is checkable is that the transport *can* do what the rule asks and
that every document states it the same way, and the header says so rather than implying the drill
proves more.

**The gate's immunity is proved by execution.** `ask-question.sh` is run twice over one fixture,
with a bot token and without, and its answers must be **byte-identical** — plus the structural
half, that it names no transport at all, so a future gate cannot start branching on a token while
still answering identically today.

**Both breakers are written against the behaviour, and both are needed.** One restores the
pre-repair **transport** (`--thread-ts` removed): confirmed by hand that the broken copy still
posts successfully (`notified: true`, with `--thread-ts` swallowed as the positional text — the
pre-repair behaviour exactly), so the row catches a **regression rather than a crash**. One
restores the pre-repair **rule** (the enumerated set deleted), so availability alone decides the
carrier. Either alone would leave the other half unproved.

**Registered and run rather than skipped.** `docs/loop-drill-runbook.md` §9 carries the row
(`hermetic` / `yes` / this mission's slug) and §5s documents it with a per-row failure→file blame
table; `drill-register.sh drill verify-directed-notification` resolves it with
`mission_resolved: true`; `verify-all --list --kind hermetic` enumerates **28** drills including
this one, so CI's matrix gains a leg named after it and `/moderate`'s `drill-health` can name it.

**Gate.** `sh scripts/e2e/loop-drill.sh verify-directed-notification` → `verdict: pass`, 13
load-bearing, 0 failed, 2 breakers. `sh scripts/e2e/loop-drill.sh verify-all --kind hermetic` →
36 drills, **0 failed**, 25 proved. `node scripts/test-workflow-scripts.mjs` → 5442 passed, 0
failed (the row that fails on a drill the register does not classify is green).

**Stated limit.** The drill proves which surface the run *chose* and what payload it built; it
cannot prove a human's phone buzzed. That half is this mission's handoff ticket, deliberately
separate so the mechanical proof is not held hostage to a credential.
