---
created_at: 2026-09-03T16:24:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: 20260903053327-draft-deploy-plan-sh-renders-non-ascii-target-titles-as-escape-sequences.md
merge_policy:
verification_handoff: 
claim: work-20260903-172646
---

# Give the squash body's housekeeping filter a fallback

## Overview

`gather/scripts/merge-commit-body.sh` composes the squash `commit_title` and `commit_message` of
every merge this loop makes. Ticket `20260903064753` repaired its `json_escape()` and, in doing so,
measured a **second** `python3` dependency in the same script that nothing had noticed.

The housekeeping filter — the step that drops `Workaholic-Housekeeping:`-marked commits from the
subject list — is a `python3 -c` program guarded by `2>/dev/null || true`. It has **no fallback
rung at all**, so on a machine where `python3` is absent or fails, `subjects` comes back empty,
`subject_reason` stays empty, and the body is assembled with **no commit list whatsoever** while
`source` still reads `story`. Measured by shimming `python3` to exit 127: the same call returned
`"見出しを日本語のまま渡す\n\n* Add a non-ASCII story"` with the interpreter present and
`"見出しを日本語のまま渡す"` without it, and nothing anywhere said the list had been dropped.

This is the same shape as the escaper defect one function over — one behaviour with two paths that
disagree — but it is a **different** function and was deliberately left out of `20260903064753`,
whose sweep was the `json_escape()` pair. The escaper's own repair pinned the two rungs against
each other and explicitly declined to compare the subject list across them, naming this ticket.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a degraded read is named, never silent

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — the housekeeping filter at the
  `# --- Compose the subject list` block, and `subject_reason`, which it never sets
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — the three-interpreter shape the
  escaper repair matched
- `scripts/test-workflow-scripts.mjs` — `testMergeBodyIsSingleSourced`, where the deliberate
  non-comparison is written down

## Implementation Steps

1. Reproduce: run the composer against a branch carrying one marked and one unmarked commit, once
   with `python3` on `PATH` and once with it shimmed to fail, and record that the subject list is
   present in the first and absent in the second with no reason reported.
2. Decide the shape and apply it. Two candidates, and the ticket does not pre-judge between them:
   give the filter the same `node`/`perl` rungs the escaper now carries, or express the whole
   subtraction in `git`/`sort`/`comm` so no interpreter is needed at all.
3. Make a filter that could not run **say so** rather than returning an empty list: `source` must
   not read `story` over a body whose commit list was silently dropped.
4. Pin a hermetic case asserting the subject list survives the fallback rung, and remove the
   deliberate non-comparison note in `testMergeBodyIsSingleSourced` once it does.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The subject list is byte-identical with `python3` present and with it shimmed to fail.
- A filter that genuinely could not run is named in the emitted JSON, never rendered as a branch
  with no commits.
- The composer's stdout is still parseable JSON on every path, and the merge is never held on it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the new hermetic case.

**Gate** — what must pass before approval:

- The subject list agrees across the rungs, or the disagreement is reported. Repairing one rung and
  leaving the other silent is the state this ticket exists to end.

## Considerations

- This is a **body**, never a gate: `merge-commit-body.sh`'s own header states that a composer which
  fails still yields a fallback body and the merge is never held on it. Whatever this change does,
  it must not introduce a path where a merge waits on the body composer.
- The two `pr_json` parsers a few lines above have the same `python3`-only shape. They already fall
  back to an empty string and set `lookup_reason`, so they degrade *and say so* — which is the
  behaviour this ticket is asking the filter to reach, and they may not need changing.
