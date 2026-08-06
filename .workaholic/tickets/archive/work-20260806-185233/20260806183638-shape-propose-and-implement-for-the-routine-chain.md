---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission: reduce-the-loop-to-two-routines-and-one-behaviour-per-command
merge_policy:
---

# Shape propose and implement for the routine chain

## Overview

PROPOSED. `/propose` and `/implement` exist for the routines, so they are shaped by what a
routine chain needs rather than by a developer at a terminal. Two concrete requirements: the
pull request **title** carries the `[Proposal]` prefix, and the pull request **body** carries
the notification target — the Slack thread URL — so the next routine finds where to reply
without re-deriving it. Today that target is re-derived from a `fb:<stem>` search, which is
the step that put a reply in the wrong place on 2026-08-05.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — the `[Proposal]` prefix contract lives here
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — writes the PR body
- `plugins/workaholic/skills/drive/SKILL.md` — where `/implement` reads its target
- `plugins/workaholic/skills/workaholify/SKILL.md` — *One thread per feedback item*, whose
  three-case search this makes unnecessary for the chain's own hand-offs

## Implementation Steps

1. Define where the target lives in the body — a single labelled line a script can read
   back, not prose a model has to interpret.
2. Have `/propose` write it, from the target the routine handed it.
3. Have `/implement` read it and reply there, falling back to the existing search only when
   the body carries none (an artifact from before this change).
4. State the contract once in the propose skill; the templates keep deferring.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A `/propose` pull request title starts with `[Proposal]`, and its body carries the
  notification target in a form a script reads back exactly.
- `/implement` replies in that target without searching for it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` over the body writer and reader
- One real chain: assigned issue → proposal PR → merge → implementation reply, all in one
  Slack thread

**Gate** — what must pass before approval:

- The fallback stays for artifacts that predate the change; it is not removed.

## Considerations

- A Slack thread URL in a public pull request body is a workspace-internal link; harmless,
  but worth stating rather than discovering.

## Final Report

Development completed as planned. `/propose` writes `Notify-Thread: <url>` into the
pull request body and prefixes the **title** with `[Proposal]`; `/implement` reads the
target back through `branching/scripts/read-notify-target.sh` and replies there, with
the existing `fb:<stem>` search kept as the documented fallback.

### Discovered Insights

- **Insight**: The `[Proposal]` prefix could not actually be written before this
  change. `publish-tree-pr.sh` passed one string to both `gh pr create --title`
  and `commit.sh`, and `commit/scripts/check-subject.sh` forbids a `[bracket]`
  prefix outright — so a proposal that honoured its own documented contract died
  at `commit_failed` before any pull request existed. The contract had been prose
  for a day and was never exercised; the test that exercised it is what found it.
  **Context**: `WORKAHOLIC_PR_TITLE` separates the two surfaces and falls back to
  the subject, so no other caller changes. A future edit that re-merges them
  reintroduces the contradiction silently — the pin asserts the subject keeps the
  project rule while the title carries the prefix.
- **Insight**: Both new inputs are **env vars, not positionals**, and the reason
  is structural: `publish-tree-pr.sh`'s positionals belong to `commit.sh` and end
  in an open-ended `[files...]`, so a seventh positional could not be told from a
  filename.
  **Context**: Any further per-publication input has the same constraint.
- **Insight**: `absent` had to be a distinct reason from `no_gh`/`unreadable`.
  It is the **fallback signal** — every pull request opened before this change
  carries no line — whereas the other two mean the question could not be asked at
  all. Collapsing them would send a caller looking for a broken tool instead of
  falling back to the search.
  **Context**: The same distinction the ownership work made between `other` and
  `unresolved`, in a different place: a conservative action shared by two states
  is not a reason to report them as one.
- **Insight**: The thread-routing rule became **four** ordered cases, with the
  carried target above the search. Placing it below would have made the writer's
  own known fact lose to a guess.
