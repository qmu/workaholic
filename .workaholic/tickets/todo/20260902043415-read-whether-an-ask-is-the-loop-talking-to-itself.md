---
created_at: 2026-09-02T04:34:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refuse-an-ask-the-loop-wrote-to-itself
merge_policy:
verification_handoff: 
---

# Read whether an ask is the loop talking to itself

## Overview

PROPOSED. Two of the three refusals this mission adds need the same reading, so it is built
once, as a reader, before either gate consumes it: **did a person want this?**

The repository already carries the three axes the answer is made of and needs no new field.
`subject:` is *who formed the opinion* (`person | meeting | observer_ai | customer | team |
other`), `author:` is *the git identity that ran the capture*, and `source:` is *the channel
it arrived through*. A record with `subject: observer_ai:…` is, by the schema's own
definition, a machine's opinion. That half is mechanical. The other half — *and its subject
is the loop's own artifact* — is a judgement, and the reader must say which half it
answered rather than blending them.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/feedback/SKILL.md`, *Choosing the subject* — the three axes
  and the closed `subject` kind set; the reading is derived from what is already there.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — refuses an absent subject, which
  is what makes the axis trustworthy on new records.
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` — writes
  `observer_ai:<author>`; the one existing machine-subject writer, and the case that proves
  the axis is real rather than theoretical.
- `plugins/workaholic/hooks/validate-feedback.sh` — floors new writes and grandfathers
  older ones; the reader must handle a grandfathered record with no subject.
- `plugins/workaholic/skills/specificate/scripts/read-ask-feedback-refs.sh` — the shape to
  follow: one reader, three-valued, exit 0 always.

## Implementation Steps

1. Write the reader — one script, pure read, no network — answering per record or per ask:
   `human` / `machine` / `unreadable:<reason>`, with the evidence it used named on the
   answer (`subject_kind`, and the author when the subject is absent).
2. Make `unreadable` a real third value that never collapses into either other one. A
   grandfathered record with no `subject:` is `unreadable:no_subject`, not `human` and not
   `machine` — and the consuming gates decide what to do with it, which is the next two
   tickets' business, not this one's.
3. Keep the judgement half out of the script. *Whether the subject matter is the loop's own
   apparatus* cannot be read from frontmatter, and a script that guessed it would refuse
   real asks about the loop written by people — which is most of this repository's inbox.
   The script answers *who*; the bar answers *about what*.
4. Add no field and no relation. The three axes exist; a fourth would be a second place for
   the same fact to drift.
5. Pin the reader hermetically: a `person:` record, an `observer_ai:` record, a
   grandfathered record with no subject, and a malformed one — four cases, four answers.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader answers `human` / `machine` / `unreadable:<reason>` and names its evidence.
- No new frontmatter field or relation is introduced.
- A grandfathered record reads `unreadable`, never `human` and never `machine`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, including the four-case assertion.

**Gate** — what must pass before approval:

- The reader is a pure read: no write, no network, exit 0 in every case.

## Considerations

- The tempting shortcut is to key on the *author* alone, since a routine session's commits
  carry a session trailer. That reads the runner rather than the opinion, and it would mark
  a human's ask captured by a routine as machine-authored. The subject axis is the one that
  means what this mission needs.
