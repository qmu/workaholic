---
created_at: 2026-08-04T20:12:30+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-routine-notifications-one-semantic-story
merge_policy:
---

# Balance structure and prose in FB issue authoring

## Overview

FB `20260804102558` (instruction): the FB issue authoring style has swung
between two extremes — heading-heavy, filler-laden structure earlier, then
plain unstructured prose as the overcorrection. Land in between: default to
prose; use a short numbered/bulleted list or a small table only when a
multi-step or multi-item ask genuinely reads better with one; no heavy heading
hierarchies; no content-free list items. And when turning a Slack ask into
issue prose, correct apparent wording mistakes and fill the gaps a standalone
reader needs — readability and accuracy over verbatim transcription.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / documentation policies — an artifact is written for its future reader, not as a transcript of its source

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — the routine's authoring guidance (currently "Brief PR description, detail in file")
- `plugins/workaholic/skills/feedback/SKILL.md` — if body-style guidance for feedback records lives anywhere canonical, it is here; templates reference it

## Implementation Steps

1. Write the style rule once (feedback SKILL if it owns record style, else the
   fb template): default prose; light structure only where a multi-step/-item
   ask genuinely helps; no deep headings; no empty-calorie bullets; fix the
   reporter's apparent slips and fill standalone-reader gaps rather than
   transcribing verbatim.
2. Reference it from the [FB] routine template's prompt with one positive and
   one negative example, compact enough not to bloat the prompt.
3. Check the two live examples the swing produced (the heading-heavy era, and
   `20260804101847`'s flat-prose era) read as before/after illustrations; cite
   them in the rule's rationale line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The style rule exists in one place with both failure modes named, and the [FB] template references it
- The rule explicitly licenses correcting wording mistakes and filling gaps over verbatim transcription

**Verification method** — the commands/tests/probes that prove them:

- Read-through of `routines/fb.md` against the FB's ask; `grep -n "prose"` finds the single canonical statement plus references

**Gate** — what must pass before approval:

- Docs consistent in the same change; rebuild `outputs/` if `feedback/SKILL.md` changed (it ships in the built bundle)

## Considerations

- This governs authoring style only; the record schema (`kind`/`source`
  validation) is untouched.
- The FB scopes itself away from the lifecycle-threading work — keep the two
  tickets' template edits sequenced to avoid rebase churn.
