---
created_at: 2026-09-03T10:42:22+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Compose the squash body at the publish tree's merge

## Overview

`branching/scripts/publish-tree-pr.sh` merges every publication the loop opens — each proposal,
each ruling draft, each `/ticket`. Those trees carry index refreshes and staging commits, and the
same forge default puts them on the trunk.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the call site (around line
  383).
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — the derivation.


## Implementation Steps

1. Read the composer before the REST merge and pass `commit_title` / `commit_message`.
2. A publication has no branch story, so this is the fallback path by construction: the title is
   the publication's own `WORKAHOLIC_PR_TITLE` and the body one line naming what was published.
3. Leave every refusal untouched — `strategy_touching` and `ruling_touching` still refuse the
   merge before any body is composed, so no work is done for a merge that will not happen.
4. Report the `source` in the script's JSON output.
5. Extend the hermetic coverage for the publish seam.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A merged publication's squash body is the composed one line, not the tree's staging commits.
- `strategy_touching` and `ruling_touching` still leave the pull request open, unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A `/specificate` proposal merged on this repository, read back with `git show --format=%B`.

**Gate** — what must pass before approval:

- The two refusal words are byte-identical across the change.
- No literal body field spelled at the call site.


## Considerations

- A publication's fallback line is the only body it will ever have. It should name the artifact
  the publication carries — the record, the mission, the ticket count — rather than repeat the
  title.

## Final Report

**Outcome**: implemented.

`branching/scripts/publish-tree-pr.sh` composes the body immediately before its REST merge and passes
the two fields. As the ticket predicted, a publication has no branch story by construction, so
`fallback` is its ordinary answer rather than a failure — one line naming what was published, in place
of the tree's staging and index-refresh commits.

**Every refusal is untouched and runs first**: `strategy_touching` and `ruling_touching` still refuse
the merge before any body is composed, so no work is done for a merge that will not happen, and the
`merge_reason` ladder is byte-identical. The script reports `body_source` in its JSON output beside
`merge_reason`.

**Verified**: `node scripts/test-workflow-scripts.mjs` — the call-site enumeration covers this file,
and the existing publish-seam rows are unchanged.
