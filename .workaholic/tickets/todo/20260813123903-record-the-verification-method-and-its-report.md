---
created_at: 2026-08-13T12:39:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-deployment-plans-in-the-release-note-before-deploying
merge_policy:
---

# Record the verification method and its report

## Overview

PROPOSED. Issue #438's step 4 — "eventually have the Release Note also record the verification method and verification report as well" — and the reason the plan is worth drafting at all: a plan that says what verification is required, and never records whether it ran, degrades into a wish within a few releases.

The evidence already exists but lands elsewhere. `ship/scripts/record-evidence.sh` appends a `## Deployment Evidence` section to the **story** for the branch, taking target, method, result and status (`pass` / `bypassed`), and refusing a `possible_secret`. `confirm-release.sh` records a `pass`/`fail` attempt into `.workaholic/releases/<release-branch>.md` for the batch. Neither writes into the note that will carry the plan, so a reader holding the plan cannot see whether its verification happened. This ticket closes the loop: the instructed deployment's method and observed report land in the same document as the plan that asked for them, without duplicating the story evidence or weakening either existing writer.

The ask marks this "eventually", so it is deliberately last in the set.

## Policies

- `workaholic:implementation` / `policies/observability.md` — the recorded result is what makes the plan checkable after the fact
- `workaholic:operation` / `policies/ci-cd.md` — verification is part of the delivery path, not a report about it
- `workaholic:design` / `policies/history-structures.md` — an attempt is history: append, never overwrite a previous result
- `workaholic:implementation` / `policies/objective-documentation.md` — the recorded method must be the executable one, not a paraphrase

## Key Files

- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` — the existing evidence writer (target, method, result, status; refuses `possible_secret`); this ticket extends or composes it rather than adding a second, divergent writer.
- `plugins/workaholic/skills/ship/scripts/confirm-release.sh` — records a release-window attempt with `pass`/`fail`; the precedent for append-only attempt history.
- `plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh` — knows whether the environment can run a declared method; a recorded "not run" must be distinguishable from a recorded failure.
- `plugins/workaholic/skills/write-release-note/SKILL.md` — the note's structure, where the verification block is specified alongside the plan section.
- `.workaholic/deployments/marketplace.md` — the `## Confirmation` this repository's target declares (pre-merge and post-merge parts), the method that would be recorded.
- `plugins/workaholic/skills/ship/reference/scripts.md` — the contract table to update.
- `.workaholic/stories/` — where deployment evidence lands today; the relation between the two records must be stated, not left implicit.

## Implementation Steps

1. Specify the verification block in `write-release-note`: per planned target, the method as declared, the exact check that ran, the observed result, and the status — with `not_run` (capability absent) distinct from `fail`.
2. Extend or compose `record-evidence.sh` so one writer fills both destinations, keeping its `possible_secret` refusal intact; do not add a second writer with its own redaction rules.
3. Make the block append-only: a second attempt adds a row and never rewrites the first, matching `confirm-release.sh`'s rule that a failed confirmation deletes nothing.
4. State the relation between the note's verification block and the story's `## Deployment Evidence` — same evidence, two audiences — and reference one from the other so a reader is not left comparing them.
5. Tie the block back to the plan entry it answers, so an unverified planned deployment is visibly unverified rather than merely absent.
6. Add hermetic coverage: `pass`, `fail`, `bypassed`, `not_run`, and a second attempt appending rather than overwriting.
7. Update `ship/reference/scripts.md`, `CLAUDE.md` and `README.md`; regenerate `outputs/` with argument-less `node scripts/build-plugins/build.mjs`.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- A deployment the developer instructed leaves, in the document carrying its plan, the verification method, the check that ran, the observed result and a status.
- `not_run`, `fail`, `pass` and `bypassed` are four distinguishable recorded states.
- A second attempt appends; no previous result is rewritten or removed.
- The existing story evidence and the `possible_secret` refusal are unchanged in behaviour.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green with the five new cases.
- A live run against the `marketplace` target recording the post-merge `gh release view v<version>` check and its result.
- A deliberate secret-shaped result string is still refused.

**Gate** — what must pass before approval:

- Suite green, the live recording pasted into the Final Report, and the story-evidence behaviour shown unchanged.

## Considerations

- The failure mode this guards against is a plan whose verification column is aspirational — every release planning a check nobody ever ran, with nothing in the tree showing it.
- Verification output can carry secrets (tokens in a probe URL, a connection string in a DB check). `record-evidence.sh`'s refusal is the only thing standing between an observed result and a committed credential; extending the writer must not route around it.
- For a deploy-on-merge target the confirmation is split pre-merge/post-merge. One block per attempt has to hold both halves, or a promoted release will look half-verified.

## Final Report

Development completed as planned.

### What was built

`record-evidence.sh` gained an optional sixth argument, the Release Note path. Given one,
the same call appends a `## Deployment Verification` block to that note in addition to the
story's `## Deployment Evidence` — **one writer, two destinations**, which is what keeps
the `possible_secret` refusal load-bearing for both. A second writer with its own
redaction rules would have been the way around the only guard standing between an observed
result and a committed credential.

The four statuses are now a **closed set checked in the script** — `pass`, `fail`,
`not_run`, `bypassed` — and anything else is refused as `bad_status` with nothing written.
`not_run` (the declared method cannot execute in this environment) is the new one, and it
exists because "we could not check" and "we checked and it was wrong" call for different
acts; a record that conflated them would make an unverified deployment read as a verified
one, which is the failure mode the ticket named.

The note block is **append-only**: the `## Deployment Verification` heading is written
once and every attempt adds a `### Attempt` beneath it, matching `confirm-release.sh`'s
rule that a failed confirmation deletes nothing. Each block ties itself back to the plan
entry it answers (`**Answers:** the ## Deployment Plan entry for <target>`) and names the
story it is also recorded in, so a reader is never left comparing two documents to work
out whether they describe the same event.

### Verification limit — stated rather than skipped

The ticket's verification method asks for "a live run against the `marketplace` target
recording the post-merge `gh release view v<version>` check and its result". **That was not
run.** A live recording requires an instructed deployment against production, which this
unattended run has no instruction to perform and which the safety floor puts outside what
it may take on its own — and, after the sibling ticket, `/ship` deliberately cannot start
one. What was proven instead is every property the ticket's acceptance criteria state, in
the hermetic suite: all four statuses recordable and distinguishable, a second attempt
appending rather than overwriting, the attempts staying in order, the secret refusal
writing to **neither** destination, an out-of-set status refused, and the story-only path
byte-for-byte unchanged when no note is passed. The live recording remains for the first
real instructed deployment.

### Discovered Insights

- **Insight**: `record-evidence.sh` returned `{"recorded": false, "reason": "no_story"}`
  when the story was missing; with a note destination that is no longer the right answer.
  **Context**: The refusal now fires only when there is *neither* a story nor a usable
  note, and `story` comes back as `""` when only the note was written. A refusal keyed to
  one destination silently becomes wrong the moment a second exists — and the failure
  would have been a *silently unrecorded* deployment, the exact thing this ticket exists
  to prevent.

- **Insight**: for a deploy-on-merge target the confirmation is split pre-merge/post-merge,
  and one block per attempt has to hold both halves.
  **Context**: The block records the method "as declared" plus the observed result, and the
  `marketplace` record declares both halves under one `## Confirmation`. So one attempt
  block naturally carries both — but only because the *record* keeps them together. A
  target that split them into two frontmatter methods would produce a half-verified
  reading, and the fix would belong in the record, not here.
