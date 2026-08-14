---
type: Term
title: File Conventions
description: Naming patterns, directory shapes and the fields that carry state
category: developer
last_updated: 2026-08-13
---

# File Conventions

Naming patterns and directory structures. The authoritative structural rules are in
`plugins/workaholic/rules/workaholic.md` and the layout allowlist beside it; this file
explains the conventions a reader meets in filenames and paths.

## kebab-case

Kebab-case — lowercase words joined by hyphens — is the naming convention for files,
directories, skills and slugs (`create-ticket`, `mission-close`, `release-scan`). It
avoids case-sensitivity surprises across filesystems. The exceptions are conventional
uppercase names: `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `SKILL.md`. Related terms:
frontmatter, slug.

## slug

A slug is the kebab-case identifier derived from a title and used as a filename and a
key — a mission's `slug`, a strategy's `<slug>.md`, a deployment target's name. Ownership
comparisons are made by slug, not by display name. Related terms: kebab-case, mission.

## timestamped filename

A ticket's filename is `YYYYMMDDHHmmss-<short-description>.md`, and a branch's name is
`work-YYYYMMDD-HHMMSS` or `release/YYYYMMDD-HHMMSS`. The timestamp is a **sort key and a
unique id**, not metadata to read: queue order falls out of it, and splitting one ticket
into several uses timestamps a second apart to fix their order. Related terms: branch
name, ticket.

## frontmatter

Frontmatter is the YAML block delimited by `---` at the top of a markdown file. Every
knowledge artifact here carries a non-empty `type:` (`Story`, `Mission`, `Feedback`,
`Strategy`, `Deployment`, `Term`, `Release Note`, `Release`) — that is the OKF floor, and
write-time validators enforce it on new files while git-tracked history is grandfathered.
**Tickets are the exception**: no `type:`, by decision. Per-artifact field lists are in
the rules table. Related terms: OKF, type, validator.

## status field

A ticket's state is a **frontmatter field, not a directory**: `status:` absent means
queued, `done` is stamped at the archive gate, and `abandoned` and `icebox` mean archived
with that outcome. `icebox` survives as a state distinct from `abandoned` — deferred and
promotable versus decided against — and promoting a ticket back to the queue clears the
field. Related terms: todo, archive, ticket.

## todo

`.workaholic/tickets/todo/` is the queue: every ticket waiting to be driven, flat, with no
per-owner subdirectories (ownership is the `assignees` field, so reassignment is an edit
rather than a file move). A source fills it; one executor drains it. Related terms:
archive, status field, assignees.

## archive

`.workaholic/tickets/archive/<branch>/` holds tickets that have been driven, keyed by the
branch that drove them. A ticket that was never driven lands in the synthetic
`archive/unbranched/` — inventing a branch name would assert a drive that never happened.
Archived files keep their original names, and archives are history: the write floors
never retro-block them. Related terms: todo, status field, branch name.

## assignees

`assignees` is the plural ownership field on every artifact, and **empty means
team-owned and claimable by anyone**. It is deliberately distinct from `author`: author
is immutable history, owner is meant to change. Read it only through the one ownership
oracle, never by grepping — that is what keeps the executor's survey, the ticket queue
report and the ship check agreeing about whose work it is. Related terms: author, slug,
survey.

## branch name

Exactly two branch-name patterns are permitted, each named by exactly one script:
`work-YYYYMMDD-HHMMSS` for a claimed unit and `release/YYYYMMDD-HHMMSS` for a release
window. A tool-level guard blocks anything else. There is no long-lived integration
branch and no hotfix pattern. Related terms: claim, cut a release branch, timestamped
filename.

## .worktrees/

`.worktrees/<unit-id>/` holds a claim's own checkout — one per claimed unit,
claim-born and ship-torn. It sits **inside** the repository root, so it belongs in
`.dockerignore` and any archiver's ignore list. Related terms: worktree, claim.

## .publish/

`.publish/` is the git-ignored publish tree: a checkout of the base branch used by
artifact writers that have no claim. It is opened, written into, pushed behind a pull
request and closed, leaving the caller's checkout byte-identical. Also ignore-listed.
Related terms: publish tree, worktree.

## index.md and README.md

`README.md` and `index.md` are the **only** files allowed at the `.workaholic/` root, and
inside each area they play distinct roles: `README.md` is the human-written definition of
what the area holds and who writes it, while `index.md` is **generated** by the OKF index
refresh before each knowledge commit. Do not hand-edit an `index.md`. Related terms: OKF,
frontmatter.

## generated output

`outputs/` is generated and committed, never hand-edited: `outputs/workflows/` is the
self-contained portable bundle (plugin-root references rewritten relative, internal
metadata stripped) and `outputs/okf/` is the knowledge bundle of the six pillars. A
continuous-integration workflow rebuilds both and fails on any diff, so regenerating them
is part of the change that touched their source. Related terms: bundle, marketplace.

## reference directory

A skill's `reference/` directory holds the detail its `SKILL.md` cannot carry without
exceeding its size budget — the full contracts, vocabularies and measured origins. The
`SKILL.md` links to it; the split is a size convention, not a difference in authority.
Related terms: skill.

## trips

`.workaholic/trips/` is **read-only legacy history** — artifacts from a retired
exploration workflow. It stays in the layout allowlist so the audit does not report it,
and nothing writes there. Related terms: retired terms.
