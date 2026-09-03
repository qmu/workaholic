---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Declare a verification handoff as a probe command

## Overview

A `verification_handoff:` value is free text quoted verbatim into `## Handoff`, so nothing can
ever falsify it. This ticket establishes the probe-shaped declaration — a **command** whose exit
status decides — and, before choosing its shape, measures what this repository's own standing
declarations actually say. The ask's measurement was taken on a consuming repository; the same
reading has to be taken here before a format is fixed, because the format has to fit the
declarations that already exist.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one reader; its header states the field's current contract and why it is free text
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — where the ticket's frontmatter and the handoff's writing rule are stated
- `plugins/workaholic/skills/specificate/scripts/scaffold-proposed-ticket.sh` — one of the two writers (`--verification-handoff`)
- `plugins/workaholic/rules/workaholic.md` — the verification axis is stated here for the fleet

## Implementation Steps

1. **Reproduce and localize first.** Enumerate every `verification_handoff:` value under
   `.workaholic/tickets/todo/` and `.workaholic/tickets/archive/` and under
   `.workaholic/missions/`. For each, record verbatim what it claims and classify it: does it
   name a credential, a host, a device or an account? Do not fix anything yet.
2. For each declaration naming something checkable, **write the probe that would decide it** and
   run it here. Record the exit status and the output. This is the measurement the ask says was
   never taken; it is also the evidence for the format.
3. Define **`verification_probe: <command>`** as optional frontmatter beside
   `verification_handoff:`, on tickets and on missions. It is a shell command line; its **exit
   status** is the whole reading — zero means the verification can run here, non-zero means it
   cannot. Do not overload `verification_handoff:`'s own value: it is quoted verbatim into
   `## Handoff` and a command rendered there reads as an instruction to a person.
4. State the field in `ticket-format.md` and in `rules/workaholic.md`, beside the existing axis:
   what it is, that its exit status decides, that it is re-run rather than read, and that a
   declaration carrying no probe is unmeasured rather than false.
5. Teach `scaffold-proposed-ticket.sh` a `--verification-probe` flag beside its existing one,
   written only when the ask states it, and state in `workaholic:create-ticket` that `/ticket`
   asks for the probe whenever it writes a handoff.
6. Leave the reader, the route and every existing declaration untouched — this ticket adds the
   vocabulary and the writers; the next ones read and act on it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every existing `verification_handoff:` in this repository is enumerated with its verbatim claim and a probed result where one could be written.
- `verification_probe:` is defined in `ticket-format.md` and `rules/workaholic.md` as a command whose exit status decides.
- `scaffold-proposed-ticket.sh --verification-probe` writes the field and omits it when not passed.

**Verification method** — the commands/tests/probes that prove them:

- The enumeration, recorded in the branch story with each probe's exit status.
- `node scripts/test-workflow-scripts.mjs` — a row asserting the flag writes the field and its absence writes nothing.

**Gate** — what must pass before approval:

- No behaviour change to `verification-handoff.sh` or any route in this ticket; a repository declaring no probe is byte-identical to one before it.

## Considerations

- The ask proposes the probe shape directly. That shape is adopted here as a **hypothesis to
  confirm against the measurement in step 1**, not as step 1's design: if this repository's own
  declarations turn out to name things no command can decide, the format has to say so rather
  than force a probe onto them.
- A probe is a command a run will execute. Its blast radius is the run's own environment; it must
  be a read, never a write, and that bound belongs in the field's definition.
