---
type: Feedback
title: Count a queued ticket by where it sits, not by the status word it declares
kind: instruction
source: development
subject: observer_ai:tamura.yoshiya@gmail.com
created_at: 2026-09-06T14:49:02+09:00
author: a@qmu.jp
supersedes: 
---

# Count a queued ticket by where it sits, not by the status word it declares

An observing AI session reports that `strategy/scripts/attributed-work.sh` counts waiting work by comparing each ticket's `state` to the literal string `queued`, while `state` is read from the ticket's own `status:` frontmatter first and falls back to the path→`queued` mapping only when that field is **absent** — so a ticket sitting in `tickets/todo/` that honestly declares `status: todo` reads `todo`, matches nothing, and is invisible to every count derived from it. Declaring the status disables the brake.

Source: https://github.com/qmu/workaholic/issues/1030

## What the ask reports

Two halves of one reader use different vocabularies for one idea, and nothing reconciles them:

- **line 381**, the count: `map(select(.kind == "ticket" and .state == "queued")) | length`
- **line 292**, where `state` comes from: `fm_status` reads the frontmatter, and the `*/tickets/todo/* → queued` case runs only when that read came back empty.

`queued` is produced *only* by the fallback. It is not a value any ticket writes.

Measured across a consuming repository's whole ticket corpus:

```
distinct status: values      737 x "status: done"      2 x "status: todo"
tickets declaring status:    739
tickets declaring "queued":  0
```

So the one value the counter accepts appears **nowhere** in the corpus. Every correct answer the reader has ever given came from tickets that omitted the field. Per direction:

```
area-a-domain-modeling         waiting_count=0   queued tickets=1   waiting_kind=unknown
layout-system-improvements     waiting_count=3   queued tickets=3   waiting_kind=advancing
```

The second row is right only because those three tickets omit `status:`.

## What else the ask says dies with it

- **`QUEUED_PATHS` (line 363)** selects on the same comparison, so `work-kind.sh` is never invoked — which is why `waiting_kind` reads `unknown` and `waiting_describing` / `waiting_advancing` are both `0`. The describing-versus-advancing distinction added on 2026-08-23, specifically so a documentation queue could not block a build proposal, is inert on any repository whose tickets declare their status.
- **The mission-grain classification (line 404)** filters queued tickets the same way, so every active mission classifies as `work_kind: "unknown"`.

The failure presents as a healthy `0` rather than as anything unreadable.

## The naive fix the ask refuses in advance

Accepting `"todo"` alongside `"queued"` introduces a second defect: of the two `status: todo` tickets measured, **one is in `tickets/archive/`** — a finished ticket whose status line was never rewritten when it was archived. Under a widened comparison it would count as waiting forever.

The ask argues the two sources answer different questions — **the path says where the ticket is**, the **frontmatter says what the ticket claims about itself** — and that for a location question like *is this waiting*, the path is the authority and the frontmatter is at best a hint.

## What it asks for, in its own preference order

1. Derive queued-ness from the **path** for this count, and let `state` keep reporting the frontmatter for display. The reader already computes the path mapping and discards it whenever a status line exists.
2. If the frontmatter must participate, reconcile the vocabularies explicitly — one canonical set, the fallback and the field producing the same words — and **report a disagreement** (`status: todo` on a file under `archive/`) rather than silently trusting either side.
3. Either way, **a count that no ticket can ever satisfy should not be able to read as `0`.**

## How this run judged it

**Record-only, `self_authored`.** The ask carries `subject: observer_ai:tamura.yoshiya@gmail.com`, so `feedback/scripts/ask-origin.sh` reads `machine`; its subject is the loop's own apparatus — the `work_waiting` brake in `/propose`'s own eligibility survey, and the attribution reader beneath it. `plugins/workaholic/rules/workaholic.md`, *What May Originate a Mission*, is explicit that such a record may not originate a mission, and the ask's own closing section says a `propose` run is what found it. The finding is kept as knowledge; a human ask naming this work is what would originate it.

**The judgement is not a comment on the finding's quality.** It is measured, localized to two line numbers, and it names the wrong fix before anyone makes it. It is refused as an *originator*, not as evidence — and it is worth saying plainly that this run's own survey was gated by the very mechanism the ask describes, which is precisely the position from which a loop must not be allowed to grant itself work.
