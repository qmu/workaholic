---
type: Feedback
title: The routines list API caps at 20, so a fleet drift report silently misses routines
kind: concern
source: discussion
created_at: 2026-08-05T21:00:36+09:00
author: a@qmu.jp
supersedes: 
---

# The routines list API caps at 20, so a fleet drift report silently misses routines

The routines list API returns at most 20 triggers, and nothing in the survey path knows it. Measured 2026-08-05: creating `[Propose] workaholic` pushed `[Propose] data-platform` out of the response entirely — same account, same routine, still live and still firing, simply absent from the list. Its id survived only because an earlier capture in the same session still held it.

That makes the fleet-wide drift report quietly incomplete once an account passes twenty routines. `compare-routines.sh` surveys every repository that carries a workaholic routine, and `list-routines.sh` reports `elsewhere.drifted` from that survey — so a routine the API did not return is not reported as unknown, not counted as drifted, and not named as missing. It is simply not there, and the report reads exactly as it would if the routine were fine. That is the failure mode both scripts were written to prevent: `checked: false` exists precisely so 'I could not look' never renders as 'nothing is wrong'.

Today's fleet is 20 routines against a 20-item ceiling, so this is not a latent risk — it is the current state, and the next routine created makes another one invisible. `this_repo` happens to be safe by luck of ordering; `elsewhere` is not.

Two things need deciding rather than assuming. Whether the API offers pagination at all (the `RemoteTrigger` tool exposes list/get/create/update/run with no cursor parameter, so if the endpoint takes one, the tool would need to pass it) — and, if it does not, what the honest report is: a survey that cannot see the whole fleet should say so on the fleet axis, the same way a shallow clone forbids `ok` in the claim scan, rather than reporting a confident zero.

A cheap corroboration exists in the meantime: the API returns a count the caller can compare against what it received. If the response is exactly at the ceiling, the survey should assume it is truncated.
