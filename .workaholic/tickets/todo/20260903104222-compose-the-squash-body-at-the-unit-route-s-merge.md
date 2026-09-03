---
created_at: 2026-09-03T10:42:22+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Compose the squash body at the unit route's merge

## Overview

`ship/scripts/merge-pr.sh` is the merge that produced the measured 267-line body: it is the unit
route's own merge, so every driven unit's bookkeeping reaches the trunk through it. It passes
`merge_method` and nothing else. This ticket makes it read the composer.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` — the call site (the `PUT
  repos/<slug>/pulls/<n>/merge` around line 93).
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — the derivation it reads.
- `plugins/workaholic/skills/gather/scripts/merge-method.sh` — the neighbouring read, for the
  shape.


## Implementation Steps

1. Read the composer for the pull request being merged, before the REST call.
2. Pass `commit_title` and `commit_message` as `-f` fields beside `merge_method`, never spelled
   inline.
3. A composer that answers `unreadable` still yields the fallback body — the merge proceeds and
   the run report names the `source`. The merge is never held on the body.
4. Report the `source` in the script's own JSON output so a caller can name it.
5. Extend the hermetic coverage of `merge-pr.sh` to assert the two fields are sent.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A merge through `merge-pr.sh` lands a squash commit whose body is the composed text, not the
  branch's concatenated messages.
- The `source` is reported and a degraded composer does not hold the merge.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A driven unit merged on this repository, reading `git show --format=%B` on the resulting commit.

**Gate** — what must pass before approval:

- No literal `commit_message=` or `commit_title=` text at the call site.
- Every existing `merge-pr.sh` refusal word is unchanged.


## Considerations

- This is the highest-traffic merge in the loop; a defect here stops units landing. The fallback
  path is what keeps a composer failure from becoming a merge failure.

## Final Report

**Outcome**: implemented.

`ship/scripts/merge-pr.sh` reads `merge-commit-body.sh` for the pull request being merged, beside the
`merge-method.sh` read already there, and passes `-f commit_title=` / `-f commit_message=` as fields
whose values are never spelled inline. A composer answering `unreadable` still yields the fallback
body, so **the merge is never held on it**; the script reports the composer's own word as a new
`body_source` field in its JSON output, and every existing refusal word (`gh_unavailable`, `no_remote`,
the merge-failure detail) is byte-identical.

**Verified**: `node scripts/test-workflow-scripts.mjs`. The suite's tree-derived enumeration of
`pulls/<n>/merge` call sites now covers this file in both directions — it spells no literal body, and
it reads the composer.
