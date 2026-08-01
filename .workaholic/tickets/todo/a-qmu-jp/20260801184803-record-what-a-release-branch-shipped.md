---
created_at: 2026-08-01T18:48:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on: [20260801184802-cut-and-promote-a-release-branch.md]
mission: adopt-a-git-flow-branching-model-with-durable-ship-records
merge_policy: auto
---

# Record what a release branch shipped, and when

## Overview

The traceability half of the mission. Today "what shipped to production, and when" is
answerable only by reading merge commits on `main`; the feedback asked for a durable
record, and the settled design attaches it to the **release branch itself** — which
`main` commits it carries, when it was cut, when it was confirmed and deployed.

This is **additive**. The existing per-unit mechanism (`.workaholic/release-notes/<branch>.md`
written pre-merge, the Deployment Evidence block appended to the story, the story copied
into the PR body) is untouched. One assumption from the originating discussion was already
corrected and still holds: `/ship` does not produce zero artifacts today.

A new top-level artifact directory under `.workaholic/` is a **registered amendment**, not
a `mkdir`: the layout is closed, and both sources of truth must be updated in the same
commit that first writes there, or the guard hard-blocks the write.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — the record must answer the question from the filesystem, with `grep` and `git log`, not by opening GitHub.
- `workaholic:implementation` / `policies/directory-structure.md` — a new artifact area is a deliberate amendment registered in the same change.
- `workaholic:operation` / `policies/deployment-pipeline.md` — the record is written by the pipeline, not by hand.

## Key Files

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` - one of the two lockstep sources of truth
- `plugins/workaholic/rules/workaholic.md` - the other; the table must gain the row in the same commit
- `plugins/workaholic/hooks/layout-doctor.sh` - the anti-drift audit that fails CI on a stale allowlist
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` - the existing evidence writer, and the model to follow
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` - every `.workaholic/` area carries an OKF index

## Implementation Steps

1. Decide the artifact's shape and where it lives. If it needs a new top-level directory,
   register it in **both** `hooks/workaholic-layout-allowlist.txt` and the
   `rules/workaholic.md` table **in the same commit** as the first write.
2. Give it OKF-conformant frontmatter with a non-empty `type`, like every other
   `.workaholic/` artifact, and make sure `refresh-index.sh` covers the area.
3. Write it from the promotion flow: the cut records the carried `main` commits and the
   cut time; confirmation appends the confirmed/deployed time. Never hand-authored.
4. Cross-reference it with the release branch both ways, so either one finds the other.
5. Reconcile every doc that describes the branching model or the `.workaholic/` layout in
   the same change, and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria**

- A confirmed release branch has a durable record naming the `main` commits it carried, its cut time, and its confirmation/deploy time.
- A developer can answer "what did this deploy carry, and when" with `grep` and `git log` alone.
- The record is a **separate** artifact: `.workaholic/release-notes/` and the story's Deployment Evidence block are byte-identical in shape to today.
- If a new directory was introduced, `hooks/workaholic-layout-allowlist.txt` and the `rules/workaholic.md` table both carry it, in the same commit as the first write.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with a hermetic case that cuts a release branch, confirms it, and asserts the record's fields against the commits actually carried.
- `layout-doctor.sh .` and the `Validate Plugins` CI audit both pass.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual diff.

**Gate**

- `layout-doctor.sh` reports conforming **and** the registration rode in the same commit as the first write. A stale allowlist is not a warning here; it hard-blocks the write.

Decided: the record is derived from git at cut/confirm time rather than accumulated per unit — the question it answers is about the release, and re-deriving it from per-unit notes would make it a view rather than a record (developer may override at /drive).

## Considerations

- Every doc naming the branching model must tell the truth in the same change: `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `docs/drive-loop-runbook.md`, `docs/loop-engineering-workflow.md`. That is one of the mission's acceptance items and is easy to leave for later.
