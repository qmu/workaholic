---
type: Feedback
title: Keep the closing link readable as the corpus grows
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T07:17:15+00:00
author: a@qmu.jp
supersedes: 
---

# Keep the closing link readable as the corpus grows

Source: https://github.com/qmu/workaholic/issues/705

The [Propose] routine's contraction move against the strategy
`an-autonomous-improvement-loop-run-by-the-routines`.

## The ask

`strategy/scripts/attributed-work.sh` — the one reader of *which work belongs to this
direction* — silently answers **zero** once the artifact corpus grows past one `xargs`
command buffer, and it began doing so on this repository today.

Both hops prefilter with:

```sh
xargs grep -lFf "${TMP}/patterns" < "${TMP}/corpus" 2>/dev/null > "${TMP}/cand1" || : > "${TMP}/cand1"
```

`xargs` splits the corpus into batches; a batch containing no match makes that `grep` exit
1, which makes `xargs` exit 123, which fires the `||` branch and truncates the candidates
the earlier batches already found. Measured on this checkout at 2026-08-29 06:41 UTC: the
corpus is 1402 files / 131508 bytes against a 131072-byte command buffer, so it splits
1396 + 6, the six-file tail matches nothing, and 25 real citations are discarded. The
reader then reports `empty_reason: no_citing_artifacts` for
`an-autonomous-improvement-loop-run-by-the-routines`, whose citing artifacts are 2 active
missions and 23 archived ones.

Both call sites are affected (hop 1 `cand1`, hop 2 `cand2`), and the second hop carries
every ticket's `via_mission:` attribution, so its loss is the larger one.

## What the ask asks to become true

- The prefilter's per-batch *no match* is not a failure. A batch that matches nothing costs
  nothing; only a batch that could not be **read** is a failure.
- A walk that did not complete is named as **degraded**, never emitted as an honest zero.
  `no_citing_artifacts` must keep the meaning mission `prove-the-loop-s-closing-link`
  established — *nothing has answered this direction yet* — and must not also mean *the
  reader could not look*.
- Every reading composed on top of the walk carries that degradation rather than deriving a
  verdict from it: `dormant`, `pace`, `quiescent`, `waiting_*` and `work_waiting` in
  `survey-strategies.sh`; the residue in `unattributed-work.sh` / `mission-strategy.sh`;
  and the digest in `standup/scripts/digest.sh`.
- The failure is pinned by a test over a corpus large enough to split into more than one
  batch — the property is **size**, so a fixture of a dozen files proves nothing.

## Why the ask calls it a contraction

The landed work — the loop's own growing output — made the reader inconsistent with the
Aim by the mechanical fact of its own volume. Nothing in the tree regressed; the corpus
crossed a boundary the reader never declared, and it will never recover on its own, because
the corpus only grows.

The failure is silent and self-perpetuating: it presents as `no_citing_artifacts`, which
the loop is designed to treat as explicitly *not* a refusal, so the tick reports a healthy
hour, `/moderate` asks the operator to rule on attributions that already exist, and
`quiescent` — the reading that would say this direction has arrived — becomes unreachable.

## What the ask chose it against

A `depth` move carrying this morning's `expiring` reading into `/standup`'s digest, and a
`breadth` move into an untouched part of the Aim: both refused because every one of those
readings is derived on top of the walk that is returning zero, so deepening any of them is
deepening a reading nobody can currently trust.
