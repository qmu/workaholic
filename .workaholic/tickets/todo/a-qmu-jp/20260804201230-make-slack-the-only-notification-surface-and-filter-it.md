---
created_at: 2026-08-04T20:12:30+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: 20260804201230-thread-the-fb-lifecycle-into-one-semantic-slack-story.md
mission: make-routine-notifications-one-semantic-story
merge_policy:
---

# Make Slack the only notification surface and filter it

## Overview

FB `20260804085719` (instruction, qmu/workaholic#187): the Web routines
currently notify twice — a Claude mobile-app push and a Slack post per event.
Make Slack the sole surface, and since dropping the mobile channel narrows
visibility, define in the templates what is *worth* a Slack post: the events a
developer must act on or stay aware of (a PR merged, a drive blocked on a real
precondition, a drive started), not every internal step of a tick. Reuse the
repository's own precedents — the branch story drops `low` severity by default,
and drive-blocked alerting deduplicates on the failure signature.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / UX policies — every notification spends reader attention; the default for an event is silence unless it earns the post

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md`, `merged-pr.md`, `drive.md` — each template's notification section gains the surface rule and its event filter
- `plugins/workaholic/skills/workaholify/SKILL.md` — the one canonical statement of the surface + filter doctrine the templates reference
- `plugins/workaholic/commands/setup-routines.md` / `compare-routines.sh` — if mobile-push behavior is a routine body/config field, the drift report must cover it

## Implementation Steps

1. Establish how the mobile push is switched off: inspect a live routine's
   config shape (via the setup-routines survey scripts) for the notification
   field; if it is body-prompt-driven instead, the template states "post to
   Slack only; send no mobile notification" as an instruction to the session.
   Record which mechanism it turned out to be in the template comment.
2. Write the filter doctrine once in `workaholify/SKILL.md`: post = an event a
   developer acts on (merge, blocked-on-precondition, handoff, run started) —
   with each template naming its own postable events; drop low-value/step-level
   events by default (the story's low-severity precedent); dedupe repeats by
   failure signature (the drive-blocked precedent).
3. Apply to the three templates' notification sections, referencing the
   doctrine; the in-thread story format from the threading ticket is the shape
   these filtered posts take.
4. Scope guard from the FB verbatim: the routines' drive/survey work is
   untouched — this changes only whether and where an event is announced.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every template's notification section names Slack as the only surface and lists its postable events
- The filter doctrine exists once, with both precedents (low-drop, signature-dedup) wired in
- The mobile-push-off mechanism is identified and recorded, not assumed

**Verification method** — the commands/tests/probes that prove them:

- `grep -n "Slack" plugins/workaholic/skills/workaholify/routines/*.md` — surface rule present in all three
- compare-routines drift report shows the live routines drifted on the changed fields (expected until refreshed)

**Gate** — what must pass before approval:

- Docs consistent in the same change; no live routine mutated by the branch itself

## Considerations

- If the mobile push turns out to be an account-level setting no template can
  reach, the ticket's deliverable becomes the documented finding plus the
  developer-facing instruction in /setup-routines — a truthful "cannot" beats a
  claimed "did".
- Filtering is prompt-enforced (a model judgment at post time); the templates
  should give bright-line examples per event class, since a vague bar refills
  the channel.
