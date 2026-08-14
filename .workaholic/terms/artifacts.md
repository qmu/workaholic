---
type: Term
title: Artifacts
description: What each .workaholic/ artifact is called, what it holds, and who writes it
category: developer
last_updated: 2026-08-13
---

# Artifacts

What each `.workaholic/` artifact is called and means. Every entry below names a live
area — one some script writes or reads. The structural rules (what may exist at the
root, which frontmatter each carries) are in `plugins/workaholic/rules/workaholic.md`;
this file is the vocabulary.

## ticket

A ticket is one **drive-able unit of work**: what should change, and afterwards what
happened. It carries `created_at`, `author`, `assignees`, optional `depends_on`,
`mission` and `merge_policy` frontmatter, and a body whose two mandatory sections are the
policy list and the `## Quality Gate`. Queued tickets live in `.workaholic/tickets/todo/`
and completed ones in `.workaholic/tickets/archive/<branch>/`; the filename is
`YYYYMMDDHHmmss-<short-description>.md`. A ticket is **the OKF exception**: it carries no
`type:` frontmatter and its directories are never index-managed. Related terms: mission,
story, quality-gate, final-report.

## mission

A mission is an optional, epic-equivalent grouping of **two or more tickets** that only
make sense driven together — the ticket floor, checked where a mission is published. It
holds a demanded `## Experience`, an `## Acceptance` list of at most three items, an
append-only `## Changelog`, and a duration record (`predicted_hours` stamped once at
creation, `actual_hours` accumulated across runs). In-flight missions live in
`missions/active/`, ended ones in `missions/archive/` with `achieved`, `abandoned` or
`carried`. Progress is computed (checked ÷ total), never stored. It is not a milestone
and not a board: a direction with no tickets is a feedback record, and a single unit of
work is a plain ticket. Related terms: ticket, acceptance, strategy.

## story

A story is the narrative of one branch's work, and it **is** the pull request body — the
file's content minus frontmatter is what GitHub shows. Stories live at
`.workaholic/stories/<branch>.md` in eight sections: Overview, Motivation, Changes,
Outcome, Concerns, Successful Development Patterns, Release Preparation, Notes, plus a
conditional unnumbered `## Handoff` that renders first. Written by `/report`. Related
terms: ticket, journey, concerns, handoff.

## feedback record

A feedback record is one **immutable** entry in the inbound stream at
`.workaholic/feedbacks/`. It carries a `kind` (insight, instruction, concern, material,
answer), a `source` (the channel it arrived through), and a `subject` (whose opinion it
is — `<kind>[:<identity>]`). It is never edited and never moved: a resolution is a **new
record** naming the old one in `supersedes`, which is why the open concern set is
computed rather than stored. Written by `/fb`, `/propose` (one on every run), `/ship` and
`/report`. Related terms: concern, subject, strategy, supersedes.

## subject

The subject of a feedback record is **whose opinion it carries** — a closed kind set
(`person`, `meeting`, `observer_ai`, `customer`, `team`, `other`) with a free-text
identity. Three axes look alike and answer different questions: **subject** is who formed
the opinion, **source** is the channel it arrived through, and **author** is the git
identity that ran the capture. It is never defaulted to the runner — a machine writes
most of the stream, so a default would record every opinion in the project as the
machine's. Related terms: feedback record, author.

## strategy

A strategy is the operator's **outbound, resolved direction**: one flat
`.workaholic/strategies/<slug>.md` carrying an **Aim** (what is pursued), a **Schedule**
(a real `target_date`) and an **Assignee** (non-empty `assignees` — the one artifact
where empty is a refusal rather than team-owned). Operator-authored; no command, hook or
routine puts one on `main` on its own — `/propose`'s strategy form may draft one into a
proposal pull request, which is then the one proposal that does not auto-merge, so the
operator's merge stays the act that authors it. It is the complement of the feedback stream, not a second copy: the
stream records what someone **said**, a strategy records what the operator **decided**,
and the citation link runs one way (strategy → feedback). It carries no ticket plan —
planning executable work stays a mission's job. Related terms: feedback record, mission.

## release note

A release note is one record per shipped **unit** branch at `.workaholic/release-notes/`,
written just before the merge. It holds **two tenses**: the retrospective narrative of
what the branch changed, and the prospective `## Deployment Plan` — per deployment
target, what is waiting to deploy, the procedure, and the verification required — which
`/ship` drafts and refreshes idempotently. An instructed deployment appends its result to
the note's append-only `## Deployment Verification`. Related terms: release record,
deployment record, story.

## release record

A release record is one file per production release at `.workaholic/releases/`, named for
its `release/*` branch: which base commits the release carried, when it was cut, and when
it was confirmed or failed. Written only by the promotion pipeline and derived from git,
never hand-authored. **Not** a release note — that is one per shipped unit, this is one
per production release, and a failed confirmation is recorded rather than erased. Related
terms: release note, release branch.

## deployment record

A deployment record is one file per **delivery path** at `.workaholic/deployments/`,
carrying a `## Procedure` (copy-paste executable, not "deploy it") and a `##
Confirmation` (the exact executable way to prove it reached production). Written by a
**human**, when the delivery path changes; `/ship` is its only live reader and gates on
the confirmation. It never holds credentials, a deploy log, or a record of what a run
did. Related terms: release note, confirmation, gate.

## term

A term is one entry in this glossary — a word, what it means *here*, and what it is not.
Records live in `.workaholic/terms/` as one file per term family and carry `type: Term`.
Written by a **human**, when a term is coined or re-defined; a machine-maintained
glossary would define the words the machine already uses, which is the opposite of what a
glossary is for. Staleness is made visible by `report/scripts/area-freshness.sh`, which
reports and never writes. Related terms: inconsistencies, area freshness.

## quality gate

The `## Quality Gate` is a ticket's mandatory contract, captured when the ticket is
written: **acceptance criteria** (the checkable conditions that must hold) and a
**verification method** (the commands, tests or probes that prove them). The driver
implements *to* it, runs its verification before archiving, and carries its criteria into
the archive commit. A ticket without one is refused by the write floor. Related terms:
ticket, gate.

## final report

The Final Report is the section appended to a ticket **before** it is archived —
"Development completed as planned", or what differed and why. The archive commit is its
permanent home, which is why the report is written first and the move second. It may
carry a **Discovered Insights** subsection. Related terms: ticket, discovered insights,
archive.

## discovered insights

Discovered Insights is the optional subsection of a Final Report recording what the work
taught: architectural patterns, non-obvious relationships, historical context, edge
cases. The test is whether it is still useful months later — restating the ticket's
Overview is not an insight. Related terms: final report, ticket.

## handoff

A handoff is a unit that is genuinely **half-driven**: its queue is not drained, the work
that exists is pushed, and continuing needs a person or another session. It writes an
unnumbered `## Handoff` section that renders first in the pull request body and cannot be
dropped, leaves its tickets stamped in `todo/`, and ends the run `pending`. It is not the
soft landing for a unit the run did not want to attempt — that is not a state at all.
Related terms: story, unit, blocked.

## concern

A concern is a problem a branch **knowingly leaves behind**, recorded in the story's
Concerns section with a severity and a fix. `/ship` extracts each into the feedback
stream as a `kind: concern` record keyed on `concern_id`, so the durable record outlives
the pull request; the open set is computed — a concern stays open until a later record
names it in `supersedes`. Low-severity blocks are dropped at pull-request render but
never from the story file. Related terms: feedback record, story, supersedes.

## journey

The Journey is a story's narrative of how the work progressed — phases and pivots rather
than per-ticket detail, 50-100 words, with a mermaid flowchart of the progression. It is
**conditional**: a branch with two or fewer archived tickets skips it entirely, because a
flowchart earns its keep only once there is a multi-phase progression worth diagramming.
Related terms: story, changes.

## changes

The Changes section is a story's detailed "what changed", one `### 3-N. <Ticket title>
([hash](commit-url))` subsection per archived ticket, each a sentence or two from that
ticket's Overview. It is the companion to Journey's "how did we get here". Related terms:
story, journey, ticket.

## related history

Related History is a ticket section linking past archived tickets that touched the same
files or concerns — a summary sentence plus links with repository-relative paths. Written
by the discovery pass at ticket time, omitted when there are no matches. Related terms:
ticket, archive.

## changelog

Two different things carry this name, and the difference matters. The root `CHANGELOG.md`
is the repository's own history file. A mission's `## Changelog` is an append-only list
of lines the commit seams (archive, ship, report) add as work lands, through idempotent
mutators — never hand-edited, and the reason `.workaholic/` merge conflicts are resolved
by keeping both sides. Related terms: mission, story.

## Retired artifacts

`spec`, `policy` (as a `.workaholic/` artifact), `constraint`, `direction`, `model`,
`design` and `failure-analysis` are recorded with their retirement dates and successors
in [retired-terms.md](retired-terms.md).
