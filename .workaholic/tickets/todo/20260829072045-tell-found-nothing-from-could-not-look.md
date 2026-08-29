---
created_at: 2026-08-29T07:20:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Tell found nothing from could not look

## Overview

PROPOSED. Give the walk its own outcome. `grep` exiting 1 means *no match* and is honest;
exiting 2 or more means *could not read* and is a failure, and today both vanish into the
same swallowed status. Derive a `readable` / `reason` answer for the walk itself. This is
the term the rest of the mission rests on, and it adds **no field to any artifact** — it is
a property of one read, reported by the reader that made it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/keep-serving.md` — a degraded read is named, never rendered as an answer

## Key Files

- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — both hops; the walk whose
  outcome is being named.
- `scripts/test-workflow-scripts.mjs` — cases for the three outcomes.
- `outputs/workflows/` — regenerated.

## Implementation Steps

1. **Separate the two exits at both hops.** `grep` exit 1 (no match in this batch) is a
   success and contributes nothing; exit ≥2 (unreadable file, bad pattern file, I/O error)
   marks the walk **degraded** and carries its own reason. Do this at hop 1 and hop 2 alike.
2. **Name the outcome once.** One derivation of `{readable, reason}` for the walk, read by
   whatever needs it — not one derivation per hop and not a second copy in a consumer, on the
   standing rule that two derivations of one fact eventually disagree.
3. Choose reasons that say what failed rather than that something did: distinguish at least a
   corpus the walk could not read from a pattern set it could not read, and keep the vocabulary
   small enough to enumerate in the skill.
4. **Emit nothing new yet.** This ticket derives and returns the term; carrying it into
   `attributed-work.sh`'s emitted reading is the next ticket, and into the survey and the
   residue the two after that. Keeping the seam narrow is what makes the next three reviewable.
5. Add hermetic cases for all three outcomes — completed-with-matches, completed-with-none,
   and could-not-read — the third built by making a corpus entry genuinely unreadable rather
   than by stubbing `grep`.
6. Regenerate `outputs/` and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A batch matching nothing leaves the walk `readable: true`.
- A batch that could not be read leaves the walk `readable: false` with a reason naming what
  failed.
- The three outcomes are covered by hermetic cases, the unreadable one built from a real
  unreadable input.
- No artifact gains a field, and the walk's outcome is derived in exactly one place.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `grep -c` over the script confirming a single derivation site for the outcome.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- Every existing consumer's output is byte-identical, since nothing is emitted yet.
- `Outputs Freshness` shows no diff after the rebuild.

## Considerations

- A test that makes a file unreadable has to run as a user who can be refused — a suite step
  running as root will not observe `EACCES`. Prefer an input the reader genuinely cannot
  consume over a permission bit if the suite's environment makes the latter unreliable.
- Resist folding *could not look* into the existing `empty_reason` vocabulary: those name why
  a completed walk found nothing, and reusing them is precisely the conflation this mission
  exists to remove.
