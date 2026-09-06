---
type: Feedback
title: The source resolver answers ok for a source missing scripts the run needs
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-06T13:20:40+09:00
author: a@qmu.jp
supersedes: 
---

# The source resolver answers ok for a source missing scripts the run needs

Source: https://github.com/qmu/workaholic/issues/1021

`plugin-src.sh` resolved the registry source and answered `ok: true` with `source: registry`,
`version: 1.0.288`, `src_immutable: true`, `degraded: true` — for a source that does **not**
contain `skills/drive/scripts/branch-checks.sh` or `skills/notify/scripts/list-unposted-lines.sh`.
Both paths were measured absent under it; a working tree of the same plugin has the first.

The current run instructions name both scripts as steps a run performs, so a run that resolves
its source through the sanctioned resolver is handed a source that cannot perform them, and the
envelope's only complaint is `degraded: true` — which is about **binding**, not about
**completeness**.

The consequence is a gate that skips itself quietly. Three separate runs in one day reported
`unreadable: script_absent` for exactly these two, each compensating by hand for a resolver that
had told it the source was fine. `branch-checks.sh` is the checks gate before a delivery; a run
that cannot find it either invents a substitute or proceeds without one, and nothing in the
envelope says which happened. That is the shape this loop refuses everywhere else: a degraded
read must be named by the reader, not left for each caller to discover and describe in its own
words.

**One report that could not be reproduced, stated so it is not taken as measured.** A run
reported that the same script answers a *newer* version when invoked from inside a consuming
checkout and the cached one when invoked by absolute path — which, if true, would mean the
working directory silently decides which plugin a run executes. Both invocations answered
`1.0.288` identically on the reporting machine, whose cache holds only `1.0.287` and `1.0.288`,
so there is no reading either way. Worth checking on a machine that has a bound root; not what
this ask is for.

**The ask** is the smaller and better-founded half: the resolver should say when its chosen
source is missing scripts the run will ask it for. `ok: true` beside a source that cannot answer
is the one thing a caller cannot recover from, because the caller has no reason to look. Whether
that is an `incomplete: [names]` field, a refusal, or a fallback to a complete candidate is the
maintainer's call — but a run should not have to discover it one `script_absent` at a time.
