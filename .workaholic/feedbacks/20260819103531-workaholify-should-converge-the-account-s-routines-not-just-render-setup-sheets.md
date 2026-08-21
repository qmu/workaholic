---
type: Feedback
title: /workaholify should converge the account's routines, not just render setup sheets
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-19T10:35:31+00:00
author: a@qmu.jp
supersedes: 
---

# /workaholify should converge the account's routines, not just render setup sheets

Source: https://github.com/qmu/workaholic/issues/532

## Summary

`/workaholify` should **converge the account's routines itself**, not merely render copy-paste setup sheets and delegate to `/setup-dev-routines`, `/setup-repo-routines` and `/setup-user-routines`.

## What was measured (2026-08-19, this repository, interactive session)

A `/workaholify` run reported the routines as something the command could not answer and rendered the sheets. The account's actual state at that moment:

- **2 routines existed** where the templates declare **6**.
- Both existing routines were `enabled: false` and had been since 2026-08-12.
- Both carried prompts dating from 2026-08-07 — several template generations behind.
- A `RemoteTrigger`-family tool **was** exposed to that session. The convergence was reachable the whole time; the command simply does not attempt it.

So the repository was reported as prepared while four of its six routines did not exist and the other two had been dead for a week.

## Why this is a gap rather than a preference

The 2026-08-14 ruling (issue #445) made `/workaholify` *the preparation command, not an audit*. That ruling was applied to three of its four subjects — `CLAUDE.md` (§3), the `.workaholic/` layout (§3a) and the web bootstrap (§4) all converge. **§5 alone still only reports.** Issue #526 assumed the converging behaviour in its own words: *"Per repository added via `/workaholify` or `/setup-dev-routines`: exactly 3 routines"*.

## Asked for

§5 should run the same list/diff/apply flow the three setup commands already run — over every scope, since `/workaholify` is scope-agnostic by nature — with `no_transport: RemoteTrigger-family tool` as its one named refusal and the sheets as that refusal's recovery path. Exactly the shape §3, §3a and §4 already have.

## Two findings for the implementer to rule on rather than assume

1. **A template declares no `enabled` field.** A routine a human deliberately disabled is therefore converged in every other field and left silently off — indistinguishable in a report from a healthy one. At minimum the run should state each routine's enabled state; whether convergence should also *set* it is a real decision (a human disabling a routine is a signal, not drift).

2. **The "a rename needs a human" limitation may be narrower than the templates claim.** `renamed_from:` documents that convergence matches by name and therefore creates a second routine rather than renaming the operator's live one. But the API's update method renames in place, and doing so resolved this repository's `[Propose]` -> `[Specificate]` swap in one call with no duplicate and no manual step. If a converging `/workaholify` can perform the rename, the `renamed_from:` cutover instruction becomes a fallback for the no-transport class rather than the standing operator obligation it is written as today.
