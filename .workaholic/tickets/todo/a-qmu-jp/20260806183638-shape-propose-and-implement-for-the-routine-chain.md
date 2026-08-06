---
created_at: 2026-08-06T18:36:38+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
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
