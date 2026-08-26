---
created_at: 2026-08-26T02:18:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-the-loop-s-closing-link
merge_policy:
verification_handoff: 
---

# Read the ask's feedback line through one script

## Overview

`specificate/reference/workflow.md` step 3b tells the run to "read the line, verify each
ref exists under `.workaholic/feedbacks/`, and pass the surviving refs to steps 8 and 9".
No script does it. `skills/specificate/scripts/` has a reader for an *artifact's*
`feedback:` relation (`read-feedback-relation.sh`) and two scaffolds that accept refs
without asking where they came from — nothing reads the **ask's own** line.

This repository's stated rule is one reader per relation: "two parsers of one field
eventually disagree, and the side that under-reads re-proposes answered feedback"
(`read-feedback-relation.sh` header). The ask's line is a second surface of the same
relation and it has no reader at all. Add it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a drop is named, never silent

## Key Files

- `plugins/workaholic/skills/specificate/scripts/read-ask-feedback-refs.sh` — new; the reader
- `plugins/workaholic/skills/specificate/scripts/read-feedback-relation.sh` — the mirror to
  match in shape, tolerance and output discipline (frontmatter-only, never fails on a
  malformed file)
- `plugins/workaholic/skills/specificate/SKILL.md` — *Carry the ask's own feedback refs
  forward*; the Scripts list gains the new entry
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 3b names the script
- `scripts/test-workflow-scripts.mjs` — hermetic coverage

## Implementation Steps

1. Write `read-ask-feedback-refs.sh`, taking the ask's body on **stdin** (a file path is not
   available for a GitHub issue body) and the feedbacks directory as an optional argument
   defaulting to `.workaholic/feedbacks`.
2. Parse the `feedback: <ref>, <ref>` line as `/propose` writes it
   (`propose/scripts/open-issue.sh` — read the writer before choosing the pattern, so the
   reader and the writer cannot disagree). Tolerate the inline-list form, a bare scalar, and
   a line with no refs; take the first such line only.
3. Resolve each ref under the feedbacks directory. Emit
   `{"carried": [...], "dropped": [{"ref", "reason"}], "line_found": true|false}` — reasons
   at least `not_found` and `unreadable`; a ref is never invented and never rewritten.
4. Exit 0 in every case, including no line at all: a missing line is the ordinary case for
   an ask a human typed, not a failure (the same discipline as
   `list-inbound-issues.sh`'s `{ok: false}` with exit 0).
5. Wire step 3b in `reference/workflow.md` and the SKILL's *Carry the ask's own feedback refs
   forward* section to invoke it, replacing the read-by-eye instruction. Add it to the
   SKILL's Scripts list.
6. Add hermetic cases to `scripts/test-workflow-scripts.mjs`: a line with two refs where one
   resolves and one does not; no line at all; a malformed line. No `gh`, no network.
7. Regenerate the cross-agent bundle (`node scripts/build-plugins/build.mjs`) and verify
   (`verify.mjs`) — a new script under a workflow skill changes `outputs/`, and the
   `Outputs Freshness` CI workflow fails on any diff.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `read-ask-feedback-refs.sh` returns the carried set and the dropped set with a reason per
  drop, for an ask body handed to it on stdin
- An ask with no `feedback:` line returns an empty carried set and `line_found: false`, exit 0
- Step 3b in `reference/workflow.md` names the script; the SKILL's Scripts list carries it

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `git diff --exit-code outputs/` after the rebuild

**Gate** — what must pass before approval:

- The smoke tests pass and `outputs/` is regenerated in the same commit

## Considerations

- **The writer is the authority on the format.** `/propose` writes that line as visible text
  rather than an HTML comment, deliberately; read its writer rather than inferring the shape
  from one issue body.
- The reader is a **pure read** — it resolves paths and never writes, so it is safe to call
  before the judgment as well as after.
- Scope discipline: this ticket adds the reader and its wiring only. What the run *says*
  about the result is the next ticket; refusing a publish that lost a ref is the one after.
