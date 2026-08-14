# Ticket format

The file structure, frontmatter schema, and content guidelines for every ticket this skill writes. Workflow §5 writes to this contract; `hooks/validate-ticket.sh` machine-checks the frontmatter and the two mandatory body sections, on the todo queue only (archives are history and never retro-blocked; the hook is PostToolUse, so each ticket is written complete in a single Write).

## Filename

`YYYYMMDDHHmmss-<short-description>.md`, the timestamp from `ticket-metadata.sh`'s `filename_timestamp` — e.g. `20260114153042-add-dark-mode.md`.

## Frontmatter

```yaml
---
created_at: 2026-01-31T19:25:46+09:00   # date -Iseconds output — actual value, never a placeholder
author: developer@company.com            # git config user.email — who wrote the spec; immutable
assignees: [developer@company.com]       # who owns the work — plural; empty = team-owned/claimable
depends_on:
mission:                                 # optional: every mission this ticket advances
merge_policy:                            # optional: auto | review — ABSENT MEANS review
verification_handoff:                    # optional: what this work's verification needs and
                                         # an unattended run does not have — ABSENT MEANS none
---
```

- `created_at` / `author` / `assignees`: required, filled with actual command output (never placeholders, never a hand-typed date format).
- `assignees`: who is to do the work — plural because a ticket can be co-owned, empty meaning team-owned and claimable by anyone (P2, 2026-08-06 — the field replaced the `todo/<user>/` directory, so reassignment is an edit, not a file move). Seed with the requester when a developer types `/ticket`; leave empty for a proposal. Read it only through `gather/scripts/owners.sh` / `owns.sh`, never by grepping — that is what keeps `/drive`'s survey, `/ticket`'s summary, and `/ship`'s queue check agreeing about whose work it is. Deliberately distinct from `author`: author is immutable history, owner is meant to change.
- `depends_on`: present but empty unless the run split the request; dependent tickets list prerequisite filenames (`depends_on: [20260410002111-foundation.md]`), only where a genuine implementation ordering exists (shared files, API contracts, schema-first changes).
- `mission`: optional — every mission the ticket advances (`mission: [alpha, beta]`, or a bare slug for one). Chosen from the existing missions in Workflow §4c, so written slugs are valid by construction; never required, and the pipeline tolerates its absence.
- `merge_policy`: optional, `auto` or `review`, captured in Workflow §4d. Absent means `review` — the conservative default; every ticket written before the field existed carries no value, and the one reading that must never produce is "merge this without a human looking". `hooks/validate-ticket.sh` enforces the enum only when a value is present: an empty field is legal, a typo'd one (`atuo`) is not — it would otherwise read as `review` while its author believed they had asked for automatic merging.

- `verification_handoff`: optional free text, added 2026-08-14 (issue #452). Record it when the ask
  already says the real-world verification cannot run where an unattended run executes — a missing
  credential, device, or third-party account — and make the value **name what is missing**, because
  it is quoted verbatim into the pull request's `## Handoff` section. Absent means none, which is
  the overwhelmingly common case; leave it empty rather than guessing, since a value here stops the
  unit from merging. `/drive` reads it through `drive/scripts/verification-handoff.sh` **before**
  the merge-policy table and routes the unit to `handoff` whatever `merge_policy` says
  (`workaholic:drive` §6). It is a creation-time declaration like `merge_policy` and is never
  edited by a run — a run that could declare its own unit unverifiable would be excusing itself.

### Retired (2026-08-07) — never written anew

`type`, `layer`, `effort`, `commit_hash`, and `category` left the ticket schema in one change: `type`/`layer` classified rather than informed (nothing routed on them once ordering became `depends_on`-and-context and the `## Policies` section became the recorded lens), `effort` was an agent's rounded guess (mission time is recorded honestly by `record-run-hours.sh`), `commit_hash` is derived from git (`report/scripts/ticket-commits.sh` — a commit cannot carry its own hash), and `category` lives in the commit's `Category:` git trailer. Existing tickets carrying them — the whole archive and any grandfathered queue item — validate and drive unchanged; the fields are tolerated everywhere and required nowhere.

## Common mistakes

| Mistake | Example | Fix |
|---------|---------|-----|
| Placeholder values | `author: user@example.com` | Run `git config user.email` and use actual output |
| Wrong date format | `2026-01-31` or `2026/01/31T...` | Use `date -Iseconds` output (includes timezone) |
| Retired fields written anew | `type: enhancement`, `layer: [UX]` | Omit them (see *Retired* above) |
| Invalid depends_on entry | `depends_on: [notes.md]` | List real ticket filenames only |

## File structure

```markdown
---
created_at: 2026-01-31T19:25:46+09:00
author: developer@company.com
assignees: [developer@company.com]
depends_on:
mission:
merge_policy: review
verification_handoff:
---

# <Title>

## Overview

<Brief description of what will be implemented>

## Policies

The standard engineering policies (synced from qmu.co.jp into the `workaholic` policy skills) that govern this ticket. The implementing session MUST read each linked hard copy before writing code and keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践). `/drive` consumes this section verbatim. Mandatory and never empty for a code-touching ticket: always the two universal implementation policies, plus the pillar policies the touched layers select (see *Policy lens* below) and any policy the policy-mode discovery surfaced.

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — TypeScript/style conventions (all code work)
- `workaholic:design` / `policies/modeless-design.md` — <why this policy applies to this ticket>

## Key Files

- `path/to/file.ts` - <why this file is relevant>

## Related History

<1-2 sentence synthesis of what historical tickets reveal about this area>

- [<filename>.md](.workaholic/tickets/archive/<branch>/<filename>.md) - description (match reason)

## Implementation Steps

1. <Step 1>
2. <Step 2>

## Quality Gate

How the outcome's quality is assured, captured from the developer in Workflow §4b. `/drive` surfaces this in its approval prompt and forwards it into the commit `Verify:` key. Mandatory and never empty for a code-touching ticket; every line objective and verifiable (`workaholic:implementation` / `objective-documentation`). The hook checks presence, never quality — whether a gate is any good stays the job of the §4b interrogation and the developer.

**Acceptance criteria** — the checkable conditions that must hold:

- <e.g. `git branch foo` exits 2 (block)>

**Verification method** — the commands/tests/probes that prove them:

- <e.g. `node scripts/test-workflow-scripts.mjs` is green; the new assertions cover the criteria>

**Gate** — what must pass before approval:

- <e.g. the suite is green, posix-lint conforming, verified live in-session>

## Patches

<Optional unified diffs — omit if no concrete code changes can be specified>

## Open Decisions

<Optional — a genuinely unrecommendable fork the writing session has no authority to
resolve unattended, each item naming the fork and its live options. `/ticket` resolves
this kind of fork by asking the developer directly in Workflow §4b, so it rarely needs
this section; `/propose` cannot ask, so this is where it records one instead of silently
choosing (`workaholic:propose`, *Open decisions*). Omit the section entirely when there
is none.>

- <The fork> — options: <A> vs <B>. <Why neither is clearly recommendable.>

## Considerations

- <Concern description> (`path/to/relevant-file.ext`)
- <Line-specific concern> (`path/to/file.ext` lines 45-60)
```

Related History is omitted entirely when discovery found no matches; `<branch>` comes from the search result. Considerations SHOULD each reference a specific file path in parentheses (with line ranges where specific); a purely conceptual concern may omit the reference. A ticket whose ask reports a failure of an existing mechanism states step 1 as reproducing and localizing that failure, with any reporter-proposed fix recorded here as a hypothesis rather than adopted directly (`workaholic:discover`, *Diagnosis-First Rule*).

### Trip Origin — a legacy line, never written anew

Archived tickets from before 2026-07-28 may carry a `**Trip Origin:** .workaholic/trips/…` note under `## Overview`, linking the retired trip workflow's design docs. Read it as history; never add it to a new ticket — a ticket's rationale now lives in the feedback stream and, for a mission's set, in the mission's `## Goal` / `## Experience`.

## Policy lens

Map the architectural layers the work touches (judged from discovery — no frontmatter field) to the pillar skills, and use the mapping to fill the mandatory `## Policies` section — the durable record `/drive` reads later to know which hard copies to open:

| Layer | Policy skill | Lens |
| ----- | ------------ | ---- |
| UX | `workaholic:design`, plus `workaholic:implementation` | Modeless design, reach, WCAG conformance, emergent design system |
| Domain | `workaholic:implementation` | Type-driven design, layer segregation, functional style |
| Infrastructure | `workaholic:implementation`, plus `workaholic:operation` | Vendor neutrality, IaC, observability; CI/CD automation |
| DB | `workaholic:implementation` | Relational-first persistence, domain–persistence segregation |
| Config | (whichever skill governs the affected behavior) | Apply the skill whose policies the config touches |

`implementation/directory-structure` and `implementation/coding-standards` apply to every code-touching ticket; when a ticket initiates new work (a new feature or project), also apply `workaholic:planning` before the design/implementation pillars.

## Patch guidelines

Patches are optional but valuable for concrete, well-understood changes. Include them for clear modifications to existing files where exact placement matters; omit them for new files, exploratory refactoring, or runtime-dependent changes. Format: standard unified diff (`git apply`-compatible), 3 context lines, ≤50 lines per file, repository-relative paths, one `### path/to/file` subsection per file. Mark uncertain ones: `> **Note**: This patch is speculative - verify before applying.`

## Writing guidelines

- Focus on the "why" and "what", not just "how"; keep steps actionable and specific
- Reference existing code patterns when applicable
- Use the Write tool directly (it creates parent directories), one complete ticket per Write
