---
created_at: 2026-09-03T06:47:53+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260903053327-draft-deploy-plan-sh-renders-non-ascii-target-titles-as-escape-sequences.md]
merge_policy:
verification_handoff: 
claim: work-20260903-160624
---

# Agree the two remaining JSON-string escapers on raw UTF-8

## Overview

Ticket `20260903053345` repaired `escape_json` in the three `ship/` scripts so a non-ASCII
deployment title reaches Markdown as text. Two other scripts carry the same escape with the same
defect and were left alone because they are outside that ticket's stated sweep — it named
deployment record fields and the release-note render, and these carry neither.

Both escape a string into a JSON value through `python3 -c '... json.dumps(...)[1:-1]'`, which
ASCII-escapes, with a `sed` fallback that does not escape non-ASCII at all. So the two paths of
one function disagree about the same input, and which answer a caller gets depends on whether
`python3` is installed:

- `gather/scripts/merge-commit-body.sh` — composes the **squash merge title and body** every
  `/implement` merge passes to `-f commit_title=` / `-f commit_message=`. A Japanese story title
  therefore lands on the trunk's permanent record as `リポ...`, which is exactly the
  hand-decoding the originating report objected to, one artifact over.
- `drive/scripts/run-verification-probe.sh` — carries a probe's **captured output** into the
  `## Handoff` section and the `🟡 Handoff` Slack post, both read by a person.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — `json_escape()`
- `plugins/workaholic/skills/drive/scripts/run-verification-probe.sh` — its own copy of the same
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — the repaired `escape_json()`,
  which is the shape to match

## Implementation Steps

1. Reproduce: feed a non-ASCII string through each `json_escape()` on a machine with `python3`
   and again with it forced to fail, and record that the two answers differ.
2. Apply the repaired shape — `ensure_ascii=False` with binary I/O — and make the `sed` fallback
   agree with it rather than leaving the two paths to disagree.
3. Confirm the emitted JSON still parses, since both scripts splice the escaped value into a
   `printf`-built object.
4. Pin a hermetic case per script asserting a non-ASCII value survives as characters.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A non-ASCII value passed through either `json_escape()` comes back as characters, not `\uXXXX`.
- The python3 path and the `sed` fallback return the same bytes for the same input.
- Each script's stdout is still parseable JSON.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the new hermetic cases.

**Gate** — what must pass before approval:

- Both escapers are covered; repairing one and reporting the other is the state this ticket exists
  to end.

## Considerations

- These were deliberately left out of `20260903053345` rather than overlooked: its sweep was
  scoped to the deployment record's own fields, and widening a ticket mid-drive is how a unit stops
  reconciling to its queue.
- `report-deploy-status.sh` and `read-deploy-state.sh` were checked in that run and need nothing —
  their `sed`-based escapers already pass non-ASCII through raw.

## Final Report

Development completed as planned.

The reproduction confirmed the ticket's account exactly. On one Japanese string the `python3`
branch of both `json_escape()` functions emitted `リポ...` while the `sed` fallback emitted
raw UTF-8 — so which answer a caller got depended on whether `python3` was installed, and both
answers reached a human-facing surface: `merge-commit-body.sh` composes the squash `commit_title`
and `commit_message` of every merge this loop makes, and `run-verification-probe.sh` carries a
probe's captured output into `## Handoff` and the `🟡 Handoff` Slack post.

Both now carry `read-deployments.sh`'s repaired shape with the outer quotes trimmed — these two
emit the **interior** of a JSON string, because their own `printf` templates supply the quotes,
which is why the repaired function could not simply be copied.

**The `sed` fallback was removed rather than patched, and that is a change of plan from the
ticket's step 2.** The ticket asked to "make the `sed` fallback agree"; measured on one input
carrying a tab, a carriage return and a `\001`, it cannot be made to agree at all — it emitted all
three **raw**, which are bytes a JSON string may not contain, so that rung was producing invalid
JSON for control characters as well as disagreeing about non-ASCII. Its `tr`/`sed` newline dance
also failed to fire (`\001` is not an escape GNU sed's BRE recognises), leaving a raw control byte
where a `\n` was intended. python3, node and perl were measured byte-identical on the same input,
so the chain is now those three — the same three `read-deployments.sh` pins, and the acceptance
criterion "the same bytes for the same input" is met exactly rather than approximately.

Both criteria were then proved at the script's own boundary rather than at the escaper's: a
non-ASCII probe output and a non-ASCII story description each survive as characters, and the run
that proves it is a `JSON.parse`, so parseability is the same assertion.

### Discovered Insights

- **Insight**: `merge-commit-body.sh` carries a **second** `python3` dependency with no fallback of
  any kind — the housekeeping filter that drops `Workaholic-Housekeeping:`-marked commits from the
  subject list, guarded by `2>/dev/null || true`. With `python3` shimmed to exit 127 the whole
  commit list vanished from the body while `source` still read `story` and `subject_reason` stayed
  empty, so nothing anywhere said the list had been dropped.
  **Context**: this is the same shape as the escaper defect one function over, and it is a
  different function, outside this ticket's stated sweep. Ticketed as
  `20260903162400-give-the-squash-body-s-housekeeping-filter-a-fallback`; the hermetic case here
  deliberately compares only the escaped description across the rungs and says in a comment why.
- **Insight**: an interpreter fallback chain is only single-sourced if the rungs are *tested against
  each other*. The measured way to do that cheaply is a shim — a `python3` on `PATH` that exits
  127 — which forces the second rung without needing a machine that lacks the interpreter.
  **Context**: both new cases use it, and it is what surfaced the housekeeping gap above; the
  earlier repair of `read-deployments.sh` pinned the pipeline's output rather than the rungs and
  would not have found this.
