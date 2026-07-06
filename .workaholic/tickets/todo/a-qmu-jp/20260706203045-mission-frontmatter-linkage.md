---
created_at: 2026-07-06T20:30:45+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort:
commit_hash:
category:
depends_on: [20260706203044-mission-artifact-type-and-command.md]
---

# Wire machine-readable mission relations across tickets, reports, and concerns

## Overview

With the mission artifact in place (ticket 1), connect the rest of the workflow to it
through **machine-readable frontmatter relations** — the developer's explicit choice:
frontmatter over prose, because it is machine-readable, and the relations span
**everything**, not just tickets:

- **Tickets** gain an optional `mission: <slug>` frontmatter field, selected at `/ticket`
  time (associate the new ticket with an existing mission, or none).
- **Stories (reports)** gain `mission: <slug>` **and** a machine-readable `tickets: [...]`
  list — the report→tickets relation. A story already narrates its tickets in prose; this
  records the association in frontmatter so a mission can roll them up mechanically.
- **Concerns** gain `mission: <slug>` **and** a `tickets: [...]` relation — the
  concerns→tickets relation — so a deferred concern is traceable to the mission and the
  specific tickets it arose from, not only to its origin PR/branch/commit.

This ticket makes each artifact **emit** its relation. It does **not** update the mission
doc itself (appending changelog lines and flipping acceptance items is ticket 3) — it only
ensures every downstream artifact carries the relation ticket 3 will read.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code and keep every change defensible
against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — changes stay within the
  relevant skills; no new top-level surfaces.
- `workaholic:implementation` / `policies/coding-standards.md` — frontmatter emission and any
  script edits follow house style.
- `workaholic:implementation` / `policies/command-scripts.md` — frontmatter parsing/emission
  goes in bundled POSIX scripts (`extract-carryover.sh`, ticket/story writers), never inline
  conditional shell in markdown.
- `workaholic:implementation` / `policies/objective-documentation.md` — the relation fields are
  unambiguous, machine-readable, and documented (slug refs and filename lists, not free text).
- `workaholic:design` / `policies/history-structures.md` — relations are recorded consistently
  and immutably at write time across all three artifact types.
- `workaholic:planning` / `policies/terminology.md` — the `mission:` field references the
  mission `slug` consistently everywhere; one term, one shape.

## Key Files

- `plugins/workaholic/skills/create-ticket/SKILL.md` - Frontmatter Template + File Structure;
  add the optional `mission:` field and the `/ticket`-time association step.
- `plugins/workaholic/commands/ticket.md` - add a step to offer mission association
  (AskUserQuestion at command level, listing existing missions).
- `plugins/workaholic/hooks/validate-ticket.sh` - confirmed to whitelist required fields and
  **not** reject extras, so an optional `mission:` line passes; add validation only if the
  field must be constrained to an existing slug.
- `plugins/workaholic/skills/report/` (+ `review-sections`) - story frontmatter writer; add
  `mission:` and the `tickets: [...]` list (report→tickets).
- `plugins/workaholic/skills/ship/scripts/extract-carryover.sh` - concern writer; add
  `mission:` and `tickets: [...]` to the concern frontmatter (concerns→tickets).
- `.workaholic/concerns/README.md` - File Format / Frontmatter Fields; document the new
  relation fields.
- `CLAUDE.md`, `.workaholic/README.md` - OKF per-file conformance notes and any frontmatter
  documentation.

## Related History

Concern files already record provenance (`origin_pr`, `origin_branch`, `origin_commit`) and
carry forward across PRs (e.g. `59-carried-from-pr-58-carried-from-pr-54…`), and stories
already reference their tickets in prose — this ticket promotes those implicit links to
explicit, machine-readable frontmatter and adds the mission axis on top.

## Implementation Steps

1. **Tickets**: add optional `mission:` to the create-ticket Frontmatter Template and File
   Structure docs (documented as optional, empty when absent). In `commands/ticket.md`, add a
   step that lists existing missions (from `skills/mission` — a `list.sh` if not already
   present from ticket 1) and, via a command-level `AskUserQuestion`, lets the developer pick
   one or none; write the chosen slug into the ticket frontmatter.
2. **Validate-ticket hook**: confirm the optional field passes unchanged; only add a check if
   the team wants `mission:` constrained to an existing `missions/<slug>/`.
3. **Stories**: extend the report story-frontmatter writer to emit `mission:` (inherited from
   the archived tickets' `mission:`, or asked) and a `tickets: [...]` list of the filenames the
   story covers (report→tickets).
4. **Concerns**: extend `ship/scripts/extract-carryover.sh` to carry `mission:` and a
   `tickets: [...]` relation into each extracted concern's frontmatter (concerns→tickets),
   deriving them from the shipped story's frontmatter written in step 3.
5. **Docs in the same change**: `concerns/README.md` File Format, `CLAUDE.md` OKF per-file
   conformance list, `.workaholic/README.md`.
6. **Regenerate + version**: run `node scripts/build-plugins/build.mjs` (create-ticket, report,
   ship are shipped skills — their `outputs/` copies must refresh) and bump the version.

## Quality Gate

Full automated gate (Workflow Step 4b).

**Acceptance criteria** — the checkable conditions that must hold:

- A ticket created with a mission association carries `mission: <slug>` in frontmatter and
  still passes `validate-ticket.sh`; a ticket created without one omits/empties the field and
  still passes.
- A generated story carries `mission:` and a `tickets: [...]` list naming exactly the ticket
  filenames it covers.
- An extracted concern carries `mission:` and a `tickets: [...]` relation traceable back to the
  shipped story, in addition to its existing provenance fields.
- All three relations are pure frontmatter (parseable, machine-readable) — no reliance on prose.

**Verification method** — the commands/tests/probes that prove them:

- New hermetic assertions in `node scripts/test-workflow-scripts.mjs`: a ticket written with and
  without a `mission:` value both pass `validate-ticket.sh`; `extract-carryover.sh` over a fixture
  story emits concern frontmatter containing `mission:` and `tickets:`.
- `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` green.
- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/ hooks/policy-index.md` empty.
- `posix-lint` clean on edited scripts.

**Gate** — what must pass before approval:

- The smoke-test additions green, `validate-ticket.sh` accepts both ticket shapes, verify/validate
  green, outputs/ + policy-index.md clean after rebuild, posix-lint clean, docs updated in the
  same commit.

## Considerations

- **Optional, never required** — `mission:` must be optional on tickets/stories/concerns so the
  entire existing pipeline keeps working for un-missioned work; the hook and all scanners must
  tolerate its absence (`plugins/workaholic/hooks/validate-ticket.sh`).
- **Slug integrity** — a `mission:` value should reference a real `missions/<slug>/`; decide at
  `/drive` whether to hard-validate (reject unknown slug) or soft-validate (warn), and keep it
  consistent across ticket/story/concern writers.
- **Backfill is out of scope** — existing tickets/stories/concerns have no `mission:`; this ticket
  only adds emission going forward. Note this in docs rather than mass-editing history
  (`.workaholic/concerns/`).
- **Depends on ticket 1** — the mission slug space and `list.sh` come from
  `20260706203044-mission-artifact-type-and-command.md`.
