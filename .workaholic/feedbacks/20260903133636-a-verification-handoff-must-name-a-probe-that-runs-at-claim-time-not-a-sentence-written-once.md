---
type: Feedback
title: A verification handoff must name a probe that runs at claim time, not a sentence written once
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-03T13:36:36+09:00
author: a@qmu.jp
supersedes: 
---

# A verification handoff must name a probe that runs at claim time, not a sentence written once

Source: https://github.com/qmu/workaholic/issues/954

A `verification_handoff` is written once, when the ticket is created, and is never measured
again. A blocker that was true at creation stays true forever, and the work behind it stops
being attempted by every run that reads it.

Measured over one session on 2026-09-03 on a consuming repository: **four pull requests parked,
and three of the four declarations behind them were false when probed.**

- A declaration naming a third-party API key an unattended run "does not hold" — the key was in
  the loop's own checkout, and passing it made the service answer `configured: true`.
- A declaration asking a person to run a secret-put command — the repository's own CI workflow
  already ran exactly that command after every deploy. Nothing was waiting on a person.
- A declaration that the deployed host sat behind an access entrance admitting no machine — that
  package declared two `non_identity` service-token policies and the matching pair was on disk;
  the probe answered `302` bare and `200` with the tokens.
- One declaration was true: a second host's service-token value is genuinely absent.

Each declaration was plausible when written. None was re-checked when the ticket was next picked
up, and every runner that touched them inherited the sentence rather than the state.

## What it cost

- Six tickets on one mission parked — three declaring the blocker, three declaring nothing at
  all and stopping only because they shared a PR-unit with the three that spoke.
- A predecessor mission had closed `achieved` on a proof nobody performed; the check that
  produced now reports eight archived tickets whose declared verification nobody recorded
  discharging, most of them wanting a credential that is present or a host that is reachable.
- One runner spent a full run establishing that it could not claim, and reported the correction
  as an issue rather than as work — rewriting a declaration is a replan, which is outside an
  unattended run's authority. That is the contract working, and it means a false declaration
  cannot be repaired by the runs that keep tripping over it.

## The failure is contagious

The orchestrating session read one top-level access declaration, saw no machine lane, and told
its runners the deployed hosts were unreachable. That file fronted a different site; the other
two entrances were declared in their own packages and were never opened. A per-ticket sentence
became a session-wide premise, then a brief, then a runner's instruction — and it took a runner
probing on its own initiative to break the chain.

A declaration that is prose spreads like prose. A declaration that is a probe cannot.

## What would make it done

- **A `verification_handoff` names a probe, not a sentence** — a command whose exit status
  decides. "Needs a credential an unattended run does not hold" is unfalsifiable; a `curl`
  writing an HTTP status is not.
- **The probe runs when the unit is claimed, not when the ticket is written.** A handoff that
  probes clean is not a handoff: the run performs the verification and the ticket proceeds.
- **A declaration nobody has re-probed is refused**, the same way a discharge nobody recorded is
  refused. The two halves are one idea from opposite ends — one refuses an unperformed proof,
  the other refuses an unmeasured excuse.
- **Where a probe genuinely fails, the failure output is the declaration.** A status code and a
  redirect target say more than any sentence about an entrance, and they go stale visibly.
